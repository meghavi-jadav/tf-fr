# Attach a new EBS volume to an EC2 instance. Take a snapshot of the volume.


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

data "aws_security_group" "selected" {
  id = "sg-0186f0dc9567a60f3"
}

resource "aws_instance" "terraform_instance" {
  ami                         = "ami-0953476d60561c955"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.kp1.key_name
  vpc_security_group_ids      = [data.aws_security_group.selected.id]
  associate_public_ip_address = true

  tags = {
    Name = "test-instance"
  }
}

resource "aws_ebs_volume" "test-ebs" {
  availability_zone = "us-east-1a"
  size              = 10
  type              = "gp3"
  iops              = 3000
  throughput        = 125
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.test-ebs.id
  instance_id = aws_instance.terraform_instance.id
}

resource "aws_ebs_snapshot" "test_snapshot" {
  volume_id = aws_ebs_volume.test-ebs.id
}
