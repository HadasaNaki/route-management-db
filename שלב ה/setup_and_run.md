# Setup & Run Instructions — Stage 5 GUI

## Prerequisites

| Requirement | Version |
|---|---|
| Docker Desktop | any recent |
| Python | 3.10+ |
| psycopg2-binary | 2.9+ |

---

## 1. Start the Database (Docker)

From the **project root** (`שלב ה/../` or wherever `docker-compose.yml` lives):

```bash
docker compose up -d
```

Wait a few seconds until PostgreSQL is fully up.  
Confirm with:

```bash
docker exec postgres_db psql -U admin -d routes_db -c "SELECT version();"
```

### Connection details
| Field | Value |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `routes_db` |
| User | `admin` |
| Password | `admin` |

---

## 2. Install Python Dependencies

```bash
cd "שלב ה"
pip install -r requirements.txt
```

Or with the project venv:

```bash
.\venv\Scripts\activate        # Windows
pip install -r "שלב ה/requirements.txt"
```

---

## 3. Run the Application

```bash
cd "שלב ה/app"
python main.py
```

The app checks the DB connection before opening.  
If the connection fails, an error dialog will appear with troubleshooting hints.

---

## 4. Application Screens

| Screen | Description |
|---|---|
| **Dashboard** | Overview stats + recent bookings + quick-nav buttons |
| **Trips** | CRUD for `TRIP` table (links to Route, Guide, Status) |
| **Bookings** | CRUD for `BOOKING` table (links to Participant, Trip, Status) |
| **Participants** | CRUD for `PARTICIPANT` table |
| **Guides** | CRUD for `GUIDE` table |
| **Routes** | CRUD for `ROUTE` table (links to DifficultyLevel) |
| **Payments** | CRUD for `PAYMENT` table (links to Booking, Status) |
| **Queries & Programs** | 5 Stage-2 SQL queries + 4 Stage-4 PL/pgSQL programs |

---

## 5. CRUD Usage

### Add a Record
1. Fill in the form fields on the right panel under **"Add New Record"**.
2. Click **➕ Add Record**.

### Update a Record
1. Double-click any row in the table **or** type the Record ID in the Update section.
2. Click **🔍 Fetch Record** — form fields will auto-fill.
3. Edit the desired fields.
4. Click **💾 Save Update**.

### Delete a Record
1. Fetch the record (as above).
2. Click **🗑 Delete**.

---

## 6. Queries & Programs

- Select any item from the left panel.
- Fill in any parameters shown (default values are pre-filled).
- Click **▶ Run**.
- Results appear as a table (for queries / functions) or as NOTICE output (for procedures).

### Stage-2 Queries included
| ID | Description |
|---|---|
| Q1 | Participants in Historic/Nature tours |
| Q2 | Routes with ≥ N trips in 2026 (parameterised) |
| Q3 | Guides not assigned in May 2026 |
| Q4 | Most popular booking month in 2026 |
| Q5 | Trips with above-average capacity |

### Stage-4 PL/pgSQL Programs included
| ID | Description |
|---|---|
| P1 | `func_trip_revenue_report()` — revenue report via REFCURSOR |
| P2 | `func_get_participant_history(id)` — participant history via REFCURSOR |
| P3 | `proc_register_participant(trip, participant, notes)` — register booking |
| P4 | `proc_process_expired_bookings()` — cancel stale bookings |

---

## 7. Tools Used

- **Python 3.10+** — application language
- **Tkinter / ttk** — GUI framework (built-in, no install needed)
- **psycopg2-binary** — PostgreSQL adapter
- **PostgreSQL 15** (via Docker) — database engine
