# wait until consul is online
while [ -n "`nc -w 1 -z CONSUL_LEADER_IP 8301 || echo "yay"`" ]; do echo 'wait'; done
echo 'okay consul is online'
