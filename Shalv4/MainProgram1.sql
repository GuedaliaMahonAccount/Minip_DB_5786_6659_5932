-- ============================================================
-- File: MainProgram1.sql
-- Stage 4: Main Program 1 – Integration Demo
-- Description: Anonymous DO block that demonstrates integration
--              by calling Function1 (fn_get_animal_medical_summary)
--              and Procedure1 (sp_transfer_animal_visits).
--              Shows practical use of both programs together.
--
-- Technical Elements Used:
--   ► Anonymous DO block
--   ► Calling a Function with OUT parameters
--   ► Calling a Procedure with CALL
--   ► FOR loop (iterating over multiple animals)
--   ► IF / ELSIF / ELSE branching
--   ► RECORD variable
--   ► Exception Handling (EXCEPTION block)
--   ► RAISE NOTICE for output
--
-- Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
-- ============================================================

DO $$
DECLARE
    -- Record variable to hold function results
    v_summary      RECORD;

    -- Variables for transfer demo
    v_from_vet     INT := 3;   -- Source vet for transfer
    v_to_vet       INT := 4;   -- Target vet for transfer

    -- Loop counter
    v_animal_id    INT;

    -- Array of animal IDs to check
    v_animals      INT[] := ARRAY[1, 2, 3, 5, 10];

BEGIN
    RAISE NOTICE '╔══════════════════════════════════════════════════╗';
    RAISE NOTICE '║   MAIN PROGRAM 1: Medical Summary & Transfer    ║';
    RAISE NOTICE '╚══════════════════════════════════════════════════╝';
    RAISE NOTICE '';

    -- ===================================================
    -- PART A: Call Function1 for multiple animals
    -- Uses a FOR loop to iterate through the array
    -- ===================================================
    RAISE NOTICE '═══ PART A: Animal Medical Summaries ═══';
    RAISE NOTICE '';

    FOR i IN 1..array_length(v_animals, 1) LOOP
        v_animal_id := v_animals[i];

        BEGIN
            -- Call the function and capture results into RECORD
            SELECT * INTO v_summary
            FROM fn_get_animal_medical_summary(v_animal_id);

            -- Display results using IF/ELSIF/ELSE
            RAISE NOTICE '┌─────────────────────────────────────────┐';
            RAISE NOTICE '│ Animal #%: %', v_animal_id, v_summary.o_animal_name;
            RAISE NOTICE '│ Species:       %', v_summary.o_species;
            RAISE NOTICE '│ Total Visits:  %', v_summary.o_total_visits;
            RAISE NOTICE '│ Total Cost:    ₪%', v_summary.o_total_cost;
            RAISE NOTICE '│ Average Cost:  ₪%', v_summary.o_avg_cost;
            RAISE NOTICE '│ Last Visit:    %', COALESCE(v_summary.o_last_visit::TEXT, 'None');

            -- Health status with conditional formatting
            IF v_summary.o_health_status = 'Critical - Needs Attention' THEN
                RAISE NOTICE '│ ⚠ HEALTH:      % ⚠', v_summary.o_health_status;
            ELSIF v_summary.o_health_status = 'Healthy' THEN
                RAISE NOTICE '│ ✓ HEALTH:      %', v_summary.o_health_status;
            ELSE
                RAISE NOTICE '│ HEALTH:        %', v_summary.o_health_status;
            END IF;

            RAISE NOTICE '└─────────────────────────────────────────┘';
            RAISE NOTICE '';

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '  ✗ Error for Animal #%: %', v_animal_id, SQLERRM;
        END;
    END LOOP;

    -- ===================================================
    -- PART B: Call Procedure1 (Transfer visits)
    -- ===================================================
    RAISE NOTICE '';
    RAISE NOTICE '═══ PART B: Visit Transfer Operation ═══';
    RAISE NOTICE '';

    -- Show before counts
    RAISE NOTICE 'Before transfer:';
    FOR v_summary IN
        SELECT mv.VetID, COUNT(*) AS cnt
        FROM MedicalVisit mv
        WHERE mv.VetID IN (v_from_vet, v_to_vet)
        GROUP BY mv.VetID
        ORDER BY mv.VetID
    LOOP
        RAISE NOTICE '  Vet #% has % visits', v_summary.VetID, v_summary.cnt;
    END LOOP;

    -- Call the transfer procedure
    CALL sp_transfer_animal_visits(v_from_vet, v_to_vet);

    -- Show after counts
    RAISE NOTICE '';
    RAISE NOTICE 'After transfer:';
    FOR v_summary IN
        SELECT mv.VetID, COUNT(*) AS cnt
        FROM MedicalVisit mv
        WHERE mv.VetID IN (v_from_vet, v_to_vet)
        GROUP BY mv.VetID
        ORDER BY mv.VetID
    LOOP
        RAISE NOTICE '  Vet #% has % visits', v_summary.VetID, v_summary.cnt;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '╔══════════════════════════════════════════════════╗';
    RAISE NOTICE '║   MAIN PROGRAM 1 COMPLETED SUCCESSFULLY        ║';
    RAISE NOTICE '╚══════════════════════════════════════════════════╝';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '╔══════════════════════════════════════════════════╗';
        RAISE NOTICE '║   MAIN PROGRAM 1 FAILED                        ║';
        RAISE NOTICE '║   Error: [%] %', SQLSTATE, SQLERRM;
        RAISE NOTICE '╚══════════════════════════════════════════════════╝';
END;
$$;
