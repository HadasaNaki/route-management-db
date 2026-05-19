-- Data generated from a mock data service (e.g. Mockaroo)
-- Inserting Guides
INSERT INTO GUIDE (GuideID, FirstName, LastName, Phone, Expertise) VALUES (1, 'Yossi', 'Cohen', '050-1234567', 'Desert Tours');
INSERT INTO GUIDE (GuideID, FirstName, LastName, Phone, Expertise) VALUES (2, 'Ronit', 'Levi', '054-7654321', 'City Architecture');
INSERT INTO GUIDE (GuideID, FirstName, LastName, Phone, Expertise) VALUES (3, 'David', 'Mizrachi', '052-9876543', 'Mountain Tracking');

-- Inserting Routes
INSERT INTO ROUTE (RouteID, RouteName, Duration, Difficulty) VALUES (101, 'Negev Night Trail', 180, 'Medium');
INSERT INTO ROUTE (RouteID, RouteName, Duration, Difficulty) VALUES (102, 'Jerusalem Old City', 120, 'Easy');
INSERT INTO ROUTE (RouteID, RouteName, Duration, Difficulty) VALUES (103, 'Golan Heights Trek', 360, 'Hard');

-- Inserting Trips
INSERT INTO TRIP (TripID, DepartureDate, MaxCapacity, Price, RouteID, GuideID) VALUES (1001, '2026-05-15', 25, 120, 101, 1);
INSERT INTO TRIP (TripID, DepartureDate, MaxCapacity, Price, RouteID, GuideID) VALUES (1002, '2026-06-01', 30, 85.50, 102, 2);
INSERT INTO TRIP (TripID, DepartureDate, MaxCapacity, Price, RouteID, GuideID) VALUES (1003, '2026-06-20', 15, 250, 103, 3);

-- Inserting Participants
INSERT INTO PARTICIPANT (ParticipantID, FullName, Email, Phone) VALUES (1, 'Avraham Israel', 'avi@gmail.com', '050-1111111');
INSERT INTO PARTICIPANT (ParticipantID, FullName, Email, Phone) VALUES (2, 'Moshe Levi', 'moshe@gmail.com', '052-2222222');
INSERT INTO PARTICIPANT (ParticipantID, FullName, Email, Phone) VALUES (3, 'Rachel Cohen', 'rachel@gmail.com', '054-3333333');

-- Inserting Bookings
INSERT INTO BOOKING (BookingID, BookingDate, Status, TripID, ParticipantID) VALUES (1, '2026-05-10', 'Confirmed', 1001, 1);
INSERT INTO BOOKING (BookingID, BookingDate, Status, TripID, ParticipantID) VALUES (2, '2026-05-11', 'Pending', 1002, 2);
INSERT INTO BOOKING (BookingID, BookingDate, Status, TripID, ParticipantID) VALUES (3, '2026-05-12', 'Confirmed', 1003, 3);

-- Inserting Locations
INSERT INTO LOCATION (LocationID, LocationName, Category) VALUES (1, 'Machtesh Ramon', 'Nature');
INSERT INTO LOCATION (LocationID, LocationName, Category) VALUES (2, 'Western Wall', 'Historic');
INSERT INTO LOCATION (LocationID, LocationName, Category) VALUES (3, 'Banias', 'Nature');

-- Inserting Passes_Through
INSERT INTO PASSES_THROUGH (LocationID, RouteID) VALUES (1, 101);
INSERT INTO PASSES_THROUGH (LocationID, RouteID) VALUES (2, 102);
INSERT INTO PASSES_THROUGH (LocationID, RouteID) VALUES (3, 103);
