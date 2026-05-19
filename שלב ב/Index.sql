-- ===============================================================
-- אינדקסים שלב ב' - Index.sql
-- תוספת 3 אינדקסים ובחינת זמני ביצוע
-- ===============================================================

-- =============================================
-- INDEX 1: תאריך יציאה של סיור (Trip.DepartureDate)
-- =============================================

-- לפני אינדקס
EXPLAIN ANALYZE SELECT * FROM TRIP WHERE DepartureDate = '2026-05-15';

-- הוספת אינדקס
CREATE INDEX idx_trip_departure ON TRIP (DepartureDate);

-- אחרי אינדקס
EXPLAIN ANALYZE SELECT * FROM TRIP WHERE DepartureDate = '2026-05-15';

-- =============================================
-- INDEX 2: מזהה הסיור בטבלת הזמנות (Booking.TripID)
-- =============================================

-- לפני אינדקס
EXPLAIN ANALYZE SELECT * FROM BOOKING WHERE TripID = 1001;

-- הוספת אינדקס
CREATE INDEX idx_booking_trip ON BOOKING (TripID);

-- אחרי אינדקס
EXPLAIN ANALYZE SELECT * FROM BOOKING WHERE TripID = 1001;

-- =============================================
-- INDEX 3: דוא"ל של משתתף (Participant.Email) - שימושי לחיפושים ושליפות 
-- =============================================

-- לפני אינדקס
EXPLAIN ANALYZE SELECT * FROM PARTICIPANT WHERE Email = 'sample@sample.com';

-- הוספת אינדקס
CREATE INDEX idx_participant_email ON PARTICIPANT (Email);

-- אחרי אינדקס
EXPLAIN ANALYZE SELECT * FROM PARTICIPANT WHERE Email = 'sample@sample.com';
