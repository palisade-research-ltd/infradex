
variable "pro_id" {
  description = "Id of the project"
  type        = string
}

variable "pro_environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "pro_region" {
  description = "AWS region for resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string

  validation {
    condition     = can(regex("^[tm][0-9][a-z]?\\.", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "private_key_path" {
  description = "Path to private key file for SSH access"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "public_key" {
  description = "AWS Access Key"
  type        = string
}

# variable "secret_access_key" {
#   description = "AWS Secret Access Key"
#   type        = string
# }
#
