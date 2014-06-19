#include worker.sh

echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> /home/ubuntu/.ssh/config
echo -e "Host bitbucket.com\n\tStrictHostKeyChecking no\n" >> /home/ubuntu/.ssh/config

# run stable docker registry!
sudo docker run --name registry -p 80:5000 -d registry:0.7.0
expose.sh registry 80

cd /home/ubuntu
cat > ./build.sh << 'BUILD_SH_END'
sudo docker build -t $1 $1 && sudo docker tag $1 localhost:80/$1 && sudo docker push localhost:80/$1
BUILD_SH_END
chmod +x build.sh

#include id_rsa.sh


# ------------ SERVER(docker)
cat > update.sh << 'UPDATE_SH_END'
HOME=~ubuntu
( (cd $1 && git pull) || git clone ssh://git@bitbucket.com/redduck/$1) && ./build.sh $1
UPDATE_SH_END
chmod +x update.sh






cat > poll_update.sh << 'POLL_UPDATE_END'

KV_URL=http://localhost:8500/v1/kv
RunTargets=$(curl -s $KV_URL/registry?recurse)
test -z $RunTargets && exit -1

Target=$(echo $RunTargets | jq ".[0]")

Key=$(echo $Target | jq -r ".Key")
Value=$(echo $Target | jq -r ".Value" | base64 -d)
arr=( $(echo $Key | tr "/" "\n") )
RunName=${arr[1]}


#RunAlias=$(echo $Value | jq -r ".alias")
#RunArgs=$(echo $Value | jq -r ".args")
#test $RunAlias = null && RunAlias=$RunName
#test $RunArgs = null && RunArgs=''

./update.sh $RunName || exit -1

curl -s -X DELETE $KV_URL/$Key

exit 0
POLL_UPDATE_END

chmod +x poll_update.sh


mkdir -p /home/ubuntu

# ------------ CLIENT(cdn)
cat > client.sh << 'CLIENT_UPDATE_SH_END'
HOME=~ubuntu
echo "updating client $1"
GIT=$(lookup.sh cdn-7002)
test -z $GIT && exit -1
( (cd $1 && git pull) || (git clone ssh://git@bitbucket.com/redduck/$1 && cd $1 && git remote add cdn $(echo $GIT | sed -e 's/tcp/http/')/$1) ) && (cd $1 && git push cdn master) && exit 0
CLIENT_UPDATE_SH_END
chmod +x client.sh


cat > poll_client.sh << 'POLL_CLIENT_END'

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
POLL_CLIENT_END

chmod +x poll_client.sh




cat > loop.sh << LOOP_END
while [[ true ]]; do
	(sudo -u ubuntu bash ./poll_update.sh) || (sudo -u ubuntu bash ./poll_client.sh) || sleep 5
done
LOOP_END
chmod +x loop.sh

nohup bash ./loop.sh > /var/log/docker-registry.log 2>&1 & 

