-- ===============================================================
-- אילוצים שלב ב' - Constraints.sql
-- תוספת של 3 אילוצים חדשים
-- ===============================================================

-- אילוץ 1: בדיקת תקינות אימייל למשתתף. לא ניתן להזין אימייל ללא שטרודל.
ALTER TABLE PARTICIPANT
ADD CONSTRAINT chk_email_format 
CHECK (Email LIKE '%@%.%');

-- אילוץ 2: הגבלה על הסטטוסים האפשריים עבור הזמנה כך שיהיו מוגדרים מראש.
ALTER TABLE BOOKING
ADD CONSTRAINT chk_booking_status 
CHECK (Status IN ('Paid', 'Pending', 'Cancelled'));

-- אילוץ 3: הגבלה על רמות קושי של מסלולים כך שיכילו ערך מרשימה ידועה.
ALTER TABLE ROUTE
ADD CONSTRAINT chk_route_difficulty 
CHECK (Difficulty IN ('Easy', 'Medium', 'Hard'));
>>>>>>> f32bdc3 (stage 2: Add scheme, reports and constraints (stage_b copies))
