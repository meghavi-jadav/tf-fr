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

data "aws_vpc" "default_vpc" {
    default = true
}   

data "aws_instance" "default_instance"{
    instance_id = "i-037c89ea021db1ad8"
}

resource "aws_key_pair" "kp1" {
  key_name   = "acm-kp"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDeIAsc1fvUiwTFvIdcPEfvNp28gawcesMhfGioOf8XwqhajXxgbWNNgAjgECtPDRhXpgVBT4CGF7aMRDRAZnl8U5/afjrKHhw6GKkL9j1TP5ujbXY37jlh3zhhXLy08LdSpzQRZXAFkzXxLG10LPzf8YZN/NOXumIM4nf0af3L0PQ7zdbAC/Q91yY9o4P4ZOONluTrVa4X6FqHvDEZSA7Sencq1gEFqDsov7IYV7E5OvASh12r5eqN3TPf1nli4JmdCTNu82FyYAfIaiqIJEDg2zFmaXQ3Wyp/xGYzvyN1HtqDafVtMeD4GxuvhYdObkP6nSQkU6ppE5nNk78ZeDJN cloudshell-user@ip-10-134-40-154.ec2.internal"
}

resource "aws_security_group" "tf-sg" {
  name        = "acm-tf-sg"
  vpc_id      = data.aws_vpc.default_vpc.id

  tags = {
    Name = "acm-tf-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_http" {
  security_group_id = aws_security_group.tf-sg.id
  cidr_ipv4         = data.aws_vpc.default_vpc.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_https" {
  security_group_id = aws_security_group.tf-sg.id
  cidr_ipv4         = data.aws_vpc.default_vpc.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4" {
  security_group_id = aws_security_group.tf-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}


resource "aws_lb" "test" {
  name               = "acm-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf-sg.id]
  subnets            = ["subnet-0d07cf27e2ab66e5c", "subnet-02ce607451364073d"]

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "test-tg" {
  name        = "tf-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.default_vpc.id
}

resource "aws_lb_target_group_attachment" "tg-target" {
  target_group_arn = aws_lb_target_group.test-tg.arn
  target_id        = data.aws_instance.default_instance.instance_id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.test.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.example.arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.test-tg.arn
  }
}

#For this you will need to do validation via DNS with Route53
# resource "aws_acm_certificate" "example" {
#   domain_name       = "example.com"
#   subject_alternative_names = ["www.example.com"]
#   validation_method = "DNS"
#   tags = {
#     Name = "Example ACM Certificate"
#   }
# }

#Email Validation
#Even thought not recommended to use it for production, can be used for test purposes.
resource "aws_acm_certificate" "example" {
  domain_name       = "example.com"
  subject_alternative_names = ["www.example.com"]
  validation_method = "EMAIL"
  tags = {
    Name = "Example ACM Certificate"
  }
}

resource "aws_lb_listener_certificate" "alb-certificate" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = aws_acm_certificate.example.arn
}
