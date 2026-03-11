-- ============================================================
-- File: dropTables.sql
-- Description: Dropping tables in reverse order 
-- to avoid foreign key errors.
-- ============================================================

-- 1. Dropping junction tables (Children)
DROP TABLE IF EXISTS Treatment_Vaccination CASCADE;
DROP TABLE IF EXISTS Hergel_Treatment_Medication CASCADE;
DROP TABLE IF EXISTS Mirsham_Visit_Treatment CASCADE;

-- 2. Dropping MedicalVisit table (Child of Animal and Vet)
DROP TABLE IF EXISTS MedicalVisit CASCADE;

-- 3. Dropping main tables (Parents)
DROP TABLE IF EXISTS Vaccination CASCADE;
DROP TABLE IF EXISTS Medication CASCADE;
DROP TABLE IF EXISTS Treatment CASCADE;
DROP TABLE IF EXISTS Veterinarian CASCADE;
DROP TABLE IF EXISTS Animal CASCADE;