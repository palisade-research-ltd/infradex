
# Output important information
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.data_pipeline_eip.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.data_pipeline.private_ip
}

