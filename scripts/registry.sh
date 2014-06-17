#include worker.sh

echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> /home/ubuntu/.ssh/config
echo -e "Host bitbucket.com\n\tStrictHostKeyChecking no\n" >> /home/ubuntu/.ssh/config

expose.sh registry 80

sudo docker run --name registry -p 80:5000 -d registry

cd /home/ubuntu
cat > ./build.sh << 'BUILD_SH_END'
sudo docker build -t $1 $1 && sudo docker tag $1 localhost:80/$1 && sudo docker push localhost:80/$1
BUILD_SH_END
chmod +x build.sh

#include id_rsa.sh
