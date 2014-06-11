sudo apt-get install -y dnsmasq
sudo sh -c 'echo "server=/consul/127.0.0.1#8600" > /etc/dnsmasq.d/10-consul'
sudo service dnsmasq force-reload
