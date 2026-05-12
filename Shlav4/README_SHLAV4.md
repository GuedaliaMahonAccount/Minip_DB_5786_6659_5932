# 🛡️ Phase 4: Advanced PL/pgSQL Programming — VetCare System

**Team Members:** Avinoam Muller 347465932, Guedalia Sebbah 337966659

---

## 📌 Overview
This stage focuses on implementing advanced server-side logic using PL/pgSQL. We have developed 8 non-trivial programs (Functions, Procedures, Triggers, and Main Blocks) that automate complex business rules, maintain data integrity, and provide detailed reporting for the integrated VetCare and HR system.

---

## 🛠️ 1. Functions

### 1.1 `fn_get_animal_medical_summary`
**Description:** 
This function generates a comprehensive medical health profile for an animal. Using an **explicit cursor**, it iterates through all visits, calculates total and average costs, identifies the most recent visit date, and analyzes the visit frequency to assign a "Health Status" label (e.g., 'Healthy', 'Frequent Visitor', or 'Critical'). It includes robust **exception handling** for non-existent animal IDs.

#### 📝 Code:
```sql
DROP FUNCTION IF EXISTS fn_get_animal_medical_summary(INT);

CREATE OR REPLACE FUNCTION fn_get_animal_medical_summary(
    p_animal_id     INT,
    OUT o_animal_name   VARCHAR,
    OUT o_species       VARCHAR,
    OUT o_total_visits  INT,
    OUT o_total_cost    NUMERIC,
    OUT o_avg_cost      NUMERIC,
    OUT o_last_visit    DATE,
    OUT o_health_status VARCHAR
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    cur_visits CURSOR FOR
        SELECT mv.VisitID, mv.VisitDate, mv.Cost, mv.Reason, mv.status
        FROM MedicalVisit mv
        WHERE mv.AnimalID = p_animal_id
        ORDER BY mv.VisitDate DESC;

    v_visit_rec  MedicalVisit%ROWTYPE;
    v_count      INT := 0;
    v_sum_cost   NUMERIC := 0;
    v_latest     DATE;
    v_animal_rec Animal%ROWTYPE;

BEGIN
    BEGIN
        SELECT * INTO STRICT v_animal_rec
        FROM Animal
        WHERE AnimalID = p_animal_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE EXCEPTION 'Animal with ID % does not exist.', p_animal_id;
    END;

    o_animal_name := v_animal_rec.Name;
    o_species     := v_animal_rec.Species;

    FOR v_rec IN cur_visits LOOP
        v_count := v_count + 1;
        IF v_rec.Cost IS NOT NULL THEN
            v_sum_cost := v_sum_cost + v_rec.Cost;
        END IF;
        IF v_count = 1 THEN
            v_latest := v_rec.VisitDate;
        END IF;
    END LOOP;

    o_total_visits := v_count;
    o_total_cost   := v_sum_cost;
    o_last_visit   := v_latest;

    IF v_count > 0 THEN
        o_avg_cost := ROUND(v_sum_cost / v_count, 2);
    ELSE
        o_avg_cost := 0;
    END IF;

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

    RAISE NOTICE 'Summary generated for animal: % (ID: %)', o_animal_name, p_animal_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in fn_get_animal_medical_summary: % - %', SQLSTATE, SQLERRM;
        RAISE;
END;
$$;

-- Quick test
SELECT * FROM fn_get_animal_medical_summary(1);
```

> 📸 **Screenshot: Animal Medical Summary Result**
> 🖼️ ![Animal Medical Summary Result](../screenshoots/shlav4/fn1_success.png)
> *Caption: Successful execution showing composite medical profile and health status*

---

### 1.2 `fn_get_vet_visits_report`
**Description:** 
Provides a high-level reporting tool that returns a **REF CURSOR**. It takes a Veterinarian ID and a date range, validates the inputs, and opens a cursor containing detailed visit information (animal names, costs, treatment counts). This allows calling programs to process large reports row-by-row efficiently.

#### 📝 Code:
```sql
DROP FUNCTION IF EXISTS fn_get_vet_visits_report(INT, DATE, DATE);

CREATE OR REPLACE FUNCTION fn_get_vet_visits_report(
    p_vet_id     INT,
    p_start_date DATE,
    p_end_date   DATE
)
RETURNS REFCURSOR
LANGUAGE plpgsql
AS $$
DECLARE
    v_cursor     REFCURSOR := 'vet_visits_cursor';
    v_vet_rec    RECORD;
    v_visit_count INT := 0;
    v_temp_rec    RECORD;
    v_count_cursor REFCURSOR;

BEGIN
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

    RETURN v_cursor;

EXCEPTION
    WHEN INVALID_PARAMETER_VALUE THEN
        RAISE NOTICE 'Invalid parameter provided: %', SQLERRM;
        RAISE;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in fn_get_vet_visits_report: [%] %', SQLSTATE, SQLERRM;
        RAISE;
END;
$$;

-- Quick test
BEGIN;
    SELECT fn_get_vet_visits_report(1, '2023-01-01', '2024-12-31');
    FETCH ALL FROM vet_visits_cursor;
COMMIT;
```

> 📸 **Screenshot: Vet Report Ref Cursor Fetch**
> 🖼️ ![Vet Report Ref Cursor Fetch](../screenshoots/shlav4/fn2_ref_cursor.png)
> *Caption: Proof of fetching data from the returned Ref Cursor*

---

## ⚙️ 2. Procedures

### 2.1 `sp_transfer_animal_visits`
**Description:** 
Automates the transfer of an entire patient list from one veterinarian to another (e.g., during staff turnover). It uses an **implicit cursor** to perform a bulk update, captures the row count using `GET DIAGNOSTICS`, and logs the entire transfer event into the audit system.

#### 📝 Code:
```sql
DROP PROCEDURE IF EXISTS sp_transfer_animal_visits(INT, INT);

CREATE OR REPLACE PROCEDURE sp_transfer_animal_visits(
    p_from_vet_id  INT,
    p_to_vet_id    INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_vet   RECORD;
    v_to_vet     RECORD;
    v_rows_affected  INT;
    v_visit_rec      RECORD;
    v_transfer_count INT := 0;

BEGIN
    IF p_from_vet_id IS NULL OR p_to_vet_id IS NULL THEN
        RAISE EXCEPTION 'Both Vet IDs must be provided (not NULL).';
    END IF;

    IF p_from_vet_id = p_to_vet_id THEN
        RAISE EXCEPTION 'Source and target vet cannot be the same (ID: %).', p_from_vet_id;
    END IF;

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

    RAISE NOTICE '--- Visits to be transferred: ---';
    FOR v_visit_rec IN
        SELECT VisitID, VisitDate, Reason, Cost
        FROM MedicalVisit
        WHERE VetID = p_from_vet_id
        ORDER BY VisitDate
        LIMIT 20
    LOOP
        v_transfer_count := v_transfer_count + 1;
        RAISE NOTICE '  Visit #%: ID=%, Date=%, Cost=%',
            v_transfer_count, v_visit_rec.VisitID,
            v_visit_rec.VisitDate, v_visit_rec.Cost;
    END LOOP;

    UPDATE MedicalVisit
    SET VetID = p_to_vet_id,
        last_updated = NOW()
    WHERE VetID = p_from_vet_id;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

    IF v_rows_affected = 0 THEN
        RAISE NOTICE 'No visits found for Vet ID %. Nothing to transfer.', p_from_vet_id;
    ELSE
        RAISE NOTICE '=== Transfer Complete ===';
        RAISE NOTICE 'Successfully transferred % visits from Dr. % % to Dr. % %.',
            v_rows_affected,
            v_from_vet.FirstName, v_from_vet.LastName,
            v_to_vet.FirstName, v_to_vet.LastName;
    END IF;

    INSERT INTO audit_log (table_name, operation, record_id, changed_column, old_value, new_value)
    VALUES ('MedicalVisit', 'TRANSFER', p_from_vet_id, 'VetID',
            p_from_vet_id::TEXT, p_to_vet_id::TEXT);

EXCEPTION
    WHEN FOREIGN_KEY_VIOLATION THEN
        RAISE NOTICE 'Foreign key violation: One of the Vet IDs is invalid.';
        RAISE;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in sp_transfer_animal_visits: [%] %', SQLSTATE, SQLERRM;
        RAISE;
END;
$$;

-- Quick test
SELECT VetID, COUNT(*) AS visit_count
FROM MedicalVisit
WHERE VetID IN (1, 2)
GROUP BY VetID
ORDER BY VetID;
-- CALL sp_transfer_animal_visits(1, 2);
```

> 📸 **Screenshot: Visit Transfer Logs**
> 🖼️ ![Visit Transfer Logs](../screenshoots/shlav4/sp1_transfer_log.png)
> *Caption: Execution output showing the list of transferred visits and the final row count*

---

### 2.2 `sp_cleanup_expired_medications`
**Description:** 
A data hygiene procedure that uses an **explicit cursor with a WHILE loop** to identify medications past their expiration date. It safely archives the data into an archive table, removes junction table links, and deletes the expired record from the main inventory.

#### 📝 Code:
```sql
DROP PROCEDURE IF EXISTS sp_cleanup_expired_medications(DATE);

CREATE OR REPLACE PROCEDURE sp_cleanup_expired_medications(
    p_cutoff_date DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    cur_expired CURSOR FOR
        SELECT MedID, CommercialName, ActiveIngredient, DosageUnit, ExpirationDate
        FROM Medication
        WHERE ExpirationDate < p_cutoff_date
        ORDER BY ExpirationDate ASC;

    v_med_rec       Medication%ROWTYPE;
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

    OPEN cur_expired;

    LOOP
        FETCH cur_expired INTO v_med_rec;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE '--- Processing: % (ID: %, Expired: %) ---',
            v_med_rec.CommercialName, v_med_rec.MedID, v_med_rec.ExpirationDate;

        INSERT INTO expired_medications_archive (
            med_id, commercial_name, active_ingredient,
            dosage_unit, expiration_date
        ) VALUES (
            v_med_rec.MedID, v_med_rec.CommercialName,
            v_med_rec.ActiveIngredient, v_med_rec.DosageUnit,
            v_med_rec.ExpirationDate
        );
        v_archived := v_archived + 1;

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

        DELETE FROM Medication
        WHERE MedID = v_med_rec.MedID;
        v_deleted := v_deleted + 1;

    END LOOP;

    CLOSE cur_expired;

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
    WHEN FOREIGN_KEY_VIOLATION THEN
        RAISE NOTICE 'Cannot delete medication: still referenced by other tables.';
        RAISE NOTICE 'Error details: %', SQLERRM;
        RAISE;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in sp_cleanup_expired_medications: [%] %', SQLSTATE, SQLERRM;
        RAISE;
END;
$$;

-- Quick test
SELECT COUNT(*) AS expired_count
FROM Medication
WHERE ExpirationDate < CURRENT_DATE;
-- CALL sp_cleanup_expired_medications(CURRENT_DATE);
```

> 📸 **Screenshot: Medication Cleanup Summary**
> 🖼️ ![Medication Cleanup Summary](../screenshoots/shlav4/sp2_cleanup.png)
> *Caption: Procedure summary showing archived meds and removed treatment links*

---

## ⚡ 3. Triggers

### 3.1 `trg_audit_visit_update` (AFTER UPDATE)
**Description:** 
A non-intrusive monitoring trigger that fires after any update to a `MedicalVisit`. It compares `OLD` and `NEW` records to detect changes in critical columns (VetID, Cost, Status) and automatically records them in the `audit_log` table for security and history tracking.

#### 📝 Code:
```sql
DROP TRIGGER IF EXISTS trg_audit_visit_update ON MedicalVisit;
DROP FUNCTION IF EXISTS fn_audit_visit_update();

CREATE OR REPLACE FUNCTION fn_audit_visit_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.VetID IS DISTINCT FROM NEW.VetID THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'VetID', OLD.VetID::TEXT, NEW.VetID::TEXT);
    END IF;

    IF OLD.AnimalID IS DISTINCT FROM NEW.AnimalID THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'AnimalID', OLD.AnimalID::TEXT, NEW.AnimalID::TEXT);
    END IF;

    IF OLD.Cost IS DISTINCT FROM NEW.Cost THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'Cost', OLD.Cost::TEXT, NEW.Cost::TEXT);
    END IF;

    IF OLD.Reason IS DISTINCT FROM NEW.Reason THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'Reason', OLD.Reason::TEXT, NEW.Reason::TEXT);
    END IF;

    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'status', OLD.status::TEXT, NEW.status::TEXT);
    END IF;

    IF OLD.VisitDate IS DISTINCT FROM NEW.VisitDate THEN
        INSERT INTO audit_log (table_name, operation, record_id,
                               changed_column, old_value, new_value)
        VALUES ('MedicalVisit', 'UPDATE', NEW.VisitID,
                'VisitDate', OLD.VisitDate::TEXT, NEW.VisitDate::TEXT);
    END IF;

    NEW.last_updated := NOW();

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_audit_visit_update
    AFTER UPDATE ON MedicalVisit
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_visit_update();

-- Quick test
-- UPDATE MedicalVisit SET Cost = 999.99 WHERE VisitID = 1;
-- SELECT * FROM audit_log ORDER BY log_id DESC LIMIT 5;
```

> 📸 **Screenshot: Audit Log Verification**
> 🖼️ ![Audit Log Verification](../screenshoots/shlav4/trg1_audit_result.png)
> *Caption: result of SELECT * FROM audit_log showing the trigger-generated record after an update*

---

### 3.2 `trg_validate_visit_insert` (BEFORE INSERT)
**Description:** 
Enforces complex business rules before saving a visit. It validates that IDs exist, prevents negative costs or future dates, and automatically updates the animal's denormalized visitation counters.

#### 📝 Code:
```sql
DROP TRIGGER IF EXISTS trg_validate_visit_insert ON MedicalVisit;
DROP FUNCTION IF EXISTS fn_validate_visit_insert();

CREATE OR REPLACE FUNCTION fn_validate_visit_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_vet_rec     RECORD;
    v_animal_rec  RECORD;
    v_visit_count INT;

BEGIN
    SELECT VetID, FirstName, LastName
    INTO v_vet_rec
    FROM Veterinarian
    WHERE VetID = NEW.VetID;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'VALIDATION ERROR: Veterinarian with ID % does not exist. Cannot create visit.', NEW.VetID;
    END IF;

    SELECT AnimalID, Name, Species
    INTO v_animal_rec
    FROM Animal
    WHERE AnimalID = NEW.AnimalID;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'VALIDATION ERROR: Animal with ID % does not exist. Cannot create visit.', NEW.AnimalID;
    END IF;

    IF NEW.Cost IS NULL THEN
        RAISE NOTICE 'Note: Visit for animal "%" has no cost specified.', v_animal_rec.Name;
    ELSIF NEW.Cost < 0 THEN
        RAISE EXCEPTION 'VALIDATION ERROR: Cost cannot be negative (given: %).', NEW.Cost;
    ELSIF NEW.Cost > 10000 THEN
        RAISE NOTICE 'WARNING: Unusually high cost (%) for visit. Proceeding with caution.', NEW.Cost;
    ELSE
        NULL;
    END IF;

    IF NEW.VisitDate > CURRENT_DATE THEN
        RAISE EXCEPTION 'VALIDATION ERROR: Visit date (%) cannot be in the future.', NEW.VisitDate;
    END IF;

    IF NEW.status IS NULL THEN
        NEW.status := 'Completed';
    END IF;

    NEW.last_updated := NOW();

    IF NEW.Summary IS NULL OR NEW.Summary = '' THEN
        NEW.Summary := 'Visit for ' || v_animal_rec.Name ||
                       ' with Dr. ' || v_vet_rec.FirstName || ' ' || v_vet_rec.LastName;
    END IF;

    UPDATE Animal
    SET total_visits    = COALESCE(total_visits, 0) + 1,
        last_visit_date = NEW.VisitDate
    WHERE AnimalID = NEW.AnimalID
      AND (last_visit_date IS NULL OR last_visit_date <= NEW.VisitDate);

    RAISE NOTICE 'Visit validated: Animal="%" (%), Vet=Dr. % %, Cost=%',
        v_animal_rec.Name, v_animal_rec.Species,
        v_vet_rec.FirstName, v_vet_rec.LastName,
        COALESCE(NEW.Cost::TEXT, 'N/A');

    RETURN NEW;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Trigger validation error: [%] %', SQLSTATE, SQLERRM;
        RAISE;
END;
$$;

CREATE TRIGGER trg_validate_visit_insert
    BEFORE INSERT ON MedicalVisit
    FOR EACH ROW
    EXECUTE FUNCTION fn_validate_visit_insert();

-- Quick test
-- INSERT INTO MedicalVisit (VisitID, VisitDate, Reason, Cost, AnimalID, VetID)
-- VALUES (99901, CURRENT_DATE, 'Annual checkup', 150.00, 1, 1);
-- SELECT * FROM MedicalVisit WHERE VisitID = 99901;
```

> 📸 **Screenshot: Validation Exception Catch**
> 🖼️ ![Validation Exception Catch](../screenshoots/shlav4/trg2_exception.png)
> *Caption: Proof of the trigger blocking an invalid insert with a custom error message*

---

## 🚀 4. Main Programs (Integration)

### 4.1 Main Program 1: Medical History & Staff Management
**Description:** 
A `DO` block that iterates through an array of animal IDs to print health reports (calling Function 1) and then executes a veterinarian patient transfer (calling Procedure 1). It demonstrates the seamless integration of functions and procedures in a single transaction.

#### 📝 Code:
```sql
DO $$
DECLARE
    v_summary      RECORD;
    v_from_vet     INT := 3;
    v_to_vet       INT := 4;
    v_animal_id    INT;
    v_animals      INT[] := ARRAY[1, 2, 3, 5, 10];

BEGIN
    RAISE NOTICE '╔══════════════════════════════════════════════════╗';
    RAISE NOTICE '║   MAIN PROGRAM 1: Medical Summary & Transfer    ║';
    RAISE NOTICE '╚══════════════════════════════════════════════════╝';
    RAISE NOTICE '';

    RAISE NOTICE '═══ PART A: Animal Medical Summaries ═══';
    RAISE NOTICE '';

    FOR i IN 1..array_length(v_animals, 1) LOOP
        v_animal_id := v_animals[i];

        BEGIN
            SELECT * INTO v_summary
            FROM fn_get_animal_medical_summary(v_animal_id);

            RAISE NOTICE '┌─────────────────────────────────────────┐';
            RAISE NOTICE '│ Animal #%: %', v_animal_id, v_summary.o_animal_name;
            RAISE NOTICE '│ Species:       %', v_summary.o_species;
            RAISE NOTICE '│ Total Visits:  %', v_summary.o_total_visits;
            RAISE NOTICE '│ Total Cost:    ₪%', v_summary.o_total_cost;
            RAISE NOTICE '│ Average Cost:  ₪%', v_summary.o_avg_cost;
            RAISE NOTICE '│ Last Visit:    %', COALESCE(v_summary.o_last_visit::TEXT, 'None');

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

    RAISE NOTICE '';
    RAISE NOTICE '═══ PART B: Visit Transfer Operation ═══';
    RAISE NOTICE '';

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

    CALL sp_transfer_animal_visits(v_from_vet, v_to_vet);

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
```

> 📸 **Screenshot: Main Program 1 Formatted Output**
> 🖼️ ![Main Program 1 Formatted Output](../screenshoots/shlav4/main1_output.png)
> *Caption: Formatted console output showing animal summaries and transfer results*

---

### 4.2 Main Program 2: Billing & Inventory Maintenance
**Description:** 
This `DO` block calls Function 2 to process a Ref Cursor for billing data (calculating running totals) and then invokes the medication cleanup procedure to ensure only valid medications are available in the system.

#### 📝 Code:
```sql
DO $$
DECLARE
    v_cursor      REFCURSOR;
    v_rec         RECORD;
    v_row_count   INT := 0;
    v_total_cost  NUMERIC := 0;
    v_max_cost    NUMERIC := 0;
    v_vet_id      INT := 2;
    v_start_date  DATE := '2023-01-01';
    v_end_date    DATE := '2024-12-31';
    v_expired_before  INT;
    v_expired_after   INT;
    v_archived_count  INT;

BEGIN
    RAISE NOTICE '╔══════════════════════════════════════════════════╗';
    RAISE NOTICE '║  MAIN PROGRAM 2: Vet Report & Medication Cleanup║';
    RAISE NOTICE '╚══════════════════════════════════════════════════╝';
    RAISE NOTICE '';

    RAISE NOTICE '═══ PART A: Vet Visits Report (REF CURSOR) ═══';
    RAISE NOTICE 'Generating report for Vet #% (% to %)',
        v_vet_id, v_start_date, v_end_date;
    RAISE NOTICE '';

    v_cursor := fn_get_vet_visits_report(v_vet_id, v_start_date, v_end_date);

    RAISE NOTICE '┌──────┬────────────────┬────────────────┬────────────┬──────────┐';
    RAISE NOTICE '│ Row# │ Animal         │ Species        │ Date       │ Cost     │';
    RAISE NOTICE '├──────┼────────────────┼────────────────┼────────────┼──────────┤';

    LOOP
        FETCH v_cursor INTO v_rec;
        EXIT WHEN NOT FOUND;

        v_row_count := v_row_count + 1;

        IF v_rec.Cost IS NOT NULL THEN
            v_total_cost := v_total_cost + v_rec.Cost;
            IF v_rec.Cost > v_max_cost THEN
                v_max_cost := v_rec.Cost;
            END IF;
        END IF;

        IF v_row_count <= 15 THEN
            RAISE NOTICE '│ %   │ % │ % │ % │ ₪%  │',
                LPAD(v_row_count::TEXT, 3),
                RPAD(COALESCE(v_rec.animal_name, 'N/A'), 14),
                RPAD(COALESCE(v_rec.animal_species, 'N/A'), 14),
                v_rec.VisitDate,
                LPAD(COALESCE(v_rec.Cost::TEXT, 'N/A'), 7);
        END IF;
    END LOOP;

    CLOSE v_cursor;

    RAISE NOTICE '└──────┴────────────────┴────────────────┴────────────┴──────────┘';
    RAISE NOTICE '';

    IF v_row_count = 0 THEN
        RAISE NOTICE 'No visits found for the specified criteria.';
    ELSE
        RAISE NOTICE 'Report Summary:';
        RAISE NOTICE '  Total visits:    %', v_row_count;
        RAISE NOTICE '  Total revenue:   ₪%', ROUND(v_total_cost, 2);
        RAISE NOTICE '  Average cost:    ₪%', ROUND(v_total_cost / v_row_count, 2);
        RAISE NOTICE '  Highest cost:    ₪%', v_max_cost;
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '═══ PART B: Expired Medication Cleanup ═══';
    RAISE NOTICE '';

    SELECT COUNT(*) INTO v_expired_before
    FROM Medication
    WHERE ExpirationDate < CURRENT_DATE;

    SELECT COUNT(*) INTO v_archived_count
    FROM expired_medications_archive;

    RAISE NOTICE 'Before cleanup:';
    RAISE NOTICE '  Expired medications in DB:    %', v_expired_before;
    RAISE NOTICE '  Already archived:             %', v_archived_count;
    RAISE NOTICE '';

    CALL sp_cleanup_expired_medications(CURRENT_DATE);

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
```

> 📸 **Screenshot: Main Program 2 Report & Cleanup**
> 🖼️ ![Main Program 2 Report & Cleanup](../screenshoots/shlav4/main2_output.png)
> *Caption: Console output showing the billing report table and cleanup stats*

---

## 📊 Appendix: Schema Modifications

### `AlterTable.sql`
**Description:** 
Creates the supporting infrastructure for Stage 4, including audit logs, archive tables, and denormalized columns (`total_visits`, `last_visit_date`) to improve performance.

#### 📝 Code:
```sql
ALTER TABLE MedicalVisit
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'Completed'
    CHECK (status IN ('Scheduled', 'Completed', 'Cancelled'));

ALTER TABLE MedicalVisit
ADD COLUMN IF NOT EXISTS last_updated TIMESTAMP DEFAULT NOW();

ALTER TABLE Animal
ADD COLUMN IF NOT EXISTS total_visits INT DEFAULT 0;

ALTER TABLE Animal
ADD COLUMN IF NOT EXISTS last_visit_date DATE;

CREATE TABLE IF NOT EXISTS audit_log (
    log_id          SERIAL          PRIMARY KEY,
    table_name      VARCHAR(100)    NOT NULL,
    operation       VARCHAR(10)     NOT NULL,
    record_id       INT             NOT NULL,
    changed_column  VARCHAR(100),
    old_value       TEXT,
    new_value       TEXT,
    changed_by      VARCHAR(100)    DEFAULT CURRENT_USER,
    changed_at      TIMESTAMP       DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS expired_medications_archive (
    archive_id       SERIAL          PRIMARY KEY,
    med_id           INT             NOT NULL,
    commercial_name  VARCHAR(100)    NOT NULL,
    active_ingredient VARCHAR(255),
    dosage_unit      VARCHAR(50),
    expiration_date  DATE            NOT NULL,
    archived_at      TIMESTAMP       DEFAULT NOW()
);

UPDATE Animal a
SET total_visits = sub.cnt
FROM (
    SELECT AnimalID, COUNT(*) AS cnt
    FROM MedicalVisit
    GROUP BY AnimalID
) sub
WHERE a.AnimalID = sub.AnimalID;

UPDATE Animal a
SET last_visit_date = sub.max_date
FROM (
    SELECT AnimalID, MAX(VisitDate) AS max_date
    FROM MedicalVisit
    GROUP BY AnimalID
) sub
WHERE a.AnimalID = sub.AnimalID;

-- Verification
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'medicalvisit'
  AND column_name IN ('status', 'last_updated')
ORDER BY ordinal_position;

SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'animal'
  AND column_name IN ('total_visits', 'last_visit_date')
ORDER BY ordinal_position;
```

> 📸 **Screenshot: Database Structure Update**
> 🖼️ ![Database Structure Update](../screenshoots/shlav4/schema_update.png)
> *Caption: Proof of successfully adding the new columns and tables*
