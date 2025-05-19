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

resource "aws_iam_group" "administration" {
  name = "administration"
}

resource "aws_iam_group_policy_attachment" "test-attach" {
  group      = aws_iam_group.administration.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user" "admin-user" {
  name = "admin-1"

  tags = {
    Department = "Admin"
  }
}

resource "aws_iam_user_group_membership" "user-group-membership" {
  user = aws_iam_user.admin-user.name

  groups = [
    aws_iam_group.administration.name
  ]
}


# resource "aws_iam_group_policy" "admin_policy" {
#   name  = "admin_policy"
#   group = aws_iam_group.administration.name

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": "*",
#             "Resource": "*"
#         }
#     ]
#   })
# }