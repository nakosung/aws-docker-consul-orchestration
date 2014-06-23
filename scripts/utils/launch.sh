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