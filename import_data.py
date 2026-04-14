import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

def main():
    # Load environment variables
    load_dotenv()
    user = os.getenv('POSTGRES_USER', 'admin')
    password = os.getenv('POSTGRES_PASSWORD', 'admin')
    db = os.getenv('POSTGRES_DB', 'routes_db')
    host = 'localhost'
    port = '5432'

    engine_url = f"postgresql://{user}:{password}@{host}:{port}/{db}"
    print(f"Connecting to database '{db}'...")
    engine = create_engine(engine_url)

    # 1. Import CSV File to PARTICIPANT table
    csv_path = 'dbFiles/sample.csv'
    if os.path.exists(csv_path):
        print(f"Loading {csv_path}...")
        df_csv = pd.read_csv(csv_path)
        df_csv.to_sql('participant', con=engine, if_exists='append', index=False)
        print("CSV imported successfully to table 'participant'!")
    else:
        print(f"File {csv_path} not found.")

    # 2. Import Excel File to BOOKING table
    excel_path = 'dbFiles/sample.xlsx'
    if os.path.exists(excel_path):
        print(f"Loading {excel_path}...")
        df_excel = pd.read_excel(excel_path)
        # Ensure BookingDate is recognized
        df_excel['BookingDate'] = pd.to_datetime(df_excel['BookingDate'])
        df_excel.to_sql('booking', con=engine, if_exists='append', index=False)
        print("Excel imported successfully to table 'booking'!")
    else:
        print(f"File {excel_path} not found.")

    # 3. Python Bulk Insert for LOCATION table (Method 2 requirement)
    print("Performing Python Bulk Insert for LOCATION table...")
    locations_data = {
        'LocationID': [501, 502, 503, 504, 505],
        'LocationName': ['Masada', 'Dead Sea', 'Western Wall', 'Sea of Galilee', 'Ramon Crater'],
        'Category': ['Historic', 'Nature', 'Historic', 'Nature', 'Nature']
    }
    df_locations = pd.DataFrame(locations_data)
    df_locations.to_sql('location', con=engine, if_exists='append', index=False)
    print("Python Bulk Insert completed successfully!")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"An error occurred: {e}")
