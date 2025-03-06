terraform {
  required_version = ">= 1.0.0"
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
      # lock into 1.76.0 until fix for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/6036 is released
      version = "1.76.0"
    }
  }
}
