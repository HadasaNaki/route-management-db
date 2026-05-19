# ============================================================
# bookings.py  –  Booking CRUD screen
# ============================================================
from base_crud import BaseCRUDScreen, FormField


class BookingsScreen(BaseCRUDScreen):
    TABLE  = "booking"
    PK     = "bookingid"
    TITLE  = "Booking Management"
    ICON   = "📋"

    LIST_QUERY = """
        SELECT b.BookingID,
               p.FullName                              AS participantname,
               r.RouteName,
               TO_CHAR(t.DepartureDate,'YYYY-MM-DD')  AS departuredate,
               TO_CHAR(b.BookingDate,'YYYY-MM-DD')    AS bookingdate,
               b.AmountToPay,
               rs.StatusName                          AS statusname,
               b.Notes
        FROM BOOKING b
        JOIN PARTICIPANT p         ON b.ParticipantID       = p.ParticipantID
        JOIN TRIP t                ON b.TripID               = t.TripID
        JOIN ROUTE r               ON t.RouteID              = r.RouteID
        JOIN REGISTRATIONSTATUS rs ON b.RegistrationStatusID = rs.RegistrationStatusID
        ORDER BY b.BookingID
    """
    LIST_COLS = [
        ("participantname", "Participant",    180),
        ("routename",       "Route",          180),
        ("departuredate",   "Trip Departure", 120),
        ("bookingdate",     "Booking Date",   110),
        ("amounttopay",     "Amount ₪",        90),
        ("statusname",      "Status",         130),
        ("notes",           "Notes",          160),
    ]
    FORM_FIELDS = [
        FormField("Participant", "participantid", kind="combo",
                  fk_query="SELECT ParticipantID, FullName FROM PARTICIPANT ORDER BY FullName",
                  fk_id_col="participantid", fk_lbl_col="fullname"),
        FormField("Trip", "tripid", kind="combo",
                  fk_query="""SELECT t.TripID,
                                     r.RouteName||' ('||TO_CHAR(t.DepartureDate,'DD/MM/YY')||')' AS label
                              FROM TRIP t JOIN ROUTE r ON t.RouteID=r.RouteID
                              ORDER BY t.DepartureDate""",
                  fk_id_col="tripid", fk_lbl_col="label"),
        FormField("Booking Date (YYYY-MM-DD)", "bookingdate"),
        FormField("Amount to Pay (₪)",         "amounttopay"),
        FormField("Notes",                     "notes"),
        FormField("Status", "registrationstatusid", kind="combo",
                  fk_query="SELECT RegistrationStatusID, StatusName FROM REGISTRATIONSTATUS ORDER BY RegistrationStatusID",
                  fk_id_col="registrationstatusid", fk_lbl_col="statusname"),
    ]

    INSERT_SQL = """
        INSERT INTO BOOKING
            (BookingID, BookingDate, TripID, ParticipantID,
             AmountToPay, Notes, RegistrationStatusID)
        VALUES (
            (SELECT COALESCE(MAX(BookingID),0)+1 FROM BOOKING),
            COALESCE(NULLIF(%(bookingdate)s,'')::DATE, CURRENT_DATE),
            %(tripid)s, %(participantid)s,
            NULLIF(%(amounttopay)s,'')::NUMERIC,
            NULLIF(%(notes)s,''),
            %(registrationstatusid)s
        )
    """
    UPDATE_SQL = """
        UPDATE BOOKING SET
            TripID               = %(tripid)s,
            ParticipantID        = %(participantid)s,
            BookingDate          = COALESCE(NULLIF(%(bookingdate)s,'')::DATE, BookingDate),
            AmountToPay          = NULLIF(%(amounttopay)s,'')::NUMERIC,
            Notes                = NULLIF(%(notes)s,''),
            RegistrationStatusID = %(registrationstatusid)s
        WHERE BookingID = %(id)s
    """
    DELETE_SQL = "DELETE FROM BOOKING WHERE BookingID = %s"
    FETCH_SQL  = """
        SELECT BookingID,
               TripID AS tripid, ParticipantID AS participantid,
               TO_CHAR(BookingDate,'YYYY-MM-DD') AS bookingdate,
               AmountToPay AS amounttopay, Notes AS notes,
               RegistrationStatusID AS registrationstatusid
        FROM BOOKING WHERE BookingID = %s
    """
