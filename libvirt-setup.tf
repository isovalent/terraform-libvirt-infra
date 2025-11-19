resource "local_file" "libvirt_host_setup_script" {
  content = templatefile("${path.module}/templates/libvirt_host_setup.sh", {
    router_public_network_ip  = local.public_network_router_ipv4_no_mask
    router_public_ssh_port    = var.router_public_ssh_port
    testbox_public_network_ip = local.public_network_test_box_ipv4_no_mask
    testbox_public_ssh_port   = var.testbox_public_ssh_port

  })

  filename = "${path.module}/scripts/libvirt_host_setup.sh"
}

resource "null_resource" "libvirt_host_setup" {

  depends_on = [local_file.libvirt_host_setup_script]
  triggers = {
    script_hash = sha256(local_file.libvirt_host_setup_script.content)
  }

  connection {
    host        = var.libvirt_host_ip
    user        = "root"
    private_key = file(var.libvirt_root_private_key_path)
    timeout     = "5m"
    type        = "ssh"
  }

  provisioner "file" {
    source      = local_file.libvirt_host_setup_script.filename
    destination = "/tmp/libvirt_host_setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/libvirt_host_setup.sh",
      "/tmp/libvirt_host_setup.sh"
    ]
  }
}

