"""
db.py – Database Access Layer for VetCare Management System (Stage 5)
=====================================================================
All SQL queries and database operations are centralized here.
Foreign keys are resolved using JOINs so the UI never shows raw IDs.

Team: Avinoam Muller (347465932), Guedalia Sebbah (337966659)
"""

import os
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

# ── Load .env from project root (handles any working-directory) ───────
_THIS_DIR = os.path.dirname(os.path.abspath(__file__))   # always Shlav5/
_PROJECT_ROOT = os.path.abspath(os.path.join(_THIS_DIR, ".."))
load_dotenv(os.path.join(_PROJECT_ROOT, ".env"))

# ── Connection configuration (can be overridden at runtime via DB_CONFIG) ──
DB_CONFIG = {
    "host":     os.getenv("DB_HOST",           "localhost"),
    "port":     int(os.getenv("DB_PORT",       "5432")),
    "dbname":   os.getenv("DB_NAME_SECRET",    "basnat"),
    "user":     os.getenv("DB_USER_SECRET",    "admin"),
    "password": os.getenv("DB_PASSWORD_SECRET","password"),
}


def get_connection():
    """Return a new psycopg2 connection using current DB_CONFIG."""
    return psycopg2.connect(**DB_CONFIG)


def test_connection():
    """Try to connect and return (True, None) or (False, error_msg)."""
    try:
        conn = get_connection()
        conn.close()
        return True, None
    except Exception as e:
        return False, str(e)


def _fetch_all(query, params=None):
    """Execute a SELECT and return (column_names, rows)."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(query, params)
            cols = [desc[0] for desc in cur.description]
            rows = cur.fetchall()
        return cols, rows
    finally:
        conn.close()


def _fetch_one(query, params=None):
    """Execute a SELECT and return a single row dict or None."""
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(query, params)
            return cur.fetchone()
    finally:
        conn.close()


def _execute(query, params=None):
    """Execute an INSERT / UPDATE / DELETE and commit."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(query, params)
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# =====================================================================
#  ANIMAL  –  CRUD
# =====================================================================

def fetch_animals():
    q = """
        SELECT animalid, name, species, birthdate, gender, weight,
               COALESCE(total_visits, 0), last_visit_date
        FROM animal
        ORDER BY animalid
    """
    return _fetch_all(q)


def fetch_animal_by_id(animal_id):
    q = "SELECT * FROM animal WHERE animalid = %s"
    return _fetch_one(q, (animal_id,))


def insert_animal(animalid, name, species, birthdate, gender, weight):
    q = """
        INSERT INTO animal (animalid, name, species, birthdate, gender, weight)
        VALUES (%s, %s, %s, %s, %s, %s)
    """
    _execute(q, (animalid, name, species, birthdate or None, gender, weight or None))


def update_animal(animalid, name, species, birthdate, gender, weight):
    q = """
        UPDATE animal
        SET name=%s, species=%s, birthdate=%s, gender=%s, weight=%s
        WHERE animalid=%s
    """
    _execute(q, (name, species, birthdate or None, gender, weight or None, animalid))


def delete_animal(animalid):
    _execute("DELETE FROM animal WHERE animalid = %s", (animalid,))


# =====================================================================
#  VETERINARIAN  –  CRUD
# =====================================================================

def fetch_veterinarians():
    q = """
        SELECT v.vetid,
               v.firstname,
               v.lastname,
               v.licensenumber,
               COALESCE(v.specialization, '—') AS specialization,
               v.hiredate,
               COALESCE(e.first_name || ' ' || e.last_name, '—') AS employee_name
        FROM veterinarian v
        LEFT JOIN employee e ON v.employee_id = e.employee_id
        ORDER BY v.vetid
    """
    return _fetch_all(q)


def fetch_vet_by_id(vetid):
    q = "SELECT * FROM veterinarian WHERE vetid = %s"
    return _fetch_one(q, (vetid,))


def insert_vet(vetid, firstname, lastname, licensenumber, specialization, hiredate):
    q = """
        INSERT INTO veterinarian (vetid, firstname, lastname, licensenumber,
                                  specialization, hiredate)
        VALUES (%s, %s, %s, %s, %s, %s)
    """
    _execute(q, (vetid, firstname, lastname, licensenumber, specialization, hiredate or None))


def update_vet(vetid, firstname, lastname, licensenumber, specialization, hiredate):
    q = """
        UPDATE veterinarian
        SET firstname=%s, lastname=%s, licensenumber=%s,
            specialization=%s, hiredate=%s
        WHERE vetid=%s
    """
    _execute(q, (firstname, lastname, licensenumber, specialization, hiredate or None, vetid))


def delete_vet(vetid):
    _execute("DELETE FROM veterinarian WHERE vetid = %s", (vetid,))


# =====================================================================
#  MEDICAL VISIT  –  CRUD  (FK hidden: Animal Name + Vet Full Name)
# =====================================================================

def fetch_visits():
    q = """
        SELECT mv.visitid,
               mv.visitdate,
               a.name                              AS animal_name,
               v.firstname || ' ' || v.lastname    AS vet_name,
               mv.reason,
               LEFT(COALESCE(mv.summary, ''), 40)  AS summary,
               mv.cost,
               COALESCE(mv.status, 'Completed')    AS status
        FROM medicalvisit mv
        JOIN animal a        ON mv.animalid = a.animalid
        JOIN veterinarian v  ON mv.vetid    = v.vetid
        ORDER BY mv.visitid
    """
    return _fetch_all(q)


def fetch_visit_by_id(visitid):
    q = """
        SELECT mv.*,
               a.name                           AS animal_name,
               v.firstname || ' ' || v.lastname AS vet_name
        FROM medicalvisit mv
        JOIN animal a        ON mv.animalid = a.animalid
        JOIN veterinarian v  ON mv.vetid    = v.vetid
        WHERE mv.visitid = %s
    """
    return _fetch_one(q, (visitid,))


def insert_visit(visitid, visitdate, reason, summary, cost, animalid, vetid, status):
    q = """
        INSERT INTO medicalvisit (visitid, visitdate, reason, summary, cost,
                                  animalid, vetid, status)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """
    _execute(q, (visitid, visitdate or None, reason, summary,
                 cost or None, animalid, vetid, status or 'Completed'))


def update_visit(visitid, visitdate, reason, summary, cost, animalid, vetid, status):
    q = """
        UPDATE medicalvisit
        SET visitdate=%s, reason=%s, summary=%s, cost=%s,
            animalid=%s, vetid=%s, status=%s, last_updated=NOW()
        WHERE visitid=%s
    """
    _execute(q, (visitdate or None, reason, summary,
                 cost or None, animalid, vetid,
                 status or 'Completed', visitid))


def delete_visit(visitid):
    _execute("DELETE FROM medicalvisit WHERE visitid = %s", (visitid,))


# ── FK Dropdown helpers ───────────────────────────────────────────────

def get_animal_options():
    cols, rows = _fetch_all(
        "SELECT animalid, name, species FROM animal ORDER BY name")
    return [(r[0], f"{r[1]} ({r[2]})") for r in rows]


def get_vet_options():
    cols, rows = _fetch_all(
        "SELECT vetid, firstname || ' ' || lastname FROM veterinarian ORDER BY lastname")
    return [(r[0], r[1]) for r in rows]


# =====================================================================
#  TREATMENT  –  CRUD
# =====================================================================

def fetch_treatments():
    q = """
        SELECT treatmentid, description, COALESCE(duration,'—'), 
               COALESCE(type,'—'), COALESCE(severity,'—')
        FROM treatment ORDER BY treatmentid
    """
    return _fetch_all(q)


def fetch_treatment_by_id(tid):
    return _fetch_one("SELECT * FROM treatment WHERE treatmentid = %s", (tid,))


def insert_treatment(tid, description, duration, ttype, severity):
    q = """INSERT INTO treatment (treatmentid, description, duration, type, severity)
           VALUES (%s, %s, %s, %s, %s)"""
    _execute(q, (tid, description, duration, ttype, severity))


def update_treatment(tid, description, duration, ttype, severity):
    q = """UPDATE treatment SET description=%s, duration=%s, type=%s, severity=%s
           WHERE treatmentid=%s"""
    _execute(q, (description, duration, ttype, severity, tid))


def delete_treatment(tid):
    _execute("DELETE FROM treatment WHERE treatmentid = %s", (tid,))


# =====================================================================
#  MEDICATION  –  CRUD
# =====================================================================

def fetch_medications():
    q = """
        SELECT medid, commercialname, COALESCE(activeingredient,'—'),
               COALESCE(dosageunit,'—'), expirationdate
        FROM medication ORDER BY medid
    """
    return _fetch_all(q)


def fetch_medication_by_id(mid):
    return _fetch_one("SELECT * FROM medication WHERE medid = %s", (mid,))


def insert_medication(mid, commercialname, activeingredient, dosageunit, expirationdate):
    q = """INSERT INTO medication (medid, commercialname, activeingredient,
                                   dosageunit, expirationdate)
           VALUES (%s, %s, %s, %s, %s)"""
    _execute(q, (mid, commercialname, activeingredient, dosageunit, expirationdate or None))


def update_medication(mid, commercialname, activeingredient, dosageunit, expirationdate):
    q = """UPDATE medication SET commercialname=%s, activeingredient=%s,
                                 dosageunit=%s, expirationdate=%s
           WHERE medid=%s"""
    _execute(q, (commercialname, activeingredient, dosageunit, expirationdate or None, mid))


def delete_medication(mid):
    _execute("DELETE FROM medication WHERE medid = %s", (mid,))


# =====================================================================
#  VACCINATION  –  CRUD
# =====================================================================

def fetch_vaccinations():
    q = """
        SELECT vacid, name, COALESCE(manufacturer,'—'),
               COALESCE(frequencymonths,0), COALESCE(storagetemp,'—')
        FROM vaccination ORDER BY vacid
    """
    return _fetch_all(q)


def fetch_vaccination_by_id(vid):
    return _fetch_one("SELECT * FROM vaccination WHERE vacid = %s", (vid,))


def insert_vaccination(vid, name, manufacturer, frequencymonths, storagetemp):
    q = """INSERT INTO vaccination (vacid, name, manufacturer, frequencymonths, storagetemp)
           VALUES (%s, %s, %s, %s, %s)"""
    _execute(q, (vid, name, manufacturer, frequencymonths or None, storagetemp))


def update_vaccination(vid, name, manufacturer, frequencymonths, storagetemp):
    q = """UPDATE vaccination SET name=%s, manufacturer=%s,
                                  frequencymonths=%s, storagetemp=%s
           WHERE vacid=%s"""
    _execute(q, (name, manufacturer, frequencymonths or None, storagetemp, vid))


def delete_vaccination(vid):
    _execute("DELETE FROM vaccination WHERE vacid = %s", (vid,))


# =====================================================================
#  ADVANCED  –  Stage 2 Queries
# =====================================================================

def query_top10_most_visited_animals():
    q = """
        SELECT
            a.animalid,
            a.name                              AS animal_name,
            a.species,
            a.gender,
            a.weight                            AS weight_kg,
            EXTRACT(YEAR FROM AGE(a.birthdate)) AS age_years,
            COUNT(mv.visitid)                   AS total_visits,
            MAX(mv.visitdate)                   AS last_visit,
            ROUND(SUM(mv.cost), 2)              AS total_cost,
            ROUND(AVG(mv.cost), 2)              AS avg_cost
        FROM animal a
        JOIN medicalvisit mv ON a.animalid = mv.animalid
        GROUP BY a.animalid, a.name, a.species, a.gender, a.weight, a.birthdate
        ORDER BY total_visits DESC
        LIMIT 10
    """
    return _fetch_all(q)


def query_monthly_revenue_by_specialization():
    q = """
        WITH MonthlyRevenue AS (
            SELECT
                EXTRACT(YEAR  FROM mv.visitdate) AS visit_year,
                EXTRACT(MONTH FROM mv.visitdate) AS visit_month,
                v.specialization,
                ROUND(SUM(mv.cost), 2)           AS total_revenue,
                COUNT(mv.visitid)                AS visit_count,
                ROUND(AVG(mv.cost), 2)           AS avg_cost
            FROM medicalvisit mv
            JOIN veterinarian v ON mv.vetid = v.vetid
            GROUP BY EXTRACT(YEAR FROM mv.visitdate),
                     EXTRACT(MONTH FROM mv.visitdate),
                     v.specialization
        )
        SELECT visit_year, visit_month, specialization,
               total_revenue, visit_count, avg_cost
        FROM MonthlyRevenue
        ORDER BY visit_year DESC, visit_month, total_revenue DESC
    """
    return _fetch_all(q)


# =====================================================================
#  ADVANCED  –  Stage 4 PL/pgSQL
# =====================================================================

def call_animal_medical_summary(animal_id):
    q = "SELECT * FROM fn_get_animal_medical_summary(%s)"
    return _fetch_one(q, (animal_id,))


def call_transfer_vet_visits(from_vet_id, to_vet_id):
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("CALL sp_transfer_animal_visits(%s, %s)",
                        (from_vet_id, to_vet_id))
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
