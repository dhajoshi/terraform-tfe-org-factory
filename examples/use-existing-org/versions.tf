terraform {

  required_version = ">= 1.8.2"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.54.0"
    }
  }
}