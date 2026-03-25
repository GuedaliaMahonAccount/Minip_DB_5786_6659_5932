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
ctk.set_default_color_theme("blue")

# ── Color palette ────────────────────────────────────────────────────
C_BG       = "#1a1a2e"   # page background
C_CARD     = "#16213e"   # card / panel background
C_SIDEBAR  = "#0f3460"   # sidebar / header gradient
C_ACCENT   = "#e94560"   # primary accent (coral-red)
C_ACCENT2  = "#533483"   # secondary accent (purple)
C_GREEN    = "#2ecc71"
C_YELLOW   = "#f39c12"
C_TEXT     = "#e0e0e0"
C_MUTED    = "#888"

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
    """Modal dialog for editing DB connection parameters."""
    def __init__(self, parent, on_save):
        super().__init__(parent)
        self.title("⚙️  Database Connection Settings")
        self.geometry("460x340")
        self.resizable(False, False)
        self.grab_set()
        self.on_save = on_save

        ctk.CTkLabel(self, text="Database Connection",
                     font=F_TITLE).pack(pady=(20, 4))
        ctk.CTkLabel(self, text="Edit your PostgreSQL credentials below",
                     font=F_SMALL, text_color=C_MUTED).pack(pady=(0, 16))

        form = ctk.CTkFrame(self)
        form.pack(fill="x", padx=30)

        fields = [
            ("Host", "host", db.DB_CONFIG["host"]),
            ("Port", "port", str(db.DB_CONFIG["port"])),
            ("Database", "dbname", db.DB_CONFIG["dbname"]),
            ("User", "user", db.DB_CONFIG["user"]),
            ("Password", "password", db.DB_CONFIG["password"]),
        ]
        self.entries = {}
        for label, key, default in fields:
            row = ctk.CTkFrame(form, fg_color="transparent")
            row.pack(fill="x", pady=3)
            ctk.CTkLabel(row, text=label, font=F_LABEL, width=90, anchor="w").pack(side="left")
            entry = ctk.CTkEntry(row, font=F_ENTRY, width=280,
                                  show="*" if key == "password" else "")
            entry.insert(0, default)
            entry.pack(side="left")
            self.entries[key] = entry

        btn_row = ctk.CTkFrame(self, fg_color="transparent")
        btn_row.pack(pady=18)
        ctk.CTkButton(btn_row, text="💾 Save & Connect", font=F_BTN,
                       fg_color=C_ACCENT, hover_color="#c0392b",
                       command=self._save).pack(side="left", padx=8)
        ctk.CTkButton(btn_row, text="Cancel", font=F_BTN,
                       fg_color="#444", hover_color="#666",
                       command=self.destroy).pack(side="left", padx=8)

    def _save(self):
        for key, entry in self.entries.items():
            val = entry.get().strip()
            if key == "port":
                db.DB_CONFIG[key] = int(val) if val.isdigit() else 5432
            else:
                db.DB_CONFIG[key] = val
        ok, err = db.test_connection()
        if ok:
            messagebox.showinfo("Connected ✅", "Connection successful!")
            self.on_save()
            self.destroy()
        else:
            messagebox.showerror("Connection Failed ❌", err)


# ═════════════════════════════════════════════════════════════════════
#  STYLED TREEVIEW HELPER
# ═════════════════════════════════════════════════════════════════════
def make_treeview(parent, columns, widths=None):
    """Dark-themed ttk.Treeview with scrollbars."""
    style = ttk.Style()
    style.theme_use("clam")
    style.configure("Vc.Treeview",
                    background="#1e1e2e", foreground=C_TEXT,
                    fieldbackground="#1e1e2e", rowheight=26,
                    font=F_SMALL, borderwidth=0)
    style.configure("Vc.Treeview.Heading",
                    background=C_SIDEBAR, foreground="white",
                    font=("Segoe UI", 11, "bold"), relief="flat")
    style.map("Vc.Treeview",
              background=[("selected", C_ACCENT)],
              foreground=[("selected", "white")])

    wrapper = ctk.CTkFrame(parent, fg_color="#1e1e2e", corner_radius=8)
    wrapper.pack(fill="both", expand=True, padx=PAD, pady=(0, PAD))

    tree = ttk.Treeview(wrapper, columns=columns, show="headings",
                         style="Vc.Treeview", selectmode="browse")
    vsb = ttk.Scrollbar(wrapper, orient="vertical",   command=tree.yview)
    hsb = ttk.Scrollbar(wrapper, orient="horizontal", command=tree.xview)
    tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

    for i, col in enumerate(columns):
        w = widths[i] if widths and i < len(widths) else 120
        tree.heading(col, text=col)
        tree.column(col, width=w, minwidth=50, stretch=False)

    tree.grid(row=0, column=0, sticky="nsew")
    vsb.grid(row=0, column=1, sticky="ns")
    hsb.grid(row=1, column=0, sticky="ew")
    wrapper.rowconfigure(0, weight=1)
    wrapper.columnconfigure(0, weight=1)
    return tree


# ═════════════════════════════════════════════════════════════════════
#  GENERIC CRUD TAB
# ═════════════════════════════════════════════════════════════════════
class CrudTab:
    """Reusable CRUD panel for one database entity."""

    def __init__(self, parent, *, table_label, pk_label,
                 fields, tree_cols, tree_widths,
                 fetch_all, fetch_by_id,
                 insert_fn, update_fn, delete_fn,
                 dropdown_fields=None):
        self.table_label    = table_label
        self.pk_label       = pk_label
        self.fields         = fields           # [(label, db_key, default), ...]
        self.fetch_all      = fetch_all
        self.fetch_by_id    = fetch_by_id
        self.insert_fn      = insert_fn
        self.update_fn      = update_fn
        self.delete_fn      = delete_fn
        self.dropdown_fields = dropdown_fields or {}
        self.entries        = {}
        self.combo_maps     = {}
        self.editing_pk     = None

        self._build(parent, tree_cols, tree_widths)
        self.refresh()

    # ── Build UI ─────────────────────────────────────────────────────
    def _build(self, parent, tree_cols, tree_widths):
        # Header
        hdr = ctk.CTkFrame(parent, fg_color=C_SIDEBAR, corner_radius=0)
        hdr.pack(fill="x")
        ctk.CTkLabel(hdr, text=f"  {self.table_label}",
                     font=F_SUB, text_color="white").pack(
            side="left", pady=8, padx=12)

        # Treeview
        self.tree = make_treeview(parent, tree_cols, tree_widths)

        # ── Form card ────────────────────────────────────────────────
        card = ctk.CTkFrame(parent, fg_color=C_CARD, corner_radius=10)
        card.pack(fill="x", padx=PAD, pady=(0, PAD))

        # PK row
        pk_row = ctk.CTkFrame(card, fg_color="transparent")
        pk_row.pack(fill="x", padx=PAD, pady=(10, 4))
        ctk.CTkLabel(pk_row, text=self.pk_label,
                     font=F_LABEL, text_color=C_MUTED, width=130, anchor="w").pack(side="left")
        self.pk_entry = ctk.CTkEntry(pk_row, font=F_ENTRY, width=100,
                                      border_color=C_ACCENT, border_width=1)
        self.pk_entry.pack(side="left", padx=(0, 8))
        ctk.CTkButton(pk_row, text="🔍 Fetch by ID", width=130, font=F_BTN,
                       fg_color=C_ACCENT2, hover_color="#6a4aaa",
                       command=self._on_fetch).pack(side="left", padx=(0, 6))
        ctk.CTkButton(pk_row, text="✖ Clear", width=80, font=F_BTN,
                       fg_color="#3a3a4a", hover_color="#555",
                       command=self._clear).pack(side="left")

        # Field grid (2 columns)
        grid = ctk.CTkFrame(card, fg_color="transparent")
        grid.pack(fill="x", padx=PAD, pady=4)

        for idx, (label, key, default) in enumerate(self.fields):
            r, c = divmod(idx, 2)
            ctk.CTkLabel(grid, text=label, font=F_LABEL,
                         text_color=C_MUTED, width=130, anchor="w").grid(
                row=r, column=c * 2, sticky="w", padx=6, pady=3)

            if key in self.dropdown_fields:
                var = StringVar()
                combo = ctk.CTkComboBox(grid, variable=var, width=190,
                                         font=F_ENTRY, state="readonly",
                                         border_color=C_ACCENT, border_width=1)
                combo.grid(row=r, column=c * 2 + 1, padx=6, pady=3, sticky="w")
                self.entries[key] = (var, combo)
            else:
                e = ctk.CTkEntry(grid, font=F_ENTRY, width=190,
                                  border_color="#3a3a5a", border_width=1)
                if default:
                    e.insert(0, default)
                e.grid(row=r, column=c * 2 + 1, padx=6, pady=3, sticky="w")
                self.entries[key] = e

        # Action buttons
        btns = ctk.CTkFrame(card, fg_color="transparent")
        btns.pack(fill="x", padx=PAD, pady=(6, 12))

        btn_cfg = [
            ("➕ Add New",       "#1a7a3a", "#27ae60", self._on_insert),
            ("💾 Save / Update", "#154a80", "#1f6aa5", self._on_update),
            ("🗑️ Delete",        "#7a1a1a", "#c0392b", self._on_delete),
        ]
        for text, fg, hover, cmd in btn_cfg:
            ctk.CTkButton(btns, text=text, font=F_BTN, width=145,
                           fg_color=fg, hover_color=hover,
                           command=cmd).pack(side="left", padx=5)
        ctk.CTkButton(btns, text="🔄 Refresh", font=F_BTN, width=110,
                       fg_color="#2a2a3a", hover_color="#3a3a5a",
                       command=self.refresh).pack(side="right", padx=5)

    # ── Helpers ──────────────────────────────────────────────────────
    def _load_dropdowns(self):
        for key, loader in self.dropdown_fields.items():
            try:
                options = loader()
                mapping = {txt: oid for oid, txt in options}
                display = [txt for _, txt in options]
                self.combo_maps[key] = mapping
                if key in self.entries:
                    _, combo = self.entries[key]
                    combo.configure(values=display)
            except Exception:
                pass

    def _get(self, key):
        w = self.entries.get(key)
        if isinstance(w, tuple):
            var, _ = w
            return self.combo_maps.get(key, {}).get(var.get(), var.get())
        return w.get().strip() if w else ""

    def _set(self, key, val):
        w = self.entries.get(key)
        if isinstance(w, tuple):
            var, _ = w
            rev = {v: k for k, v in self.combo_maps.get(key, {}).items()}
            var.set(rev.get(val, str(val) if val else ""))
        else:
            w.delete(0, "end")
            w.insert(0, "" if val is None else str(val))

    def _clear(self):
        self.pk_entry.delete(0, "end")
        for _, key, _ in self.fields:
            self._set(key, "")
        self.editing_pk = None

    def refresh(self):
        self._load_dropdowns()
        for item in self.tree.get_children():
            self.tree.delete(item)
        try:
            _, rows = self.fetch_all()
            for row in rows:
                self.tree.insert("", "end", values=row)
        except Exception as e:
            messagebox.showerror("DB Error", str(e))

    # ── CRUD ─────────────────────────────────────────────────────────
    def _on_fetch(self):
        pk = self.pk_entry.get().strip()
        if not pk:
            messagebox.showwarning("Required", f"Enter {self.pk_label} first."); return
        try:
            rec = self.fetch_by_id(int(pk))
        except Exception as e:
            messagebox.showerror("Error", str(e)); return
        if not rec:
            messagebox.showinfo("Not Found", f"No record with {self.pk_label} = {pk}"); return
        self.editing_pk = int(pk)
        for _, key, _ in self.fields:
            self._set(key, rec.get(key))
        messagebox.showinfo("✅ Loaded",
                            f"Record loaded. Edit fields then click 'Save / Update'.")

    def _on_insert(self):
        pk = self.pk_entry.get().strip()
        if not pk:
            messagebox.showwarning("Required", f"Enter a new {self.pk_label}."); return
        vals = [int(pk)] + [self._get(key) for _, key, _ in self.fields]
        try:
            self.insert_fn(*vals)
            messagebox.showinfo("✅ Added", "Record added successfully!")
            self.refresh(); self._clear()
        except Exception as e:
            messagebox.showerror("Insert Error", str(e))

    def _on_update(self):
        pk = self.pk_entry.get().strip()
        if not pk:
            messagebox.showwarning("Required", f"Enter {self.pk_label}."); return
        if self.editing_pk is None:
            messagebox.showwarning("Fetch First",
                                   "Click '🔍 Fetch by ID' before updating.\n"
                                   "This loads the current record so you can edit it."); return
        vals = [int(pk)] + [self._get(key) for _, key, _ in self.fields]
        try:
            self.update_fn(*vals)
            messagebox.showinfo("✅ Updated", "Record updated!")
            self.refresh(); self.editing_pk = None
        except Exception as e:
            messagebox.showerror("Update Error", str(e))

    def _on_delete(self):
        pk = self.pk_entry.get().strip()
        if not pk:
            messagebox.showwarning("Required", f"Enter {self.pk_label}."); return
        if not messagebox.askyesno("⚠️ Confirm",
                                   f"Delete record {self.pk_label} = {pk}?\n"
                                   "This cannot be undone."): return
        try:
            self.delete_fn(int(pk))
            messagebox.showinfo("Deleted", "Record deleted.")
            self.refresh(); self._clear()
        except Exception as e:
            messagebox.showerror("Delete Error", str(e))


# ═════════════════════════════════════════════════════════════════════
#  APP SHELL
# ═════════════════════════════════════════════════════════════════════
class VetCareApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("🐾  VetCare Management System — Stage 5")
        self.geometry("1300x840")
        self.minsize(1100, 720)
        self.configure(fg_color=C_BG)

        self.main = ctk.CTkFrame(self, fg_color=C_BG, corner_radius=0)
        self.main.pack(fill="both", expand=True)
        self.main.rowconfigure(0, weight=1)
        self.main.columnconfigure(0, weight=1)

        self._show_welcome()

    def _clear(self):
        for w in self.main.winfo_children():
            w.destroy()

    def _show_welcome(self):
        self._clear()
        WelcomePage(self.main, self).grid(row=0, column=0, sticky="nsew")

    def show_crud(self):
        self._clear()
        CrudPage(self.main, self).grid(row=0, column=0, sticky="nsew")

    def show_advanced(self):
        self._clear()
        AdvancedPage(self.main, self).grid(row=0, column=0, sticky="nsew")

    def open_settings(self, callback=None):
        def on_save():
            if callback:
                callback()
            else:
                self._show_welcome()   # re-check DB status
        SettingsDialog(self, on_save)


# ═════════════════════════════════════════════════════════════════════
#  WELCOME PAGE
# ═════════════════════════════════════════════════════════════════════
class WelcomePage(ctk.CTkFrame):
    def __init__(self, parent, controller):
        super().__init__(parent, fg_color=C_BG, corner_radius=0)
        self.controller = controller

        # ── Decorative sidebar strip ─────────────────────────────────
        sidebar = ctk.CTkFrame(self, fg_color=C_SIDEBAR, width=8, corner_radius=0)
        sidebar.pack(side="left", fill="y")

        # ── Center content ───────────────────────────────────────────
        center = ctk.CTkFrame(self, fg_color="transparent")
        center.place(relx=0.5, rely=0.46, anchor="center")

        ctk.CTkLabel(center, text="🐾", font=("Segoe UI Emoji", 72)).pack()
        ctk.CTkLabel(center, text="VetCare Management System",
                     font=F_HERO, text_color=C_TEXT).pack(pady=(6, 2))
        ctk.CTkLabel(center, text="Veterinary Clinic & HR Database — Stage 5",
                     font=("Segoe UI", 15), text_color=C_MUTED).pack()
        ctk.CTkLabel(center,
                     text="Avinoam Muller  (347465932)   ·   Guedalia Sebbah  (337966659)",
                     font=F_SMALL, text_color="#555").pack(pady=(4, 32))

        # Divider
        div = ctk.CTkFrame(center, height=2, fg_color=C_ACCENT, width=420)
        div.pack(pady=(0, 28))

        # Navigation buttons
        for text, color, hover, cmd in [
            ("📋   Data Management  (CRUD)",
             C_SIDEBAR, "#1a4a80", controller.show_crud),
            ("📊   Advanced Reports & Actions",
             C_ACCENT2, "#6a4aaa", controller.show_advanced),
            ("⚙️   Connection Settings",
             "#2a2a3a", "#404058", lambda: controller.open_settings(self._recheck)),
            ("🚪   Exit",
             "#2a1a1a", "#4a2020", controller.quit),
        ]:
            ctk.CTkButton(center, text=text, font=("Segoe UI", 15, "bold"),
                           width=340, height=52, corner_radius=10,
                           fg_color=color, hover_color=hover,
                           command=cmd).pack(pady=6)

        # DB status bar
        self.status = ctk.CTkLabel(self, text="", font=F_SMALL)
        self.status.place(relx=0.5, rely=0.94, anchor="center")
        self._recheck()

    def _recheck(self):
        ok, err = db.test_connection()
        if ok:
            self.status.configure(
                text=f"✅  Connected to {db.DB_CONFIG['dbname']}  "
                     f"@ {db.DB_CONFIG['host']}:{db.DB_CONFIG['port']}",
                text_color=C_GREEN)
        else:
            self.status.configure(
                text=f"❌  {err}   —  click ⚙️ Settings to fix",
                text_color=C_ACCENT)


# ═════════════════════════════════════════════════════════════════════
#  CRUD PAGE
# ═════════════════════════════════════════════════════════════════════
class CrudPage(ctk.CTkFrame):
    def __init__(self, parent, controller):
        super().__init__(parent, fg_color=C_BG, corner_radius=0)
        self.controller = controller

        # Top bar
        bar = ctk.CTkFrame(self, fg_color=C_CARD, corner_radius=0, height=50)
        bar.pack(fill="x")
        bar.pack_propagate(False)
        ctk.CTkButton(bar, text="⬅  Home", font=F_BTN, width=110,
                       fg_color="transparent", hover_color="#2a2a3a",
                       command=controller._show_welcome).pack(side="left", padx=10, pady=8)
        ctk.CTkLabel(bar, text="📋  Data Management", font=F_TITLE,
                     text_color=C_TEXT).pack(side="left", padx=16)

        # Tabview
        tabs = ctk.CTkTabview(self, fg_color=C_BG, segmented_button_fg_color=C_CARD,
                               segmented_button_selected_color=C_ACCENT,
                               segmented_button_unselected_hover_color="#2a2a3a")
        tabs.pack(fill="both", expand=True, padx=PAD, pady=PAD)

        self._animal(tabs.add("🐾 Animals"))
        self._vet(tabs.add("👨‍⚕️ Veterinarians"))
        self._visit(tabs.add("🏥 Medical Visits"))
        self._treatment(tabs.add("💊 Treatments"))
        self._medication(tabs.add("💉 Medications"))
        self._vaccination(tabs.add("🛡️ Vaccinations"))

    def _animal(self, tab):
        CrudTab(tab,
                table_label="Animal Records",
                pk_label="AnimalID",
                fields=[("Name", "name", ""), ("Species", "species", ""),
                        ("Birth Date (YYYY-MM-DD)", "birthdate", ""),
                        ("Gender", "gender", ""), ("Weight (kg)", "weight", "")],
                tree_cols=("ID","Name","Species","BirthDate","Gender","Weight(kg)","Visits","LastVisit"),
                tree_widths=[55,130,110,100,75,80,65,100],
                fetch_all=db.fetch_animals, fetch_by_id=db.fetch_animal_by_id,
                insert_fn=db.insert_animal, update_fn=db.update_animal,
                delete_fn=db.delete_animal)

    def _vet(self, tab):
        CrudTab(tab,
                table_label="Veterinarian Records",
                pk_label="VetID",
                fields=[("First Name", "firstname", ""), ("Last Name", "lastname", ""),
                        ("License #", "licensenumber", ""),
                        ("Specialization", "specialization", ""),
                        ("Hire Date (YYYY-MM-DD)", "hiredate", "")],
                tree_cols=("ID","FirstName","LastName","License","Specialization","Hired","Employee"),
                tree_widths=[55,100,100,130,130,100,160],
                fetch_all=db.fetch_veterinarians, fetch_by_id=db.fetch_vet_by_id,
                insert_fn=db.insert_vet, update_fn=db.update_vet,
                delete_fn=db.delete_vet)

    def _visit(self, tab):
        CrudTab(tab,
                table_label="Medical Visit Records  (Animal & Vet shown by Name — no raw IDs)",
                pk_label="VisitID",
                fields=[("Visit Date (YYYY-MM-DD)", "visitdate", ""),
                        ("Reason", "reason", ""),
                        ("Summary", "summary", ""),
                        ("Cost (₪)", "cost", ""),
                        ("Animal →", "animalid", ""),
                        ("Veterinarian →", "vetid", ""),
                        ("Status", "status", "Completed")],
                tree_cols=("ID","Date","Animal","Veterinarian","Reason","Summary","Cost","Status"),
                tree_widths=[55,100,140,160,160,170,80,90],
                fetch_all=db.fetch_visits, fetch_by_id=db.fetch_visit_by_id,
                insert_fn=db.insert_visit, update_fn=db.update_visit,
                delete_fn=db.delete_visit,
                dropdown_fields={"animalid": db.get_animal_options,
                                  "vetid":    db.get_vet_options})

    def _treatment(self, tab):
        CrudTab(tab,
                table_label="Treatment Catalog",
                pk_label="TreatmentID",
                fields=[("Description", "description", ""), ("Duration", "duration", ""),
                        ("Type", "type", ""), ("Severity", "severity", "")],
                tree_cols=("ID","Description","Duration","Type","Severity"),
                tree_widths=[55,240,100,100,100],
                fetch_all=db.fetch_treatments, fetch_by_id=db.fetch_treatment_by_id,
                insert_fn=db.insert_treatment, update_fn=db.update_treatment,
                delete_fn=db.delete_treatment)

    def _medication(self, tab):
        CrudTab(tab,
                table_label="Medication Inventory",
                pk_label="MedID",
                fields=[("Commercial Name", "commercialname", ""),
                        ("Active Ingredient", "activeingredient", ""),
                        ("Dosage Unit", "dosageunit", ""),
                        ("Expiration Date (YYYY-MM-DD)", "expirationdate", "")],
                tree_cols=("ID","Commercial Name","Active Ingredient","Dosage","Expiration"),
                tree_widths=[55,190,190,100,110],
                fetch_all=db.fetch_medications, fetch_by_id=db.fetch_medication_by_id,
                insert_fn=db.insert_medication, update_fn=db.update_medication,
                delete_fn=db.delete_medication)

    def _vaccination(self, tab):
        CrudTab(tab,
                table_label="Vaccination Catalog",
                pk_label="VacID",
                fields=[("Name", "name", ""), ("Manufacturer", "manufacturer", ""),
                        ("Frequency (months)", "frequencymonths", ""),
                        ("Storage Temp", "storagetemp", "")],
                tree_cols=("ID","Name","Manufacturer","Frequency(mo)","StorageTemp"),
                tree_widths=[55,160,160,110,120],
                fetch_all=db.fetch_vaccinations, fetch_by_id=db.fetch_vaccination_by_id,
                insert_fn=db.insert_vaccination, update_fn=db.update_vaccination,
                delete_fn=db.delete_vaccination)


# ═════════════════════════════════════════════════════════════════════
#  ADVANCED REPORTS PAGE
# ═════════════════════════════════════════════════════════════════════
class AdvancedPage(ctk.CTkFrame):
    def __init__(self, parent, controller):
        super().__init__(parent, fg_color=C_BG, corner_radius=0)

        # Top bar
        bar = ctk.CTkFrame(self, fg_color=C_CARD, corner_radius=0, height=50)
        bar.pack(fill="x")
        bar.pack_propagate(False)
        ctk.CTkButton(bar, text="⬅  Home", font=F_BTN, width=110,
                       fg_color="transparent", hover_color="#2a2a3a",
                       command=controller._show_welcome).pack(side="left", padx=10, pady=8)
        ctk.CTkLabel(bar, text="📊  Advanced Reports & Actions", font=F_TITLE,
                     text_color=C_TEXT).pack(side="left", padx=16)

        tabs = ctk.CTkTabview(self, fg_color=C_BG,
                               segmented_button_fg_color=C_CARD,
                               segmented_button_selected_color=C_ACCENT2,
                               segmented_button_unselected_hover_color="#2a2a3a")
        tabs.pack(fill="both", expand=True, padx=PAD, pady=PAD)

        self._build_top10(tabs.add("🏆 Top 10 Animals"))
        self._build_revenue(tabs.add("💰 Revenue Report"))
        self._build_summary(tabs.add("🔬 Animal Summary"))
        self._build_transfer(tabs.add("🔄 Transfer Visits"))

    # ── Query 1 ──────────────────────────────────────────────────────
    def _build_top10(self, tab):
        ctk.CTkLabel(tab, font=F_SUB, text_color=C_YELLOW,
                     text="Stage 2 · Simple Query 1 — Top 10 Most Visited Animals").pack(
            anchor="w", padx=PAD, pady=(PAD, 4))
        ctk.CTkLabel(tab, font=F_SMALL, text_color=C_MUTED,
                     text="Aggregates visit count, total cost, and average cost per animal.").pack(
            anchor="w", padx=PAD)
        ctk.CTkButton(tab, text="▶  Run Query", font=F_BTN, width=200, height=38,
                       fg_color=C_ACCENT2, hover_color="#6a4aaa",
                       command=self._run_q1).pack(pady=8)
        cols = ("ID","Name","Species","Gender","Weight","Age","Visits","Last Visit","Total Cost","Avg Cost")
        self.q1_tree = make_treeview(tab, cols, [55,120,110,70,70,50,65,105,105,90])

    def _run_q1(self):
        for i in self.q1_tree.get_children(): self.q1_tree.delete(i)
        try:
            _, rows = db.query_top10_most_visited_animals()
            for r in rows: self.q1_tree.insert("", "end", values=r)
        except Exception as e:
            messagebox.showerror("Error", str(e))

    # ── Query 2 ──────────────────────────────────────────────────────
    def _build_revenue(self, tab):
        ctk.CTkLabel(tab, font=F_SUB, text_color=C_YELLOW,
                     text="Stage 2 · Double Query 4 (CTE) — Monthly Revenue by Specialization").pack(
            anchor="w", padx=PAD, pady=(PAD, 4))
        ctk.CTkLabel(tab, font=F_SMALL, text_color=C_MUTED,
                     text="Groups revenue and visit count per month per vet specialization.").pack(
            anchor="w", padx=PAD)
        ctk.CTkButton(tab, text="▶  Run Query", font=F_BTN, width=200, height=38,
                       fg_color=C_ACCENT2, hover_color="#6a4aaa",
                       command=self._run_q2).pack(pady=8)
        cols = ("Year","Month","Specialization","Revenue","Visits","Avg Cost")
        self.q2_tree = make_treeview(tab, cols, [70,70,170,120,80,100])

    def _run_q2(self):
        for i in self.q2_tree.get_children(): self.q2_tree.delete(i)
        try:
            _, rows = db.query_monthly_revenue_by_specialization()
            for r in rows: self.q2_tree.insert("", "end", values=r)
        except Exception as e:
            messagebox.showerror("Error", str(e))

    # ── Function ─────────────────────────────────────────────────────
    def _build_summary(self, tab):
        ctk.CTkLabel(tab, font=F_SUB, text_color=C_YELLOW,
                     text="Stage 4 · Function — fn_get_animal_medical_summary( animal_id )").pack(
            anchor="w", padx=PAD, pady=(PAD, 4))
        ctk.CTkLabel(tab, font=F_SMALL, text_color=C_MUTED,
                     text="Returns total visits, costs, last visit date, and health status label.").pack(
            anchor="w", padx=PAD)

        inp = ctk.CTkFrame(tab, fg_color="transparent")
        inp.pack(fill="x", padx=PAD, pady=8)
        ctk.CTkLabel(inp, text="Animal ID:", font=F_LABEL).pack(side="left")
        self.fn_id = ctk.CTkEntry(inp, font=F_ENTRY, width=90,
                                   border_color=C_ACCENT, border_width=1)
        self.fn_id.pack(side="left", padx=8)
        ctk.CTkButton(inp, text="▶  Execute Function", font=F_BTN, width=200,
                       fg_color="#1a6a35", hover_color="#27ae60",
                       command=self._run_fn).pack(side="left")

        self.fn_out = ctk.CTkTextbox(tab, font=F_MONO,
                                      fg_color="#0d0d1a", text_color=C_GREEN,
                                      border_color=C_ACCENT2, border_width=1,
                                      state="disabled")
        self.fn_out.pack(fill="both", expand=True, padx=PAD, pady=(0, PAD))

    def _run_fn(self):
        aid = self.fn_id.get().strip()
        if not aid:
            messagebox.showwarning("Required", "Enter an Animal ID."); return
        try:
            r = db.call_animal_medical_summary(int(aid))
            if not r:
                messagebox.showinfo("Not Found", f"No animal with ID {aid}"); return
            out = (
                f"{'═'*48}\n"
                f"  Animal Medical Summary  (ID: {aid})\n"
                f"{'═'*48}\n\n"
                f"  Name            :  {r.get('o_animal_name', '—')}\n"
                f"  Species         :  {r.get('o_species', '—')}\n"
                f"  Total Visits    :  {r.get('o_total_visits', 0)}\n"
                f"  Total Cost      :  ₪ {float(r.get('o_total_cost', 0)):,.2f}\n"
                f"  Average Cost    :  ₪ {float(r.get('o_avg_cost', 0)):,.2f}\n"
                f"  Last Visit      :  {r.get('o_last_visit', '—')}\n"
                f"  Health Status   :  {r.get('o_health_status', '—')}\n\n"
                f"{'═'*48}\n"
            )
            self.fn_out.configure(state="normal")
            self.fn_out.delete("1.0", "end")
            self.fn_out.insert("1.0", out)
            self.fn_out.configure(state="disabled")
        except Exception as e:
            messagebox.showerror("Error", str(e))

    # ── Procedure ────────────────────────────────────────────────────
    def _build_transfer(self, tab):
        ctk.CTkLabel(tab, font=F_SUB, text_color=C_YELLOW,
                     text="Stage 4 · Procedure — sp_transfer_animal_visits( from_id, to_id )").pack(
            anchor="w", padx=PAD, pady=(PAD, 4))

        warn = ctk.CTkFrame(tab, fg_color="#2a1800", corner_radius=8)
        warn.pack(fill="x", padx=PAD, pady=(0, 8))
        ctk.CTkLabel(warn, font=F_SMALL, text_color=C_YELLOW,
                     text="⚠️  This moves ALL medical visits from one veterinarian to another.\n"
                          "    A confirmation dialog will appear before execution.").pack(
            anchor="w", padx=12, pady=8)

        inp = ctk.CTkFrame(tab, fg_color="transparent")
        inp.pack(fill="x", padx=PAD, pady=8)
        ctk.CTkLabel(inp, text="From Vet ID:", font=F_LABEL).pack(side="left")
        self.sp_from = ctk.CTkEntry(inp, font=F_ENTRY, width=80,
                                     border_color=C_ACCENT, border_width=1)
        self.sp_from.pack(side="left", padx=(6, 20))
        ctk.CTkLabel(inp, text="To Vet ID:", font=F_LABEL).pack(side="left")
        self.sp_to = ctk.CTkEntry(inp, font=F_ENTRY, width=80,
                                   border_color=C_ACCENT, border_width=1)
        self.sp_to.pack(side="left", padx=(6, 20))
        ctk.CTkButton(inp, text="▶  Execute Procedure", font=F_BTN, width=200,
                       fg_color=C_ACCENT, hover_color="#c0392b",
                       command=self._run_sp).pack(side="left")

        self.sp_out = ctk.CTkTextbox(tab, font=F_MONO,
                                      fg_color="#0d0d1a", text_color=C_TEXT,
                                      border_color=C_ACCENT2, border_width=1,
                                      state="disabled")
        self.sp_out.pack(fill="both", expand=True, padx=PAD, pady=(0, PAD))

    def _run_sp(self):
        fid = self.sp_from.get().strip()
        tid = self.sp_to.get().strip()
        if not fid or not tid:
            messagebox.showwarning("Required", "Enter both Vet IDs."); return
        if not messagebox.askyesno("⚠️ Confirm",
                                   f"Transfer ALL visits from Vet {fid} → Vet {tid}?\n\n"
                                   "This modifies the database."): return
        try:
            db.call_transfer_vet_visits(int(fid), int(tid))
            out = (f"{'═'*48}\n  ✅  Transfer Completed Successfully\n{'═'*48}\n\n"
                   f"  From Vet ID  :  {fid}\n  To Vet ID    :  {tid}\n\n"
                   f"  All visits transferred and audit log updated.\n{'═'*48}\n")
            self.sp_out.configure(state="normal")
            self.sp_out.delete("1.0", "end")
            self.sp_out.insert("1.0", out)
            self.sp_out.configure(state="disabled")
        except Exception as e:
            messagebox.showerror("Procedure Error", str(e))


# ═════════════════════════════════════════════════════════════════════
#  LAUNCH
# ═════════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    app = VetCareApp()
    app.mainloop()
