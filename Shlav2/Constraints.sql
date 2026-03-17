-- ============================================================
-- File: Constraints.sql
-- Phase 2 – Structure Modifications (ALTER TABLE + Constraint Tests)
-- Database: VetCare Management System (basnat)
-- ============================================================


-- ************************************************************
-- CONSTRAINT 1: CHECK – Animal weight must be between 0.01 and 999.99 kg
-- Rationale: The original CHECK only ensures Weight > 0, but does not
--            prevent a weight of zero or other illogical values.
--            The upper bound is set to 999.99 to match the column type
--            NUMERIC(5,2), which stores at most 3 digits before the decimal.
-- ************************************************************

ALTER TABLE Animal
ADD CONSTRAINT chk_animal_weight_range
CHECK (Weight BETWEEN 0.01 AND 999.99);

-- TEST: This INSERT should FAIL because Weight = 0 violates the lower bound (0.01)
-- Note: We use 0 rather than 15000 because NUMERIC(5,2) cannot store values
--       above 999.99 — the column type would reject it before the CHECK runs.
INSERT INTO Animal (AnimalID, Name, Species, BirthDate, Gender, Weight)
VALUES (99901, 'TestZero', 'Cat', '2020-01-01', 'Male', 0);
-- ERROR expected: new row violates check constraint "chk_animal_weight_range"


-- ************************************************************
-- CONSTRAINT 2: CHECK – Visit date must not be in the future
-- Rationale: A medical visit cannot be recorded for a date that has not
--            yet occurred. This prevents data entry errors.
-- ************************************************************

ALTER TABLE MedicalVisit
ADD CONSTRAINT chk_visit_not_future
CHECK (VisitDate <= CURRENT_DATE);

-- TEST: This INSERT should FAIL because the visit date is in 2030
INSERT INTO MedicalVisit (VisitID, VisitDate, Reason, Summary, Cost, AnimalID, VetID)
VALUES (99901, '2030-12-31', 'Future checkup', 'Impossible', 100.00, 1, 1);
-- ERROR expected: new row violates check constraint "chk_visit_not_future"


-- ************************************************************
-- CONSTRAINT 3: UNIQUE – Each animal can only have ONE visit per day
--               per veterinarian (prevents duplicate entries)
-- Rationale: It is logically impossible for the same vet to see the same
--            animal twice on the same day. This prevents accidental duplicate
--            record entry.
-- ************************************************************

ALTER TABLE MedicalVisit
ADD CONSTRAINT uq_one_visit_per_animal_per_vet_per_day
UNIQUE (AnimalID, VetID, VisitDate);

-- TEST: First, insert a valid visit, then try to insert a DUPLICATE
-- Step 1: Insert a valid visit (should succeed)
INSERT INTO MedicalVisit (VisitID, VisitDate, Reason, Summary, Cost, AnimalID, VetID)
VALUES (99902, '2024-06-15', 'Routine checkup', 'All good', 75.00, 1, 1);

-- Step 2: Try to insert a duplicate (same animal, same vet, same date) → SHOULD FAIL
INSERT INTO MedicalVisit (VisitID, VisitDate, Reason, Summary, Cost, AnimalID, VetID)
VALUES (99903, '2024-06-15', 'Another checkup', 'Duplicate', 80.00, 1, 1);
-- ERROR expected: duplicate key value violates unique constraint "uq_one_visit_per_animal_per_vet_per_day"


-- ************************************************************
-- CONSTRAINT 4 (BONUS): CHECK – Medication expiration must be after 2020
-- Rationale: Any medication with an expiration predating 2020 is clearly
--            erroneous data. This protects data quality at entry time.
-- ************************************************************

ALTER TABLE Medication
ADD CONSTRAINT chk_medication_min_expiration
CHECK (ExpirationDate >= '2020-01-01');

-- TEST: This INSERT should FAIL because expiration is in 2015
INSERT INTO Medication (MedID, CommercialName, ActiveIngredient, DosageUnit, ExpirationDate)
VALUES (99901, 'OldMed', 'Expired_Ingredient', 'mg', '2015-06-01');
-- ERROR expected: new row violates check constraint "chk_medication_min_expiration"


-- ============================================================
-- CLEANUP: Remove test records (optional – run after screenshots)
-- ============================================================
-- DELETE FROM MedicalVisit WHERE VisitID IN (99902);
-- Note: 99901 and 99903 never got inserted (constraint violations).
