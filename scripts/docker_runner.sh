#include worker.sh
cat > lookup.sh << 'END_LOOKUP_SH'
echo tcp://$(dig +short $1.service.consul):$(dig +short $1.service.consul SRV | awk '{print $3}')
sudo killall -s 1 consul
END_LOOKUP_SH
chmod +x lookup.sh

cat > run.sh << 'END_RUN_SH'
sudo docker run -e REDIS_PORT=$(./lookup.sh redis) -e ZK_PORT=$(./lookup.sh zookeeper) -e MONGO_PORT=$(./lookup.sh mongo) --net=host -d $(dig +short docker.service.consul)/$1
END_RUN_SH
chmod +x run.sh

cat > expose.sh << 'END_EXPOSE_SH'
echo '{"service":{"name":"'$1'","port":'$2',"check":{"script":"nc -z localhost '$2'","interval":"10s"}}}' | sudo tee -a /etc/consul.d/$1.json
sudo killall -s 1 consul
END_EXPOSE_SH
chmod +x expose.sh

