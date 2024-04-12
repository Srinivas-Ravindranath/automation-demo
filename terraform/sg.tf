# Ca security group that allows HTTP traffic inbound on the load balancer
resource "aws_security_group" "allow_lb_traffic" {
  name        = "aws_lb_sec_group"
  description = "Allow http/https traffic inbound on the load balancer"
  vpc_id      = aws_vpc.project_vpc.id

  tags = {
    Name = "ALB security group"
  }
}

# Allow HTTPS traffic from the internet to the load balancer
resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
  security_group_id = aws_security_group.allow_lb_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Allow HTTP traffic from the internet to the load balancer
resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_lb_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_lb_traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Create a security group that allows HTTP traffic inbound from the load balancer to the EC2 instance
resource "aws_security_group" "allow_lb_traffic_instance" {
  name        = "allow_lb_traffic_instance"
  description = "Allow http/https traffic inbound from the load balancer to EC2 instance"
  vpc_id      = aws_vpc.project_vpc.id

  tags = {
    Name = "EC2 Security group"
  }
}

# Allow HTTPS traffic from the load balancer to the EC2 instance
resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4_instance" {
  security_group_id            = aws_security_group.allow_lb_traffic_instance.id
  referenced_security_group_id = aws_security_group.allow_lb_traffic.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

# Allow HTTP traffic from the load balancer to the EC2 instance
resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4_instance" {
  security_group_id            = aws_security_group.allow_lb_traffic_instance.id
  referenced_security_group_id = aws_security_group.allow_lb_traffic.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_http_ipv4_instance" {
  security_group_id = aws_security_group.allow_lb_traffic_instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
