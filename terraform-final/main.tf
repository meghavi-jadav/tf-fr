terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


#-----------Local-----------

locals{
    project_name = "tf-final"
    tags = {
        Name = local.project_name
        Environment = "dev"
    }
} 

#-----------VPC-----------
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = local.tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = local.tags
}

resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "public-subnet${count.index + 1}"
  }
}

#-----------Route Table-----------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = local.tags
}

resource "aws_route_table_association" "public" {
  count = 2
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#-----------Security Group----------
resource "aws_security_group" "sg" {
  name = "${local.project_name}-sg"
  description = "allowing HTTP and HTTPS"
  vpc_id = aws_vpc.vpc.id
  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port = 0
  to_port   = 0
  ip_protocol       = "-1" 
}


#-----------EC2(Compute)-----------

resource "aws_key_pair" "fkp" {
  key_name = "fkp"
  public_key = var.public_key
}

resource "aws_instance" "instance" {
  ami = var.ami_id
  instance_type = var.instance_type
  key_name = aws_key_pair.fkp.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = true
  subnet_id = aws_subnet.public[0].id
  tags = {
    Name = "${local.project_name}-instance"
  }
}


#-----------Launch Template-----------


resource "aws_launch_template" "lt-tf" {
    name = "${local.project_name}-lt"
    image_id = var.ami_id
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.sg.id]

    tag_specifications {
        resource_type = "instance"
        tags = local.tags
    }
}
#-----------Load Balancer-----------

resource "aws_lb" "lb" {
  name               = "${local.project_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [ aws_subnet.public[*].id ]

  tags = local.tags
}

#-----------Target Group-----------


resource "aws_lb_target_group" "tg" {
  name        = "${local.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    path = "/health"
    interval = 30
    timeout = 5
  }
}

resource "aws_lb_target_group_attachment" "tg-target" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.instance.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

#-----------Autoscaling Group-----------

resource "aws_autoscaling_group" "asg" {
  desired_capacity   = 2
  max_size           = 2
  min_size           = 1
  vpc_zone_identifier = [ aws_subnet.public[*].id ]
  target_group_arns = [ aws_lb_target_group.tg.arn ]
  launch_template {
    id      = aws_launch_template.lt-tf.id
    version = "$Latest"
  }
}

#-----------Route53-----------

resource "aws_route53_zone" "dev" {
  name = var.domain_name
  tags = local.tags
}

resource "aws_route53_record" "dev-hz" {
  zone_id = aws_route53_zone.dev.zone_id
  name    = var.domain_name
  type    = "A"
#   ttl     = "300"
  alias {
    name                   = aws_lb.lb.name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true

    # name                   = aws_cloudfront_distribution.alb_distribution.domain_name
    # zone_id                = aws_cloudfront_distribution.alb_distribution.hosted_zone_id
    # evaluate_target_health = false
  }
}

#-----------CloudFront Distribution-----------

resource "aws_cloudfront_distribution" "alb_distribution" {
  enabled         = true
  is_ipv6_enabled     = false
  aliases         = [var.domain_name, "*.${var.domain_name}", "www.${var.domain_name}"]
   price_class     = "PriceClass_100" 
   

   origin {
    domain_name = aws_lb.lb.dns_name
    origin_id   = aws_lb.lb.id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    origin_shield {
      enabled              = false
    }
   }

   default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = aws_lb.lb.id
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"

   }

   restrictions {
    geo_restriction {
      restriction_type = "none"
    }
   }

   viewer_certificate {
#     acm_certificate_arn = var.cf_ertificate_arn
#     ssl_support_method  = "sni-only"
   }
  depends_on = [aws_lb.lb]
}

