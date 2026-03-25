"""
app.py – VetCare Management System – Stage 5 GUI
=================================================
Premium dark dashboard UI — CustomTkinter + psycopg2
Team: Avinoam Muller (347465932) · Guedalia Sebbah (337966659)
"""

import customtkinter as ctk
from tkinter import ttk, messagebox, StringVar
import db

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("dark-blue")

# ══════════════════════════════════════════════════════════════════════
#  DESIGN SYSTEM
# ══════════════════════════════════════════════════════════════════════

# Backgrounds — depth layers (darkest → lightest)
C_BASE      = "#060a13"   # window / page background
C_SURFACE   = "#0d1526"   # cards, panels
C_RAISED    = "#111e35"   # inputs, secondary cards
C_HOVER_BG  = "#162040"   # hover state
C_BORDER    = "#1c2d4a"   # subtle borders
C_DIVIDER   = "#0f1e38"   # section separators

# Brand / Accent
C_PRIMARY   = "#6366f1"   # indigo – main CTA
C_PRIMARY_H = "#4f46e5"   # indigo hover
C_VIOLET    = "#8b5cf6"   # soft violet – secondary
C_VIOLET_H  = "#7c3aed"
C_TEAL      = "#14b8a6"   # teal – tertiary

# Semantic
C_SUCCESS   = "#10b981"   # emerald
C_SUCCESS_H = "#059669"
C_DANGER    = "#f43f5e"   # rose
C_DANGER_H  = "#e11d48"
C_WARNING   = "#f59e0b"   # amber
C_INFO      = "#38bdf8"   # sky

# Text
C_TEXT      = "#f1f5f9"   # primary
C_SUBTLE    = "#8b9ab0"   # secondary
C_DIM       = "#3d5173"   # very dim

# Tree-specific
C_TREE_BG   = "#040810"
C_TREE_ODD  = "#07101f"
C_TREE_HEAD = "#0d1526"

# ── Fonts ──────────────────────────────────────────────────────────
F_HERO   = ("Segoe UI", 36, "bold")
F_TITLE  = ("Segoe UI", 19, "bold")
F_SUB    = ("Segoe UI", 14, "bold")
F_LABEL  = ("Segoe UI", 12)
F_BOLD   = ("Segoe UI", 12, "bold")
F_BTN    = ("Segoe UI", 12, "bold")
F_SMALL  = ("Segoe UI", 11)
F_TINY   = ("Segoe UI", 10)
F_MONO   = ("Consolas", 12)

PAD = 16


# ══════════════════════════════════════════════════════════════════════
#  REUSABLE UI HELPERS
# ══════════════════════════════════════════════════════════════════════

def make_treeview(parent, columns, widths=None):
    """Premium dark treeview with zebra rows and indigo header."""
    style = ttk.Style()
    style.theme_use("clam")

    style.configure("Vc.Treeview",
                    background=C_TREE_BG, foreground="#cbd5e1",
                    fieldbackground=C_TREE_BG, rowheight=30,
                    font=("Segoe UI", 10), borderwidth=0, relief="flat")
    style.configure("Vc.Treeview.Heading",
                    background=C_TREE_HEAD, foreground=C_PRIMARY,
                    font=("Segoe UI", 10, "bold"),
                    relief="flat", borderwidth=0)
    style.map("Vc.Treeview",
              background=[("selected", C_PRIMARY)],
              foreground=[("selected", "#ffffff")])

    wrap = ctk.CTkFrame(parent, fg_color=C_TREE_BG,
                        corner_radius=10, border_width=1, border_color=C_BORDER)
    wrap.pack(fill="both", expand=True, padx=PAD, pady=(0, PAD))

    tree = ttk.Treeview(wrap, columns=columns, show="headings",
                        style="Vc.Treeview", selectmode="browse")
    vsb = ttk.Scrollbar(wrap, orient="vertical", command=tree.yview)
    tree.configure(yscrollcommand=vsb.set)

    for i, col in enumerate(columns):
        w = widths[i] if widths and i < len(widths) else 120
        tree.heading(col, text=col)
        tree.column(col, width=w, stretch=True, anchor="w")

    tree.tag_configure("even", background=C_TREE_BG)
    tree.tag_configure("odd",  background=C_TREE_ODD)

    tree.grid(row=0, column=0, sticky="nsew")
    vsb.grid(row=0, column=1, sticky="ns")
    wrap.rowconfigure(0, weight=1)
    wrap.columnconfigure(0, weight=1)
    return tree


def _insert_tree(tree, rows):
    """Insert rows into tree with zebra tags."""
    for i in tree.get_children():
        tree.delete(i)
    for idx, r in enumerate(rows):
        tree.insert("", "end", values=r, tags=("even" if idx % 2 == 0 else "odd",))


def make_section_header(parent, text, icon="", color=C_PRIMARY):
    """Colored accent line + bold label as section header."""
    bar = ctk.CTkFrame(parent, fg_color="transparent")
    bar.pack(fill="x", padx=PAD, pady=(PAD, 4))
    ctk.CTkFrame(bar, fg_color=color, width=3, height=20, corner_radius=2).pack(side="left")
    ctk.CTkLabel(bar, text=f"  {icon}  {text}" if icon else f"  {text}",
                 font=F_BOLD, text_color=C_TEXT).pack(side="left")


def make_divider(parent):
    ctk.CTkFrame(parent, fg_color=C_BORDER, height=1, corner_radius=0).pack(
        fill="x", padx=PAD, pady=8)


def styled_btn(parent, text, cmd, color, hover, width=160, height=38, icon=""):
    return ctk.CTkButton(parent, text=f"{icon}  {text}" if icon else text,
                         command=cmd, fg_color=color, hover_color=hover,
                         font=F_BTN, corner_radius=8,
                         width=width, height=height)


# ══════════════════════════════════════════════════════════════════════
#  SETTINGS DIALOG
# ══════════════════════════════════════════════════════════════════════
class SettingsDialog(ctk.CTkToplevel):
    def __init__(self, parent, on_save):
        super().__init__(parent)
        self.title("Connection Settings")
        self.geometry("460x400")
        self.resizable(False, False)
        self.grab_set()
        self.on_save = on_save
        self.configure(fg_color=C_SURFACE)

        ctk.CTkFrame(self, fg_color=C_PRIMARY, height=3, corner_radius=0).pack(fill="x")

        hdr = ctk.CTkFrame(self, fg_color="transparent")
        hdr.pack(pady=(20, 4))
        ctk.CTkLabel(hdr, text="⚙️", font=("Segoe UI", 24)).pack()
        ctk.CTkLabel(hdr, text="Database Connection", font=F_TITLE, text_color=C_TEXT).pack()
        ctk.CTkLabel(hdr, text="Update credentials and test the connection",
                     font=F_SMALL, text_color=C_SUBTLE).pack()

        form = ctk.CTkFrame(self, fg_color="transparent")
        form.pack(fill="x", padx=40, pady=16)

        self.entries = {}
        fields = [("Host",     "host",     db.DB_CONFIG["host"]),
                  ("Port",     "port",     str(db.DB_CONFIG["port"])),
                  ("Database", "dbname",   db.DB_CONFIG["dbname"]),
                  ("User",     "user",     db.DB_CONFIG["user"]),
                  ("Password", "password", db.DB_CONFIG["password"])]
        for label, key, default in fields:
            row = ctk.CTkFrame(form, fg_color="transparent")
            row.pack(fill="x", pady=4)
            ctk.CTkLabel(row, text=label, font=F_LABEL,
                         text_color=C_SUBTLE, width=90, anchor="w").pack(side="left")
            e = ctk.CTkEntry(row, width=260, fg_color=C_RAISED,
                             border_color=C_BORDER, corner_radius=8,
                             show="*" if key == "password" else "")
            e.insert(0, default)
            e.pack(side="left")
            self.entries[key] = e

        ctk.CTkButton(self, text="💾  Save & Test Connection", font=F_BTN,
                      fg_color=C_SUCCESS, hover_color=C_SUCCESS_H,
                      corner_radius=8, height=40, width=260,
                      command=self._save).pack(pady=16)

    def _save(self):
        for key, entry in self.entries.items():
            val = entry.get().strip()
            db.DB_CONFIG[key] = int(val) if key == "port" and val.isdigit() else val
        ok, err = db.test_connection()
        if ok:
            messagebox.showinfo("Connected ✅", "Database connection successful!")
            self.on_save()
            self.destroy()
        else:
            messagebox.showerror("Connection Failed", f"{err}\n\nDouble-check credentials.")


# ══════════════════════════════════════════════════════════════════════
#  CRUD TAB — reusable CRUD panel
# ══════════════════════════════════════════════════════════════════════
class CrudTab:
    def __init__(self, parent, *, table_label, pk_label, fields,
                 tree_cols, tree_widths,
                 fetch_all, fetch_by_id, insert_fn, update_fn, delete_fn,
                 dropdown_fields=None, accent=C_PRIMARY):
        self.table_label   = table_label
        self.pk_label      = pk_label
        self.fields        = fields
        self.fetch_all     = fetch_all
        self.fetch_by_id   = fetch_by_id
        self.insert_fn     = insert_fn
        self.update_fn     = update_fn
        self.delete_fn     = delete_fn
        self.dropdown_fields = dropdown_fields or {}
        self.entries       = {}
        self.combo_maps    = {}
        self.editing_pk    = None
        self.accent        = accent

        self._build(parent, tree_cols, tree_widths)
        self.refresh()

    # ── Layout ──────────────────────────────────────────────────────
    def _build(self, parent, tree_cols, tree_widths):
        # Top label bar
        hdr = ctk.CTkFrame(parent, fg_color=C_RAISED, height=40, corner_radius=0)
        hdr.pack(fill="x")
        ctk.CTkFrame(hdr, fg_color=self.accent, width=4, height=40, corner_radius=0).pack(side="left")
        ctk.CTkLabel(hdr, text=f"  {self.table_label}",
                     font=F_BOLD, text_color=C_TEXT).pack(side="left", padx=8)
        styled_btn(hdr, "Refresh", self.refresh, C_RAISED, C_HOVER_BG,
                   width=100, height=30, icon="↻").pack(side="right", padx=10, pady=5)

        # Treeview
        self.tree = make_treeview(parent, tree_cols, tree_widths)

        # Edit Panel card
        panel = ctk.CTkFrame(parent, fg_color=C_SURFACE,
                             corner_radius=12, border_width=1, border_color=C_BORDER)
        panel.pack(fill="x", padx=PAD, pady=(0, PAD))

        # PK Lookup area
        pk_card = ctk.CTkFrame(panel, fg_color=C_RAISED,
                               corner_radius=8, border_width=1, border_color=self.accent)
        pk_card.pack(fill="x", padx=PAD, pady=(PAD, 8))
        ctk.CTkLabel(pk_card, text=f"🔑  {self.pk_label}",
                     font=F_BOLD, text_color=self.accent).pack(side="left", padx=12)
        self.pk_entry = ctk.CTkEntry(pk_card, width=110, fg_color=C_BASE,
                                     border_color=C_BORDER, corner_radius=8,
                                     placeholder_text="Enter ID…")
        self.pk_entry.pack(side="left", padx=8, pady=8)
        ctk.CTkButton(pk_card, text="🔍  Load Record",
                      font=F_BTN, fg_color=self.accent, hover_color=C_PRIMARY_H,
                      corner_radius=8, height=34, width=160,
                      command=self._on_fetch).pack(side="left")

        # Fields grid
        grid = ctk.CTkFrame(panel, fg_color="transparent")
        grid.pack(fill="x", padx=PAD, pady=4)
        for idx, (label, key, _) in enumerate(self.fields):
            r, c = divmod(idx, 2)
            ctk.CTkLabel(grid, text=label, font=F_LABEL,
                         text_color=C_SUBTLE, width=130, anchor="w"
                         ).grid(row=r*2, column=c, sticky="w", pady=(8, 2), padx=(0, 16))
            if key in self.dropdown_fields:
                var = StringVar()
                cb = ctk.CTkComboBox(grid, variable=var, width=220,
                                     state="readonly",
                                     fg_color=C_RAISED, border_color=C_BORDER,
                                     button_color=C_BORDER, corner_radius=8)
                cb.grid(row=r*2+1, column=c, sticky="w", padx=(0, 16))
                self.entries[key] = (var, cb)
            else:
                e = ctk.CTkEntry(grid, width=220, fg_color=C_RAISED,
                                 border_color=C_BORDER, corner_radius=8)
                e.grid(row=r*2+1, column=c, sticky="w", padx=(0, 16))
                self.entries[key] = e

        # Action buttons
        make_divider(panel)
        actions = ctk.CTkFrame(panel, fg_color="transparent")
        actions.pack(fill="x", padx=PAD, pady=(0, PAD))

        styled_btn(actions, "Create New",   self._on_insert, "#1e3a8a", "#1e40af", icon="➕").pack(side="left", padx=4)
        styled_btn(actions, "Save Changes", self._on_update, C_SUCCESS,  C_SUCCESS_H, icon="💾").pack(side="left", padx=4)
        styled_btn(actions, "Delete",       self._on_delete, C_DANGER,   C_DANGER_H,  icon="🗑️").pack(side="left", padx=4)

    # ── Dropdown helpers ─────────────────────────────────────────────
    def _load_dropdowns(self):
        for key, loader in self.dropdown_fields.items():
            try:
                opts = loader()
                self.combo_maps[key] = {t: i for i, t in opts}
                if key in self.entries:
                    self.entries[key][1].configure(values=[t for _, t in opts])
            except Exception:
                pass  # Silently skip if DB not ready yet

    def _get(self, key):
        w = self.entries.get(key)
        if isinstance(w, tuple):
            return self.combo_maps.get(key, {}).get(w[0].get())
        return w.get().strip()

    def _set(self, key, val):
        w = self.entries.get(key)
        if isinstance(w, tuple):
            rev = {v: k for k, v in self.combo_maps.get(key, {}).items()}
            w[0].set(rev.get(val, ""))
        else:
            w.delete(0, "end")
            w.insert(0, str(val) if val is not None else "")

    # ── CRUD actions ─────────────────────────────────────────────────
    def refresh(self):
        self._load_dropdowns()
        for i in self.tree.get_children():
            self.tree.delete(i)
        try:
            _, rows = self.fetch_all()
            for idx, r in enumerate(rows):
                self.tree.insert("", "end", values=r,
                                 tags=("even" if idx % 2 == 0 else "odd",))
        except Exception as e:
            messagebox.showerror("Load Error", f"Could not load {self.table_label}:\n{e}")

    def _on_fetch(self):
        i = self.pk_entry.get().strip()
        if not i:
            messagebox.showwarning("Input Required", "Enter a record ID to load.")
            return
        try:
            pk = int(i)
        except ValueError:
            messagebox.showerror("Invalid ID", "ID must be a whole number.")
            return
        r = self.fetch_by_id(pk)
        if not r:
            messagebox.showwarning("Not Found", f"No record found with ID {pk}.")
            return
        self.editing_pk = pk
        for _, k, _ in self.fields:
            self._set(k, r.get(k))
        messagebox.showinfo("Loaded ✅",
                            f"Record #{pk} loaded — edit the fields then click 💾 Save Changes.")

    def _on_insert(self):
        i = self.pk_entry.get().strip()
        if not i:
            messagebox.showwarning("Input Required", "Enter an ID for the new record.")
            return
        try:
            pk = int(i)
        except ValueError:
            messagebox.showerror("Invalid ID", "ID must be a whole number.")
            return
        try:
            self.insert_fn(pk, *[self._get(k) for _, k, _ in self.fields])
            self.editing_pk = None
            self.refresh()
            messagebox.showinfo("Created ✅", f"Record #{pk} created successfully.")
        except Exception as e:
            messagebox.showerror("DB Error", str(e))

    def _on_update(self):
        if self.editing_pk is None:
            messagebox.showwarning("Load First",
                                   "Click 🔍 Load Record before editing.\n"
                                   "Enter the ID → Load → modify fields → Save Changes.")
            return
        try:
            self.update_fn(self.editing_pk, *[self._get(k) for _, k, _ in self.fields])
            pk = self.editing_pk
            self.editing_pk = None
            self.refresh()
            messagebox.showinfo("Updated ✅", f"Record #{pk} saved successfully.")
        except Exception as e:
            messagebox.showerror("DB Error", str(e))

    def _on_delete(self):
        i = self.pk_entry.get().strip()
        if not i:
            messagebox.showwarning("Input Required", "Enter the ID of the record to delete.")
            return
        try:
            pk = int(i)
        except ValueError:
            messagebox.showerror("Invalid ID", "ID must be a whole number.")
            return
        if not messagebox.askyesno("Confirm Delete",
                                   f"⚠️  Permanently delete record #{pk}?\n\nThis cannot be undone."):
            return
        try:
            self.delete_fn(pk)
            self.editing_pk = None
            self.refresh()
            messagebox.showinfo("Deleted", f"Record #{pk} has been deleted.")
        except Exception as e:
            messagebox.showerror("DB Error", str(e))


# ══════════════════════════════════════════════════════════════════════
#  WELCOME PAGE  –  Dashboard Hero
# ══════════════════════════════════════════════════════════════════════
class WelcomePage(ctk.CTkFrame):
    def __init__(self, parent, controller):
        super().__init__(parent, fg_color=C_BASE)
        self.controller = controller

        # Subtle top gradient strip
        ctk.CTkFrame(self, fg_color=C_PRIMARY, height=3,
                     corner_radius=0).pack(fill="x")

        # Center container
        wrap = ctk.CTkFrame(self, fg_color="transparent")
        wrap.place(relx=0.5, rely=0.5, anchor="center")

        # ── Hero text ─────────────────────────────────────────────
        ctk.CTkLabel(wrap, text="🏥", font=("Segoe UI", 48)).pack()
        ctk.CTkLabel(wrap, text="VetCare Dashboard",
                     font=F_HERO, text_color=C_TEXT).pack(pady=(6, 0))
        ctk.CTkLabel(wrap, text="Mini-Project  ·  Stage 5  ·  Database GUI",
                     font=F_LABEL, text_color=C_SUBTLE).pack(pady=(2, 0))
        ctk.CTkLabel(wrap, text="Avinoam Muller  ·  Guedalia Sebbah",
                     font=F_TINY, text_color=C_DIM).pack(pady=(2, 20))

        # ── DB Status indicator ───────────────────────────────────
        status_row = ctk.CTkFrame(wrap, fg_color=C_SURFACE,
                                  corner_radius=20, border_width=1,
                                  border_color=C_BORDER)
        status_row.pack(pady=(0, 28))
        self._dot = ctk.CTkLabel(status_row, text="●",
                                 font=("Segoe UI", 13), width=20)
        self._dot.pack(side="left", padx=(14, 4), pady=8)
        self._status = ctk.CTkLabel(status_row, text="Checking connection…",
                                    font=F_SMALL, text_color=C_SUBTLE)
        self._status.pack(side="left", padx=(0, 16), pady=8)

        # ── Navigation card (single, centered) ───────────────────
        self._nav_card(
            wrap,
            icon="📋", title="Data Management",
            lines=["6 tables — full CRUD", "Animals · Vets · Visits",
                   "Treatments · Meds · Vax"],
            color=C_PRIMARY, hover=C_PRIMARY_H,
            cmd=controller.show_crud
        )

        # ── Settings button ───────────────────────────────────────
        ctk.CTkButton(wrap, text="⚙️   Connection Settings",
                      font=F_SMALL, fg_color="transparent",
                      text_color=C_DIM, hover_color=C_HOVER_BG,
                      height=36, border_width=1, border_color=C_BORDER,
                      corner_radius=18, width=300,
                      command=lambda: controller.open_settings(self._refresh)
                      ).pack(pady=(20, 0))

        self._refresh()

    def _nav_card(self, parent, icon, title, lines, color, hover, cmd):
        card = ctk.CTkFrame(parent, fg_color=C_SURFACE, corner_radius=16,
                            border_width=2, border_color=color,
                            width=290, height=240)
        card.pack(pady=(0, 0))
        card.pack_propagate(False)

        ctk.CTkFrame(card, fg_color=color, height=4,
                     corner_radius=2).pack(fill="x", padx=20, pady=(18, 0))
        ctk.CTkLabel(card, text=icon,
                     font=("Segoe UI", 30)).pack(pady=(10, 0))
        ctk.CTkLabel(card, text=title,
                     font=F_SUB, text_color=C_TEXT).pack(pady=(4, 0))
        for line in lines:
            ctk.CTkLabel(card, text=line,
                         font=F_TINY, text_color=C_SUBTLE).pack()
        ctk.CTkButton(card, text="Open  →", font=F_BTN,
                      fg_color=color, hover_color=hover,
                      corner_radius=8, height=36, width=180,
                      command=cmd).pack(side="bottom", pady=14)

    def _refresh(self):
        ok, err = db.test_connection()
        if ok:
            self._dot.configure(text_color=C_SUCCESS)
            self._status.configure(
                text=f"Connected  ·  {db.DB_CONFIG['dbname']}  ·  "
                     f"{db.DB_CONFIG['host']}:{db.DB_CONFIG['port']}",
                text_color=C_SUCCESS)
        else:
            self._dot.configure(text_color=C_DANGER)
            self._status.configure(
                text=f"Not connected  ·  {str(err)[:52]}",
                text_color=C_DANGER)


# ══════════════════════════════════════════════════════════════════════
#  CRUD PAGE
# ══════════════════════════════════════════════════════════════════════
class CrudPage(ctk.CTkFrame):
    def __init__(self, parent, controller):
        super().__init__(parent, fg_color=C_BASE)

        # Top nav bar
        nav = ctk.CTkFrame(self, fg_color=C_SURFACE, height=52, corner_radius=0)
        nav.pack(fill="x")
        ctk.CTkFrame(nav, fg_color=C_PRIMARY, width=4, height=52,
                     corner_radius=0).pack(side="left")
        ctk.CTkButton(nav, text="← Back", width=90, height=36,
                      fg_color=C_RAISED, hover_color=C_HOVER_BG,
                      font=F_BTN, corner_radius=8,
                      command=controller._show_welcome).pack(side="left", padx=12)
        ctk.CTkLabel(nav, text="Database CRUD Management",
                     font=F_TITLE, text_color=C_TEXT).pack(side="left", padx=8)
        ctk.CTkButton(nav, text="📊  Reports & PL/SQL", width=190, height=36,
                      fg_color=C_VIOLET, hover_color=C_VIOLET_H,
                      font=F_BTN, corner_radius=8,
                      command=controller.show_advanced).pack(side="right", padx=12)

        tabs = ctk.CTkTabview(self, fg_color=C_SURFACE,
                              segmented_button_fg_color=C_RAISED,
                              segmented_button_selected_color=C_PRIMARY,
                              segmented_button_unselected_color=C_RAISED,
                              segmented_button_selected_hover_color=C_PRIMARY_H,
                              text_color=C_TEXT)
        tabs.pack(fill="both", expand=True, padx=PAD, pady=PAD)

        # VetCare tables
        CrudTab(tabs.add("🐾 Animals"), table_label="Animal Records",
                pk_label="Animal ID", accent=C_SUCCESS,
                fields=[("Name","name",""), ("Species","species",""),
                        ("Birth Date","birthdate",""), ("Gender","gender",""),
                        ("Weight (kg)","weight","")],
                tree_cols=("ID","Name","Species","Birth","Gender","Kg","Visits","Last Visit"),
                tree_widths=[50,120,110,100,70,65,55,100],
                fetch_all=db.fetch_animals, fetch_by_id=db.fetch_animal_by_id,
                insert_fn=db.insert_animal, update_fn=db.update_animal,
                delete_fn=db.delete_animal)

        CrudTab(tabs.add("🩺 Vets"), table_label="Veterinarians",
                pk_label="Vet ID", accent=C_INFO,
                fields=[("First Name","firstname",""), ("Last Name","lastname",""),
                        ("License No.","licensenumber",""), ("Specialization","specialization",""),
                        ("Hire Date","hiredate","")],
                tree_cols=("ID","First","Last","License","Specialization","Hired"),
                tree_widths=[50,110,110,140,170,110],
                fetch_all=db.fetch_veterinarians, fetch_by_id=db.fetch_vet_by_id,
                insert_fn=db.insert_vet, update_fn=db.update_vet,
                delete_fn=db.delete_vet)

        CrudTab(tabs.add("🏥 Visits"), table_label="Medical Visits  (FK → Names via JOIN)",
                pk_label="Visit ID", accent=C_WARNING,
                fields=[("Date","visitdate",""), ("Reason","reason",""),
                        ("Summary","summary",""), ("Cost","cost",""),
                        ("Animal","animalid",""), ("Vet","vetid","")],
                tree_cols=("ID","Date","Animal","Veterinarian","Reason","Summary","Cost"),
                tree_widths=[45,95,140,155,155,175,75],
                fetch_all=db.fetch_visits, fetch_by_id=db.fetch_visit_by_id,
                insert_fn=db.insert_visit, update_fn=db.update_visit,
                delete_fn=db.delete_visit,
                dropdown_fields={"animalid": db.get_animal_options,
                                 "vetid":    db.get_vet_options})

        CrudTab(tabs.add("💉 Treatments"), table_label="Treatments Catalog",
                pk_label="Treatment ID", accent=C_VIOLET,
                fields=[("Description","description",""), ("Duration","duration",""),
                        ("Type","type",""), ("Severity","severity","")],
                tree_cols=("ID","Description","Duration","Type","Severity"),
                tree_widths=[50,220,110,120,110],
                fetch_all=db.fetch_treatments, fetch_by_id=db.fetch_treatment_by_id,
                insert_fn=db.insert_treatment, update_fn=db.update_treatment,
                delete_fn=db.delete_treatment)

        CrudTab(tabs.add("💊 Medications"), table_label="Medication Inventory",
                pk_label="Med ID", accent=C_DANGER,
                fields=[("Commercial Name","commercialname",""),
                        ("Active Ingredient","activeingredient",""),
                        ("Dosage Unit","dosageunit",""),
                        ("Expiration Date","expirationdate","")],
                tree_cols=("ID","Commercial Name","Active Ingredient","Unit","Expires"),
                tree_widths=[50,185,185,100,105],
                fetch_all=db.fetch_medications, fetch_by_id=db.fetch_medication_by_id,
                insert_fn=db.insert_medication, update_fn=db.update_medication,
                delete_fn=db.delete_medication)

        CrudTab(tabs.add("🔬 Vaccinations"), table_label="Vaccination Catalog",
                pk_label="Vac ID", accent=C_TEAL,
                fields=[("Vaccine Name","name",""), ("Manufacturer","manufacturer",""),
                        ("Freq (months)","frequencymonths",""),
                        ("Storage Temp","storagetemp","")],
                tree_cols=("ID","Vaccine Name","Manufacturer","Freq (mo)","Storage Temp"),
                tree_widths=[50,170,165,95,125],
                fetch_all=db.fetch_vaccinations, fetch_by_id=db.fetch_vaccination_by_id,
                insert_fn=db.insert_vaccination, update_fn=db.update_vaccination,
                delete_fn=db.delete_vaccination)



# ══════════════════════════════════════════════════════════════════════
#  ADVANCED PAGE  –  Reports, Queries & PL/pgSQL
# ══════════════════════════════════════════════════════════════════════
class AdvancedPage(ctk.CTkFrame):
    def __init__(self, parent, controller):
        super().__init__(parent, fg_color=C_BASE)

        # Top nav bar
        nav = ctk.CTkFrame(self, fg_color=C_SURFACE, height=52, corner_radius=0)
        nav.pack(fill="x")
        ctk.CTkFrame(nav, fg_color=C_VIOLET, width=4, height=52,
                     corner_radius=0).pack(side="left")
        ctk.CTkButton(nav, text="← Back", width=90, height=36,
                      fg_color=C_RAISED, hover_color=C_HOVER_BG,
                      font=F_BTN, corner_radius=8,
                      command=controller.show_crud).pack(side="left", padx=12)
        ctk.CTkLabel(nav, text="Reports & Complex Programs",
                     font=F_TITLE, text_color=C_TEXT).pack(side="left", padx=8)

        tabs = ctk.CTkTabview(self, fg_color=C_SURFACE,
                              segmented_button_fg_color=C_RAISED,
                              segmented_button_selected_color=C_VIOLET,
                              segmented_button_unselected_color=C_RAISED,
                              segmented_button_selected_hover_color=C_VIOLET_H,
                              text_color=C_TEXT)
        tabs.pack(fill="both", expand=True, padx=PAD, pady=PAD)

        self._build_q1(tabs.add("🏆 Top 10 Animals"))
        self._build_q2(tabs.add("💰 Revenue Report"))
        self._build_fn(tabs.add("🔬 Health Profile"))
        self._build_sp(tabs.add("🔄 Vet Transfer"))

    # ── Tab 1 : Stage 2 — Simple Query 1 ────────────────────────────
    def _build_q1(self, tab):
        self._query_header(tab,
            badge="Stage 2 — Simple Query 1",
            title="Activity Leaderboard",
            desc="Top 10 most-visited animals with total cost and average cost per visit.",
            color=C_SUCCESS)
        ctk.CTkButton(tab, text="▶   Generate Report", font=F_BTN,
                      fg_color=C_SUCCESS, hover_color=C_SUCCESS_H,
                      corner_radius=8, height=40, width=220,
                      command=self._q1).pack(pady=(0, 8))
        self.tr1 = make_treeview(tab,
            ("ID","Name","Species","Gender","Kg","Age","Visits","Last Visit","Total Cost","Avg Cost"),
            [40,110,110,65,55,40,55,100,90,90])

    # ── Tab 2 : Stage 2 — Double Query 4 (CTE) ─────────────────────
    def _build_q2(self, tab):
        self._query_header(tab,
            badge="Stage 2 — Double Query 4 (CTE version)",
            title="Monthly Revenue by Specialization",
            desc="Revenue, visit count, and average cost broken down by vet specialization per month.",
            color=C_WARNING)
        ctk.CTkButton(tab, text="▶   Calculate Revenue", font=F_BTN,
                      fg_color=C_WARNING, hover_color="#d97706",
                      corner_radius=8, height=40, width=220,
                      text_color="#1c1917",
                      command=self._q2).pack(pady=(0, 8))
        self.tr2 = make_treeview(tab,
            ("Year","Month","Specialization","Total Revenue","Visits","Avg Cost"),
            [65,65,220,115,80,100])

    # ── Tab 3 : Stage 4 — Function 1 ────────────────────────────────
    def _build_fn(self, tab):
        self._query_header(tab,
            badge="Stage 4 — Function  fn_get_animal_medical_summary()",
            title="Animal Medical Profile",
            desc="Calls the PL/pgSQL function with an explicit cursor — returns full medical history summary.",
            color=C_INFO)

        # Input card
        input_card = ctk.CTkFrame(tab, fg_color=C_RAISED,
                                  corner_radius=10, border_width=1,
                                  border_color=C_BORDER)
        input_card.pack(fill="x", padx=PAD, pady=(0, 8))
        row = ctk.CTkFrame(input_card, fg_color="transparent")
        row.pack(pady=12, padx=PAD)
        ctk.CTkLabel(row, text="Animal ID", font=F_BOLD,
                     text_color=C_SUBTLE).pack(side="left", padx=(0, 10))
        self.fid_e = ctk.CTkEntry(row, width=120, fg_color=C_BASE,
                                  border_color=C_BORDER, corner_radius=8,
                                  placeholder_text="e.g. 1")
        self.fid_e.pack(side="left", padx=(0, 10))
        ctk.CTkButton(row, text="▶   Get Summary", font=F_BTN,
                      fg_color=C_INFO, hover_color="#0284c7",
                      text_color="#0c1a25",
                      corner_radius=8, height=36, width=180,
                      command=self._fn).pack(side="left")

        # Result textbox
        self.txt = ctk.CTkTextbox(tab, font=F_MONO, fg_color=C_TREE_BG,
                                  text_color="#a5f3fc",
                                  border_color=C_BORDER, border_width=1,
                                  corner_radius=10)
        self.txt.pack(fill="both", expand=True, padx=PAD, pady=(0, PAD))
        self.txt.insert("1.0", "  Enter an Animal ID above and click ▶ Get Summary…")
        self.txt.configure(state="disabled")

    # ── Tab 4 : Stage 4 — Procedure 1 ───────────────────────────────
    def _build_sp(self, tab):
        self._query_header(tab,
            badge="Stage 4 — Procedure  sp_transfer_animal_visits()",
            title="Transfer Visit History Between Vets",
            desc="Calls the PL/pgSQL procedure — reassigns all visits from one vet to another and logs the operation in audit_log.",
            color=C_DANGER)

        # Transfer card
        card = ctk.CTkFrame(tab, fg_color=C_RAISED, corner_radius=12,
                            border_width=1, border_color=C_BORDER)
        card.pack(fill="x", padx=PAD, pady=(0, 16))

        row = ctk.CTkFrame(card, fg_color="transparent")
        row.pack(pady=20, padx=PAD)

        # From
        from_col = ctk.CTkFrame(row, fg_color="transparent")
        from_col.pack(side="left", padx=16)
        ctk.CTkLabel(from_col, text="FROM  Vet ID",
                     font=F_BOLD, text_color=C_DANGER).pack(pady=(0, 6))
        self.f_v = ctk.CTkEntry(from_col, width=130, fg_color=C_BASE,
                                border_color=C_DANGER, corner_radius=8,
                                placeholder_text="Source vet ID")
        self.f_v.pack()

        # Arrow
        ctk.CTkLabel(row, text="→",
                     font=("Segoe UI", 28, "bold"),
                     text_color=C_DIM).pack(side="left", padx=20, pady=8)

        # To
        to_col = ctk.CTkFrame(row, fg_color="transparent")
        to_col.pack(side="left", padx=16)
        ctk.CTkLabel(to_col, text="TO  Vet ID",
                     font=F_BOLD, text_color=C_SUCCESS).pack(pady=(0, 6))
        self.t_v = ctk.CTkEntry(to_col, width=130, fg_color=C_BASE,
                                border_color=C_SUCCESS, corner_radius=8,
                                placeholder_text="Target vet ID")
        self.t_v.pack()

        ctk.CTkButton(card, text="⚡   Execute Transfer", font=F_BTN,
                      fg_color=C_DANGER, hover_color=C_DANGER_H,
                      corner_radius=8, height=42, width=260,
                      command=self._sp).pack(pady=(8, 20))

        ctk.CTkLabel(tab,
                     text="⚠️  This operation permanently modifies the database and is logged in audit_log.",
                     font=F_TINY, text_color=C_DIM).pack()

    # ── Static query header helper ───────────────────────────────────
    def _query_header(self, parent, badge, title, desc, color):
        hdr = ctk.CTkFrame(parent, fg_color=C_SURFACE,
                           corner_radius=10, border_width=1,
                           border_color=C_BORDER)
        hdr.pack(fill="x", padx=PAD, pady=(PAD, 8))

        badge_lbl = ctk.CTkFrame(hdr, fg_color=color, corner_radius=4)
        badge_lbl.pack(side="left", padx=12, pady=12)
        ctk.CTkLabel(badge_lbl, text=f"  {badge}  ",
                     font=F_TINY, text_color="#ffffff").pack()

        txt_col = ctk.CTkFrame(hdr, fg_color="transparent")
        txt_col.pack(side="left", padx=10, pady=8)
        ctk.CTkLabel(txt_col, text=title,
                     font=F_BOLD, text_color=C_TEXT).pack(anchor="w")
        ctk.CTkLabel(txt_col, text=desc,
                     font=F_TINY, text_color=C_SUBTLE, wraplength=620,
                     justify="left").pack(anchor="w")

    # ── Query / procedure callbacks ──────────────────────────────────
    def _q1(self):
        try:
            _, r = db.query_top10_most_visited_animals()
            _insert_tree(self.tr1, r)
            if not r:
                messagebox.showinfo("No Data",
                                    "No results — verify visits exist in the database.")
        except Exception as e:
            messagebox.showerror("Query Error", f"Top 10 Animals failed:\n{e}")

    def _q2(self):
        try:
            _, r = db.query_monthly_revenue_by_specialization()
            _insert_tree(self.tr2, r)
            if not r:
                messagebox.showinfo("No Data",
                                    "No results — verify visits with costs exist.")
        except Exception as e:
            messagebox.showerror("Query Error", f"Revenue Breakdown failed:\n{e}")

    def _fn(self):
        aid = self.fid_e.get().strip()
        if not aid:
            messagebox.showwarning("Input Required", "Enter an Animal ID.")
            return
        try:
            r = db.call_animal_medical_summary(int(aid))
            self.txt.configure(state="normal")
            self.txt.delete("1.0", "end")
            if not r:
                self.txt.insert("1.0", f"  No medical data found for Animal ID {aid}.")
            else:
                self.txt.insert("1.0",
                    f"  ╔══════════════════════════════════════╗\n"
                    f"  ║   Medical Profile — Animal #{aid:<6}    ║\n"
                    f"  ╚══════════════════════════════════════╝\n\n"
                    f"  Name           :  {r.get('o_animal_name',  'N/A')}\n"
                    f"  Species        :  {r.get('o_species',      'N/A')}\n\n"
                    f"  Total Visits   :  {r.get('o_total_visits', 'N/A')}\n"
                    f"  Total Cost     :  {r.get('o_total_cost',   'N/A')}\n"
                    f"  Avg Cost/Visit :  {r.get('o_avg_cost',     'N/A')}\n"
                    f"  Last Visit     :  {r.get('o_last_visit',   'N/A')}\n\n"
                    f"  ── Health Status ──────────────────────\n"
                    f"  {r.get('o_health_status', 'N/A')}\n"
                )
            self.txt.configure(state="disabled")
        except ValueError:
            messagebox.showerror("Invalid Input", "Animal ID must be a whole number.")
        except Exception as e:
            messagebox.showerror("Function Error",
                                 f"fn_get_animal_medical_summary failed:\n{e}")

    def _sp(self):
        f, t = self.f_v.get().strip(), self.t_v.get().strip()
        if not f or not t:
            messagebox.showwarning("Input Required", "Enter both Vet IDs.")
            return
        try:
            fid, tid = int(f), int(t)
        except ValueError:
            messagebox.showerror("Invalid Input", "Vet IDs must be whole numbers.")
            return
        if fid == tid:
            messagebox.showwarning("Same Vet",
                                   "Source and destination vets must be different.")
            return
        if not messagebox.askyesno("Confirm Transfer",
                f"⚡ Transfer ALL visits from Vet #{fid} → Vet #{tid}?\n\n"
                "This permanently modifies the database\nand will be logged in audit_log."):
            return
        try:
            db.call_transfer_vet_visits(fid, tid)
            messagebox.showinfo("Transfer Complete ✅",
                f"All visits from Vet #{fid} have been successfully\n"
                f"transferred to Vet #{tid}.\n\nChanges are logged in audit_log.")
        except Exception as e:
            messagebox.showerror("Procedure Error",
                                 f"sp_transfer_animal_visits failed:\n{e}")


# ══════════════════════════════════════════════════════════════════════
#  APP CONTROLLER
# ══════════════════════════════════════════════════════════════════════
class VetCareApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("🏥  VetCare — Database Management System")
        self.geometry("1280x820")
        self.minsize(1000, 680)
        self.configure(fg_color=C_BASE)
        self._frame = ctk.CTkFrame(self, fg_color="transparent")
        self._frame.pack(fill="both", expand=True)
        self._show_welcome()

    def _clear(self):
        for w in self._frame.winfo_children():
            w.destroy()

    def _show_welcome(self):
        self._clear()
        WelcomePage(self._frame, self).pack(fill="both", expand=True)

    def show_crud(self):
        self._clear()
        CrudPage(self._frame, self).pack(fill="both", expand=True)

    def show_advanced(self):
        self._clear()
        AdvancedPage(self._frame, self).pack(fill="both", expand=True)

    def open_settings(self, cb):
        SettingsDialog(self, cb)


if __name__ == "__main__":
    app = VetCareApp()
    app.mainloop()
