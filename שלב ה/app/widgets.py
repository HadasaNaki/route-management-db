# ============================================================
# widgets.py  –  Reusable Tkinter widget helpers
# ============================================================
import tkinter as tk
from tkinter import ttk
import styles as s


def apply_ttk_style(root: tk.Tk):
    """Configure a consistent ttk style for the whole application."""
    style = ttk.Style(root)
    style.theme_use("clam")

    # Treeview
    style.configure("Treeview",
        background=s.BG_CARD, foreground=s.T_DARK,
        fieldbackground=s.BG_CARD, rowheight=27,
        font=s.F_BODY, relief="flat", borderwidth=0)
    style.configure("Treeview.Heading",
        background=s.TBL_HDR_BG, foreground=s.TBL_HDR_FG,
        font=("Segoe UI", 10, "bold"), relief="flat",
        padding=(6, 6))
    style.map("Treeview",
        background=[("selected", s.A_BLUE)],
        foreground=[("selected", s.T_LIGHT)])

    # Buttons
    for name, bg in [
        ("Add.TButton",    s.A_GREEN),
        ("Edit.TButton",   s.A_AMBER),
        ("Delete.TButton", s.A_RED),
        ("Fetch.TButton",  s.A_BLUE),
        ("Run.TButton",    s.A_PURPLE),
        ("Refresh.TButton", s.T_MUTED),
    ]:
        style.configure(name, background=bg, foreground=s.T_LIGHT,
                        font=s.F_BTN, padding=(10, 5), relief="flat",
                        borderwidth=0)
        style.map(name,
                  background=[("active", bg), ("pressed", bg)],
                  relief=[("pressed", "flat")])

    # Entry & Combobox
    style.configure("TEntry", font=s.F_BODY, padding=5,
                    fieldbackground=s.BG_CARD)
    style.configure("TCombobox", font=s.F_BODY, padding=4)
    style.map("TCombobox",
              fieldbackground=[("readonly", s.BG_CARD)],
              selectbackground=[("readonly", s.BG_CARD)],
              selectforeground=[("readonly", s.T_DARK)])

    # Scrollbar
    style.configure("TScrollbar", troughcolor=s.BG_CONTENT,
                    background=s.T_NAV, arrowsize=12)

    # Separator
    style.configure("TSeparator", background=s.TBL_BORDER)

    # LabelFrame
    style.configure("TLabelframe", background=s.BG_CARD,
                    foreground=s.T_DARK, bordercolor=s.TBL_BORDER)
    style.configure("TLabelframe.Label", background=s.BG_CARD,
                    foreground=s.A_BLUE, font=s.F_SECTION)


def scrolled_tree(parent, columns: list[tuple], height=14) -> tuple:
    """
    Create a Treeview with vertical+horizontal scrollbars.
    columns: list of (key, heading, width)
    Returns (outer_frame, tree)
    """
    outer = tk.Frame(parent, bg=s.BG_CARD,
                     highlightthickness=1,
                     highlightbackground=s.TBL_BORDER)

    tree = ttk.Treeview(outer,
                        columns=[c[0] for c in columns],
                        show="headings", height=height)

    vsb = ttk.Scrollbar(outer, orient="vertical", command=tree.yview)
    hsb = ttk.Scrollbar(outer, orient="horizontal", command=tree.xview)
    tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

    for key, heading, width in columns:
        tree.heading(key, text=heading, anchor="w")
        tree.column(key, width=width, minwidth=50, anchor="w")

    tree.tag_configure("odd",  background=s.TBL_ROW_ODD)
    tree.tag_configure("even", background=s.TBL_ROW_EVEN)

    tree.grid(row=0, column=0, sticky="nsew")
    vsb.grid(row=0, column=1, sticky="ns")
    hsb.grid(row=1, column=0, sticky="ew")
    outer.grid_rowconfigure(0, weight=1)
    outer.grid_columnconfigure(0, weight=1)

    return outer, tree


def populate_tree(tree: ttk.Treeview, rows: list[dict],
                  col_keys: list[str], pk_key: str):
    """
    Populate a Treeview from rows.
    Uses pk_key as iid (hidden row ID for DB operations).
    """
    tree.delete(*tree.get_children())
    for i, row in enumerate(rows):
        tag = "even" if i % 2 == 0 else "odd"
        vals = [row.get(k, "") for k in col_keys]
        vals = ["" if v is None else v for v in vals]
        tree.insert("", tk.END,
                    iid=str(row[pk_key]),
                    values=vals, tags=(tag,))


def form_row(parent, row: int, label: str,
             bg=None, pady=4) -> tuple[tk.StringVar, ttk.Entry]:
    """Add a Label + Entry to a grid parent. Returns (StringVar, Entry)."""
    bg = bg or s.BG_CARD
    tk.Label(parent, text=label, bg=bg, fg=s.T_DARK,
             font=s.F_BODY, anchor="e").grid(
        row=row, column=0, sticky="e", padx=(4, 6), pady=pady)
    var = tk.StringVar()
    entry = ttk.Entry(parent, textvariable=var, width=28)
    entry.grid(row=row, column=1, sticky="ew", pady=pady, padx=(0, 4))
    return var, entry


def form_combo(parent, row: int, label: str,
               values=None, bg=None, pady=4) -> tuple[tk.StringVar, ttk.Combobox]:
    """Add a Label + Combobox to a grid parent. Returns (StringVar, Combobox)."""
    bg = bg or s.BG_CARD
    values = values or []
    tk.Label(parent, text=label, bg=bg, fg=s.T_DARK,
             font=s.F_BODY, anchor="e").grid(
        row=row, column=0, sticky="e", padx=(4, 6), pady=pady)
    var = tk.StringVar()
    combo = ttk.Combobox(parent, textvariable=var,
                         values=values, state="readonly", width=26)
    combo.grid(row=row, column=1, sticky="ew", pady=pady, padx=(0, 4))
    return var, combo


def section_sep(parent, title: str, bg=None):
    """A thin separator with a bold label – used between form sections."""
    bg = bg or s.BG_CARD
    f = tk.Frame(parent, bg=bg)
    tk.Frame(f, bg=s.TBL_BORDER, height=1).pack(fill=tk.X, pady=(10, 4))
    tk.Label(f, text=f"  {title}", bg=bg, fg=s.A_BLUE,
             font=s.F_SECTION).pack(anchor="w")
    return f


def stat_card(parent, title: str, value, color=None) -> tk.Frame:
    """A small rounded statistics card for the dashboard."""
    color = color or s.A_BLUE
    card = tk.Frame(parent, bg=color, padx=18, pady=14)
    tk.Label(card, text=str(value), bg=color, fg=s.T_LIGHT,
             font=("Segoe UI", 24, "bold")).pack()
    tk.Label(card, text=title, bg=color, fg=s.T_LIGHT,
             font=s.F_BODY).pack()
    return card
