KV_URL=http://localhost:8500/v1/kv
RunTargets=$(curl -s $KV_URL/client?recurse)
test -z $RunTargets && exit -1

Target=$(echo $RunTargets | jq ".[0]")

Key=$(echo $Target | jq -r ".Key")
#Value=$(echo $Target | jq -r ".Value" | base64 -d)
arr=( $(echo $Key | tr "/" "\n") )
RunName=${arr[1]}

#RunAlias=$(echo $Value | jq -r ".alias")
#RunArgs=$(echo $Value | jq -r ".args")
#test $RunAlias = null && RunAlias=$RunName
#test $RunArgs = null && RunArgs=''

./client.sh $RunName || exit -1

curl -s -X DELETE $KV_URL/$Key

exit 0