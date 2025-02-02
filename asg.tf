# Launch Template
resource "aws_launch_template" "ecommerce_ec2_launch_templ" {
  name_prefix   = "ecommerce-ec2-launch-templ"
  image_id      = data.aws_ami.latest_amazon_linux.id # Dynamically fetch the latest Amazon Linux AMI
  instance_type = "t2.micro"
  user_data     = filebase64("user_data.sh")

  network_interfaces {
    associate_public_ip_address = false # No public IP since instances are in private subnets
    subnet_id                   = aws_subnet.ecommerce_priv_subnet_2.id # Correct subnet reference
    security_groups             = [aws_security_group.ecommerce_sg_for_ec2.id] # Correct security group reference
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecommerce-instance" # Name for the EC2 instances
    }
  }

  tags = {
    Name = "ecommerce-launch-template"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecommerce_asg" {
  name_prefix          = "ecommerce-asg-"
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.ecommerce_priv_subnet_1.id, aws_subnet.ecommerce_priv_subnet_2.id] # Use both private subnets
  target_group_arns    = [aws_lb_target_group.ecommerce_alb_tg.arn] # Correct target group reference

  launch_template {
    id      = aws_launch_template.ecommerce_ec2_launch_templ.id
    version = "$Latest" # Use the latest version of the launch template
  }

}

# Data Source to Fetch the Latest Amazon Linux AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}