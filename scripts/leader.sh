#!/bin/bash
#include common.sh
#include id_rsa_pub.sh
#include id_rsa.sh

mkdir /tmp/consul_ui
cd /tmp/consul_ui
curl -OL https://dl.bintray.com/mitchellh/consul/0.2.1_web_ui.zip
unzip -o *

sudo sh -c "nohup consul agent -server -bootstrap -data-dir=/tmp/consul -ui-dir=/tmp/consul_ui/dist> /var/log/consul.log 2>&1 &"

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