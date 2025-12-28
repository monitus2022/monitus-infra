output "instance_public_ip" {
  value = length(data.aws_instances.existing.ids) > 0 ? "Instance already exists - check AWS console for details" : aws_instance.app_instance[0].public_ip
}

output "security_group_id" {
  value = aws_security_group.app_sg.id
}

output "elastic_ip" {
  value = length(data.aws_instances.existing.ids) > 0 ? "EIP not created - instance already exists" : aws_eip.app_eip[0].public_ip
}

# Placeholder for future outputs
# output "db_endpoint" { value = aws_db_instance.example.endpoint }
