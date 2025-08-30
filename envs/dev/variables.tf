
variable "pro_id" {
  description = "Id of the project"
  type        = string
  default     = "infradex"
}

variable "pro_environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev_infradex"
}

variable "pro_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = ""
  type        = string
  default     = "t3.micro"
}

variable "bybit_account_no_01" {}
variable "bybit_access_key_01" {}
variable "bybit_secret_key_01" {}

