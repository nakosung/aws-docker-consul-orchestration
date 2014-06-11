#include worker.sh

sudo docker run --name redis -p 6379:6379 -d redis
echo '{"service":{"name":"redis","port":6379,"check":{"script":"nc -z localhost 6379","interval":"10s"}}}' | sudo tee -a /etc/consul.d/redis.json

sudo docker run --name mongo -p 27017:27017 -d mongo
echo '{"service":{"name":"mongo","port":27017,"check":{"script":"nc -z localhost 27017","interval":"10s"}}}' | sudo tee -a /etc/consul.d/mongo.json

sudo killall -s 1 consul
