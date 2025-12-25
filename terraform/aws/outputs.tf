output "instance_public_ip" {
  value = aws_instance.app_instance.public_ip
}

output "security_group_id" {
  value = aws_security_group.app_sg.id
}

output "elastic_ip" {
  value = aws_eip.app_eip.public_ip
}

# Placeholder for future outputs
# output "db_endpoint" { value = aws_db_instance.example.endpoint }
