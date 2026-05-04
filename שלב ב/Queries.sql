-- ===============================================================
-- שאילתות שלב ב' - Queries.sql
-- מערכת לניהול סיורים
-- ===============================================================

-- ===============================================================
-- חלק 1: 4 שאילתות בשתי דרכים שונות + הסבר יעילות בדוח
-- ===============================================================

-- שאילתה 1: מציאת שמות וטלפונים של משתתפים שהזמינו סיור העובר באתר מסוג 'Historic' או 'Nature'.
-- דרך 1: שימוש בלולאות IN (תתי שאילתות)
SELECT FullName, Phone
FROM PARTICIPANT
WHERE ParticipantID IN (
    SELECT ParticipantID
    FROM BOOKING
    WHERE TripID IN (
        SELECT TripID
        FROM TRIP
        WHERE RouteID IN (
            SELECT RouteID
            FROM PASSES_THROUGH
            WHERE LocationID IN (
                SELECT LocationID
                FROM LOCATION
                WHERE Category IN ('Historic', 'Nature')
            )
        )
    )
);

-- דרך 2: שימוש ב- EXISTS תתי שאילתות מתואמות
SELECT p.FullName, p.Phone
FROM PARTICIPANT p
WHERE EXISTS (
    SELECT 1 
    FROM BOOKING b
    JOIN TRIP t ON b.TripID = t.TripID
    JOIN PASSES_THROUGH pt ON t.RouteID = pt.RouteID
    JOIN LOCATION l ON pt.LocationID = l.LocationID
    WHERE b.ParticipantID = p.ParticipantID
    AND l.Category IN ('Historic', 'Nature')
);


-- שאילתה 2: שמות מסלולים שיש להם יותר מ-2 סיורים מתוכננים בשנת 2026.
-- דרך 1: שימוש ב- GROUP BY ו- HAVING
SELECT r.RouteName, COUNT(t.TripID) AS TotalTrips
FROM ROUTE r
JOIN TRIP t ON r.RouteID = t.RouteID
WHERE EXTRACT(YEAR FROM t.DepartureDate) = 2026
GROUP BY r.RouteID, r.RouteName
HAVING COUNT(t.TripID) > 2;

-- דרך 2: שאילתה פנימית (Inline Query) מבוססת COUNT
SELECT RouteName, TotalTrips
FROM (
    SELECT r.RouteName, (
        SELECT COUNT(*) 
        FROM TRIP t 
        WHERE t.RouteID = r.RouteID 
        AND EXTRACT(YEAR FROM t.DepartureDate) = 2026
    ) AS TotalTrips
    FROM ROUTE r
) AS Temp
WHERE TotalTrips > 2;


-- שאילתה 3: מציאת שמות מדריכים אשר לא שובצו לאף סיור בחודש מאי בשנת 2026.
-- דרך 1: שימוש ב- NOT IN
SELECT FirstName, LastName
FROM GUIDE
WHERE GuideID NOT IN (
    SELECT GuideID
    FROM TRIP
    WHERE EXTRACT(YEAR FROM DepartureDate) = 2026 
      AND EXTRACT(MONTH FROM DepartureDate) = 5
);

-- דרך 2: שימוש ב- LEFT JOIN וסינון NULL
SELECT g.FirstName, g.LastName
FROM GUIDE g
LEFT JOIN TRIP t ON g.GuideID = t.GuideID 
    AND EXTRACT(YEAR FROM t.DepartureDate) = 2026 
    AND EXTRACT(MONTH FROM t.DepartureDate) = 5
WHERE t.TripID IS NULL;


-- שאילתה 4: מציאת הסיור (Trip) בעל המחיר הגבוה ביותר לכל דרגת קושי של מסלול.
-- דרך 1: שימוש בתת שאילתה עם הקינון של MAX 
SELECT t.TripID, r.Difficulty, t.Price
FROM TRIP t
JOIN ROUTE r ON t.RouteID = r.RouteID
WHERE t.Price = (
    SELECT MAX(t2.Price)
    FROM TRIP t2
    JOIN ROUTE r2 ON t2.RouteID = r2.RouteID
    WHERE r2.Difficulty = r.Difficulty
);

-- דרך 2: שימוש ב- Window Function מבוסס RANK
SELECT TripID, Difficulty, Price
FROM (
    SELECT t.TripID, r.Difficulty, t.Price,
           RANK() OVER (PARTITION BY r.Difficulty ORDER BY t.Price DESC) AS rnk
    FROM TRIP t
    JOIN ROUTE r ON t.RouteID = r.RouteID
) AS ranked
WHERE rnk = 1;


-- ===============================================================
-- חלק 2: 4 שאילתות SELECT מורכבות נוספות
-- ===============================================================

-- שאילתה 5: חישוב סך ההכנסות מקטלוג הטיולים עבור כל מדריך בשנת 2026, מסודר מהגבוה לנמוך.
SELECT g.FirstName || ' ' || g.LastName AS GuideName, SUM(t.Price) AS TotalRevenue
FROM GUIDE g
JOIN TRIP t ON g.GuideID = t.GuideID
JOIN BOOKING b ON b.TripID = t.TripID
WHERE b.Status = 'Paid'
  AND EXTRACT(YEAR FROM t.DepartureDate) = 2026
GROUP BY g.GuideID, g.FirstName, g.LastName
ORDER BY TotalRevenue DESC;

-- שאילתה 6: פרטי משתתפים שהזמינו סיורים במסלולים ברמת קושי 'Hard', ועוברים ביותר מ-2 מיקומים.
SELECT p.FullName, p.Email, p.Phone
FROM PARTICIPANT p
JOIN BOOKING b ON p.ParticipantID = b.ParticipantID
JOIN TRIP t ON b.TripID = t.TripID
JOIN ROUTE r ON t.RouteID = r.RouteID
WHERE r.Difficulty = 'Hard'
  AND r.RouteID IN (
      SELECT RouteID
      FROM PASSES_THROUGH
      GROUP BY RouteID
      HAVING COUNT(LocationID) > 2
  );

-- שאילתה 7: מציאת החודש בו בוצעו הכי הרבה הזמנות (BookingDate) בשנת 2026 (מאתגר עם Date function).
SELECT EXTRACT(MONTH FROM BookingDate) AS BookingMonth, COUNT(BookingID) AS TotalBookings
FROM BOOKING
WHERE EXTRACT(YEAR FROM BookingDate) = 2026
GROUP BY EXTRACT(MONTH FROM BookingDate)
ORDER BY TotalBookings DESC
LIMIT 1;

-- שאילתה 8: רשימת טיולים בהם כמות המשתתפים המקסימלית גדולה מהממוצע הכללי, כולל שם המסלול, שם המדריך, ותאריך מדויק.
SELECT t.TripID, r.RouteName, (g.FirstName || ' ' || g.LastName) AS GuideName, t.DepartureDate, t.MaxCapacity
FROM TRIP t
JOIN ROUTE r ON t.RouteID = r.RouteID
JOIN GUIDE g ON t.GuideID = g.GuideID
WHERE t.MaxCapacity > (SELECT AVG(MaxCapacity) FROM TRIP)
ORDER BY t.DepartureDate;


-- ===============================================================
-- חלק 3: 3 שאילתות UPDATE 
-- ===============================================================

-- Update 1: עדכון עלויות מחיר של סיורים אשר עוברים בטבע וברמת קושי גבוהה, עליית מחיר של 10%.
UPDATE TRIP
SET Price = Price * 1.10
WHERE RouteID IN (
    SELECT r.RouteID
    FROM ROUTE r
    JOIN PASSES_THROUGH pt ON r.RouteID = pt.RouteID
    JOIN LOCATION l ON pt.LocationID = l.LocationID
    WHERE r.Difficulty = 'Hard' AND l.Category = 'Nature'
);

-- Update 2: ביטול (Cancelled) אוטומטי להזמנות אשר שייכות לסיורים שמתוכננים לחודש הנוכחי אבל טרם שולמו.
UPDATE BOOKING
SET Status = 'Cancelled'
WHERE Status != 'Paid' AND TripID IN (
    SELECT TripID
    FROM TRIP
    WHERE EXTRACT(MONTH FROM DepartureDate) = EXTRACT(MONTH FROM CURRENT_DATE)
      AND EXTRACT(YEAR FROM DepartureDate) = EXTRACT(YEAR FROM CURRENT_DATE)
);

-- Update 3: קידום תחומי מומחיות למדריכים בעלי יותר מ-5 סיורים רשומים, הוספת הקידומת 'Senior '. 
UPDATE GUIDE
SET Expertise = 'Senior ' || Expertise
WHERE GuideID IN (
    SELECT GuideID
    FROM TRIP
    GROUP BY GuideID
    HAVING COUNT(TripID) > 5
) AND Expertise NOT LIKE 'Senior %';


-- ===============================================================
-- חלק 4: 3 שאילתות DELETE 
-- ===============================================================

-- Delete 1: מחיקת הזמנות שעדיין בהמתנה ושהסיור יוצא בעוד פחות מ-3 ימים (שחרור מקום).
DELETE FROM BOOKING
WHERE Status = 'Pending'
  AND TripID IN (
      SELECT TripID
      FROM TRIP
      WHERE DepartureDate <= CURRENT_DATE + INTERVAL '3 days'
  );

-- Delete 2: מחיקת מיקומים/אתרי ביקור שאינם משויכים כלל למסלולים בבסיס הנתונים.
DELETE FROM LOCATION
WHERE LocationID NOT IN (
    SELECT DISTINCT LocationID FROM PASSES_THROUGH
);

-- Delete 3: ביטול סיורים (מחיקתם) שאין בהם אף משתתף שהזמין ותאריך היציאה עבר.
DELETE FROM TRIP
WHERE TripID NOT IN (SELECT TripID FROM BOOKING)
  AND DepartureDate < CURRENT_DATE;

