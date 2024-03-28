terraform {
  # module uses nullable feature which is only available in versions >= 1.1.0
  required_version = ">= 1.1.0, <1.7.0"

  required_providers {
    # Lock DA into an exact provider version - renovate automation will keep it updated
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.63.0"
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
