#!/bin/bash

set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Silence is bliss.
touch "/root/.hushlogin"

if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  distro="$${ID,,}"
else
  echo "ERROR: cannot detect OS."
  exit 1
fi

if [[ "$distro" != "ubuntu" && "$distro" != "debian" ]]; then
  echo "ERROR: Unsupported OS: $PRETTY_NAME"
  exit 1
fi

echo "OK: Supported OS detected: $PRETTY_NAME"
# Install libvirt and guest utilities.
apt-get update

# This is required to manage libvirt networks.
if ! grep -q "^DNSStubListener=no" /etc/systemd/resolved.conf; then
  echo "Disabling DNSStubListener..."
  cat <<EOF | tee -a /etc/systemd/resolved.conf
DNSStubListener=no
EOF
  systemctl restart systemd-resolved
fi

if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
  echo "Disabling ufw to prevent interference..."
  ufw disable
  systemctl disable ufw
fi

# Loop until apt-get update succeeds and the required packages are found.
# This is the most reliable way to handle transient network issues with mirrors.
echo "Updating package lists until required packages are found..."
ATTEMPTS=0
MAX_ATTEMPTS=5
until apt-get update -y && \
      apt-cache policy iptables >/dev/null 2>&1 && \
      apt-cache policy libguestfs-tools >/dev/null 2>&1 && \
      apt-cache policy libvirt-daemon-system >/dev/null 2>&1 && \
      apt-cache policy qemu-system >/dev/null 2>&1; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    echo "ERROR: Failed to find packages after $MAX_ATTEMPTS attempts of apt-get update."
    exit 1
  fi
  echo "Verification failed. Retrying apt-get update in 10 seconds... (Attempt $ATTEMPTS)"
  sleep 10
done
echo "Package lists updated and verified successfully."

# Now, install the packages.
echo "Installing packages..."
apt-get install -y --no-install-recommends \
  iptables \
  libguestfs-tools \
  libvirt-daemon-system \
  qemu-system

# Wait for the libvirtd socket to be present.
until [[ -S /var/run/libvirt/libvirt-sock ]]; do
  sleep 1
done
# Work around https://github.com/dmacvicar/terraform-provider-libvirt/issues/97.
if ! grep -q "^security_driver = \"none\"" /etc/libvirt/qemu.conf; then
  echo "Setting security_driver to none in qemu.conf..."
  cat <<EOF | tee -a /etc/libvirt/qemu.conf
security_driver = "none"
EOF
  systemctl restart libvirtd
fi

# DNAT k8s API traffic traffic to router
iptables -t nat -C PREROUTING -p tcp -m tcp --dport 6443 -j DNAT --to-destination ${router_public_network_ip}:6443 2>/dev/null ||
  iptables -t nat -A PREROUTING -p tcp --dport 6443 -j DNAT --to-destination ${router_public_network_ip}:6443

iptables -C FORWARD -d ${router_public_network_ip} -p tcp -m tcp --dport 6443 -j ACCEPT 2>/dev/null ||
  iptables -I FORWARD -d ${router_public_network_ip} -p tcp --dport 6443 -j ACCEPT

# DNAT testbox ssh traffic to testbox
iptables -t nat -C PREROUTING -p tcp -m tcp --dport ${testbox_public_ssh_port} -j DNAT --to-destination ${testbox_public_network_ip}:22 2>/dev/null ||
  iptables -t nat -A PREROUTING -p tcp --dport ${testbox_public_ssh_port} -j DNAT --to-destination ${testbox_public_network_ip}:22

iptables -C FORWARD -d ${testbox_public_network_ip} -p tcp -m tcp --dport 22 -j ACCEPT 2>/dev/null ||
  iptables -I FORWARD -d ${testbox_public_network_ip} -p tcp --dport 22 -j ACCEPT

# DNAT router ssh traffic to router

iptables -t nat -C PREROUTING -p tcp -m tcp --dport ${router_public_ssh_port} -j DNAT --to-destination ${router_public_network_ip}:22 2>/dev/null ||
  iptables -t nat -A PREROUTING -p tcp --dport ${router_public_ssh_port} -j DNAT --to-destination ${router_public_network_ip}:22

iptables -C FORWARD -d ${router_public_network_ip} -p tcp -m tcp --dport 22 -j ACCEPT 2>/dev/null ||
  iptables -I FORWARD -d ${router_public_network_ip} -p tcp --dport 22 -j ACCEPT


