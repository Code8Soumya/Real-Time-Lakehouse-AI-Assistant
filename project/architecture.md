# Project Architecture & Flow

## High-Level Execution Flow

1. **Infrastructure Provisioning**:
   - Organized in `infra/` folder mapping cleanly to different service scopes.
   - Deployed via Terraform automatically through GitHub Actions (`infra.yml`). 
   - Authenticates to AWS via OIDC. Features local bootstrap (local state then remote migration to S3).

2. **Data Ingestion (Simulator)**:
   - `src/simulator/batch_generator.py` generates historical batch e-commerce events (users, products, orders using Faker).
   - Uses `boto3` to push payloads directly to **S3 (Raw Layer)**.
   - *(Future)* Streaming events will push to **Kinesis Data Streams**.

3. **Data Processing (ETL / ELT)**:
   - **Batch (AWS Glue)**: Runs `src/jobs/glue_batch_etl.py` which reads from S3 raw (`csv`/`json`), transforms via PySpark, and exposes as **Apache Iceberg** tables in S3 Silver/Gold layers.
   - **Streaming (Apache Flink)**: *(Future)* Reads from Kinesis, aggregates over windows, and writes near-real-time updates directly to Iceberg.

4. **Analytics & Modeling**:
   - **Athena**: Serves as the interactive serverless query engine reading Iceberg format stored in S3.
   - **dbt**: *(Next)* Uses dbt-athena to build models, define business metrics, and structure the gold layer.
   - **Amazon QuickSight**: Connected to Athena to visualize dashboards.

5. **Machine Learning & Feature Store**:
   - SageMaker Feature Store stores offline (synced to S3) and online features.
   - Batch features are computed via Airflow (or MWAA) periodically from Iceberg.
   - **FastAPI / App Runner**: A microservice fetches features online and returns product recommendations.

6. **AI Agent (LLM)**:
   - Powered by **Amazon Bedrock** (e.g., Claude 3).
   - Uses OpenSearch/DynamoDB for metadata and vector storage.
   - Translates natural language questions into Athena SQL queries using schema definitions, acting as the user-facing AI assistant.
