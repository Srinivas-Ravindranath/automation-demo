resource "aws_lb" "website_load_balancer" {
  name               = var.load_balancer_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_lb_traffic.id]
  subnets            = aws_subnet.public_subnet.*.id

  enable_deletion_protection = var.enable_deletion_protection

  # Best Practice but not required for the DEMO

  #  access_logs {
  #    bucket  = aws_s3_bucket.lb_logs.id
  #    prefix  = "test-lb"
  #    enabled = true
  #  }

  tags = {
    Name = "Website Load balancer"
  }
}

resource "aws_lb_target_group" "website_target_group" {
  name     = var.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.project_vpc.id
}

#resource "aws_lb_listener" "load_balancer_listener" {
#  load_balancer_arn = aws_lb.website_load_balancer.arn
#  port = 80
#  protocol = "HTTP"
#
#  default_action {
#    target_group_arn = aws_lb_target_group.website_target_group.arn
#    type = "forward"
#  }
#}
