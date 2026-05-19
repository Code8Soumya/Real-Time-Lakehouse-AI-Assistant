# Current Memory / Status

## Current Phase: Phase 1 (Foundation & Batch Lakehouse) execution

### Recently Completed:
- Completed Terraform structure for Phase 1 (`infra/main.tf`, `infra/lakehouse.tf`).
- Commented out the S3 backend in Terraform to allow for local bootstrapping before migrating state.
- Created local Python simulator `src/simulator/batch_generator.py` for synthetic data generation using Faker.
- Created PySpark ETL job `src/jobs/glue_batch_etl.py` which ingests raw data from S3, converts to Apache Iceberg format, and outputs to Silver/Gold prefixes.
- Created `requirements.txt` to track Python dependencies (`boto3`, `Faker`).

### What is going on now:
- We have prepped Phase 1 scripts and infrastructure.
- User will optionally run Terraform locally to provision S3 buckets, AWS Glue catalog, and Athena workgroup.
- Next active tasks will be running the python simulator to push raw data to S3, running the Glue job, and verifying the Iceberg table availability in Athena.
- Then, we'll set up `dbt` (dbt-athena) to define metrics models in the gold layer.
