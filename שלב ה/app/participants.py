# ============================================================
# participants.py  –  Participant CRUD screen
# ============================================================
from base_crud import BaseCRUDScreen, FormField


class ParticipantsScreen(BaseCRUDScreen):
    TABLE  = "participant"
    PK     = "participantid"
    TITLE  = "Participant Management"
    ICON   = "👥"

    LIST_QUERY = """
        SELECT ParticipantID, FullName, Email, Phone,
               TO_CHAR(JoinDate, 'YYYY-MM-DD') AS joindate
        FROM PARTICIPANT
        ORDER BY ParticipantID
    """
    LIST_COLS = [
        ("fullname",  "Full Name",   200),
        ("email",     "Email",       220),
        ("phone",     "Phone",       130),
        ("joindate",  "Join Date",   110),
    ]
    FORM_FIELDS = [
        FormField("Full Name",  "fullname"),
        FormField("Email",      "email"),
        FormField("Phone",      "phone"),
        FormField("Join Date (YYYY-MM-DD)", "joindate"),
    ]

    INSERT_SQL = """
        INSERT INTO PARTICIPANT (ParticipantID, FullName, Email, Phone, JoinDate)
        VALUES (
            (SELECT COALESCE(MAX(ParticipantID),0)+1 FROM PARTICIPANT),
            %(fullname)s, %(email)s, %(phone)s,
            NULLIF(%(joindate)s, '')::DATE
        )
    """
    UPDATE_SQL = """
        UPDATE PARTICIPANT SET
            FullName  = %(fullname)s,
            Email     = %(email)s,
            Phone     = %(phone)s,
            JoinDate  = NULLIF(%(joindate)s, '')::DATE
        WHERE ParticipantID = %(id)s
    """
    DELETE_SQL = "DELETE FROM PARTICIPANT WHERE ParticipantID = %s"
    FETCH_SQL  = """
        SELECT ParticipantID, FullName, Email, Phone,
               TO_CHAR(JoinDate, 'YYYY-MM-DD') AS joindate
        FROM PARTICIPANT WHERE ParticipantID = %s
    """
