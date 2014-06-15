#include worker.sh

echo '{"service":{"name":"redis","port":6379,"check":{"script":"nc -z localhost 6379","interval":"10s"}}}' | sudo tee -a /etc/consul.d/redis.json
echo '{"service":{"name":"mongo","port":27017,"check":{"script":"nc -z localhost 27017","interval":"10s"}}}' | sudo tee -a /etc/consul.d/mongo.json
echo '{"service":{"name":"zookeeper","port":2181,"check":{"script":"nc -z localhost 2181","interval":"10s"}}}' | sudo tee -a /etc/consul.d/zookeeper.json
sudo killall -s 1 consul

sudo docker run --name redis -p 6379:6379 -d redis
sudo killall -s 1 consul

sudo docker run --name mongo -p 27017:27017 -d mongo
sudo killall -s 1 consul

sudo docker run --name zk -p 2181:2181 -p 2888:2888 -p 3888:3888 -d jplock/zookeeper
sudo killall -s 1 consul
