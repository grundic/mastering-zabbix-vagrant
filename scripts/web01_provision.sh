#!/bin/sh

if [ -f "/var/vagrant_provision" ]; then
    exit 0
fi

echo "Provisioning web front end"

# install
rpm -ivh http://repo.zabbix.com/zabbix/2.4/rhel/6/x86_64/zabbix-release-2.4-1.el6.noarch.rpm
yum install zabbix-web-pgsql.noarch -y

# configure
chkconfig --add httpd
chkconfig httpd on
sed -i "s/^;date.timezone =$/date.timezone = \"Europe\/Moscow\"/" /etc/php.ini |grep "^timezone" /etc/php.ini
iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT

# start
/etc/init.d/httpd start

yum install pacemaker corosync -y

cp /etc/corosync/corosync.conf.example /etc/corosync/corosync.conf

export MULTICAST_PORT=4000
export MULTICAST_ADDRESS=226.94.1.1
export BIND_NET_ADDRESS=`ip addr | grep "inet " |grep brd |tail -n1 | awk '{print $4}' | sed s/255/0/`

sed -i.bak "s/ *mcastaddr:.*/mcastaddr:\ $MULTICAST_ADDRESS/g" /etc/corosync/corosync.conf
sed -i.bak "s/ *mcastport:.*/mcastport:\ $MULTICAST_PORT/g" /etc/corosync/corosync.conf
sed -i.bak "s/ *bindnetaddr:.*/bindnetaddr:\ $BIND_NET_ADDRESS/g" /etc/corosync/corosync.conf

cat <<'EOF' > /etc/corosync/service.d/pcmk
service {
  # Load the Pacemaker Cluster Resource Manager
  name: pacemaker
  ver: 1
}
EOF

/etc/init.d/corosync start
/etc/init.d/pacemaker start

wget http://download.opensuse.org/repositories/network:/ha-clustering:/Stable/CentOS_CentOS-6/network:ha-clustering:Stable.repo -O /etc/yum.repos.d/etwork:ha-clustering:Stable.repo
yum install crmsh -y

crm configure property stonith-enabled="false"
crm configure property no-quorum-policy=ignore
crm configure property default-resource-stickiness="100"

cat <<'EOF' >> /etc/httpd/conf/httpd.conf
<Location /server-status>
   SetHandler server-status
   Order deny,allow
   Deny from all
   Allow from 127.0.0.1 192.168.100.0/24
</Location>
EOF

/etc/init.d/httpd restart

echo primitive vip ocf:heartbeat:IPaddr2 params \
     ip="10.0.0.100" nic="eth1" cidr_netmask="24" \
     op start interval="0s" timeout="50s" op monitor \
     interval="5s" timeout="20s" op stop interval="0s" \
     timeout="50s" | crm configure

echo primitive httpd ocf:heartbeat:apache params \
     configfile="/etc/httpd/conf/httpd.conf" port="80" \
     op start interval="0s" timeout="50s" op monitor interval="5s" \
     timeout="20s" op stop interval="0s" timeout="50s" | crm configure

echo group webserver vip httpd | crm configure

# TODO: this should be fixed, for now turn off firewall at all
iptables -F

touch /var/vagrant_provision
echo "Provisioning finished."
