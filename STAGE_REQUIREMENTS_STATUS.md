# Stage Requirements Status

This file maps course requirements to the current repository structure for Stage A, Stage B, and Stage C.

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
- [~] Backup file named `backup3`: not found in `שלב ג`.

## Git Hygiene Notes

- Keep each stage in a dedicated commit where possible.
- Use clear commit messages in English or Hebrew with a scope, for example:
  - `fix(stage-a): add missing selectAll.sql and clean duplicate inserts`
  - `docs: align README paths and stage requirements status`
- Keep stage tags consistent (`stage-a`, `stage-b`, `stage-c` style).
