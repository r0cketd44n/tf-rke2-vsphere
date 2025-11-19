cluster_name           = "rke2-airgap"
kubernetes_version     = "v1.29.8+rke2r1"

rancher_api_url        = "https://rancher.example.local"
rancher_access_key     = "RANCHER_ACCESS_KEY"
rancher_secret_key     = "RANCHER_SECRET_KEY"
rancher_ca_bundle_pem  = <<-PEM
-----BEGIN CERTIFICATE-----
... your internal CA that signed Rancher server cert ...
-----END CERTIFICATE-----
PEM

vsphere_server               = "vcenter.example.local"
vsphere_user                 = "svc_rancher@vsphere.local"
vsphere_password             = "REDACTED"
# vsphere_allow_unverified_ssl = false

# vsphere_datacenter  = "DC1"
# vsphere_cluster     = "Compute-Cluster"
# vsphere_datastore   = "Datastore1"
# vsphere_folder      = "Rancher"
# vsphere_networks    = ["VM Network"]
# template_ubuntu     = "tpl-ubuntu-24.04"
# template_rocky      = "tpl-rocky-9.6"

ssh_username            = "rancher"
ssh_private_key_pem     = <<-PEM
-----BEGIN OPENSSH PRIVATE KEY-----
...your key...
-----END OPENSSH PRIVATE KEY-----
PEM

system_default_registry = "registry.example.local:5000"
registry_auth_username  = "robot"
registry_auth_password  = "REDACTED"
registry_ca_bundle_pem  = <<-PEM
-----BEGIN CERTIFICATE-----
... CA that signed registry.example.local cert ...
-----END CERTIFICATE-----
PEM

kube_api_sans  = ["rke2-api.example.local", "10.0.0.50"]
service_cidr   = "10.43.0.0/16"
pod_cidr       = "10.42.0.0/16"
# changed the cni to flannel to support f5 vxlan
cni            = "flannel"
cluster_domain = "cluster.local"

vsphere-rhel-template = "vol_iso1/rhel-9.5-k8s-2025.ova"
airgap_private_mirror = "my-org-mirror.lab"