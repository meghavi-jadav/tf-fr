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

data "aws_route53_zone" "dev" {
  name = "dev.example.com."
}

variable "tg_name" {
  type    = string
  default = "test-tg"
}

variable "tg_arn"{
    type = string
    default = "arn:aws:elasticloadbalancing:us-east-1:552429782677:targetgroup/test-tg/245c220ae162b6dc"
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

resource "aws_acm_certificate" "cert" {
  domain_name       = "dev.example.com"
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.test.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = var.tg_arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_route53_record" "example" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.dev.zone_id
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.example : record.fqdn]
}

# resource "aws_route53_zone" "dev" {
#   name = "dev.example.com"

#   tags = {
#     Environment = "dev"
#   }
# }

# resource "aws_route53_record" "www" {
#   zone_id = aws_route53_zone.dev.zone_id
#   name    = "dev.example.com"
#   type    = "A"
#   ttl     = "300"
#   alias {
#     name                   = aws_lb.test.dns_name
#     zone_id                = aws_lb.test.zone_id
#     evaluate_target_health = true
#   }
# }
