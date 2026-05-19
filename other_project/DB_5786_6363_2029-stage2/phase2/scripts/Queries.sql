------------------- Select Section ----------------------------------------

-- 1. High-Earning Guides Report (March 2026)
-- Option A: Using Standard JOINs (Efficient)
SELECT 
    CONCAT(g.FirstName, ' ', g.LastName) AS GuideName,
    g.Email,
    EXTRACT(MONTH FROM p.PaymentDate) AS PaymentMonth,
    SUM(p.Amount) AS TotalEarned
FROM GUIDE g
JOIN GUIDEDTOUR gt ON g.GuideID = gt.GuideID
JOIN REGISTRATION r ON gt.TourID = r.TourID
JOIN PAYMENT p ON r.RegistrationID = p.RegistrationID
WHERE EXTRACT(YEAR FROM p.PaymentDate) = 2026
  AND EXTRACT(MONTH FROM p.PaymentDate) = 3
GROUP BY g.GuideID, g.FirstName, g.LastName, g.Email, EXTRACT(MONTH FROM p.PaymentDate)
HAVING SUM(p.Amount) > 5000
ORDER BY TotalEarned DESC;

-- Option B: Using IN with Nested Subqueries (Less efficient)
SELECT CONCAT(FirstName, ' ', LastName) AS GuideName 
FROM GUIDE
WHERE GuideID IN (
    SELECT GuideID FROM GUIDEDTOUR WHERE TourID IN (
        SELECT TourID FROM REGISTRATION WHERE RegistrationID IN (
            SELECT RegistrationID FROM PAYMENT
            WHERE EXTRACT(MONTH FROM PaymentDate) = 3 
              AND EXTRACT(YEAR FROM PaymentDate) = 2026
        )
    )
);

-- 2. Monthly Revenue Analysis for 2026
-- Option A: Simple GROUP BY
SELECT 
    EXTRACT(YEAR FROM PaymentDate) AS Year,
    EXTRACT(MONTH FROM PaymentDate) AS Month, 
    SUM(Amount) AS MonthlyIncome,
    COUNT(PaymentID) AS TransactionCount
FROM PAYMENT
WHERE EXTRACT(YEAR FROM PaymentDate) = 2026
GROUP BY EXTRACT(YEAR FROM PaymentDate), EXTRACT(MONTH FROM PaymentDate)
ORDER BY Month;

-- Option B: Using a Subquery for grouping
SELECT Month, SUM(Amount) AS Total 
FROM (SELECT EXTRACT(MONTH FROM PaymentDate) as Month, Amount FROM PAYMENT WHERE EXTRACT(YEAR FROM PaymentDate) = 2026) AS MonthlyStats 
GROUP BY Month ORDER BY Month;

-- 3. Debtors List: Jerusalem Tours with Pending Payments
-- Option A: Using JOINs
SELECT DISTINCT c.FullName, c.Phone, r.RegistrationID, rt.Name AS RouteName
FROM CUSTOMER c
JOIN REGISTRATION r ON c.CustomerID = r.CustomerID
JOIN GUIDEDTOUR gt ON r.TourID = gt.TourID
JOIN ROUTE rt ON gt.RouteID = rt.RouteID
WHERE rt.Description LIKE '%Jerusalem%' 
  AND r.RegistrationStatusID = (SELECT RegistrationStatusID FROM REGISTRATIONSTATUS WHERE StatusName = 'Pending');

-- Option B: Using EXISTS
SELECT FullName, Phone FROM CUSTOMER c
WHERE EXISTS (
    SELECT 1 FROM REGISTRATION r 
    JOIN GUIDEDTOUR gt ON r.TourID = gt.TourID
    JOIN ROUTE rt ON gt.RouteID = rt.RouteID
    WHERE r.CustomerID = c.CustomerID 
      AND rt.Description LIKE '%Jerusalem%' 
      AND r.RegistrationStatusID = (SELECT RegistrationStatusID FROM REGISTRATIONSTATUS WHERE StatusName = 'Pending')
);

-- 4. Elite Guides: Above Average Rating & High Activity
-- Option A: Using HAVING with Scalar Subquery
SELECT g.FirstName, g.LastName, g.Rating, COUNT(gt.TourID) AS TourCount
FROM GUIDE g
JOIN GUIDEDTOUR gt ON g.GuideID = gt.GuideID
GROUP BY g.GuideID, g.FirstName, g.LastName, g.Rating
HAVING COUNT(gt.TourID) > 3 
   AND g.Rating > (SELECT AVG(Rating) FROM GUIDE);

-- Option B: Using an Inline View
SELECT g.FirstName, g.LastName, TCounts.cnt
FROM GUIDE g
JOIN (SELECT GuideID, COUNT(*) AS cnt FROM GUIDEDTOUR GROUP BY GuideID) TCounts 
  ON g.GuideID = TCounts.GuideID
WHERE TCounts.cnt > 3 AND g.Rating > (SELECT AVG(Rating) FROM GUIDE);

-- 5. Real-Time Availability: Tours in the Next 7 Days
SELECT 
    gt.TourID, 
    rt.Name AS RouteName, 
    gt.StartDate AS Starting,
    gt.MaxParticipants,
    (gt.MaxParticipants - (SELECT COUNT(*) FROM REGISTRATION r WHERE r.TourID = gt.TourID)) AS AvailableSlots
FROM GUIDEDTOUR gt
JOIN ROUTE rt ON gt.RouteID = rt.RouteID
WHERE gt.StartDate BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
ORDER BY gt.StartDate;

-- 6. VIP Customer Loyalty Program (Spent > 2000 in last year)
SELECT 
    c.FullName, 
    c.Email, 
    SUM(p.Amount) AS TotalSpent,
    MAX(p.PaymentDate) AS LastPayment
FROM CUSTOMER c
JOIN REGISTRATION r ON c.CustomerID = r.CustomerID
JOIN PAYMENT p ON r.RegistrationID = p.RegistrationID
WHERE p.PaymentDate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY c.CustomerID, c.FullName, c.Email
HAVING SUM(p.Amount) > 2000;

-- 7. Popular Routes Analysis
SELECT 
    r.Name, 
    SUM(gt.MaxParticipants) AS TotalCapacity,
    COUNT(gt.TourID) AS Occurrences
FROM ROUTE r
JOIN GUIDEDTOUR gt ON r.RouteID = gt.RouteID
GROUP BY r.RouteID, r.Name
HAVING COUNT(gt.TourID) >= 2
ORDER BY TotalCapacity DESC;

-- 8. Quality Control: Low Experience Feedback
SELECT 
    CONCAT(g.FirstName, ' ', g.LastName) AS GuideName,
    g.ExperienceYears,
    rt.Name AS RouteName,
    r.Notes AS Feedback
FROM REGISTRATION r
JOIN GUIDEDTOUR gt ON r.TourID = gt.TourID
JOIN GUIDE g ON gt.GuideID = g.GuideID
JOIN ROUTE rt ON gt.RouteID = rt.RouteID
WHERE g.ExperienceYears < 2 AND r.Notes IS NOT NULL;

------------------- Delete Section ----------------------------------------

-- 1. Cleanup: Remove customers with no activity in 3 years
DELETE FROM CUSTOMER
WHERE CustomerID NOT IN (
    SELECT DISTINCT CustomerID FROM REGISTRATION 
    WHERE RegistrationDate > CURRENT_DATE - INTERVAL '3 years'
);

-- 2. Data Retention: Delete payments older than 5 years
DELETE FROM PAYMENT
WHERE PaymentDate < CURRENT_DATE - INTERVAL '5 years';

-- 3. Optimization: Delete routes that have never been assigned to a tour
DELETE FROM ROUTE
WHERE RouteID NOT IN (SELECT DISTINCT RouteID FROM GUIDEDTOUR);

------------------- Updates Section ---------------------------------------

-- 1. Incentive: 10% raise for highly rated, experienced guides
UPDATE GUIDE
SET DailyRate = DailyRate * 1.10
WHERE Rating > 4.8 AND ExperienceYears > 5;

-- 2. Maintenance: Auto-complete past tours
UPDATE GUIDEDTOUR
SET TourStatusID = (SELECT TourStatusID FROM TOURSTATUS WHERE StatusName = 'Completed')
WHERE EndDate < CURRENT_DATE 
  AND TourStatusID != (SELECT TourStatusID FROM TOURSTATUS WHERE StatusName = 'Completed');

-- 3. Data Standardization: Israeli Phone Format
UPDATE CUSTOMER
SET Phone = CONCAT('+972', SUBSTRING(Phone, 2))
WHERE Phone LIKE '0%';