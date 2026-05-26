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
    -- Explicit cursor: registrations for tours that started more than 7 days ago
    -- that are still in 'Needs Action' status
    c_expired CURSOR FOR
        SELECT b.RegistrationID, b.TourID, b.ParticipantID,
               t.StartDate
        FROM REGISTRATION b
        JOIN GUIDEDTOUR t ON b.TourID = t.TripID
        WHERE b.RegistrationStatusID = 1          -- Needs Action
          AND t.StartDate < CURRENT_DATE - 7      -- Tour started > 7 days ago
        ORDER BY t.StartDate, b.RegistrationID;

    v_row           RECORD;
    v_cancelled     INT := 0;
    v_trips_closed  INT := 0;
    v_open_count    INT;

BEGIN
    RAISE NOTICE 'Starting expired registrations cleanup — date threshold: %',
        CURRENT_DATE - 7;

    OPEN c_expired;
    LOOP
        FETCH c_expired INTO v_row;
        EXIT WHEN NOT FOUND;

        -- Cancel the registration
        UPDATE REGISTRATION
        SET RegistrationStatusID = 3   -- Cancelled
        WHERE RegistrationID = v_row.RegistrationID;

        -- Decrement CurrentBookings on the tour
        UPDATE GUIDEDTOUR
        SET CurrentBookings = GREATEST(CurrentBookings - 1, 0)
        WHERE TripID = v_row.TourID;

        v_cancelled := v_cancelled + 1;

        RAISE NOTICE 'Cancelled RegistrationID % (TourID %, started %)',
            v_row.RegistrationID, v_row.TourID, v_row.StartDate;

        -- Check if all registrations for this tour are now resolved (none pending)
        SELECT COUNT(*) INTO v_open_count
        FROM REGISTRATION
        WHERE TourID = v_row.TourID
          AND RegistrationStatusID = 1;   -- Needs Action

        IF v_open_count = 0 THEN
            -- Mark tour as Completed
            UPDATE GUIDEDTOUR
            SET TourStatusID = 5   -- Completed
            WHERE TripID = v_row.TourID
              AND TourStatusID != 5;

            IF FOUND THEN
                v_trips_closed := v_trips_closed + 1;
                RAISE NOTICE 'Tour % marked as Completed.', v_row.TourID;
            END IF;
        END IF;

    END LOOP;
    CLOSE c_expired;

    RAISE NOTICE 'Cleanup complete: % registration(s) cancelled, % tour(s) marked Completed.',
        v_cancelled, v_trips_closed;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'proc_process_expired_bookings failed: %', SQLERRM;
END;
$$;
