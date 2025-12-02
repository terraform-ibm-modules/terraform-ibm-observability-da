terraform {
  required_version = ">= 1.9.0"
  required_providers {
    # Lock DA into an exact provider version - renovate automation will keep it updated
    ibm = {
      source  = "ibm-cloud/ibm"
<<<<<<< HEAD
      version = "1.81.1"
=======
      version = "1.85.0"
>>>>>>> 017e02fa30e03cf18dd9dd8507325c315ba3c5f8
    }
    time = {
      source  = "hashicorp/time"
      version = "0.13.1"
    }
  }
}
