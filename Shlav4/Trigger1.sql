-- ============================================================
-- File: Trigger1.sql
-- Stage 4: Trigger 1 – trg_audit_visit_update (AFTER UPDATE)
-- Description: Automatically logs every change made to the
--              MedicalVisit table into the audit_log table.
--              Tracks which columns changed, old/new values,
--              who made the change, and when.
--
-- Technical Elements Used:
--   ► AFTER UPDATE trigger
--   ► OLD / NEW record references
--   ► IF branching (comparing old vs new values)
--   ► DML: INSERT (into audit_log)
--   ► Implicit cursor operations
--
-- Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
-- ============================================================

-- Drop trigger and function if they exist (for re-runnability)
DROP TRIGGER IF EXISTS trg_audit_visit_update ON MedicalVisit;
DROP FUNCTION IF EXISTS fn_audit_visit_update();

-- ============================================================
-- Trigger Function
-- ============================================================
CREATE OR REPLACE FUNCTION fn_audit_visit_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- ===================================================
    -- Compare OLD and NEW values for each important column
    -- Log only columns that actually changed
    -- Uses IF branching and OLD/NEW record references
    -- ===================================================

    -- Check if VetID changed
    IF OLD.VetID IS DISTINCT FROM NEW.VetID THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'VetID', OLD.VetID::TEXT, NEW.VetID::TEXT);
    END IF;

    -- Check if AnimalID changed
    IF OLD.AnimalID IS DISTINCT FROM NEW.AnimalID THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'AnimalID', OLD.AnimalID::TEXT, NEW.AnimalID::TEXT);
    END IF;

    -- Check if Cost changed
    IF OLD.Cost IS DISTINCT FROM NEW.Cost THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'Cost', OLD.Cost::TEXT, NEW.Cost::TEXT);
    END IF;

    -- Check if Reason changed
    IF OLD.Reason IS DISTINCT FROM NEW.Reason THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'Reason', OLD.Reason::TEXT, NEW.Reason::TEXT);
    END IF;

    -- Check if Status changed
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'status', OLD.status::TEXT, NEW.status::TEXT);
    END IF;

    -- Check if VisitDate changed
    IF OLD.VisitDate IS DISTINCT FROM NEW.VisitDate THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'VisitDate', OLD.VisitDate::TEXT, NEW.VisitDate::TEXT);
    END IF;

    -- ===================================================
    -- Always update the last_updated timestamp
    -- ===================================================
    NEW.last_updated := NOW();

    RETURN NEW;
END;
$$;

-- ============================================================
-- Create the AFTER UPDATE trigger on MedicalVisit
-- ============================================================
CREATE TRIGGER trg_audit_visit_update
    AFTER UPDATE ON MedicalVisit
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_visit_update();

-- ============================================================
-- Quick test: Update a visit and check the audit log
-- ============================================================
-- UPDATE MedicalVisit SET Cost = 999.99 WHERE VisitID = 1;
-- SELECT * FROM audit_log ORDER BY log_id DESC LIMIT 5;
