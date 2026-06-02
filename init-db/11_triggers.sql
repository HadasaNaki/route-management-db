-- ======================================================
-- 11_triggers.sql  (Stage 4 triggers)
-- Description: Creates the Stage 4 triggers on the integrated schema.
--   Loaded LAST so the bulk seed/integration loads (03 + 06) are not
--   affected. Mirrors "שלב ד/Trigger1.sql" and "שלב ד/Trigger2.sql".
-- ======================================================

SET search_path TO public;

-- ------------------------------------------------------
-- BEFORE INSERT on REGISTRATION:
-- auto-fill AmountToPay / RegistrationDate and block full tours.
-- ------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_fn_before_booking_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_trip GUIDEDTOUR%ROWTYPE;
BEGIN
    SELECT * INTO v_trip
    FROM GUIDEDTOUR
    WHERE TripID = NEW.TourID;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trigger: Tour ID % does not exist.', NEW.TourID;
    END IF;

    IF v_trip.CurrentBookings >= v_trip.MaxParticipants THEN
        RAISE EXCEPTION 'Trigger: Tour % is fully booked (% / %). Registration rejected.',
            NEW.TourID, v_trip.CurrentBookings, v_trip.MaxParticipants;
    END IF;

    IF NEW.AmountToPay IS NULL THEN
        NEW.AmountToPay := v_trip.Price;
        RAISE NOTICE 'Trigger: AmountToPay auto-set to % for RegistrationID %.',
            v_trip.Price, NEW.RegistrationID;
    END IF;

    IF NEW.RegistrationDate IS NULL THEN
        NEW.RegistrationDate := CURRENT_DATE;
    END IF;

    RETURN NEW;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'trg_fn_before_registration_insert: %', SQLERRM;
END;
$$;

DROP TRIGGER IF EXISTS trg_before_registration_insert ON REGISTRATION;
CREATE TRIGGER trg_before_registration_insert
    BEFORE INSERT ON REGISTRATION
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_before_booking_insert();

-- ------------------------------------------------------
-- AFTER UPDATE on REGISTRATION (status change):
-- writes an audit row and, on cancellation, releases tour capacity.
-- ------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_fn_after_booking_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_trip_current_bookings INT;
    v_trip_max_capacity     INT;
    v_trip_status_id        INT;
BEGIN
    IF OLD.RegistrationStatusID IS NOT DISTINCT FROM NEW.RegistrationStatusID THEN
        RETURN NEW;
    END IF;

    INSERT INTO REGISTRATION_AUDIT (RegistrationID, OldStatusID, NewStatusID)
    VALUES (NEW.RegistrationID, OLD.RegistrationStatusID, NEW.RegistrationStatusID);

    RAISE NOTICE 'AUDIT: Registration % changed status % → %',
        NEW.RegistrationID, OLD.RegistrationStatusID, NEW.RegistrationStatusID;

    IF NEW.RegistrationStatusID = 3 AND OLD.RegistrationStatusID != 3 THEN

        UPDATE GUIDEDTOUR
        SET CurrentBookings = GREATEST(CurrentBookings - 1, 0)
        WHERE TripID = NEW.TourID
        RETURNING CurrentBookings, MaxParticipants, TourStatusID
            INTO v_trip_current_bookings, v_trip_max_capacity, v_trip_status_id;

        RAISE NOTICE 'Tour % capacity released: now % / %',
            NEW.TourID, v_trip_current_bookings, v_trip_max_capacity;

        IF v_trip_status_id = 3 THEN   -- 3 = Full
            UPDATE GUIDEDTOUR
            SET TourStatusID = 2       -- 2 = Open for Registration
            WHERE TripID = NEW.TourID;

            RAISE NOTICE 'Tour % status reverted to Open for Registration.', NEW.TourID;
        END IF;

    END IF;

    RETURN NEW;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'trg_fn_after_registration_update: %', SQLERRM;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_registration_update ON REGISTRATION;
CREATE TRIGGER trg_after_registration_update
    AFTER UPDATE ON REGISTRATION
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_after_booking_update();
