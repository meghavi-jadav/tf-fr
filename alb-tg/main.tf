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

data "aws_instance" "existing-instance" {
  instance_id = "i-0cceef1f2727eba04"
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

resource "aws_lb_target_group" "test-tg" {
  name        = "tf-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test-tg.arn
  }
}

resource "aws_lb_target_group_attachment" "tg-target" {
  target_group_arn = aws_lb_target_group.test-tg.arn
  target_id        = data.aws_instance.existing-instance.instance_id
  port             = 80
}
