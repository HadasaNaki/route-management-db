-- ======================================================
-- Stage 4: PL/pgSQL Programming
-- Trigger2.sql - trg_after_booking_update
-- Description: AFTER UPDATE trigger on BOOKING (fires on status change).
--   When a booking's RegistrationStatusID changes:
--     • Cancellation (→ 3): decrements CurrentBookings on TRIP,
--       reverts trip status from Full (3) to Open (2) if applicable,
--       and writes an audit row to BOOKING_AUDIT.
--     • Confirmation (→ 2): also writes an audit row.
--   Demonstrates: AFTER UPDATE trigger, OLD/NEW comparison,
--                 DML (UPDATE + INSERT), conditionals.
-- ======================================================

CREATE OR REPLACE FUNCTION trg_fn_after_booking_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_trip_current_bookings INT;
    v_trip_max_capacity     INT;
    v_trip_status_id        INT;
BEGIN
    -- Only act when the status column actually changed
    IF OLD.RegistrationStatusID IS NOT DISTINCT FROM NEW.RegistrationStatusID THEN
        RETURN NEW;
    END IF;

    -- Write audit log entry for every status transition
    INSERT INTO BOOKING_AUDIT (BookingID, OldStatusID, NewStatusID)
    VALUES (NEW.BookingID, OLD.RegistrationStatusID, NEW.RegistrationStatusID);

    RAISE NOTICE 'AUDIT: Booking % changed status % → %',
        NEW.BookingID, OLD.RegistrationStatusID, NEW.RegistrationStatusID;

    -- If booking was cancelled → adjust trip capacity
    IF NEW.RegistrationStatusID = 3 AND OLD.RegistrationStatusID != 3 THEN

        -- Decrement counter
        UPDATE TRIP
        SET CurrentBookings = GREATEST(CurrentBookings - 1, 0)
        WHERE TripID = NEW.TripID
        RETURNING CurrentBookings, MaxCapacity, TourStatusID
            INTO v_trip_current_bookings, v_trip_max_capacity, v_trip_status_id;

        RAISE NOTICE 'Trip % capacity released: now % / %',
            NEW.TripID, v_trip_current_bookings, v_trip_max_capacity;

        -- If trip was Full, reopen it
        IF v_trip_status_id = 3 THEN   -- 3 = Full
            UPDATE TRIP
            SET TourStatusID = 2       -- 2 = Open for Registration
            WHERE TripID = NEW.TripID;

            RAISE NOTICE 'Trip % status reverted to Open for Registration.', NEW.TripID;
        END IF;

    END IF;

    RETURN NEW;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'trg_fn_after_booking_update: %', SQLERRM;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_booking_update ON BOOKING;
CREATE TRIGGER trg_after_booking_update
    AFTER UPDATE ON BOOKING
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_after_booking_update();
