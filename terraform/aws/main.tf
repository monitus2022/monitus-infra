terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
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

}

# Placeholder for future AWS components
# resource "aws_db_instance" "example" { ... }  # For RDS
# resource "aws_s3_bucket" "example" { ... }    # For S3
