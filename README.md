# Libvirt Infrastructure Module

This module deploys a libvirt-based infrastructure. It is designed to set up a complete networking and VM environment on a libvirt host, suitable for deploying a Kubernetes cluster.

Due to a limitation in Terraform's provider initialization, the setup of the libvirt host must be done in a separate step before deploying the actual libvirt resources.

## Architecture

This module provisions the following resources on the libvirt host:

*   **Networking**: Creates a public and a private libvirt network.
*   **VyOS Router**: A VM that acts as a router between the public and private networks. It also provides DHCP and DNS services for the private network.
    *   **Gateway and NAT**: Provides internet access for the VMs on the private network.
    *   **DHCP Server**: Assigns static IPv4 and IPv6 addresses to Kubernetes nodes based on their MAC addresses.
    *   **DNS Server (CoreDNS)**: Provides DNS resolution for the cluster, including records for all nodes and Kubernetes API endpoints.
    *   **Load Balancer (HAProxy)**: Acts as a load balancer for the Kubernetes control plane and ingress traffic (ports 80, 443, 6443, and 22623).
    *   **BGP Peer**: Establishes BGP sessions with Kubernetes nodes, enabling advanced networking features required by CNIs like Cilium.
*   **Testbox VM**: A general-purpose Ubuntu-based VM connected to both networks that can be used for administrative or testing tasks.

## Usage

Follow these two steps to deploy the infrastructure:

### Step 1: Prepare the Libvirt Host

This step runs a setup script on your libvirt host to install necessary packages and configure networking.

```bash
terraform init
terraform apply --target=module.libvirt-infra.null_resource.libvirt_host_setup
```

### Step 2: Deploy the Libvirt Resources

After the host is prepared, you can deploy the full infrastructure, including the router and testbox VMs.

```bash
terraform apply
```

## Requirements

*   A host with libvirt installed and running.
*   SSH access to the libvirt host with a private key.

## Accessing the Environment

The setup script configures port forwarding on the libvirt host using `iptables`. This allows you to access the VMs and services running within the libvirt environment from the host machine's IP address.

### SSH Access

*   **Router:** Connect to the VyOS router via SSH. The default port is `8022`. Use the password you configured (defaults to `R0uter123!`).
    ```bash
    ssh -p 8022 vyos@<libvirt_host_ip>
    ```

*   **Testbox:** Connect to the testbox via SSH using the SSH key you provided. The default port is `8023` and the default username is `testbox`.
    ```bash
    ssh -p 8023 testbox@<libvirt_host_ip>
    ```

### Kubernetes API

Port `6443` is forwarded for Kubernetes API access. Once your cluster is running, you can access its API server through the libvirt host's IP address:
`https://<libvirt_host_ip>:6443`
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.6.5 |
| <a name="requirement_libvirt"></a> [libvirt](#requirement\_libvirt) | 0.7.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_libvirt"></a> [libvirt](#provider\_libvirt) | 0.7.6 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.3 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [libvirt_cloudinit_disk.router](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6/docs/resources/cloudinit_disk) | resource |
| [libvirt_cloudinit_disk.testbox](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6/docs/resources/cloudinit_disk) | resource |
| [libvirt_domain.router](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6/docs/resources/domain) | resource |
| [libvirt_domain.testbox](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6/docs/resources/domain) | resource |
| [libvirt_network.libvirt_private_network](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6/docs/resources/network) | resource |
| [libvirt_network.libvirt_public_network](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6/docs/resources/network) | resource |
| [libvirt_pool.main](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6/docs/resources/pool) | resource |
| [libvirt_volume.router](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6/docs/resources/volume) | resource |
| [libvirt_volume.router_base](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6/docs/resources/volume) | resource |
| [libvirt_volume.testbox](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6/docs/resources/volume) | resource |
| [libvirt_volume.testbox_base](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.6/docs/resources/volume) | resource |
| [local_file.libvirt_host_setup_script](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.libvirt_host_setup](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_base_domain"></a> [dns\_base\_domain](#input\_dns\_base\_domain) | base domain for the LAN network so the k8s nodes can get unique the FQDN name and resolved by the router | `string` | `"local"` | no |
| <a name="input_image_download_base_url"></a> [image\_download\_base\_url](#input\_image\_download\_base\_url) | the base url of the images | `string` | n/a | yes |
| <a name="input_infra_name"></a> [infra\_name](#input\_infra\_name) | The name of the equinix metal infrastructure. | `string` | n/a | yes |
| <a name="input_k8s_cluster_name"></a> [k8s\_cluster\_name](#input\_k8s\_cluster\_name) | this will be used to create the FQDN name in the DNS record to follow the OCP guide(https://docs.openshift.com/container-platform/4.11/installing/installing_bare_metal/installing-bare-metal.html#installation-dns-user-infra-example_installing-bare-metal) | `string` | n/a | yes |
| <a name="input_k8s_master_count"></a> [k8s\_master\_count](#input\_k8s\_master\_count) | number of master nodes, and we only support numbers 1 or 3 for now | `number` | `"1"` | no |
| <a name="input_k8s_master_hostname_prefix"></a> [k8s\_master\_hostname\_prefix](#input\_k8s\_master\_hostname\_prefix) | prefix hostname of the master nodes | `string` | `"masters"` | no |
| <a name="input_k8s_master_mac_prefix"></a> [k8s\_master\_mac\_prefix](#input\_k8s\_master\_mac\_prefix) | prefix mac address of the master nodes | `string` | `"52:54:00:aa:bb:a"` | no |
| <a name="input_k8s_worker_count"></a> [k8s\_worker\_count](#input\_k8s\_worker\_count) | number of worker nodes, and we only support numbers less than 9 for now | `number` | `"2"` | no |
| <a name="input_k8s_worker_hostname_prefix"></a> [k8s\_worker\_hostname\_prefix](#input\_k8s\_worker\_hostname\_prefix) | prefix hostname of the worker nodes | `string` | `"workers"` | no |
| <a name="input_k8s_worker_mac_prefix"></a> [k8s\_worker\_mac\_prefix](#input\_k8s\_worker\_mac\_prefix) | prefix mac address of the worker nodes | `string` | `"52:54:00:aa:bb:b"` | no |
| <a name="input_libvirt_host_ip"></a> [libvirt\_host\_ip](#input\_libvirt\_host\_ip) | The IP address of the libvirt host. | `string` | n/a | yes |
| <a name="input_libvirt_root_private_key_path"></a> [libvirt\_root\_private\_key\_path](#input\_libvirt\_root\_private\_key\_path) | The root private key path of the libvirt host. | `string` | n/a | yes |
| <a name="input_private_network_ipv4_cidr"></a> [private\_network\_ipv4\_cidr](#input\_private\_network\_ipv4\_cidr) | the private network IPv4 cidr block for VMs, only /24 is supported for now | `string` | `"192.168.1.0/24"` | no |
| <a name="input_private_network_ipv6_cidr"></a> [private\_network\_ipv6\_cidr](#input\_private\_network\_ipv6\_cidr) | the private network IPv6 cidr block for VMs, and only /112 is supported for now | `string` | `"fd03::/112"` | no |
| <a name="input_public_network_ipv4_cidr"></a> [public\_network\_ipv4\_cidr](#input\_public\_network\_ipv4\_cidr) | the public network IPv4 cidr block for VMs, only /24 is supported for now | `string` | `"10.0.0.0/24"` | no |
| <a name="input_router_image_name"></a> [router\_image\_name](#input\_router\_image\_name) | the name of the router image | `string` | `"vyos-1.4-rolling.qcow2"` | no |
| <a name="input_router_password"></a> [router\_password](#input\_router\_password) | The login password for vyos. | `string` | `"R0uter123!"` | no |
| <a name="input_router_public_ssh_port"></a> [router\_public\_ssh\_port](#input\_router\_public\_ssh\_port) | The public SSH port of the router from external. | `number` | `8022` | no |
| <a name="input_testbox_image_name"></a> [testbox\_image\_name](#input\_testbox\_image\_name) | the name of the testbox image | `string` | `"jammy-server-cloudimg-amd64-disk-kvm.img"` | no |
| <a name="input_testbox_public_ssh_port"></a> [testbox\_public\_ssh\_port](#input\_testbox\_public\_ssh\_port) | The public SSH port of the testbox from external. | `number` | `8023` | no |
| <a name="input_testbox_ssh_private_key"></a> [testbox\_ssh\_private\_key](#input\_testbox\_ssh\_private\_key) | Content of the SSH private key. | `string` | n/a | yes |
| <a name="input_testbox_ssh_public_key"></a> [testbox\_ssh\_public\_key](#input\_testbox\_ssh\_public\_key) | Content of the SSH public key. | `string` | n/a | yes |
| <a name="input_testbox_username"></a> [testbox\_username](#input\_testbox\_username) | the username of the testbox | `string` | `"testbox"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_libvirt_info"></a> [libvirt\_info](#output\_libvirt\_info) | Information about the libvirt environment. |
| <a name="output_masters_info_list"></a> [masters\_info\_list](#output\_masters\_info\_list) | The IP addresses, mac addresses, hostnames, and ipv6 addresses of the master nodes. |
| <a name="output_router_info"></a> [router\_info](#output\_router\_info) | The connection details for the router. |
| <a name="output_testbox_info"></a> [testbox\_info](#output\_testbox\_info) | The connection details for the testbox. |
| <a name="output_workers_info_list"></a> [workers\_info\_list](#output\_workers\_info\_list) | The IP addresses, mac addresses, hostnames, and ipv6 addresses of the worker nodes. |
<!-- END_TF_DOCS -->