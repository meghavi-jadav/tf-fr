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

variable "requester_profile" {
    description = "AWS Requester ID"
    default = ""
}

variable "accepter_profile"{
    description = "AWS Accepter ID"
    default = ""
}

variable "aws_region" {
    description = "AWS Region"
    default = "us-east-1"
}

variable "requester_vpc_id" {
    description = "VPC ID of the Requester"
    default = ""
}

variable "accepter_vpc_id" {
    description = "VPC ID of the Accepter"
    default = ""
}



provider "aws" {
  alias   = "requester"
  region  = var.aws_region
  profile = var.requester_profile
}

provider "aws" {
  alias   = "accepter"
  region  = var.aws_region
  profile = var.accepter_profile
}

data aws_vpc "requester_vpc" {
    provider = aws.requester
    id = var.requester_vpc_id
}

data aws_vpc "accepter_vpc"{
    provider = aws.accepter
    id = var.accepter_vpc_id
}

resource "aws_vpc_peering_connection" "vpc-peering" {
  peer_owner_id = "${var.accepter_profile}"
  peer_vpc_id   = "${data.aws_vpc.accepter_vpc.id}"
  vpc_id        = "${data.aws_vpc.requester_vpc.id}"
  peer_region   = var.aws_region
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  provider = aws.accepter
  vpc_peering_connection_id = "${aws_vpc_peering_connection.vpc-peering.id}"
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}
