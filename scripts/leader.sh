#!/bin/bash
#include common.sh
#include id_rsa_pub.sh
#include id_rsa.sh

echo "install consul web ui"
mkdir /tmp/consul_ui
cd /tmp/consul_ui
curl -OL https://dl.bintray.com/mitchellh/consul/0.2.1_web_ui.zip
unzip -o *

sudo sh -c "nohup consul agent -server -bootstrap -data-dir=/tmp/consul -config-dir=/etc/consul.d -ui-dir=/tmp/consul_ui/dist> /var/log/consul.log 2>&1 &"

#include dns.sh

#include docker.sh

mkdir -p /home/ubuntu
cd /home/ubuntu

sudo rm run_at.sh
cat > run_at.sh << 'END_RUN_SH'
sudo docker \
    -H $1 \
    rm -f $1
sudo docker \
    -H $1 \
    pull $(dig @localhost -p 8600 +short registry.service.consul)/$1
sudo docker \
    -H $1 \
    run \
    -e REDIS_PORT=$(lookup.sh redis) \
    -e ZK_PORT=$(lookup.sh zookeeper) \
    -e MONGO_PORT=$(lookup.sh mongo) \
    -e REGISTRY_PORT=$(lookup.sh registry) \
    ${@:2} \    
    --net=host \
    --name=$1 \
    -d $(dig @localhost -p 8600 +short registry.service.consul)/$2
END_RUN_SH
sudo chmod +x run_at.sh
sudo mv run_at.sh /usr/local/bin