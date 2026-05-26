# ============================================================
# trips.py  –  Trip CRUD screen
# ============================================================
from base_crud import BaseCRUDScreen, FormField


class TripsScreen(BaseCRUDScreen):
    TABLE  = "guidedtour"
    PK     = "tripid"
    TITLE  = "Trip Management"
    ICON   = "✈️"

    LIST_QUERY = """
        SELECT t.TripID,
               r.Name                                AS routename,
               g.FirstName || ' ' || g.LastName      AS guidename,
               TO_CHAR(t.StartDate,'YYYY-MM-DD')     AS startdate,
               TO_CHAR(t.EndDate,'YYYY-MM-DD')       AS enddate,
               t.MaxParticipants,
               COALESCE(t.CurrentBookings,0)         AS currentbookings,
               t.Price,
               ts.StatusName                         AS statusname
        FROM GUIDEDTOUR t
        JOIN ROUTE r           ON t.RouteID      = r.RouteID
        JOIN GUIDE g           ON t.GuideID      = g.GuideID
        LEFT JOIN TOURSTATUS ts ON t.TourStatusID = ts.TourStatusID
        ORDER BY t.TripID
    """
    LIST_COLS = [
        ("routename",        "Route",          180),
        ("guidename",        "Guide",          160),
        ("startdate",        "Start Date",     110),
        ("enddate",          "End Date",       110),
        ("maxparticipants",  "Max Cap",         80),
        ("currentbookings",  "Booked",          70),
        ("price",            "Price ₪",         90),
        ("statusname",       "Status",         140),
    ]
    FORM_FIELDS = [
        FormField("Route", "routeid", kind="combo",
                  fk_query="SELECT RouteID, Name FROM ROUTE ORDER BY Name",
                  fk_id_col="routeid", fk_lbl_col="name"),
        FormField("Guide", "guideid", kind="combo",
                  fk_query="SELECT GuideID, FirstName||' '||LastName AS name FROM GUIDE ORDER BY name",
                  fk_id_col="guideid", fk_lbl_col="name"),
        FormField("Start Date (YYYY-MM-DD)",  "startdate"),
        FormField("End Date (YYYY-MM-DD)",    "enddate"),
        FormField("Start Time (HH:MM)",       "starttime"),
        FormField("End Time (HH:MM)",         "endtime"),
        FormField("Max Participants",         "maxparticipants"),
        FormField("Price (₪)",               "price"),
        FormField("Meeting Point",            "meetingpoint"),
        FormField("Notes",                    "notes"),
        FormField("Status", "tourstatusid", kind="combo",
                  fk_query="SELECT TourStatusID, StatusName FROM TOURSTATUS ORDER BY TourStatusID",
                  fk_id_col="tourstatusid", fk_lbl_col="statusname"),
    ]

    INSERT_SQL = """
        INSERT INTO GUIDEDTOUR
            (TripID, RouteID, GuideID, StartDate, EndDate,
             StartTime, EndTime, MaxParticipants, Price,
             MeetingPoint, Notes, TourStatusID, CurrentBookings)
        VALUES (
            (SELECT COALESCE(MAX(TripID),999)+1 FROM GUIDEDTOUR),
            %(routeid)s, %(guideid)s,
            %(startdate)s::DATE,
            NULLIF(%(enddate)s,'')::DATE,
            NULLIF(%(starttime)s,''), NULLIF(%(endtime)s,''),
            %(maxparticipants)s::INT,
            %(price)s::NUMERIC,
            NULLIF(%(meetingpoint)s,''),
            NULLIF(%(notes)s,''),
            %(tourstatusid)s,
            0
        )
    """
    UPDATE_SQL = """
        UPDATE GUIDEDTOUR SET
            RouteID         = %(routeid)s,
            GuideID         = %(guideid)s,
            StartDate       = %(startdate)s::DATE,
            EndDate         = NULLIF(%(enddate)s,'')::DATE,
            StartTime       = NULLIF(%(starttime)s,''),
            EndTime         = NULLIF(%(endtime)s,''),
            MaxParticipants = %(maxparticipants)s::INT,
            Price           = %(price)s::NUMERIC,
            MeetingPoint    = NULLIF(%(meetingpoint)s,''),
            Notes           = NULLIF(%(notes)s,''),
            TourStatusID    = %(tourstatusid)s
        WHERE TripID = %(id)s
    """
    DELETE_SQL = "DELETE FROM GUIDEDTOUR WHERE TripID = %s"
    FETCH_SQL  = """
        SELECT TripID, RouteID AS routeid, GuideID AS guideid,
               TO_CHAR(StartDate,'YYYY-MM-DD') AS startdate,
               TO_CHAR(EndDate,'YYYY-MM-DD')   AS enddate,
               StartTime AS starttime, EndTime AS endtime,
               MaxParticipants AS maxparticipants, Price AS price,
               MeetingPoint AS meetingpoint, Notes AS notes,
               TourStatusID AS tourstatusid
        FROM GUIDEDTOUR WHERE TripID = %s
    """
