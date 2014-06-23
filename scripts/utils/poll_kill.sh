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