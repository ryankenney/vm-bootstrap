#!/bin/bash

# Exit on any script failure
set -e

this_script=`basename "$0"`

if [[ $# -ne 2 ]]; then
	echo ""
	echo "Sets up local VMs after loading unattended Ubuntu install"
	echo ""
	echo "Usage: ${this_script} <hostname> <ip-last-octet>"
	echo ""
	exit 1
fi

this_hostname=$1
this_ip_octet=$2

if [[ "$EUID" -ne 0 ]]; then
	echo ""
	echo "This script must be run as root"
	echo ""
	exit 1
fi

echo "==== Enabling the Second NIC ===="
# NOTE: This presumes that we want the VM on the first host-only network (vboxnet0 == 192.168.56.x subnet)
# NOTE: This presumes that the second NIC appears as "enp0s8".
#       Use "ifconfig -a -s" to verify.
echo "" >> /etc/network/interfaces
echo "auto enp0s8" >> /etc/network/interfaces
echo "iface enp0s8 inet static" >> /etc/network/interfaces
echo "address 192.168.56.${this_ip_octet}" >> /etc/network/interfaces
echo "netmask 255.255.255.0" >> /etc/network/interfaces

echo "==== Restarting the Network ===="
systemctl restart networking

echo "==== Setting the Hostname ===="
# NOTE: This presumes that we want to refer to use a "vboxnet0" domain name for VMs
#       on that host-only network
sed -i "s/ubuntu/${this_hostname} ${this_hostname}.vboxnet0/g" /etc/hosts
sed -i "s/ubuntu/${this_hostname}/g" /etc/hostname

echo "==== Setup Firewall ===="
ufw enable

echo "==== Setup SSH Server ===="
ufw allow ssh
systemctl enable ssh

