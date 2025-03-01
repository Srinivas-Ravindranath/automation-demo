variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The aws region the resources have to be deployed to"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR range"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 32))
    error_message = "VPC CIDR range is invalid please use the x.x.x.x or x.x.x.x/x CIDR range"
  }
}

variable "enable_dns_support_vpc" {
  type        = bool
  default     = true
  description = "Whether DNS Support should be enabled for VPC"
}

variable "enable_dns_hostnames_vpc" {
  type        = bool
  default     = true
  description = "Whether DNS hostnames should be enabled for the VPC"
}


variable "public_subnet_count" {
  type        = number
  default     = 2
  description = "Number of public subnets that need to be created"

  validation {
    condition     = var.public_subnet_count > 0 && var.public_subnet_count < 6
    error_message = "Please enter a number of public subnets between 1 and 5"
  }
}

variable "private_subnet_count" {
  type        = number
  default     = 2
  description = "Number of private subnets that need to be created"

  validation {
    condition     = var.private_subnet_count > 0 && var.private_subnet_count < 6
    error_message = "Please enter a number of private subnets between 1 and 5"
  }
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "List of subnet CIDR ranges for the public subnet(list should contain the no of subnet cidr's equal to public subnet count"
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "List of subnet CIDR ranges for the private subnet(list should contain the no of subnet cidr's equal to private subnet count"
  default     = ["10.0.32.0/20", "10.0.48.0/20"]
}

variable "availability_zones" {
  type        = list(string)
  description = "The availability zones to which the subnets have to be deployed"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "load_balancer_name" {
  type        = string
  description = "The name for the application load balancer being created"
  default     = "website-alb"
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable/Disable deletion protection for ALB"
  default     = false
}

variable "target_group_name" {
  type        = string
  description = "Name for the target group being attached to the ALB"
  default     = "web-target-group"
}

variable "asg_name" {
  type        = string
  description = "The name for the autoscaling group for the server"
  default     = "demo-asg"
}

variable "placement_group_name" {
  type        = string
  default     = "web-demo-placement-group"
  description = "The name for the placement group of the auto scaling group"
}
variable "placement_group_type" {
  type        = string
  default     = "partition"
  description = "The type of placement for the cluster in the auto scaling group"
}

variable "asg_max_size" {
  type        = string
  default     = "5"
  description = "The maximum number of ec2 instances that can run in the autoscaling group"
}
variable "asg_min_size" {
  type        = string
  default     = "0"
  description = "The minimum number of ec2 instances that need to be running in the autoscaling group"
}
variable "desired_capacity" {
  type        = string
  default     = "3"
  description = "The number of EC2 instances that have to be up and running at all times when auto scaling is active"
}

variable "min_healthy_percentage" {
  type        = string
  default     = "50"
  description = "The minimum health of the autoscaling cluster that needs to be maintained to prevent descaling"
}

variable "max_healthy_percentage" {
  type        = string
  default     = "100"
  description = "The maximum of health of the autoscaling cluster that can be maintained when up scaling(can be over 100)"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "The type of EC2 instance that we need to spin up in the autoscaling group"
}

variable "ssh_key_name" {
  type        = string
  default     = "vockey"
  description = "The SSH key name we need to associate with the EC2 instances we will spin up with the auto scaling group"
}

variable "launch_template_prefix" {
  type        = string
  default     = "web-server-launch-template"
  description = "The name for the launch  template to be associated with the auto scaling group"
}

variable "image_details" {
  type = object({
    image_name          = string
    virtualization-type = string
    root-device-type    = string
    owners              = string
  })
  default = {
    image_name          = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    virtualization-type = "hvm"
    root-device-type    = "ebs"
    owners              = "amazon"
  }
  description = <<EOT
      image_name : "The image name for the ami to be used on the launch template"
      virtualization-type : "The virtualization type for the ami. Valid values are paravirtual or hvm"
      root-device-type : "The type of the root device volume, valid values are ebs or instance-store"
      owners : "The owners of the AMI, valid values are (amazon, aws-marketplace, microsoft)"
    }
  EOT
}

variable "jenkins_job_name" {
  type        = string
  description = "The name of the jenkins job that built the deployment"
  default     = "demo-job"
}