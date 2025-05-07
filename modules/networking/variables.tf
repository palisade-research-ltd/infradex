
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

// --- -------------------------------------------------------------------- OUTPUT VARIABLES --- //
// --- -------------------------------------------------------------------- ---------------- --- //



// --- --------------------------------------------------------------------- LOCAL VARIABLES --- //
// --- --------------------------------------------------------------------- --------------- --- //

locals {
  
  apis = {
    "cloud" = { url = "cloudresourcemanager" }
    "iam" = { url = "iamcredentials" }
    "networking" = { url = "servicenetworking" }
    "services"  = { url = "serviceusage" }
    "compute" = { url = "compute" }
    "secrets" = { url = "secretmanager" }
  }

}

