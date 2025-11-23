resource "libvirt_network" "libvirt_public_network" {
  autostart = true
  mode      = "nat"
  name      = "libvirt_public_network"
  addresses = [var.public_network_ipv4_cidr,var.public_network_ipv6_cidr]

  dhcp {
    enabled = false 
  }

  dns {
    enabled = false
  }
}


resource "libvirt_network" "libvirt_private_network" {
  autostart = true
  mode      = "none"
  name      = "libvirt_private_network"


  dhcp {
    enabled = false // DHCP to be handled by the router.
  }

  dns {
    enabled = false // DNS to be handled by the router.
  }
}


// The main storage pool.
resource "libvirt_pool" "main" {
  name = "main"
  path = "/var/lib/libvirt/pools/main"
  type = "dir"
}