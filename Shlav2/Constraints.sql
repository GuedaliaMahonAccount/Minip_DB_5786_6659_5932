-- 1. Cleanup and constraint for Animal (Weight)
-- Delete animals whose weight is not in the valid range
DELETE FROM Animal 
WHERE Weight < 0.01 OR Weight > 999.99;

ALTER TABLE Animal
ADD CONSTRAINT chk_animal_weight_range
CHECK (Weight BETWEEN 0.01 AND 999.99);


-- 2. Cleanup and constraint for MedicalVisit (Dates)
-- Delete visits that are scheduled in the future
DELETE FROM MedicalVisit 
WHERE VisitDate > CURRENT_DATE;

ALTER TABLE MedicalVisit
ADD CONSTRAINT chk_visit_not_future
CHECK (VisitDate <= CURRENT_DATE);


-- 3. Cleanup and constraint for MedicalVisit (Duplicates)
-- Delete duplicate visits for the same animal, vet, and day.
-- The "ctid" trick is specific to PostgreSQL: it keeps only the first row found among duplicates.
DELETE FROM MedicalVisit
WHERE ctid NOT IN (
    SELECT min(ctid)
    FROM MedicalVisit
    GROUP BY AnimalID, VetID, VisitDate
);

ALTER TABLE MedicalVisit
ADD CONSTRAINT uq_one_visit_per_animal_per_vet_per_day
UNIQUE (AnimalID, VetID, VisitDate);


-- 4. Cleanup and constraint for Medication (Expiration)
-- Delete medications with an expiration date that is too old
DELETE FROM Medication 
WHERE ExpirationDate < '2020-01-01';

ALTER TABLE Medication
ADD CONSTRAINT chk_medication_min_expiration
CHECK (ExpirationDate >= '2020-01-01');