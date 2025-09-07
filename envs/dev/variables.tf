
variable "pro_id" {
  description = "Id of the project"
  type        = string
}

variable "pro_env" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "pro_region" {
  description = "AWS region for resources"
  type        = string
}

variable "instance_type" {
  description = ""
  type        = string
}

variable "instance_ami" {
  description = "Amazon Machine Image (AMI) for the Ec2 instance of the datalake"
  type        = string
}

variable "key_pair_name" {
  description = "key pair to connect to AWS, stored as terraform sensitive variable"
  type        = string
}

variable "bybit_account_no_01" {}
variable "bybit_access_key_01" {}
variable "bybit_secret_key_01" {}

