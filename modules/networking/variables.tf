
variable "pro_id" {
  description = "Id of the project"
  type = string
  default = "infradex"
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

variable "private_key_path" {
  description = "Path to private key file for SSH access"
  type        = string
  default     = "~/.ssh/id_rsa"
}

