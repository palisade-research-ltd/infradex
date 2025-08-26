
# output "instance_public_ip" {
#  description = "Public IP address of the EC2 instance"
#  value       = module.networking.aws_eip.data_pipeline_eip.public_ip
# }

# output "clickhouse_url" {
#  description = "ClickHouse HTTP interface URL"
#  value       = "http://${aws_eip.data_pipeline_eip.public_ip}:8123"
# }

# output "ml_model_api_url" {
#   description = "ML Model API URL"
#   value       = "http://${aws_eip.data_pipeline_eip.public_ip}:5000"
# }

# output "data_pipeline_api_url" {
#   description = "Data Pipeline API URL"
#   value       = "http://${aws_eip.data_pipeline_eip.public_ip}:8080"
# }

# output "ssh_command" {
#  description = "SSH command to connect to the instance"
#  value       = "ssh -i ${var.private_key_path} ec2-user@${var.public_ip}"
# }

