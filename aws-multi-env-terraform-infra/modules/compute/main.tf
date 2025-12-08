data "aws_key_pair" "existing" {
  key_name = "multi-env-key"  # EXACT name as in EC2 console
  # include_public_key = true  # optional
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

     filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

}


resource "aws_iam_role" "ssm" {
  name = "${var.app_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.app_name}-ssm-profile"
  role = aws_iam_role.ssm.name
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.app_name}-lt-"
  key_name      = data.aws_key_pair.existing.key_name
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  update_default_version = true

  vpc_security_group_ids = [var.app_sg_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              yum install -y telnet
              yum install -y amazon-ssm-agent
              systemctl enable httpd
              systemctl start httpd
              systemctl enable --now amazon-ssm-agent
              echo "Hello from ${var.app_name}" > /var/www/html/index.html
              EOF
  )
}



resource "aws_lb" "this" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]
}

resource "aws_lb_target_group" "this" {
  name     = "${var.app_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}

#data "aws_vpc" "selected" {
  #id = aws_lb.this.vpc_id
#}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_autoscaling_group" "this" {
    name                = "${var.app_name}-asg"
    max_size            = 3
    min_size            = 1
    desired_capacity    = 1
    vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  
  target_group_arns = [aws_lb_target_group.this.arn]
  
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup = 300
    }
  }

  

  lifecycle {
    create_before_destroy = true
  }
}
 