#!/bin/sh

# get corosync configured
 echo "START=yes" >> /etc/default/corosync 
 vi /etc/corosync/corosync.conf 
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
                bindnetaddr: 172.29.236.11
                broadcast: yes (1)
                mcastport: 5405
                ttl: 1
        }
        transport: udpu (2)
}
nodelist { (3)
        node {
                ring0_addr: 172.29.236.11
                nodeid: 1
        }
        node {
                ring0_addr: 172.29.236.12
                nodeid: 2
        }
        node {
                ring0_addr: 172.29.236.13
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
 scp /etc/default/corosync root@172.29.236.12:/etc/default/corosync
 scp /etc/default/corosync root@172.29.236.13:/etc/default/corosync
 sed -e 's/bindnetaddr: 172.29.236.11/bindnetaddr: 172.29.236.12/g' /etc/corosync/corosync.conf > /tmp/infra2.corosync.conf
 sed -e 's/bindnetaddr: 172.29.236.11/bindnetaddr: 172.29.236.13/g' /etc/corosync/corosync.conf > /tmp/infra3.corosync.conf
 scp /tmp/infra2.corosync.conf root@172.29.236.12:/etc/corosync/corosync.conf
 scp /tmp/infra3.corosync.conf root@172.29.236.13:/etc/corosync/corosync.conf
 crm configure property pe-warn-series-max="1000"   pe-input-series-max="1000"   pe-error-series-max="1000"   cluster-recheck-interval="5min"
 crm configure property stonith-enabled=false
 crm_verify -L
 corosync-keygen 
 scp /etc/corosync/authkey 172.29.236.12:/etc/corosync/authkey
 scp /etc/corosync/authkey 172.29.236.13:/etc/corosync/authkey
 service corosync restart
 ssh 172.29.236.12 service corosync restart
 ssh 172.29.236.13 service corosync restart
 crm_mon
 crm status
 crm configure primitive openstack-vip ocf:heartbeat:IPaddr2 params ip="172.29.239.150" cidr_netmask="22" op monitor interval="30s"
 #crm configure primitive vip2 ocf:heartbeat:IPaddr2   params ip="172.29.236.151" cidr_netmask="24" op monitor interval="30s"
 cd /usr/lib/ocf/resource.d/
 mkdir openstack
 cd openstack
 wget https://raw.github.com/leseb/keystone/ha/tools/ocf/keystone
 wget https://raw.github.com/madkiss/glance/ha/tools/ocf/glance-registry
 wget https://raw.github.com/madkiss/glance/ha/tools/ocf/glance-api
