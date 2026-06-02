-- ======================================================
-- 09_functions.sql  (Stage 4 functions)
-- Description: Creates the Stage 4 PL/pgSQL functions on the
--   integrated schema. Mirrors "שלב ד/Function1.sql" and
--   "שלב ד/Function2.sql".
-- ======================================================

SET search_path TO public;

-- ------------------------------------------------------
-- func_trip_revenue_report() -> REFCURSOR
-- Revenue summary per trip (occupancy, expected income, classification).
-- ------------------------------------------------------
CREATE OR REPLACE FUNCTION func_trip_revenue_report()
RETURNS REFCURSOR
LANGUAGE plpgsql
AS $$
DECLARE
    v_cursor    REFCURSOR := 'trip_revenue_cursor';

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

    v_trip            RECORD;
    v_occupancy_rate  NUMERIC(5,2);
    v_classification  VARCHAR(20);
    v_results_exist   BOOLEAN := FALSE;

BEGIN
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

    DELETE FROM tmp_trip_revenue;

    OPEN c_trips;
    LOOP
        FETCH c_trips INTO v_trip;
        EXIT WHEN NOT FOUND;

        v_results_exist := TRUE;

        IF v_trip.MaxParticipants = 0 THEN
            RAISE EXCEPTION 'Tour % has MaxParticipants = 0 — invalid data', v_trip.TripID;
        END IF;

        v_occupancy_rate := ROUND(
            (v_trip.CurrentBookings::NUMERIC / v_trip.MaxParticipants::NUMERIC) * 100, 2
        );

        IF v_occupancy_rate >= 80 THEN
            v_classification := 'High';
        ELSIF v_occupancy_rate >= 40 THEN
            v_classification := 'Medium';
        ELSE
            v_classification := 'Low';
        END IF;

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

    OPEN v_cursor FOR SELECT * FROM tmp_trip_revenue ORDER BY OccupancyPct DESC;
    RETURN v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'func_trip_revenue_report failed: %', SQLERRM;
END;
$$;

-- ------------------------------------------------------
-- func_get_participant_history(p_participant_id) -> REFCURSOR
-- Full booking history for a participant.
-- ------------------------------------------------------
CREATE OR REPLACE FUNCTION func_get_participant_history(p_participant_id INT)
RETURNS REFCURSOR
LANGUAGE plpgsql
AS $$
DECLARE
    v_cursor        REFCURSOR := 'participant_history_cursor';
    v_participant   PARTICIPANT%ROWTYPE;
    v_count         INT := 0;
    v_booking       RECORD;
BEGIN
    SELECT * INTO v_participant
    FROM PARTICIPANT
    WHERE ParticipantID = p_participant_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Participant with ID % does not exist.', p_participant_id;
    END IF;

    RAISE NOTICE 'Fetching history for participant: % %',
        v_participant.FullName, v_participant.Email;

    FOR v_booking IN
        SELECT b.RegistrationID
        FROM REGISTRATION b
        WHERE b.ParticipantID = p_participant_id
    LOOP
        v_count := v_count + 1;
    END LOOP;

    IF v_count = 0 THEN
        RAISE NOTICE 'Participant % has no registrations.', v_participant.FullName;
    ELSE
        RAISE NOTICE 'Participant % has % registration(s).', v_participant.FullName, v_count;
    END IF;

    OPEN v_cursor FOR
        SELECT
            b.RegistrationID,
            b.RegistrationDate,
            t.StartDate,
            r.Name                              AS RouteName,
            rs.StatusName                       AS BookingStatus,
            b.AmountToPay,
            COALESCE(SUM(p.Amount), 0)          AS TotalPaid,
            COALESCE(b.AmountToPay, 0) -
                COALESCE(SUM(p.Amount), 0)      AS BalanceDue
        FROM REGISTRATION b
        JOIN GUIDEDTOUR t               ON b.TourID               = t.TripID
        JOIN ROUTE r                    ON t.RouteID               = r.RouteID
        JOIN REGISTRATIONSTATUS rs      ON b.RegistrationStatusID  = rs.RegistrationStatusID
        LEFT JOIN PAYMENT p             ON b.RegistrationID        = p.RegistrationID
        WHERE b.ParticipantID = p_participant_id
        GROUP BY b.RegistrationID, b.RegistrationDate, t.StartDate,
                 r.Name, rs.StatusName, b.AmountToPay
        ORDER BY b.RegistrationDate DESC;

    RETURN v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'func_get_participant_history failed: %', SQLERRM;
END;
$$;
