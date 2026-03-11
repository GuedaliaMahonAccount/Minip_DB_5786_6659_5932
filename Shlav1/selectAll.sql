-- ============================================================
-- File: selectAll.sql
-- Description: Verification of inserted data
-- ============================================================

SELECT * FROM Animal;
SELECT * FROM Veterinarian;
SELECT * FROM MedicalVisit;
SELECT * FROM Treatment;
SELECT * FROM Medication;
SELECT * FROM Vaccination;

SELECT * FROM Mirsham_Visit_Treatment;
SELECT * FROM Hergel_Treatment_Medication;
SELECT * FROM Treatment_Vaccination;

-- Bonus Query: Verify that you have exactly 20,000 rows
SELECT count(*) AS total_visits FROM MedicalVisit;