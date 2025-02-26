#!/usr/bin/env bash

set -euo pipefail

# The folder where your Terraform code lives
TERRAFORM_DIR="$(git rev-parse --show-toplevel)/terraform"

echo "Terraform directory: $TERRAFORM_DIR"

echo "==> Checking Terraform format..."
terraform fmt -check -recursive "${TERRAFORM_DIR}"

echo "==> Installing tfsec..."
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install.sh | bash
sudo mv tfsec /usr/local/bin

echo "==> Scanning Terraform code with tfsec..."
tfsec "${TERRAFORM_DIR}"