-- ======================================================
-- Stage 4: PL/pgSQL Programming
-- Procedure2.sql - proc_process_expired_bookings
-- Description: Scans all bookings for trips that departed more than
--   7 days ago and still have status 'Needs Action' (1).
--   Sets those bookings to 'Cancelled' (3) and, once all bookings
--   for a trip are resolved, marks the trip as 'Completed' (5).
--   Demonstrates: explicit cursor, LOOP, DML (UPDATE),
--                 records, conditionals, EXCEPTION handling.
-- ======================================================

CREATE OR REPLACE PROCEDURE proc_process_expired_bookings()
LANGUAGE plpgsql
AS $$
DECLARE
    -- Explicit cursor: bookings for trips departed more than 7 days ago
    -- that are still in 'Needs Action' status
    c_expired CURSOR FOR
        SELECT b.BookingID, b.TripID, b.ParticipantID,
               t.DepartureDate
        FROM BOOKING b
        JOIN TRIP t ON b.TripID = t.TripID
        WHERE b.RegistrationStatusID = 1          -- Needs Action
          AND t.DepartureDate < CURRENT_DATE - 7  -- Trip departed > 7 days ago
        ORDER BY t.DepartureDate, b.BookingID;

    v_row           RECORD;
    v_cancelled     INT := 0;
    v_trips_closed  INT := 0;
    v_open_count    INT;

BEGIN
    RAISE NOTICE 'Starting expired bookings cleanup — date threshold: %',
        CURRENT_DATE - 7;

    OPEN c_expired;
    LOOP
        FETCH c_expired INTO v_row;
        EXIT WHEN NOT FOUND;

        -- Cancel the booking
        UPDATE BOOKING
        SET RegistrationStatusID = 3   -- Cancelled
        WHERE BookingID = v_row.BookingID;

        -- Decrement CurrentBookings on the trip
        UPDATE TRIP
        SET CurrentBookings = GREATEST(CurrentBookings - 1, 0)
        WHERE TripID = v_row.TripID;

        v_cancelled := v_cancelled + 1;

        RAISE NOTICE 'Cancelled BookingID % (TripID %, departed %)',
            v_row.BookingID, v_row.TripID, v_row.DepartureDate;

        -- Check if all bookings for this trip are now resolved (none pending)
        SELECT COUNT(*) INTO v_open_count
        FROM BOOKING
        WHERE TripID = v_row.TripID
          AND RegistrationStatusID = 1;   -- Needs Action

        IF v_open_count = 0 THEN
            -- Mark trip as Completed
            UPDATE TRIP
            SET TourStatusID = 5   -- Completed
            WHERE TripID = v_row.TripID
              AND TourStatusID != 5;

            IF FOUND THEN
                v_trips_closed := v_trips_closed + 1;
                RAISE NOTICE 'Trip % marked as Completed.', v_row.TripID;
            END IF;
        END IF;

    END LOOP;
    CLOSE c_expired;

    RAISE NOTICE 'Cleanup complete: % booking(s) cancelled, % trip(s) marked Completed.',
        v_cancelled, v_trips_closed;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'proc_process_expired_bookings failed: %', SQLERRM;
END;
$$;
