
output "clickhouse_url" {
  description = "ClickHouse HTTP interface URL"
  value       = "http://${aws_eip.data_pipeline_eip.public_ip}:8123"
}

