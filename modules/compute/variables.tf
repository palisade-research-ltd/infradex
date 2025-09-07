
variable "pro_region" {
  description = "AWS region for resources"
  type        = string
}

variable "pro_id" {
  description = "ID of the project"
  type        = string
}

variable "pro_env" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  
  validation {
    condition = can(regex("^[tm][0-9][a-z]?\\.", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "security_group" {
  description = "Security group to operate within"
  type        = set(string)
}

variable "subnet_id" {
  description = "Subnet id to operate within"
  type        = string
}

variable "key_pair_name" {
  description = "Key pair name to be used"
  type        = string
}

variable "ec2_profile" {
  description = "aws_iam_profile"
  type        = string
}

