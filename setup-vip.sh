#!/bin/sh

# Use at your own risk.  Do not run this without reading it first.
# There is a lot hard-coded in this script.  I'm working on generalizing it, but it gives you
# an idea of what needs to happen to get the VIP up and running on Ubuntu 16.04

INFRA1_IP="172.29.236.11"
INFRA2_IP="172.29.236.12"
INFRA3_IP="172.29.236.13"
OSA_VIP_IP="172.29.239.150"

# corosync
echo "START=yes" >> /etc/default/corosync 

cat << EOF > /etc/corosync/corosync.conf
totem {
        version: 2
        cluster_name: openstack
        token: 3000
        token_retransmits_before_loss_const: 10
        clear_node_high_bit: yes
        crypto_cipher: none
        crypto_hash: none
        interface {
                ringnumber: 0
                bindnetaddr: $INFRA1_IP
                broadcast: yes (1)
                mcastport: 5405
                ttl: 1
        }
        transport: udpu (2)
}
nodelist { (3)
        node {
                ring0_addr: $INFRA1_IP
                nodeid: 1
        }
        node {
                ring0_addr: $INFRA2_IP
                nodeid: 2
        }
        node {
                ring0_addr: $INFRA3_IP
                nodeid: 3
        }
}
logging {
        fileline: off
        to_stderr: no
        to_logfile: no
        to_syslog: yes
        syslog_facility: daemon
        debug: off
        timestamp: on
        logger_subsys {
                subsys: QUORUM
                debug: off
        }
}
quorum {
        provider: corosync_votequorum
        expected_votes: 2
}

EOF
scp /etc/default/corosync root@$INFRA2_IP:/etc/default/corosync
scp /etc/default/corosync root@$INFRA3_IP:/etc/default/corosync
sed -e 's/bindnetaddr: $INFRA1_IP/bindnetaddr: $INFRA2_IP/g' /etc/corosync/corosync.conf > /tmp/infra2.corosync.conf
sed -e 's/bindnetaddr: $INFRA1_IP/bindnetaddr: $INFRA3_IP/g' /etc/corosync/corosync.conf > /tmp/infra3.corosync.conf
scp /tmp/infra2.corosync.conf root@$INFRA2_IP:/etc/corosync/corosync.conf
scp /tmp/infra3.corosync.conf root@$INFRA3_IP:/etc/corosync/corosync.conf
crm configure property pe-warn-series-max="1000"   pe-input-series-max="1000"   pe-error-series-max="1000"   cluster-recheck-interval="5min"
crm configure property stonith-enabled=false
crm_verify -L
corosync-keygen 
scp /etc/corosync/authkey $INFRA2_IP:/etc/corosync/authkey
scp /etc/corosync/authkey $INFRA3_IP:/etc/corosync/authkey
service corosync restart
ssh $INFRA2_IP service corosync restart
ssh $INFRA3_IP service corosync restart
crm status
crm configure primitive openstack-vip ocf:heartbeat:IPaddr2 params ip="$OSA_VIP_IP" cidr_netmask="22" op monitor interval="30s"

cd /usr/lib/ocf/resource.d/
mkdir openstack
cd openstack
wget https://raw.github.com/leseb/keystone/ha/tools/ocf/keystone
wget https://raw.github.com/madkiss/glance/ha/tools/ocf/glance-registry
wget https://raw.github.com/madkiss/glance/ha/tools/ocf/glance-api
