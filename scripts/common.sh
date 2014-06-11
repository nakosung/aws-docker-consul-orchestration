sudo apt-get install -y unzip
mkdir /tmp/consul
cd /tmp/consul
curl -OL https://dl.bintray.com/mitchellh/consul/0.2.1_linux_amd64.zip
unzip -o *
chmod +x consul
sudo cp consul /usr/local/bin