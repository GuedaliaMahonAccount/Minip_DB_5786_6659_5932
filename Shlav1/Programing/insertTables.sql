-- ============================================================
-- File: insertTables.sql
-- Description: Data population for tables NOT imported externally.
--
-- NOTE: Animal data is imported manually via CSV (MOCK_DATA.csv) in pgAdmin.
--       Veterinarian data is imported via mockaroo_veterinarians.sql.
--       This script handles: Treatment, Medication, Vaccination,
--       MedicalVisit (20,000+ rows), and Mirsham_Visit_Treatment (20,000+ rows).
-- ============================================================

-- 1. TREATMENT (500 rows)
INSERT INTO Treatment (TreatmentID, Description, Duration, Type, Severity)
SELECT 
    i, 
    'Treatment_Desc_' || i, 
    (ARRAY['30 mins','1 hour','2 hours'])[ (i % 3) + 1 ],
    (ARRAY['Routine','Surgical','Emergency'])[ (i % 3) + 1 ],
    (ARRAY['Low','Medium','High','Critical'])[ (i % 4) + 1 ]
FROM generate_series(1, 500) AS i;

-- 2. MEDICATION (500 rows)
INSERT INTO Medication (MedID, CommercialName, ActiveIngredient, DosageUnit, ExpirationDate)
SELECT 
    i, 
    'Med_' || i, 
    'Ingredient_' || i, 
    (ARRAY['mg','ml','Tablet'])[ (i % 3) + 1 ],
    '2025-01-01'::date + (random() * 1000)::int
FROM generate_series(1, 500) AS i;

-- 3. VACCINATION (500 rows)
INSERT INTO Vaccination (VacID, Name, Manufacturer, FrequencyMonths, StorageTemp)
SELECT 
    i, 
    'Vax_' || i, 
    'Pharma_' || i, 
    (ARRAY[6, 12, 24, 36])[ (i % 4) + 1 ],
    (ARRAY['2°C','4°C','-20°C'])[ (i % 3) + 1 ]
FROM generate_series(1, 500) AS i;

-- ============================================================
-- 🔥 THE 2 TABLES WITH 20,000+ ROWS 🔥
-- ============================================================

-- 4. MEDICALVISIT (20,000 rows)
-- AnimalID range: 1-1000 (from MOCK_DATA.csv, ~1001 rows)
-- VetID range: 1-800 (from mockaroo_veterinarians.sql)
INSERT INTO MedicalVisit (VisitID, VisitDate, Reason, Summary, Cost, AnimalID, VetID)
SELECT 
    i, 
    '2023-01-01'::date + (random() * 700)::int,
    'Reason for visit ' || i,
    'Summary of visit ' || i,
    round((random() * 500 + 50)::numeric, 2),
    (random() * 999 + 1)::int,  -- Associates a random animal between 1 and 1000
    (random() * 799 + 1)::int   -- Associates a random veterinarian between 1 and 800
FROM generate_series(1, 20000) AS i;

-- 5. MIRSHAM_VISIT_TREATMENT (20,000 rows)
INSERT INTO Mirsham_Visit_Treatment (VisitID, TreatmentID)
SELECT DISTINCT
    (random() * 19999 + 1)::int,  -- Random VisitID
    (random() * 499 + 1)::int     -- Random TreatmentID
FROM generate_series(1, 25000) AS i
ON CONFLICT DO NOTHING; -- Ignore duplicates if random generation creates the same pair