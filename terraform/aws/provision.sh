#!/bin/bash

set -e

# Load environment variables from .env file
if [ -f .env ]; then
  source .env
else
  echo "Error: .env file not found. Please copy .env.template to .env and fill in your secrets."
  exit 1
fi

# Check for AWS credentials
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "Warning: AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY not set. Please add them to .env file."
else
  echo "Testing AWS credentials..."
  if aws sts get-caller-identity --region ap-northeast-3 >/dev/null 2>&1; then
    echo "AWS credentials are valid."
  else
    echo "Error: AWS credentials are invalid or region is incorrect."
    exit 1
  fi
fi

# Load certificate files
if [ -f origin.pem ] && [ -f origin.key ]; then
  CLOUDFLARE_ORIGIN_CERT=$(cat origin.pem)
  CLOUDFLARE_ORIGIN_KEY=$(cat origin.key)
else
  echo "Error: origin.pem and/or origin.key files not found. Please place them in this directory."
  exit 1
fi

# Check if backend is commented
if grep -q "# backend \"s3\"" main.tf; then
  backend_commented=true
else
  backend_commented=false
fi

echo "Backend commented: $backend_commented"

# Terraform Init
if [ "$backend_commented" = true ]; then
  echo "Initializing with local backend..."
  terraform init
else
  echo "Initializing with S3 backend..."
  terraform init -reconfigure
fi

# Terraform Plan
echo "Planning..."
terraform plan \
  -var="account_id=$AWS_ACCOUNT_ID" \
  -var="cloudflare_origin_cert=$CLOUDFLARE_ORIGIN_CERT" \
  -var="cloudflare_origin_key=$CLOUDFLARE_ORIGIN_KEY" \
  -out=tfplan

# Terraform Apply
echo "Applying..."
terraform apply -auto-approve tfplan

# If backend was commented, upload state and switch to S3
if [ "$backend_commented" = true ]; then
  echo "Uploading state to S3..."
  if [ -f .terraform/terraform.tfstate ]; then
    aws s3 cp .terraform/terraform.tfstate s3://monitus-terraform-state/monitus-infra/terraform.tfstate --region ap-northeast-3
    rm -rf .terraform
  fi

  echo "Uncommenting S3 backend..."
  sed -i '' 's/# \(backend "s3" {\)/\1/' main.tf
  sed -i '' 's/# \(  bucket.*\)/\1/' main.tf
  sed -i '' 's/# \(  key.*\)/\1/' main.tf
  sed -i '' 's/# \(  region.*\)/\1/' main.tf
  sed -i '' 's/# \(  use_lockfile.*\)/\1/' main.tf
  sed -i '' 's/# \(}\)/\1/' main.tf

  echo "Reinitializing with S3 backend..."
  terraform init -reconfigure -lock=false
fi

# Display Outputs
echo "Outputs:"
terraform output