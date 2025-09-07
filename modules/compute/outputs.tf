
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.features_compute_eip.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.features_compute.private_ip
}

output "ml_model_api_url" {
  description = "ML Model API URL"
  value       = "http://${aws_eip.features_compute_eip.public_ip}:5000"
}

