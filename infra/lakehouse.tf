# ==============================================================================
# MODIFIABLE PARAMETERS (LOCALS)
# ==============================================================================
locals {
  project_prefix      = "rt-lakehouse"
  environment         = "dev"
  
  # Ensure bucket name is globally unique, typically adding account id
  lakehouse_bucket_name = "${local.project_prefix}-data-${local.environment}-${data.aws_caller_identity.current.account_id}"
  
  glue_database_name  = "ecommerce_lakehouse_${local.environment}"
  athena_workgroup    = "ecommerce_analytics"
  
  # S3 Prefixes
  raw_prefix               = "raw/"
  silver_prefix            = "silver/"
  gold_prefix              = "gold/"
  glue_scripts_prefix      = "glue-scripts/"
  streaming_scripts_prefix = "flink-scripts/"
  athena_query_prefix      = "athena-results/"
}

# ==============================================================================
# S3 DATA LAKEHOUSE BUCKET
# ==============================================================================
resource "aws_s3_bucket" "lakehouse" {
  bucket        = local.lakehouse_bucket_name
  force_destroy = true
}

# Create Prefixes (Folders) inside the bucket
resource "aws_s3_object" "raw_folder" {
  bucket = aws_s3_bucket.lakehouse.id
  key    = local.raw_prefix
}

resource "aws_s3_object" "silver_folder" {
  bucket = aws_s3_bucket.lakehouse.id
  key    = local.silver_prefix
}

resource "aws_s3_object" "gold_folder" {
  bucket = aws_s3_bucket.lakehouse.id
  key    = local.gold_prefix
}

resource "aws_s3_object" "glue_scripts_folder" {
  bucket = aws_s3_bucket.lakehouse.id
  key    = local.glue_scripts_prefix
}

resource "aws_s3_object" "streaming_scripts_folder" {
  bucket = aws_s3_bucket.lakehouse.id
  key    = local.streaming_scripts_prefix
}

resource "aws_s3_object" "athena_results_folder" {
  bucket = aws_s3_bucket.lakehouse.id
  key    = local.athena_query_prefix
}

# ==============================================================================
# AWS GLUE CATALOG & JOB SETUP
# ==============================================================================

resource "aws_glue_catalog_database" "lakehouse_db" {
  name = local.glue_database_name
}

# IAM Role for AWS Glue
resource "aws_iam_role" "glue_role" {
  name = "${local.project_prefix}-glue-role-${local.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for S3 access
resource "aws_iam_role_policy" "glue_s3_access" {
  name = "${local.project_prefix}-glue-s3-policy"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.lakehouse.arn,
          "${aws_s3_bucket.lakehouse.arn}/*"
        ]
      }
    ]
  })
}

# Attach AWS Managed Policy for Glue Service
resource "aws_iam_role_policy_attachment" "glue_service_policy" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Glue Job (Batch ETL)
resource "aws_glue_job" "batch_etl_job" {
  name     = "${local.project_prefix}-batch-etl"
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${aws_s3_bucket.lakehouse.id}/${local.glue_scripts_prefix}glue_batch_etl.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--datalake-formats"                 = "iceberg"
    "--conf"                             = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.warehouse=s3://${aws_s3_bucket.lakehouse.id}/ --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO"
    "--S3_LAKEHOUSE_BUCKET"              = aws_s3_bucket.lakehouse.id
    "--GLUE_DATABASE_NAME"               = local.glue_database_name
  }

  glue_version = "4.0"
  worker_type  = "G.1X"
  number_of_workers = 2
}

# ==============================================================================
# AMAZON ATHENA WORKGROUP
# ==============================================================================

resource "aws_athena_workgroup" "analytics" {
  name = local.athena_workgroup

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.lakehouse.id}/${local.athena_query_prefix}"
    }
  }
}
