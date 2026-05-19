## Plan: AWS E-Commerce Lakehouse & AI Assistant

An end-to-end streaming data platform on AWS handling e-commerce events, providing analytics, real-time ML features, and an LLM-powered data agent, fully automated with GitHub Actions.

**Steps**

**Phase 0: Project Setup & CI/CD**
1. Initialize repository structure and configure AWS OpenID Connect (OIDC) for GitHub Actions.
2. Create GitHub Actions workflows for Terraform formatting, validation, planning, and applying (`.github/workflows/infra.yml`).
3. Create GitHub Actions workflows for linting, testing, and deploying Python scripts (Glue, Flink, FastAPI) to S3/ECR (`.github/workflows/deploy.yml`).

**Phase 1: Foundation & Batch Lakehouse**
4. Set up Terraform for AWS infrastructure provisioning (S3, IAM, Athena, Glue).
5. Write a Python script to simulate e-commerce data (users, products, historical orders) and upload as batch CSV/JSON to S3 raw layer.
6. Create AWS Glue PySpark jobs to process raw data into S3 silver and gold layers using Apache Iceberg format.
7. Configure Amazon Athena to query Iceberg tables.
8. Set up dbt (dbt-athena) to define transformation models and business metrics in the gold layer.
9. Connect Amazon QuickSight to Athena to create a basic e-commerce dashboard.

**Phase 2: Real-Time Streaming Ingestion**
10. Provision Amazon Kinesis Data Streams via Terraform.
11. Enhance the Python simulator to emit continuous e-commerce events (page views, add to cart, purchases) to the Kinesis stream.
12. Deploy an Apache Flink application to read from Kinesis, perform time-windowed aggregations, and write near real-time updates directly to Iceberg tables.
13. Update QuickSight dashboards to include near real-time metrics.

**Phase 3: Feature Store & ML Setup**
14. Design user and product features for a recommendation engine.
15. Configure Amazon SageMaker Feature Store to hold offline features (synced to S3) and online features.
16. Create an Airflow DAG (MWAA or EC2) to periodically compute batch features from Iceberg tables and ingest them into the feature store.
17. Deploy a FastAPI microservice on AWS App Runner that fetches online features and returns simple product recommendations.

**Phase 4: LLM Agent Integration**
18. Set up Amazon Bedrock access for an LLM (e.g., Claude 3).
19. Create an Amazon OpenSearch Serverless collection or DynamoDB as a vector store for schema and metric metadata definitions.
20. Develop an AI Agent (Python/LangChain) that translates natural language questions into Athena SQL queries using the metadata.
21. Expose the Agent via a simple frontend (Streamlit) or REST API.

**Relevant files**
- `.github/workflows/infra.yml` — Terraform pipeline.
- `.github/workflows/deploy.yml` — Code testing and deployment pipeline.
- `infra/main.tf` — Terraform configuration for all AWS services.
- `src/simulator/event_generator.py` — Kinesis producer simulating e-commerce events.
- `src/jobs/glue_etl.py` — PySpark Iceberg transformation scripts.
- `src/streaming/flink_app.py` — Flink application connecting Kinesis to Iceberg.
- `dbt/models/` — dbt SQL models for the analytical layer.
- `src/api/recommendation.py` — FastAPI service for ML inference.
- `src/agent/llm_agent.py` — LLM Bedrock chain for text-to-SQL.

**Verification**
1. Push a commit to GitHub and verify that the Actions pipeline correctly provisions Terraform resources (S3, Kinesis, Glue, Athena).
2. Verify GitHub Actions deploys the latest Flink app and Glue scripts to S3.
3. Run generator script; confirm events arrive in Kinesis and raw S3.
4. Execute Glue/Flink jobs; query Iceberg tables via Athena to verify data lands correctly.
5. Run `dbt test` to ensure metric models have no errors.
6. Ask the AI agent a test question like "How many users added shoes to cart in the last hour?" and verify correct Athena SQL execution.

**Decisions**
- Domain: E-commerce events.
- Table Format: Apache Iceberg.
- Streaming: Amazon Kinesis.
- AI Layer: Amazon Bedrock.
- CI/CD: GitHub Actions with AWS OIDC authentication.

**Customer Interactions Scope**
For this project, the streaming event generator will strictly be limited to the following interaction types to maintain a manageable scope while fully proving out the analytics and ML pathways:
1. **Discovery & Browsing**: `page_view`, `search_query`
2. **Intent (Funnel)**: `add_to_cart`, `remove_from_cart`, `begin_checkout`
3. **Conversion**: `purchase` (includes transaction details), `refund_request`
4. **ML & Engagement**: `click_recommendation`, `product_rating`

**Further Considerations**
1. None at this moment. Ready for implementation.