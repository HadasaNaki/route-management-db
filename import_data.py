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

    # 1. Import CSV File
    csv_path = 'dbFiles/sample.csv'
    if os.path.exists(csv_path):
        print(f"Loading {csv_path}...")
        df_csv = pd.read_csv(csv_path)
        df_csv.to_sql('products_csv', con=engine, if_exists='replace', index=False)
        print("CSV imported successfully to table 'products_csv'!")
    else:
        print(f"File {csv_path} not found.")

    # 2. Import Excel File
    excel_path = 'dbFiles/sample.xlsx'
    if os.path.exists(excel_path):
        print(f"Loading {excel_path}...")
        df_excel = pd.read_excel(excel_path)
        df_excel.to_sql('users_excel', con=engine, if_exists='replace', index=False)
        print("Excel imported successfully to table 'users_excel'!")
    else:
        print(f"File {excel_path} not found.")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"An error occurred: {e}")
