
// --- ------------------------------------------------------------------- PROJECT VARIABLES --- //
// --- ------------------------------------------------------------------- ----------------- --- //

variable "prj_project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "prj_region" {
  description = "The GCP region where resources will be created"
  type        = string
}

variable "prj_zone" {
  description = "The GCP zone where resources will be created"
  type        = string
}

variable "prj_environment" {
  description = "a Tag to identify different environments to deploy"
  type        = string
}

// --- -------------------------------------------------------------------- MODULE VARIABLES --- //
// --- -------------------------------------------------------------------- ---------------- --- //

variable "cmp_instance_type" {
  type        = string
  description = "The instance type for the server"
  default     = "e2-small"
}

variable "cmp_instance_name" {
  type        = string
  description = "The instance name for the server"
}

variable "cmp_instance_image" {
  type        = string
  description = "The source image to use"
}

variable "cmp_container_image" {
  type        = string
  description = "The route of the container image to use into the compute resource"
}

// --- -------------------------------------------------------------------------- CREDENTIALS --- //
// --- -------------------------------------------------------------------------- ----------- --- //

variable "gcp_acc_email_1" {}

variable "gcp_ssh_usr_0" {}
variable "gcp_ssh_prv_0" {}
variable "gcp_ssh_pub_0" {}

variable "gcp_ssh_usr_1" {}
variable "gcp_ssh_pub_1" {}

variable "gcp_ssh_usr_2" {}
variable "gcp_ssh_pub_2" {}
