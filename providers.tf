# Rancher API (air-gapped, private CA)
provider "rancher2" {
  api_url    = var.rancher_api_url            # e.g., https://rancher.example.local
  #access_key = var.rancher_access_key
  #secret_key = var.rancher_secret_key
  bootstrap = true
  # Paste the PEM of the Rancher Server CA (or your internal PKI) if not publicly trusted
  ca_certs   = var.rancher_ca_bundle_pem
}

# add Vault provider to pull vsphere credential
provider "vault" {
  address  = ""
  token    = ""
}
# note - chatGPT thought we needed to use the VMware provider but seems this is unnecessary
# was only calling vsphere for data sources that weren't utilized
# vSphere (on-prem)
# provider "vsphere" {
#   user                 = var.vsphere_user
#   password             = var.vsphere_password
#   vsphere_server       = var.vsphere_server    # e.g., vcenter.example.local
#   allow_unverified_ssl = var.vsphere_allow_unverified_ssl
# }
