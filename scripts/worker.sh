#!/bin/bash
#include common.sh
#include docker.sh
#include wait.sh
#include id_rsa_pub.sh

sudo sh -c "nohup consul agent -data-dir=/tmp/consul -config-dir=/etc/consul.d -join='CONSUL_LEADER_IP' > /var/log/consul.log 2>&1 &"

#//include dns.sh

