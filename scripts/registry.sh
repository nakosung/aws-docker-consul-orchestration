#include worker.sh

sudo docker run --name registry -p 80:5000 -d registry
echo '{"service":{"name":"docker","port":80,"check":{"script":"nc -z localhost 80","interval":"10s"}}}' | sudo tee -a /etc/consul.d/registry.json

sudo killall -s 1 consul

#include id_rsa.sh
