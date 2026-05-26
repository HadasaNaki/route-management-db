-- ======================================================
-- Project: Guided Tours Management System
-- Description: Seed data for integrated schema
-- ======================================================

-- Lookup tables
INSERT INTO DIFFICULTYLEVEL(DifficultyID, DifficultyName) VALUES(1, 'Easy');
INSERT INTO DIFFICULTYLEVEL(DifficultyID, DifficultyName) VALUES(2, 'Medium');
INSERT INTO DIFFICULTYLEVEL(DifficultyID, DifficultyName) VALUES(3, 'Hard');
INSERT INTO DIFFICULTYLEVEL(DifficultyID, DifficultyName) VALUES(4, 'Extreme');

INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(1, 'Planned');
INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(2, 'Open for Registration');
INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(3, 'Full');
INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(4, 'In Progress');
INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(5, 'Completed');
INSERT INTO TOURSTATUS(TourStatusID, StatusName) VALUES(6, 'Cancelled');

INSERT INTO REGISTRATIONSTATUS(RegistrationStatusID, StatusName) VALUES(1, 'Needs Action');
INSERT INTO REGISTRATIONSTATUS(RegistrationStatusID, StatusName) VALUES(2, 'Confirmed');
INSERT INTO REGISTRATIONSTATUS(RegistrationStatusID, StatusName) VALUES(3, 'Cancelled');

INSERT INTO PAYMENTSTATUS(PaymentStatusID, StatusName) VALUES(1, 'Pending');
INSERT INTO PAYMENTSTATUS(PaymentStatusID, StatusName) VALUES(2, 'Completed');
INSERT INTO PAYMENTSTATUS(PaymentStatusID, StatusName) VALUES(3, 'Failed');
INSERT INTO PAYMENTSTATUS(PaymentStatusID, StatusName) VALUES(4, 'Refunded');

-- Guides
INSERT INTO GUIDE (GuideID, FirstName, LastName, Phone, Expertise) VALUES (1, 'Yossi', 'Cohen', '050-1234567', 'Desert Tours');
INSERT INTO GUIDE (GuideID, FirstName, LastName, Phone, Expertise) VALUES (2, 'Ronit', 'Levi', '054-7654321', 'City Architecture');
INSERT INTO GUIDE (GuideID, FirstName, LastName, Phone, Expertise) VALUES (3, 'David', 'Mizrachi', '052-9876543', 'Mountain Tracking');

-- Routes
INSERT INTO ROUTE (RouteID, Name, EstimatedDuration, DifficultyID) VALUES (101, 'Negev Night Trail', 180, 2);
INSERT INTO ROUTE (RouteID, Name, EstimatedDuration, DifficultyID) VALUES (102, 'Jerusalem Old City', 120, 1);
INSERT INTO ROUTE (RouteID, Name, EstimatedDuration, DifficultyID) VALUES (103, 'Golan Heights Trek', 360, 3);

-- GuidedTours
INSERT INTO GUIDEDTOUR (TripID, StartDate, MaxParticipants, Price, RouteID, GuideID, TourStatusID) VALUES (1001, '2026-05-15', 25, 120, 101, 1, 2);
INSERT INTO GUIDEDTOUR (TripID, StartDate, MaxParticipants, Price, RouteID, GuideID, TourStatusID) VALUES (1002, '2026-06-01', 30, 85.50, 102, 2, 2);
INSERT INTO GUIDEDTOUR (TripID, StartDate, MaxParticipants, Price, RouteID, GuideID, TourStatusID) VALUES (1003, '2026-06-20', 15, 250, 103, 3, 1);

-- Participants
INSERT INTO PARTICIPANT (ParticipantID, FullName, Email, Phone) VALUES (1, 'Avraham Israel', 'avi@gmail.com', '050-1111111');
INSERT INTO PARTICIPANT (ParticipantID, FullName, Email, Phone) VALUES (2, 'Moshe Levi', 'moshe@gmail.com', '052-2222222');
INSERT INTO PARTICIPANT (ParticipantID, FullName, Email, Phone) VALUES (3, 'Rachel Cohen', 'rachel@gmail.com', '054-3333333');

-- Registrations
INSERT INTO REGISTRATION (RegistrationID, RegistrationDate, TourID, ParticipantID, RegistrationStatusID) VALUES (1, '2026-05-10', 1001, 1, 2);
INSERT INTO REGISTRATION (RegistrationID, RegistrationDate, TourID, ParticipantID, RegistrationStatusID) VALUES (2, '2026-05-11', 1002, 2, 1);
INSERT INTO REGISTRATION (RegistrationID, RegistrationDate, TourID, ParticipantID, RegistrationStatusID) VALUES (3, '2026-05-12', 1003, 3, 2);

-- Locations
INSERT INTO LOCATION (LocationID, LocationName, Category) VALUES (1, 'Machtesh Ramon', 'Nature');
INSERT INTO LOCATION (LocationID, LocationName, Category) VALUES (2, 'Western Wall', 'Historic');
INSERT INTO LOCATION (LocationID, LocationName, Category) VALUES (3, 'Banias', 'Nature');

-- Passes Through
INSERT INTO PASSES_THROUGH (LocationID, RouteID) VALUES (1, 101);
INSERT INTO PASSES_THROUGH (LocationID, RouteID) VALUES (2, 102);
INSERT INTO PASSES_THROUGH (LocationID, RouteID) VALUES (3, 103);
