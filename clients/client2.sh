#!/bin/bash
echo "8021q" >> /etc/modules

cat > /etc/network/interfaces << EOF
auto eth1.10
iface eth1.10 inet static
  pre-up ip link add name eth1.10 link eth1 type vlan id 10
  up ip link set dev eth1.10 up
  up ip route add 172.16.31.0/30 via 172.16.31.5 dev eth1.10
  address 172.16.31.6
  netmask 255.255.255.252

EOF

ifup eth1.10