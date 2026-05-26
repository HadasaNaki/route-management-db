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

-- ── GUIDE (IDs 4–20 from group2) ───────────────────────────────
-- public already has GuideIDs 1-3; skip them with WHERE
INSERT INTO GUIDE (GuideID, FirstName, LastName, Phone, Email,
                   BirthDate, JoinDate, DailyRate, ExperienceYears, Rating)
    SELECT GuideID, FirstName, LastName, Phone, Email,
           BirthDate, JoinDate, DailyRate, ExperienceYears, Rating
    FROM group2.GUIDE
    WHERE GuideID > 3
    ON CONFLICT DO NOTHING;

-- ── ROUTE (IDs 4–20 from group2) ───────────────────────────────
-- public already has RouteIDs 1-3
INSERT INTO ROUTE (RouteID, Name, EstimatedLength, EstimatedDuration, Description, DifficultyID)
    SELECT RouteID, Name, EstimatedLength, EstimatedDuration, Description, DifficultyID
    FROM group2.ROUTE
    WHERE RouteID > 3
    ON CONFLICT DO NOTHING;

-- ── PARTICIPANT (map group2.CUSTOMER IDs 4–20) ─────────────────
-- public already has ParticipantIDs 1-3
INSERT INTO PARTICIPANT (ParticipantID, FullName, Email, Phone, JoinDate)
    SELECT CustomerID, FullName, Email, Phone, JoinDate
    FROM group2.CUSTOMER
    WHERE CustomerID > 3
    ON CONFLICT DO NOTHING;

-- ── GUIDEDTOUR (IDs 4–20 from group2) ──────────────────────────
-- Note: public.guidedtour PK column is named "tripid" (legacy name kept from stage 1)
-- public already has TripIDs 1-3
INSERT INTO GUIDEDTOUR (tripid, StartDate, EndDate, StartTime, EndTime,
                        MeetingPoint, Price, MaxParticipants, Notes,
                        TourStatusID, GuideID, RouteID)
    SELECT TourID, StartDate, EndDate, StartTime, EndTime,
           MeetingPoint, Price, MaxParticipants, Notes,
           TourStatusID, GuideID, RouteID
    FROM group2.GUIDEDTOUR
    WHERE TourID > 3
    ON CONFLICT DO NOTHING;

-- ── REGISTRATION (IDs 5–20 from group2) ────────────────────────
-- public already has RegistrationIDs 1-4
-- group2 REGISTRATION uses CustomerID; maps to public ParticipantID (same numeric ID)
INSERT INTO REGISTRATION (RegistrationID, RegistrationDate, AmountToPay, Notes,
                          TourID, RegistrationStatusID, ParticipantID)
    SELECT RegistrationID, RegistrationDate, AmountToPay, Notes,
           TourID, RegistrationStatusID, CustomerID
    FROM group2.REGISTRATION
    WHERE RegistrationID > 4
    ON CONFLICT DO NOTHING;

-- ── PAYMENT (IDs 5–20 from group2) ─────────────────────────────
-- Only import payments whose RegistrationID was imported above (> 4)
INSERT INTO PAYMENT (PaymentID, PaymentDate, Amount, PaymentMethod,
                     RegistrationID, PaymentStatusID)
    SELECT PaymentID, PaymentDate, Amount, PaymentMethod,
           RegistrationID, PaymentStatusID
    FROM group2.PAYMENT
    WHERE RegistrationID > 4
    ON CONFLICT DO NOTHING;

-- Re-enable triggers
SET session_replication_role = DEFAULT;
