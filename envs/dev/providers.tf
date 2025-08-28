terraform {
  cloud {
    organization = "palisade"
    workspaces {
      name = "dev_infradex" 
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.pro_region
}

