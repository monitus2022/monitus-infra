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