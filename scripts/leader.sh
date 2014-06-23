#!/bin/bash
#include common.sh
#include id_rsa_pub.sh
#include id_rsa.sh

#include utils/consul_webui.sh

sudo sh -c "nohup consul agent -server -bootstrap -data-dir=/tmp/consul -config-dir=/etc/consul.d -ui-dir=/tmp/consul_ui/dist> /var/log/consul.log 2>&1 &"
while [[ true ]]; do
    sudo cat /var/log/consul.log | grep 'Consul agent running!' && break    
done

#include dns.sh

mkdir -p /home/ubuntu
cd /home/ubuntu
#embed launch.sh utils/launch.sh +x
./launch.sh &

#include docker.sh
