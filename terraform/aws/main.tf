terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Temporarily using local backend to create state infrastructure
  # Uncomment the S3 backend after initial apply
  # backend "s3" {
  #   bucket         = "monitus-terraform-state"
  #   key            = "monitus-infra/terraform.tfstate"
  #   region         = "ap-northeast-3"
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.region
}

# Check for existing S3 bucket
data "aws_s3_bucket" "existing_state" {
  bucket = "monitus-terraform-state"
}

# Check for existing DynamoDB table
data "aws_dynamodb_table" "existing_locks" {
  name = "terraform-state-lock"
}

# Check for existing IAM role
data "aws_iam_role" "existing_ecr_role" {
  name = "monitus-ec2-ecr-role"
}

# Check for existing instance profile
data "aws_iam_instance_profile" "existing_profile" {
  name = "monitus-ec2-profile"
}

# Check for existing instance with same name
data "aws_instances" "existing" {
  filter {
    name   = "tag:Name"
    values = ["monitus"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running", "pending", "stopping", "stopped"]
  }
}

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  count  = try(data.aws_s3_bucket.existing_state.id, "") == "" ? 1 : 0
  bucket = "monitus-terraform-state"

  tags = {
    Name = "Terraform State Bucket"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = try(data.aws_s3_bucket.existing_state.id, "") == "" ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  count        = try(data.aws_dynamodb_table.existing_locks.id, "") == "" ? 1 : 0
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

# IAM role for EC2 to access ECR
resource "aws_iam_role" "ec2_ecr_role" {
  count = try(data.aws_iam_role.existing_ecr_role.arn, null) == null ? 1 : 0
  name = "monitus-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_policy" {
  count      = try(data.aws_iam_role.existing_ecr_role.arn, null) == null ? 1 : 0
  role       = aws_iam_role.ec2_ecr_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  count = try(data.aws_iam_instance_profile.existing_profile.arn, null) == null ? 1 : 0
  name  = "monitus-ec2-profile"
  role  = aws_iam_role.ec2_ecr_role[0].name
}

resource "aws_instance" "app_instance" {
  count                  = length(data.aws_instances.existing.ids) == 0 ? 1 : 0
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = "aws-ec2"
  iam_instance_profile   = try(data.aws_iam_instance_profile.existing_profile.name, aws_iam_instance_profile.ec2_profile[0].name)

  security_groups = [aws_security_group.app_sg.name]

  user_data = <<-EOF
  #!/bin/bash
  dnf update -y
  dnf install -y docker awscli
  systemctl start docker
  systemctl enable docker
  usermod -aG docker ec2-user

  # Authenticate Docker with ECR
  aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com
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
  count    = length(data.aws_instances.existing.ids) == 0 ? 1 : 0
  instance = aws_instance.app_instance[0].id
  domain   = "vpc"
}

# Placeholder for future AWS components
# resource "aws_db_instance" "example" { ... }  # For RDS
