import random
from faker import Faker

fake = Faker()

NUM_RECORDS = 20000

def generate_registration_inserts():
    print(f"Generating {NUM_RECORDS} inserts for REGISTRATION table...")
    
    MAX_CUSTOMER_ID = 10000 
    MAX_TOUR_ID = 500
    MAX_STATUS_ID = 4  

    with open('insert_registration.sql', mode='w', encoding='utf-8') as file:
        file.write("-- REGISTRATION INSERTS\n")
        
        for reg_id in range(1, NUM_RECORDS + 1):
            reg_date = fake.date_between(start_date='-3y', end_date='today').strftime('%Y-%m-%d')
            
            amount = round(random.uniform(50.0, 5000.0), 2)
            
            notes = fake.sentence(nb_words=8).replace("'", "''")
            if len(notes) > 500: notes = notes[:497] + "..."
            
            cust_id = random.randint(1, MAX_CUSTOMER_ID)
            tour_id = random.randint(1, MAX_TOUR_ID)
            status_id = random.randint(1, MAX_STATUS_ID)
            
            sql = (f"INSERT INTO REGISTRATION (RegistrationID, RegistrationDate, AmountToPay, Notes, "
                   f"TourID, RegistrationStatusID, CustomerID) "
                   f"VALUES ({reg_id}, TO_DATE('{reg_date}', 'YYYY-MM-DD'), {amount}, '{notes}', "
                   f"{tour_id}, {status_id}, {cust_id});\n")
            
            file.write(sql)

    print("Success! 'insert_registration.sql' has been created.")

if __name__ == '__main__':
    generate_registration_inserts()