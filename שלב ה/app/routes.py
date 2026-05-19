# ============================================================
# routes.py  –  Route CRUD screen
# ============================================================
from base_crud import BaseCRUDScreen, FormField


class RoutesScreen(BaseCRUDScreen):
    TABLE  = "route"
    PK     = "routeid"
    TITLE  = "Route Management"
    ICON   = "🗺️"

    LIST_QUERY = """
        SELECT r.RouteID, r.RouteName,
               r.Duration,
               d.DifficultyName AS difficulty,
               r.EstimatedLength,
               r.Description
        FROM ROUTE r
        LEFT JOIN DIFFICULTYLEVEL d ON r.DifficultyID = d.DifficultyID
        ORDER BY r.RouteID
    """
    LIST_COLS = [
        ("routename",      "Route Name",      200),
        ("duration",       "Duration (min)",   120),
        ("difficulty",     "Difficulty",       110),
        ("estimatedlength","Length (km)",       100),
        ("description",    "Description",      260),
    ]
    FORM_FIELDS = [
        FormField("Route Name",       "routename"),
        FormField("Duration (min)",   "duration"),
        FormField("Estimated Length (km)", "estimatedlength"),
        FormField("Description",      "description"),
        FormField("Difficulty",       "difficultyid", kind="combo",
                  fk_query="SELECT DifficultyID, DifficultyName FROM DIFFICULTYLEVEL ORDER BY DifficultyID",
                  fk_id_col="difficultyid", fk_lbl_col="difficultyname"),
    ]

    INSERT_SQL = """
        INSERT INTO ROUTE
            (RouteID, RouteName, Duration, EstimatedLength, Description, DifficultyID)
        VALUES (
            (SELECT COALESCE(MAX(RouteID),0)+1 FROM ROUTE),
            %(routename)s,
            NULLIF(%(duration)s,'')::INT,
            NULLIF(%(estimatedlength)s,'')::NUMERIC,
            NULLIF(%(description)s,''),
            %(difficultyid)s
        )
    """
    UPDATE_SQL = """
        UPDATE ROUTE SET
            RouteName       = %(routename)s,
            Duration        = NULLIF(%(duration)s,'')::INT,
            EstimatedLength = NULLIF(%(estimatedlength)s,'')::NUMERIC,
            Description     = NULLIF(%(description)s,''),
            DifficultyID    = %(difficultyid)s
        WHERE RouteID = %(id)s
    """
    DELETE_SQL = "DELETE FROM ROUTE WHERE RouteID = %s"
    FETCH_SQL  = """
        SELECT r.RouteID, r.RouteName,
               r.Duration,
               r.EstimatedLength,
               r.Description,
               r.DifficultyID AS difficultyid
        FROM ROUTE r WHERE r.RouteID = %s
    """
