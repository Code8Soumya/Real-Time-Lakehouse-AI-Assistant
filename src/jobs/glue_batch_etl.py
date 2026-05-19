import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, explode, to_timestamp

# ==============================================================================
# MODIFIABLE PARAMETERS
# ==============================================================================
# In standard Glue jobs, parameters are usually passed via job arguments
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_LAKEHOUSE_BUCKET', 'GLUE_DATABASE_NAME'])

S3_BUCKET = args.get('S3_LAKEHOUSE_BUCKET', 'rt-lakehouse-data-dev-331651485923') # fallback for local
DB_NAME = args.get('GLUE_DATABASE_NAME', 'ecommerce_lakehouse_dev')
CATALOG_NAME = "glue_catalog" # Defined in Glue Job conf

RAW_PREFIX = "raw"
SILVER_PREFIX = "silver"
GOLD_PREFIX = "gold"

USERS_RAW_PATH = f"s3://{S3_BUCKET}/{RAW_PREFIX}/users/"
PRODUCTS_RAW_PATH = f"s3://{S3_BUCKET}/{RAW_PREFIX}/products/"
ORDERS_RAW_PATH = f"s3://{S3_BUCKET}/{RAW_PREFIX}/orders/"

# ==============================================================================

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

def process_users():
    print("Processing users...")
    df_users = spark.read.option("header", "true").csv(USERS_RAW_PATH)
    
    # Simple cast types
    df_users = df_users.withColumn("registration_date", to_timestamp("registration_date"))
    
    # Write to Iceberg Silver
    table_identifier = f"{CATALOG_NAME}.{DB_NAME}.silver_users"
    silver_location = f"s3://{S3_BUCKET}/{SILVER_PREFIX}/users/"
    
    df_users.write.format("iceberg") \
        .mode("overwrite") \
        .option("path", silver_location) \
        .saveAsTable(table_identifier)
        
    return df_users

def process_products():
    print("Processing products...")
    df_products = spark.read.option("header", "true").csv(PRODUCTS_RAW_PATH)
    
    # Cast types
    df_products = df_products.withColumn("price", col("price").cast("double"))
    
    # Write to Iceberg Silver
    table_identifier = f"{CATALOG_NAME}.{DB_NAME}.silver_products"
    silver_location = f"s3://{S3_BUCKET}/{SILVER_PREFIX}/products/"
    
    df_products.write.format("iceberg") \
        .mode("overwrite") \
        .option("path", silver_location) \
        .saveAsTable(table_identifier)
        
    return df_products

def process_orders():
    print("Processing orders...")
    # Read JSON lines
    df_orders = spark.read.json(ORDERS_RAW_PATH)
    
    # Cast types
    df_orders = df_orders.withColumn("order_date", to_timestamp("order_date"))
    df_orders = df_orders.withColumn("total_amount", col("total_amount").cast("double"))
    
    # Write to Iceberg Silver
    table_identifier = f"{CATALOG_NAME}.{DB_NAME}.silver_orders"
    silver_location = f"s3://{S3_BUCKET}/{SILVER_PREFIX}/orders/"
    
    df_orders.write.format("iceberg") \
        .mode("overwrite") \
        .option("path", silver_location) \
        .saveAsTable(table_identifier)
        
    # Create simple Gold model via PySpark (can also be done in dbt later)
    # Explode items array to create order_items fact table
    df_order_items = df_orders.select(
        col("order_id"),
        explode(col("items")).alias("item")
    ).select(
        col("order_id"),
        col("item.product_id"),
        col("item.quantity").cast("int"),
        col("item.price_at_purchase").cast("double")
    )
    
    gold_table_identifier = f"{CATALOG_NAME}.{DB_NAME}.gold_order_items"
    gold_location = f"s3://{S3_BUCKET}/{GOLD_PREFIX}/order_items/"
    
    df_order_items.write.format("iceberg") \
        .mode("overwrite") \
        .option("path", gold_location) \
        .saveAsTable(gold_table_identifier)
        
    return df_orders

# Execute the pipeline
process_users()
process_products()
process_orders()

job.commit()