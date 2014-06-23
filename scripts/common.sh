apt-get update -y
#apt-get install -y jq

# download latest jq
wget http://stedolan.github.io/jq/download/linux64/jq
chmod +x jq
mv jq /usr/bin/jq

# install consul
apt-get install -y unzip
mkdir /tmp/consul
cd /tmp/consul
curl -OL https://dl.bintray.com/mitchellh/consul/0.3.0_linux_amd64.zip
unzip -o *
chmod +x consul
sudo cp consul /usr/local/bin

# prepare data dir
mkdir /etc/consul.d

# util func
cd /tmp
#embed expose.sh utils/expose.sh +x
sudo mv expose.sh /usr/local/bin
