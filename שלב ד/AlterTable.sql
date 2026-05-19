-- ======================================================
-- Stage 4: PL/pgSQL Programming - Schema Additions
-- AlterTable.sql
-- Description: Additional columns needed to support Stage 4 programs.
-- ======================================================

-- Add CurrentBookings counter to TRIP for capacity tracking in triggers/procedures
ALTER TABLE TRIP ADD COLUMN IF NOT EXISTS CurrentBookings INT DEFAULT 0
    CHECK (CurrentBookings >= 0);

-- Sync initial values based on confirmed/pending bookings already in the system
UPDATE TRIP t
SET CurrentBookings = (
    SELECT COUNT(*)
    FROM BOOKING b
    WHERE b.TripID = t.TripID
      AND b.RegistrationStatusID != 3  -- exclude Cancelled
);

-- Add AuditLog table to record trigger-driven changes on BOOKING
CREATE TABLE IF NOT EXISTS BOOKING_AUDIT (
    AuditID       SERIAL PRIMARY KEY,
    BookingID     INT NOT NULL,
    ChangedAt     TIMESTAMP DEFAULT NOW(),
    OldStatusID   INT,
    NewStatusID   INT,
    ChangedBy     VARCHAR(50) DEFAULT CURRENT_USER
);
