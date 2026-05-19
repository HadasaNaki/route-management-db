-- 1. Guide Rating Validation
ALTER TABLE GUIDE ADD CONSTRAINT chk_guide_rating CHECK (Rating >= 0 AND Rating <= 5);

-- 2. Email Uniqueness (Adding to Customer as an example of Alter Table)
ALTER TABLE CUSTOMER ADD CONSTRAINT uni_cust_email UNIQUE (Email);

-- 3. Financial Integrity (Price must be positive)
ALTER TABLE GUIDE ADD CONSTRAINT chk_daily_rate CHECK (DailyRate > 0);

-- 4. Tour Capacity Logic
ALTER TABLE GUIDEDTOUR ADD CONSTRAINT chk_max_participants CHECK (MaxParticipants > 0);

-- 5. Date Consistency
ALTER TABLE GUIDEDTOUR ADD CONSTRAINT chk_tour_dates CHECK (EndDate >= StartDate);

-- 6. Default Values (Standard SQL Syntax)
ALTER TABLE REGISTRATION ALTER COLUMN RegistrationDate SET DEFAULT CURRENT_DATE;