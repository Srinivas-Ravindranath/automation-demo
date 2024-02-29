terraform {
  backend "s3" {
    bucket = "cloud-computing-6907-81-terraform-state-bucket"
    key    = "demo_deployment/terraform.tfstate"
    region = "us-east-1"
  }
}