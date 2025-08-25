
variable "pro_name" {
  description = "Name of the project"
  type = string
  default = "infradex"
}

variable "pro_project_id" {
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

variable "public_key" {
  description = "Public key for EC2 key pair"
  type        = string
  # You'll need to provide this when running terraform apply
  # Example: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."
}

variable "private_key_path" {
  description = "Path to private key file for SSH access"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "instance_type" {
  description = "compute instance type"
  type = string
  default = "infradex"
}

