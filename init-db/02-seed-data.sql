-- ============================================================
-- 02-seed-data.sql
-- Veterinary Clinic Database — Sample Data
-- ============================================================

BEGIN;

-- ============================================================
-- 1. VETERINARIANS  (50 records)
-- ============================================================
INSERT INTO Veterinarian (VetID, FirstName, LastName, LicenseNumber, Specialization, HireDate) VALUES
( 1, 'Guedalia',  'Betsalel',   'VET-99001-IL', 'Senior Surgeon',    '2020-01-15'),
( 2, 'Sarah',     'Levi',       'VET-10002-NY', 'Exotic Animals',    '2021-03-22'),
( 3, 'David',     'Cohen',      'VET-10003-FR', 'General Practice',  '2019-11-10'),
( 4, 'Maya',      'Rosen',      'VET-10004-IL', 'Radiology',         '2022-05-01'),
( 5, 'Daniel',    'Katz',       'VET-10005-US', 'Dentistry',         '2023-01-12'),
( 6, 'Noa',       'Mizrahi',    'VET-10006-IL', 'Internal Medicine', '2018-07-20'),
( 7, 'Yosef',     'Avraham',    'VET-10007-UK', 'Orthopedics',       '2020-09-05'),
( 8, 'Tamar',     'Ben-David',  'VET-10008-DE', 'Cardiology',        '2021-11-18'),
( 9, 'Eitan',     'Shapira',    'VET-10009-CA', 'Dermatology',       '2017-04-03'),
(10, 'Michal',    'Goldstein',  'VET-10010-AU', 'Neurology',         '2022-02-28'),
(11, 'Oren',      'Peretz',     'VET-10011-IL', 'Ophthalmology',     '2019-06-14'),
(12, 'Shira',     'Azulay',     'VET-10012-FR', 'Emergency Care',    '2023-08-09'),
(13, 'Amir',      'Dahan',      'VET-10013-US', 'Anesthesiology',    '2020-12-01'),
(14, 'Yael',      'Biton',      'VET-10014-IL', 'Pathology',         '2018-03-25'),
(15, 'Itay',      'Nachmani',   'VET-10015-UK', 'Oncology',          '2021-07-11'),
(16, 'Liat',      'Edri',       'VET-10016-DE', 'General Practice',  '2019-10-07'),
(17, 'Gil',       'Ohana',      'VET-10017-CA', 'Surgery',           '2022-04-19'),
(18, 'Ronit',     'Sarusi',     'VET-10018-AU', 'Exotic Animals',    '2020-08-30'),
(19, 'Nadav',     'Shalom',     'VET-10019-IL', 'Radiology',         '2017-01-22'),
(20, 'Hadas',     'Malka',      'VET-10020-FR', 'Internal Medicine', '2023-05-16'),
(21, 'Tomer',     'Gabai',      'VET-10021-US', 'Dentistry',         '2018-09-12'),
(22, 'Efrat',     'Elbaz',      'VET-10022-IL', 'Orthopedics',       '2021-02-04'),
(23, 'Boaz',      'Pinto',      'VET-10023-UK', 'Cardiology',        '2019-12-28'),
(24, 'Keren',     'Hadad',      'VET-10024-DE', 'Dermatology',       '2022-06-08'),
(25, 'Shai',      'Amar',       'VET-10025-CA', 'Neurology',         '2020-03-17'),
(26, 'Dana',      'Vaknin',     'VET-10026-AU', 'Ophthalmology',     '2023-10-23'),
(27, 'Ran',       'Assayag',    'VET-10027-IL', 'Emergency Care',    '2018-05-09'),
(28, 'Inbar',     'Harush',     'VET-10028-FR', 'Anesthesiology',    '2021-08-15'),
(29, 'Omri',      'Almog',      'VET-10029-US', 'Pathology',         '2019-01-30'),
(30, 'Tal',       'Buskila',    'VET-10030-IL', 'Oncology',          '2022-11-06'),
(31, 'Ariel',     'Revivo',     'VET-10031-UK', 'General Practice',  '2020-06-22'),
(32, 'Lihi',      'Suissa',     'VET-10032-DE', 'Surgery',           '2017-08-18'),
(33, 'Nir',       'Tubul',      'VET-10033-CA', 'Exotic Animals',    '2023-03-04'),
(34, 'Sapir',     'Yossef',     'VET-10034-AU', 'Radiology',         '2019-07-27'),
(35, 'Matan',     'Afriat',     'VET-10035-IL', 'Internal Medicine', '2021-12-13'),
(36, 'Roni',      'Ben-Haim',   'VET-10036-FR', 'Dentistry',         '2018-11-01'),
(37, 'Asaf',      'Swissa',     'VET-10037-US', 'Orthopedics',       '2022-07-25'),
(38, 'Shani',     'Dayan',      'VET-10038-IL', 'Cardiology',        '2020-04-10'),
(39, 'Ori',       'Lugasi',     'VET-10039-UK', 'Dermatology',       '2017-10-06'),
(40, 'Neta',      'Zaguri',     'VET-10040-DE', 'Neurology',         '2023-01-29'),
(41, 'Ido',       'Torjman',    'VET-10041-CA', 'Ophthalmology',     '2019-05-15'),
(42, 'Mor',       'Sabag',      'VET-10042-AU', 'Emergency Care',    '2021-09-21'),
(43, 'Yuval',     'Hajaj',      'VET-10043-IL', 'Anesthesiology',    '2018-02-07'),
(44, 'Lee',       'Baranes',    'VET-10044-FR', 'Pathology',         '2022-08-13'),
(45, 'Ofir',      'Chriqui',    'VET-10045-US', 'Oncology',          '2020-11-28'),
(46, 'Amit',      'Ben-Shlomo', 'VET-10046-IL', 'General Practice',  '2017-06-03'),
(47, 'Chen',      'Atias',      'VET-10047-UK', 'Surgery',           '2023-09-17'),
(48, 'Rotem',     'Ozeri',      'VET-10048-DE', 'Exotic Animals',    '2019-04-22'),
(49, 'Maor',      'Abutbul',    'VET-10049-CA', 'Radiology',         '2021-10-09'),
(50, 'Avital',    'Marciano',   'VET-10050-AU', 'Internal Medicine', '2022-03-14');

-- ============================================================
-- 2. ANIMALS  (500 records)
-- ============================================================
INSERT INTO Animal (AnimalID, Name, Species, BirthDate, Gender, Weight)
SELECT
    i,
    (ARRAY[
        'Simba','Nala','Rex','Bella','Milo','Luna','Zeus','Cleo',
        'Rocky','Daisy','Bruno','Kira','Max','Zoe','Leo','Ruby',
        'Duke','Stella','Finn','Rosie','Oscar','Penny','Thor','Ivy',
        'Gus','Lola','Jake','Olive','Bear','Willow'
    ])[ (i % 30) + 1 ] || '_' || i,
    (ARRAY['Lion','Tiger','Elephant','Giraffe','Zebra','Panda','Wolf',
           'Eagle','Dolphin','Bear','Snake','Parrot','Monkey','Deer',
           'Fox','Turtle','Owl','Penguin','Koala','Kangaroo'])[ (i % 20) + 1 ],
    '2015-01-01'::date + (random() * (365 * 10))::int,
    (ARRAY['Male','Female','Unknown'])[ (i % 3) + 1 ],
    CASE WHEN random() > 0.1
         THEN round((random() * 300 + 5)::numeric, 2)
         ELSE NULL
    END
FROM generate_series(1, 500) AS i;

-- ============================================================
-- 3. TREATMENTS  (20 records)
-- ============================================================
INSERT INTO Treatment (TreatmentID, Description, Duration, Type, Severity) VALUES
( 1, 'Annual Physical Checkup',       '30 mins',  'Routine',     'Low'),
( 2, 'Emergency Surgery',             '2 hours',  'Surgical',    'High'),
( 3, 'Dental Scaling',                '45 mins',  'Dental',      'Medium'),
( 4, 'X-Ray Scan',                    '20 mins',  'Diagnostic',  'Medium'),
( 5, 'Vaccination Protocol',          '10 mins',  'Preventive',  'Low'),
( 6, 'Blood Panel Analysis',          '15 mins',  'Diagnostic',  'Low'),
( 7, 'Wound Suturing',                '40 mins',  'Surgical',    'Medium'),
( 8, 'Parasite Treatment',            '20 mins',  'Preventive',  'Low'),
( 9, 'MRI Scan',                      '1 hour',   'Diagnostic',  'High'),
(10, 'Ultrasound Imaging',            '30 mins',  'Diagnostic',  'Medium'),
(11, 'Fluid Therapy',                 '2 hours',  'Supportive',  'Medium'),
(12, 'Fracture Repair',               '3 hours',  'Surgical',    'High'),
(13, 'Skin Biopsy',                   '25 mins',  'Diagnostic',  'Medium'),
(14, 'Eye Examination',               '15 mins',  'Routine',     'Low'),
(15, 'Ear Cleaning & Treatment',      '20 mins',  'Routine',     'Low'),
(16, 'Chemotherapy Session',          '4 hours',  'Oncology',    'High'),
(17, 'Physical Rehabilitation',       '1 hour',   'Supportive',  'Medium'),
(18, 'Spay / Neuter Surgery',         '1.5 hours','Surgical',    'Medium'),
(19, 'Allergy Testing',               '30 mins',  'Diagnostic',  'Low'),
(20, 'Emergency Poison Treatment',    '1 hour',   'Emergency',   'High');

-- ============================================================
-- 4. MEDICATIONS  (20 records)
-- ============================================================
INSERT INTO Medication (MedID, CommercialName, ActiveIngredient, DosageUnit, ExpirationDate) VALUES
( 1, 'Amoxi-Drop',       'Amoxicillin',          'ml',       '2027-05-12'),
( 2, 'Rimadyl',          'Carprofen',             'mg',       '2026-11-30'),
( 3, 'Advantage Multi',  'Imidacloprid',          'Pipette',  '2028-01-15'),
( 4, 'Metacam',          'Meloxicam',             'mg/ml',    '2026-08-22'),
( 5, 'Bravecto',         'Fluralaner',            'Tablet',   '2027-12-01'),
( 6, 'Clavamox',         'Amoxicillin-Clavulanate','ml',      '2027-09-10'),
( 7, 'Dexamethasone Inj','Dexamethasone',         'mg/ml',    '2026-12-15'),
( 8, 'Cerenia',          'Maropitant Citrate',    'mg',       '2027-03-28'),
( 9, 'Gabapentin Cap',   'Gabapentin',            'mg',       '2028-06-01'),
(10, 'Tramadol Tab',     'Tramadol HCl',          'mg',       '2027-07-19'),
(11, 'Onsior',           'Robenacoxib',           'mg',       '2027-11-05'),
(12, 'Prednisolone Oral','Prednisolone',          'mg',       '2026-10-20'),
(13, 'Fortiflora',       'Enterococcus faecium',  'Sachet',   '2027-04-14'),
(14, 'Convenia Inj',     'Cefovecin Sodium',      'mg/ml',    '2026-09-30'),
(15, 'Apoquel',          'Oclacitinib',           'mg',       '2028-02-22'),
(16, 'Simparica',        'Sarolaner',             'mg',       '2027-08-07'),
(17, 'Metronidazole Tab','Metronidazole',         'mg',       '2027-01-18'),
(18, 'Furosemide Inj',   'Furosemide',            'mg/ml',    '2026-07-25'),
(19, 'Cytopoint Inj',    'Lokivetmab',            'mg/ml',    '2028-04-11'),
(20, 'Vetmedin',         'Pimobendan',            'mg',       '2027-10-03');

-- ============================================================
-- 5. VACCINATIONS  (10 records)
-- ============================================================
INSERT INTO Vaccination (VacID, Name, Manufacturer, FrequencyMonths, StorageTemp) VALUES
( 1, 'Rabies v2',             'Zoetis',      36, '4°C'),
( 2, 'Distemper Combo',       'Merck',       12, '5°C'),
( 3, 'Feline Leukemia',      'Boehringer',  12, '4°C'),
( 4, 'Bordetella Oral',       'Elanco',       6, '2°C'),
( 5, 'Parvovirus Guard',     'Virbac',      12, '4°C'),
( 6, 'Leptospirosis 4-Way',  'Zoetis',      12, '3°C'),
( 7, 'Canine Influenza H3N2','Merck',       12, '5°C'),
( 8, 'Equine Tetanus',       'Boehringer',  12, '4°C'),
( 9, 'Avian Polyoma',        'Biomune',      6, '4°C'),
(10, 'West Nile Virus',      'Merial',      12, '3°C');

-- ============================================================
-- 6. MEDICAL VISITS  (200 records linking Animals ↔ Veterinarians)
-- ============================================================
INSERT INTO MedicalVisit (VisitID, VisitDate, Reason, Summary, Cost, AnimalID, VetID)
SELECT
    i,
    '2024-01-01'::date + (random() * 365)::int,
    (ARRAY[
        'Routine annual checkup',
        'Emergency — trauma / injury',
        'Vaccination booster',
        'Skin rash / allergic reaction',
        'Digestive issues',
        'Post-surgery follow-up',
        'Dental cleaning scheduled',
        'Eye infection',
        'Difficulty breathing',
        'Parasite detected'
    ])[ (i % 10) + 1 ],
    CASE WHEN random() > 0.15
         THEN (ARRAY[
            'Standard clinical observation performed.',
            'Patient stable, treatment ongoing.',
            'Lab results pending. Follow-up in 2 weeks.',
            'Significant improvement noted since last visit.',
            'Administered prescribed medications successfully.'
         ])[ (i % 5) + 1 ]
         ELSE NULL
    END,
    round((random() * 800 + 50)::numeric, 2),
    (i % 500) + 1,         -- AnimalID  (1..500)
    (i % 50)  + 1          -- VetID     (1..50)
FROM generate_series(1, 200) AS i;

-- ============================================================
-- 7. JUNCTION TABLES  (M:M relationships)
-- ============================================================

-- 7a. Mirsham — Visits ↔ Treatments  (~300 links)
INSERT INTO Mirsham_Visit_Treatment (VisitID, TreatmentID)
SELECT DISTINCT
    (i % 200) + 1,          -- VisitID   (1..200)
    (i % 20)  + 1           -- TreatmentID (1..20)
FROM generate_series(1, 400) AS i
ON CONFLICT DO NOTHING;

-- 7b. Hergel — Treatments ↔ Medications  (explicit rows)
INSERT INTO Hergel_Treatment_Medication (TreatmentID, MedID) VALUES
( 1,  6),  -- Checkup   → Clavamox
( 2,  1),  -- Surgery   → Amoxi-Drop
( 2,  2),  -- Surgery   → Rimadyl
( 2, 10),  -- Surgery   → Tramadol
( 3,  4),  -- Dental    → Metacam
( 6,  7),  -- Blood     → Dexamethasone
( 7,  1),  -- Wound     → Amoxi-Drop
( 7, 10),  -- Wound     → Tramadol
( 8,  3),  -- Parasite  → Advantage Multi
( 8, 16),  -- Parasite  → Simparica
( 9,  9),  -- MRI       → Gabapentin (sedation)
(11, 18),  -- Fluid Therapy → Furosemide
(12,  2),  -- Fracture  → Rimadyl
(12, 10),  -- Fracture  → Tramadol
(13, 12),  -- Biopsy    → Prednisolone
(15, 14),  -- Ear       → Convenia
(16,  7),  -- Chemo     → Dexamethasone
(16, 12),  -- Chemo     → Prednisolone
(17,  4),  -- Rehab     → Metacam
(18,  1),  -- Spay      → Amoxi-Drop
(18,  2),  -- Spay      → Rimadyl
(19, 15),  -- Allergy   → Apoquel
(19, 19),  -- Allergy   → Cytopoint
(20,  8),  -- Poison    → Cerenia
(20, 13);  -- Poison    → Fortiflora

-- 7c. Treatment ↔ Vaccination  (explicit rows)
INSERT INTO Treatment_Vaccination (TreatmentID, VacID) VALUES
( 1,  4),  -- Checkup       → Bordetella
( 5,  1),  -- Vac Protocol  → Rabies
( 5,  2),  -- Vac Protocol  → Distemper
( 5,  3),  -- Vac Protocol  → Feline Leukemia
( 5,  5),  -- Vac Protocol  → Parvovirus
( 5,  6),  -- Vac Protocol  → Leptospirosis
( 5,  7),  -- Vac Protocol  → Canine Influenza
( 8,  4),  -- Parasite      → Bordetella (combo)
(14,  9),  -- Eye Exam      → Avian Polyoma (exotic)
(20, 10);  -- Poison        → West Nile (prophylactic)

COMMIT;