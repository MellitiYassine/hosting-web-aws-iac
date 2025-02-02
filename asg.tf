# IAM Role for EC2 Instances
resource "aws_iam_role" "ecommerce_ec2_role" {
  name = "ecommerce-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for S3 Access
resource "aws_iam_policy" "ecommerce_s3_access_policy" {
  name        = "ecommerce-s3-access-policy"
  description = "Policy to allow EC2 instances to access the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.ecommerce_jar_bucket.arn,
          "${aws_s3_bucket.ecommerce_jar_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "ecommerce_s3_access_attachment" {
  role       = aws_iam_role.ecommerce_ec2_role.name
  policy_arn = aws_iam_policy.ecommerce_s3_access_policy.arn
}

# IAM Instance Profile for EC2 Instances
resource "aws_iam_instance_profile" "ecommerce_ec2_profile" {
  name = "ecommerce-ec2-profile"
  role = aws_iam_role.ecommerce_ec2_role.name
}

# Update Launch Template to Use IAM Role
resource "aws_launch_template" "ecommerce_ec2_launch_templ" {
  name_prefix   = "ecommerce-ec2-launch-templ"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.ecommerce_ec2_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Install AWS CLI (if not already installed)
              yum update -y
              yum install -y aws-cli

              # Download JAR file from S3 bucket
              aws s3 cp s3://${aws_s3_bucket.ecommerce_jar_bucket.bucket}/be-ecommerce-0.0.1-SNAPSHOT.jar /home/ec2-user/be-ecommerce-0.0.1-SNAPSHOT.jar

              # Run the JAR file
              java -jar /home/ec2-user/be-ecommerce-0.0.1-SNAPSHOT.jar &
              EOF
              )

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = aws_subnet.ecommerce_priv_subnet_2.id
    security_groups             = [aws_security_group.ecommerce_sg_for_ec2.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecommerce-instance"
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