# ============================================================
# bookings.py  –  Booking CRUD screen
# ============================================================
from base_crud import BaseCRUDScreen, FormField


class BookingsScreen(BaseCRUDScreen):
    TABLE  = "registration"
    PK     = "registrationid"
    TITLE  = "Registration Management"
    ICON   = "📋"

    LIST_QUERY = """
        SELECT b.RegistrationID,
               p.FullName                              AS participantname,
               r.Name                                 AS routename,
               TO_CHAR(t.StartDate,'YYYY-MM-DD')      AS startdate,
               TO_CHAR(b.RegistrationDate,'YYYY-MM-DD') AS registrationdate,
               b.AmountToPay,
               rs.StatusName                          AS statusname,
               b.Notes
        FROM REGISTRATION b
        JOIN PARTICIPANT p         ON b.ParticipantID       = p.ParticipantID
        JOIN GUIDEDTOUR t          ON b.TourID               = t.TripID
        JOIN ROUTE r               ON t.RouteID              = r.RouteID
        JOIN REGISTRATIONSTATUS rs ON b.RegistrationStatusID = rs.RegistrationStatusID
        ORDER BY b.RegistrationID
    """
    LIST_COLS = [
        ("participantname",  "Participant",    180),
        ("routename",        "Route",          180),
        ("startdate",        "Tour Start",     120),
        ("registrationdate", "Reg. Date",      110),
        ("amounttopay",      "Amount ₪",        90),
        ("statusname",       "Status",         130),
        ("notes",            "Notes",          160),
    ]
    FORM_FIELDS = [
        FormField("Participant", "participantid", kind="combo",
                  fk_query="SELECT ParticipantID, FullName FROM PARTICIPANT ORDER BY FullName",
                  fk_id_col="participantid", fk_lbl_col="fullname"),
        FormField("Tour", "tourid", kind="combo",
                  fk_query="""SELECT t.TripID,
                                     r.Name||' ('||TO_CHAR(t.StartDate,'DD/MM/YY')||')' AS label
                              FROM GUIDEDTOUR t JOIN ROUTE r ON t.RouteID=r.RouteID
                              ORDER BY t.StartDate""",
                  fk_id_col="tourid", fk_lbl_col="label"),
        FormField("Registration Date (YYYY-MM-DD)", "registrationdate"),
        FormField("Amount to Pay (₪)",              "amounttopay"),
        FormField("Notes",                          "notes"),
        FormField("Status", "registrationstatusid", kind="combo",
                  fk_query="SELECT RegistrationStatusID, StatusName FROM REGISTRATIONSTATUS ORDER BY RegistrationStatusID",
                  fk_id_col="registrationstatusid", fk_lbl_col="statusname"),
    ]

    INSERT_SQL = """
        INSERT INTO REGISTRATION
            (RegistrationID, RegistrationDate, TourID, ParticipantID,
             AmountToPay, Notes, RegistrationStatusID)
        VALUES (
            (SELECT COALESCE(MAX(RegistrationID),0)+1 FROM REGISTRATION),
            COALESCE(NULLIF(%(registrationdate)s,'')::DATE, CURRENT_DATE),
            %(tourid)s, %(participantid)s,
            NULLIF(%(amounttopay)s,'')::NUMERIC,
            NULLIF(%(notes)s,''),
            %(registrationstatusid)s
        )
    """
    UPDATE_SQL = """
        UPDATE REGISTRATION SET
            TourID               = %(tourid)s,
            ParticipantID        = %(participantid)s,
            RegistrationDate     = COALESCE(NULLIF(%(registrationdate)s,'')::DATE, RegistrationDate),
            AmountToPay          = NULLIF(%(amounttopay)s,'')::NUMERIC,
            Notes                = NULLIF(%(notes)s,''),
            RegistrationStatusID = %(registrationstatusid)s
        WHERE RegistrationID = %(id)s
    """
    DELETE_SQL = "DELETE FROM REGISTRATION WHERE RegistrationID = %s"
    FETCH_SQL  = """
        SELECT RegistrationID,
               TourID AS tourid, ParticipantID AS participantid,
               TO_CHAR(RegistrationDate,'YYYY-MM-DD') AS registrationdate,
               AmountToPay AS amounttopay, Notes AS notes,
               RegistrationStatusID AS registrationstatusid
        FROM REGISTRATION WHERE RegistrationID = %s
    """
