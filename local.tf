locals {
  testbox_base_image_url = "${var.image_download_base_url}/${var.testbox_image_name}"
  router_base_image_url  = "${var.image_download_base_url}/${var.router_image_name}"

  public_network_ipv4_cidr_no_mask     = split("/", var.public_network_ipv4_cidr)[0]
  public_network_ipv4_cidr_mask        = split("/", var.public_network_ipv4_cidr)[1]
  public_network_ipv4_netmask          = cidrnetmask(var.public_network_ipv4_cidr)
  public_network_gateway_ipv4_no_mask  = cidrhost(var.public_network_ipv4_cidr, 1)
  public_network_gateway_ipv4          = "${local.public_network_gateway_ipv4_no_mask}/${local.public_network_ipv4_cidr_mask}"
  public_network_router_ipv4_no_mask   = cidrhost(var.public_network_ipv4_cidr, 2)
  public_network_router_ipv4           = "${local.public_network_router_ipv4_no_mask}/${local.public_network_ipv4_cidr_mask}"
  public_network_test_box_ipv4_no_mask = cidrhost(var.public_network_ipv4_cidr, 3)
  public_network_test_box_ipv4         = "${local.public_network_test_box_ipv4_no_mask}/${local.public_network_ipv4_cidr_mask}"

  private_network_ipv4_cidr_no_mask           = split("/", var.private_network_ipv4_cidr)[0]
  private_network_ipv4_cidr_mask              = split("/", var.private_network_ipv4_cidr)[1]
  private_network_ipv4_netmask                = cidrnetmask(var.private_network_ipv4_cidr)
  private_network_router_ipv4_no_mask         = cidrhost(var.private_network_ipv4_cidr, 1)
  private_network_router_ipv4                 = "${local.private_network_router_ipv4_no_mask}/${local.private_network_ipv4_cidr_mask}"
  private_network_first_ip_address_last_octet = 50
  private_network_last_ip_address_last_octet  = 200
  dhcp_vm_node_cidr_first_ipv4_address        = cidrhost(var.private_network_ipv4_cidr, local.private_network_first_ip_address_last_octet)
  dhcp_vm_node_cidr_last_ipv4_address         = cidrhost(var.private_network_ipv4_cidr, local.private_network_last_ip_address_last_octet)

  private_network_ipv6_cidr_no_mask    = split("/", var.private_network_ipv6_cidr)[0]
  private_network_ipv6_network_mask    = split("/", var.private_network_ipv6_cidr)[1]
  private_network_router_ipv6_no_mask  = cidrhost(var.private_network_ipv6_cidr, 1)
  private_network_router_ipv6          = "${local.private_network_router_ipv6_no_mask}/${local.private_network_ipv6_network_mask}"
  dhcp_vm_node_cidr_first_ipv6_address = cidrhost(var.private_network_ipv6_cidr, local.private_network_first_ip_address_last_octet)
  dhcp_vm_node_cidr_last_ipv6_address  = cidrhost(var.private_network_ipv6_cidr, local.private_network_last_ip_address_last_octet)

  # use 20-30 for k8s masters ipv4/ipv6 address
  k8s_master_info_list = [
    for i in range(var.k8s_master_count) : {
      ipv4     = cidrhost(var.private_network_ipv4_cidr, 20 + i)
      mac      = "${var.k8s_master_mac_prefix}${i}"
      hostname = "${var.k8s_master_hostname_prefix}${i}"
      ipv6     = cidrhost(var.private_network_ipv6_cidr, 32 + i)
    }
  ]
  # use 30-40 for k8s worker ipv4/ipv6 address

  k8s_worker_info_list = [
    for i in range(var.k8s_worker_count) : {
      ipv4     = cidrhost(var.private_network_ipv4_cidr, 30 + i)
      mac      = "${var.k8s_worker_mac_prefix}${i}"
      hostname = "${var.k8s_worker_hostname_prefix}${i}"
      ipv6     = cidrhost(var.private_network_ipv6_cidr, 48 + i)
    }
  ]
}

