#include worker.sh

expose.sh registry 80

echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> /home/ubuntu/.ssh/config
echo -e "Host bitbucket.com\n\tStrictHostKeyChecking no\n" >> /home/ubuntu/.ssh/config

# run stable docker registry!
#sudo docker run --name registry -p 80:5000 -d registry:0.7.0


mkdir -p /home/ubuntu


#embed /home/ubuntu/config.yml docker-registry/config.yml
REDIS_HOST=$(lookup_host.sh redis)
REDIS_PORT=$(lookup_port.sh redis)
docker run --name registry -d -e CACHE_REDIS_HOST=$REDIS_HOST -e CACHE_LRU_REDIS_HOST=$REDIS_HOST -e CACHE_REDIS_PORT=$REDIS_PORT -e CACHE_LRU_REDIS_PORT=$REDIS_PORT -e SETTINGS_FLAVOR=prod -v /home/ubuntu:/registry-conf -e DOCKER_REGISTRY_CONFIG=/registry-conf/config.yml -p 80:5000 registry:0.7.0         

cd /home/ubuntu
cat > ./build.sh << 'BUILD_SH_END'
sudo docker pull localhost:80/$1
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



#embed client.sh utils/client.sh +x
#embed poll_update.sh utils/poll_update.sh +x
#embed poll_client.sh utils/poll_client.sh +x
#embed loop.sh utils/loop_registry.sh +x

#embed /etc/init/docker-registry.conf utils/docker-registry.conf

start docker-registry
