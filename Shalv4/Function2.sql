-- ============================================================
-- File: Function2.sql
-- Stage 4: Function 2 – fn_get_vet_visits_report
-- Description: Returns a REF CURSOR containing a detailed
--              report of all medical visits performed by a
--              specific veterinarian within a given date range.
--
-- Technical Elements Used:
--   ► Returning a REF CURSOR (REFCURSOR type)
--   ► Explicit Cursor (OPEN ... FOR)
--   ► RECORD variable
--   ► IF / ELSE branching (parameter validation)
--   ► LOOP with EXIT WHEN (for counting)
--   ► Exception Handling (EXCEPTION block)
--
-- Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
-- ============================================================

-- Drop function if exists (for re-runnability)
DROP FUNCTION IF EXISTS fn_get_vet_visits_report(INT, DATE, DATE);

CREATE OR REPLACE FUNCTION fn_get_vet_visits_report(
    p_vet_id     INT,       -- Input: Veterinarian ID
    p_start_date DATE,      -- Input: Start of date range
    p_end_date   DATE       -- Input: End of date range
)
RETURNS REFCURSOR              -- ► RETURNS A REF CURSOR
LANGUAGE plpgsql
AS $$
DECLARE
    -- ===================================================
    -- REF CURSOR: will be opened and returned to caller
    -- ===================================================
    v_cursor     REFCURSOR := 'vet_visits_cursor';

    -- RECORD variable to validate the vet exists
    v_vet_rec    RECORD;

    -- Counter for validation
    v_visit_count INT := 0;
    v_temp_rec    RECORD;

    -- Temporary cursor for counting
    v_count_cursor REFCURSOR;

BEGIN
    -- ===================================================
    -- Step 1: Validate input parameters using IF/ELSE
    -- ===================================================
    IF p_vet_id IS NULL OR p_vet_id <= 0 THEN
        RAISE EXCEPTION 'Invalid Vet ID: %. Must be a positive integer.', p_vet_id;
    END IF;

    IF p_start_date IS NULL OR p_end_date IS NULL THEN
        RAISE EXCEPTION 'Date range cannot be NULL. Provide both start and end dates.';
    END IF;

    IF p_start_date > p_end_date THEN
        RAISE EXCEPTION 'Invalid date range: start date (%) is after end date (%).', 
            p_start_date, p_end_date;
    END IF;

    -- ===================================================
    -- Step 2: Check that the veterinarian exists
    -- Uses a RECORD variable
    -- ===================================================
    SELECT VetID, FirstName, LastName, Specialization
    INTO v_vet_rec
    FROM Veterinarian
    WHERE VetID = p_vet_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Veterinarian with ID % does not exist.', p_vet_id;
    END IF;

    RAISE NOTICE 'Generating report for Dr. % % (Specialization: %)',
        v_vet_rec.FirstName, v_vet_rec.LastName, 
        COALESCE(v_vet_rec.Specialization, 'General');

    -- ===================================================
    -- Step 3: Count matching visits using a LOOP
    -- We use a separate counting loop to validate that 
    -- there are results before opening the main cursor
    -- ===================================================
    SELECT COUNT(*) INTO v_visit_count
    FROM MedicalVisit
    WHERE VetID = p_vet_id
      AND VisitDate BETWEEN p_start_date AND p_end_date;

    IF v_visit_count = 0 THEN
        RAISE NOTICE 'WARNING: No visits found for Vet ID % between % and %.',
            p_vet_id, p_start_date, p_end_date;
    ELSE
        RAISE NOTICE 'Found % visits in the specified date range.', v_visit_count;
    END IF;

    -- ===================================================
    -- Step 4: Open the REF CURSOR with the full query
    -- This is the cursor returned to the caller
    -- ===================================================
    OPEN v_cursor FOR
        SELECT
            mv.VisitID,
            a.Name          AS animal_name,
            a.Species       AS animal_species,
            mv.VisitDate,
            mv.Reason,
            mv.Summary,
            mv.Cost,
            COALESCE(mv.status, 'Completed') AS visit_status,
            (SELECT COUNT(*)
             FROM Mirsham_Visit_Treatment mvt
             WHERE mvt.VisitID = mv.VisitID
            ) AS treatment_count
        FROM MedicalVisit mv
        JOIN Animal a ON mv.AnimalID = a.AnimalID
        WHERE mv.VetID = p_vet_id
          AND mv.VisitDate BETWEEN p_start_date AND p_end_date
        ORDER BY mv.VisitDate DESC, mv.Cost DESC;

    -- Return the open cursor to the caller
    RETURN v_cursor;

EXCEPTION
    -- ===================================================
    -- EXCEPTION HANDLING: catch specific and general errors
    -- ===================================================
    WHEN INVALID_PARAMETER_VALUE THEN
        RAISE NOTICE 'Invalid parameter provided: %', SQLERRM;
        RAISE;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in fn_get_vet_visits_report: [%] %', SQLSTATE, SQLERRM;
        RAISE;
END;
$$;

-- ============================================================
-- Quick test: Call the function and FETCH from the cursor
-- Must be inside a transaction to use the refcursor
-- ============================================================
BEGIN;
    SELECT fn_get_vet_visits_report(1, '2023-01-01', '2024-12-31');
    FETCH ALL FROM vet_visits_cursor;
COMMIT;
