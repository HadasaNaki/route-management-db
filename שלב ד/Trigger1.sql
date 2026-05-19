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
    v_trip TRIP%ROWTYPE;
BEGIN
    -- Fetch the trip record
    SELECT * INTO v_trip
    FROM TRIP
    WHERE TripID = NEW.TripID;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Trigger: Trip ID % does not exist.', NEW.TripID;
    END IF;

    -- Block insert if trip is full
    IF v_trip.CurrentBookings >= v_trip.MaxCapacity THEN
        RAISE EXCEPTION 'Trigger: Trip % is fully booked (% / %). Booking rejected.',
            NEW.TripID, v_trip.CurrentBookings, v_trip.MaxCapacity;
    END IF;

    -- Auto-fill AmountToPay from trip price if not explicitly set
    IF NEW.AmountToPay IS NULL THEN
        NEW.AmountToPay := v_trip.Price;
        RAISE NOTICE 'Trigger: AmountToPay auto-set to % for BookingID %.',
            v_trip.Price, NEW.BookingID;
    END IF;

    -- Auto-fill BookingDate if missing
    IF NEW.BookingDate IS NULL THEN
        NEW.BookingDate := CURRENT_DATE;
    END IF;

    RETURN NEW;  -- Proceed with the modified NEW row

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'trg_fn_before_booking_insert: %', SQLERRM;
END;
$$;

DROP TRIGGER IF EXISTS trg_before_booking_insert ON BOOKING;
CREATE TRIGGER trg_before_booking_insert
    BEFORE INSERT ON BOOKING
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_before_booking_insert();
