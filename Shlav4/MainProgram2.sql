-- ============================================================
-- File: MainProgram2.sql
-- Stage 4: Main Program 2 – Integration Demo
-- Description: Anonymous DO block that demonstrates integration
--              by calling Function2 (fn_get_vet_visits_report
--              with REF CURSOR) and Procedure2
--              (sp_cleanup_expired_medications).
--
-- Technical Elements Used:
--   ► Anonymous DO block
--   ► Calling a Function that returns a REFCURSOR
--   ► FETCH from REF CURSOR in a WHILE loop
--   ► Calling a Procedure with CALL
--   ► RECORD variable
--   ► IF / ELSE branching
--   ► Exception Handling (EXCEPTION block)
--   ► RAISE NOTICE for output
--
-- Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
-- ============================================================

DO $$
DECLARE
    -- REF CURSOR returned by Function2
    v_cursor      REFCURSOR;

    -- RECORD for fetching from cursor
    v_rec         RECORD;

    -- Counters and variables
    v_row_count   INT := 0;
    v_total_cost  NUMERIC := 0;
    v_max_cost    NUMERIC := 0;
    v_vet_id      INT := 2;        -- Vet to generate report for
    v_start_date  DATE := '2023-01-01';
    v_end_date    DATE := '2024-12-31';

    -- Variables for cleanup summary
    v_expired_before  INT;
    v_expired_after   INT;
    v_archived_count  INT;

BEGIN
    RAISE NOTICE '╔══════════════════════════════════════════════════╗';
    RAISE NOTICE '║  MAIN PROGRAM 2: Vet Report & Medication Cleanup║';
    RAISE NOTICE '╚══════════════════════════════════════════════════╝';
    RAISE NOTICE '';

    -- ===================================================
    -- PART A: Call Function2 (REF CURSOR report)
    -- Fetch and display results from the cursor
    -- ===================================================
    RAISE NOTICE '═══ PART A: Vet Visits Report (REF CURSOR) ═══';
    RAISE NOTICE 'Generating report for Vet #% (% to %)',
        v_vet_id, v_start_date, v_end_date;
    RAISE NOTICE '';

    -- Call the function – returns a REFCURSOR
    v_cursor := fn_get_vet_visits_report(v_vet_id, v_start_date, v_end_date);

    -- ===================================================
    -- WHILE loop: FETCH from REF CURSOR row by row
    -- ===================================================
    RAISE NOTICE '┌──────┬────────────────┬────────────────┬────────────┬──────────┐';
    RAISE NOTICE '│ Row# │ Animal         │ Species        │ Date       │ Cost     │';
    RAISE NOTICE '├──────┼────────────────┼────────────────┼────────────┼──────────┤';

    LOOP
        -- FETCH the next row from the REF CURSOR
        FETCH v_cursor INTO v_rec;

        -- EXIT when no more rows
        EXIT WHEN NOT FOUND;

        v_row_count := v_row_count + 1;

        -- Accumulate totals
        IF v_rec.Cost IS NOT NULL THEN
            v_total_cost := v_total_cost + v_rec.Cost;
            IF v_rec.Cost > v_max_cost THEN
                v_max_cost := v_rec.Cost;
            END IF;
        END IF;

        -- Display first 15 rows for readability
        IF v_row_count <= 15 THEN
            RAISE NOTICE '│ %   │ % │ % │ % │ ₪%  │',
                LPAD(v_row_count::TEXT, 3),
                RPAD(COALESCE(v_rec.animal_name, 'N/A'), 14),
                RPAD(COALESCE(v_rec.animal_species, 'N/A'), 14),
                v_rec.VisitDate,
                LPAD(COALESCE(v_rec.Cost::TEXT, 'N/A'), 7);
        END IF;
    END LOOP;

    -- Close the cursor
    CLOSE v_cursor;

    RAISE NOTICE '└──────┴────────────────┴────────────────┴────────────┴──────────┘';
    RAISE NOTICE '';

    -- Summary with IF/ELSE
    IF v_row_count = 0 THEN
        RAISE NOTICE 'No visits found for the specified criteria.';
    ELSE
        RAISE NOTICE 'Report Summary:';
        RAISE NOTICE '  Total visits:    %', v_row_count;
        RAISE NOTICE '  Total revenue:   ₪%', ROUND(v_total_cost, 2);
        RAISE NOTICE '  Average cost:    ₪%', ROUND(v_total_cost / v_row_count, 2);
        RAISE NOTICE '  Highest cost:    ₪%', v_max_cost;
    END IF;

    -- ===================================================
    -- PART B: Call Procedure2 (Expired Medication Cleanup)
    -- ===================================================
    RAISE NOTICE '';
    RAISE NOTICE '═══ PART B: Expired Medication Cleanup ═══';
    RAISE NOTICE '';

    -- Count expired medications before cleanup
    SELECT COUNT(*) INTO v_expired_before
    FROM Medication
    WHERE ExpirationDate < CURRENT_DATE;

    SELECT COUNT(*) INTO v_archived_count
    FROM expired_medications_archive;

    RAISE NOTICE 'Before cleanup:';
    RAISE NOTICE '  Expired medications in DB:    %', v_expired_before;
    RAISE NOTICE '  Already archived:             %', v_archived_count;
    RAISE NOTICE '';

    -- Call the cleanup procedure
    CALL sp_cleanup_expired_medications(CURRENT_DATE);

    -- Count after cleanup
    SELECT COUNT(*) INTO v_expired_after
    FROM Medication
    WHERE ExpirationDate < CURRENT_DATE;

    SELECT COUNT(*) INTO v_archived_count
    FROM expired_medications_archive;

    RAISE NOTICE '';
    RAISE NOTICE 'After cleanup:';
    RAISE NOTICE '  Expired medications in DB:    %', v_expired_after;
    RAISE NOTICE '  Total in archive:             %', v_archived_count;
    RAISE NOTICE '  Medications cleaned up:       %', v_expired_before - v_expired_after;

    RAISE NOTICE '';
    RAISE NOTICE '╔══════════════════════════════════════════════════╗';
    RAISE NOTICE '║  MAIN PROGRAM 2 COMPLETED SUCCESSFULLY         ║';
    RAISE NOTICE '╚══════════════════════════════════════════════════╝';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '╔══════════════════════════════════════════════════╗';
        RAISE NOTICE '║  MAIN PROGRAM 2 FAILED                         ║';
        RAISE NOTICE '║  Error: [%] %', SQLSTATE, SQLERRM;
        RAISE NOTICE '╚══════════════════════════════════════════════════╝';
END;
$$;
