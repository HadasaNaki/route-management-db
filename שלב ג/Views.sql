-- ======================================================
-- Phase 3: Integration (Views.sql)
-- Description: Creating views and related queries
-- ======================================================

-- ------------------------------------------------------
-- VIEW 1: Perspective of the original department (Trip Guide Insights)
-- This view combines GUIDEDTOUR, GUIDE, and ROUTE to provide a detailed look at planned trips.
-- ------------------------------------------------------
CREATE OR REPLACE VIEW V_UpcomingTripsDetails AS
SELECT
    t.TripID,
    t.StartDate,
    r.Name AS RouteName,
    dl.DifficultyName AS DifficultyLevel,
    g.FirstName || ' ' || g.LastName AS GuideName,
    g.Phone AS GuidePhone,
    t.Price,
    t.MaxParticipants
FROM
    GUIDEDTOUR t
JOIN
    ROUTE r ON t.RouteID = r.RouteID
JOIN
    DIFFICULTYLEVEL dl ON r.DifficultyID = dl.DifficultyID
JOIN
    GUIDE g ON t.GuideID = g.GuideID
WHERE
    t.StartDate >= CURRENT_DATE;

-- Query 1.1: List upcoming trips with capacity less than 30 ordered by date
-- Description: View what trips are impending that are designed for smaller groups.
SELECT * FROM V_UpcomingTripsDetails
WHERE MaxParticipants < 30
ORDER BY StartDate ASC;

-- Query 1.2: Check average price grouped by difficulty level of upcoming trips
-- Description: Aggregate the cost of upcoming trips grouped by how physically demanding they are.
SELECT DifficultyLevel, AVG(Price) AS AvgTripPrice
FROM V_UpcomingTripsDetails
GROUP BY DifficultyLevel
ORDER BY AvgTripPrice DESC;


-- ------------------------------------------------------
-- VIEW 2: Perspective of the new department (Financials/Payments & Registration status)
-- This view focuses on REGISTRATION, PAYMENT, and PAYMENTSTATUS (from the integrated side).
-- ------------------------------------------------------
CREATE OR REPLACE VIEW V_CustomerPaymentLedger AS
SELECT
    b.RegistrationID,
    b.RegistrationDate,
    p.FullName AS CustomerName,
    p.Email,
    b.AmountToPay,
    COALESCE(SUM(pay.Amount), 0) AS TotalPaid,
    rs.StatusName AS BookStatus
FROM
    REGISTRATION b
JOIN
    PARTICIPANT p ON b.ParticipantID = p.ParticipantID
JOIN
    REGISTRATIONSTATUS rs ON b.RegistrationStatusID = rs.RegistrationStatusID
LEFT JOIN
    PAYMENT pay ON b.RegistrationID = pay.RegistrationID
GROUP BY
    b.RegistrationID, b.RegistrationDate, p.FullName, p.Email, b.AmountToPay, rs.StatusName;

-- Query 2.1: Find all customers with outstanding balances (AmountToPay > TotalPaid)
-- Description: Identifies which registrations are not fully paid yet, so they can be reminded.
SELECT CustomerName, Email, BookStatus, AmountToPay, TotalPaid, (AmountToPay - TotalPaid) AS BalanceDue
FROM V_CustomerPaymentLedger
WHERE TotalPaid < AmountToPay OR TotalPaid IS NULL;

-- Query 2.2: Summarize total revenue received vs expected by registration status
-- Description: High-level financial overview grouped by registration status.
SELECT BookStatus, SUM(AmountToPay) AS TotalExpected, SUM(TotalPaid) AS TotalReceived
FROM V_CustomerPaymentLedger
GROUP BY BookStatus;


-- ------------------------------------------------------
-- VIEW 3: Combined Perspective (Holistic View of Tour Statistics)
-- Combines the original LOCATION/PASSES_THROUGH with the new TOURSTATUS to see site popularity.
-- ------------------------------------------------------
CREATE OR REPLACE VIEW V_LocationPopularityAndStatus AS
SELECT
    l.LocationID,
    l.LocationName,
    l.Category,
    COUNT(DISTINCT t.TripID) AS NumberOfTripsAssociated,
    STRING_AGG(DISTINCT ts.StatusName, ', ') AS CurrentTourStatuses
FROM
    LOCATION l
JOIN
    PASSES_THROUGH pt ON l.LocationID = pt.LocationID
JOIN
    ROUTE r ON pt.RouteID = r.RouteID
LEFT JOIN
    GUIDEDTOUR t ON r.RouteID = t.RouteID
LEFT JOIN
    TOURSTATUS ts ON t.TourStatusID = ts.TourStatusID
GROUP BY
    l.LocationID, l.LocationName, l.Category;

-- Query 3.1: Find locations with no planned trips (zero associated trips)
-- Description: Looking for unused geographic points to plan future tours.
SELECT LocationName, Category
FROM V_LocationPopularityAndStatus
WHERE NumberOfTripsAssociated = 0;

-- Query 3.2: Filter locations based on Nature category sorted by highest associated trips
-- Description: Determine what nature sites are heavily reliant upon the tour guides' time.
SELECT LocationName, NumberOfTripsAssociated, CurrentTourStatuses
FROM V_LocationPopularityAndStatus
WHERE Category = 'Nature'
ORDER BY NumberOfTripsAssociated DESC;