# Configure the S3 bucket to store the Terraform state file
terraform {
  backend "s3" {
    bucket = "cloud-computing-6907-81-terraform-state-bucket-new"
    key    = "demo_deployment/terraform.tfstate"
    region = "us-east-1"
  }
}