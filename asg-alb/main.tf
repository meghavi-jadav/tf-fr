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

resource "aws_launch_template" "lt-tf" {
    name = "lt-tf"
    image_id = "ami-084568db4383264d4"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["sg-0186f0dc9567a60f3"]

    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "lt-tf-instance"
        }
    }

}

resource "aws_autoscaling_group" "asg-tf" {
    name = "asg-tf"
    desired_capacity   = 1
    min_size           = 1
    max_size           = 2
    
    launch_template {
        id = aws_launch_template.lt-tf.id
        version = aws_launch_template.lt-tf.latest_version


    }

    vpc_zone_identifier  = ["subnet-0d07cf27e2ab66e5c", "subnet-02ce607451364073d"]
    # availability_zones = ["us-east-1a", "us-east-1b"]
    health_check_type     = "EC2"
}

resource "aws_autoscaling_attachment" "asg-att" {
  autoscaling_group_name = aws_autoscaling_group.asg-tf.name
  lb_target_group_arn    = "arn:aws:elasticloadbalancing:us-east-1:552429782677:targetgroup/test-tg/245c220ae162b6dc"
  depends_on             = [aws_autoscaling_group.asg-tf]
}
