# Create an S3 bucket. Enable versioning and server-side encryption. Set up a lifecycle policy to transition objects.


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


data "aws_s3_bucket" "test" {
  bucket = "s3ver-test"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = data.aws_s3_bucket.test.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "versioning-bucket-config" {
    bucket = data.aws_s3_bucket.test.id
    rule {
        id = "rule1"
        status = "Enabled"

        transition {
            days          = 45
            storage_class = "STANDARD_IA"
        }

        noncurrent_version_transition {
            noncurrent_days = 45
            storage_class   = "GLACIER_IR"
        }
    }
}
