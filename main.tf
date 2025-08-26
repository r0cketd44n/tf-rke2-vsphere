# ---------------------------
# vSphere lookups (IDs)
# ---------------------------
data "vsphere_datacenter" "dc" { name = var.vsphere_datacenter }
data "vsphere_compute_cluster" "cc" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_datastore" "ds" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}
data "vsphere_network" "nets" {
  for_each      = toset(var.vsphere_networks)
  name          = each.key
  datacenter_id = data.vsphere_datacenter.dc.id
}

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

# Control plane / etcd nodes (use Ubuntu here; change to Rocky if you prefer)
resource "rancher2_vsphere_machine_config_v2" "cp" {
  generate_name   = "${var.cluster_name}-cp-"
  clone_from      = var.template_ubuntu
  datacenter      = var.vsphere_datacenter
  datastore       = var.vsphere_datastore
  folder          = var.vsphere_folder
  cpu_count       = var.cp_etcd_cpu
  memory_size     = var.cp_etcd_memory_mb
  disk_size       = var.cp_etcd_disk_gb * 1024
  network         = [for n in data.vsphere_network.nets : n.value.name]
  resource_pool   = var.vsphere_resource_pool != "" ? var.vsphere_resource_pool : null
  cloud_config    = <<-CLOUD
    #cloud-config
    users:
      - name: ${var.ssh_username}
        ssh-authorized-keys:
          - ${trimspace(chomp(filebase64decode(base64encode(var.ssh_private_key_pem)))) != "" ? chomp(join("\n", [
              "ssh-rsa PLACEHOLDER_IF_NEEDED"
            ])) : "ssh-rsa PLACEHOLDER_IF_NEEDED"}
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
    package_update: true
    write_files:
      - path: /etc/motd
        permissions: "0644"
        content: |
          Managed by Rancher (CP/ETCD)
  CLOUD
}

# Worker (Ubuntu)
resource "rancher2_vsphere_machine_config_v2" "worker_ubuntu" {
  generate_name   = "${var.cluster_name}-wk-ubu-"
  clone_from      = var.template_ubuntu
  datacenter      = var.vsphere_datacenter
  datastore       = var.vsphere_datastore
  folder          = var.vsphere_folder
  cpu_count       = var.worker_cpu
  memory_size     = var.worker_memory_mb
  disk_size       = var.worker_disk_gb * 1024
  network         = [for n in data.vsphere_network.nets : n.value.name]
  resource_pool   = var.vsphere_resource_pool != "" ? var.vsphere_resource_pool : null
  cloud_config    = <<-CLOUD
    #cloud-config
    users:
      - name: ${var.ssh_username}
        ssh-authorized-keys:
          - ssh-rsa PLACEHOLDER_IF_NEEDED
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
    package_update: true
    write_files:
      - path: /etc/motd
        permissions: "0644"
        content: |
          Managed by Rancher (Worker Ubuntu)
  CLOUD
}

# Worker (Rocky Linux)
resource "rancher2_vsphere_machine_config_v2" "worker_rocky" {
  generate_name   = "${var.cluster_name}-wk-rky-"
  clone_from      = var.template_rocky
  datacenter      = var.vsphere_datacenter
  datastore       = var.vsphere_datastore
  folder          = var.vsphere_folder
  cpu_count       = var.worker_cpu
  memory_size     = var.worker_memory_mb
  disk_size       = var.worker_disk_gb * 1024
  network         = [for n in data.vsphere_network.nets : n.value.name]
  resource_pool   = var.vsphere_resource_pool != "" ? var.vsphere_resource_pool : null
  cloud_config    = <<-CLOUD
    #cloud-config
    users:
      - name: ${var.ssh_username}
        ssh-authorized-keys:
          - ssh-rsa PLACEHOLDER_IF_NEEDED
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
    package_update: true
    write_files:
      - path: /etc/motd
        permissions: "0644"
        content: |
          Managed by Rancher (Worker Rocky)
  CLOUD
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
        name = rancher2_vsphere_machine_config_v2.cp.name
      }
      cloud_credential_secret_name = rancher2_cloud_credential.vsphere.id
      drain_before_delete           = true
    }

    # Choose ONE worker pool by enabling it and disabling the other.

    # Workers on Ubuntu
    machine_pools {
      name                     = "workers-ubuntu"
      etcd_role                = false
      control_plane_role       = false
      worker_role              = true
      quantity                 = var.worker_quantity
      machine_config {
        kind = "VmwarevsphereConfig"
        name = rancher2_vsphere_machine_config_v2.worker_ubuntu.name
      }
      cloud_credential_secret_name = rancher2_cloud_credential.vsphere.id
      drain_before_delete           = true
    }

    # Workers on Rocky (disable above if using this)
    # machine_pools {
    #   name                     = "workers-rocky"
    #   etcd_role                = false
    #   control_plane_role       = false
    #   worker_role              = true
    #   quantity                 = var.worker_quantity
    #   machine_config {
    #     kind = "VmwarevsphereConfig"
    #     name = rancher2_vsphere_machine_config_v2.worker_rocky.name
    #   }
    #   cloud_credential_secret_name = rancher2_cloud_credential.vsphere.id
    #   drain_before_delete           = true
    # }

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
      system_default_registry = var.system_default_registry

      # Per-registry config (auth + TLS CA)
      configs {
        host = var.system_default_registry
        auth_config {
          username = var.registry_auth_username
          password = var.registry_auth_password
        }
        tls_config {
          ca_bundle = var.registry_ca_bundle_pem
        }
      }

      # Optional mirror example (uncomment and adapt)
      # mirrors {
      #   host      = "docker.io"
      #   endpoints = ["https://${var.system_default_registry}/v2/docker.io"]
      # }
    }
  }
}
