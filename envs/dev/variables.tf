
variable "pro_project_id" {
  description = "Id of the project"
  type        = string
  default     = "infradex"
}

variable "pro_environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "pro_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "pro_name" {
  description = "Name of the project"
  type        = string
  default     = "infradex"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"

  validation {
    condition     = can(regex("^[tm][0-9][a-z]?\\.", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "public_key" {
  description = "Public key for EC2 key pair"
  type        = string
}

variable "private_key_path" {
  description = "Path to private key file for SSH access"
  type        = string
  default     = "~/.ssh/id_rsa"
}

