-- ======================================================
-- Stage 4: PL/pgSQL Programming - Schema Additions
-- AlterTable.sql
-- Description: Additional columns needed to support Stage 4 programs.
-- ======================================================

-- Add CurrentBookings counter to GUIDEDTOUR for capacity tracking in triggers/procedures
ALTER TABLE GUIDEDTOUR ADD COLUMN IF NOT EXISTS CurrentBookings INT DEFAULT 0
    CHECK (CurrentBookings >= 0);

-- Sync initial values based on confirmed/pending registrations already in the system
UPDATE GUIDEDTOUR t
SET CurrentBookings = (
    SELECT COUNT(*)
    FROM REGISTRATION b
    WHERE b.TourID = t.TripID
      AND b.RegistrationStatusID != 3  -- exclude Cancelled
);

-- Add AuditLog table to record trigger-driven changes on REGISTRATION
CREATE TABLE IF NOT EXISTS REGISTRATION_AUDIT (
    AuditID          SERIAL PRIMARY KEY,
    RegistrationID   INT NOT NULL,
    ChangedAt        TIMESTAMP DEFAULT NOW(),
    OldStatusID      INT,
    NewStatusID      INT,
    ChangedBy        VARCHAR(50) DEFAULT CURRENT_USER
);
