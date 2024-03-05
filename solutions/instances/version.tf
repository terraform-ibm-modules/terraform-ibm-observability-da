terraform {
  required_version = ">= 1.3.0, <1.7.0"
  required_providers {
    # Pin to the lowest provider version of the range defined in the main module to ensure lowest version still works
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.62.0"
    }
    logdna = {
      source  = "logdna/logdna"
      version = "1.16.0"
    }
  }
}
