
terraform {

  cloud {
    organization = "palisade"
    workspaces { name = "infradex" }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.9"

}

