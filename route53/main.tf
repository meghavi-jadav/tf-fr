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

resource "aws_route53_zone" "dev" {
  name = "dev.example.com"

  tags = {
    Environment = "dev"
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.dev.zone_id
  name    = "dev.example.com"
  type    = "A"
  ttl     = "300"
  alias {
    name                   = aws_lb.test.dns_name
    zone_id                = aws_lb.test.zone_id
    evaluate_target_health = true
  }
}
