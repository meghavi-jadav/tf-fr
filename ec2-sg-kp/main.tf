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

data "aws_vpc" "default" {
  default = true
}

resource "aws_key_pair" "kp1" {
  key_name   = "kp1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDeIAsc1fvUiwTFvIdcPEfvNp28gawcesMhfGioOf8XwqhajXxgbWNNgAjgECtPDRhXpgVBT4CGF7aMRDRAZnl8U5/afjrKHhw6GKkL9j1TP5ujbXY37jlh3zhhXLy08LdSpzQRZXAFkzXxLG10LPzf8YZN/NOXumIM4nf0af3L0PQ7zdbAC/Q91yY9o4P4ZOONluTrVa4X6FqHvDEZSA7Sencq1gEFqDsov7IYV7E5OvASh12r5eqN3TPf1nli4JmdCTNu82FyYAfIaiqIJEDg2zFmaXQ3Wyp/xGYzvyN1HtqDafVtMeD4GxuvhYdObkP6nSQkU6ppE5nNk78ZeDJN cloudshell-user@ip-10-134-40-154.ec2.internal"
}

resource "aws_security_group" "tf-sg" {
  name        = "test-tf-sg"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "test-tf-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_ssh" {
  security_group_id = aws_security_group.tf-sg.id
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_http" {
  security_group_id = aws_security_group.tf-sg.id
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_https" {
  security_group_id = aws_security_group.tf-sg.id
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4" {
  security_group_id = aws_security_group.tf-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
}

resource "aws_instance" "terraform_instance" {
  ami                         = "ami-0953476d60561c955"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.kp1.key_name
  vpc_security_group_ids      = [aws_security_group.tf-sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "test-instance"
  }
}

