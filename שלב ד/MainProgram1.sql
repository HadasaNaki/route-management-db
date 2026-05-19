-- ======================================================
-- Stage 4: PL/pgSQL Programming
-- MainProgram1.sql
-- Description: Main program that invokes:
--   1. func_trip_revenue_report()  – fetches a REFCURSOR and reads
--      all rows from the trip revenue summary, printing each line.
--   2. proc_process_expired_bookings() – runs the cleanup procedure.
-- ======================================================

DO $$
DECLARE
    v_ref         REFCURSOR;
    v_row         RECORD;
    v_line_count  INT := 0;
BEGIN
    RAISE NOTICE '===================================================';
    RAISE NOTICE 'MAIN PROGRAM 1 — Trip Revenue Report + Cleanup';
    RAISE NOTICE '===================================================';

    -- ── Part 1: Call func_trip_revenue_report ──────────────────────
    RAISE NOTICE '';
    RAISE NOTICE '--- Part 1: Trip Revenue Report ---';

    -- Call the function; it returns a named REFCURSOR
    v_ref := func_trip_revenue_report();

    -- Read every row from the cursor and print
    LOOP
        FETCH v_ref INTO v_row;
        EXIT WHEN NOT FOUND;

        v_line_count := v_line_count + 1;

        RAISE NOTICE 'Trip % - % | Guide: % | Departs: % | Status: % | % / % booked | Revenue: % NIS | Occupancy: % pct [%]',
            v_row.TripID,
            v_row.RouteName,
            v_row.GuideName,
            v_row.DepartureDate,
            v_row.TripStatus,
            v_row.CurrentBookings,
            v_row.MaxCapacity,
            v_row.ExpectedRevenue,
            v_row.OccupancyPct,
            v_row.Classification;
    END LOOP;
    CLOSE v_ref;

    RAISE NOTICE 'Total trips reported: %', v_line_count;

    -- ── Part 2: Call proc_process_expired_bookings ─────────────────
    RAISE NOTICE '';
    RAISE NOTICE '--- Part 2: Expired Bookings Cleanup ---';

    CALL proc_process_expired_bookings();

    RAISE NOTICE '';
    RAISE NOTICE '=== MAIN PROGRAM 1 COMPLETE ===';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'MainProgram1 failed: %', SQLERRM;
END;
$$;
