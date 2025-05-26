terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

provider aws {
    region = "us-east-1"
}

data "aws_vpc" "main"{
    default = true
}

data "aws_security_group" "existing-sg" {
  id = "sg-0186f0dc9567a60f3"
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.existing-sg.id]
  subnets            = ["subnet-0d07cf27e2ab66e5c", "subnet-02ce607451364073d"]

  tags = {
    Environment = "production"
  }
}

data "aws_s3_bucket" "selected" {
  bucket = "static-website-quizapp"
}

resource "aws_cloudfront_distribution" "alb-distribution" {
    origin{
        domain_name = data.aws_s3_bucket.selected.bucket_domain_name
        origin_id = "s3-selected-bucket"
    }
    enabled = true
    is_ipv6_enabled = false

    default_cache_behavior {
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id       = "alb-origin"
        viewer_protocol_policy = "redirect-to-https"
        compress               = true
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400

    }

    # ordered_cache_behavior {
    #     path_pattern     = "Default"
    #     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    #     cached_methods   = ["GET", "HEAD"]
    #     target_origin_id = aws_lb.test.id
    #     min_ttl                = 0
    #     default_ttl            = 3600
    #     max_ttl                = 86400 #1day
    #     compress               = true
    #     viewer_protocol_policy = "redirect-to-https"
    # }

    viewer_certificate{
        cloudfront_default_certificate = true
    }

    restrictions{
        geo_restriction {
            restriction_type = "none"
        }
    }

    tags = {
        Environment = "production"
    }
}
