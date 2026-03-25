-- ============================================================
-- File: Procedure1.sql
-- Stage 4: Procedure 1 – sp_transfer_animal_visits
-- Description: Transfers all medical visits from one veterinarian
--              to another. Useful when a vet retires or is
--              reassigned. Updates visit records and logs the
--              transfer details.
--
-- Technical Elements Used:
--   ► Implicit Cursor (UPDATE ... with GET DIAGNOSTICS)
--   ► FOR loop (iterating over affected visits)
--   ► DML: UPDATE
--   ► IF / ELSE branching (validation)
--   ► RECORD variable
--   ► Exception Handling (EXCEPTION block)
--
-- Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
-- ============================================================

-- Drop procedure if exists (for re-runnability)
DROP PROCEDURE IF EXISTS sp_transfer_animal_visits(INT, INT);

CREATE OR REPLACE PROCEDURE sp_transfer_animal_visits(
    p_from_vet_id  INT,   -- Source vet (visits will be moved FROM)
    p_to_vet_id    INT    -- Target vet (visits will be moved TO)
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- RECORD variable for vet validation
    v_from_vet   RECORD;
    v_to_vet     RECORD;

    -- Counter for rows affected (Implicit Cursor result)
    v_rows_affected  INT;

    -- RECORD for iterating visits before transfer
    v_visit_rec      RECORD;
    v_transfer_count INT := 0;

BEGIN
    -- ===================================================
    -- Step 1: Input validation using IF/ELSE
    -- ===================================================
    IF p_from_vet_id IS NULL OR p_to_vet_id IS NULL THEN
        RAISE EXCEPTION 'Both Vet IDs must be provided (not NULL).';
    END IF;

    IF p_from_vet_id = p_to_vet_id THEN
        RAISE EXCEPTION 'Source and target vet cannot be the same (ID: %).', p_from_vet_id;
    END IF;

    -- ===================================================
    -- Step 2: Verify both veterinarians exist
    -- Uses RECORD variables
    -- ===================================================
    SELECT VetID, FirstName, LastName, Specialization
    INTO v_from_vet
    FROM Veterinarian
    WHERE VetID = p_from_vet_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source Veterinarian with ID % does not exist.', p_from_vet_id;
    END IF;

    SELECT VetID, FirstName, LastName, Specialization
    INTO v_to_vet
    FROM Veterinarian
    WHERE VetID = p_to_vet_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Target Veterinarian with ID % does not exist.', p_to_vet_id;
    END IF;

    RAISE NOTICE '=== Visit Transfer Process ===';
    RAISE NOTICE 'FROM: Dr. % % (ID: %)', v_from_vet.FirstName, v_from_vet.LastName, p_from_vet_id;
    RAISE NOTICE 'TO:   Dr. % % (ID: %)', v_to_vet.FirstName, v_to_vet.LastName, p_to_vet_id;

    -- ===================================================
    -- Step 3: FOR loop – list visits before transfer
    -- Iterates over all visits that will be affected
    -- ===================================================
    RAISE NOTICE '--- Visits to be transferred: ---';
    FOR v_visit_rec IN
        SELECT VisitID, VisitDate, Reason, Cost
        FROM MedicalVisit
        WHERE VetID = p_from_vet_id
        ORDER BY VisitDate
        LIMIT 20  -- Show first 20 for readability
    LOOP
        v_transfer_count := v_transfer_count + 1;
        RAISE NOTICE '  Visit #%: ID=%, Date=%, Cost=%',
            v_transfer_count, v_visit_rec.VisitID,
            v_visit_rec.VisitDate, v_visit_rec.Cost;
    END LOOP;

    -- ===================================================
    -- Step 4: Perform the transfer using IMPLICIT CURSOR
    -- UPDATE with GET DIAGNOSTICS to capture row count
    -- ===================================================
    UPDATE MedicalVisit
    SET VetID = p_to_vet_id,
        last_updated = NOW()
    WHERE VetID = p_from_vet_id;

    -- IMPLICIT CURSOR: Get the number of affected rows
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    -- ===================================================
    -- Step 5: Report results using IF/ELSE
    -- ===================================================
    IF v_rows_affected = 0 THEN
        RAISE NOTICE 'No visits found for Vet ID %. Nothing to transfer.', p_from_vet_id;
    ELSE
        RAISE NOTICE '=== Transfer Complete ===';
        RAISE NOTICE 'Successfully transferred % visits from Dr. % % to Dr. % %.',
            v_rows_affected,
            v_from_vet.FirstName, v_from_vet.LastName,
            v_to_vet.FirstName, v_to_vet.LastName;
    END IF;

    -- Log the transfer in audit_log
    INSERT INTO audit_log (table_name, operation, record_id, changed_column, old_value, new_value)
    VALUES ('MedicalVisit', 'TRANSFER', p_from_vet_id, 'VetID',
            p_from_vet_id::TEXT, p_to_vet_id::TEXT);

EXCEPTION
    -- ===================================================
    -- EXCEPTION HANDLING: Catches specific and general errors
    -- ===================================================
    WHEN FOREIGN_KEY_VIOLATION THEN
        RAISE NOTICE 'Foreign key violation: One of the Vet IDs is invalid.';
        RAISE;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in sp_transfer_animal_visits: [%] %', SQLSTATE, SQLERRM;
        RAISE;
END;
$$;

-- ============================================================
-- Quick test
-- ============================================================
-- Check visits count before
SELECT VetID, COUNT(*) AS visit_count
FROM MedicalVisit
WHERE VetID IN (1, 2)
GROUP BY VetID
ORDER BY VetID;

-- Run the procedure (transfers visits from Vet 1 to Vet 2)
-- CALL sp_transfer_animal_visits(1, 2);
