
terraform {

  cloud {
    organization = "palisade"
    workspaces {
      name = "signals-dev"
    }
  }

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 6.12.0"
    }

  }

  required_version = ">= 1.9"

}

provider "google" {

  project     = var.prj_project_id
  region      = var.prj_region
  credentials = var.gcp_credentials

}


