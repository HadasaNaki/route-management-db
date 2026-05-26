# ============================================================
# queries.py  –  Queries (Stage 2) + PL/pgSQL Programs (Stage 4)
# ============================================================
import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import styles as s
import widgets as w
import db


# ── Stage 2 queries ──────────────────────────────────────────
QUERIES = {
    "Q1: Participants in Historic/Nature tours": {
        "description": "Find all participants who registered for a tour that passes through a 'Historic' or 'Nature' location.",
        "sql": """
            SELECT DISTINCT p.FullName, p.Phone, p.Email
            FROM PARTICIPANT p
            JOIN REGISTRATION b ON p.ParticipantID  = b.ParticipantID
            JOIN GUIDEDTOUR t   ON b.TourID          = t.TripID
            JOIN PASSES_THROUGH pt ON t.RouteID      = pt.RouteID
            JOIN LOCATION l     ON pt.LocationID     = l.LocationID
            WHERE l.Category IN ('Historic', 'Nature')
            ORDER BY p.FullName
        """,
        "cols": [("fullname","Full Name",200), ("phone","Phone",130), ("email","Email",220)],
        "params": [],
    },
    "Q2: Routes with ≥ N trips in 2026": {
        "description": "Show routes that have at least N scheduled tours in 2026. Enter the minimum tour count.",
        "sql": """
            SELECT r.Name AS RouteName, COUNT(t.TripID) AS TotalTrips
            FROM ROUTE r
            JOIN GUIDEDTOUR t ON r.RouteID = t.RouteID
            WHERE EXTRACT(YEAR FROM t.StartDate) = 2026
            GROUP BY r.RouteID, r.Name
            HAVING COUNT(t.TripID) >= %s
            ORDER BY TotalTrips DESC
        """,
        "cols": [("routename","Route Name",240), ("totaltrips","# Tours",100)],
        "params": [("Minimum tours (e.g. 1)", "1")],
    },
    "Q3: Guides not assigned in May 2026": {
        "description": "List guides who have no tours scheduled in May 2026.",
        "sql": """
            SELECT g.FirstName||' '||g.LastName AS GuideName,
                   g.Phone, g.Email
            FROM GUIDE g
            WHERE g.GuideID NOT IN (
                SELECT t.GuideID FROM GUIDEDTOUR t
                WHERE EXTRACT(YEAR FROM t.StartDate)  = 2026
                  AND EXTRACT(MONTH FROM t.StartDate) = 5
            )
            ORDER BY g.LastName
        """,
        "cols": [("guidename","Guide Name",200), ("phone","Phone",130), ("email","Email",200)],
        "params": [],
    },
    "Q4: Most popular registration month in 2026": {
        "description": "Find the month in 2026 with the highest number of registrations.",
        "sql": """
            SELECT TO_CHAR(TO_DATE(month_num::text,'MM'),'Month') AS MonthName,
                   TotalRegistrations
            FROM (
                SELECT EXTRACT(MONTH FROM RegistrationDate)::INT AS month_num,
                       COUNT(*) AS TotalRegistrations
                FROM REGISTRATION
                WHERE EXTRACT(YEAR FROM RegistrationDate) = 2026
                GROUP BY EXTRACT(MONTH FROM RegistrationDate)
                ORDER BY TotalRegistrations DESC
                LIMIT 5
            ) sub
        """,
        "cols": [("monthname","Month",150), ("totalregistrations","Registrations",120)],
        "params": [],
    },
    "Q5: Tours with above-average capacity": {
        "description": "Show tours whose MaxParticipants is greater than the overall average, ordered by date.",
        "sql": """
            SELECT t.TripID, r.Name AS RouteName,
                   g.FirstName||' '||g.LastName AS GuideName,
                   TO_CHAR(t.StartDate,'YYYY-MM-DD') AS StartDate,
                   t.MaxParticipants, ts.StatusName AS Status
            FROM GUIDEDTOUR t
            JOIN ROUTE r           ON t.RouteID      = r.RouteID
            JOIN GUIDE g           ON t.GuideID      = g.GuideID
            LEFT JOIN TOURSTATUS ts ON t.TourStatusID = ts.TourStatusID
            WHERE t.MaxParticipants > (SELECT AVG(MaxParticipants) FROM GUIDEDTOUR)
            ORDER BY t.StartDate
        """,
        "cols": [
            ("tripid","Tour ID",70), ("routename","Route",180),
            ("guidename","Guide",160), ("startdate","Start Date",110),
            ("maxparticipants","Max Cap",80), ("status","Status",130),
        ],
        "params": [],
    },
}

# ── Stage 4 programs ─────────────────────────────────────────
PROGRAMS = {
    "P1: Trip Revenue Report": {
        "description": "Calls func_trip_revenue_report() — returns a revenue summary for every trip (occupancy, expected income, classification).",
        "kind": "refcursor",
        "call": "func_trip_revenue_report()",
        "params": [],
    },
    "P2: Participant Booking History": {
        "description": "Calls func_get_participant_history(p_id) — returns the full booking history for a specific participant.",
        "kind": "refcursor",
        "call": "func_get_participant_history",
        "params": [("Participant ID", "1")],
    },
    "P3: Register Participant for a Tour": {
        "description": "Calls proc_register_participant(trip_id, participant_id, notes) — validates and creates a new registration.",
        "kind": "procedure",
        "call": "proc_register_participant",
        "params": [
            ("Tour ID",        "1002"),
            ("Participant ID", "2"),
            ("Notes",          "Registered from GUI"),
        ],
    },
    "P4: Process Expired Registrations": {
        "description": "Calls proc_process_expired_bookings() — cancels stale registrations for tours that started more than 7 days ago.",
        "kind": "procedure",
        "call": "proc_process_expired_bookings()",
        "params": [],
    },
}


class QueriesScreen(tk.Frame):
    def __init__(self, parent, app):
        super().__init__(parent, bg=s.BG_CONTENT)
        self.app = app
        self._param_vars: list[tk.StringVar] = []
        self._param_frame: tk.Frame | None = None
        self._current_item: dict | None = None
        self._current_kind: str = "query"   # "query" | "program"
        self._build()

    def _build(self):
        # Title
        title_bar = tk.Frame(self, bg=s.BG_CONTENT)
        title_bar.pack(fill=tk.X, padx=20, pady=(18, 6))
        tk.Label(title_bar, text="🔍  Queries & PL/pgSQL Programs",
                 bg=s.BG_CONTENT, fg=s.T_DARK,
                 font=s.F_TITLE).pack(side=tk.LEFT)

        # PanedWindow: left = menu, right = detail + results
        pane = tk.PanedWindow(self, orient=tk.HORIZONTAL,
                              bg=s.BG_CONTENT, bd=0,
                              sashrelief="flat", sashwidth=6)
        pane.pack(fill=tk.BOTH, expand=True, padx=10, pady=(0, 10))

        # ── Left panel: query/program list ──────────────────
        left = tk.Frame(pane, bg=s.BG_CARD,
                        highlightthickness=1,
                        highlightbackground=s.TBL_BORDER)
        pane.add(left, stretch="never", minsize=260)

        tk.Label(left, text="  Stage 2 — SQL Queries",
                 bg=s.BG_CARD, fg=s.A_BLUE,
                 font=s.F_SECTION).pack(anchor="w", padx=8, pady=(12, 4))

        for name in QUERIES:
            btn = tk.Button(left, text=f"  {name}",
                            anchor="w", relief="flat", bd=0,
                            bg=s.BG_CARD, fg=s.T_DARK,
                            activebackground=s.TBL_SEL_BG,
                            font=s.F_BODY, cursor="hand2",
                            wraplength=230, justify="left",
                            pady=7, padx=6,
                            command=lambda n=name: self._select("query", n))
            btn.pack(fill=tk.X, padx=4, pady=1)
            btn.bind("<Enter>", lambda e, b=btn: b.config(bg=s.TBL_SEL_BG))
            btn.bind("<Leave>", lambda e, b=btn: b.config(bg=s.BG_CARD))

        ttk.Separator(left, orient="horizontal").pack(fill=tk.X, pady=8, padx=8)
        tk.Label(left, text="  Stage 4 — PL/pgSQL Programs",
                 bg=s.BG_CARD, fg=s.A_PURPLE,
                 font=s.F_SECTION).pack(anchor="w", padx=8, pady=(0, 4))

        for name in PROGRAMS:
            btn = tk.Button(left, text=f"  {name}",
                            anchor="w", relief="flat", bd=0,
                            bg=s.BG_CARD, fg=s.T_DARK,
                            activebackground="#EDE9FE",
                            font=s.F_BODY, cursor="hand2",
                            wraplength=230, justify="left",
                            pady=7, padx=6,
                            command=lambda n=name: self._select("program", n))
            btn.pack(fill=tk.X, padx=4, pady=1)
            btn.bind("<Enter>", lambda e, b=btn: b.config(bg="#EDE9FE"))
            btn.bind("<Leave>", lambda e, b=btn: b.config(bg=s.BG_CARD))

        # ── Right panel: detail + results ───────────────────
        right = tk.Frame(pane, bg=s.BG_CONTENT)
        pane.add(right, stretch="always", minsize=500)

        # Description card
        self._desc_var = tk.StringVar(value="← Select a query or program from the left.")
        desc_card = tk.Frame(right, bg=s.BG_CARD,
                             highlightthickness=1,
                             highlightbackground=s.TBL_BORDER)
        desc_card.pack(fill=tk.X, padx=8, pady=(8, 4))
        tk.Label(desc_card, textvariable=self._desc_var,
                 bg=s.BG_CARD, fg=s.T_MUTED,
                 font=s.F_BODY, anchor="w", justify="left",
                 wraplength=700).pack(anchor="w", padx=12, pady=10)

        # Parameters area
        self._param_outer = tk.Frame(right, bg=s.BG_CARD,
                                     highlightthickness=1,
                                     highlightbackground=s.TBL_BORDER)
        self._param_outer.pack(fill=tk.X, padx=8, pady=2)
        self._param_inner = tk.Frame(self._param_outer, bg=s.BG_CARD)
        self._param_inner.pack(fill=tk.X, padx=10, pady=8)

        # Run button
        self._run_btn = ttk.Button(right, text="▶  Run",
                                   style="Run.TButton",
                                   state="disabled",
                                   command=self._run)
        self._run_btn.pack(pady=(6, 4), padx=8, anchor="w")

        # Results area
        res_lf = tk.LabelFrame(right, text="  Results",
                               bg=s.BG_CARD, fg=s.A_BLUE,
                               font=s.F_SECTION,
                               relief="flat",
                               highlightthickness=1,
                               highlightbackground=s.TBL_BORDER)
        res_lf.pack(fill=tk.BOTH, expand=True, padx=8, pady=(2, 8))

        # Treeview for tabular results
        self._result_frame = tk.Frame(res_lf, bg=s.BG_CARD)
        self._result_frame.pack(fill=tk.BOTH, expand=True, padx=6, pady=6)

        # Text widget for procedure notices
        self._notice_text = scrolledtext.ScrolledText(
            res_lf, wrap=tk.WORD, height=10,
            bg="#1E293B", fg="#86EFAC",
            font=s.F_MONO, state="disabled",
            relief="flat", bd=0)

        # Row count label
        self._row_count_var = tk.StringVar(value="")
        tk.Label(res_lf, textvariable=self._row_count_var,
                 bg=s.BG_CARD, fg=s.T_MUTED,
                 font=s.F_SMALL).pack(anchor="e", padx=6, pady=(0, 4))

    # ── Interaction ──────────────────────────────────────────
    def _select(self, kind: str, name: str):
        if kind == "query":
            self._current_item = QUERIES[name]
        else:
            self._current_item = PROGRAMS[name]
        self._current_kind = kind
        self._desc_var.set(self._current_item["description"])
        self._build_params(self._current_item["params"])
        self._run_btn.config(state="normal")
        self._clear_results()

    def _build_params(self, param_defs: list):
        for w_ in self._param_inner.winfo_children():
            w_.destroy()
        self._param_vars.clear()

        if not param_defs:
            tk.Label(self._param_inner, text="No parameters required.",
                     bg=s.BG_CARD, fg=s.T_MUTED,
                     font=s.F_SMALL).pack(anchor="w")
            return

        for label, default in param_defs:
            row_f = tk.Frame(self._param_inner, bg=s.BG_CARD)
            row_f.pack(fill=tk.X, pady=3)
            tk.Label(row_f, text=f"{label}:", bg=s.BG_CARD, fg=s.T_DARK,
                     font=s.F_BODY, width=22, anchor="e").pack(side=tk.LEFT)
            var = tk.StringVar(value=default)
            ttk.Entry(row_f, textvariable=var, width=22).pack(
                side=tk.LEFT, padx=(6, 0))
            self._param_vars.append(var)

    def _clear_results(self):
        for child in self._result_frame.winfo_children():
            child.destroy()
        self._notice_text.pack_forget()
        self._row_count_var.set("")

    def _run(self):
        if not self._current_item:
            return
        params = [v.get().strip() for v in self._param_vars]
        self._clear_results()

        try:
            if self._current_kind == "query":
                self._run_query(self._current_item, params)
            else:
                self._run_program(self._current_item, params)
        except Exception as e:
            messagebox.showerror("Error", str(e), parent=self)

    def _run_query(self, item: dict, params: list):
        rows = db.fetch(item["sql"], params if params else None)
        self._show_table(item["cols"], rows,
                         pk_key=item["cols"][0][0])

    def _run_program(self, item: dict, params: list):
        kind = item["kind"]

        if kind == "refcursor":
            if params:
                cols, rows = db.call_refcursor(item["call"], params)
            else:
                cols, rows = db.call_refcursor(item["call"])

            if not cols:
                self._notice_text.config(state="normal")
                self._notice_text.delete("1.0", tk.END)
                self._notice_text.insert(tk.END, "Function executed — no rows returned.")
                self._notice_text.config(state="disabled")
                self._notice_text.pack(fill=tk.BOTH, expand=True, padx=6, pady=6)
                return

            display_cols = [(c, c.replace("_", " ").title(), 120) for c in cols]
            self._show_table(display_cols, rows, pk_key=cols[0])

        elif kind == "procedure":
            notices = db.call_proc(item["call"], params if params else None)
            self._notice_text.config(state="normal")
            self._notice_text.delete("1.0", tk.END)
            self._notice_text.insert(tk.END,
                f"Procedure: {item['call']}\nParameters: {params}\n"
                + "─" * 50 + "\n")
            for line in notices:
                self._notice_text.insert(tk.END, line + "\n")
            if not notices:
                self._notice_text.insert(tk.END,
                    "(Procedure completed with no NOTICE output)")
            self._notice_text.config(state="disabled")
            self._notice_text.pack(fill=tk.BOTH, expand=True, padx=6, pady=6)
            self._row_count_var.set("✓ Procedure completed successfully")

    def _show_table(self, cols: list, rows: list[dict], pk_key: str):
        outer, tree = w.scrolled_tree(self._result_frame, cols, height=14)
        outer.pack(fill=tk.BOTH, expand=True)

        for i, row in enumerate(rows):
            tag = "even" if i % 2 == 0 else "odd"
            vals = [str(row.get(c[0].lower(), row.get(c[0], "")))
                    if row.get(c[0].lower(), row.get(c[0], "")) is not None
                    else "" for c in cols]
            tree.insert("", tk.END, iid=str(i), values=vals, tags=(tag,))

        count = len(rows)
        self._row_count_var.set(
            f"{count} row{'s' if count != 1 else ''} returned"
            if count else "No results found.")
