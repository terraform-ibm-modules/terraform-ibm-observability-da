terraform {
  # module uses nullable feature which is only available in versions >= 1.1.0
  required_version = ">= 1.1.0, <1.7.0"

  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.62.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
  }
}