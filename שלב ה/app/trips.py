# ============================================================
# trips.py  –  Trip CRUD screen
# ============================================================
from base_crud import BaseCRUDScreen, FormField


class TripsScreen(BaseCRUDScreen):
    TABLE  = "trip"
    PK     = "tripid"
    TITLE  = "Trip Management"
    ICON   = "✈️"

    LIST_QUERY = """
        SELECT t.TripID,
               r.RouteName,
               g.FirstName || ' ' || g.LastName AS guidename,
               TO_CHAR(t.DepartureDate,'YYYY-MM-DD')  AS departuredate,
               TO_CHAR(t.EndDate,'YYYY-MM-DD')        AS enddate,
               t.MaxCapacity,
               COALESCE(t.CurrentBookings,0)          AS currentbookings,
               t.Price,
               ts.StatusName                          AS statusname
        FROM TRIP t
        JOIN ROUTE r           ON t.RouteID      = r.RouteID
        JOIN GUIDE g           ON t.GuideID      = g.GuideID
        LEFT JOIN TOURSTATUS ts ON t.TourStatusID = ts.TourStatusID
        ORDER BY t.TripID
    """
    LIST_COLS = [
        ("routename",       "Route",          180),
        ("guidename",       "Guide",          160),
        ("departuredate",   "Departure",      110),
        ("enddate",         "End Date",       110),
        ("maxcapacity",     "Max Cap",         80),
        ("currentbookings", "Booked",          70),
        ("price",           "Price ₪",         90),
        ("statusname",      "Status",         140),
    ]
    FORM_FIELDS = [
        FormField("Route", "routeid", kind="combo",
                  fk_query="SELECT RouteID, RouteName FROM ROUTE ORDER BY RouteName",
                  fk_id_col="routeid", fk_lbl_col="routename"),
        FormField("Guide", "guideid", kind="combo",
                  fk_query="SELECT GuideID, FirstName||' '||LastName AS name FROM GUIDE ORDER BY name",
                  fk_id_col="guideid", fk_lbl_col="name"),
        FormField("Departure Date (YYYY-MM-DD)", "departuredate"),
        FormField("End Date (YYYY-MM-DD)",        "enddate"),
        FormField("Start Time (HH:MM)",           "starttime"),
        FormField("End Time (HH:MM)",             "endtime"),
        FormField("Max Capacity",                 "maxcapacity"),
        FormField("Price (₪)",                    "price"),
        FormField("Meeting Point",                "meetingpoint"),
        FormField("Notes",                        "notes"),
        FormField("Status", "tourstatusid", kind="combo",
                  fk_query="SELECT TourStatusID, StatusName FROM TOURSTATUS ORDER BY TourStatusID",
                  fk_id_col="tourstatusid", fk_lbl_col="statusname"),
    ]

    INSERT_SQL = """
        INSERT INTO TRIP
            (TripID, RouteID, GuideID, DepartureDate, EndDate,
             StartTime, EndTime, MaxCapacity, Price,
             MeetingPoint, Notes, TourStatusID, CurrentBookings)
        VALUES (
            (SELECT COALESCE(MAX(TripID),999)+1 FROM TRIP),
            %(routeid)s, %(guideid)s,
            %(departuredate)s::DATE,
            NULLIF(%(enddate)s,'')::DATE,
            NULLIF(%(starttime)s,''), NULLIF(%(endtime)s,''),
            %(maxcapacity)s::INT,
            %(price)s::NUMERIC,
            NULLIF(%(meetingpoint)s,''),
            NULLIF(%(notes)s,''),
            %(tourstatusid)s,
            0
        )
    """
    UPDATE_SQL = """
        UPDATE TRIP SET
            RouteID      = %(routeid)s,
            GuideID      = %(guideid)s,
            DepartureDate= %(departuredate)s::DATE,
            EndDate      = NULLIF(%(enddate)s,'')::DATE,
            StartTime    = NULLIF(%(starttime)s,''),
            EndTime      = NULLIF(%(endtime)s,''),
            MaxCapacity  = %(maxcapacity)s::INT,
            Price        = %(price)s::NUMERIC,
            MeetingPoint = NULLIF(%(meetingpoint)s,''),
            Notes        = NULLIF(%(notes)s,''),
            TourStatusID = %(tourstatusid)s
        WHERE TripID = %(id)s
    """
    DELETE_SQL = "DELETE FROM TRIP WHERE TripID = %s"
    FETCH_SQL  = """
        SELECT TripID, RouteID AS routeid, GuideID AS guideid,
               TO_CHAR(DepartureDate,'YYYY-MM-DD') AS departuredate,
               TO_CHAR(EndDate,'YYYY-MM-DD')       AS enddate,
               StartTime AS starttime, EndTime AS endtime,
               MaxCapacity AS maxcapacity, Price AS price,
               MeetingPoint AS meetingpoint, Notes AS notes,
               TourStatusID AS tourstatusid
        FROM TRIP WHERE TripID = %s
    """
