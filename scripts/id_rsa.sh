USER=ubuntu
# sudo useradd $USER sudo
sudo mkdir -p /home/$USER/.ssh

cat > id_rsa << EOF_ID
ID_RSA
EOF_ID

sudo mv id_rsa /home/$USER/.ssh/id_rsa
sudo chmod 600 /home/$USER/.ssh/id_rsa
sudo cat /etc/passwd
sudo chown -R $USER /home/$USER/.ssh