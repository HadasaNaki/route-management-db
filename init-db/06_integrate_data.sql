-- ============================================================
-- 06_integrate_data.sql
-- Merges group2 schema data into the public schema.
-- Runs after 04_other_schema.sql and 05_other_data.sql.
-- Safe to re-run: all inserts use ON CONFLICT DO NOTHING.
-- ============================================================

SET search_path TO public;

-- Disable row triggers for bulk import (FK checks also bypassed)
SET session_replication_role = 'replica';

-- ── Lookup tables ──────────────────────────────────────────────
-- group2 has more entries; insert any IDs not already in public
INSERT INTO DIFFICULTYLEVEL (DifficultyID, DifficultyName)
    SELECT DifficultyID, DifficultyName FROM group2.DIFFICULTYLEVEL
    ON CONFLICT DO NOTHING;

INSERT INTO TOURSTATUS (TourStatusID, StatusName)
    SELECT TourStatusID, StatusName FROM group2.TOURSTATUS
    ON CONFLICT DO NOTHING;

INSERT INTO REGISTRATIONSTATUS (RegistrationStatusID, StatusName)
    SELECT RegistrationStatusID, StatusName FROM group2.REGISTRATIONSTATUS
    ON CONFLICT DO NOTHING;

INSERT INTO PAYMENTSTATUS (PaymentStatusID, StatusName)
    SELECT PaymentStatusID, StatusName FROM group2.PAYMENTSTATUS
    ON CONFLICT DO NOTHING;

-- ── GUIDE (from group2) ───────────────────────────────────────
-- ON CONFLICT DO NOTHING skips any IDs that already exist in public
INSERT INTO GUIDE (GuideID, FirstName, LastName, Phone, Email,
                   BirthDate, JoinDate, DailyRate, ExperienceYears, Rating)
    SELECT GuideID, FirstName, LastName, Phone, Email,
           BirthDate, JoinDate, DailyRate, ExperienceYears, Rating
    FROM group2.GUIDE
    ON CONFLICT DO NOTHING;

-- ── ROUTE (from group2) ───────────────────────────────────────
INSERT INTO ROUTE (RouteID, Name, EstimatedLength, EstimatedDuration, Description, DifficultyID)
    SELECT RouteID, Name, EstimatedLength, EstimatedDuration, Description, DifficultyID
    FROM group2.ROUTE
    ON CONFLICT DO NOTHING;

-- ── PARTICIPANT (map group2.CUSTOMER) ─────────────────────────
INSERT INTO PARTICIPANT (ParticipantID, FullName, Email, Phone, JoinDate)
    SELECT CustomerID, FullName, Email, Phone, JoinDate
    FROM group2.CUSTOMER
    ON CONFLICT DO NOTHING;

-- ── GUIDEDTOUR (from group2) ──────────────────────────────────
-- Note: public.guidedtour PK column is named "tripid" (legacy name kept from stage 1)
INSERT INTO GUIDEDTOUR (tripid, StartDate, EndDate, StartTime, EndTime,
                        MeetingPoint, Price, MaxParticipants, Notes,
                        TourStatusID, GuideID, RouteID)
    SELECT TourID, StartDate, EndDate, StartTime, EndTime,
           MeetingPoint, Price, MaxParticipants, Notes,
           TourStatusID, GuideID, RouteID
    FROM group2.GUIDEDTOUR
    ON CONFLICT DO NOTHING;

-- ── REGISTRATION (from group2) ────────────────────────────────
-- group2 REGISTRATION uses CustomerID; maps to public ParticipantID (same numeric ID)
INSERT INTO REGISTRATION (RegistrationID, RegistrationDate, AmountToPay, Notes,
                          TourID, RegistrationStatusID, ParticipantID)
    SELECT RegistrationID, RegistrationDate, AmountToPay, Notes,
           TourID, RegistrationStatusID, CustomerID
    FROM group2.REGISTRATION
    ON CONFLICT DO NOTHING;

-- ── PAYMENT (from group2) ─────────────────────────────────────
INSERT INTO PAYMENT (PaymentID, PaymentDate, Amount, PaymentMethod,
                     RegistrationID, PaymentStatusID)
    SELECT PaymentID, PaymentDate, Amount, PaymentMethod,
           RegistrationID, PaymentStatusID
    FROM group2.PAYMENT
    ON CONFLICT DO NOTHING;

-- Re-enable triggers
SET session_replication_role = DEFAULT;
