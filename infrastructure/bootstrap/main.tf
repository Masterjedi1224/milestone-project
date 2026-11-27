terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "terraform_state" {
  for_each = toset(["dev", "staging", "production"])

  bucket_prefix = "milestone-tfstate-${each.key}-"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project     = "milestone-badges"
    Environment = each.key
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "state_bucket_names" {
  description = "S3 bucket names to use in the dev, staging and production backend configurations."
  value = {
    for environment, bucket in aws_s3_bucket.terraform_state :
    environment => bucket.bucket
  }
}