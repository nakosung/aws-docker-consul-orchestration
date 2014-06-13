#include worker.sh

cat > run.sh << 'END_RUN_SH'
sudo docker run -e REDIS_PORT=tcp://redis.service.consul:6379 -e ZK_PORT=tcp://zookeeper.service.consul:2181 -e MONGO_PORT=tcp://mongo.service.consul:27017 --net=host -d $(dig +short docker.service.consul)/$1
END_RUN_SH
chmod +x run.sh

cat > expose.sh << 'END_EXPOSE_SH'
echo '{"service":{"name":"'$1'","port":'$2',"check":{"script":"nc -z localhost '$2'","interval":"10s"}}}' | sudo tee -a /etc/consul.d/$1.json
sudo killall -s 1 consul
END_EXPOSE_SH
chmod +x expose.sh
