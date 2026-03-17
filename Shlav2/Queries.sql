-- ============================================================
-- File: Queries.sql
-- Phase 2 – Selection & Modification Queries
-- Database: VetCare Management System (basnat)
-- ============================================================

-- ************************************************************
-- SECTION A: 4 "DOUBLE" SELECT QUERIES (2 versions each)
-- ************************************************************

-- ============================================================
-- DOUBLE QUERY 1 – Animals with the most expensive average visit cost per species
-- Goal: For each species, find the animal whose average visit cost is the highest.
--       Display the animal name, species, average cost, and number of visits.
-- ============================================================

-- VERSION A: Using a JOIN with a derived subquery (inline view)
-- Strategy: We pre-compute the max average cost per species in a subquery,
--           then JOIN to filter only the animals matching that max.
SELECT 
    a.AnimalID,
    a.Name              AS AnimalName,
    a.Species,
    ROUND(AVG(mv.Cost), 2)          AS AvgVisitCost,
    COUNT(mv.VisitID)               AS TotalVisits,
    EXTRACT(YEAR FROM a.BirthDate)  AS BirthYear
FROM Animal a
JOIN MedicalVisit mv ON a.AnimalID = mv.AnimalID
GROUP BY a.AnimalID, a.Name, a.Species, a.BirthDate
HAVING AVG(mv.Cost) = (
    SELECT MAX(sub.avg_cost)
    FROM (
        SELECT a2.Species AS sp, a2.AnimalID, AVG(mv2.Cost) AS avg_cost
        FROM Animal a2
        JOIN MedicalVisit mv2 ON a2.AnimalID = mv2.AnimalID
        GROUP BY a2.Species, a2.AnimalID
    ) sub
    WHERE sub.sp = a.Species
)
ORDER BY a.Species;

-- VERSION B: Using a CTE (Common Table Expression) + Window Function RANK()
-- Strategy: We compute rank of each animal within its species partition
--           based on average cost, then filter rank = 1.
WITH AnimalAvgCost AS (
    SELECT 
        a.AnimalID,
        a.Name              AS AnimalName,
        a.Species,
        ROUND(AVG(mv.Cost), 2)          AS AvgVisitCost,
        COUNT(mv.VisitID)               AS TotalVisits,
        EXTRACT(YEAR FROM a.BirthDate)  AS BirthYear,
        RANK() OVER (
            PARTITION BY a.Species 
            ORDER BY AVG(mv.Cost) DESC
        ) AS CostRank
    FROM Animal a
    JOIN MedicalVisit mv ON a.AnimalID = mv.AnimalID
    GROUP BY a.AnimalID, a.Name, a.Species, a.BirthDate
)
SELECT AnimalID, AnimalName, Species, AvgVisitCost, TotalVisits, BirthYear
FROM AnimalAvgCost
WHERE CostRank = 1
ORDER BY Species;

/*
  EFFICIENCY ANALYSIS – Query 1:
  ──────────────────────────────
  VERSION A (Correlated Subquery in HAVING):
  • The inner subquery is CORRELATED: it is re-executed for EACH species group.
  • Complexity: O(S × N) where S = number of species, N = number of animals.
  • PostgreSQL may partially optimize this, but the repeated scanning is inherently
    less efficient.

  VERSION B (CTE + Window Function):
  • The RANK() window function computes all ranks in a SINGLE PASS over the
    already-aggregated data. No repeated scanning.
  • Complexity: O(N log N) for the window sort, executed once.
  • PostgreSQL materializes the CTE and the window function uses an efficient
    sort-based algorithm.

  ✅ WINNER: VERSION B – The window function approach is more efficient because
  it avoids the correlated subquery entirely. It scans the data once, computes
  the aggregation, then performs a single-pass ranking. This is both faster and
  more readable.
*/

-- ============================================================
-- DOUBLE QUERY 2 – Veterinarians who treated more than 30 animals in 2024
-- Goal: Find vets with heavy workload in the year 2024, showing their
--       full name, specialization, total visits, and total revenue generated.
-- ============================================================

-- VERSION A: Using IN with a subquery
SELECT 
    v.VetID,
    v.FirstName || ' ' || v.LastName    AS VetFullName,
    v.Specialization,
    COUNT(mv.VisitID)                   AS VisitsIn2024,
    ROUND(SUM(mv.Cost), 2)             AS TotalRevenue,
    EXTRACT(YEAR FROM v.HireDate)       AS HireYear
FROM Veterinarian v
JOIN MedicalVisit mv ON v.VetID = mv.VetID
WHERE EXTRACT(YEAR FROM mv.VisitDate) = 2024
  AND v.VetID IN (
      SELECT mv2.VetID
      FROM MedicalVisit mv2
      WHERE EXTRACT(YEAR FROM mv2.VisitDate) = 2024
      GROUP BY mv2.VetID
      HAVING COUNT(DISTINCT mv2.AnimalID) > 30
  )
GROUP BY v.VetID, v.FirstName, v.LastName, v.Specialization, v.HireDate
ORDER BY VisitsIn2024 DESC;

-- VERSION B: Using EXISTS with a correlated subquery
SELECT 
    v.VetID,
    v.FirstName || ' ' || v.LastName    AS VetFullName,
    v.Specialization,
    COUNT(mv.VisitID)                   AS VisitsIn2024,
    ROUND(SUM(mv.Cost), 2)             AS TotalRevenue,
    EXTRACT(YEAR FROM v.HireDate)       AS HireYear
FROM Veterinarian v
JOIN MedicalVisit mv ON v.VetID = mv.VetID
WHERE EXTRACT(YEAR FROM mv.VisitDate) = 2024
  AND EXISTS (
      SELECT 1
      FROM MedicalVisit mv2
      WHERE mv2.VetID = v.VetID
        AND EXTRACT(YEAR FROM mv2.VisitDate) = 2024
      GROUP BY mv2.VetID
      HAVING COUNT(DISTINCT mv2.AnimalID) > 30
  )
GROUP BY v.VetID, v.FirstName, v.LastName, v.Specialization, v.HireDate
ORDER BY VisitsIn2024 DESC;

/*
  EFFICIENCY ANALYSIS – Query 2:
  ──────────────────────────────
  VERSION A (IN + Subquery):
  • The IN subquery is UNCORRELATED: it executes ONCE, producing a list of VetIDs.
  • PostgreSQL converts IN(...) into a hash semi-join internally.
  • Very efficient when the result set of the subquery is small relative to the
    outer table.

  VERSION B (EXISTS + Correlated Subquery):
  • The EXISTS subquery is CORRELATED: it is evaluated for each row of the outer
    query (each vet). PostgreSQL can short-circuit (stop at the first match),
    but the GROUP BY + HAVING inside makes this less effective.
  • Each correlated execution requires a full scan and aggregation of MedicalVisit
    for that specific VetID.

  ✅ WINNER: VERSION A – The IN approach is more efficient here because:
  1. The subquery executes only ONCE and produces a small set of VetIDs.
  2. PostgreSQL uses a Hash Semi-Join to match, which is O(1) per lookup.
  3. The EXISTS version must repeatedly aggregate data per vet, making it O(V × M)
     where V = number of vets and M = visits per vet.
*/

-- ============================================================
-- DOUBLE QUERY 3 – Animals that have NEVER received a "Critical" severity treatment
-- Goal: Find all animals that were treated but never assigned a Critical treatment.
-- ============================================================

-- VERSION A: Using NOT IN
SELECT 
    a.AnimalID,
    a.Name          AS AnimalName,
    a.Species,
    a.Gender,
    a.Weight,
    EXTRACT(YEAR FROM AGE(a.BirthDate)) AS AgeInYears
FROM Animal a
WHERE a.AnimalID NOT IN (
    SELECT DISTINCT mv.AnimalID
    FROM MedicalVisit mv
    JOIN Mirsham_Visit_Treatment mvt ON mv.VisitID = mvt.VisitID
    JOIN Treatment t ON mvt.TreatmentID = t.TreatmentID
    WHERE t.Severity = 'Critical'
)
AND a.AnimalID IN (
    SELECT mv.AnimalID FROM MedicalVisit mv
)
ORDER BY a.Species, a.Name;

-- VERSION B: Using NOT EXISTS
SELECT 
    a.AnimalID,
    a.Name          AS AnimalName,
    a.Species,
    a.Gender,
    a.Weight,
    EXTRACT(YEAR FROM AGE(a.BirthDate)) AS AgeInYears
FROM Animal a
WHERE NOT EXISTS (
    SELECT 1
    FROM MedicalVisit mv
    JOIN Mirsham_Visit_Treatment mvt ON mv.VisitID = mvt.VisitID
    JOIN Treatment t ON mvt.TreatmentID = t.TreatmentID
    WHERE t.Severity = 'Critical'
      AND mv.AnimalID = a.AnimalID
)
AND EXISTS (
    SELECT 1 FROM MedicalVisit mv WHERE mv.AnimalID = a.AnimalID
)
ORDER BY a.Species, a.Name;

/*
  EFFICIENCY ANALYSIS – Query 3:
  ──────────────────────────────
  VERSION A (NOT IN):
  • The subquery is UNCORRELATED and produces a full list of AnimalIDs.
  • ⚠️ CRITICAL RISK: If ANY AnimalID in the subquery result is NULL, NOT IN
    returns no rows at all (SQL three-valued logic). This is a known pitfall.
  • PostgreSQL evaluates NOT IN as an Anti-Join, but must first materialize
    the entire subquery result set.

  VERSION B (NOT EXISTS):
  • The subquery is CORRELATED, but PostgreSQL optimizes EXISTS/NOT EXISTS
    with an Anti Semi-Join that short-circuits on the first match.
  • ✅ NULL-SAFE: NOT EXISTS correctly handles NULLs because it checks row
    existence, not value equality.
  • With an index on MedicalVisit(AnimalID), each probe is O(log N).

  ✅ WINNER: VERSION B – NOT EXISTS is superior for two reasons:
  1. NULL SAFETY: It avoids the dangerous NOT IN + NULL trap.
  2. SHORT-CIRCUIT: PostgreSQL stops scanning as soon as it finds one matching
     row, whereas NOT IN must materialize the entire set.
  3. Plan: PostgreSQL typically uses an Anti Join plan for NOT EXISTS which
     is highly optimized with Hash or Merge strategies.
*/

-- ============================================================
-- DOUBLE QUERY 4 – Monthly revenue breakdown by veterinarian specialization (2024)
-- Goal: Show per month, per specialization, the total revenue and visit count.
-- ============================================================

-- VERSION A: Using a subquery in FROM (derived table)
SELECT 
    monthly.VisitMonth,
    monthly.Specialization,
    monthly.TotalRevenue,
    monthly.VisitCount,
    monthly.AvgCostPerVisit
FROM (
    SELECT 
        EXTRACT(MONTH FROM mv.VisitDate)    AS VisitMonth,
        v.Specialization,
        ROUND(SUM(mv.Cost), 2)              AS TotalRevenue,
        COUNT(mv.VisitID)                   AS VisitCount,
        ROUND(AVG(mv.Cost), 2)              AS AvgCostPerVisit
    FROM MedicalVisit mv
    JOIN Veterinarian v ON mv.VetID = v.VetID
    WHERE EXTRACT(YEAR FROM mv.VisitDate) = 2024
    GROUP BY EXTRACT(MONTH FROM mv.VisitDate), v.Specialization
) monthly
ORDER BY monthly.VisitMonth, monthly.TotalRevenue DESC;

-- VERSION B: Using a CTE (WITH clause)
WITH MonthlyRevenue AS (
    SELECT 
        EXTRACT(MONTH FROM mv.VisitDate)    AS VisitMonth,
        v.Specialization,
        ROUND(SUM(mv.Cost), 2)              AS TotalRevenue,
        COUNT(mv.VisitID)                   AS VisitCount,
        ROUND(AVG(mv.Cost), 2)              AS AvgCostPerVisit
    FROM MedicalVisit mv
    JOIN Veterinarian v ON mv.VetID = v.VetID
    WHERE EXTRACT(YEAR FROM mv.VisitDate) = 2024
    GROUP BY EXTRACT(MONTH FROM mv.VisitDate), v.Specialization
)
SELECT VisitMonth, Specialization, TotalRevenue, VisitCount, AvgCostPerVisit
FROM MonthlyRevenue
ORDER BY VisitMonth, TotalRevenue DESC;

/*
  EFFICIENCY ANALYSIS – Query 4:
  ──────────────────────────────
  VERSION A (Derived Table / Inline View):
  • The subquery in the FROM clause creates a temporary result set.
  • PostgreSQL can "inline" the subquery: it merges the subquery plan into
    the outer query, optimizing as if it were a single query.
  • No materialization overhead if the optimizer decides to inline.

  VERSION B (CTE / WITH clause):
  • In PostgreSQL 12+, CTEs can also be inlined (the "optimization fence"
    was removed). So performance is IDENTICAL in modern PostgreSQL.
  • In PostgreSQL 11 and below, CTEs were ALWAYS materialized (stored in
    memory/disk as a temp table), adding overhead.
  • CTEs are more READABLE and REUSABLE: if we need the same intermediate
    result multiple times, we write it once.

  ✅ VERDICT: TIE (PostgreSQL 12+) – Both produce the same execution plan.
  The CTE version wins on READABILITY and MAINTAINABILITY.
  In older PostgreSQL (< 12), VERSION A wins because the derived table
  is always inlined, whereas the CTE would be needlessly materialized.
*/


-- ************************************************************
-- SECTION B: 4 "SIMPLE" SELECT QUERIES
-- ************************************************************

-- ============================================================
-- SIMPLE QUERY 1 – Top 10 most visited animals with full medical profile
-- Goal: Show the animals with the most visits, including their latest visit
--       date, total cost spent, and average cost per visit.
-- ============================================================
SELECT 
    a.AnimalID,
    a.Name                              AS AnimalName,
    a.Species,
    a.Gender,
    a.Weight                            AS WeightKg,
    EXTRACT(YEAR FROM AGE(a.BirthDate)) AS AgeInYears,
    COUNT(mv.VisitID)                   AS TotalVisits,
    MAX(mv.VisitDate)                   AS LastVisitDate,
    ROUND(SUM(mv.Cost), 2)             AS TotalCostSpent,
    ROUND(AVG(mv.Cost), 2)             AS AvgCostPerVisit
FROM Animal a
JOIN MedicalVisit mv ON a.AnimalID = mv.AnimalID
GROUP BY a.AnimalID, a.Name, a.Species, a.Gender, a.Weight, a.BirthDate
ORDER BY TotalVisits DESC
LIMIT 10;

-- ============================================================
-- SIMPLE QUERY 2 – Treatments breakdown by severity with medication count
-- Goal: For each treatment, show its severity, how many visits used it,
--       and how many distinct medications are associated with it.
-- ============================================================
SELECT 
    t.TreatmentID,
    t.Description       AS TreatmentDesc,
    t.Type              AS TreatmentType,
    t.Severity,
    t.Duration,
    COUNT(DISTINCT mvt.VisitID)     AS TimesUsedInVisits,
    COUNT(DISTINCT htm.MedID)       AS DistinctMedications
FROM Treatment t
LEFT JOIN Mirsham_Visit_Treatment mvt ON t.TreatmentID = mvt.TreatmentID
LEFT JOIN Hergel_Treatment_Medication htm ON t.TreatmentID = htm.TreatmentID
GROUP BY t.TreatmentID, t.Description, t.Type, t.Severity, t.Duration
HAVING COUNT(DISTINCT mvt.VisitID) > 0
ORDER BY TimesUsedInVisits DESC, t.Severity
LIMIT 20;

-- ============================================================
-- SIMPLE QUERY 3 – Expired medications still linked to active treatments
-- Goal: Find medications that have expired but are still associated
--       with treatments that were used in visits after the expiration date.
-- ============================================================
SELECT 
    m.MedID,
    m.CommercialName,
    m.ActiveIngredient,
    m.DosageUnit,
    m.ExpirationDate,
    t.TreatmentID,
    t.Description       AS TreatmentDesc,
    t.Severity,
    MAX(mv.VisitDate)   AS LatestVisitUsingExpiredMed
FROM Medication m
JOIN Hergel_Treatment_Medication htm ON m.MedID = htm.MedID
JOIN Treatment t ON htm.TreatmentID = t.TreatmentID
JOIN Mirsham_Visit_Treatment mvt ON t.TreatmentID = mvt.TreatmentID
JOIN MedicalVisit mv ON mvt.VisitID = mv.VisitID
WHERE m.ExpirationDate < CURRENT_DATE
  AND mv.VisitDate > m.ExpirationDate
GROUP BY m.MedID, m.CommercialName, m.ActiveIngredient, m.DosageUnit,
         m.ExpirationDate, t.TreatmentID, t.Description, t.Severity
ORDER BY m.ExpirationDate ASC
LIMIT 15;

-- ============================================================
-- SIMPLE QUERY 4 – Quarterly visit summary with year-over-year comparison
-- Goal: Show the number of visits and revenue per quarter per year,
--       providing a high-level business overview.
-- ============================================================
SELECT 
    EXTRACT(YEAR FROM mv.VisitDate)                AS VisitYear,
    EXTRACT(QUARTER FROM mv.VisitDate)             AS VisitQuarter,
    COUNT(mv.VisitID)                              AS TotalVisits,
    COUNT(DISTINCT mv.AnimalID)                    AS UniqueAnimals,
    COUNT(DISTINCT mv.VetID)                       AS ActiveVets,
    ROUND(SUM(mv.Cost), 2)                         AS TotalRevenue,
    ROUND(AVG(mv.Cost), 2)                         AS AvgCostPerVisit,
    ROUND(MAX(mv.Cost), 2)                         AS MaxVisitCost,
    ROUND(MIN(mv.Cost), 2)                         AS MinVisitCost
FROM MedicalVisit mv
GROUP BY EXTRACT(YEAR FROM mv.VisitDate), EXTRACT(QUARTER FROM mv.VisitDate)
ORDER BY VisitYear, VisitQuarter;


-- ************************************************************
-- SECTION C: 3 DELETE QUERIES
-- ************************************************************

-- ============================================================
-- DELETE 1 – Remove all medical visits older than 18 months
--            that had a cost below 100 (low-value old records cleanup)
-- ============================================================
DELETE FROM MedicalVisit
WHERE VisitDate < CURRENT_DATE - INTERVAL '18 months'
  AND Cost < 100
  AND VisitID NOT IN (
      SELECT mvt.VisitID FROM Mirsham_Visit_Treatment mvt
      JOIN Treatment t ON mvt.TreatmentID = t.TreatmentID
      WHERE t.Severity = 'Critical'
  );

-- ============================================================
-- DELETE 2 – Remove treatments that have never been used in any visit
--            and have no associated medication (orphan records)
-- ============================================================
DELETE FROM Treatment
WHERE TreatmentID NOT IN (
    SELECT TreatmentID FROM Mirsham_Visit_Treatment
)
AND TreatmentID NOT IN (
    SELECT TreatmentID FROM Hergel_Treatment_Medication
)
AND TreatmentID NOT IN (
    SELECT TreatmentID FROM Treatment_Vaccination
);

-- ============================================================
-- DELETE 3 – Remove expired medications that are not linked
--            to any treatment (safe cleanup of obsolete inventory)
-- ============================================================
DELETE FROM Medication
WHERE ExpirationDate < CURRENT_DATE
  AND MedID NOT IN (
      SELECT MedID FROM Hergel_Treatment_Medication
  );


-- ************************************************************
-- SECTION D: 3 UPDATE QUERIES
-- ************************************************************

-- ============================================================
-- UPDATE 1 – Apply a 15% cost increase on all visits handled by
--            veterinarians with specialization 'Surgery' in 2024
-- ============================================================
UPDATE MedicalVisit
SET Cost = ROUND(Cost * 1.15, 2)
WHERE VetID IN (
    SELECT VetID 
    FROM Veterinarian 
    WHERE Specialization = 'Surgery'
)
AND EXTRACT(YEAR FROM VisitDate) = 2024;

-- ============================================================
-- UPDATE 2 – Upgrade severity from 'Medium' to 'High' for treatments
--            that have been used in more than 50 visits
-- ============================================================
UPDATE Treatment
SET Severity = 'High'
WHERE Severity = 'Medium'
  AND TreatmentID IN (
      SELECT TreatmentID
      FROM Mirsham_Visit_Treatment
      GROUP BY TreatmentID
      HAVING COUNT(VisitID) > 50
  );

-- ============================================================
-- UPDATE 3 – Extend medication expiration by 6 months for medications
--            currently in use (linked to at least one treatment)
--            and expiring within the next 3 months
-- ============================================================
UPDATE Medication
SET ExpirationDate = ExpirationDate + INTERVAL '6 months'
WHERE ExpirationDate BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '3 months'
  AND MedID IN (
      SELECT DISTINCT MedID
      FROM Hergel_Treatment_Medication
  );
