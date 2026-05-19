# Project Structure

```text
e:\Coding\Projects\Real-Time-Lakehouse-AI-Assistant\
├── .github/
│   └── workflows/
│       ├── infra.yml      # GitHub Actions: Terraform validation & deployment pipeline
│       └── deploy.yml     # GitHub Actions: PySpark/Flink/App CI/CD pipeline
├── dbt/
│   └── models/            # dbt definitions for metric aggregations in the Gold Layer
├── infra/
│   ├── main.tf            # Core AWS provider, CI role, and Backend state definitions
│   └── lakehouse.tf       # Phase 1: S3 Bucket, IAM glue policies, Glue Jobs, Athena Workgroup
├── project/
│   ├── architecture.md    # System design and connection logic
│   ├── critical-context.md# Guardrails and crucial context
│   ├── memory.md          # Current task tracker
│   └── structure.md       # (This file) Overview of paths
├── src/
│   ├── agent/             # LLM Bedrock chain for text-to-SQL (LangChain)
│   ├── api/               # FastAPI service for ML inference (Recommender)
│   ├── jobs/
│   │   └── glue_batch_etl.py  # AWS Glue PySpark Iceberg transformation scripts
│   ├── simulator/
│   │   └── batch_generator.py # Python script for fake historical data generation
│   └── streaming/         # Flink application connecting Kinesis to Iceberg
├── requirements.txt       # Python dependencies (boto3, faker)
├── copilot-instructions.md# AI behavior and guidance rules
├── plan.md                # The master plan and phases
└── README.md
```
