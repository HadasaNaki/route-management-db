-- ======================================================
-- Stage 4: PL/pgSQL Programming
-- Procedure1.sql - proc_register_participant
-- Description: Registers a participant for a trip.
--   Validates: trip existence, capacity not exceeded,
--   participant not already registered for the same trip.
--   Inserts a new BOOKING and increments CurrentBookings on TRIP.
--   Sets AmountToPay from the trip's Price.
--   Demonstrates: DML (INSERT, UPDATE), explicit cursor,
--                 records, conditionals, EXCEPTION handling.
-- ======================================================

CREATE OR REPLACE PROCEDURE proc_register_participant(
    p_trip_id       INT,
    p_participant_id INT,
    p_notes         VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_trip          GUIDEDTOUR%ROWTYPE;
    v_participant   PARTICIPANT%ROWTYPE;
    v_existing_count INT := 0;
    v_new_reg_id     INT;
    v_status_id     INT := 1;   -- 1 = 'Needs Action'

BEGIN
    -- 1. Validate participant exists
    SELECT * INTO v_participant
    FROM PARTICIPANT
    WHERE ParticipantID = p_participant_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Participant ID % does not exist.', p_participant_id;
    END IF;

    -- 2. Validate tour exists (explicit cursor via SELECT INTO)
    SELECT * INTO v_trip
    FROM GUIDEDTOUR
    WHERE TripID = p_trip_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tour ID % does not exist.', p_trip_id;
    END IF;

    -- 3. Check that the tour has not already passed
    IF v_trip.StartDate < CURRENT_DATE THEN
        RAISE EXCEPTION 'Tour % started on % — cannot register for a past tour.',
            p_trip_id, v_trip.StartDate;
    END IF;

    -- 4. Check capacity
    IF v_trip.CurrentBookings >= v_trip.MaxParticipants THEN
        RAISE EXCEPTION 'Tour % is fully booked (% / %).',
            p_trip_id, v_trip.CurrentBookings, v_trip.MaxParticipants;
    END IF;

    -- 5. Check the participant is not already registered for this tour
    SELECT COUNT(*) INTO v_existing_count
    FROM REGISTRATION
    WHERE TourID        = p_trip_id
      AND ParticipantID = p_participant_id
      AND RegistrationStatusID != 3;   -- 3 = Cancelled

    IF v_existing_count > 0 THEN
        RAISE EXCEPTION 'Participant % is already registered for tour %.',
            v_participant.FullName, p_trip_id;
    END IF;

    -- 6. Compute next RegistrationID (simple sequence simulation)
    SELECT COALESCE(MAX(RegistrationID), 0) + 1 INTO v_new_reg_id FROM REGISTRATION;

    -- 7. Insert new registration
    INSERT INTO REGISTRATION (RegistrationID, RegistrationDate, TourID, ParticipantID,
                              AmountToPay, Notes, RegistrationStatusID)
    VALUES (v_new_reg_id, CURRENT_DATE, p_trip_id, p_participant_id,
            v_trip.Price, p_notes, v_status_id);

    -- 8. Increment CurrentBookings on the tour
    UPDATE GUIDEDTOUR
    SET CurrentBookings = CurrentBookings + 1
    WHERE TripID = p_trip_id;

    -- 9. Update TourStatus to 'Full' if now at capacity
    IF (v_trip.CurrentBookings + 1) >= v_trip.MaxParticipants THEN
        UPDATE GUIDEDTOUR
        SET TourStatusID = 3   -- 3 = Full
        WHERE TripID = p_trip_id;
        RAISE NOTICE 'Tour % is now FULL.', p_trip_id;
    ELSE
        -- Ensure status is 'Open for Registration'
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
