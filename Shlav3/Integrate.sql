-- ============================================================
-- File: Integrate.sql
-- Phase 3: Database Integration
-- Description: Integration of VetCare system (Clinic & Medical)
--              with HR system (Eitan's department)
-- Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
-- ============================================================

-- ============================================================
-- PART A: Create tables from the received HR system
-- These tables come from backup_eitan_friend.sql
-- We create them here only if they don't exist yet
-- ============================================================

-- 1. Department table (independent entity)
CREATE TABLE IF NOT EXISTS Department (
    department_id   INTEGER         PRIMARY KEY,
    dept_name       VARCHAR(255)    NOT NULL UNIQUE,
    location        VARCHAR(255)
);

-- 2. Role table (independent entity)
CREATE TABLE IF NOT EXISTS Role (
    role_id     INTEGER         PRIMARY KEY,
    role_title  VARCHAR(255)    NOT NULL
);

-- 3. Employee_Contract table (independent entity)
CREATE TABLE IF NOT EXISTS Employee_Contract (
    contract_id INTEGER         PRIMARY KEY,
    start_date  DATE            DEFAULT CURRENT_DATE NOT NULL,
    salary      NUMERIC(10,2)   NOT NULL,
    CONSTRAINT chk_min_salary CHECK (salary >= 5000)
);

-- 4. Employee table (depends on Department, Role, Employee_Contract)
CREATE TABLE IF NOT EXISTS Employee (
    employee_id     INTEGER         PRIMARY KEY,
    first_name      VARCHAR(50)     NOT NULL,
    last_name       VARCHAR(50)     NOT NULL,
    phone_number    VARCHAR(15),
    department_id   INTEGER         REFERENCES Department(department_id),
    role_id         INTEGER         REFERENCES Role(role_id),
    contract_id     INTEGER         REFERENCES Employee_Contract(contract_id),
    birth_date      DATE
);

-- 5. Office table (depends on Department)
CREATE TABLE IF NOT EXISTS Office (
    office_id       INTEGER         PRIMARY KEY,
    office_name     VARCHAR(255)    NOT NULL,
    department_id   INTEGER         REFERENCES Department(department_id),
    office_location VARCHAR(255)
);

-- 6. Shift table (independent entity)
CREATE TABLE IF NOT EXISTS Shift (
    shift_id    INTEGER         PRIMARY KEY,
    shift_type  VARCHAR(50)     NOT NULL,
    start_time  TIME            NOT NULL
);

-- 7. Shift_Assignment table (depends on Employee, Shift)
CREATE TABLE IF NOT EXISTS Shift_Assignment (
    assignment_id   INTEGER     PRIMARY KEY,
    employee_id     INTEGER     REFERENCES Employee(employee_id),
    shift_id        INTEGER     REFERENCES Shift(shift_id),
    work_date       DATE        NOT NULL,
    CONSTRAINT unique_assignment UNIQUE (employee_id, shift_id, work_date)
);


-- ============================================================
-- PART B: Integration - Connect the two systems
-- Decision: Veterinarians are also employees of the organization.
-- We add an employee_id FK to the Veterinarian table to link
-- a vet to the Employee table from the HR system.
-- ============================================================

-- Add employee_id column to Veterinarian table (only if it doesn't exist yet)
ALTER TABLE Veterinarian
ADD COLUMN IF NOT EXISTS employee_id INTEGER;

-- Add foreign key constraint linking Veterinarian to Employee
ALTER TABLE Veterinarian DROP CONSTRAINT IF EXISTS fk_vet_employee;
ALTER TABLE Veterinarian
ADD CONSTRAINT fk_vet_employee
FOREIGN KEY (employee_id) REFERENCES Employee(employee_id)
ON DELETE SET NULL ON UPDATE CASCADE;

-- ============================================================
-- PART C: Populate the link between Veterinarian and Employee
-- We assign employee IDs to the first veterinarians to show
-- the integration works. In a real scenario, all vets would
-- be registered as employees.
-- ============================================================

-- Link some veterinarians to employees (sample data)
-- We use employees who have role_id = 2 (which could represent "Medical Staff")
UPDATE Veterinarian SET employee_id = 10  WHERE VetID = 1;
UPDATE Veterinarian SET employee_id = 20  WHERE VetID = 2;
UPDATE Veterinarian SET employee_id = 30  WHERE VetID = 3;
UPDATE Veterinarian SET employee_id = 40  WHERE VetID = 4;
UPDATE Veterinarian SET employee_id = 50  WHERE VetID = 5;
UPDATE Veterinarian SET employee_id = 60  WHERE VetID = 6;
UPDATE Veterinarian SET employee_id = 70  WHERE VetID = 7;
UPDATE Veterinarian SET employee_id = 80  WHERE VetID = 8;
UPDATE Veterinarian SET employee_id = 90  WHERE VetID = 9;
UPDATE Veterinarian SET employee_id = 100 WHERE VetID = 10;

-- ============================================================
-- Verification: Display all tables and their row counts
-- ============================================================
SELECT 'Animal' AS table_name, COUNT(*) AS row_count FROM Animal
UNION ALL
SELECT 'Veterinarian', COUNT(*) FROM Veterinarian
UNION ALL
SELECT 'MedicalVisit', COUNT(*) FROM MedicalVisit
UNION ALL
SELECT 'Treatment', COUNT(*) FROM Treatment
UNION ALL
SELECT 'Medication', COUNT(*) FROM Medication
UNION ALL
SELECT 'Vaccination', COUNT(*) FROM Vaccination
UNION ALL
SELECT 'Mirsham_Visit_Treatment', COUNT(*) FROM Mirsham_Visit_Treatment
UNION ALL
SELECT 'Hergel_Treatment_Medication', COUNT(*) FROM Hergel_Treatment_Medication
UNION ALL
SELECT 'Treatment_Vaccination', COUNT(*) FROM Treatment_Vaccination
UNION ALL
SELECT 'Department', COUNT(*) FROM Department
UNION ALL
SELECT 'Role', COUNT(*) FROM Role
UNION ALL
SELECT 'Employee_Contract', COUNT(*) FROM Employee_Contract
UNION ALL
SELECT 'Employee', COUNT(*) FROM Employee
UNION ALL
SELECT 'Office', COUNT(*) FROM Office
UNION ALL
SELECT 'Shift', COUNT(*) FROM Shift
UNION ALL
SELECT 'Shift_Assignment', COUNT(*) FROM Shift_Assignment
ORDER BY table_name;
