USER=ubuntu
# sudo useradd user sudo
sudo mkdir -p /home/$USER/.ssh
sudo cp /home/$USER/.ssh/authorized_keys .

cat >> authorized_keys << EOF_ID_PUB
ID_RSA_PUB
EOF_ID_PUB

sudo cp authorized_keys /home/$USER/.ssh/authorized_keys
sudo cat /etc/passwd
sudo chown -R $USER /home/$USER/.ssh