terraform {
  required_version = ">= 1.0.0, <1.7.0"
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.49.0, < 2.0.0"
    }
    logdna = {
      source  = "logdna/logdna"
      version = ">= 1.14.2"
    }
    # tflint-ignore: terraform_unused_required_providers
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.2"
    }
    # tflint-ignore: terraform_unused_required_providers
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11.1"
    }
  }
}
