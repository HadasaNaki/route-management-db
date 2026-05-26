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
        RAISE NOTICE 'RegistrationID: % | Trip: % | Start: % | Status: % | Paid: % / %',
            v_row.RegistrationID,
            v_row.RouteName,
            v_row.StartDate,
            v_row.BookingStatus,
            v_row.TotalPaid,
            v_row.AmountToPay;
    END LOOP;
    CLOSE v_ref;

    IF v_count = 0 THEN
        RAISE NOTICE 'No registration history found for participant 1.';
    ELSE
        RAISE NOTICE 'Total registrations found: %', v_count;
    END IF;

    -- ── Part 2: Call proc_register_participant ─────────────────────
    RAISE NOTICE '';
    RAISE NOTICE '--- Part 2: Register Participant 1 for Trip 1002 ---';

    CALL proc_register_participant(
        p_trip_id        => 1002,
        p_participant_id => 1,
        p_notes          => 'Registered via MainProgram2'
    );

    -- Verify the new registration was created
    RAISE NOTICE '';
    RAISE NOTICE '--- Verification: Registration table after registration ---';
    FOR v_row IN
        SELECT b.RegistrationID, b.RegistrationDate, b.TourID,
               p.FullName, b.AmountToPay, rs.StatusName
        FROM REGISTRATION b
        JOIN PARTICIPANT p          ON b.ParticipantID = p.ParticipantID
        JOIN REGISTRATIONSTATUS rs  ON b.RegistrationStatusID = rs.RegistrationStatusID
        WHERE b.TourID = 1002
        ORDER BY b.RegistrationID
    LOOP
        RAISE NOTICE 'RegistrationID: % | Date: % | Participant: % | Amount: % | Status: %',
            v_row.RegistrationID, v_row.RegistrationDate, v_row.FullName,
            v_row.AmountToPay, v_row.StatusName;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '=== MAIN PROGRAM 2 COMPLETE ===';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'MainProgram2 failed: %', SQLERRM;
END;
$$;
