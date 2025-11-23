resource "libvirt_volume" "testbox_base" {
  depends_on = [libvirt_domain.router]
  name       = "testbox-base"
  source     = local.testbox_base_image_url
  pool       = libvirt_pool.main.name
  format     = "qcow2"
}

// The root volume for the testbox.
resource "libvirt_volume" "testbox" {
  depends_on     = [libvirt_pool.main]
  base_volume_id = libvirt_volume.testbox_base.id
  format         = "qcow2"
  name           = "testbox-root-volume.qcow2"
  size           = 10000000000
  pool           = libvirt_pool.main.name
}

resource "libvirt_cloudinit_disk" "testbox" {
  meta_data = templatefile("${path.module}/templates/testbox-meta-data.yaml", {})
  name      = "testbox.iso"
  network_config = templatefile("${path.module}/templates/testbox-network-config.yaml", {
    public_test_box_ipv4_address = local.public_network_test_box_ipv4
    public_gateway_ip_no_mask    = local.public_network_gateway_ipv4_no_mask
    private_test_box_ipv6_address = local.private_network_test_box_ipv6
    private_gateway_ip_v6_no_mask = local.private_network_router_ipv6_no_mask
    public_test_box_ipv6_address = local.public_network_test_box_ipv6
    public_gateway_ip_v6_no_mask = local.public_network_gateway_ipv6_no_mask
  })
  pool = libvirt_pool.main.name
  user_data = templatefile("${path.module}/templates/testbox-user-data.yaml", {
    name                                = var.testbox_username
    private_network_router_ipv4_no_mask = local.private_network_router_ipv4_no_mask
    router_public_ipv4                  = local.public_network_router_ipv4_no_mask
    router_public_ipv6                  = local.public_network_router_ipv6_no_mask
    private_ssh_key                     = base64encode(var.testbox_ssh_private_key)
    public_ssh_keys = jsonencode([
      var.testbox_ssh_public_key
    ])
  })
}

// The testbox VM.
resource "libvirt_domain" "testbox" {
  autostart = true
  cloudinit = libvirt_cloudinit_disk.testbox.id
  memory    = 2048
  name      = "testbox"
  vcpu      = 2

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
  graphics {
    type        = "vnc"
    listen_type = "address"
  }
  disk {
    volume_id = libvirt_volume.testbox.id
  }


  network_interface {
    network_id     = libvirt_network.libvirt_public_network.id
    wait_for_lease = false
  }

  network_interface {
    network_id     = libvirt_network.libvirt_private_network.id
    wait_for_lease = false
  }
}
