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
│   └── main.tf            # Terraform infrastructure provisioning (AWS)
├── project/
│   ├── architecture.md    # System design and connection logic
│   ├── critical-context.md# Guardrails and crucial context
│   ├── memory.md          # Current task tracker
│   └── structure.md       # (This file) Overview of paths
├── src/
│   ├── agent/             # LLM Bedrock chain for text-to-SQL (LangChain)
│   ├── api/               # FastAPI service for ML inference (Recommender)
│   ├── jobs/              # AWS Glue PySpark Iceberg transformation scripts
│   ├── simulator/         # Python Kinesis producer for simulated e-commerce events
│   └── streaming/         # Flink application connecting Kinesis to Iceberg
├── copilot-instructions.md# AI behavior and guidance rules
├── plan.md                # The master plan and phases
└── README.md
```
