# ============================================================
# dashboard.py  –  Main dashboard screen
# ============================================================
import tkinter as tk
from tkinter import ttk
import styles as s
import widgets as w
import db


class DashboardScreen(tk.Frame):
    def __init__(self, parent, app):
        super().__init__(parent, bg=s.BG_CONTENT)
        self.app = app
        self._build()

    def _build(self):
        # ── Title ────────────────────────────────────────────
        title_bar = tk.Frame(self, bg=s.BG_CONTENT)
        title_bar.pack(fill=tk.X, padx=30, pady=(28, 4))
        tk.Label(title_bar, text="🏠  Dashboard",
                 bg=s.BG_CONTENT, fg=s.T_DARK,
                 font=s.F_TITLE).pack(side=tk.LEFT)
        tk.Label(title_bar, text="Overview of your guided-tours database",
                 bg=s.BG_CONTENT, fg=s.T_MUTED,
                 font=s.F_BODY).pack(side=tk.LEFT, padx=16)

        # ── Stats row ────────────────────────────────────────
        stats_frame = tk.Frame(self, bg=s.BG_CONTENT)
        stats_frame.pack(fill=tk.X, padx=30, pady=10)

        stats = self._load_stats()
        colors = [s.A_BLUE, s.A_GREEN, s.A_AMBER, s.A_RED, s.A_PURPLE, "#0891B2"]
        for i, (title, val) in enumerate(stats):
            card = w.stat_card(stats_frame, title, val, colors[i % len(colors)])
            card.grid(row=0, column=i, padx=8, pady=4, ipadx=4)

        # ── Quick Nav ────────────────────────────────────────
        nav_frame = tk.Frame(self, bg=s.BG_CARD,
                             relief="flat", bd=0,
                             highlightthickness=1,
                             highlightbackground=s.TBL_BORDER)
        nav_frame.pack(fill=tk.X, padx=30, pady=10)

        tk.Label(nav_frame, text="  Quick Navigation",
                 bg=s.BG_CARD, fg=s.T_DARK,
                 font=s.F_SECTION).pack(anchor="w", padx=10, pady=(10, 6))

        btn_row = tk.Frame(nav_frame, bg=s.BG_CARD)
        btn_row.pack(fill=tk.X, padx=10, pady=(0, 12))

        nav_items = [
            ("✈️  Trips",         "trips"),
            ("📋  Bookings",      "bookings"),
            ("👥  Participants",  "participants"),
            ("👤  Guides",        "guides"),
            ("🗺️  Routes",        "routes"),
            ("💳  Payments",      "payments"),
            ("🔍  Queries",       "queries"),
        ]
        for label, key in nav_items:
            btn = tk.Button(btn_row, text=label,
                            font=s.F_BTN, bg=s.A_BLUE, fg=s.T_LIGHT,
                            activebackground=s.BG_SIDEBAR_H,
                            activeforeground=s.T_LIGHT,
                            cursor="hand2", relief="flat",
                            bd=0, padx=14, pady=8,
                            command=lambda k=key: self.app._show_screen(k))
            btn.pack(side=tk.LEFT, padx=6)

        # ── Recent Bookings ───────────────────────────────────
        recent_frame = tk.LabelFrame(self, text="  Recent Bookings",
                                     bg=s.BG_CARD, fg=s.A_BLUE,
                                     font=s.F_SECTION,
                                     relief="flat", bd=1,
                                     highlightthickness=1,
                                     highlightbackground=s.TBL_BORDER)
        recent_frame.pack(fill=tk.BOTH, expand=True, padx=30, pady=10)

        cols = [
            ("bookingid",    "Booking #",  80),
            ("participantname","Participant",160),
            ("routename",    "Route",      180),
            ("departuredate","Departure",  110),
            ("amounttopay",  "Amount",     90),
            ("statusname",   "Status",     120),
        ]
        _, tree = w.scrolled_tree(recent_frame, cols, height=10)
        tree.pack(fill=tk.BOTH, expand=True, padx=8, pady=8)

        rows = db.fetch("""
            SELECT b.BookingID, p.FullName AS participantname,
                   r.RouteName, t.DepartureDate,
                   b.AmountToPay, rs.StatusName
            FROM BOOKING b
            JOIN PARTICIPANT p ON b.ParticipantID = p.ParticipantID
            JOIN TRIP t        ON b.TripID = t.TripID
            JOIN ROUTE r       ON t.RouteID = r.RouteID
            JOIN REGISTRATIONSTATUS rs ON b.RegistrationStatusID = rs.RegistrationStatusID
            ORDER BY b.BookingDate DESC LIMIT 20
        """)
        for i, row in enumerate(rows):
            tag = "even" if i % 2 == 0 else "odd"
            tree.insert("", tk.END,
                        iid=str(row["bookingid"]),
                        values=(row["bookingid"],
                                row["participantname"],
                                row["routename"],
                                str(row["departuredate"]),
                                f"₪{row['amounttopay']:.2f}" if row["amounttopay"] else "—",
                                row["statusname"]),
                        tags=(tag,))

    def _load_stats(self) -> list[tuple]:
        try:
            rows = db.fetch("""
                SELECT
                  (SELECT COUNT(*) FROM TRIP)        AS trips,
                  (SELECT COUNT(*) FROM BOOKING)     AS bookings,
                  (SELECT COUNT(*) FROM PARTICIPANT) AS participants,
                  (SELECT COUNT(*) FROM GUIDE)       AS guides,
                  (SELECT COUNT(*) FROM ROUTE)       AS routes,
                  (SELECT COUNT(*) FROM PAYMENT)     AS payments
            """)
            r = rows[0]
            return [
                ("Total Trips",        r["trips"]),
                ("Bookings",           r["bookings"]),
                ("Participants",       r["participants"]),
                ("Guides",             r["guides"]),
                ("Routes",             r["routes"]),
                ("Payments",           r["payments"]),
            ]
        except Exception:
            return [("N/A", "—")] * 6
