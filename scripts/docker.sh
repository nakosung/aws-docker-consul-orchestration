expose.sh docker 4243

# install docker.io
curl https://get.docker.io | sh

# expose docker interface to public (should be restricted within subnet)
echo 'DOCKER_OPTS="-H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock"' | sudo tee -a /etc/default/docker 
sudo service docker restart

cd /tmp
cat > lookup_host.sh << 'END_LOOKUP_HOST_SH'
dig @localhost -p 8600 +short $1.service.consul
END_LOOKUP_HOST_SH
cat > lookup_port.sh << 'END_LOOKUP_PORT_SH'
dig @localhost -p 8600 +short $1.service.consul SRV | awk '{print $3}'
END_LOOKUP_PORT_SH
cat > lookup.sh << 'END_LOOKUP_SH'
IP=$(lookup_host.sh $1)
test -z $IP && exit -1
PORT=$(lookup_port.sh $1)
echo tcp://$IP:$PORT
END_LOOKUP_SH

chmod +x lookup_host.sh
sudo mv lookup_host.sh /usr/local/bin
chmod +x lookup_port.sh
sudo mv lookup_port.sh /usr/local/bin
chmod +x lookup.sh
sudo mv lookup.sh /usr/local/bin
