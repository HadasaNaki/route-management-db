# ============================================================
# guides.py  –  Guide CRUD screen
# ============================================================
from base_crud import BaseCRUDScreen, FormField


class GuidesScreen(BaseCRUDScreen):
    TABLE  = "guide"
    PK     = "guideid"
    TITLE  = "Guide Management"
    ICON   = "👤"

    LIST_QUERY = """
        SELECT GuideID,
               FirstName || ' ' || LastName AS guidename,
               Phone, Email, Expertise,
               DailyRate, ExperienceYears,
               ROUND(Rating::numeric,2) AS rating
        FROM GUIDE
        ORDER BY GuideID
    """
    LIST_COLS = [
        ("guidename",      "Name",          180),
        ("phone",          "Phone",         130),
        ("email",          "Email",         200),
        ("expertise",      "Expertise",     160),
        ("dailyrate",      "Daily Rate ₪",   100),
        ("experienceyears","Experience Yrs", 110),
        ("rating",         "Rating",         80),
    ]
    FORM_FIELDS = [
        FormField("First Name",      "firstname"),
        FormField("Last Name",       "lastname"),
        FormField("Phone",           "phone"),
        FormField("Email",           "email"),
        FormField("Expertise",       "expertise"),
        FormField("Daily Rate",      "dailyrate"),
        FormField("Experience Yrs",  "experienceyears"),
        FormField("Rating (0–5)",    "rating"),
        FormField("Join Date (YYYY-MM-DD)", "joindate"),
        FormField("Address",         "address"),
    ]

    INSERT_SQL = """
        INSERT INTO GUIDE
            (GuideID, FirstName, LastName, Phone, Email, Expertise,
             DailyRate, ExperienceYears, Rating, JoinDate, Address)
        VALUES (
            (SELECT COALESCE(MAX(GuideID),0)+1 FROM GUIDE),
            %(firstname)s, %(lastname)s, %(phone)s,
            NULLIF(%(email)s,''), NULLIF(%(expertise)s,''),
            NULLIF(%(dailyrate)s,'')::NUMERIC,
            NULLIF(%(experienceyears)s,'')::INT,
            NULLIF(%(rating)s,'')::NUMERIC,
            NULLIF(%(joindate)s,'')::DATE,
            NULLIF(%(address)s,'')
        )
    """
    UPDATE_SQL = """
        UPDATE GUIDE SET
            FirstName       = %(firstname)s,
            LastName        = %(lastname)s,
            Phone           = %(phone)s,
            Email           = NULLIF(%(email)s,''),
            Expertise       = NULLIF(%(expertise)s,''),
            DailyRate       = NULLIF(%(dailyrate)s,'')::NUMERIC,
            ExperienceYears = NULLIF(%(experienceyears)s,'')::INT,
            Rating          = NULLIF(%(rating)s,'')::NUMERIC,
            JoinDate        = NULLIF(%(joindate)s,'')::DATE,
            Address         = NULLIF(%(address)s,'')
        WHERE GuideID = %(id)s
    """
    DELETE_SQL = "DELETE FROM GUIDE WHERE GuideID = %s"
    FETCH_SQL  = """
        SELECT GuideID, FirstName AS firstname, LastName AS lastname,
               Phone, Email, Expertise, DailyRate,
               ExperienceYears, Rating,
               TO_CHAR(JoinDate,'YYYY-MM-DD') AS joindate,
               Address
        FROM GUIDE WHERE GuideID = %s
    """
