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


cat > launch.sh << 'LAUNCH_SH_END'

KV_URL=http://localhost:8500/v1/kv

curl -X PUT $KV_URL/client/yt-framework -d '{}'
curl -X PUT $KV_URL/client/dashboard -d '{}'
curl -X PUT $KV_URL/client/yt-phy -d '{}'
curl -X PUT $KV_URL/client/pang-db -d '{}'
curl -X PUT $KV_URL/client/yt-sosopang -d '{}'
curl -X PUT $KV_URL/client/yt-soso -d '{}'

curl -X PUT $KV_URL/registry/db -d '{}'
curl -X PUT $KV_URL/registry/devices -d '{}'
curl -X PUT $KV_URL/registry/eventbus -d '{}'
curl -X PUT $KV_URL/registry/gateway  -d '{}'
curl -X PUT $KV_URL/registry/nginx  -d '{}'
curl -X PUT $KV_URL/registry/router  -d '{}'
curl -X PUT $KV_URL/registry/user -d '{}'
curl -X PUT $KV_URL/registry/server  -d '{}'
curl -X PUT $KV_URL/registry/cdn -d '{}'
curl -X PUT $KV_URL/registry/url_feedback -d '{}'
curl -X PUT $KV_URL/registry/gift -d '{}'
curl -X PUT $KV_URL/registry/mailbox -d '{}'
curl -X PUT $KV_URL/registry/receipt -d '{}'
curl -X PUT $KV_URL/registry/email -d '{}'
curl -X PUT $KV_URL/registry/server_saga -d '{}'
curl -X PUT $KV_URL/registry/bank -d '{}'
curl -X PUT $KV_URL/registry/server_heart -d '{}'
curl -X PUT $KV_URL/registry/zko -d '{}'
curl -X PUT $KV_URL/registry/remotelog -d '{}'

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


curl -X PUT $KV_URL/$TARGET/expose/gateway -d '{"port":"7070"}'
curl -X PUT $KV_URL/$TARGET/expose/webfrontend -d '{"port":"3000"}'
curl -X PUT $KV_URL/$TARGET/expose/git -d '{"port":"7002"}'
curl -X PUT $KV_URL/$TARGET/run/router -d '{}'
curl -X PUT $KV_URL/$TARGET/run/devices -d '{}'
curl -X PUT $KV_URL/$TARGET/run/eventbus -d '{}'
curl -X PUT $KV_URL/$TARGET/run/gateway -d '{}'
curl -X PUT $KV_URL/$TARGET/run/cdn -d '{"args":"-v /mnt/cdn:/tmp"}'
curl -X PUT $KV_URL/$TARGET/run/authdb -d '{"image":"db","args":"-e MONGO_SETNAME=auth -e MY_MONGO_ADDR=$(hostname -i):27017 -v /mnt/authdb/data:/data"}'
curl -X PUT $KV_URL/$TARGET/run/gamedb -d '{"image":"db","args":"-e MY_MONGO_ADDR=$(hostname -i):27018 -v /mnt/gamedb/data:/data"}'
curl -X PUT $KV_URL/$TARGET/run/user -d '{}'
curl -X PUT $KV_URL/$TARGET/run/server -d '{"args":"-e EVERYAUTH='\'{\\"\"github\\"\":\\"\"EVERYAUTH_GITHUB\\"\"}\''"}'
curl -X PUT $KV_URL/$TARGET/run/nginx -d '{}'
curl -X PUT $KV_URL/$TARGET/run/url_feedback -d '{}'
curl -X PUT $KV_URL/$TARGET/run/gift -d '{}'
curl -X PUT $KV_URL/$TARGET/run/mailbox -d '{}'
curl -X PUT $KV_URL/$TARGET/run/receipt -d '{}'
curl -X PUT $KV_URL/$TARGET/run/email -d '{}'
curl -X PUT $KV_URL/$TARGET/run/server_saga -d '{}'
curl -X PUT $KV_URL/$TARGET/run/server_heart -d '{}'
curl -X PUT $KV_URL/$TARGET/run/zko -d '{}'
curl -X PUT $KV_URL/$TARGET/run/remotelog -d '{}'

LAUNCH_SH_END
chmod +x launch.sh

./launch.sh