terraform {
  # module uses nullable feature which is only available in versions >= 1.1.0
  required_version = ">= 1.1.0, <1.6.0"

  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.59.0"
    }
  }
}
