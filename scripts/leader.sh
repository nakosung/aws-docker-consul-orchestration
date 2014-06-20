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
while [[ true ]]; do
    sudo cat /var/log/consul.log | grep 'Consul agent running!' && break    
done

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


cat > launch.sh << 'LAUNCH_SH_END'

KV_URL=http://localhost:8500/v1/kv

cat > make-consul-req.sh << 'MAKE_CONSUL_REQ_END'
jq -r 'to_entries | [.[] | "cat << JSON | curl -s -X PUT '$1'/\(.key) -d @- \n\(.value)\nJSON"] | join("\n") | tostring'
MAKE_CONSUL_REQ_END
chmod +x make-consul-req.sh

cat > run-consul-req.sh << 'RUN_CONSUL_REQ_END'
cat | ./make-consul-req.sh $1 | sh
RUN_CONSUL_REQ_END
chmod +x run-consul-req.sh

./run-consul-req.sh $KV_URL/client << 'CDN_CLIENTS_JSON_END'
#include cdn-clients.json
CDN_CLIENTS_JSON_END

./run-consul-req.sh $KV_URL/registry << 'DOCKER_IMAGES_JSON_END'
#include docker-images.json
DOCKER_IMAGES_JSON_END

while true; do
	WORKER_IPS=$(dig +short worker.service.consul)
	test $WORKER_IPS || continue
	WORKER_IP_ARRAY=( $WORKER_IPS )
	WORKER_IP=${WORKER_IP_ARRAY[0]}
	WORKER_HOSTNAME=$(consul members | grep $WORKER_IP | awk {'print $1'})
	echo "found worker $WORKER_HOSTNAME($WORKER_IP)"
	break
done

TARGET=$WORKER_HOSTNAME


./run-consul-req.sh $KV_URL/$TARGET/run << 'DOCKER_CONTAINERS_JSON_END'
#include docker-containers.json
DOCKER_CONTAINERS_JSON_END

LAUNCH_SH_END
chmod +x launch.sh

./launch.sh