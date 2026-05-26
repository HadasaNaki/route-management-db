-- ======================================================
-- Project: Guided Tours Management System
-- Description: Database schema creation script (Integrated - Stage 3+)
-- Matches the joint ERD diagram agreed upon in Stage 3.
-- ======================================================

-- 1. Create DifficultyLevel lookup table
CREATE TABLE DIFFICULTYLEVEL
(
  DifficultyID   INT         NOT NULL,
  DifficultyName VARCHAR(50) NOT NULL,
  PRIMARY KEY (DifficultyID)
);

-- 2. Create Route table
CREATE TABLE ROUTE
(
  RouteID           INT          NOT NULL,
  Name              VARCHAR(100) NOT NULL,
  EstimatedDuration INT,
  EstimatedLength   NUMERIC(8,2) CHECK (EstimatedLength >= 0),
  Description       VARCHAR(500),
  DifficultyID      INT,
  PRIMARY KEY (RouteID),
  CONSTRAINT chk_est_duration CHECK (EstimatedDuration IS NULL OR EstimatedDuration > 0),
  FOREIGN KEY (DifficultyID) REFERENCES DIFFICULTYLEVEL(DifficultyID)
);

-- 3. Create Guide table
CREATE TABLE GUIDE
(
  GuideID         INT          NOT NULL,
  FirstName       VARCHAR(50)  NOT NULL,
  LastName        VARCHAR(50)  NOT NULL,
  Phone           VARCHAR(20)  NOT NULL,
  Expertise       VARCHAR(100),
  Email           VARCHAR(100) UNIQUE,
  BirthDate       DATE,
  JoinDate        DATE,
  DailyRate       NUMERIC(8,2) CHECK (DailyRate >= 0),
  ExperienceYears INT          CHECK (ExperienceYears >= 0),
  Rating          NUMERIC(3,2) CHECK (Rating BETWEEN 0 AND 5),
  Address         VARCHAR(200),
  Notes           VARCHAR(500),
  PRIMARY KEY (GuideID)
);

-- 4. Create TourStatus lookup table
CREATE TABLE TOURSTATUS
(
  TourStatusID INT         NOT NULL,
  StatusName   VARCHAR(50) NOT NULL,
  PRIMARY KEY (TourStatusID)
);

-- 5. Create GuidedTour table (specific tour instances)
CREATE TABLE GUIDEDTOUR
(
  TripID          INT          NOT NULL,
  StartDate       DATE         NOT NULL,
  EndDate         DATE,
  StartTime       VARCHAR(10),
  EndTime         VARCHAR(10),
  MaxParticipants INT          NOT NULL,
  Price           NUMERIC(8,2) NOT NULL,
  MeetingPoint    VARCHAR(200),
  Notes           VARCHAR(500),
  TourStatusID    INT,
  RouteID         INT          NOT NULL,
  GuideID         INT          NOT NULL,
  PRIMARY KEY (TripID),
  FOREIGN KEY (RouteID)      REFERENCES ROUTE(RouteID),
  FOREIGN KEY (GuideID)      REFERENCES GUIDE(GuideID),
  FOREIGN KEY (TourStatusID) REFERENCES TOURSTATUS(TourStatusID),
  CONSTRAINT chk_participants CHECK (MaxParticipants > 0),
  CONSTRAINT chk_price        CHECK (Price >= 0),
  CONSTRAINT chk_enddate      CHECK (EndDate IS NULL OR EndDate >= StartDate)
);

-- 6. Create Participant table
CREATE TABLE PARTICIPANT
(
  ParticipantID INT          NOT NULL,
  FullName      VARCHAR(100) NOT NULL,
  Email         VARCHAR(100) NOT NULL,
  Phone         VARCHAR(20)  NOT NULL,
  JoinDate      DATE,
  PRIMARY KEY (ParticipantID)
);

-- 7. Create RegistrationStatus lookup table
CREATE TABLE REGISTRATIONSTATUS
(
  RegistrationStatusID INT         NOT NULL,
  StatusName           VARCHAR(50) NOT NULL,
  PRIMARY KEY (RegistrationStatusID)
);

-- 8. Create Registration table (registration instances)
CREATE TABLE REGISTRATION
(
  RegistrationID       INT          NOT NULL,
  RegistrationDate     DATE         NOT NULL,
  AmountToPay          NUMERIC(8,2) CHECK (AmountToPay >= 0),
  Notes                VARCHAR(500),
  TourID               INT          NOT NULL,
  ParticipantID        INT          NOT NULL,
  RegistrationStatusID INT          NOT NULL,
  PRIMARY KEY (RegistrationID),
  FOREIGN KEY (TourID)               REFERENCES GUIDEDTOUR(TripID),
  FOREIGN KEY (ParticipantID)        REFERENCES PARTICIPANT(ParticipantID),
  FOREIGN KEY (RegistrationStatusID) REFERENCES REGISTRATIONSTATUS(RegistrationStatusID)
);

-- 9. Create Location table (Points of Interest)
CREATE TABLE LOCATION
(
  LocationID   INT          NOT NULL,
  LocationName VARCHAR(100) NOT NULL,
  Category     VARCHAR(50),
  PRIMARY KEY (LocationID)
);

-- 10. Create Passes_Through junction table (M:N Route-Location)
CREATE TABLE PASSES_THROUGH
(
  LocationID INT NOT NULL,
  RouteID    INT NOT NULL,
  PRIMARY KEY (LocationID, RouteID),
  FOREIGN KEY (LocationID) REFERENCES LOCATION(LocationID),
  FOREIGN KEY (RouteID)    REFERENCES ROUTE(RouteID)
);

-- 11. Create PaymentStatus lookup table
CREATE TABLE PAYMENTSTATUS
(
  PaymentStatusID INT         NOT NULL,
  StatusName      VARCHAR(50) NOT NULL,
  PRIMARY KEY (PaymentStatusID)
);

-- 12. Create Payment table
CREATE TABLE PAYMENT
(
  PaymentID       INT          NOT NULL,
  PaymentDate     DATE         NOT NULL,
  Amount          NUMERIC(8,2) CHECK (Amount >= 0),
  Notes           VARCHAR(500),
  PaymentMethod   VARCHAR(50)  NOT NULL,
  ReferenceNumber VARCHAR(50),
  RegistrationID  INT          NOT NULL,
  PaymentStatusID INT          NOT NULL,
  PRIMARY KEY (PaymentID),
  FOREIGN KEY (RegistrationID)  REFERENCES REGISTRATION(RegistrationID),
  FOREIGN KEY (PaymentStatusID) REFERENCES PAYMENTSTATUS(PaymentStatusID)
);
