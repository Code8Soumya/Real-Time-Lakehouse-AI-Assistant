# Critical Context & Guardrails

**Crucial points to keep in mind before modifying files:**

1. **Target Data Format & S3 Architecture**:
   - **Apache Iceberg** is the unified table format. Any Glue script, Flink app, or dbt model must be strictly compatible with Iceberg. Do not default to plain Parquet or Delta Lake.
   - We are using a **single S3 Bucket** structure with prefixes (`raw/`, `silver/`, `gold/`, `scripts/`, `athena-results/`) rather than separate buckets.
   - Region is pinned explicitly to **`ap-south-1`**.

2. **Domain-Specific Boundaries**:
   - This project strictly simulates an **E-commerce event** domain (Faker library is used to synthesize simple generic users, products, constraints without strict enterprise formats).
   - Supported events ONLY: `page_view`, `search_query`, `add_to_cart`, `remove_from_cart`, `begin_checkout`, `purchase`, `refund_request`, `click_recommendation`, `product_rating`. 
   - Do not add random external domains. Keep dummy data generator strictly focused on these events.

3. **CI/CD Constraints**:
   - The pipelines rely on GitHub Actions AWS OIDC (`role-to-assume`). **Never** introduce hardcoded AWS access keys/secrets or AWS IAM user profiles. 

4. **Query Engine Limit**:
   - All text-to-SQL logic in the AI Agent must produce dialect-specific SQL designed for **Amazon Athena**. 
   - Presto/Trino SQL syntax applies. Do not generate Snowflake or PostgreSQL syntax in the DB Agent prompt logic.

5. **Follow `plan.md` Phases**:
   - Adhere strictly to the phases outlined in `plan.md`. If a requested feature drops into a future phase, ensure the foundation (current phase) is stable before proceeding.
