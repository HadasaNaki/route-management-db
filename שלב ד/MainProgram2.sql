-- ======================================================
-- Stage 4: PL/pgSQL Programming
-- MainProgram2.sql
-- Description: Main program that invokes:
--   1. func_get_participant_history(1) – prints the booking
--      history of participant 1 (Avraham Israel).
--   2. proc_register_participant(1002, 1) – registers participant 1
--      for trip 1002 (Jerusalem Old City, 2026-06-01).
-- ======================================================

DO $$
DECLARE
    v_ref  REFCURSOR;
    v_row  RECORD;
    v_count INT := 0;
BEGIN
    RAISE NOTICE '===================================================';
    RAISE NOTICE 'MAIN PROGRAM 2 — Participant History + Registration';
    RAISE NOTICE '===================================================';

    -- ── Part 1: Call func_get_participant_history ──────────────────
    RAISE NOTICE '';
    RAISE NOTICE '--- Part 1: Booking History for Participant 1 ---';

    v_ref := func_get_participant_history(1);

    LOOP
        FETCH v_ref INTO v_row;
        EXIT WHEN NOT FOUND;

        v_count := v_count + 1;
        RAISE NOTICE 'BookingID: % | Trip: % | Departs: % | Status: % | Paid: % / %',
            v_row.BookingID,
            v_row.RouteName,
            v_row.DepartureDate,
            v_row.BookingStatus,
            v_row.TotalPaid,
            v_row.AmountToPay;
    END LOOP;
    CLOSE v_ref;

    IF v_count = 0 THEN
        RAISE NOTICE 'No booking history found for participant 1.';
    ELSE
        RAISE NOTICE 'Total bookings found: %', v_count;
    END IF;

    -- ── Part 2: Call proc_register_participant ─────────────────────
    RAISE NOTICE '';
    RAISE NOTICE '--- Part 2: Register Participant 1 for Trip 1002 ---';

    CALL proc_register_participant(
        p_trip_id        => 1002,
        p_participant_id => 1,
        p_notes          => 'Registered via MainProgram2'
    );

    -- Verify the new booking was created
    RAISE NOTICE '';
    RAISE NOTICE '--- Verification: Booking table after registration ---';
    FOR v_row IN
        SELECT b.BookingID, b.BookingDate, b.TripID,
               p.FullName, b.AmountToPay, rs.StatusName
        FROM BOOKING b
        JOIN PARTICIPANT p          ON b.ParticipantID = p.ParticipantID
        JOIN REGISTRATIONSTATUS rs  ON b.RegistrationStatusID = rs.RegistrationStatusID
        WHERE b.TripID = 1002
        ORDER BY b.BookingID
    LOOP
        RAISE NOTICE 'BookingID: % | Date: % | Participant: % | Amount: % | Status: %',
            v_row.BookingID, v_row.BookingDate, v_row.FullName,
            v_row.AmountToPay, v_row.StatusName;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '=== MAIN PROGRAM 2 COMPLETE ===';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'MainProgram2 failed: %', SQLERRM;
END;
$$;
