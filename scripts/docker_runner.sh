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


sudo apt-get install -y jq

cat > poll_run.sh << 'POLL_RUN_END'

DOCKER_URL=http://localhost:4243
KV_URL=http://localhost:8500/v1/kv
RunTargets=$(curl -s $KV_URL/$(hostname)/run?recurse)
test -z $RunTargets && exit -1

Target=$(echo $RunTargets | jq ".[0]")

Key=$(echo $Target | jq -r ".Key")
Value=$(echo $Target | jq -r ".Value" | base64 -d)
arr=( $(echo $Key | tr "/" "\n") )
RunName=${arr[2]}


RunImage=$(echo $Value | jq -r ".image")
RunArgs=$(echo $Value | jq -r ".args")
test $RunImage = null && RunImage=$RunName
test $RunArgs = null && RunArgs=''

echo "run_aliased.sh $RunName $RunImage $RunArgs"
bash -c "run_aliased.sh $RunName $RunImage $RunArgs"

test $(sudo docker inspect $RunName 2>/dev/null | jq ". | length") -eq 0 && echo "$RunName failed" && exit -2

echo "$RunName launched"

curl -s -X DELETE $KV_URL/$Key
curl -s $DOCKER_URL/containers/json | curl -s -X PUT $KV_URL/$(hostname)/docker/containers -d @-

exit 0
POLL_RUN_END

chmod +x poll_run.sh





cat > poll_expose.sh << 'EXPOSE_RUN_END'

DOCKER_URL=http://localhost:4243
KV_URL=http://localhost:8500/v1/kv
RunTargets=$(curl -s $KV_URL/$(hostname)/expose?recurse)
test -z $RunTargets && exit -1

Target=$(echo $RunTargets | jq ".[0]")

Key=$(echo $Target | jq -r ".Key")
Value=$(echo $Target | jq -r ".Value" | base64 -d)
arr=( $(echo $Key | tr "/" "\n") )
RunName=${arr[2]}

curl -X DELETE $KV_URL/$Key

RunPort=$(echo $Value | jq -r ".port")

expose.sh $RunName $RunPort

exit 0
EXPOSE_RUN_END

chmod +x poll_expose.sh


cat > loop.sh << LOOP_END
while [[ true ]]; do
	./poll_expose.sh || ./poll_run.sh || sleep 5
done
LOOP_END
chmod +x loop.sh

nohup bash ./loop.sh > /var/log/docker-runner.log 2>&1 & 

expose.sh worker 22