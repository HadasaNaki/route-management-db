-- =========================================================================
-- Scenario 1: Accidental Update and ROLLBACK
-- =========================================================================

-- 1. View current state (Top 5 guides)
SELECT GuideID, FirstName, Rating FROM GUIDE LIMIT 5;

-- 2. The Mistake: Setting all ratings to 5.0
UPDATE GUIDE SET Rating = 5.0;

-- 3. Verify mistake
SELECT GuideID, FirstName, Rating FROM GUIDE LIMIT 5;

-- 4. Revert
ROLLBACK;

-- 5. Final check (Original data restored)
SELECT GuideID, FirstName, Rating FROM GUIDE LIMIT 5;

-- =========================================================================
-- Scenario 2: Valid Update and COMMIT
-- =========================================================================

-- 1. View current email
SELECT FullName, Email FROM CUSTOMER WHERE CustomerID = 1;

-- 2. Perform update
UPDATE CUSTOMER SET Email = 'new_email@gmail.com' WHERE CustomerID = 1;

-- 3. Save permanently
COMMIT;

-- 4. Verify persistence
SELECT FullName, Email FROM CUSTOMER WHERE CustomerID = 1;