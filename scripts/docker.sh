mkdir -p /etc/consul.d

expose.sh docker 4243

# install docker.io
curl https://get.docker.io | sh

# expose docker interface to public (should be restricted within subnet)
echo 'DOCKER_OPTS="-H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock"' | sudo tee -a /etc/default/docker 
sudo service docker restart

cd /tmp
cat > lookup.sh << 'END_LOOKUP_SH'
echo tcp://$(dig @localhost -p 8600 +short $1.service.consul):$(dig @localhost -p 8600 +short $1.service.consul SRV | awk '{print $3}')
END_LOOKUP_SH

chmod +x lookup.sh
sudo mv lookup.sh /usr/local/bin
