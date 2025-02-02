# Data Source to Fetch CloudFront Managed Prefix List
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# Security Group for Load Balancer
resource "aws_security_group" "ecommerce_sg_for_elb" {
  name   = "ecommerce-sg-for-elb"
  vpc_id = aws_vpc.ecommerce_vpc.id

  # Allow HTTP traffic from CloudFront edge locations
  ingress {
    description      = "Allow HTTP traffic from CloudFront edge locations"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    prefix_list_ids  = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  # Allow HTTPS traffic from CloudFront edge locations
  ingress {
    description      = "Allow HTTPS traffic from CloudFront edge locations"
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    prefix_list_ids  = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-sg-for-elb"
  }
}

resource "aws_security_group" "ecommerce_sg_for_ec2" {
  name   = "ecommerce-sg_for_ec2"
  vpc_id = aws_vpc.ecommerce_vpc.id

  ingress {
    description     = "Allow http request from Load Balancer"
    protocol        = "tcp"
    from_port       = 80 # range of
    to_port         = 80 # port numbers
    security_groups = [aws_security_group.ecommerce_sg_for_elb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}