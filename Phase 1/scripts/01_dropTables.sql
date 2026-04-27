-- ======================================================
-- Project: Guided Tours Management System
-- Description: Cleanup script to drop all tables
-- Note: Tables are dropped in reverse order of creation
-- to handle foreign key dependencies.
-- ======================================================

DROP TABLE IF EXISTS PASSES_THROUGH CASCADE;
DROP TABLE IF EXISTS BOOKING CASCADE;
DROP TABLE IF EXISTS PARTICIPANT CASCADE;
DROP TABLE IF EXISTS TRIP CASCADE;
DROP TABLE IF EXISTS GUIDE CASCADE;
DROP TABLE IF EXISTS ROUTE CASCADE;
DROP TABLE IF EXISTS LOCATION CASCADE;
