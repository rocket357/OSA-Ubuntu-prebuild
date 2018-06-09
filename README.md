# OSA-Ubuntu-prebuild
Scripts to configure br-mgmt, br-storage, br-vlan, br-vxlan, etc... along with corosync/pacemaker for HA LB VIPs and openstack-ansible.  Tested on Ubuntu-16.04 with OSA Pike.

Also includes a preseed config file appropriate for auto-installing Ubuntu 16.04.  To accomplish this, you can provide appropriate 
pxelinux.cfg scripts such as:

    file1# cat /tftp/pxelinux.cfg/01-00-25-64-9d-a8-20
    DEFAULT vesamenu.c32
    prompt 0
    MENU title PXE Boot Menu - infra1
    MENU AUTOBOOT Starting autoinstall in # seconds
    LABEL preseed-ubuntu
        MENU label ^Ubuntu 16.04 autoinstall
        MENU default
        TIMEOUT 10
        KERNEL xenial/linux
        APPEND initrd=xenial/initrd.gz locale=en_US keyboard-configuration/layoutcode=us ipv6.disable=1 hostname=infra1 interface=enp0s25 auto url=tftp://10.42.0.2/preseed/os-infra.cfg vga=788 --- quiet

Simply ensure the os-infra.cfg file is downloadable and specified in the APPEND line, and you're all set.

These scripts are WIP and targeted to a specific network configuration:

ASSUMPTIONS
I make a lot of assumptions in these scripts.  I wrote them to run pre-configuration setup on a three-node (infra nodes only)
OSA (Ubuntu) setup using re-purposed (obsolete) gaming PCs on my home network (the joys of living with three gamers).  

As such, I make a few assumptions:

First, I assume the typical Ubuntu "enp0s25" interface naming silliness.
Second, I'm assuming there is a single NIC with multiple vlans trunked to it per infra node.
Third, I'm assuming the single NIC in each machine is configured via DHCP, and I use the last octet of the DHCP-assigned address 
    as the last octet of the BR interface ips.  This needs to be accounted for in your openstack_user_config.yml!  
    I use DHCP on my network with fixed-addresses for servers, but you may wish to go static config.
Fourth, there is a base package install list below based on OSA-Pike Ubuntu deployment instructions, with corosync/pacemaker added 
    on for setup-vip.sh in this repo.  Some packages are totally optional, but since we'll be installing OSA-Pike, it makes sense to
    include them now to save a bit of typing later.  (and tmux FTW).  Since this script is intended to be run on each infra node, I
    skipped the deployment host packages as well, since installing gcc and friends on each infra node seemed...excessive?
Lastly, I did not write this in any way, shape, or form, to be run on a production machine.  This is **STRICTLY** intended for running
    on a cleanly-installed Ubuntu 16.04 machine.  Don't blame me if you run this on a production box and SHTF.

Once more:
Don't blame me if you run this on a production box and SHTF.
