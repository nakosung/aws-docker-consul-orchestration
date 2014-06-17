#include worker.sh

mkdir -p /home/ubuntu
cd /home/ubuntu

sudo rm run_aliased.sh
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

sudo rm run.sh
cat > run.sh << 'END_RUN_SH'
run_aliased.sh $1 ${@:1}
END_RUN_SH
sudo chmod +x run.sh
sudo mv run.sh /usr/local/bin


