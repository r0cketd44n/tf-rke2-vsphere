# ---------------------------
# vSphere lookups (IDs)
# ---------------------------
# data "vsphere_datacenter" "dc" { name = var.vsphere_datacenter }
# data "vsphere_compute_cluster" "cc" {
#   name          = var.vsphere_cluster
#   datacenter_id = data.vsphere_datacenter.dc.id
# }
# data "vsphere_datastore" "ds" {
#   name          = var.vsphere_datastore
#   datacenter_id = data.vsphere_datacenter.dc.id
# }
# data "vsphere_network" "nets" {
#   for_each      = toset(var.vsphere_networks)
#   name          = each.key
#   datacenter_id = data.vsphere_datacenter.dc.id
# }

# ---------------------------
# Rancher Cloud Credential for vSphere (used by machine pools)
# ---------------------------
resource "rancher2_cloud_credential" "vsphere" {
  name = "cc-vsphere"
  vsphere_credential_config {
    username = var.vsphere_user
    password = var.vsphere_password
    vcenter  = var.vsphere_server
  }
}

# ---------------------------
# Machine configs: control-plane/etcd + workers
# Two worker configs so you can choose Ubuntu or Rocky
# ---------------------------

# Control plane / etcd nodes
resource "rancher2_machine_config_v2" "rhel-cp" {
  generate_name = "${var.cluster_name}-cp-el9-"
  vsphere_config {
    # not specifying anything other than the OVA we're cloning from 
    # all other specs inherited from Packer-created OVA
    clone_from = var.vsphere-rhel-template
  }
}

# Worker (rhel)
resource "rancher2_machine_config_v2" "rhel-worker" {
  generate_name = "${var.cluster_name}-wk-el9-"
  vsphere_config {
    # not specifying anything other than the OVA we're cloning from 
    # all other specs inherited from Packer-created OVA
    clone_from = var.vsphere-rhel-template
  }
}

# ---------------------------
# RKE2 Cluster (Cluster v2 API)
# ---------------------------
resource "rancher2_cluster_v2" "rke2" {
  name                = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  rke_config {
    machine_pools {
      name                     = "cp-etcd"
      etcd_role                = true
      control_plane_role       = true
      worker_role              = false
      quantity                 = var.cp_etcd_quantity
      machine_config {
        kind = "VmwarevsphereConfig"
        name = rancher2_machine_config_v2.rhel-cp
      }
      cloud_credential_secret_name = rancher2_cloud_credential.vsphere.id
      drain_before_delete           = true
    }

    # Choose ONE worker pool by enabling it and disabling the other.

    # Workers on Ubuntu
    machine_pools {
      name                     = "workers"
      etcd_role                = false
      control_plane_role       = false
      worker_role              = true
      quantity                 = var.worker_quantity
      machine_config {
        kind = "VmwarevsphereConfig"
        name = rancher2_machine_config_v2.rhel-worker
      }
      cloud_credential_secret_name = rancher2_cloud_credential.vsphere.id
      drain_before_delete           = true
    }

    # Cluster networking
    machine_global_config = <<-EOT
      cni: ${var.cni}
      kube-apiserver-arg:
        - "service-node-port-range=30000-32767"
      cluster-domain: ${var.cluster_domain}
      service-cidr: ${var.service_cidr}
      cluster-cidr: ${var.pod_cidr}
      tls-san:
${join("\n", [for s in var.kube_api_sans : "        - \"" + s + "\""])}
    EOT

    # Private registry and custom CA (air-gapped)
    registries {
      # All images will be pulled through this registry prefix
      # Per-registry config (auth + TLS CA)
      configs {
        hostname = var.system_default_registry
        auth_config_secret_name = ""
        ca_bundle = var.registry_ca_bundle_pem
      }


      mirrors {
        hostname      = "*"
        endpoints = [var.airgap_private_mirror]
      }
    }
  }
}
