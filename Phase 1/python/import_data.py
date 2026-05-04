import os
import pandas as pd
from sqlalchemy import create_engine
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
        print(f"\nLoading {csv_path}...")
        df_csv = pd.read_csv(csv_path)
        df_csv.columns = df_csv.columns.str.lower()
        
        # Smart Filter
        df_csv_new = get_new_records(df_csv, 'participant', 'participantid', engine)
        if not df_csv_new.empty:
            df_csv_new.to_sql('participant', con=engine, if_exists='append', index=False)
            print(" -> CSV imported successfully!")
        else:
            print(" -> No new CSV records to import (All already exist).")
    else:
        print(f"File {csv_path} not found.")

    # 2. Import Excel File to BOOKING table
    excel_path = 'dbFiles/sample.xlsx'
    if os.path.exists(excel_path):
        print(f"\nLoading {excel_path}...")
        df_excel = pd.read_excel(excel_path)
        df_excel['BookingDate'] = pd.to_datetime(df_excel['BookingDate'])
        df_excel.columns = df_excel.columns.str.lower()
        
        # Smart Filter
        df_excel_new = get_new_records(df_excel, 'booking', 'bookingid', engine)
        if not df_excel_new.empty:
            df_excel_new.to_sql('booking', con=engine, if_exists='append', index=False)
            print(" -> Excel imported successfully!")
        else:
            print(" -> No new Excel records to import (All already exist).")
    else:
        print(f"File {excel_path} not found.")

    # 3. Python Bulk Insert for LOCATION table
    print("\nPerforming Python Bulk Insert for LOCATION table...")
    locations_data = {
        'locationid': [501, 502, 503, 504, 505],
        'locationname': ['Masada', 'Dead Sea', 'Western Wall', 'Sea of Galilee', 'Ramon Crater'],
        'category': ['Historic', 'Nature', 'Historic', 'Nature', 'Nature']
    }
    df_locations = pd.DataFrame(locations_data)
    
    df_locations_new = get_new_records(df_locations, 'location', 'locationid', engine)
    if not df_locations_new.empty:
        df_locations_new.to_sql('location', con=engine, if_exists='append', index=False)
        print(" -> Python Bulk Insert completed successfully!")
    else:
        print(" -> No new locations to insert (All already exist).")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"An error occurred: {e}")

