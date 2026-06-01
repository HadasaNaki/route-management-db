# Stage Requirements Status

This file maps course requirements to the current repository structure for Stages A through E.

## Stage A (Design, Build, Populate, Backup)

Required folder: `שלב א`

- [x] ERD files: `שלב א/ERDandDSDfiles/`
- [x] DSD files: `שלב א/ERDandDSDfiles/`
- [x] `createTables.sql`: `שלב א/scripts/createTables.sql`
- [x] `dropTables.sql`: `שלב א/scripts/dropTables.sql`
- [x] `insertTables.sql`: `שלב א/scripts/insertTables.sql`
- [x] `selectAll.sql`: `שלב א/scripts/selectAll.sql`
- [x] Data import/generation folders: `שלב א/mockData`, `שלב א/python`
- [x] Backup folder: `שלב א/backup`

Notes:
- Duplicate INSERT blocks were removed from `שלב א/scripts/insertTables.sql` to prevent primary key collisions.

## Stage B (Queries, Constraints, Indexes, Transactions)

Required folder: `שלב ב`

- [x] `Queries.sql`: `שלב ב/Queries.sql`
- [x] `Constraints.sql`: `שלב ב/Constraints.sql`
- [x] `RollbackCommit.sql`: `שלב ב/RollbackCommit.sql`
- [x] `Index.sql`: `שלב ב/Index.sql`
- [~] Backup file named `backup2`: not found as a backup dump file in `שלב ב`.

## Stage C (Integration and Views)

Required folder: `שלב ג`

- [x] New unit DSD: `שלב ג/dsd_new.mmd`
- [x] New unit ERD: `שלב ג/erd_new.mmd`
- [x] Combined ERD: `שלב ג/erd_joint.mmd`
- [x] Integrated DSD: `שלב ג/dsd_joint.mmd`
- [x] `Integrate.sql`: `שלב ג/Integrate.sql`
- [x] `Views.sql`: `שלב ג/Views.sql`
- [x] Stage report: `שלב ג/דוח פרויקט שלב ג.md`
- [x] Backup file named `backup3`: `שלב ג/backup3.dump`

## Stage D (PL/pgSQL Programming)

Required folder: `שלב ד`

- [x] 2 Functions: `שלב ד/Function1.sql`, `שלב ד/Function2.sql`
- [x] 2 Procedures: `שלב ד/Procedure1.sql`, `שלב ד/Procedure2.sql`
- [x] 2 Triggers: `שלב ד/Trigger1.sql`, `שלב ד/Trigger2.sql`
- [x] 2 Main programs: `שלב ד/MainProgram1.sql`, `שלב ד/MainProgram2.sql`
- [x] Schema additions: `שלב ד/AlterTable.sql` (CurrentBookings + REGISTRATION_AUDIT)
- [x] Stage report: `שלב ד/דוח פרוייקט שלב ד.md`
- [x] Backup file named `backup4`: `שלב ד/backup4.dump`

## Stage E (Graphical User Interface)

Required folder: `שלב ה`

- [x] Application source: `שלב ה/app/` (Python + Tkinter + psycopg2)
- [x] CRUD screens for all tables (Trips, Bookings, Participants, Guides, Routes, Payments)
- [x] Foreign keys shown as readable names (not raw IDs)
- [x] Update-by-key with fetch-then-edit flow
- [x] Stage-2 queries (5) + Stage-4 programs (4) runnable from `queries.py`
- [x] Run instructions: `שלב ה/setup_and_run.md`
- [x] Report section in git README: "Stage 5: Graphical User Interface"
- [ ] GUI screenshots to be added under `שלב ה` per stage guidelines

## Integration / Docker Sync

- [x] `init-db/01`–`06`: drop/create/insert main schema + load `group2` + merge into `public`
- [x] `init-db/07_alter_tables.sql`: adds `CurrentBookings` + `REGISTRATION_AUDIT`
- [x] `init-db/08_views.sql`: Stage C views
- [x] `init-db/09_functions.sql`, `10_procedures.sql`, `11_triggers.sql`: Stage D objects
- Result: a fresh `docker compose up` produces a fully integrated DB matching the Stage 5 GUI.

## Git Hygiene Notes

- Keep each stage in a dedicated commit where possible.
- Use clear commit messages in English or Hebrew with a scope, for example:
  - `fix(stage-a): add missing selectAll.sql and clean duplicate inserts`
  - `docs: align README paths and stage requirements status`
- Keep stage tags consistent (`stage-a`, `stage-b`, `stage-c`, `stage-d`, `stage-e` style).
