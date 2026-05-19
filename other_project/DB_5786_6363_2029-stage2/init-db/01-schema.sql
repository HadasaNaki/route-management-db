CREATE TABLE GUIDE
(
    GuideID INT NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Phone VARCHAR(20) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    BirthDate DATE,
    JoinDate DATE,
    DailyRate NUMERIC(8,2) CHECK (DailyRate >= 0),
    ExperienceYears INT CHECK (ExperienceYears >= 0),
    Rating NUMERIC(3,2) CHECK (Rating BETWEEN 0 AND 5),
    Address VARCHAR(200),
    Notes VARCHAR(500),
    PRIMARY KEY (GuideID)
);

CREATE TABLE DIFFICULTYLEVEL
(
    DifficultyID INT NOT NULL,
    DifficultyName VARCHAR(50) NOT NULL,
    PRIMARY KEY (DifficultyID)
);

CREATE TABLE ROUTE
(
    RouteID INT NOT NULL,
    Name VARCHAR(100) NOT NULL,
    EstimatedLength NUMERIC(8,2) CHECK (EstimatedLength >= 0),
    EstimatedDuration INT CHECK (EstimatedDuration > 0),
    Description VARCHAR(500),
    DifficultyID INT NOT NULL,
    PRIMARY KEY (RouteID),
    FOREIGN KEY (DifficultyID) REFERENCES DIFFICULTYLEVEL(DifficultyID)
);

CREATE TABLE TOURSTATUS
(
    TourStatusID INT NOT NULL,
    StatusName VARCHAR(50) NOT NULL,
    PRIMARY KEY (TourStatusID)
);

CREATE TABLE GUIDEDTOUR
(
    TourID INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE,
    StartTime VARCHAR(10),
    EndTime VARCHAR(10),
    MeetingPoint VARCHAR(200) NOT NULL,
    Price NUMERIC(8,2) CHECK (Price >= 0),
    MaxParticipants INT CHECK (MaxParticipants > 0),
    Notes VARCHAR(500),
    TourStatusID INT NOT NULL,
    GuideID INT NOT NULL,
    RouteID INT NOT NULL,
    PRIMARY KEY (TourID),
    FOREIGN KEY (GuideID) REFERENCES GUIDE(GuideID),
    FOREIGN KEY (RouteID) REFERENCES ROUTE(RouteID),
    FOREIGN KEY (TourStatusID) REFERENCES TOURSTATUS(TourStatusID),
    CHECK (EndDate IS NULL OR EndDate >= StartDate)
);

CREATE TABLE CUSTOMER
(
    CustomerID INT NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    Phone VARCHAR(20) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    JoinDate DATE,
    PRIMARY KEY (CustomerID)
);

CREATE TABLE REGISTRATIONSTATUS
(
    RegistrationStatusID INT NOT NULL,
    StatusName VARCHAR(50) NOT NULL,
    PRIMARY KEY (RegistrationStatusID)
);

CREATE TABLE REGISTRATION
(
    RegistrationID INT NOT NULL,
    RegistrationDate DATE NOT NULL,
    AmountToPay NUMERIC(8,2) CHECK (AmountToPay >= 0),
    Notes VARCHAR(500),
    TourID INT NOT NULL,
    RegistrationStatusID INT NOT NULL,
    CustomerID INT NOT NULL,
    PRIMARY KEY (RegistrationID),
    FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID),
    FOREIGN KEY (TourID) REFERENCES GUIDEDTOUR(TourID),
    FOREIGN KEY (RegistrationStatusID) REFERENCES REGISTRATIONSTATUS(RegistrationStatusID)
);

CREATE TABLE PAYMENTSTATUS
(
    PaymentStatusID INT NOT NULL,
    StatusName VARCHAR(50) NOT NULL,
    PRIMARY KEY (PaymentStatusID)
);

CREATE TABLE PAYMENT
(
    PaymentID INT NOT NULL,
    PaymentDate DATE NOT NULL,
    Amount NUMERIC(8,2) CHECK (Amount >= 0),
    Notes VARCHAR(500),
    PaymentMethod VARCHAR(50) NOT NULL,
    ReferenceNumber VARCHAR(50),
    RegistrationID INT NOT NULL,
    PaymentStatusID INT NOT NULL,
    PRIMARY KEY (PaymentID),
    FOREIGN KEY (RegistrationID) REFERENCES REGISTRATION(RegistrationID),
    FOREIGN KEY (PaymentStatusID) REFERENCES PAYMENTSTATUS(PaymentStatusID)
);

