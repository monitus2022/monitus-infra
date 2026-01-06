# monitus-infra

Infrastructure as Code (IaC) repository for the Monitus project using Terraform and AWS.

## Overview

This repository contains Terraform configurations for deploying the Monitus application infrastructure on AWS, including:
- EC2 instance with Docker
- ECR access for container images
- Cloudflare origin SSL certificate injection for secure container deployments
- S3 storage for certificates

## Architecture

- **EC2 Instance**: Runs Amazon Linux 2023 with Docker installed
- **Certificate Management**: Cloudflare origin certificates are securely stored in S3 and injected into the instance during startup
- **Container Support**: Certificates are available at `/etc/ssl/cloudflare/` for container mounting

## Prerequisites

- AWS Account with appropriate permissions
- Cloudflare account with origin certificate generated
- GitHub repository with secrets configured

## Required GitHub Secrets

Set the following secrets in your GitHub repository settings:

- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `AWS_ACCOUNT_ID`: Your AWS account ID
- `CLOUDFLARE_ORIGIN_CERT`: Full PEM content of Cloudflare origin certificate
- `CLOUDFLARE_ORIGIN_KEY`: Full PEM content of Cloudflare origin private key

## Deployment

### Automatic Deployment

Pushes to the `main` branch automatically trigger the GitHub Actions workflow, which:
1. Runs `terraform plan`
2. Applies changes if approved (manual approval step)
3. Deploys infrastructure to AWS

### Manual Deployment

To deploy manually:

1. Clone the repository
2. Navigate to `terraform/aws/`
3. Create a `terraform.tfvars` file with your values
4. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Certificate Setup

The Cloudflare origin certificate is automatically injected into the EC2 instance at `/etc/ssl/cloudflare/origin.pem` and `/etc/ssl/cloudflare/origin.key`. Containers can mount this directory to use the certificates for HTTPS termination.

## State Management

Terraform state is stored in S3 with DynamoDB locking. After initial deployment, uncomment the S3 backend in `main.tf` and run `terraform init` to migrate state.

## Security

- Certificates are stored encrypted in S3
- IAM roles follow least-privilege principle
- Sensitive variables are marked as such in Terraform
