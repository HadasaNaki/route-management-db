-- =========================================================================
-- Index Section
-- Phase 2: Indexes and Performance Testing
-- Tour Guide Management System
-- =========================================================================

-- =========================================================================
-- Query 1: Search payments by payment date
-- Purpose: Improve performance for date-based payment reports
-- =========================================================================

-- Runtime test BEFORE index
EXPLAIN ANALYZE
SELECT *
FROM PAYMENT
WHERE PaymentDate BETWEEN '2026-01-01' AND '2026-12-31';

-- Create index
CREATE INDEX idx_payment_paymentdate
ON PAYMENT (PaymentDate);

-- Runtime test AFTER index
EXPLAIN ANALYZE
SELECT *
FROM PAYMENT
WHERE PaymentDate BETWEEN '2026-01-01' AND '2026-12-31';


-- =========================================================================
-- Query 2: Search registrations by tour
-- Purpose: Improve performance when finding all registrations for a specific tour
-- =========================================================================

-- Runtime test BEFORE index
EXPLAIN ANALYZE
SELECT *
FROM REGISTRATION
WHERE TourID = 1;

-- Create index
CREATE INDEX idx_registration_tourid
ON REGISTRATION (TourID);

-- Runtime test AFTER index
EXPLAIN ANALYZE
SELECT *
FROM REGISTRATION
WHERE TourID = 1;


-- =========================================================================
-- Query 3: Search guided tours by route
-- Purpose: Improve performance when finding all tours of a specific route
-- =========================================================================

-- Runtime test BEFORE index
EXPLAIN ANALYZE
SELECT *
FROM GUIDEDTOUR
WHERE RouteID = 1;

-- Create index
CREATE INDEX idx_guidedtour_routeid
ON GUIDEDTOUR (RouteID);

-- Runtime test AFTER index
EXPLAIN ANALYZE
SELECT *
FROM GUIDEDTOUR
WHERE RouteID = 1;