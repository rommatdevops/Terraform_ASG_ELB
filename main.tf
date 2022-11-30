terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.45"
    }
  }
}

provider "aws" {
  region = var.region
}
resource "aws_key_pair" "my_auth" {
  key_name   = "my_key"
  public_key = file("/home/user/.ssh/id_ed25519.pub")
}

#resource "aws_instance" "home_menu_cicd_instance" {
#  ami           = data.aws_ami.server_ami.id
#  instance_type = var.instance_type
#  key_name      = aws_key_pair.my_auth.id
#  vpc_security_group_ids = [aws_security_group.server_security_group.id]
#
#  tags = {
#    Name = "${var.environment}-home_menu_cicd_instance"
#  }
#}

resource "aws_security_group" "server_security_group" {
  name        = "Basic security group"
  description = "Allow http, https, ssh ports"

  dynamic "ingress" {
    for_each = ["80", "443", "22", "8080", "8000"]
    content {
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"
      cidr_blocks = var.default_cidr_blocks
    }
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = var.default_cidr_blocks
  }

  tags = {
    Name = "${var.environment}-home_menu_cicd_SG"
  }
}

resource "aws_launch_configuration" "web" {
  name          = "Web-Server-Highly-Available-LC"
  image_id      = data.aws_ami.ubuntu_ami.id
  instance_type = var.instance_type
  security_groups = [aws_security_group.server_security_group.id]
  user_data     = file("user_data.sh")
  key_name      = aws_key_pair.my_auth.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name                 = "ASG-${aws_launch_configuration.web.name}"
  launch_configuration = aws_launch_configuration.web.name
  max_size             = 2
  min_size             = 2
  min_elb_capacity     = 2
  health_check_grace_period = 300
  health_check_type    = "EC2"
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  load_balancers       = [aws_elb.web.name]

  dynamic "tag" {
    for_each = {
      Name   = "WebServer in ASG"
      Owner  = "Roman"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "web" {
  name = "WebServer-HA-ELB"
  availability_zones  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  security_groups     = [aws_security_group.server_security_group.id]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    interval            = 8
    target              = "HTTP:80/"
    timeout             = 3
    unhealthy_threshold = 2
  }

  tags = {
    Name = "WebServer-Highly-Available-ELB"
  }
}


resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}

output "web_loadbalancer_url" {
  value = aws_elb.web.dns_name
}