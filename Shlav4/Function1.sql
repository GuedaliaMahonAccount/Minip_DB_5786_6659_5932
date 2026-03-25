-- ============================================================
-- File: Function1.sql
-- Stage 4: Function 1 – fn_get_animal_medical_summary
-- Description: Returns a comprehensive medical summary for a
--              given animal: total visits, total cost, average
--              cost, last visit date, and a health status label.
--
-- Technical Elements Used:
--   ► Explicit Cursor (cur_visits)
--   ► %ROWTYPE record variable
--   ► IF / ELSIF / ELSE branching
--   ► FOR loop (iterating over cursor)
--   ► Exception Handling (EXCEPTION block)
--   ► Returns composite scalar values via OUT parameters
--
-- Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
-- ============================================================

-- Drop function if it already exists (for re-runnability)
DROP FUNCTION IF EXISTS fn_get_animal_medical_summary(INT);

CREATE OR REPLACE FUNCTION fn_get_animal_medical_summary(
    p_animal_id     INT,            -- Input: the animal to look up
    OUT o_animal_name   VARCHAR,    -- Output: animal's name
    OUT o_species       VARCHAR,    -- Output: animal's species
    OUT o_total_visits  INT,        -- Output: number of visits
    OUT o_total_cost    NUMERIC,    -- Output: sum of all visit costs
    OUT o_avg_cost      NUMERIC,    -- Output: average visit cost
    OUT o_last_visit    DATE,       -- Output: date of most recent visit
    OUT o_health_status VARCHAR     -- Output: health status label
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    -- ===================================================
    -- EXPLICIT CURSOR: fetches all visits for the animal
    -- Ordered by date descending so we can grab the latest
    -- ===================================================
    cur_visits CURSOR FOR
        SELECT mv.VisitID, mv.VisitDate, mv.Cost, mv.Reason, mv.status
        FROM MedicalVisit mv
        WHERE mv.AnimalID = p_animal_id
        ORDER BY mv.VisitDate DESC;

    -- %ROWTYPE record to hold each row fetched from cursor
    v_visit_rec  MedicalVisit%ROWTYPE;

    -- Accumulators
    v_count      INT := 0;
    v_sum_cost   NUMERIC := 0;
    v_latest     DATE;

    -- Variable for animal existence check
    v_animal_rec Animal%ROWTYPE;

BEGIN
    -- ===================================================
    -- Step 1: Validate that the animal exists
    -- Uses implicit query into %ROWTYPE record
    -- ===================================================
    BEGIN
        SELECT * INTO STRICT v_animal_rec
        FROM Animal
        WHERE AnimalID = p_animal_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE EXCEPTION 'Animal with ID % does not exist.', p_animal_id;
    END;

    -- Store basic animal info in output parameters
    o_animal_name := v_animal_rec.Name;
    o_species     := v_animal_rec.Species;

    -- ===================================================
    -- Step 2: Iterate through visits using EXPLICIT CURSOR
    -- Uses a FOR loop over the cursor
    -- ===================================================
    FOR v_rec IN cur_visits LOOP
        v_count := v_count + 1;

        -- Accumulate cost (handle NULLs)
        IF v_rec.Cost IS NOT NULL THEN
            v_sum_cost := v_sum_cost + v_rec.Cost;
        END IF;

        -- Capture the latest visit date (first row since ORDER BY DESC)
        IF v_count = 1 THEN
            v_latest := v_rec.VisitDate;
        END IF;
    END LOOP;

    -- ===================================================
    -- Step 3: Calculate results and set output parameters
    -- ===================================================
    o_total_visits := v_count;
    o_total_cost   := v_sum_cost;
    o_last_visit   := v_latest;

    -- Calculate average (avoid division by zero)
    IF v_count > 0 THEN
        o_avg_cost := ROUND(v_sum_cost / v_count, 2);
    ELSE
        o_avg_cost := 0;
    END IF;

    -- ===================================================
    -- Step 4: Determine health status using IF/ELSIF/ELSE
    -- Based on how frequently the animal visits the clinic
    -- ===================================================
    IF v_count = 0 THEN
        o_health_status := 'No Records';
    ELSIF v_count <= 5 THEN
        o_health_status := 'Healthy';
    ELSIF v_count <= 15 THEN
        o_health_status := 'Regular Patient';
    ELSIF v_count <= 30 THEN
        o_health_status := 'Frequent Visitor';
    ELSE
        o_health_status := 'Critical - Needs Attention';
    END IF;

    -- Log success
    RAISE NOTICE 'Summary generated for animal: % (ID: %)', o_animal_name, p_animal_id;

EXCEPTION
    -- ===================================================
    -- EXCEPTION HANDLING: Catches any unexpected error
    -- ===================================================
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in fn_get_animal_medical_summary: % - %', SQLSTATE, SQLERRM;
        -- Re-raise so caller knows something went wrong
        RAISE;
END;
$$;

-- ============================================================
-- Quick test: Call the function for AnimalID = 1
-- ============================================================
SELECT * FROM fn_get_animal_medical_summary(1);
