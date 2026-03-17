-- ============================================================
-- File: RollbackCommit.sql
-- Phase 2 – Transaction Management (ROLLBACK & COMMIT)
-- Database: VetCare Management System (basnat)
-- ============================================================

-- ************************************************************
-- TRANSACTION 1: UPDATE + ROLLBACK
-- Scenario: We try to double the cost of all visits in January 2024,
--           but then we ROLLBACK to undo the change.
-- ************************************************************

-- Step 1: Verify the data BEFORE the transaction
SELECT VisitID, VisitDate, Cost 
FROM MedicalVisit 
WHERE EXTRACT(MONTH FROM VisitDate) = 1 
  AND EXTRACT(YEAR FROM VisitDate) = 2024
ORDER BY VisitID
LIMIT 10;

-- Step 2: Begin the transaction
BEGIN;

-- Step 3: Perform the UPDATE (double the cost)
UPDATE MedicalVisit
SET Cost = Cost * 2
WHERE EXTRACT(MONTH FROM VisitDate) = 1 
  AND EXTRACT(YEAR FROM VisitDate) = 2024;

-- Step 4: Verify the data DURING the transaction (costs should be doubled)
SELECT VisitID, VisitDate, Cost 
FROM MedicalVisit 
WHERE EXTRACT(MONTH FROM VisitDate) = 1 
  AND EXTRACT(YEAR FROM VisitDate) = 2024
ORDER BY VisitID
LIMIT 10;

-- Step 5: ROLLBACK – Cancel all changes made in this transaction
ROLLBACK;

-- Step 6: Verify the data AFTER ROLLBACK (costs should be back to original)
SELECT VisitID, VisitDate, Cost 
FROM MedicalVisit 
WHERE EXTRACT(MONTH FROM VisitDate) = 1 
  AND EXTRACT(YEAR FROM VisitDate) = 2024
ORDER BY VisitID
LIMIT 10;

/*
  EXPLANATION:
  ────────────
  After the ROLLBACK, the data returns to its ORIGINAL state.
  The UPDATE was executed within the transaction but was NEVER committed
  to the database. This demonstrates the ATOMICITY property of ACID:
  either ALL operations in a transaction succeed, or NONE of them do.
  
  USE CASE: This is essential when you detect an error mid-transaction
  (e.g., wrong calculation, wrong WHERE clause) and want to cancel
  everything before the damage becomes permanent.
*/


-- ************************************************************
-- TRANSACTION 2: UPDATE + COMMIT
-- Scenario: We apply a 10% discount on all visits with Cost > 400
--           from February 2024, and we COMMIT to make it permanent.
-- ************************************************************

-- Step 1: Verify the data BEFORE the transaction
SELECT VisitID, VisitDate, Cost 
FROM MedicalVisit 
WHERE EXTRACT(MONTH FROM VisitDate) = 2 
  AND EXTRACT(YEAR FROM VisitDate) = 2024
  AND Cost > 400
ORDER BY VisitID
LIMIT 10;

-- Step 2: Begin the transaction
BEGIN;

-- Step 3: Perform the UPDATE (apply 10% discount)
UPDATE MedicalVisit
SET Cost = ROUND(Cost * 0.90, 2)
WHERE EXTRACT(MONTH FROM VisitDate) = 2 
  AND EXTRACT(YEAR FROM VisitDate) = 2024
  AND Cost > 400;

-- Step 4: Verify the data DURING the transaction (costs should be reduced by 10%)
SELECT VisitID, VisitDate, Cost 
FROM MedicalVisit 
WHERE EXTRACT(MONTH FROM VisitDate) = 2 
  AND EXTRACT(YEAR FROM VisitDate) = 2024
  AND Cost > 360  -- lower threshold to still see affected rows
ORDER BY VisitID
LIMIT 10;

-- Step 5: COMMIT – Make all changes PERMANENT
COMMIT;

-- Step 6: Verify the data AFTER COMMIT (changes are permanent)
SELECT VisitID, VisitDate, Cost 
FROM MedicalVisit 
WHERE EXTRACT(MONTH FROM VisitDate) = 2 
  AND EXTRACT(YEAR FROM VisitDate) = 2024
  AND Cost > 360
ORDER BY VisitID
LIMIT 10;

/*
  EXPLANATION:
  ────────────
  After the COMMIT, the changes are PERMANENT and DURABLE.
  Even if the database server crashes immediately after the COMMIT,
  the data will be preserved (DURABILITY property of ACID).
  
  The key difference with Transaction 1:
  - ROLLBACK → changes are DISCARDED (as if they never happened)
  - COMMIT   → changes are SAVED PERMANENTLY
  
  This demonstrates the CONSISTENCY and DURABILITY properties:
  the database moves from one valid state to another, and once
  committed, the new state survives any failure.
*/
