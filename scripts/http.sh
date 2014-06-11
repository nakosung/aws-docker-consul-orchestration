#include worker.sh

mkdir /tmp/web
echo "<html><body>hello world</body></html>" > /tmp/web/index.html

sudo docker run --name nginx -p 80:80 -v /tmp/web:/usr/local/nginx/html:ro -d nginx 
echo '{"service":{"name":"web","port":80,"check":{"script":"curl -sS -o /dev/null http://localhost","interval":"10s"}}}' | sudo tee -a /etc/consul.d/web.json

sudo killall -s 1 consul
