variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"] 
}

variable "ami_id"{
    default = "ami-084568db4383264d4"
}

variable "instance_type"{
    default = "t2.micro"
}

variable "domain_name" {
  default = "dev.example.com"
}

variable "public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDeIAsc1fvUiwTFvIdcPEfvNp28gawcesMhfGioOf8XwqhajXxgbWNNgAjgECtPDRhXpgVBT4CGF7aMRDRAZnl8U5/afjrKHhw6GKkL9j1TP5ujbXY37jlh3zhhXLy08LdSpzQRZXAFkzXxLG10LPzf8YZN/NOXumIM4nf0af3L0PQ7zdbAC/Q91yY9o4P4ZOONluTrVa4X6FqHvDEZSA7Sencq1gEFqDsov7IYV7E5OvASh12r5eqN3TPf1nli4JmdCTNu82FyYAfIaiqIJEDg2zFmaXQ3Wyp/xGYzvyN1HtqDafVtMeD4GxuvhYdObkP6nSQkU6ppE5nNk78ZeDJN cloudshell-user@ip-10-134-40-154.ec2.internal"
}
