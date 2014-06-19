expose.sh docker 4243

# install docker.io
curl https://get.docker.io | sh

# expose docker interface to public (should be restricted within subnet)
echo 'DOCKER_OPTS="-H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock"' | sudo tee -a /etc/default/docker 
sudo service docker restart

cd /tmp
cat > lookup.sh << 'END_LOOKUP_SH'
IP=$(dig @localhost -p 8600 +short $1.service.consul)
test -z $IP && exit -1
PORT=$(dig @localhost -p 8600 +short $1.service.consul SRV | awk '{print $3}')
echo tcp://$IP:$PORT
END_LOOKUP_SH

chmod +x lookup.sh
sudo mv lookup.sh /usr/local/bin
