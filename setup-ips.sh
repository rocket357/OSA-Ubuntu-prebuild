#!/bin/sh

### ASSUMPTIONS
# I make a lot of assumptions in this script.  I'm writing this to run pre-configuration setup on a three-node (infra nodes only)
# OSA (Ubuntu) setup using re-purposed (obsolete) gaming PCs on my home network (the joys of living with three gamers).  
#
# As such, I make a few assumptions:
#
# First, I assume the typical Ubuntu "enp0s25" interface naming silliness. (see "INT" variable below)
# Second, I'm assuming there is a single NIC with multiple vlans trunked to it per infra node. (see *VLAN variables below)
# Third, I'm assuming the single NIC in each machine is configured via DHCP, and I use the last octet of the DHCP-assigned address as the last octet of the BR interface ips.
#     This needs to be accounted for in your openstack_user_config.yml!  I use DHCP on my network with fixed-addresses for servers, but you may wish to go static config.
# Fourth, there is a base package install list below based on OSA-Pike Ubuntu deployment instructions.
#     Some packages are totally optional, but since we'll be installing OSA-Pike, it makes sense to include them now to save a bit of typing later.  (and tmux FTW).
#     Since this script is intended to be run on each infra node, I skipped the deployment host packages as well, since installing gcc and friends on each infra node seemed...
#     excessive?
# Lastly, I did not write this in any way, shape, or form, to be run on a production machine.  This is **STRICTLY** intended for running on a cleanly-installed Ubuntu 16.04
#     machine.  Don't blame me if you run this on a production box and SHTF.

# BASE PACKAGE SETUP - moved corosync and friends to setup-vip.sh
apt-get update
apt-get dist-upgrade
apt install -y bridge-utils debootstrap ifenslave{,-2.6} lsof lvm2 ntp ntpdate openssh-server sudo tcpdump vlan tmux

# NETWORK CONFIG
BRMGMTVLAN=2999
BRVXLANVLAN=3000
BRSTORAGEVLAN=3001
BRVLANVLAN=3002

# AUTO-DETECTED NETWORK VARIABLES
INT=`ifconfig | grep ^en | awk '{print $1}' | grep -v '\.'`
LAST=`ifconfig $INT | grep 'inet addr' | awk '{print $2}' | cut -d '.' -f4`

cat << EOF > /etc/network/interfaces
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto $INT
iface $INT inet dhcp

auto $INT.$BRMGMTVLAN
iface $INT.$BRMGMTVLAN inet manual
    vlan-raw-device $INT

auto $INT.$BRVXLANVLAN
iface $INT.$BRVXLANVLAN inet manual
    vlan-raw-device $INT

auto $INT.$BRSTORAGEVLAN
iface $INT.$BRSTORAGEVLAN inet manual
    vlan-raw-device $INT

auto $INT.$BRVLANVLAN
iface $INT.$BRVLANVLAN inet manual
    vlan-raw-device $INT

auto br-mgmt
iface br-mgmt inet static
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
    bridge_ports $INT.$BRMGMTVLAN
    address 172.29.236.$LAST
    netmask 255.255.252.0


auto br-vxlan
iface br-vxlan inet static
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
    bridge_ports $INT.$BRVXLANVLAN
    address 172.29.240.$LAST
    netmask 255.255.252.0

auto br-vlan
iface br-vlan inet manual
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
    bridge_ports $INT.$BRVLANVLAN


auto br-storage
iface br-storage inet static
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
    bridge_ports $INT.$BRSTORAGEVLAN
    address 172.29.244.$LAST
    netmask 255.255.252.0

source /etc/network/interfaces.d/*.cfg

EOF

# don't forget to:
#  service networking restart or reboot
