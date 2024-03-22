output "load_balancer_dns" {
  value = aws_lb.website_load_balancer.dns_name
}