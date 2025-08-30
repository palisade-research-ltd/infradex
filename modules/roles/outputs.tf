
output "ec2_profile" {
  description = "ec2 instance profile name"
  value = aws_iam_instance_profile.ec2_profile_name
}

