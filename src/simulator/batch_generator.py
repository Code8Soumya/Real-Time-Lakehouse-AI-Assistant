import json
import csv
import random
import uuid
import tempfile
import os
from datetime import datetime, timedelta
import boto3
from faker import Faker

# ==============================================================================
# MODIFIABLE PARAMETERS
# ==============================================================================
AWS_REGION = "ap-south-1"
S3_BUCKET_NAME = "rt-lakehouse-data-dev-331651485923" # Replace with your terraform-generated bucket name
UPLOAD_TO_S3 = True

# Data generation scaling
NUM_USERS = 10000
NUM_PRODUCTS = 500
NUM_ORDERS = 5000

# File formats and prefixes
RAW_PREFIX = "raw"
USERS_FILE = "users.csv"
PRODUCTS_FILE = "products.csv"
ORDERS_FILE = "orders.json"

# ==============================================================================

fake = Faker()

def generate_users(num_users):
    users = []
    for _ in range(num_users):
        users.append({
            "user_id": str(uuid.uuid4()),
            "name": fake.name(),
            "email": fake.email(),
            "registration_date": fake.date_time_between(start_date='-2y', end_date='now').isoformat()
        })
    return users

def generate_products(num_products):
    categories = ["Electronics", "Clothing", "Home", "Sports", "Books"]
    products = []
    for _ in range(num_products):
        products.append({
            "product_id": str(uuid.uuid4()),
            "name": fake.word().capitalize() + " " + fake.word().capitalize(),
            "category": random.choice(categories),
            "price": round(random.uniform(10.0, 500.0), 2)
        })
    return products

def generate_orders(num_orders, users, products):
    orders = []
    statuses = ["completed", "processing", "cancelled", "refunded"]
    
    for _ in range(num_orders):
        user = random.choice(users)
        
        # An order can have 1 to 5 items
        num_items = random.randint(1, 5)
        order_items = []
        total_amount = 0.0
        
        for _ in range(num_items):
            product = random.choice(products)
            quantity = random.randint(1, 3)
            price = product["price"]
            total_amount += quantity * price
            
            order_items.append({
                "product_id": product["product_id"],
                "quantity": quantity,
                "price_at_purchase": price
            })
            
        orders.append({
            "order_id": str(uuid.uuid4()),
            "user_id": user["user_id"],
            "order_date": fake.date_time_between(start_date='-1y', end_date='now').isoformat(),
            "status": random.choices(statuses, weights=[0.8, 0.1, 0.05, 0.05])[0],
            "total_amount": round(total_amount, 2),
            "items": order_items
        })
        
    return orders

def save_and_upload_to_s3(data, filename, is_json=False):
    temp_dir = tempfile.gettempdir()
    filepath = os.path.join(temp_dir, filename)
    
    # Save locally
    if is_json:
        with open(filepath, 'w') as f:
            for record in data:
                f.write(json.dumps(record) + '\n') # JSON lines format
    else:
        with open(filepath, 'w', newline='') as f:
            if not data:
                return
            writer = csv.DictWriter(f, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)
            
    print(f"[{filename}] Saved locally at {filepath}")
    
    # Upload to S3
    if UPLOAD_TO_S3:
        try:
            s3_client = boto3.client('s3', region_name=AWS_REGION)
            s3_key = f"{RAW_PREFIX}/{filename.split('.')[0]}/{filename}"
            s3_client.upload_file(filepath, S3_BUCKET_NAME, s3_key)
            print(f"[{filename}] Uploaded to s3://{S3_BUCKET_NAME}/{s3_key}")
        except Exception as e:
            print(f"Failed to upload {filename} to S3: {e}")

if __name__ == "__main__":
    print("Starting batch data generation...")
    
    users = generate_users(NUM_USERS)
    products = generate_products(NUM_PRODUCTS)
    orders = generate_orders(NUM_ORDERS, users, products)
    
    save_and_upload_to_s3(users, USERS_FILE)
    save_and_upload_to_s3(products, PRODUCTS_FILE)
    save_and_upload_to_s3(orders, ORDERS_FILE, is_json=True)
    
    print("Batch data generation complete.")