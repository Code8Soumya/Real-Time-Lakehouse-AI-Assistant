# Project Architecture & Flow

## High-Level Execution Flow

1. **Infrastructure Provisioning**:
   - Deployed via Terraform automatically through GitHub Actions (`infra.yml`). 
   - Authenticats to AWS via OIDC.

2. **Data Ingestion (Simulator)**:
   - `src/simulator/` generates e-commerce events.
   - Pushes batch payloads to **S3 (Raw Layer)**.
   - Pushes streaming events to **Kinesis Data Streams**.

3. **Data Processing (ETL / ELT)**:
   - **Batch (AWS Glue)**: Reads from S3 raw, transforms, and saves to S3 Silver/Gold layers using **Apache Iceberg**.
   - **Streaming (Apache Flink)**: Reads from Kinesis, aggregates over windows, and writes near-real-time updates directly to Iceberg.

4. **Analytics & Modeling**:
   - **dbt**: Uses dbt-athena to build models, define business metrics, and structure the gold layer.
   - **Amazon QuickSight**: Connected to Athena to visualize dashboards.

5. **Machine Learning & Feature Store**:
   - SageMaker Feature Store stores offline (synced to S3) and online features.
   - Batch features are computed via Airflow (or MWAA) periodically from Iceberg.
   - **FastAPI / App Runner**: A microservice fetches features online and returns product recommendations.

6. **AI Agent (LLM)**:
   - Powered by **Amazon Bedrock** (e.g., Claude 3).
   - Uses OpenSearch/DynamoDB for metadata and vector storage.
   - Translates natural language questions into Athena SQL queries using schema definitions, acting as the user-facing AI assistant.
