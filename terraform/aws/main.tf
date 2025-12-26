terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "monitus-terraform-state"
    key            = "monitus-infra/terraform.tfstate"
    region         = "ap-northeast-3"
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.region
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "monitus-terraform-state"

  tags = {
    Name = "Terraform State Bucket"
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}

resource "aws_security_group" "app_sg" {
  name_prefix = "monitus-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict to your IP in production
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Placeholder for future components (e.g., HTTPS, database access)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name = "aws-ec2"

  security_groups = [aws_security_group.app_sg.name]

  user_data = <<-EOF
  #!/bin/bash
  dnf update -y
  dnf install -y docker
  systemctl start docker
  systemctl enable docker
  usermod -aG docker ec2-user
  EOF

  tags = {
    Name = "monitus"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [user_data]
  }
}

resource "aws_eip" "app_eip" {
  instance = aws_instance.app_instance.id
  domain   = "vpc"
}

# Placeholder for future AWS components
# resource "aws_db_instance" "example" { ... }  # For RDS
