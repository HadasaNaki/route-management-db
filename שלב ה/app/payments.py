# ============================================================
# payments.py  –  Payment CRUD screen
# ============================================================
from base_crud import BaseCRUDScreen, FormField


class PaymentsScreen(BaseCRUDScreen):
    TABLE  = "payment"
    PK     = "paymentid"
    TITLE  = "Payment Management"
    ICON   = "💳"

    LIST_QUERY = """
        SELECT pa.PaymentID,
               p.FullName                              AS participantname,
               r.RouteName,
               TO_CHAR(pa.PaymentDate,'YYYY-MM-DD')   AS paymentdate,
               pa.Amount,
               pa.PaymentMethod,
               ps.StatusName                          AS statusname,
               pa.ReferenceNumber,
               pa.Notes
        FROM PAYMENT pa
        JOIN BOOKING b         ON pa.BookingID       = b.BookingID
        JOIN PARTICIPANT p     ON b.ParticipantID    = p.ParticipantID
        JOIN TRIP t            ON b.TripID           = t.TripID
        JOIN ROUTE r           ON t.RouteID          = r.RouteID
        JOIN PAYMENTSTATUS ps  ON pa.PaymentStatusID = ps.PaymentStatusID
        ORDER BY pa.PaymentID
    """
    LIST_COLS = [
        ("participantname", "Participant",    180),
        ("routename",       "Route",          160),
        ("paymentdate",     "Date",           110),
        ("amount",          "Amount ₪",        90),
        ("paymentmethod",   "Method",         120),
        ("statusname",      "Status",         120),
        ("referencenumber", "Reference",      120),
    ]
    FORM_FIELDS = [
        FormField("Booking", "bookingid", kind="combo",
                  fk_query="""
                      SELECT b.BookingID,
                             p.FullName||' → '||r.RouteName||
                             ' ('||TO_CHAR(t.DepartureDate,'DD/MM/YY')||')' AS label
                      FROM BOOKING b
                      JOIN PARTICIPANT p ON b.ParticipantID=p.ParticipantID
                      JOIN TRIP t ON b.TripID=t.TripID
                      JOIN ROUTE r ON t.RouteID=r.RouteID
                      ORDER BY b.BookingID
                  """,
                  fk_id_col="bookingid", fk_lbl_col="label"),
        FormField("Payment Date (YYYY-MM-DD)", "paymentdate"),
        FormField("Amount (₪)",                "amount"),
        FormField("Payment Method",            "paymentmethod"),
        FormField("Reference Number",          "referencenumber"),
        FormField("Notes",                     "notes"),
        FormField("Status", "paymentstatusid", kind="combo",
                  fk_query="SELECT PaymentStatusID, StatusName FROM PAYMENTSTATUS ORDER BY PaymentStatusID",
                  fk_id_col="paymentstatusid", fk_lbl_col="statusname"),
    ]

    INSERT_SQL = """
        INSERT INTO PAYMENT
            (PaymentID, PaymentDate, Amount, PaymentMethod,
             ReferenceNumber, Notes, BookingID, PaymentStatusID)
        VALUES (
            (SELECT COALESCE(MAX(PaymentID),0)+1 FROM PAYMENT),
            COALESCE(NULLIF(%(paymentdate)s,'')::DATE, CURRENT_DATE),
            NULLIF(%(amount)s,'')::NUMERIC,
            %(paymentmethod)s,
            NULLIF(%(referencenumber)s,''),
            NULLIF(%(notes)s,''),
            %(bookingid)s,
            %(paymentstatusid)s
        )
    """
    UPDATE_SQL = """
        UPDATE PAYMENT SET
            PaymentDate     = COALESCE(NULLIF(%(paymentdate)s,'')::DATE, PaymentDate),
            Amount          = NULLIF(%(amount)s,'')::NUMERIC,
            PaymentMethod   = %(paymentmethod)s,
            ReferenceNumber = NULLIF(%(referencenumber)s,''),
            Notes           = NULLIF(%(notes)s,''),
            BookingID       = %(bookingid)s,
            PaymentStatusID = %(paymentstatusid)s
        WHERE PaymentID = %(id)s
    """
    DELETE_SQL = "DELETE FROM PAYMENT WHERE PaymentID = %s"
    FETCH_SQL  = """
        SELECT PaymentID,
               BookingID AS bookingid,
               TO_CHAR(PaymentDate,'YYYY-MM-DD') AS paymentdate,
               Amount AS amount, PaymentMethod AS paymentmethod,
               ReferenceNumber AS referencenumber, Notes AS notes,
               PaymentStatusID AS paymentstatusid
        FROM PAYMENT WHERE PaymentID = %s
    """
