import os
import random
import pandas as pd
from sqlalchemy import create_engine
from faker import Faker
from dotenv import load_dotenv

def get_new_records(df, table_name, pk_col, engine):
    """
    Function to detect existing Primary Keys in the database
    and return only the rows that do NOT exist yet.
    """
    try:
        query = f"SELECT {pk_col} FROM {table_name}"
        existing_keys = pd.read_sql(query, con=engine)[pk_col].tolist()
        df_new = df[~df[pk_col].isin(existing_keys)]
        print(f" => DB already has {len(existing_keys)} records in {table_name}. Adding {len(df_new)} new records out of {len(df)}.")
        return df_new
    except Exception as e:
        print(f" => Note: Could not filter {table_name} (maybe table is empty or {pk_col} is wrong). Inserting all {len(df)} records.")
        return df

def insert_safe(df, table_name, pk_col, engine):
    df_new = get_new_records(df, table_name, pk_col, engine)
    if not df_new.empty:
        df_new.to_sql(table_name, con=engine, if_exists='append', index=False)
        print(f" -> Inserted to {table_name} successfully.")
    else:
        print(f" -> Skipped {table_name}: No new records to insert.")

def main():
    print("Initializing Faker and connecting to the database...")
    load_dotenv()
    user = os.getenv('POSTGRES_USER', 'admin')
    password = os.getenv('POSTGRES_PASSWORD', 'admin')
    db = os.getenv('POSTGRES_DB', 'routes_db')
    host = 'localhost'
    port = '5432'
    
    engine = create_engine(f"postgresql://{user}:{password}@{host}:{port}/{db}")
    fake = Faker('he_IL')  # Let's generate Israeli/Hebrew-sounding fake data along with English
    Faker.seed(42)
    random.seed(42)

    # 1. GENERATE GUIDES (500)
    print("\nGenerating 500 Guides...")
    guides = []
    expertises = ['Desert Tours', 'City Architecture', 'Mountain Tracking', 'History & Religion', 'Culinary Tours', 'Extreme Sports', 'Water Tracks']
    for i in range(10, 510):
        guides.append({
            'guideid': i,
            'firstname': fake.first_name()[:50],
            'lastname': fake.last_name()[:50],
            'phone': fake.phone_number()[:20],
            'expertise': random.choice(expertises)
        })
    insert_safe(pd.DataFrame(guides), 'guide', 'guideid', engine)

    # 2. GENERATE LOCATIONS (500)
    print("\nGenerating 500 Locations...")
    locations = []
    categories = ['Nature', 'Historic', 'City', 'Museum', 'Park', 'Beach & Water', 'Archaeology']
    for i in range(1000, 1500):
        locations.append({
            'locationid': i,
            'locationname': (fake.city() + " " + random.choice(['Park', 'Ruins', 'Viewpoint', 'Valley', 'Museum']))[:100],
            'category': random.choice(categories)
        })
    insert_safe(pd.DataFrame(locations), 'location', 'locationid', engine)

    # 3. GENERATE ROUTES (500)
    print("\nGenerating 500 Routes...")
    routes = []
    difficulties = ['Easy', 'Medium', 'Hard', 'Extreme']
    for i in range(1000, 1500):
        routes.append({
            'routeid': i,
            'routename': (fake.street_name() + " Trail")[:100],
            'duration': random.randint(30, 720),
            'difficulty': random.choice(difficulties)[:20]
        })
    insert_safe(pd.DataFrame(routes), 'route', 'routeid', engine)

    # 4. GENERATE TRIPS (500)
    print("\nGenerating 500 Trips...")
    trips = []
    for i in range(2000, 2500):
        trips.append({
            'tripid': i,
            'departuredate': fake.date_between(start_date='-2y', end_date='+2y'),
            'maxcapacity': random.randint(10, 60),
            'price': round(random.uniform(50.0, 800.0), 2),
            'routeid': random.randint(1000, 1499),
            'guideid': random.randint(10, 509)
        })
    insert_safe(pd.DataFrame(trips), 'trip', 'tripid', engine)

    # 5. GENERATE PARTICIPANTS (20,000)
    print("\nGenerating 20,000 Participants... This might take a few seconds.")
    participants = []
    for i in range(1000, 21000):
        participants.append({
            'participantid': i,
            'fullname': fake.name()[:100],
            'email': fake.email()[:100],
            'phone': fake.phone_number()[:20]
        })
    insert_safe(pd.DataFrame(participants), 'participant', 'participantid', engine)

    # 6. GENERATE BOOKINGS (20,000)
    print("\nGenerating 20,000 Bookings...")
    bookings = []
    statuses = ['Paid', 'Pending', 'Cancelled', 'Refunded']
    for i in range(1000, 22000):
        bookings.append({
            'bookingid': i,
            'bookingdate': fake.date_between(start_date='-2y', end_date='today'),
            'status': random.choices(statuses, weights=[0.65, 0.2, 0.1, 0.05])[0][:20],
            'tripid': random.randint(2000, 2499),
            'participantid': random.randint(1000, 20999)
        })
    insert_safe(pd.DataFrame(bookings), 'booking', 'bookingid', engine)

    print("\nSuccess! Bulk generation and insertion finished.")

if __name__ == '__main__':
    main()

