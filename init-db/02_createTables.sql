-- ======================================================
-- Project: Guided Tours Management System
-- Description: Database schema creation script
-- ======================================================

-- 1. Create Route table (Stores general tour paths)
CREATE TABLE ROUTE
(
  RouteID INT NOT NULL, -- Primary Key [cite: 4]
  RouteName VARCHAR(100) NOT NULL,
  Duration INT NOT NULL, -- Estimated time in minutes
  Difficulty VARCHAR(20) NOT NULL, -- e.g., 'Easy', 'Medium', 'Hard'
  PRIMARY KEY (RouteID),
  CONSTRAINT chk_duration CHECK (Duration > 0) -- Ensuring positive duration
);

-- 2. Create Guide table (Stores tour leader information)
CREATE TABLE GUIDE
(
  GuideID INT NOT NULL, -- Primary Key [cite: 13]
  FirstName VARCHAR(50) NOT NULL,
  LastName VARCHAR(50) NOT NULL,
  Phone VARCHAR(20) NOT NULL,
  Expertise VARCHAR(100), -- Area of specialization
  PRIMARY KEY (GuideID)
);

-- 3. Create Trip table (Specific tour instances)
CREATE TABLE TRIP
(
  TripID INT NOT NULL, -- Primary Key [cite: 25]
  DepartureDate DATE NOT NULL, -- First mandatory date [cite: 27]
  MaxCapacity INT NOT NULL,
  Price NUMERIC(8,2) NOT NULL,
  RouteID INT NOT NULL, -- Foreign Key to Route
  GuideID INT NOT NULL, -- Foreign Key to Guide
  PRIMARY KEY (TripID),
  FOREIGN KEY (RouteID) REFERENCES ROUTE(RouteID),
  FOREIGN KEY (GuideID) REFERENCES GUIDE(GuideID),
  CONSTRAINT chk_capacity CHECK (MaxCapacity > 0),
  CONSTRAINT chk_price CHECK (Price >= 0)
);

-- 4. Create Participant table (Stores traveler details)
CREATE TABLE PARTICIPANT
(
  ParticipantID INT NOT NULL, -- Primary Key [cite: 35]
  FullName VARCHAR(100) NOT NULL,
  Email VARCHAR(100) NOT NULL,
  Phone VARCHAR(20) NOT NULL,
  PRIMARY KEY (ParticipantID)
);

-- 5. Create Booking table (Registration instances)
CREATE TABLE BOOKING
(
  BookingID INT NOT NULL, -- Primary Key [cite: 44]
  BookingDate DATE NOT NULL, -- Second mandatory date [cite: 46]
  Status VARCHAR(20) NOT NULL, -- e.g., 'Paid', 'Pending', 'Cancelled'
  TripID INT NOT NULL, -- Foreign Key to Trip
  ParticipantID INT NOT NULL, -- Foreign Key to Participant
  PRIMARY KEY (BookingID),
  FOREIGN KEY (TripID) REFERENCES TRIP(TripID),
  FOREIGN KEY (ParticipantID) REFERENCES PARTICIPANT(ParticipantID)
);

-- 6. Create Location table (Points of Interest)
CREATE TABLE LOCATION
(
  LocationID INT NOT NULL, -- Primary Key [cite: 52]
  LocationName VARCHAR(100) NOT NULL,
  Category VARCHAR(50), -- e.g., 'Nature', 'Historic'
  PRIMARY KEY (LocationID)
);

-- 7. Create Passes_Through table (Junction table for M:N relationship)
CREATE TABLE PASSES_THROUGH
(
  LocationID INT NOT NULL,
  RouteID INT NOT NULL,
  PRIMARY KEY (LocationID, RouteID),
  FOREIGN KEY (LocationID) REFERENCES LOCATION(LocationID),
  FOREIGN KEY (RouteID) REFERENCES ROUTE(RouteID)
);
