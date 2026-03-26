import pandas as pd
from sqlalchemy import create_engine

engine = create_engine('postgresql://admin:admin@localhost:5432/kids_db')

try:
    connection = engine.connect()
    print('Connected successfully!')
    connection.close()
except Exception as e:
    print(f'Error: {e}')
