#!/usr/bin/env python3
# ============================================================
# main.py  –  Application entry point
# Run with:  python main.py
# ============================================================
import sys
import os
import tkinter as tk
from tkinter import messagebox

# Make sure all modules in this folder are importable
sys.path.insert(0, os.path.dirname(__file__))

import styles as s
import widgets as w
import db

from dashboard    import DashboardScreen
from trips        import TripsScreen
from bookings     import BookingsScreen
from participants import ParticipantsScreen
from guides       import GuidesScreen
from routes       import RoutesScreen
from payments     import PaymentsScreen
from queries      import QueriesScreen


_SCREENS = {
    "dashboard":    ("🏠",  "Dashboard",          DashboardScreen),
    "trips":        ("✈️",  "Trips",               TripsScreen),
    "bookings":     ("📋",  "Bookings",            BookingsScreen),
    "participants": ("👥",  "Participants",        ParticipantsScreen),
    "guides":       ("👤",  "Guides",              GuidesScreen),
    "routes":       ("🗺️", "Routes",              RoutesScreen),
    "payments":     ("💳",  "Payments",            PaymentsScreen),
    "queries":      ("🔍",  "Queries & Programs",  QueriesScreen),
}


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Guided Tours Management System")
        self.geometry("1300x780")
        self.minsize(1000, 620)
        self.configure(bg=s.BG_CONTENT)

        # Set window icon (no .ico needed)
        try:
            self.iconbitmap(default="")
        except Exception:
            pass

        w.apply_ttk_style(self)
        self._active = None
        self._frame  = None

        self._build_header()
        self._build_body()
        self._show("dashboard")

    # ── Header bar ───────────────────────────────────────────
    def _build_header(self):
        hdr = tk.Frame(self, bg=s.BG_HEADER, height=52)
        hdr.pack(fill=tk.X, side=tk.TOP)
        hdr.pack_propagate(False)

        tk.Label(hdr, text="🗺  Guided Tours Management System",
                 bg=s.BG_HEADER, fg=s.T_LIGHT,
                 font=("Segoe UI", 14, "bold")).pack(side=tk.LEFT,
                                                     padx=22, pady=10)
        self._breadcrumb = tk.Label(hdr, text="",
                                    bg=s.BG_HEADER, fg=s.T_NAV,
                                    font=("Segoe UI", 11))
        self._breadcrumb.pack(side=tk.LEFT, padx=4)

        # DB status indicator
        tk.Label(hdr, text="● Connected to routes_db",
                 bg=s.BG_HEADER, fg="#22C55E",
                 font=("Segoe UI", 9)).pack(side=tk.RIGHT, padx=18)

    # ── Body (sidebar + content) ─────────────────────────────
    def _build_body(self):
        body = tk.Frame(self, bg=s.BG_CONTENT)
        body.pack(fill=tk.BOTH, expand=True)

        # Sidebar
        self._sidebar = tk.Frame(body, bg=s.BG_SIDEBAR, width=215)
        self._sidebar.pack(fill=tk.Y, side=tk.LEFT)
        self._sidebar.pack_propagate(False)

        # Content area
        self._content = tk.Frame(body, bg=s.BG_CONTENT)
        self._content.pack(fill=tk.BOTH, expand=True)

        # Build nav buttons
        self._nav_btns: dict[str, tk.Button] = {}

        # Top spacer
        tk.Frame(self._sidebar, bg=s.BG_SIDEBAR, height=16).pack(fill=tk.X)

        for key, (icon, label, _cls) in _SCREENS.items():
            btn = tk.Button(
                self._sidebar,
                text=f"   {icon}  {label}",
                anchor="w", relief="flat", bd=0,
                bg=s.BG_SIDEBAR, fg=s.T_NAV,
                activebackground=s.BG_SIDEBAR_H,
                activeforeground=s.T_LIGHT,
                font=s.F_NAV, cursor="hand2",
                padx=8, pady=11,
                command=lambda k=key: self._show(k),
            )
            btn.pack(fill=tk.X, padx=6, pady=2)
            self._nav_btns[key] = btn

            btn.bind("<Enter>", lambda e, b=btn, k=key:
                     b.config(bg=s.BG_SIDEBAR_H, fg=s.T_LIGHT)
                     if k != self._active else None)
            btn.bind("<Leave>", lambda e, b=btn, k=key:
                     b.config(bg=s.A_BLUE if k == self._active else s.BG_SIDEBAR,
                              fg=s.T_LIGHT if k == self._active else s.T_NAV))

        # Separator & version
        tk.Frame(self._sidebar, bg="#1E293B", height=1).pack(
            fill=tk.X, padx=12, pady=8)
        tk.Label(self._sidebar, text="DB Project  •  Stage 5",
                 bg=s.BG_SIDEBAR, fg="#334155",
                 font=("Segoe UI", 8)).pack(side=tk.BOTTOM, pady=10)

    # ── Screen switching ─────────────────────────────────────
    def _show(self, key: str):
        # Reset old button
        if self._active and self._active in self._nav_btns:
            self._nav_btns[self._active].config(
                bg=s.BG_SIDEBAR, fg=s.T_NAV)

        self._active = key
        self._nav_btns[key].config(bg=s.A_BLUE, fg=s.T_LIGHT)

        # Update breadcrumb
        icon, label, _ = _SCREENS[key]
        self._breadcrumb.config(text=f"›  {label}")

        # Destroy current frame and build new one
        if self._frame:
            self._frame.destroy()

        _cls = _SCREENS[key][2]
        self._frame = _cls(self._content, self)
        self._frame.pack(fill=tk.BOTH, expand=True)

    # Public method so screens can navigate
    def _show_screen(self, key: str):
        self._show(key)


# ── Entry point ──────────────────────────────────────────────
def main():
    # Test DB connection before opening the window
    try:
        db.fetch("SELECT 1 AS ok")
    except Exception as e:
        root = tk.Tk()
        root.withdraw()
        messagebox.showerror(
            "Database Connection Error",
            f"Cannot connect to PostgreSQL:\n\n{e}\n\n"
            "Make sure:\n"
            "  • Docker Desktop is running\n"
            "  • docker-compose is up  (docker compose up -d)\n"
            "  • Port 5432 is accessible",
        )
        root.destroy()
        sys.exit(1)

    app = App()
    app.mainloop()


if __name__ == "__main__":
    main()
