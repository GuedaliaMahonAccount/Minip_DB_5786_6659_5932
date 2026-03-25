-- ============================================================
-- File: AlterTable.sql
-- Stage 4: Schema Modifications for PL/pgSQL Programs
-- Description: Adds columns and tables required by the
--              functions, procedures, and triggers in Stage 4.
-- Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
-- ============================================================

-- ============================================================
-- 1. Add 'status' column to MedicalVisit
--    Tracks the lifecycle of a visit: Scheduled, Completed, Cancelled
-- ============================================================
ALTER TABLE MedicalVisit
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'Completed'
    CHECK (status IN ('Scheduled', 'Completed', 'Cancelled'));

-- ============================================================
-- 2. Add 'last_updated' column to MedicalVisit
--    Timestamp of the last modification – updated by trigger
-- ============================================================
ALTER TABLE MedicalVisit
ADD COLUMN IF NOT EXISTS last_updated TIMESTAMP DEFAULT NOW();

-- ============================================================
-- 3. Add 'total_visits' counter to Animal
--    Denormalized counter for quick access (maintained by procedures)
-- ============================================================
ALTER TABLE Animal
ADD COLUMN IF NOT EXISTS total_visits INT DEFAULT 0;

-- ============================================================
-- 4. Add 'last_visit_date' to Animal
--    Cached date of the most recent visit for the animal
-- ============================================================
ALTER TABLE Animal
ADD COLUMN IF NOT EXISTS last_visit_date DATE;

-- ============================================================
-- 5. Create audit_log table
--    Stores a history of all changes made to MedicalVisit rows.
--    Populated automatically by the AFTER UPDATE trigger.
-- ============================================================
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

-- ============================================================
-- 6. Create expired_medications_archive table
--    Archive table for medications removed by the cleanup procedure
-- ============================================================
CREATE TABLE IF NOT EXISTS expired_medications_archive (
    archive_id       SERIAL          PRIMARY KEY,
    med_id           INT             NOT NULL,
    commercial_name  VARCHAR(100)    NOT NULL,
    active_ingredient VARCHAR(255),
    dosage_unit      VARCHAR(50),
    expiration_date  DATE            NOT NULL,
    archived_at      TIMESTAMP       DEFAULT NOW()
);

-- ============================================================
-- 7. Populate the total_visits counter in Animal table
--    One-time update so the column reflects existing data
-- ============================================================
UPDATE Animal a
SET total_visits = sub.cnt
FROM (
    SELECT AnimalID, COUNT(*) AS cnt
    FROM MedicalVisit
    GROUP BY AnimalID
) sub
WHERE a.AnimalID = sub.AnimalID;

-- Populate last_visit_date from existing data
UPDATE Animal a
SET last_visit_date = sub.max_date
FROM (
    SELECT AnimalID, MAX(VisitDate) AS max_date
    FROM MedicalVisit
    GROUP BY AnimalID
) sub
WHERE a.AnimalID = sub.AnimalID;

-- ============================================================
-- Verification: Show the new columns
-- ============================================================
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
