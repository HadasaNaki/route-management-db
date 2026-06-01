-- ======================================================
-- 10_procedures.sql  (Stage 4 procedures)
-- Description: Creates the Stage 4 PL/pgSQL procedures on the
--   integrated schema. Mirrors "שלב ד/Procedure1.sql" and
--   "שלב ד/Procedure2.sql".
-- ======================================================

SET search_path TO public;

-- ------------------------------------------------------
-- proc_register_participant(trip_id, participant_id, notes)
-- Validates and creates a new registration, updating capacity/status.
-- ------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_register_participant(
    p_trip_id        INT,
    p_participant_id INT,
    p_notes          VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_trip           GUIDEDTOUR%ROWTYPE;
    v_participant    PARTICIPANT%ROWTYPE;
    v_existing_count INT := 0;
    v_new_reg_id     INT;
    v_status_id      INT := 1;   -- 1 = 'Needs Action'
BEGIN
    SELECT * INTO v_participant
    FROM PARTICIPANT
    WHERE ParticipantID = p_participant_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Participant ID % does not exist.', p_participant_id;
    END IF;

    SELECT * INTO v_trip
    FROM GUIDEDTOUR
    WHERE TripID = p_trip_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tour ID % does not exist.', p_trip_id;
    END IF;

    IF v_trip.StartDate < CURRENT_DATE THEN
        RAISE EXCEPTION 'Tour % started on % — cannot register for a past tour.',
            p_trip_id, v_trip.StartDate;
    END IF;

    IF v_trip.CurrentBookings >= v_trip.MaxParticipants THEN
        RAISE EXCEPTION 'Tour % is fully booked (% / %).',
            p_trip_id, v_trip.CurrentBookings, v_trip.MaxParticipants;
    END IF;

    SELECT COUNT(*) INTO v_existing_count
    FROM REGISTRATION
    WHERE TourID        = p_trip_id
      AND ParticipantID = p_participant_id
      AND RegistrationStatusID != 3;   -- 3 = Cancelled

    IF v_existing_count > 0 THEN
        RAISE EXCEPTION 'Participant % is already registered for tour %.',
            v_participant.FullName, p_trip_id;
    END IF;

    SELECT COALESCE(MAX(RegistrationID), 0) + 1 INTO v_new_reg_id FROM REGISTRATION;

    INSERT INTO REGISTRATION (RegistrationID, RegistrationDate, TourID, ParticipantID,
                              AmountToPay, Notes, RegistrationStatusID)
    VALUES (v_new_reg_id, CURRENT_DATE, p_trip_id, p_participant_id,
            v_trip.Price, p_notes, v_status_id);

    UPDATE GUIDEDTOUR
    SET CurrentBookings = CurrentBookings + 1
    WHERE TripID = p_trip_id;

    IF (v_trip.CurrentBookings + 1) >= v_trip.MaxParticipants THEN
        UPDATE GUIDEDTOUR
        SET TourStatusID = 3   -- 3 = Full
        WHERE TripID = p_trip_id;
        RAISE NOTICE 'Tour % is now FULL.', p_trip_id;
    ELSE
        UPDATE GUIDEDTOUR
        SET TourStatusID = 2   -- 2 = Open for Registration
        WHERE TripID = p_trip_id AND TourStatusID = 1;
    END IF;

    RAISE NOTICE 'SUCCESS: % registered for tour % (RegistrationID: %, AmountToPay: %)',
        v_participant.FullName, p_trip_id, v_new_reg_id, v_trip.Price;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'proc_register_participant failed: %', SQLERRM;
END;
$$;

-- ------------------------------------------------------
-- proc_process_expired_bookings()
-- Cancels stale 'Needs Action' registrations for tours that started
-- more than 7 days ago, and closes fully-resolved tours.
-- ------------------------------------------------------
CREATE OR REPLACE PROCEDURE proc_process_expired_bookings()
LANGUAGE plpgsql
AS $$
DECLARE
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

        UPDATE REGISTRATION
        SET RegistrationStatusID = 3   -- Cancelled
        WHERE RegistrationID = v_row.RegistrationID;

        UPDATE GUIDEDTOUR
        SET CurrentBookings = GREATEST(CurrentBookings - 1, 0)
        WHERE TripID = v_row.TourID;

        v_cancelled := v_cancelled + 1;

        RAISE NOTICE 'Cancelled RegistrationID % (TourID %, started %)',
            v_row.RegistrationID, v_row.TourID, v_row.StartDate;

        SELECT COUNT(*) INTO v_open_count
        FROM REGISTRATION
        WHERE TourID = v_row.TourID
          AND RegistrationStatusID = 1;   -- Needs Action

        IF v_open_count = 0 THEN
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
