import pathlib
content = pathlib.Path('README.md').read_text(encoding='utf-8')

# Query 1
content = content.replace('| Rachel Cohen   | 054-3333333 |\n**הסבר', '| Rachel Cohen   | 054-3333333 |\n\n![תוצאה שאילתה 1](./image/1.png)\n\n**הסבר')

# Query 2
content = content.replace('**[צילום מסך של הרצה והתוצאה עבור שאילתה 2 - הוסף כאן]**', '![תוצאה שאילתה 2](./image/2.png)')

# Query 3
content = content.replace('**[צילום מסך של הרצה והתוצאה עבור שאילתה 3 - הוסף כאן]**', '![תוצאה שאילתה 3](./image/3.png)')

# Query 4
content = content.replace('**[צילום מסך של הרצה והתוצאה עבור שאילתה 4 - הוסף כאן]**', '![תוצאה שאילתה 4](./image/4.png)')

# Query 5
content = content.replace('**[צילום מסך של הרצה והתוצאה עבור שאילתה 5 - הוסף כאן]**', '![תוצאה שאילתה 5](./image/5.png)')

# Query 6
content = content.replace('**[צילום מסך של הרצה והתוצאה עבור שאילתה 6 - הוסף כאן]**', '![תוצאה שאילתה 6](./image/6.png)')

# Query 7
content = content.replace('**[צילום מסך של הרצה והתוצאה עבור שאילתה 7 - הוסף כאן]**', '![תוצאה שאילתה 7](./image/7.png)')

# Query 8
content = content.replace('**[צילום מסך של הרצה והתוצאה עבור שאילתה 8 - הוסף כאן]**', '![תוצאה שאילתה 8](./image/8.png)')


# Part C: Update
c_old = '''### חלק ג': שאילתות Update
**[צילומי מסך לפני ואחרי לכל שאילתת עדכון - הוסף כאן]**'''

c_new = '''### חלק ג': שאילתות Update

'''
content = content.replace(c_old, c_new)

content = content.replace('''`sql
UPDATE TRIP SET Price = Price * 1.10 WHERE RouteID IN (SELECT r.RouteID FROM ROUTE r JOIN PASSES_THROUGH pt ON r.RouteID = pt.RouteID JOIN LOCATION l ON pt.LocationID = l.LocationID WHERE r.Difficulty = 'Hard' AND l.Category = 'Nature');
`''', '''`sql
UPDATE TRIP SET Price = Price * 1.10 WHERE RouteID IN (SELECT r.RouteID FROM ROUTE r JOIN PASSES_THROUGH pt ON r.RouteID = pt.RouteID JOIN LOCATION l ON pt.LocationID = l.LocationID WHERE r.Difficulty = 'Hard' AND l.Category = 'Nature');
`
**לפני עדכון מחיר:**  
![לפני עדכון 1](./image/ג1%20לפני.png)  
**אחרי עדכון מחיר:**  
![אחרי עדכון 1](./image/ג1אחרי.png)''')

content = content.replace('''`sql
UPDATE BOOKING SET Status = 'Cancelled' WHERE Status != 'Paid' AND TripID IN (SELECT TripID FROM TRIP WHERE EXTRACT(MONTH FROM DepartureDate) = EXTRACT(MONTH FROM CURRENT_DATE) AND EXTRACT(YEAR FROM DepartureDate) = EXTRACT(YEAR FROM CURRENT_DATE));
`''', '''`sql
UPDATE BOOKING SET Status = 'Cancelled' WHERE Status != 'Paid' AND TripID IN (SELECT TripID FROM TRIP WHERE EXTRACT(MONTH FROM DepartureDate) = EXTRACT(MONTH FROM CURRENT_DATE) AND EXTRACT(YEAR FROM DepartureDate) = EXTRACT(YEAR FROM CURRENT_DATE));
`
**לפני ביטול ההזמנות:**  
![לפני עדכון 2](./image/ג2לפני.png)  
**אחרי השלמת הביטול:**  
![אחרי עדכון 2](./image/ג2אחרי%20.png)''')

content = content.replace('''`sql
UPDATE GUIDE SET Expertise = 'Senior ' || Expertise WHERE GuideID IN (SELECT GuideID FROM TRIP GROUP BY GuideID HAVING COUNT(TripID) > 5) AND Expertise NOT LIKE 'Senior %';
`''', '''`sql
UPDATE GUIDE SET Expertise = 'Senior ' || Expertise WHERE GuideID IN (SELECT GuideID FROM TRIP GROUP BY GuideID HAVING COUNT(TripID) > 5) AND Expertise NOT LIKE 'Senior %';
`
**לפני קידום מדריכים:**  
![לפני עדכון 3](./image/ג3לפני.png)  
**אחרי קידום המדריכים:**  
![אחרי עדכון 3](./image/ג3אחרי.png)''')


# Part D: Delete
d_old = '''### חלק ד': שאילתות Delete
**[צילומי מסך לפני ואחרי לכל שאילתת מחיקה - הוסף כאן]**'''

d_new = '''### חלק ד': שאילתות Delete

'''
content = content.replace(d_old, d_new)

content = content.replace('''`sql
DELETE FROM BOOKING WHERE Status = 'Pending' AND TripID IN (SELECT TripID FROM TRIP WHERE DepartureDate <= CURRENT_DATE + INTERVAL '3 days');
`''', '''`sql
DELETE FROM BOOKING WHERE Status = 'Pending' AND TripID IN (SELECT TripID FROM TRIP WHERE DepartureDate <= CURRENT_DATE + INTERVAL '3 days');
`
**לפני מחיקת הזמנות ממתינות:**  
![לפני מחיקה 1](./image/ד1%20לפני.png)  
**אחרי המחיקה:**  
![אחרי מחיקה 1](./image/ד1אחרי.png)''')

content = content.replace('''`sql
DELETE FROM LOCATION WHERE LocationID NOT IN (SELECT LocationID FROM PASSES_THROUGH);
`''', '''`sql
DELETE FROM LOCATION WHERE LocationID NOT IN (SELECT LocationID FROM PASSES_THROUGH);
`
**לפני מחיקת מיקומים:**  
![לפני מחיקה 2](./image/ד2לפני.png)  
**אחרי המחיקה:**  
![אחרי מחיקה 2](./image/ד2אחרי.png)''')


# Part E: Constraints
content = content.replace('**[צילום מסך של ניסיון הכנסת נתון שגוי לכל אילוץ המקפיץ שגיאה - הוסף כאן]**\n\nהוטמעו אילוצים קריטיים במסד הנתונים. להלן פקודות שיש להריץ כדי להציג את קפיצת השגיאות בצילומי המסך:', 'הוטמעו אילוצים קריטיים במסד הנתונים שחוסמים הכנסת נתונים שגויים כמוראה בצילומי המסך:')

content = content.replace('''`sql
INSERT INTO TRIP (TripID, DepartureDate, MaxCapacity, Price, RouteID, GuideID) VALUES (901, '2026-06-01', 20, -50, 101, 1);
`''', '''`sql
INSERT INTO TRIP (TripID, DepartureDate, MaxCapacity, Price, RouteID, GuideID) VALUES (901, '2026-06-01', 20, -50, 101, 1);
`
![שגיאת אילוץ 1](./image/ה1.png)''')

content = content.replace('''`sql
INSERT INTO BOOKING (BookingID, BookingDate, Status, TripID, ParticipantID) VALUES (901, '2026-05-19', 'UnknownStatus', 1001, 1);
`''', '''`sql
INSERT INTO BOOKING (BookingID, BookingDate, Status, TripID, ParticipantID) VALUES (901, '2026-05-19', 'UnknownStatus', 1001, 1);
`
![שגיאת אילוץ 2](./image/ה2.png)''')

content = content.replace('''`sql
INSERT INTO ROUTE (RouteID, RouteName, Duration, Difficulty) VALUES (901, 'Bad Route', 100, 'Extreme');
`''', '''`sql
INSERT INTO ROUTE (RouteID, RouteName, Duration, Difficulty) VALUES (901, 'Bad Route', 100, 'Extreme');
`
![שגיאת אילוץ 3](./image/ה3.png)''')


# Part F: Rollback
content = content.replace('''### חלק ו': הדגמות Rollback ו- Commit
**[צילומי מסד נתונים המראים את הנתונים המשתנים בשלבי הזיכרון השונים - הוסף כאן]**''', '''### חלק ו': הדגמות Rollback ו- Commit''')

content = content.replace('''SELECT Price FROM TRIP WHERE TripID = 1001; -- 1. לצלם מחיר התחלתי''', '''SELECT Price FROM TRIP WHERE TripID = 1001; -- הצגת מחיר התחלתי\n`\n![לפני הרולבק](./image/ו%20לפני%20.png)\n`sql''')

content = content.replace('''SELECT Price FROM TRIP WHERE TripID = 1001; -- 2. לצלם מחיר לאחר עלייה (לפני ביטול)''', '''SELECT Price FROM TRIP WHERE TripID = 1001; -- מחיר לאחר עלייה (עדיין בזיכרון, טרם ביטול)\n`\n![אחרי השינוי](./image/ו%20אחרי%20השינוי.png)\n`sql''')

content = content.replace('''SELECT Price FROM TRIP WHERE TripID = 1001; -- 3. לצלם מחיר שהוחזר לקדמותו''', '''SELECT Price FROM TRIP WHERE TripID = 1001; -- מחיר שהוחזר לקדמותו לחלוטין\n`\n![בחזרה למקור](./image/ו%20בחזרה%20למקור.png)''')


# Part G: Indexes
content = content.replace('**[צילום של טבלת Explain Analyze עם Index Scan מול Seq Scan - הוסף כאן]**\n\n', '')
content = content.replace('''EXPLAIN ANALYZE SELECT * FROM TRIP WHERE DepartureDate = '2026-05-15';
`
*(לאחר הרצה תופיע השורה Seq Scan on trip)*''', '''EXPLAIN ANALYZE SELECT * FROM TRIP WHERE DepartureDate = '2026-05-15';
`
![סריקה לפני אינדקס](./image/ז%20לפני.png)''')

content = content.replace('''EXPLAIN ANALYZE SELECT * FROM TRIP WHERE DepartureDate = '2026-05-15';
`
*(כעת יופיע בפלט Index Scan using idx_trip_departure - וזמן הריצה יתקצר!)*''', '''EXPLAIN ANALYZE SELECT * FROM TRIP WHERE DepartureDate = '2026-05-15';
`
![סריקה אחרי אינדקס](./image/ז%20אחרי.png)''')


pathlib.Path('README.md').write_text(content, encoding='utf-8')
