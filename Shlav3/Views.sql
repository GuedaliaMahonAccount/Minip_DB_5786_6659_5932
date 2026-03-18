-- ============================================================
-- File: Views.sql
-- Phase 3: Views and Queries
-- Description: 3 Views + 2 queries per view = 6 queries total
-- Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
-- ============================================================


-- ============================================================
-- VIEW 1: VetCare Department Perspective (Original System)
-- Description: A comprehensive view of medical visits showing
--   animal information, veterinarian details, visit info,
--   and treatment count. Combines Animal, Veterinarian,
--   and MedicalVisit tables.
-- ============================================================

CREATE OR REPLACE VIEW vet_visit_summary AS
SELECT
    mv.VisitID,
    a.Name              AS animal_name,
    a.Species           AS animal_species,
    a.Gender            AS animal_gender,
    v.FirstName || ' ' || v.LastName AS vet_full_name,
    v.Specialization    AS vet_specialization,
    mv.VisitDate,
    mv.Reason,
    mv.Cost,
    (SELECT COUNT(*)
     FROM Mirsham_Visit_Treatment mvt
     WHERE mvt.VisitID = mv.VisitID
    ) AS treatment_count
FROM MedicalVisit mv
JOIN Animal a       ON mv.AnimalID = a.AnimalID
JOIN Veterinarian v ON mv.VetID = v.VetID;


-- ============================================================
-- Query 1.1 on vet_visit_summary:
-- Find the top 5 most expensive visits, showing animal and vet
-- ============================================================
-- Description: This query retrieves the 5 most costly medical
-- visits. Useful for understanding which visits generate the
-- most revenue or require the most resources.

SELECT
    animal_name,
    animal_species,
    vet_full_name,
    vet_specialization,
    VisitDate,
    Reason,
    Cost,
    treatment_count
FROM vet_visit_summary
WHERE Cost IS NOT NULL
ORDER BY Cost DESC
LIMIT 5;


-- ============================================================
-- Query 1.2 on vet_visit_summary:
-- Count visits per species and average cost
-- ============================================================
-- Description: This query groups visits by animal species to
-- find which species have the most medical visits and the
-- average cost per species. Useful for resource planning.

SELECT
    animal_species,
    COUNT(*)        AS total_visits,
    ROUND(AVG(Cost), 2) AS avg_cost,
    MAX(Cost)       AS max_cost,
    MIN(Cost)       AS min_cost
FROM vet_visit_summary
WHERE Cost IS NOT NULL
GROUP BY animal_species
ORDER BY total_visits DESC
LIMIT 10;


-- ============================================================
-- VIEW 2: HR Department Perspective (Received System)
-- Description: A comprehensive view of employees showing their
--   personal info, department, role, office, and salary.
--   Combines Employee, Department, Role, Employee_Contract,
--   and Office tables.
-- ============================================================

CREATE OR REPLACE VIEW hr_employee_overview AS
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_full_name,
    e.phone_number,
    e.birth_date,
    d.dept_name         AS department_name,
    d.location          AS department_location,
    r.role_title,
    ec.salary,
    ec.start_date       AS contract_start_date,
    o.office_name
FROM Employee e
JOIN Department d           ON e.department_id = d.department_id
JOIN Role r                 ON e.role_id = r.role_id
LEFT JOIN Employee_Contract ec ON e.contract_id = ec.contract_id
LEFT JOIN Office o          ON e.department_id = o.department_id;


-- ============================================================
-- Query 2.1 on hr_employee_overview:
-- Find the top 10 highest-paid employees with their details
-- ============================================================
-- Description: This query finds the 10 employees with the
-- highest salary, showing their department, role, and office.
-- Useful for salary auditing.

SELECT
    employee_full_name,
    department_name,
    role_title,
    salary,
    contract_start_date,
    office_name
FROM hr_employee_overview
WHERE salary IS NOT NULL
ORDER BY salary DESC
LIMIT 10;


-- ============================================================
-- Query 2.2 on hr_employee_overview:
-- Department summary: count employees and average salary
-- ============================================================
-- Description: This query groups employees by department and
-- calculates the number of employees and the average salary
-- per department. Useful for HR management.

SELECT
    department_name,
    COUNT(DISTINCT employee_id) AS num_employees,
    ROUND(AVG(salary), 2)       AS avg_salary,
    MAX(salary)                 AS max_salary
FROM hr_employee_overview
WHERE salary IS NOT NULL
GROUP BY department_name
ORDER BY num_employees DESC
LIMIT 10;


-- ============================================================
-- VIEW 3: Integrated View (Both Systems Combined)
-- Description: Shows veterinarians who are also employees,
--   combining data from both VetCare and HR systems.
--   This view demonstrates the integration by joining
--   Veterinarian with Employee through the new employee_id FK.
-- ============================================================

CREATE OR REPLACE VIEW vet_staff_integrated_view AS
SELECT
    v.VetID,
    v.FirstName         AS vet_first_name,
    v.LastName          AS vet_last_name,
    v.LicenseNumber,
    v.Specialization,
    v.HireDate          AS vet_hire_date,
    e.employee_id,
    e.phone_number      AS employee_phone,
    d.dept_name         AS hr_department,
    r.role_title        AS hr_role,
    ec.salary           AS employee_salary,
    ec.start_date       AS contract_start,
    (SELECT COUNT(*)
     FROM MedicalVisit mv
     WHERE mv.VetID = v.VetID
    ) AS total_visits
FROM Veterinarian v
LEFT JOIN Employee e            ON v.employee_id = e.employee_id
LEFT JOIN Department d          ON e.department_id = d.department_id
LEFT JOIN Role r                ON e.role_id = r.role_id
LEFT JOIN Employee_Contract ec  ON e.contract_id = ec.contract_id;


-- ============================================================
-- Query 3.1 on vet_staff_integrated_view:
-- Veterinarians with their HR salary and visit count
-- ============================================================
-- Description: This query shows the veterinarians that are
-- linked to the HR system, along with their salary and the
-- number of medical visits they performed. Useful for
-- evaluating vet productivity vs compensation.

SELECT
    vet_first_name || ' ' || vet_last_name AS vet_name,
    Specialization,
    LicenseNumber,
    hr_department,
    hr_role,
    employee_salary,
    total_visits
FROM vet_staff_integrated_view
WHERE employee_id IS NOT NULL
ORDER BY total_visits DESC;


-- ============================================================
-- Query 3.2 on vet_staff_integrated_view:
-- All vets with their HR status (linked or not)
-- ============================================================
-- Description: This query shows all veterinarians and whether
-- they have been linked to an employee record in the HR system.
-- Helps identify vets that still need to be integrated.

SELECT
    vet_first_name || ' ' || vet_last_name AS vet_name,
    Specialization,
    vet_hire_date,
    CASE
        WHEN employee_id IS NOT NULL THEN 'Linked to HR'
        ELSE 'Not yet linked'
    END AS hr_status,
    COALESCE(employee_salary::TEXT, 'N/A') AS salary_info,
    COALESCE(hr_department, 'N/A')         AS department_info,
    total_visits
FROM vet_staff_integrated_view
ORDER BY hr_status, vet_name;
