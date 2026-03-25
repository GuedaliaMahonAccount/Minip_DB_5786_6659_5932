-- ============================================================
-- File: Trigger2.sql
-- Stage 4: Trigger 2 – trg_validate_visit_insert (BEFORE INSERT)
-- Description: Validates business rules before allowing a new
--              MedicalVisit to be inserted. Ensures data
--              integrity by checking that the vet exists, the
--              animal exists, the cost is valid, and auto-sets
--              default values.
--
-- Technical Elements Used:
--   ► BEFORE INSERT trigger
--   ► NEW record reference
--   ► IF / ELSIF / ELSE branching (multiple validations)
--   ► RECORD variable (for existence checks)
--   ► RAISE EXCEPTION (to reject invalid data)
--   ► Exception Handling
--
-- Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
-- ============================================================

-- Drop trigger and function if they exist (for re-runnability)
DROP TRIGGER IF EXISTS trg_validate_visit_insert ON MedicalVisit;
DROP FUNCTION IF EXISTS fn_validate_visit_insert();

-- ============================================================
-- Trigger Function
-- ============================================================
CREATE OR REPLACE FUNCTION fn_validate_visit_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    -- RECORD variables for existence checks
    v_vet_rec     RECORD;
    v_animal_rec  RECORD;
    v_visit_count INT;

BEGIN
    -- ===================================================
    -- Validation 1: Check that the Veterinarian exists
    -- ===================================================
    SELECT VetID, FirstName, LastName
    INTO v_vet_rec
    FROM Veterinarian
    WHERE VetID = NEW.VetID;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'VALIDATION ERROR: Veterinarian with ID % does not exist. Cannot create visit.', NEW.VetID;
    END IF;

    -- ===================================================
    -- Validation 2: Check that the Animal exists
    -- ===================================================
    SELECT AnimalID, Name, Species
    INTO v_animal_rec
    FROM Animal
    WHERE AnimalID = NEW.AnimalID;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'VALIDATION ERROR: Animal with ID % does not exist. Cannot create visit.', NEW.AnimalID;
    END IF;

    -- ===================================================
    -- Validation 3: Cost validation using IF/ELSIF/ELSE
    -- ===================================================
    IF NEW.Cost IS NULL THEN
        -- Allow NULL cost (some visits may be free)
        RAISE NOTICE 'Note: Visit for animal "%" has no cost specified.', v_animal_rec.Name;
    ELSIF NEW.Cost < 0 THEN
        RAISE EXCEPTION 'VALIDATION ERROR: Cost cannot be negative (given: %).', NEW.Cost;
    ELSIF NEW.Cost > 10000 THEN
        RAISE NOTICE 'WARNING: Unusually high cost (%) for visit. Proceeding with caution.', NEW.Cost;
    ELSE
        -- Normal cost range, no action needed
        NULL;
    END IF;

    -- ===================================================
    -- Validation 4: Prevent future visit dates
    -- ===================================================
    IF NEW.VisitDate > CURRENT_DATE THEN
        RAISE EXCEPTION 'VALIDATION ERROR: Visit date (%) cannot be in the future.', NEW.VisitDate;
    END IF;

    -- ===================================================
    -- Auto-set defaults using NEW record
    -- ===================================================

    -- Set status to 'Completed' if not provided
    IF NEW.status IS NULL THEN
        NEW.status := 'Completed';
    END IF;

    -- Set last_updated timestamp
    NEW.last_updated := NOW();

    -- Set Summary if empty
    IF NEW.Summary IS NULL OR NEW.Summary = '' THEN
        NEW.Summary := 'Visit for ' || v_animal_rec.Name ||
                       ' with Dr. ' || v_vet_rec.FirstName || ' ' || v_vet_rec.LastName;
    END IF;

    -- ===================================================
    -- Update the Animal's denormalized counters
    -- ===================================================
    UPDATE Animal
    SET total_visits    = COALESCE(total_visits, 0) + 1,
        last_visit_date = NEW.VisitDate
    WHERE AnimalID = NEW.AnimalID
      AND (last_visit_date IS NULL OR last_visit_date <= NEW.VisitDate);

    RAISE NOTICE 'Visit validated: Animal="%" (%), Vet=Dr. % %, Cost=%',
        v_animal_rec.Name, v_animal_rec.Species,
        v_vet_rec.FirstName, v_vet_rec.LastName,
        COALESCE(NEW.Cost::TEXT, 'N/A');

    -- Return the (possibly modified) NEW record
    RETURN NEW;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Trigger validation error: [%] %', SQLSTATE, SQLERRM;
        RAISE;
END;
$$;

-- ============================================================
-- Create the BEFORE INSERT trigger on MedicalVisit
-- ============================================================
CREATE TRIGGER trg_validate_visit_insert
    BEFORE INSERT ON MedicalVisit
    FOR EACH ROW
    EXECUTE FUNCTION fn_validate_visit_insert();

-- ============================================================
-- Quick test: Insert a valid visit
-- ============================================================
-- INSERT INTO MedicalVisit (VisitID, VisitDate, Reason, Cost, AnimalID, VetID)
-- VALUES (99901, CURRENT_DATE, 'Annual checkup', 150.00, 1, 1);
-- SELECT * FROM MedicalVisit WHERE VisitID = 99901;
