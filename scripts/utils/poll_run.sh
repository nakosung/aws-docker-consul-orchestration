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