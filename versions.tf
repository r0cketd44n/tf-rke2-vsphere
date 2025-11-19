terraform {
  required_version = ">= 1.5.0"

  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = ">= 3.0.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">=5.0.0"
    }
    # other providers suggested by GPT but not needed
    # vsphere = {
    #   source  = "hashicorp/vsphere"
    #   version = ">= 2.5.0"
    # }
    # tls = {
    #   source  = "hashicorp/tls"
    #   version = ">= 4.0.0"
    # }
  }
}
