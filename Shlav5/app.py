"""
app.py – VetCare Management System – Stage 5 GUI
=================================================
Full-featured CustomTkinter desktop application for veterinary
clinic data management.  CRUD on 6 tables, FK-hidden views,
UPDATE-by-PK flow, and advanced Stage 2/4 executions.

Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
"""

import customtkinter as ctk
from tkinter import ttk, messagebox, StringVar
import db

# ── App-wide theme ───────────────────────────────────────────────────
ctk.set_appearance_mode("dark")
# Switched to dark-blue for better stability on Windows 11 / Python 3.13
ctk.set_default_color_theme("dark-blue")

# ── Color palette (Hex only, no alpha strings) ───────────────────────
C_BG       = "#161b22"   # deep navy-grey
C_CARD     = "#0d1117"   # darker card background
C_SIDEBAR  = "#1f2937"   # header / sidebar
C_ACCENT   = "#ef4444"   # primary red-red
C_ACCENT2  = "#8b5cf6"   # purple
C_GREEN    = "#10b981"
C_YELLOW   = "#f59e0b"
C_TEXT     = "#f0f6fc"
C_MUTED    = "#8b949e"

# ── Fonts ────────────────────────────────────────────────────────────
F_HERO     = ("Segoe UI", 34, "bold")
F_TITLE    = ("Segoe UI", 20, "bold")
F_SUB      = ("Segoe UI", 14, "bold")
F_LABEL    = ("Segoe UI", 12)
F_ENTRY    = ("Segoe UI", 12)
F_BTN      = ("Segoe UI", 12, "bold")
F_SMALL    = ("Segoe UI", 11)
F_MONO     = ("Consolas", 12)

PAD = 10


# ═════════════════════════════════════════════════════════════════════
#  SETTINGS DIALOG — enter DB credentials at launch
# ═════════════════════════════════════════════════════════════════════
class SettingsDialog(ctk.CTkToplevel):
    def __init__(self, parent, on_save):
        super().__init__(parent)
        self.title("⚙️ Database Settings")
        self.geometry("450x380")
        self.resizable(False, False)
        self.grab_set()
        self.on_save = on_save

        ctk.CTkLabel(self, text="Connection Parameters", font=F_TITLE).pack(pady=(20, 10))

        form = ctk.CTkFrame(self, fg_color="transparent")
        form.pack(fill="x", padx=30)

        self.entries = {}
        fields = [
            ("Host (IP)", "host", db.DB_CONFIG["host"]),
            ("Port", "port", str(db.DB_CONFIG["port"])),
            ("Database", "dbname", db.DB_CONFIG["dbname"]),
            ("User", "user", db.DB_CONFIG["user"]),
            ("Password", "password", db.DB_CONFIG["password"]),
        ]
        for label, key, default in fields:
            row = ctk.CTkFrame(form, fg_color="transparent")
            row.pack(fill="x", pady=4)
            ctk.CTkLabel(row, text=label, font=F_LABEL, width=100, anchor="w").pack(side="left")
            entry = ctk.CTkEntry(row, width=250, show="*" if key == "password" else "")
            entry.insert(0, default)
            entry.pack(side="left")
            self.entries[key] = entry

        ctk.CTkButton(self, text="💾 Save & Try Connect", font=F_BTN,
                       fg_color=C_GREEN, hover_color="#059669",
                       command=self._save).pack(pady=25)

    def _save(self):
        for key, entry in self.entries.items():
            val = entry.get().strip()
            if key == "port":
                db.DB_CONFIG[key] = int(val) if val.isdigit() else 5432
            else:
                db.DB_CONFIG[key] = val
        
        ok, err = db.test_connection()
        if ok:
            messagebox.showinfo("Success", "Database connected! ✅")
            self.on_save()
            self.destroy()
        else:
            messagebox.showerror("Auth Error", f"Failed: {err}\n\nDouble check password!")


# ═════════════════════════════════════════════════════════════════════
#  STYLED TREEVIEW HELPER
# ═════════════════════════════════════════════════════════════════════
def make_treeview(parent, columns, widths=None):
    """Simple styled ttk.Treeview to avoid TclError with alpha colors."""
    style = ttk.Style()
    style.theme_use("clam")
    
    # Force solid hex colors for Treeview to avoid invalid color name errors
    style.configure("Vc.Treeview",
                    background="#010409", foreground="#d1d5db",
                    fieldbackground="#010409", rowheight=28,
                    font=("Segoe UI", 10), borderwidth=0)
    style.configure("Vc.Treeview.Heading",
                    background="#1f2937", foreground="white",
                    font=("Segoe UI", 11, "bold"), relief="flat")
    style.map("Vc.Treeview",
              background=[("selected", "#3b82f6")],
              foreground=[("selected", "white")])

    wrapper = ctk.CTkFrame(parent, fg_color="#010409", corner_radius=8)
    wrapper.pack(fill="both", expand=True, padx=PAD, pady=(0, PAD))

    tree = ttk.Treeview(wrapper, columns=columns, show="headings",
                         style="Vc.Treeview", selectmode="browse")
    vsb = ttk.Scrollbar(wrapper, orient="vertical", command=tree.yview)
    tree.configure(yscrollcommand=vsb.set)

    for i, col in enumerate(columns):
        w = widths[i] if widths and i < len(widths) else 120
        tree.heading(col, text=col)
        tree.column(col, width=w, stretch=True)

    tree.grid(row=0, column=0, sticky="nsew")
    vsb.grid(row=0, column=1, sticky="ns")
    wrapper.rowconfigure(0, weight=1)
    wrapper.columnconfigure(0, weight=1)
    return tree


# ═════════════════════════════════════════════════════════════════════
#  CRUD TAB BASE
# ═════════════════════════════════════════════════════════════════════
class CrudTab:
    def __init__(self, parent, *, table_label, pk_label, fields, tree_cols, tree_widths,
                 fetch_all, fetch_by_id, insert_fn, update_fn, delete_fn, dropdown_fields=None):
        self.table_label = table_label
        self.pk_label = pk_label
        self.fields = fields
        self.fetch_all = fetch_all
        self.fetch_by_id = fetch_by_id
        self.insert_fn = insert_fn
        self.update_fn = update_fn
        self.delete_fn = delete_fn
        self.dropdown_fields = dropdown_fields or {}
        self.entries = {}
        self.combo_maps = {}
        self.editing_pk = None

        self._build(parent, tree_cols, tree_widths)
        self.refresh()

    def _build(self, parent, tree_cols, tree_widths):
        hdr = ctk.CTkFrame(parent, fg_color=C_SIDEBAR, height=35, corner_radius=0)
        hdr.pack(fill="x")
        ctk.CTkLabel(hdr, text=self.table_label, font=F_SUB, text_color="white").pack(side="left", padx=10)

        self.tree = make_treeview(parent, tree_cols, tree_widths)

        card = ctk.CTkFrame(parent, fg_color=C_CARD, corner_radius=12, border_width=1, border_color="#30363d")
        card.pack(fill="x", padx=PAD, pady=(0, PAD))

        pk_row = ctk.CTkFrame(card, fg_color="transparent")
        pk_row.pack(fill="x", padx=20, pady=(15, 10))
        ctk.CTkLabel(pk_row, text=self.pk_label, font=F_LABEL, width=120, anchor="w").pack(side="left")
        self.pk_entry = ctk.CTkEntry(pk_row, width=120)
        self.pk_entry.pack(side="left", padx=10)
        ctk.CTkButton(pk_row, text="🔍 Fetch Current Record", width=180, fg_color=C_SIDEBAR, command=self._on_fetch).pack(side="left")
        
        grid = ctk.CTkFrame(card, fg_color="transparent")
        grid.pack(fill="x", padx=20, pady=5)
        for idx, (label, key, _) in enumerate(self.fields):
            r, c = divmod(idx, 2)
            ctk.CTkLabel(grid, text=label, font=F_LABEL, width=120, anchor="w").grid(row=r, column=c*2, sticky="w", pady=4)
            if key in self.dropdown_fields:
                var = StringVar()
                cb = ctk.CTkComboBox(grid, variable=var, width=200, state="readonly")
                cb.grid(row=r, column=c*2+1, sticky="w", pady=4, padx=5)
                self.entries[key] = (var, cb)
            else:
                e = ctk.CTkEntry(grid, width=200)
                e.grid(row=r, column=c*2+1, sticky="w", pady=4, padx=5)
                self.entries[key] = e

        actions = ctk.CTkFrame(card, fg_color="transparent")
        actions.pack(fill="x", padx=20, pady=(10, 20))
        ctk.CTkButton(actions, text="➕ Create New", fg_color="#1e3a8a", command=self._on_insert).pack(side="left", padx=5)
        ctk.CTkButton(actions, text="💾 Save Updates", fg_color="#3730a3", command=self._on_update).pack(side="left", padx=5)
        ctk.CTkButton(actions, text="🗑️ Delete", fg_color="#991b1b", command=self._on_delete).pack(side="left", padx=5)
        ctk.CTkButton(actions, text="🔄 Refresh Table", fg_color="#334155", command=self.refresh).pack(side="right", padx=5)

    def _load_dropdowns(self):
        for key, loader in self.dropdown_fields.items():
            try:
                opts = loader()
                self.combo_maps[key] = {t: i for i, t in opts}
                if key in self.entries:
                    self.entries[key][1].configure(values=[t for _, t in opts])
            except Exception: pass

    def _get(self, key):
        w = self.entries.get(key)
        if isinstance(w, tuple): return self.combo_maps.get(key, {}).get(w[0].get())
        return w.get().strip()
    
    def _set(self, key, val):
        w = self.entries.get(key)
        if isinstance(w, tuple):
            rev = {v: k for k, v in self.combo_maps.get(key, {}).items()}
            w[0].set(rev.get(val, ""))
        else:
            w.delete(0, "end")
            w.insert(0, str(val) if val is not None else "")

    def refresh(self):
        self._load_dropdowns()
        for i in self.tree.get_children(): self.tree.delete(i)
        try:
            _, rows = self.fetch_all()
            for r in rows: self.tree.insert("", "end", values=r)
        except: pass

    def _on_fetch(self):
        i = self.pk_entry.get().strip()
        if not i: return
        r = self.fetch_by_id(int(i))
        if not r: messagebox.showwarning("Error", "ID not found!"); return
        self.editing_pk = int(i)
        for _, k, _ in self.fields: self._set(k, r.get(k))
        messagebox.showinfo("Loaded", "Record loaded for update.")

    def _on_insert(self):
        i = self.pk_entry.get().strip()
        if not i: return
        try:
            self.insert_fn(int(i), *[self._get(k) for _, k, _ in self.fields])
            self.refresh()
            messagebox.showinfo("Done", "Record created!")
        except Exception as e: messagebox.showerror("DB Error", str(e))

    def _on_update(self):
        i = self.pk_entry.get().strip()
        if self.editing_pk is None: messagebox.showwarning("Wait", "Fetch by ID first!"); return
        try:
            self.update_fn(int(i), *[self._get(k) for _, k, _ in self.fields])
            self.refresh()
            messagebox.showinfo("Done", "Record updated!")
        except Exception as e: messagebox.showerror("DB Error", str(e))

    def _on_delete(self):
        i = self.pk_entry.get().strip()
        if not i or not messagebox.askyesno("Confirm", "Delete this record?"): return
        try:
            self.delete_fn(int(i))
            self.refresh()
        except Exception as e: messagebox.showerror("DB Error", str(e))


# ═════════════════════════════════════════════════════════════════════
#  MAIN PAGES
# ═════════════════════════════════════════════════════════════════════
class WelcomePage(ctk.CTkFrame):
    def __init__(self, parent, controller):
        super().__init__(parent, fg_color=C_BG)
        self.controller = controller

        # Layout
        center = ctk.CTkFrame(self, fg_color="transparent")
        center.place(relx=0.5, rely=0.5, anchor="center")

        ctk.CTkLabel(center, text="🏥 VetCare Dashboard", font=F_HERO).pack(pady=10)
        ctk.CTkLabel(center, text="Mini-Project Stage 5 — Database GUI", font=F_SUB, text_color=C_MUTED).pack(pady=5)

        self.status = ctk.CTkLabel(center, text="Checking DB...", font=F_SMALL)
        self.status.pack(pady=20)

        nav = ctk.CTkFrame(center, fg_color="transparent")
        nav.pack(pady=10)
        ctk.CTkButton(nav, text="📋 Manage Tables", width=220, height=45, command=controller.show_crud).pack(pady=5)
        ctk.CTkButton(nav, text="📊 Reports & PL/SQL", width=220, height=45, fg_color=C_ACCENT2, command=controller.show_advanced).pack(pady=5)
        ctk.CTkButton(nav, text="⚙️ Settings", width=220, height=45, fg_color="#334155", command=lambda: controller.open_settings(self._update)).pack(pady=5)
        
        self._update()

    def _update(self):
        ok, err = db.test_connection()
        if ok: self.status.configure(text=f"Connected to {db.DB_CONFIG['dbname']} ✅", text_color=C_GREEN)
        else: self.status.configure(text=f"Auth Error: {err} ❌", text_color=C_ACCENT)

class CrudPage(ctk.CTkFrame):
    def __init__(self, parent, controller):
        super().__init__(parent, fg_color=C_BG)
        top = ctk.CTkFrame(self, fg_color=C_SIDEBAR, height=50, corner_radius=0)
        top.pack(fill="x")
        ctk.CTkButton(top, text="⬅ Back", width=80, command=controller._show_welcome).pack(side="left", padx=10)
        ctk.CTkLabel(top, text="Database CRUD Management", font=F_TITLE).pack(side="left", padx=20)

        tabs = ctk.CTkTabview(self)
        tabs.pack(fill="both", expand=True, padx=10, pady=10)

        self._animal(tabs.add("Animals"))
        self._vet(tabs.add("Vets"))
        self._visit(tabs.add("Visits"))
        self._more(tabs)

    def _animal(self, t):
        CrudTab(t, table_label="Animal Records", pk_label="AnimalID",
                fields=[("Name","name",""), ("Species","species",""), ("BirthDate","birthdate",""), ("Gender","gender",""), ("Weight","weight","")],
                tree_cols=("ID","Name","Species","Birth","Gender","Kg","V","Last"), tree_widths=[50,120,100,100,70,60,40,90],
                fetch_all=db.fetch_animals, fetch_by_id=db.fetch_animal_by_id,
                insert_fn=db.insert_animal, update_fn=db.update_animal, delete_fn=db.delete_animal)

    def _vet(self, t):
        CrudTab(t, table_label="Veterinarians", pk_label="VetID",
                fields=[("First","firstname",""), ("Last","lastname",""), ("License","licensenumber",""), ("Spec","specialization",""), ("Date","hiredate","")],
                tree_cols=("ID","First","Last","License","Spec","Hired","Emp"), tree_widths=[50,100,100,120,120,100,150],
                fetch_all=db.fetch_veterinarians, fetch_by_id=db.fetch_vet_by_id,
                insert_fn=db.insert_vet, update_fn=db.update_vet, delete_fn=db.delete_vet)

    def _visit(self, t):
        CrudTab(t, table_label="Visits (JOIN Resolving FK)", pk_label="VisitID",
                fields=[("Date","visitdate",""), ("Reason","reason",""), ("Summary","summary",""), ("Cost","cost",""), ("Animal","animalid",""), ("Vet","vetid",""), ("Status","status","")],
                tree_cols=("ID","Date","Animal","Vet","Reason","Smry","Cost","St"), tree_widths=[40,90,120,130,130,150,60,60],
                fetch_all=db.fetch_visits, fetch_by_id=db.fetch_visit_by_id,
                insert_fn=db.insert_visit, update_fn=db.update_visit, delete_fn=db.delete_visit,
                dropdown_fields={"animalid": db.get_animal_options, "vetid": db.get_vet_options})

    def _more(self, tabs):
        for name, lbl, pk, flds, fetch, get, ins, upd, dele in [
            ("Treatments", "Treatments", "T_ID", [("Desc","description",""),("Dur","duration",""),("Type","type",""),("Sev","severity","")], db.fetch_treatments, db.fetch_treatment_by_id, db.insert_treatment, db.update_treatment, db.delete_treatment),
            ("Meds", "Inventory", "M_ID", [("Name","commercialname",""),("Ingr","activeingredient",""),("Unit","dosageunit",""),("Exp","expirationdate","")], db.fetch_medications, db.fetch_medication_by_id, db.insert_medication, db.update_medication, db.delete_medication),
            ("Vax", "Vaccinations", "V_ID", [("Name","name",""),("Mfr","manufacturer",""),("Freq","frequencymonths",""),("Storage","storagetemp","")], db.fetch_vaccinations, db.fetch_vaccination_by_id, db.insert_vaccination, db.update_vaccination, db.delete_vaccination)
        ]:
            CrudTab(tabs.add(name), table_label=lbl, pk_label=pk, fields=flds, 
                    tree_cols=("ID","Col1","Col2","Col3","Col4"), tree_widths=[50,200,150,100,100],
                    fetch_all=fetch, fetch_by_id=get, insert_fn=ins, update_fn=upd, delete_fn=dele)

class AdvancedPage(ctk.CTkFrame):
    def __init__(self, parent, controller):
        super().__init__(parent, fg_color=C_BG)
        top = ctk.CTkFrame(self, fg_color=C_SIDEBAR, height=50, corner_radius=0)
        top.pack(fill="x")
        ctk.CTkButton(top, text="⬅ Back", width=80, command=controller._show_welcome).pack(side="left", padx=10)
        ctk.CTkLabel(top, text="Reports & Complex Programs", font=F_TITLE).pack(side="left", padx=20)

        t = ctk.CTkTabview(self)
        t.pack(fill="both", expand=True, padx=10, pady=10)

        # Stage 2 Queries
        q1 = t.add("Top 10 Animals")
        ctk.CTkLabel(q1, text="Simple Query 1: Activity Leaderboard").pack(pady=5)
        ctk.CTkButton(q1, text="Generate Activity Report", command=self._q1).pack(pady=5)
        self.tr1 = make_treeview(q1, ("ID","Name","Spec","Gen","Kg","Age","V","Last","Total","Avg"), [40,100,100,60,60,40,40,90,80,80])

        q2 = t.add("Revenue Breakdown")
        ctk.CTkLabel(q2, text="Double Query 4: Monthly Financials by Spec").pack(pady=5)
        ctk.CTkButton(q2, text="Calculate Revenue", command=self._q2).pack(pady=5)
        self.tr2 = make_treeview(q2, ("Year","Month","Specialization","Revenue","Visits","Avg"), [60,60,200,100,80,100])

        # Stage 4 Programs
        fn = t.add("Health Profile")
        ctk.CTkLabel(fn, text="Medical Summary Function").pack(pady=5)
        self.fid_e = ctk.CTkEntry(fn, placeholder_text="Animal ID")
        self.fid_e.pack(pady=5)
        ctk.CTkButton(fn, text="Get Summary", fg_color=C_GREEN, command=self._fn).pack(pady=5)
        self.txt = ctk.CTkTextbox(fn, height=200, font=F_MONO)
        self.txt.pack(fill="both", expand=True, padx=20, pady=10)

        sp = t.add("Vet Transfer")
        ctk.CTkLabel(sp, text="Procedure: Move Visit History").pack(pady=5)
        self.f_v = ctk.CTkEntry(sp, placeholder_text="From Vet ID")
        self.f_v.pack(pady=2)
        self.t_v = ctk.CTkEntry(sp, placeholder_text="To Vet ID")
        self.t_v.pack(pady=2)
        ctk.CTkButton(sp, text="Transfer Visits", fg_color=C_ACCENT, command=self._sp).pack(pady=10)

    def _q1(self):
        try:
            _, r = db.query_top10_most_visited_animals()
            for i in self.tr1.get_children(): self.tr1.delete(i)
            for row in r: self.tr1.insert("", "end", values=row)
        except: pass
    def _q2(self):
        try:
            _, r = db.query_monthly_revenue_by_specialization()
            for i in self.tr2.get_children(): self.tr2.delete(i)
            for row in r: self.tr2.insert("", "end", values=row)
        except: pass
    def _fn(self):
        aid = self.fid_e.get()
        if not aid: return
        try:
            r = db.call_animal_medical_summary(int(aid))
            self.txt.delete("1.0", "end")
            self.txt.insert("1.0", f"--- Medical Profile for Animal {aid} ---\n\nName: {r['o_animal_name']}\nTotal Visits: {r['o_total_visits']}\nCosts: {r['o_total_cost']}\nStatus: {r['o_health_status']}")
        except: pass
    def _sp(self):
        f, t = self.f_v.get(), self.t_v.get()
        if not f or not t or not messagebox.askyesno("Confirm", "Modifying DB! Proceed?"): return
        try:
            db.call_transfer_vet_visits(int(f), int(t))
            messagebox.showinfo("Done", "Visits transferred.")
        except: pass

class VetCareApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("VetCare GUI")
        self.geometry("1200x800")
        self.main = ctk.CTkFrame(self, fg_color="transparent")
        self.main.pack(fill="both", expand=True)
        self._show_welcome()
    def _clear(self):
        for w in self.main.winfo_children(): w.destroy()
    def _show_welcome(self):
        self._clear()
        WelcomePage(self.main, self).pack(fill="both", expand=True)
    def show_crud(self):
        self._clear()
        CrudPage(self.main, self).pack(fill="both", expand=True)
    def show_advanced(self):
        self._clear()
        AdvancedPage(self.main, self).pack(fill="both", expand=True)
    def open_settings(self, cb):
        SettingsDialog(self, cb)

if __name__ == "__main__":
    app = VetCareApp()
    app.mainloop()
