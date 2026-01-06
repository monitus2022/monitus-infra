variable "region" {
  description = "AWS region"
  default     = "ap-northeast-3"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-06571d6ae17e327ff"  # Amazon Linux 2023 in ap-northeast-3
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "cloudflare_origin_cert" {
  description = "Cloudflare origin certificate PEM content"
  type        = string
  sensitive   = true
}

variable "cloudflare_origin_key" {
  description = "Cloudflare origin private key PEM content"
  type        = string
  sensitive   = true
}