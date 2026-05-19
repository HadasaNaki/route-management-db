import random
from faker import Faker

fake = Faker()

NUM_RECORDS = 20000

def generate_payment_inserts():
    """
    Generates a SQL script ('insert_payments.sql') containing INSERT
    statements for the PAYMENT table.
    """
    print(f"Generating {NUM_RECORDS} inserts for PAYMENT table...")
    
    payment_methods = ['Credit Card', 'Bank Transfer', 'PayPal', 'Cash', 'Check']
    
    MAX_REGISTRATION_ID = 20000 
    MAX_STATUS_ID = 5

    with open('insert_payments.sql', mode='w', encoding='utf-8') as file:
        file.write("-- PAYMENT INSERTS\n")
        
        for pay_id in range(1, NUM_RECORDS + 1):
            pay_date = fake.date_between(start_date='-2y', end_date='today').strftime('%Y-%m-%d')
            
            amount = round(random.uniform(10.0, 9999.99), 2)
            
            notes = fake.sentence(nb_words=10).replace("'", "''").replace("\n", " ")
            if len(notes) > 500: notes = notes[:497] + "..."
            
            method = random.choice(payment_methods)
            
            ref_num = fake.bothify(text='REF-#######-??').upper()
            
            reg_id = random.randint(1, MAX_REGISTRATION_ID)
            status_id = random.randint(1, MAX_STATUS_ID)
            
            sql = (f"INSERT INTO PAYMENT (PaymentID, PaymentDate, Amount, Notes, "
                   f"PaymentMethod, ReferenceNumber, RegistrationID, PaymentStatusID) "
                   f"VALUES ({pay_id}, TO_DATE('{pay_date}', 'YYYY-MM-DD'), {amount}, '{notes}', "
                   f"'{method}', '{ref_num}', {reg_id}, {status_id});\n")
            
            file.write(sql)

    print("Success! 'insert_payments.sql' has been created.")

if __name__ == '__main__':
    generate_payment_inserts()