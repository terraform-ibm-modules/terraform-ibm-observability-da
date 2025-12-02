terraform {
  # module uses nullable feature which is only available in versions >= 1.1.0
  required_version = ">= 1.9.0"

  required_providers {
    # Lock DA into an exact provider version - renovate automation will keep it updated
    ibm = {
      source  = "ibm-cloud/ibm"
<<<<<<< HEAD
      version = "1.81.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
=======
      version = "1.85.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
>>>>>>> 017e02fa30e03cf18dd9dd8507325c315ba3c5f8
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
}
