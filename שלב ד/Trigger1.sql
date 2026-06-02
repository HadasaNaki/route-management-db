-- ======================================================
-- Stage 4: PL/pgSQL Programming
-- Trigger1.sql - trg_before_booking_insert
-- Description: BEFORE INSERT trigger on BOOKING.
--   Automatically sets AmountToPay from the trip's Price if not
--   provided, and raises an exception if the trip is already full.
--   Demonstrates: BEFORE INSERT trigger, NEW record access,
--                 conditionals, EXCEPTION handling, DML-like side effects.
-- ======================================================

CREATE OR REPLACE FUNCTION trg_fn_before_booking_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_trip GUIDEDTOUR%ROWTYPE;
BEGIN
    -- Fetch the tour record
    SELECT * INTO v_trip
    FROM GUIDEDTOUR
    WHERE TripID = NEW.TourID;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trigger: Tour ID % does not exist.', NEW.TourID;
    END IF;

    -- Block insert if tour is full
    IF v_trip.CurrentBookings >= v_trip.MaxParticipants THEN
        RAISE EXCEPTION 'Trigger: Tour % is fully booked (% / %). Registration rejected.',
            NEW.TourID, v_trip.CurrentBookings, v_trip.MaxParticipants;
    END IF;

    -- Auto-fill AmountToPay from tour price if not explicitly set
    IF NEW.AmountToPay IS NULL THEN
        NEW.AmountToPay := v_trip.Price;
        RAISE NOTICE 'Trigger: AmountToPay auto-set to % for RegistrationID %.',
            v_trip.Price, NEW.RegistrationID;
    END IF;

    -- Auto-fill RegistrationDate if missing
    IF NEW.RegistrationDate IS NULL THEN
        NEW.RegistrationDate := CURRENT_DATE;
    END IF;

    RETURN NEW;  -- Proceed with the modified NEW row

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
