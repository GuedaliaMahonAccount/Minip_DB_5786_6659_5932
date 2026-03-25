-- ============================================================
-- seed_data.sql
-- Populates all empty tables for the fresh Docker DB.
-- Run this ONCE in pgAdmin after docker-compose up.
-- VetID range: 1-1000 (from mockaroo_veterinarians.sql)
-- ============================================================

-- ── 1. ANIMAL  (200 rows) ─────────────────────────────────
INSERT INTO Animal (AnimalID, Name, Species, BirthDate, Gender, Weight)
SELECT
    i,
    (ARRAY[
        'Leo','Max','Bella','Charlie','Luna','Rocky','Milo','Coco',
        'Simba','Nala','Zara','Thor','Zeus','Cleo','Titan','Rex',
        'Lola','Bruno','Daisy','Oscar','Ruby','Buddy','Lily','Bear',
        'Penny','Duke','Molly','Ace','Rosie','Hunter'
    ])[ (i % 30) + 1 ] || '_' || i,
    (ARRAY[
        'Lion','Tiger','Elephant','Giraffe','Zebra','Cheetah',
        'Hippo','Rhinoceros','Leopard','Wolf','Bear','Gorilla',
        'Crocodile','Flamingo','Penguin','Eagle','Parrot','Otter'
    ])[ (i % 18) + 1 ],
    '2010-01-01'::date + (i * 37 % 4000),
    (ARRAY['Male','Female','Unknown'])[ (i % 3) + 1 ],
    ROUND((15 + (i * 7.3) % 485)::numeric, 2)
FROM generate_series(1, 200) AS i
ON CONFLICT (AnimalID) DO NOTHING;

-- ── 2. TREATMENT  (200 rows) ──────────────────────────────
INSERT INTO Treatment (TreatmentID, Description, Duration, Type, Severity)
SELECT
    i,
    (ARRAY[
        'General Checkup','Wound Cleaning','Blood Test','X-Ray',
        'Ultrasound','Dental Cleaning','Vaccination','Surgery',
        'Physiotherapy','Nutritional Assessment','Parasite Treatment',
        'Eye Exam','Ear Cleaning','Skin Treatment','Bone Setting'
    ])[ (i % 15) + 1 ] || ' #' || i,
    (ARRAY['30 mins','1 hour','2 hours','3 hours','30 mins'])[ (i % 5) + 1 ],
    (ARRAY['Routine','Surgical','Emergency','Preventive'])[ (i % 4) + 1 ],
    (ARRAY['Low','Medium','High','Critical'])[ (i % 4) + 1 ]
FROM generate_series(1, 200) AS i
ON CONFLICT (TreatmentID) DO NOTHING;

-- ── 3. MEDICATION  (200 rows) ─────────────────────────────
INSERT INTO Medication (MedID, CommercialName, ActiveIngredient, DosageUnit, ExpirationDate)
SELECT
    i,
    (ARRAY[
        'Amoxivet','Carprofen','Metronidazole','Fenbendazole',
        'Ivermectin','Doxycycline','Tramadol','Gabapentin',
        'Prednisolone','Furosemide','Enalapril','Phenobarbital',
        'Acepromazine','Ketamine','Meloxicam'
    ])[ (i % 15) + 1 ] || '_' || i,
    (ARRAY[
        'Amoxicillin','Carprofen','Metronidazole','Fenbendazole',
        'Ivermectin','Doxycycline','Tramadol Hydrochloride',
        'Gabapentin','Prednisolone','Furosemide'
    ])[ (i % 10) + 1 ],
    (ARRAY['mg','ml','Tablet','Capsule','mg/kg'])[ (i % 5) + 1 ],
    '2025-06-01'::date + (i * 13 % 1095)
FROM generate_series(1, 200) AS i
ON CONFLICT (MedID) DO NOTHING;

-- ── 4. VACCINATION  (200 rows) ────────────────────────────
INSERT INTO Vaccination (VacID, Name, Manufacturer, FrequencyMonths, StorageTemp)
SELECT
    i,
    (ARRAY[
        'Rabies Vaccine','Distemper','Parvovirus','Hepatitis',
        'Leptospirosis','Bordetella','Influenza','Tetanus',
        'FeLV','FIV','Panleukopenia','Calicivirus','Herpesvirus'
    ])[ (i % 13) + 1 ] || ' v' || i,
    (ARRAY[
        'Zoetis','Merck Animal Health','Elanco','Boehringer',
        'Virbac','Ceva','Merial','Fort Dodge'
    ])[ (i % 8) + 1 ],
    (ARRAY[6, 12, 24, 36])[ (i % 4) + 1 ],
    (ARRAY['2°C – 8°C','−20°C','4°C','Room temp'])[ (i % 4) + 1 ]
FROM generate_series(1, 200) AS i
ON CONFLICT (VacID) DO NOTHING;

-- ── 5. MEDICALVISIT  (5 000 rows) ─────────────────────────
-- AnimalID: 1-200  |  VetID: 1-1000
INSERT INTO MedicalVisit (VisitID, VisitDate, Reason, Summary, Cost, AnimalID, VetID)
SELECT
    i,
    '2020-01-01'::date + (i * 3 % 1800),
    (ARRAY[
        'Annual checkup','Injury treatment','Vaccination',
        'Follow-up visit','Emergency consultation','Dental exam',
        'Pre-surgery evaluation','Post-surgery care',
        'Parasite control','Nutritional consultation'
    ])[ (i % 10) + 1 ],
    'Visit summary for record ' || i,
    ROUND((50 + (i * 17.3) % 1950)::numeric, 2),
    (i % 200) + 1,
    (i % 1000) + 1
FROM generate_series(1, 5000) AS i
ON CONFLICT (VisitID) DO NOTHING;

-- ── 6. JUNCTION: Mirsham_Visit_Treatment ──────────────────
INSERT INTO Mirsham_Visit_Treatment (VisitID, TreatmentID)
SELECT DISTINCT
    (i % 5000) + 1,
    (i % 200)  + 1
FROM generate_series(1, 3000) AS i
ON CONFLICT DO NOTHING;

-- ── 7. JUNCTION: Hergel_Treatment_Medication ──────────────
INSERT INTO Hergel_Treatment_Medication (TreatmentID, MedID)
SELECT DISTINCT
    (i % 200) + 1,
    ((i * 3) % 200) + 1
FROM generate_series(1, 500) AS i
ON CONFLICT DO NOTHING;

-- ── 8. JUNCTION: Treatment_Vaccination ────────────────────
INSERT INTO Treatment_Vaccination (TreatmentID, VacID)
SELECT DISTINCT
    (i % 200) + 1,
    ((i * 5) % 200) + 1
FROM generate_series(1, 400) AS i
ON CONFLICT DO NOTHING;

-- Done!
SELECT 'Seed complete' AS status,
       (SELECT COUNT(*) FROM animal)       AS animals,
       (SELECT COUNT(*) FROM treatment)    AS treatments,
       (SELECT COUNT(*) FROM medication)   AS medications,
       (SELECT COUNT(*) FROM vaccination)  AS vaccinations,
       (SELECT COUNT(*) FROM medicalvisit) AS visits;
