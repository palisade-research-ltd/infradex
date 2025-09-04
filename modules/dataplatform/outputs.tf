
output "s3_deployment_files_id" {
  description = "ID of the deployment files S3 bucket"
  value = aws_s3_bucket.s3_deployment_files.id
}

output "clickhouse_url" {
  description = "ClickHouse HTTP interface URL"
  value       = "http://${aws_eip.data_lake_eip.public_ip}:8123"
}

output "ml_model_api_url" {
  description = "ML Model API URL"
  value       = "http://${aws_eip.data_lake_eip.public_ip}:5000"
}

output "data_pipeline_api_url" {
  description = "Data Pipeline API URL"
  value       = "http://${aws_eip.data_lake_eip.public_ip}:8080"
}

