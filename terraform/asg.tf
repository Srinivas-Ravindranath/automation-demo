resource "aws_placement_group" "demo_server_placement_group" {
  name     = var.placement_group_name
  strategy = var.placement_group_type
}


resource "aws_autoscaling_group" "demo_servers" {
  #  depends_on = [aws_lb_target_group.website_target_group]

  name                      = var.asg_name
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = var.desired_capacity
  force_delete              = true
  placement_group           = aws_placement_group.demo_server_placement_group.id
  vpc_zone_identifier       = aws_subnet.private_subnet.*.id

  instance_maintenance_policy {
    min_healthy_percentage = var.min_healthy_percentage // keep this low like 50%
    max_healthy_percentage = var.max_healthy_percentage // keep this also low like 70% to avoid costs on demo
  }

  launch_template {
    id      = aws_launch_template.web_server_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Demo Web Server ASG"
    propagate_at_launch = true
  }

  tag {
    key                 = "image-name"
    value               = var.image_details["image_name"]
    propagate_at_launch = false
  }

  tag {
    key                 = "root-device"
    value               = var.image_details["root-device-type"]
    propagate_at_launch = false
  }

  tag {
    key                 = "virtualization-type"
    value               = var.image_details["virtualization-type"]
    propagate_at_launch = false
  }

  tag {
    key                 = "owners"
    value               = var.image_details["owners"]
    propagate_at_launch = false
  }

  tag {
    key                 = "jenkins_job_name"
    value               = var.jenkins_job_name
    propagate_at_launch = false
  }

    target_group_arns = [aws_lb_target_group.website_target_group.arn]

}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.image_details["image_name"]]
  }

  filter {
    name   = "virtualization-type"
    values = [var.image_details["virtualization-type"]]
  }

  filter {
    name   = "root-device-type"
    values = [var.image_details["root-device-type"]]
  }

  owners = [var.image_details["owners"]]
}


resource "aws_launch_template" "web_server_template" {
  name_prefix   = var.launch_template_prefix
  image_id      = "ami-0eb45246cba02871b"
  instance_type = var.instance_type

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }
  vpc_security_group_ids = [aws_security_group.allow_lb_traffic_instance.id]
  key_name               = var.ssh_key_name
  user_data              = filebase64("${path.module}/shell_scripts/user_data.sh")
}