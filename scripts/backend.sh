#include worker.sh

expose.sh redis 6379
expose.sh mongo 27017
expose.sh zookeeper 2181

sudo docker run --name zk -p 2181:2181 -p 2888:2888 -p 3888:3888 -d jplock/zookeeper
sudo docker run --name redis -p 6379:6379 -d redis
sudo docker run --name mongo -p 27017:27017 -d mongo
