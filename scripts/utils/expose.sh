echo '{"service":{"name":"'$1'","port":'$2',"check":{"script":"nc -z localhost '$2'","interval":"10s"}}}' | sudo tee /etc/consul.d/$1.json
sudo killall -s 1 consul