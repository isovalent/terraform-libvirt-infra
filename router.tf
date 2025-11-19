// Copyright 2024 Isovalent, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


resource "libvirt_volume" "router_base" {


  format = "qcow2"
  name   = "router-base.qcow2"
  pool   = libvirt_pool.main.name
  source = local.router_base_image_url
}

resource "libvirt_volume" "router" {
  depends_on     = [libvirt_pool.main]
  base_volume_id = libvirt_volume.router_base.id
  format         = "qcow2"
  name           = "router-root-volume.qcow2"
  pool           = libvirt_pool.main.name
}

resource "libvirt_cloudinit_disk" "router" {
  meta_data      = templatefile("${path.module}/templates/router-meta-data.yaml", {})
  name           = "router.iso"
  network_config = templatefile("${path.module}/templates/router-network-config.yaml", {})
  pool           = libvirt_pool.main.name

  user_data = templatefile("${path.module}/templates/router-user-data.yaml", {
    private_network_ipv4_cidr         = var.private_network_ipv4_cidr
    private_network_ipv4_cidr_no_mask = local.private_network_ipv4_cidr_no_mask
    private_network_ipv6_cidr         = var.private_network_ipv6_cidr

    router_public_ipv4_address                 = local.public_network_router_ipv4
    router_private_ipv4_address                = local.private_network_router_ipv4
    router_private_ipv4_address_no_mask        = local.private_network_router_ipv4_no_mask
    router_private_ipv6_address                = local.private_network_router_ipv6
    router_public_gateway_ipv4_address_no_mask = local.public_network_gateway_ipv4_no_mask

    dhcp_vm_node_cidr_first_ipv4_address = local.dhcp_vm_node_cidr_first_ipv4_address
    dhcp_vm_node_cidr_last_ipv4_address  = local.dhcp_vm_node_cidr_last_ipv4_address
    dhcp_vm_node_cidr_first_ipv6_address = local.dhcp_vm_node_cidr_first_ipv6_address
    dhcp_vm_node_cidr_last_ipv6_address  = local.dhcp_vm_node_cidr_last_ipv6_address
    private_network_ipv4_netmask         = local.private_network_ipv4_netmask
    name                                 = "${var.infra_name}_router"
    vyos_password                        = var.router_password


    dns_base_domain      = var.dns_base_domain
    cluster_name         = var.k8s_cluster_name
    k8s_master_info_list = local.k8s_master_info_list
    k8s_worker_info_list = local.k8s_worker_info_list
  })

}

resource "libvirt_domain" "router" {
  autostart = true
  cloudinit = libvirt_cloudinit_disk.router.id
  machine   = "q35"
  memory    = 1024
  name      = "router"
  vcpu      = 1
  graphics {
    type        = "vnc"
    listen_type = "address"
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  disk {
    volume_id = libvirt_volume.router.id
  }

  network_interface {
    network_id     = libvirt_network.libvirt_public_network.id
    wait_for_lease = false
  }

  network_interface {
    network_id     = libvirt_network.libvirt_private_network.id
    wait_for_lease = false
  }


  xml {
    xslt = file("${path.module}/hack/cdrom-model.xsl")
  }
}