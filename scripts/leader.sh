#!/bin/bash
#include common.sh
#include id_rsa_pub.sh
#include id_rsa.sh
sudo sh -c "nohup consul agent -server -bootstrap -data-dir=/tmp/consul > /var/log/consul.log 2>&1 &"

# echo "waiting for quorom"
# while [ "`consul members | grep role=consul | wc -l`" -eq 1 ]; do sleep 1; done
# sudo killall consul

# QUOROM=$(consul members | grep consul | awk {'split($2,a,":"); print a[1]'} | head -n 1)
# echo "quorom : $QUOROM"

# sudo mkdir /etc/consul.d
# sudo sh -c "nohup consul agent -data-dir=/tmp/consul -config-dir=/etc/consul.d -join='$QUOROM' > /var/log/consul.log 2>&1 &"


# EC2
# sudo sed -i.dist 's,universe$,universe multiverse,' /etc/apt/sources.list
# sudo apt-get update
# sudo apt-get install -y ec2-api-tools

#include dns.sh