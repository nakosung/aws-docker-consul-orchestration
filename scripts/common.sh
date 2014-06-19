apt-get update -y
apt-get install -y jq
wget http://stedolan.github.io/jq/download/linux64/jq
chmod +x jq
mv jq /usr/bin/jq
apt-get install -y unzip
mkdir /tmp/consul
cd /tmp/consul
curl -OL https://dl.bintray.com/mitchellh/consul/0.2.1_linux_amd64.zip
unzip -o *
chmod +x consul
sudo cp consul /usr/local/bin

mkdir /etc/consul.d

cd /tmp
cat > expose.sh << 'END_EXPOSE_SH'
echo '{"service":{"name":"'$1'","port":'$2',"check":{"script":"nc -z localhost '$2'","interval":"10s"}}}' | sudo tee /etc/consul.d/$1.json
sudo killall -s 1 consul
END_EXPOSE_SH
chmod +x expose.sh

sudo mv expose.sh /usr/local/bin
