# ============================================================
# base_crud.py  –  Generic CRUD screen base class
# ============================================================
"""
Each subclass defines:
  TABLE       – DB table name (string)
  PK          – primary key column (lowercase, as returned by psycopg2)
  TITLE       – screen title
  ICON        – emoji icon
  LIST_QUERY  – SELECT query for the treeview (no IDs in result; uses JOINs)
  LIST_COLS   – list of (result_col_key, heading, width)  ← display only
  FORM_FIELDS – list of FormField(label, var_key, kind, fk_query, fk_val_col, fk_lbl_col)
  INSERT_SQL  – parameterised INSERT (excluding auto-id tables)
  UPDATE_SQL  – parameterised UPDATE (WHERE {PK}=%(id)s)
  DELETE_SQL  – parameterised DELETE (WHERE {PK}=%(id)s)
  FETCH_SQL   – SELECT * for one row by PK (for the update form)
"""

import tkinter as tk
from tkinter import ttk, messagebox
from dataclasses import dataclass, field
from typing import Optional
import styles as s
import widgets as w
import db


@dataclass
class FormField:
    label: str        # display label
    var_key: str      # key in the values dict passed to SQL
    kind: str = "entry"   # "entry" | "combo" | "text"
    fk_query: str = ""    # query that returns (id_col, label_col) for combo
    fk_id_col: str = ""   # which column is the FK id
    fk_lbl_col: str = ""  # which column is the human label
    width: int = 28


class BaseCRUDScreen(tk.Frame):
    # ── subclass MUST override these ─────────────────────────
    TABLE      = ""
    PK         = ""
    TITLE      = "Records"
    ICON       = "📄"
    LIST_QUERY = ""
    LIST_COLS  = []   # [(key, heading, width), ...]
    FORM_FIELDS = []  # list of FormField
    INSERT_SQL = ""
    UPDATE_SQL = ""
    DELETE_SQL = ""
    FETCH_SQL  = ""
    # ─────────────────────────────────────────────────────────

    def __init__(self, parent, app):
        super().__init__(parent, bg=s.BG_CONTENT)
        self.app = app
        self._fk_maps: dict[str, dict] = {}   # var_key → {label: id}
        self._form_vars: dict[str, tk.StringVar] = {}
        self._form_combos: dict[str, ttk.Combobox] = {}
        self._edit_pk_var = tk.StringVar()
        self._tree: Optional[ttk.Treeview] = None
        self._build()
        self._refresh()

    # ── Layout ───────────────────────────────────────────────
    def _build(self):
        # Title bar
        bar = tk.Frame(self, bg=s.BG_CONTENT)
        bar.pack(fill=tk.X, padx=20, pady=(18, 6))
        tk.Label(bar, text=f"{self.ICON}  {self.TITLE}",
                 bg=s.BG_CONTENT, fg=s.T_DARK,
                 font=s.F_TITLE).pack(side=tk.LEFT)

        ttk.Button(bar, text="↻  Refresh",
                   style="Refresh.TButton",
                   command=self._refresh).pack(side=tk.RIGHT, padx=4)

        # Horizontal split: table left, form right
        split = tk.PanedWindow(self, orient=tk.HORIZONTAL,
                               bg=s.BG_CONTENT, bd=0,
                               sashrelief="flat", sashwidth=6)
        split.pack(fill=tk.BOTH, expand=True, padx=10, pady=(0, 10))

        # ── Left: table ──────────────────────────────────────
        left = tk.Frame(split, bg=s.BG_CONTENT)
        tbl_outer, self._tree = w.scrolled_tree(left, self.LIST_COLS)
        tbl_outer.pack(fill=tk.BOTH, expand=True)
        split.add(left, stretch="always", minsize=400)

        # Double-click fills update form
        self._tree.bind("<Double-1>", self._on_double_click)

        # ── Right: form panel ────────────────────────────────
        right_outer = tk.Frame(split, bg=s.BG_CONTENT)
        canvas = tk.Canvas(right_outer, bg=s.BG_CARD,
                           highlightthickness=0)
        vsb = ttk.Scrollbar(right_outer, orient="vertical",
                            command=canvas.yview)
        canvas.configure(yscrollcommand=vsb.set)
        vsb.pack(side=tk.RIGHT, fill=tk.Y)
        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        self._form_frame = tk.Frame(canvas, bg=s.BG_CARD)
        win_id = canvas.create_window((0, 0), window=self._form_frame,
                                      anchor="nw")

        def _on_configure(event):
            canvas.configure(scrollregion=canvas.bbox("all"))
            canvas.itemconfig(win_id, width=event.width)

        self._form_frame.bind("<Configure>",
                              lambda e: canvas.configure(
                                  scrollregion=canvas.bbox("all")))
        canvas.bind("<Configure>", _on_configure)
        canvas.bind_all("<MouseWheel>",
                        lambda e: canvas.yview_scroll(-1 * (e.delta // 120),
                                                      "units"))

        self._build_form(self._form_frame)
        split.add(right_outer, stretch="never", minsize=310)

    def _build_form(self, parent):
        parent.columnconfigure(1, weight=1)
        row = 0

        # ── Section: Add new ─────────────────────────────────
        w.section_sep(parent, "➕  Add New Record").grid(
            row=row, column=0, columnspan=2, sticky="ew", padx=10)
        row += 1

        self._load_fk_data()

        for ff in self.FORM_FIELDS:
            if ff.kind == "combo":
                labels = list(self._fk_maps.get(ff.var_key, {}).keys())
                var, combo = w.form_combo(parent, row, ff.label, labels)
                self._form_combos[ff.var_key] = combo
            else:
                var, _ = w.form_row(parent, row, ff.label)
            self._form_vars[ff.var_key] = var
            row += 1

        ttk.Button(parent, text="✚  Add Record",
                   style="Add.TButton",
                   command=self._add).grid(
            row=row, column=0, columnspan=2, pady=(8, 4), padx=10, sticky="ew")
        row += 1

        # ── Section: Update / Delete ─────────────────────────
        w.section_sep(parent, "✏️  Update / Delete Record").grid(
            row=row, column=0, columnspan=2, sticky="ew", padx=10)
        row += 1

        tk.Label(parent, text="Record ID:", bg=s.BG_CARD, fg=s.T_DARK,
                 font=s.F_BODY).grid(row=row, column=0, sticky="e",
                                     padx=(4, 6), pady=4)
        id_entry = ttk.Entry(parent, textvariable=self._edit_pk_var, width=14)
        id_entry.grid(row=row, column=1, sticky="w", pady=4, padx=(0, 4))
        row += 1

        ttk.Button(parent, text="🔍  Fetch Record",
                   style="Fetch.TButton",
                   command=self._fetch_record).grid(
            row=row, column=0, columnspan=2,
            pady=(0, 6), padx=10, sticky="ew")
        row += 1

        # Update form fields (reuse same StringVars with suffix _u)
        self._update_vars: dict[str, tk.StringVar] = {}
        self._update_combos: dict[str, ttk.Combobox] = {}

        for ff in self.FORM_FIELDS:
            if ff.kind == "combo":
                labels = list(self._fk_maps.get(ff.var_key, {}).keys())
                var, combo = w.form_combo(parent, row, ff.label, labels)
                self._update_combos[ff.var_key] = combo
            else:
                var, _ = w.form_row(parent, row, ff.label)
            self._update_vars[ff.var_key] = var
            row += 1

        btn_row = tk.Frame(parent, bg=s.BG_CARD)
        btn_row.grid(row=row, column=0, columnspan=2,
                     sticky="ew", padx=10, pady=(8, 12))
        ttk.Button(btn_row, text="💾  Save Update",
                   style="Edit.TButton",
                   command=self._update).pack(side=tk.LEFT, expand=True,
                                              fill=tk.X, padx=(0, 4))
        ttk.Button(btn_row, text="🗑  Delete",
                   style="Delete.TButton",
                   command=self._delete).pack(side=tk.LEFT, expand=True,
                                              fill=tk.X)

    # ── FK data loading ──────────────────────────────────────
    def _load_fk_data(self):
        for ff in self.FORM_FIELDS:
            if ff.kind == "combo" and ff.fk_query:
                try:
                    rows = db.fetch(ff.fk_query)
                    self._fk_maps[ff.var_key] = {
                        str(r[ff.fk_lbl_col]): r[ff.fk_id_col]
                        for r in rows
                    }
                except Exception as e:
                    self._fk_maps[ff.var_key] = {}

    def _id_for(self, var_key: str, label: str):
        """Reverse-lookup: human label → FK id."""
        return self._fk_maps.get(var_key, {}).get(label, label)

    def _label_for(self, var_key: str, fk_id) -> str:
        """Lookup: FK id → human label."""
        rev = {v: k for k, v in self._fk_maps.get(var_key, {}).items()}
        return rev.get(fk_id, str(fk_id) if fk_id is not None else "")

    # ── Data operations ──────────────────────────────────────
    def _refresh(self):
        try:
            rows = db.fetch(self.LIST_QUERY)
            col_keys = [c[0] for c in self.LIST_COLS]
            w.populate_tree(self._tree, rows, col_keys, self.PK)
        except Exception as e:
            messagebox.showerror("DB Error", str(e), parent=self)

    def _collect_form(self, vars_dict: dict) -> dict:
        """Collect form values, resolving combo labels to FK ids."""
        values = {}
        for ff in self.FORM_FIELDS:
            raw = vars_dict[ff.var_key].get().strip()
            if ff.kind == "combo":
                values[ff.var_key] = self._id_for(ff.var_key, raw) if raw else None
            else:
                values[ff.var_key] = raw if raw else None
        return values

    def _add(self):
        try:
            values = self._collect_form(self._form_vars)
            db.execute(self.INSERT_SQL, values)
            self._refresh()
            self._clear_form(self._form_vars)
            messagebox.showinfo("Success", "Record added successfully.", parent=self)
        except Exception as e:
            messagebox.showerror("Error", str(e), parent=self)

    def _fetch_record(self):
        pk_val = self._edit_pk_var.get().strip()
        if not pk_val:
            # Also try from tree selection
            sel = self._tree.selection()
            if sel:
                pk_val = sel[0]
                self._edit_pk_var.set(pk_val)
            else:
                messagebox.showwarning("Input Required",
                                       "Enter a Record ID or select a row.",
                                       parent=self)
                return
        try:
            rows = db.fetch(self.FETCH_SQL, (pk_val,))
            if not rows:
                messagebox.showinfo("Not Found",
                                    f"No record with ID = {pk_val}",
                                    parent=self)
                return
            row = rows[0]
            for ff in self.FORM_FIELDS:
                val = row.get(ff.var_key.lower(), "")
                if val is None:
                    val = ""
                if ff.kind == "combo":
                    # Convert id → label
                    lbl = self._label_for(ff.var_key, val)
                    self._update_vars[ff.var_key].set(lbl)
                else:
                    self._update_vars[ff.var_key].set(str(val))
        except Exception as e:
            messagebox.showerror("Error", str(e), parent=self)

    def _on_double_click(self, event):
        """Double-click on a tree row → fill the update form."""
        sel = self._tree.selection()
        if sel:
            self._edit_pk_var.set(sel[0])
            self._fetch_record()

    def _update(self):
        pk_val = self._edit_pk_var.get().strip()
        if not pk_val:
            messagebox.showwarning("Input Required",
                                   "Fetch a record first.", parent=self)
            return
        try:
            values = self._collect_form(self._update_vars)
            values["id"] = pk_val
            db.execute(self.UPDATE_SQL, values)
            self._refresh()
            messagebox.showinfo("Success", "Record updated.", parent=self)
        except Exception as e:
            messagebox.showerror("Error", str(e), parent=self)

    def _delete(self):
        pk_val = self._edit_pk_var.get().strip()
        if not pk_val:
            sel = self._tree.selection()
            if sel:
                pk_val = sel[0]
            else:
                messagebox.showwarning("Input Required",
                                       "Select or enter a record ID to delete.",
                                       parent=self)
                return
        if not messagebox.askyesno("Confirm Delete",
                                   f"Delete record with ID = {pk_val}?",
                                   parent=self):
            return
        try:
            db.execute(self.DELETE_SQL, (pk_val,))
            self._refresh()
            self._edit_pk_var.set("")
            self._clear_form(self._update_vars)
            messagebox.showinfo("Deleted", "Record deleted.", parent=self)
        except Exception as e:
            messagebox.showerror("Error", f"Cannot delete:\n{e}", parent=self)

    def _clear_form(self, vars_dict: dict):
        for v in vars_dict.values():
            v.set("")
