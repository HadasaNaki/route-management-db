-- ======================================================
-- 07_alter_tables.sql  (Stage 4 schema additions)
-- Description: Extra columns / tables required by the Stage 4
--   PL/pgSQL programs and the Stage 5 GUI.
--   Runs AFTER data is loaded (03 + 06) so CurrentBookings can be
--   synced from the existing registrations.
--   Mirrors "שלב ד/AlterTable.sql".
-- ======================================================

SET search_path TO public;

-- Add CurrentBookings counter to GUIDEDTOUR for capacity tracking
-- in triggers / procedures / the GUI Trips screen.
ALTER TABLE GUIDEDTOUR ADD COLUMN IF NOT EXISTS CurrentBookings INT DEFAULT 0
    CHECK (CurrentBookings >= 0);

-- Sync initial values based on non-cancelled registrations already loaded.
UPDATE GUIDEDTOUR t
SET CurrentBookings = (
    SELECT COUNT(*)
    FROM REGISTRATION b
    WHERE b.TourID = t.TripID
      AND b.RegistrationStatusID != 3  -- exclude Cancelled
);

-- Audit table populated by the AFTER UPDATE trigger on REGISTRATION.
CREATE TABLE IF NOT EXISTS REGISTRATION_AUDIT (
    AuditID          SERIAL PRIMARY KEY,
    RegistrationID   INT NOT NULL,
    ChangedAt        TIMESTAMP DEFAULT NOW(),
    OldStatusID      INT,
    NewStatusID      INT,
    ChangedBy        VARCHAR(50) DEFAULT CURRENT_USER
);
