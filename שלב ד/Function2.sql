-- ======================================================
-- Stage 4: PL/pgSQL Programming
-- Function2.sql - func_get_participant_history
-- Description: Accepts a participant ID and returns a REF CURSOR
--   with their full booking history: trip details, booking status,
--   total paid, and balance due.
--   Demonstrates: REFCURSOR return, implicit cursor (FOR loop),
--                 records, conditionals, EXCEPTION handling.
-- ======================================================

CREATE OR REPLACE FUNCTION func_get_participant_history(p_participant_id INT)
RETURNS REFCURSOR
LANGUAGE plpgsql
AS $$
DECLARE
    v_cursor        REFCURSOR := 'participant_history_cursor';
    v_participant   PARTICIPANT%ROWTYPE;
    v_count         INT := 0;

    -- Implicit cursor via FOR-IN loop
    v_booking RECORD;

BEGIN
    -- Validate the participant exists (uses implicit cursor via SELECT INTO)
    SELECT * INTO v_participant
    FROM PARTICIPANT
    WHERE ParticipantID = p_participant_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Participant with ID % does not exist.', p_participant_id;
    END IF;

    RAISE NOTICE 'Fetching history for participant: % %',
        v_participant.FullName, v_participant.Email;

    -- Count bookings using implicit cursor
    FOR v_booking IN
        SELECT b.BookingID
        FROM BOOKING b
        WHERE b.ParticipantID = p_participant_id
    LOOP
        v_count := v_count + 1;
    END LOOP;

    IF v_count = 0 THEN
        RAISE NOTICE 'Participant % has no bookings.', v_participant.FullName;
    ELSE
        RAISE NOTICE 'Participant % has % booking(s).', v_participant.FullName, v_count;
    END IF;

    -- Open REFCURSOR with the detailed query
    OPEN v_cursor FOR
        SELECT
            b.BookingID,
            b.BookingDate,
            t.DepartureDate,
            r.RouteName,
            rs.StatusName          AS BookingStatus,
            b.AmountToPay,
            COALESCE(SUM(p.Amount), 0)              AS TotalPaid,
            COALESCE(b.AmountToPay, 0) -
                COALESCE(SUM(p.Amount), 0)          AS BalanceDue
        FROM BOOKING b
        JOIN TRIP t                  ON b.TripID              = t.TripID
        JOIN ROUTE r                 ON t.RouteID             = r.RouteID
        JOIN REGISTRATIONSTATUS rs   ON b.RegistrationStatusID = rs.RegistrationStatusID
        LEFT JOIN PAYMENT p          ON b.BookingID           = p.BookingID
        WHERE b.ParticipantID = p_participant_id
        GROUP BY b.BookingID, b.BookingDate, t.DepartureDate,
                 r.RouteName, rs.StatusName, b.AmountToPay
        ORDER BY b.BookingDate DESC;

    RETURN v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'func_get_participant_history failed: %', SQLERRM;
END;
$$;
