output "masters_info_list" {
  description = "The IP addresses, mac addresses, hostnames, and ipv6 addresses of the master nodes."
  value       = local.k8s_master_info_list
}

output "workers_info_list" {
  description = "The IP addresses, mac addresses, hostnames, and ipv6 addresses of the worker nodes."
  value       = local.k8s_worker_info_list
}

output "libvirt_info" {
  description = "Information about the libvirt environment."
  value = {
    public_network_id  = libvirt_network.libvirt_public_network.id
    private_network_id = libvirt_network.libvirt_private_network.id
    pool_name          = libvirt_pool.main.name
  }
}

output "router_info" {
  description = "The connection details for the router."
  value = {
    public_ip   = var.libvirt_host_ip
    public_port = var.router_public_ssh_port
    username    = "vyos"
    password    = var.router_password
  }
}

output "testbox_info" {
  description = "The connection details for the testbox."
  value = {
    username    = var.testbox_username
    public_ip   = var.libvirt_host_ip
    public_port = var.testbox_public_ssh_port
    private_key = var.testbox_ssh_private_key
    public_key = var.testbox_ssh_public_key
  }
}
