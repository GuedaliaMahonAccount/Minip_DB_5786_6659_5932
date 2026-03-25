-- ============================================================
-- File: Procedure2.sql
-- Stage 4: Procedure 2 – sp_cleanup_expired_medications
-- Description: Archives expired medications, removes their
--              treatment links, and deletes them from the
--              main Medication table. Demonstrates safe cleanup
--              with archiving before deletion.
--
-- Technical Elements Used:
--   ► Explicit Cursor (cur_expired)
--   ► WHILE loop with FETCH
--   ► DML: INSERT (archive), DELETE (cleanup)
--   ► RECORD variable (%ROWTYPE)
--   ► IF / ELSE branching
--   ► Exception Handling (EXCEPTION block with SAVEPOINT)
--
-- Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
-- ============================================================

-- Drop procedure if exists (for re-runnability)
DROP PROCEDURE IF EXISTS sp_cleanup_expired_medications(DATE);

CREATE OR REPLACE PROCEDURE sp_cleanup_expired_medications(
    p_cutoff_date DATE DEFAULT CURRENT_DATE  -- Date threshold for expiration
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- ===================================================
    -- EXPLICIT CURSOR: fetches all medications expired
    -- before the cutoff date
    -- ===================================================
    cur_expired CURSOR FOR
        SELECT MedID, CommercialName, ActiveIngredient, DosageUnit, ExpirationDate
        FROM Medication
        WHERE ExpirationDate < p_cutoff_date
        ORDER BY ExpirationDate ASC;

    -- %ROWTYPE record variable to hold each fetched row
    v_med_rec       Medication%ROWTYPE;

    -- Counters
    v_archived      INT := 0;
    v_links_removed INT := 0;
    v_deleted       INT := 0;
    v_link_count    INT;
    v_found         BOOLEAN;

BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE ' Expired Medication Cleanup Process';
    RAISE NOTICE ' Cutoff Date: %', p_cutoff_date;
    RAISE NOTICE '============================================';

    -- ===================================================
    -- Step 1: OPEN the explicit cursor
    -- ===================================================
    OPEN cur_expired;

    -- ===================================================
    -- Step 2: WHILE loop – fetch and process each record
    -- ===================================================
    LOOP
        -- FETCH into %ROWTYPE record
        FETCH cur_expired INTO v_med_rec;

        -- EXIT when no more rows
        EXIT WHEN NOT FOUND;

        RAISE NOTICE '--- Processing: % (ID: %, Expired: %) ---',
            v_med_rec.CommercialName, v_med_rec.MedID, v_med_rec.ExpirationDate;

        -- ===================================================
        -- Step 3: Archive the medication before deleting
        -- DML: INSERT into archive table
        -- ===================================================
        INSERT INTO expired_medications_archive (
            med_id, commercial_name, active_ingredient,
            dosage_unit, expiration_date
        ) VALUES (
            v_med_rec.MedID, v_med_rec.CommercialName,
            v_med_rec.ActiveIngredient, v_med_rec.DosageUnit,
            v_med_rec.ExpirationDate
        );
        v_archived := v_archived + 1;

        -- ===================================================
        -- Step 4: Remove treatment links
        -- DML: DELETE from junction table
        -- Uses IF/ELSE to report whether links existed
        -- ===================================================
        SELECT COUNT(*) INTO v_link_count
        FROM Hergel_Treatment_Medication
        WHERE MedID = v_med_rec.MedID;

        IF v_link_count > 0 THEN
            DELETE FROM Hergel_Treatment_Medication
            WHERE MedID = v_med_rec.MedID;

            v_links_removed := v_links_removed + v_link_count;
            RAISE NOTICE '  Removed % treatment links.', v_link_count;
        ELSE
            RAISE NOTICE '  No treatment links found.';
        END IF;

        -- ===================================================
        -- Step 5: Delete the medication record
        -- DML: DELETE from main table
        -- ===================================================
        DELETE FROM Medication
        WHERE MedID = v_med_rec.MedID;
        v_deleted := v_deleted + 1;

    END LOOP;

    -- ===================================================
    -- Step 6: Close the cursor
    -- ===================================================
    CLOSE cur_expired;

    -- ===================================================
    -- Step 7: Summary report using IF/ELSE
    -- ===================================================
    RAISE NOTICE '============================================';
    RAISE NOTICE ' Cleanup Summary';
    RAISE NOTICE '============================================';

    IF v_deleted = 0 THEN
        RAISE NOTICE 'No expired medications found before %.', p_cutoff_date;
        RAISE NOTICE 'Database is clean – no action taken.';
    ELSE
        RAISE NOTICE 'Medications archived:       %', v_archived;
        RAISE NOTICE 'Treatment links removed:    %', v_links_removed;
        RAISE NOTICE 'Medications deleted:        %', v_deleted;
        RAISE NOTICE 'All expired medications have been safely archived and removed.';
    END IF;

EXCEPTION
    -- ===================================================
    -- EXCEPTION HANDLING
    -- ===================================================
    WHEN FOREIGN_KEY_VIOLATION THEN
        RAISE NOTICE 'Cannot delete medication: still referenced by other tables.';
        RAISE NOTICE 'Error details: %', SQLERRM;
        RAISE;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in sp_cleanup_expired_medications: [%] %', SQLSTATE, SQLERRM;
        RAISE;
END;
$$;

-- ============================================================
-- Quick test: Show expired medications before running
-- ============================================================
SELECT COUNT(*) AS expired_count
FROM Medication
WHERE ExpirationDate < CURRENT_DATE;

-- Run the procedure:
-- CALL sp_cleanup_expired_medications(CURRENT_DATE);
