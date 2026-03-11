-- ============================================================
-- File: createTables.sql
-- Description: Creation of tables with constraints (3NF)
-- ============================================================

-- 1. ANIMAL Table
CREATE TABLE Animal (
    AnimalID    INT           PRIMARY KEY,
    Name        VARCHAR(100)  NOT NULL,
    Species     VARCHAR(100)  NOT NULL,
    BirthDate   DATE          NOT NULL,
    Gender      VARCHAR(20)   CHECK (Gender IN ('Male', 'Female', 'Unknown')),
    Weight      NUMERIC(5, 2) CHECK (Weight > 0)
);

-- 2. VETERINARIAN Table
CREATE TABLE Veterinarian (
    VetID          INT           PRIMARY KEY,
    FirstName      VARCHAR(100)  NOT NULL,
    LastName       VARCHAR(100)  NOT NULL,
    LicenseNumber  VARCHAR(50)   UNIQUE NOT NULL,
    Specialization VARCHAR(100),
    HireDate       DATE          NOT NULL CHECK (HireDate <= CURRENT_DATE)
);

-- 3. MEDICALVISIT Table
CREATE TABLE MedicalVisit (
    VisitID   INT            PRIMARY KEY,
    VisitDate DATE           NOT NULL,
    Reason    VARCHAR(255)   NOT NULL,
    Summary   TEXT,
    Cost      NUMERIC(10, 2) CHECK (Cost >= 0),
    AnimalID  INT            NOT NULL,
    VetID     INT            NOT NULL,
    FOREIGN KEY (AnimalID) REFERENCES Animal(AnimalID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (VetID) REFERENCES Veterinarian(VetID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 4. TREATMENT Table
CREATE TABLE Treatment (
    TreatmentID INT           PRIMARY KEY,
    Description VARCHAR(255)  NOT NULL,
    Duration    VARCHAR(50),
    Type        VARCHAR(50),
    Severity    VARCHAR(50)   CHECK (Severity IN ('Low', 'Medium', 'High', 'Critical'))
);

-- 5. MEDICATION Table
CREATE TABLE Medication (
    MedID            INT           PRIMARY KEY,
    CommercialName   VARCHAR(100)  NOT NULL,
    ActiveIngredient VARCHAR(255),
    DosageUnit       VARCHAR(50),
    ExpirationDate   DATE          NOT NULL
);

-- 6. VACCINATION Table
CREATE TABLE Vaccination (
    VacID           INT           PRIMARY KEY,
    Name            VARCHAR(100)  NOT NULL,
    Manufacturer    VARCHAR(100),
    FrequencyMonths INT           CHECK (FrequencyMonths > 0),
    StorageTemp     VARCHAR(50)
);

-- 7. JUNCTION TABLES (M:M)

-- 7a. Mirsham_Visit_Treatment
CREATE TABLE Mirsham_Visit_Treatment (
    VisitID     INT NOT NULL,
    TreatmentID INT NOT NULL,
    PRIMARY KEY (VisitID, TreatmentID),
    FOREIGN KEY (VisitID) REFERENCES MedicalVisit(VisitID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (TreatmentID) REFERENCES Treatment(TreatmentID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 7b. Hergel_Treatment_Medication
CREATE TABLE Hergel_Treatment_Medication (
    TreatmentID INT NOT NULL,
    MedID       INT NOT NULL,
    PRIMARY KEY (TreatmentID, MedID),
    FOREIGN KEY (TreatmentID) REFERENCES Treatment(TreatmentID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (MedID) REFERENCES Medication(MedID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 7c. Treatment_Vaccination
CREATE TABLE Treatment_Vaccination (
    TreatmentID INT NOT NULL,
    VacID       INT NOT NULL,
    PRIMARY KEY (TreatmentID, VacID),
    FOREIGN KEY (TreatmentID) REFERENCES Treatment(TreatmentID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (VacID) REFERENCES Vaccination(VacID)
        ON DELETE CASCADE ON UPDATE CASCADE
);