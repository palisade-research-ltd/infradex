
variable "public_ip" {
  description = "Inherited from compute"
  type        = string
}

variable "private_key_path" {
  description = "Path to private key file for SSH access"
  type        = string
  default     = "~/.ssh/id_rsa"
}

