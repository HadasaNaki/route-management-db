-- ======================================================
-- Stage 4: PL/pgSQL Programming
-- Function1.sql - func_trip_revenue_report
-- Description: Returns a REF CURSOR with a revenue summary per trip.
--   For every trip, reports: route name, guide name, departure date,
--   max capacity, current bookings, expected revenue, and classification
--   (High / Medium / Low) based on occupancy rate.
--   Demonstrates: explicit cursor, REFCURSOR return, records, loops,
--                 conditionals (IF/ELSIF), EXCEPTION handling.
-- ======================================================

CREATE OR REPLACE FUNCTION func_trip_revenue_report()
RETURNS REFCURSOR
LANGUAGE plpgsql
AS $$
DECLARE
    v_cursor    REFCURSOR := 'trip_revenue_cursor';

    -- Explicit cursor over all tours joined to route + guide
    c_trips CURSOR FOR
        SELECT
            t.TripID,
            t.StartDate,
            t.MaxParticipants,
            t.CurrentBookings,
            t.Price,
            r.Name              AS RouteName,
            g.FirstName || ' ' || g.LastName AS GuideName,
            ts.StatusName       AS TripStatus
        FROM GUIDEDTOUR t
        JOIN ROUTE r         ON t.RouteID  = r.RouteID
        JOIN GUIDE g         ON t.GuideID  = g.GuideID
        LEFT JOIN TOURSTATUS ts ON t.TourStatusID = ts.TourStatusID
        ORDER BY t.StartDate;

    -- Record to hold one row from the cursor
    v_trip      RECORD;

    -- Occupancy classification
    v_occupancy_rate  NUMERIC(5,2);
    v_classification  VARCHAR(20);

    -- Temporary table to collect results before opening ref cursor
    v_results_exist BOOLEAN := FALSE;

BEGIN
    -- Create a temporary table to hold calculated results
    CREATE TEMP TABLE IF NOT EXISTS tmp_trip_revenue (
        TripID          INT,
        RouteName       VARCHAR(200),
        GuideName       VARCHAR(200),
        StartDate       DATE,
        TripStatus      VARCHAR(50),
        MaxParticipants INT,
        CurrentBookings INT,
        ExpectedRevenue NUMERIC(10,2),
        OccupancyPct    NUMERIC(5,2),
        Classification  VARCHAR(20)
    ) ON COMMIT DELETE ROWS;

    -- Empty any leftover data from a previous call in this transaction
    DELETE FROM tmp_trip_revenue;

    -- Open explicit cursor and loop over each trip
    OPEN c_trips;
    LOOP
        FETCH c_trips INTO v_trip;
        EXIT WHEN NOT FOUND;

        v_results_exist := TRUE;

        -- Guard against division by zero
        IF v_trip.MaxParticipants = 0 THEN
            RAISE EXCEPTION 'Tour % has MaxParticipants = 0 — invalid data', v_trip.TripID;
        END IF;

        -- Calculate occupancy rate and expected revenue (implicit cursor via formula)
        v_occupancy_rate := ROUND(
            (v_trip.CurrentBookings::NUMERIC / v_trip.MaxParticipants::NUMERIC) * 100, 2
        );

        -- Classify occupancy
        IF v_occupancy_rate >= 80 THEN
            v_classification := 'High';
        ELSIF v_occupancy_rate >= 40 THEN
            v_classification := 'Medium';
        ELSE
            v_classification := 'Low';
        END IF;

        -- Insert calculated row into temp table
        INSERT INTO tmp_trip_revenue VALUES (
            v_trip.TripID,
            v_trip.RouteName,
            v_trip.GuideName,
            v_trip.StartDate,
            COALESCE(v_trip.TripStatus, 'Unknown'),
            v_trip.MaxParticipants,
            v_trip.CurrentBookings,
            ROUND(v_trip.CurrentBookings * v_trip.Price, 2),
            v_occupancy_rate,
            v_classification
        );

    END LOOP;
    CLOSE c_trips;

    IF NOT v_results_exist THEN
        RAISE NOTICE 'No trips found in the system.';
    END IF;

    -- Open a REFCURSOR over the temp table and return it
    OPEN v_cursor FOR SELECT * FROM tmp_trip_revenue ORDER BY OccupancyPct DESC;
    RETURN v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'func_trip_revenue_report failed: %', SQLERRM;
END;
$$;
