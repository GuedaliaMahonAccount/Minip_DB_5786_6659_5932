-- ============================================================
-- 01-sheme.sql
-- Veterinary Clinic Database Schema
-- Corresponds to the ER Diagram (Minip_DB_5786_6659_5932)
-- ============================================================

-- ============================================================
-- 1. ANIMAL Table
-- Attributes: AnimalID (PK), Name, Species, BirthDate, Gender, Weight
-- ============================================================
CREATE TABLE Animal (
    AnimalID    INT           PRIMARY KEY,
    Name        VARCHAR(100)  NOT NULL,
    Species     VARCHAR(100)  NOT NULL,
    BirthDate   DATE          NOT NULL,
    Gender      VARCHAR(20),
    Weight      DECIMAL(5, 2)
);

-- ============================================================
-- 2. VETERINARIAN Table
-- Attributes: VetID (PK), FirstName, LastName, LicenseNumber (UNIQUE),
--             Specialization, HireDate
-- ============================================================
CREATE TABLE Veterinarian (
    VetID          INT           PRIMARY KEY,
    FirstName      VARCHAR(100)  NOT NULL,
    LastName       VARCHAR(100)  NOT NULL,
    LicenseNumber  VARCHAR(50)   UNIQUE NOT NULL,
    Specialization VARCHAR(100),
    HireDate       DATE          NOT NULL
);

-- ============================================================
-- 3. MEDICALVISIT Table
-- Attributes: VisitID (PK), VisitDate, Reason, Summary, Cost
-- Foreign Keys: AnimalID -> Animal, VetID -> Veterinarian
-- Relationships:
--   Animal  1 --- M  MedicalVisit  (ON)
--   Veterinarian 1 --- M MedicalVisit (Perform)
-- ============================================================
CREATE TABLE MedicalVisit (
    VisitID   INT            PRIMARY KEY,
    VisitDate DATE           NOT NULL,
    Reason    VARCHAR(255)   NOT NULL,
    Summary   TEXT,
    Cost      DECIMAL(10, 2),
    AnimalID  INT            NOT NULL,
    VetID     INT            NOT NULL,
    FOREIGN KEY (AnimalID) REFERENCES Animal(AnimalID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (VetID) REFERENCES Veterinarian(VetID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- 4. TREATMENT Table
-- Attributes: TreatmentID (PK), Description, Duration, Type, Severity
-- ============================================================
CREATE TABLE Treatment (
    TreatmentID INT           PRIMARY KEY,
    Description VARCHAR(255)  NOT NULL,
    Duration    VARCHAR(50),
    Type        VARCHAR(50),
    Severity    VARCHAR(50)
);

-- ============================================================
-- 5. MEDICATION Table
-- Attributes: MedID (PK), CommercialName, ActiveIngredient,
--             DosageUnit, ExpirationDate
-- ============================================================
CREATE TABLE Medication (
    MedID            INT           PRIMARY KEY,
    CommercialName   VARCHAR(100)  NOT NULL,
    ActiveIngredient VARCHAR(255),
    DosageUnit       VARCHAR(50),
    ExpirationDate   DATE          NOT NULL
);

-- ============================================================
-- 6. VACCINATION Table
-- Attributes: VacID (PK), Name, Manufacturer,
--             FrequencyMonths, StorageTemp
-- ============================================================
CREATE TABLE Vaccination (
    VacID           INT           PRIMARY KEY,
    Name            VARCHAR(100)  NOT NULL,
    Manufacturer    VARCHAR(100),
    FrequencyMonths INT,
    StorageTemp     VARCHAR(50)
);





-- ============================================================
-- 7. JUNCTION / RELATIONSHIP TABLES (M:M)
-- ============================================================

-- ------------------------------------------------------------
-- 7a. Mirsham_Visit_Treatment (DK relationship)
--     MedicalVisit M --- M Treatment
-- ------------------------------------------------------------
CREATE TABLE Mirsham_Visit_Treatment (
    VisitID     INT NOT NULL,
    TreatmentID INT NOT NULL,
    PRIMARY KEY (VisitID, TreatmentID),
    FOREIGN KEY (VisitID)     REFERENCES MedicalVisit(VisitID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (TreatmentID) REFERENCES Treatment(TreatmentID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- 7b. Hergel_Treatment_Medication
--     Treatment M --- M Medication
-- ------------------------------------------------------------
CREATE TABLE Hergel_Treatment_Medication (
    TreatmentID INT NOT NULL,
    MedID       INT NOT NULL,
    PRIMARY KEY (TreatmentID, MedID),
    FOREIGN KEY (TreatmentID) REFERENCES Treatment(TreatmentID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (MedID)       REFERENCES Medication(MedID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- 7c. Treatment_Vaccination (PB relationship)
--     Treatment M --- M Vaccination
-- ------------------------------------------------------------
CREATE TABLE Treatment_Vaccination (
    TreatmentID INT NOT NULL,
    VacID       INT NOT NULL,
    PRIMARY KEY (TreatmentID, VacID),
    FOREIGN KEY (TreatmentID) REFERENCES Treatment(TreatmentID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (VacID)       REFERENCES Vaccination(VacID)
        ON DELETE CASCADE ON UPDATE CASCADE
);