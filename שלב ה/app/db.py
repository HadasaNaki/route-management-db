# ============================================================
# db.py  –  Database layer (psycopg2 / PostgreSQL)
# ============================================================
import psycopg2
import psycopg2.extras
from contextlib import contextmanager

DB_CONFIG = {
    "host":     "localhost",
    "port":     5432,
    "dbname":   "routes_db",
    "user":     "admin",
    "password": "admin",
}


@contextmanager
def _conn():
    """Open a connection, commit on success, rollback on error."""
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def fetch(query: str, params=None) -> list[dict]:
    """Return all rows as list of dicts."""
    with _conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, params or ())
            return [dict(r) for r in cur.fetchall()]


def execute(query: str, params=None) -> int:
    """Execute DML (INSERT / UPDATE / DELETE). Returns row-count."""
    with _conn() as conn:
        with conn.cursor() as cur:
            cur.execute(query, params or ())
            return cur.rowcount


def next_id(table: str, pk_col: str) -> int:
    """Return MAX(pk)+1 for simple sequential IDs."""
    rows = fetch(f"SELECT COALESCE(MAX({pk_col}), 0)+1 AS nid FROM {table}")
    return rows[0]["nid"]


def call_refcursor(func_call: str, params=None):
    """
    Call a PL/pgSQL function that returns a REFCURSOR.
    Returns (column_names: list, rows: list[dict]).
    func_call example: "func_trip_revenue_report()"
    """
    cols, rows = [], []
    with _conn() as conn:
        with conn.cursor() as cur:
            if params:
                ph = ",".join(["%s"] * len(params))
                cur.execute(f"SELECT {func_call.split('(')[0]}({ph})", params)
            else:
                cur.execute(f"SELECT {func_call}")
            cursor_name = cur.fetchone()[0]

        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur2:
            cur2.execute(f'FETCH ALL FROM "{cursor_name}"')
            if cur2.description:
                cols = [d[0] for d in cur2.description]
            rows = [dict(r) for r in cur2.fetchall()]
    return cols, rows


def call_proc(proc_call: str, params=None) -> list[str]:
    """
    Call a PL/pgSQL procedure.
    Returns list of NOTICE messages captured during execution.
    """
    notices = []
    with _conn() as conn:
        conn.notices = notices
        with conn.cursor() as cur:
            if params:
                ph = ",".join(["%s"] * len(params))
                cur.execute(f"CALL {proc_call.split('(')[0]}({ph})", params)
            else:
                cur.execute(f"CALL {proc_call}")
    return [str(n).replace("NOTICE:  ", "").strip() for n in notices]
