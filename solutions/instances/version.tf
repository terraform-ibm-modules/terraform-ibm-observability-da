terraform {
  required_version = ">= 1.3.0"
  required_providers {
    # Lock DA into an exact provider version - renovate automation will keep it updated
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.66.0"
    }
    logdna = {
      source  = "logdna/logdna"
      version = "1.16.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.11.2"
    }
  }
}
