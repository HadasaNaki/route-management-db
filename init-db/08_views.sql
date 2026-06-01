-- ======================================================
-- 08_views.sql  (Stage 3 views)
-- Description: Creates the integrated views used by the project.
--   Mirrors the CREATE VIEW statements in "שלב ג/Views.sql"
--   (the demonstration SELECT queries from that file are kept there
--   for the report; only the view definitions are needed at init time).
-- ======================================================

SET search_path TO public;

-- ------------------------------------------------------
-- VIEW 1: Perspective of the original department (Trip Guide Insights)
-- Combines GUIDEDTOUR, GUIDE, ROUTE and DIFFICULTYLEVEL.
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
FROM GUIDEDTOUR t
JOIN ROUTE r           ON t.RouteID = r.RouteID
JOIN DIFFICULTYLEVEL dl ON r.DifficultyID = dl.DifficultyID
JOIN GUIDE g           ON t.GuideID = g.GuideID
WHERE t.StartDate >= CURRENT_DATE;

-- ------------------------------------------------------
-- VIEW 2: Perspective of the new department (Payments & Registration status)
-- Combines REGISTRATION, PARTICIPANT, REGISTRATIONSTATUS and PAYMENT.
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
FROM REGISTRATION b
JOIN PARTICIPANT p           ON b.ParticipantID = p.ParticipantID
JOIN REGISTRATIONSTATUS rs   ON b.RegistrationStatusID = rs.RegistrationStatusID
LEFT JOIN PAYMENT pay        ON b.RegistrationID = pay.RegistrationID
GROUP BY b.RegistrationID, b.RegistrationDate, p.FullName, p.Email,
         b.AmountToPay, rs.StatusName;

-- ------------------------------------------------------
-- VIEW 3: Combined perspective (Location popularity + tour status)
-- Combines LOCATION/PASSES_THROUGH (original) with TOURSTATUS (new).
-- ------------------------------------------------------
CREATE OR REPLACE VIEW V_LocationPopularityAndStatus AS
SELECT
    l.LocationID,
    l.LocationName,
    l.Category,
    COUNT(DISTINCT t.TripID) AS NumberOfTripsAssociated,
    STRING_AGG(DISTINCT ts.StatusName, ', ') AS CurrentTourStatuses
FROM LOCATION l
JOIN PASSES_THROUGH pt  ON l.LocationID = pt.LocationID
JOIN ROUTE r            ON pt.RouteID = r.RouteID
LEFT JOIN GUIDEDTOUR t  ON r.RouteID = t.RouteID
LEFT JOIN TOURSTATUS ts ON t.TourStatusID = ts.TourStatusID
GROUP BY l.LocationID, l.LocationName, l.Category;
