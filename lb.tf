# Application Load Balancer (ALB)
resource "aws_lb" "ecommerce_lb" {
  name               = "ecommerce-lb-asg"
  internal           = false # Internet-facing ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecommerce_sg_for_elb.id]
  subnets            = [aws_subnet.ecommerce_pub_subnet_1.id, aws_subnet.ecommerce_pub_subnet_2.id] # Use public subnets

  tags = {
    Name = "ecommerce-lb"
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "ecommerce_alb_tg" {
  name     = "ecommerce-tf-lb-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ecommerce_vpc.id # Correct VPC reference

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }

  tags = {
    Name = "ecommerce-alb-tg"
  }
}

# ALB Listener
resource "aws_lb_listener" "ecommerce_front_end" {
  load_balancer_arn = aws_lb.ecommerce_lb.arn # Correct ALB ARN reference
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecommerce_alb_tg.arn
  }

  tags = {
    Name = "ecommerce-alb-listener"
  }
}