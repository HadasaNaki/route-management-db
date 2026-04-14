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
