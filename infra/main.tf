terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Note: Configure remote backend (S3/DynamoDB) for state locking before actual deployment
  backend "s3" {
    bucket         = "rt-lakehouse-tf-state-ap-south-1-331651485923"
    key            = "state/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "rt-lakehouse-tf-locks"
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "github_repo" {
  description = "GitHub repository for OIDC trust (e.g. user/repo)"
  type        = string
  default     = "Code8Soumya/Real-Time-Lakehouse-AI-Assistant"
}

# AWS OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # Standard GitHub Actions OIDC thumbprint
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:${var.github_repo}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach AdministratorAccess or scoped policies to the GitHub Actions role
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions to assume"
  value       = aws_iam_role.github_actions.arn
}

# Data source to get current AWS account ID dynamically
data "aws_caller_identity" "current" {}

# Terraform State S3 Bucket
resource "aws_s3_bucket" "terraform_state" {
  # Naming logic ensures the bucket name is globally unique
  bucket        = "rt-lakehouse-tf-state-${var.aws_region}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Allows easy cleanup during teardown
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "rt-lakehouse-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "terraform_state_bucket" {
  description = "The name of the S3 bucket to configure in the terraform backend"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_locks_table" {
  description = "The name of the DynamoDB table to configure in the terraform backend"
  value       = aws_dynamodb_table.terraform_locks.name
}
