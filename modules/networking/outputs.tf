
output "aws_security_group_id" {
  description = "ID for the security group"
  value = [aws_security_group.data_pipeline_sg.id]
}

output "aws_subnet_id" {
  description = "ID for the subnet"
  value = aws_subnet.public.id
}

