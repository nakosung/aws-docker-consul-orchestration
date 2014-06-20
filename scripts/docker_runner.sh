#include worker.sh

mkdir -p /home/ubuntu
cd /home/ubuntu

cat > run_aliased.sh << 'END_RUN_ALIASED_SH'
echo $EVERYAUTH
sudo docker rm -f $1
sudo docker pull $(dig @localhost -p 8600 +short registry.service.consul)/$2
sudo docker run \
    -e REDIS_PORT=$(lookup.sh redis) \
    -e ZK_PORT=$(lookup.sh zookeeper) \
    -e MONGO_PORT=$(lookup.sh mongo) \
    -e REGISTRY_PORT=$(lookup.sh registry) \
    ${@:3} \
    --net=host \
    --name=$1 \
    -d $(dig @localhost -p 8600 +short registry.service.consul)/$2
END_RUN_ALIASED_SH
sudo chmod +x run_aliased.sh
sudo mv run_aliased.sh /usr/local/bin




cat > run.sh << 'END_RUN_SH'
run_aliased.sh $1 ${@:1}
END_RUN_SH
sudo chmod +x run.sh
sudo mv run.sh /usr/local/bin





cat > poll_run.sh << 'POLL_RUN_END'

Type=$1
DOCKER_URL=http://localhost:4243
KV_URL=http://localhost:8500/v1/kv
RunTargets=$(curl -s $KV_URL/$(hostname)/$Type/?recurse)
test -z $RunTargets && exit -1

Target=$(echo $RunTargets | jq ".[0]")

Key=$(echo $Target | jq -r ".Key")
RawValue=$(echo $Target | jq -r ".Value")
Value=$(echo $RawValue | base64 -d)
arr=( $(echo $Key | tr "/" "\n") )
RunName=${arr[2]}

RunImage=$(echo $Value | jq -r ".image")
RunArgs=$(echo $Value | jq -r ".args")
test $RunImage = null && RunImage=$RunName
test $RunArgs = null && RunArgs=''

# Some magic keywords
RunArgs=$(echo '' $RunArgs | sed s/LOCAL_IP_ADDRESS/$(hostname -i)/g)

echo "run_aliased.sh $RunName $RunImage $RunArgs"
bash -c "run_aliased.sh $RunName $RunImage $RunArgs"

function toss {
	curl -s -X DELETE $KV_URL/$Key
	echo $RawValue | base64 -d | curl -s -X PUT $KV_URL/${arr[0]}/$1/$RunName -d @-
}

test $(sudo docker inspect $RunName 2>/dev/null | jq ". | length") -eq 0 && echo "$RunName failed" && toss failed && exit -2

sudo docker inspect $RunName | jq -r '.[].Config.ExposedPorts | to_entries | [ .[] | .key | rtrimstr("/tcp") | "expose.sh '$RunName'-\(.) \(.)" ] | join("\n")' | sh

Container=$(docker ps -lq)
echo "$RunName($RunImage) launched $Container"

toss running

curl -s $DOCKER_URL/containers/json | curl -s -X PUT $KV_URL/$(hostname)/docker/containers -d @-

exit 0
POLL_RUN_END

chmod +x poll_run.sh


cat > poll_kill.sh << 'POLL_KILL_END'

Type=$1
DOCKER_URL=http://localhost:4243
KV_URL=http://localhost:8500/v1/kv
RunTargets=$(curl -s $KV_URL/$(hostname)/$Type/?recurse)
test -z $RunTargets && exit -1

Target=$(echo $RunTargets | jq ".[0]")

Key=$(echo $Target | jq -r ".Key")
RawValue=$(echo $Target | jq -r ".Value")
Value=$(echo $RawValue | base64 -d)
arr=( $(echo $Key | tr "/" "\n") )
RunName=${arr[2]}

RunImage=$(echo $Value | jq -r ".image")
RunArgs=$(echo $Value | jq -r ".args")
test $RunImage = null && RunImage=$RunName
test $RunArgs = null && RunArgs=''

sudo docker kill $RunName
curl -s -X DELETE $KV_URL/$Key

curl -s $DOCKER_URL/containers/json | curl -s -X PUT $KV_URL/$(hostname)/docker/containers -d @-

exit 0
POLL_KILL_END

chmod +x poll_kill.sh

cat > restart_containers.sh << 'RESTART_CONTAINERS_END'
docker ps -a | grep "Exit" | grep -v "(0)" | awk '{print $1}' | xargs -r docker restart
RESTART_CONTAINERS_END

chmod +x restart_containers.sh

cat > loop.sh << LOOP_END
while [[ true ]]; do
	./poll_kill.sh kill || ./poll_run.sh run || sleep 5 && ./poll_run.sh failed
    ./restart_containers.sh
done
LOOP_END
chmod +x loop.sh

nohup bash ./loop.sh > /var/log/docker-runner.log 2>&1 & 

expose.sh worker 22