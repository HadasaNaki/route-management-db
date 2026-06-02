-- ======================================================
-- Project: Guided Tours Management System
-- Phase 3: Integration (Integrate.sql)
-- Description: Migrates the original Stage 1 schema to the integrated
--   joint schema. Run ONCE on the original Stage 1 database.
--   In Docker the full integrated schema is created by init-db/ scripts.
-- ======================================================

-- ============================================================
-- STEP 1: Rename Stage 1 tables to match the joint diagram
-- ============================================================
ALTER TABLE IF EXISTS TRIP    RENAME TO GUIDEDTOUR;
ALTER TABLE IF EXISTS BOOKING RENAME TO REGISTRATION;

-- ============================================================
-- STEP 2: Rename Stage 1 columns to match the joint diagram
-- ============================================================

-- GUIDEDTOUR (was TRIP)
ALTER TABLE GUIDEDTOUR RENAME COLUMN DepartureDate TO StartDate;
ALTER TABLE GUIDEDTOUR RENAME COLUMN MaxCapacity   TO MaxParticipants;

-- REGISTRATION (was BOOKING)
ALTER TABLE REGISTRATION RENAME COLUMN BookingID   TO RegistrationID;
ALTER TABLE REGISTRATION RENAME COLUMN BookingDate TO RegistrationDate;
ALTER TABLE REGISTRATION RENAME COLUMN TripID      TO TourID;

-- PAYMENT (BookingID FK → RegistrationID)
-- Only needed if PAYMENT existed before Stage 3 (Stage 2 DB); safe to skip otherwise
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'payment' AND column_name = 'bookingid'
    ) THEN
        ALTER TABLE PAYMENT RENAME COLUMN BookingID TO RegistrationID;
    END IF;
END $$;

-- ROUTE
ALTER TABLE ROUTE RENAME COLUMN RouteName TO Name;
ALTER TABLE ROUTE RENAME COLUMN Duration  TO EstimatedDuration;


-- ============================================================
-- STEP 3: Integrate DIFFICULTYLEVEL and extend ROUTE
-- ============================================================
CREATE TABLE IF NOT EXISTS DIFFICULTYLEVEL
(
    DifficultyID   INT         NOT NULL,
    DifficultyName VARCHAR(50) NOT NULL,
    PRIMARY KEY (DifficultyID)
);

INSERT INTO DIFFICULTYLEVEL(DifficultyID, DifficultyName) VALUES(1, 'Easy')    ON CONFLICT DO NOTHING;
INSERT INTO DIFFICULTYLEVEL(DifficultyID, DifficultyName) VALUES(2, 'Medium')  ON CONFLICT DO NOTHING;
INSERT INTO DIFFICULTYLEVEL(DifficultyID, DifficultyName) VALUES(3, 'Hard')    ON CONFLICT DO NOTHING;
INSERT INTO DIFFICULTYLEVEL(DifficultyID, DifficultyName) VALUES(4, 'Extreme') ON CONFLICT DO NOTHING;

ALTER TABLE ROUTE ADD COLUMN IF NOT EXISTS EstimatedLength NUMERIC(8,2) CHECK (EstimatedLength >= 0);
ALTER TABLE ROUTE ADD COLUMN IF NOT EXISTS Description     VARCHAR(500);
ALTER TABLE ROUTE ADD COLUMN IF NOT EXISTS DifficultyID    INT;

-- Migrate string difficulty values (only if the old column still exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'route' AND column_name = 'difficulty'
    ) THEN
        UPDATE ROUTE SET DifficultyID = 1 WHERE difficulty = 'Easy';
        UPDATE ROUTE SET DifficultyID = 2 WHERE difficulty = 'Medium';
        UPDATE ROUTE SET DifficultyID = 3 WHERE difficulty = 'Hard';
        ALTER TABLE ROUTE DROP COLUMN difficulty;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_route_difficulty'
    ) THEN
        ALTER TABLE ROUTE
            ADD CONSTRAINT fk_route_difficulty
            FOREIGN KEY (DifficultyID) REFERENCES DIFFICULTYLEVEL(DifficultyID);
    END IF;
END $$;


-- ============================================================
-- STEP 4: Extend GUIDE with Stage 2 attributes
-- ============================================================
ALTER TABLE GUIDE ADD COLUMN IF NOT EXISTS Email           VARCHAR(100) UNIQUE;
ALTER TABLE GUIDE ADD COLUMN IF NOT EXISTS BirthDate       DATE;
ALTER TABLE GUIDE ADD COLUMN IF NOT EXISTS JoinDate        DATE;
ALTER TABLE GUIDE ADD COLUMN IF NOT EXISTS DailyRate       NUMERIC(8,2) CHECK (DailyRate >= 0);
ALTER TABLE GUIDE ADD COLUMN IF NOT EXISTS ExperienceYears INT          CHECK (ExperienceYears >= 0);
ALTER TABLE GUIDE ADD COLUMN IF NOT EXISTS Rating          NUMERIC(3,2) CHECK (Rating BETWEEN 0 AND 5);
ALTER TABLE GUIDE ADD COLUMN IF NOT EXISTS Address         VARCHAR(200);
ALTER TABLE GUIDE ADD COLUMN IF NOT EXISTS Notes           VARCHAR(500);


-- ============================================================
-- STEP 5: Integrate TOURSTATUS and extend GUIDEDTOUR
-- ============================================================
CREATE TABLE IF NOT EXISTS TOURSTATUS
(
    TourStatusID INT         NOT NULL,
    StatusName   VARCHAR(50) NOT NULL,
    PRIMARY KEY (TourStatusID)
);

INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(1, 'Planned')               ON CONFLICT DO NOTHING;
INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(2, 'Open for Registration')  ON CONFLICT DO NOTHING;
INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(3, 'Full')                   ON CONFLICT DO NOTHING;
INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(4, 'In Progress')            ON CONFLICT DO NOTHING;
INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(5, 'Completed')              ON CONFLICT DO NOTHING;
INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(6, 'Cancelled')              ON CONFLICT DO NOTHING;

ALTER TABLE GUIDEDTOUR ADD COLUMN IF NOT EXISTS EndDate      DATE;
ALTER TABLE GUIDEDTOUR ADD COLUMN IF NOT EXISTS StartTime    VARCHAR(10);
ALTER TABLE GUIDEDTOUR ADD COLUMN IF NOT EXISTS EndTime      VARCHAR(10);
ALTER TABLE GUIDEDTOUR ADD COLUMN IF NOT EXISTS MeetingPoint VARCHAR(200);
ALTER TABLE GUIDEDTOUR ADD COLUMN IF NOT EXISTS Notes        VARCHAR(500);
ALTER TABLE GUIDEDTOUR ADD COLUMN IF NOT EXISTS TourStatusID INT;

-- Default all existing tours to 'Planned'
UPDATE GUIDEDTOUR SET TourStatusID = 1 WHERE TourStatusID IS NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_guidedtour_tourstatus'
    ) THEN
        ALTER TABLE GUIDEDTOUR
            ADD CONSTRAINT fk_guidedtour_tourstatus
            FOREIGN KEY (TourStatusID) REFERENCES TOURSTATUS(TourStatusID);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'chk_enddate'
    ) THEN
        ALTER TABLE GUIDEDTOUR
            ADD CONSTRAINT chk_enddate
            CHECK (EndDate IS NULL OR EndDate >= StartDate);
    END IF;
END $$;


-- ============================================================
-- STEP 6: Extend PARTICIPANT
-- ============================================================
ALTER TABLE PARTICIPANT ADD COLUMN IF NOT EXISTS JoinDate DATE;


-- ============================================================
-- STEP 7: Integrate REGISTRATIONSTATUS and extend REGISTRATION
-- ============================================================
CREATE TABLE IF NOT EXISTS REGISTRATIONSTATUS
(
    RegistrationStatusID INT         NOT NULL,
    StatusName           VARCHAR(50) NOT NULL,
    PRIMARY KEY (RegistrationStatusID)
);

INSERT INTO REGISTRATIONSTATUS(RegistrationStatusID, StatusName) VALUES(1, 'Needs Action') ON CONFLICT DO NOTHING;
INSERT INTO REGISTRATIONSTATUS(RegistrationStatusID, StatusName) VALUES(2, 'Confirmed')    ON CONFLICT DO NOTHING;
INSERT INTO REGISTRATIONSTATUS(RegistrationStatusID, StatusName) VALUES(3, 'Cancelled')    ON CONFLICT DO NOTHING;

ALTER TABLE REGISTRATION ADD COLUMN IF NOT EXISTS AmountToPay          NUMERIC(8,2) CHECK (AmountToPay >= 0);
ALTER TABLE REGISTRATION ADD COLUMN IF NOT EXISTS Notes                VARCHAR(500);
ALTER TABLE REGISTRATION ADD COLUMN IF NOT EXISTS RegistrationStatusID INT;

-- Migrate old string Status to RegistrationStatusID (only if old column exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'registration' AND column_name = 'status'
    ) THEN
        UPDATE REGISTRATION SET RegistrationStatusID = 1 WHERE status = 'Pending';
        UPDATE REGISTRATION SET RegistrationStatusID = 2 WHERE status IN ('Paid', 'Confirmed');
        UPDATE REGISTRATION SET RegistrationStatusID = 3 WHERE status = 'Cancelled';
        ALTER TABLE REGISTRATION DROP COLUMN status;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_reg_regstatus'
    ) THEN
        ALTER TABLE REGISTRATION
            ADD CONSTRAINT fk_reg_regstatus
            FOREIGN KEY (RegistrationStatusID) REFERENCES REGISTRATIONSTATUS(RegistrationStatusID);
    END IF;
END $$;


-- ============================================================
-- STEP 8: Integrate PAYMENTSTATUS and PAYMENT
-- ============================================================
CREATE TABLE IF NOT EXISTS PAYMENTSTATUS
(
    PaymentStatusID INT         NOT NULL,
    StatusName      VARCHAR(50) NOT NULL,
    PRIMARY KEY (PaymentStatusID)
);

INSERT INTO PAYMENTSTATUS(PaymentStatusID, StatusName) VALUES(1, 'Pending')   ON CONFLICT DO NOTHING;
INSERT INTO PAYMENTSTATUS(PaymentStatusID, StatusName) VALUES(2, 'Completed') ON CONFLICT DO NOTHING;
INSERT INTO PAYMENTSTATUS(PaymentStatusID, StatusName) VALUES(3, 'Failed')    ON CONFLICT DO NOTHING;
INSERT INTO PAYMENTSTATUS(PaymentStatusID, StatusName) VALUES(4, 'Refunded')  ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS PAYMENT
(
    PaymentID       INT          NOT NULL,
    PaymentDate     DATE         NOT NULL,
    Amount          NUMERIC(8,2) CHECK (Amount >= 0),
    Notes           VARCHAR(500),
    PaymentMethod   VARCHAR(50)  NOT NULL,
    ReferenceNumber VARCHAR(50),
    RegistrationID  INT          NOT NULL,  -- FK to REGISTRATION (renamed from BookingID)
    PaymentStatusID INT          NOT NULL,
    PRIMARY KEY (PaymentID),
    FOREIGN KEY (RegistrationID)  REFERENCES REGISTRATION(RegistrationID),
    FOREIGN KEY (PaymentStatusID) REFERENCES PAYMENTSTATUS(PaymentStatusID)
);