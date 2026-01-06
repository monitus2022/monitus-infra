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
- AWS CLI installed and configured with credentials
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

### Local Deployment

To deploy locally using the provided script:

1. Clone the repository
2. Navigate to `terraform/aws/`
3. Copy `.env.template` to `.env` and fill in your AWS credentials:
   ```bash
   cp .env.template .env
   # Edit .env with your AWS Account ID, Access Key ID, and Secret Access Key
   ```
4. Place your Cloudflare origin certificate files in `terraform/aws/`:
   - `origin.pem`: The certificate file
   - `origin.key`: The private key file
5. Configure AWS credentials using one of the following methods:
   - Run `aws configure` to set up your credentials interactively.
   - Or export environment variables:
     ```bash
     export AWS_ACCESS_KEY_ID=your_access_key
     export AWS_SECRET_ACCESS_KEY=your_secret_key
     export AWS_DEFAULT_REGION=ap-northeast-3
     ```
6. Run the provisioning script:
   ```bash
   ./provision.sh
   ```

The script handles initialization, planning, applying, and backend migration automatically.

## Certificate Setup

The Cloudflare origin certificate is automatically injected into the EC2 instance at `/etc/ssl/cloudflare/origin.pem` and `/etc/ssl/cloudflare/origin.key`. Containers can mount this directory to use the certificates for HTTPS termination.

## State Management

Terraform state is stored in S3 with DynamoDB locking. The provisioning script automatically handles backend migration from local to S3 after the initial apply.

## Security

- Certificates are stored encrypted in S3
- IAM roles follow least-privilege principle
- Sensitive variables are marked as such in Terraform
