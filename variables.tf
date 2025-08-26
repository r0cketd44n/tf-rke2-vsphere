variable "cluster_name" {
  type    = string
  default = "rke2-airgap"
}

variable "kubernetes_version" {
  type    = string
  default = "v1.29.8+rke2r1"
}

# Rancher
variable "rancher_api_url" {
  type = string
}

variable "rancher_access_key" {
  type      = string
  sensitive = true
}

variable "rancher_secret_key" {
  type      = string
  sensitive = true
}

variable "rancher_ca_bundle_pem" {
  type      = string
  sensitive = true
}

# vSphere
variable "vsphere_server" {
  type = string
}

variable "vsphere_user" {
  type      = string
  sensitive = true
}

variable "vsphere_password" {
  type      = string
  sensitive = true
}

variable "vsphere_allow_unverified_ssl" {
  type    = bool
  default = false
}

variable "vsphere_datacenter" {
  type = string
}

variable "vsphere_cluster" {
  type = string
}

variable "vsphere_datastore" {
  type = string
}

variable "vsphere_folder" {
  type    = string
  default = "Rancher"
}

variable "vsphere_resource_pool" {
  type    = string
  default = ""
}

variable "vsphere_networks" {
  type = list(string)
}

variable "template_ubuntu" {
  type = string
}

variable "template_rocky" {
  type = string
}

# Sizing
variable "cp_etcd_quantity" {
  type    = number
  default = 3
}

variable "cp_etcd_cpu" {
  type    = number
  default = 4
}

variable "cp_etcd_memory_mb" {
  type    = number
  default = 8192
}

variable "cp_etcd_disk_gb" {
  type    = number
  default = 100
}

variable "worker_quantity" {
  type    = number
  default = 3
}

variable "worker_cpu" {
  type    = number
  default = 4
}

variable "worker_memory_mb" {
  type    = number
  default = 16384
}

variable "worker_disk_gb" {
  type    = number
  default = 150
}

# SSH
variable "ssh_username" {
  type    = string
  default = "rancher"
}

variable "ssh_private_key_pem" {
  type      = string
  sensitive = true
}

# Air-gap / registry
variable "system_default_registry" {
  type = string
}

variable "registry_auth_username" {
  type      = string
  sensitive = true
}

variable "registry_auth_password" {
  type      = string
  sensitive = true
}

variable "registry_ca_bundle_pem" {
  type      = string
  sensitive = true
}

# Networking & cluster options
variable "kube_api_sans" {
  type    = list(string)
  default = []
}

variable "service_cidr" {
  type    = string
  default = "10.43.0.0/16"
}

variable "pod_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "cni" {
  type    = string
  default = "cilium"
}

variable "cluster_domain" {
  type    = string
  default = "cluster.local"
}
