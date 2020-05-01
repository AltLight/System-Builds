#!/bin/bash
#
# Set Script Variables:
##################################################################################################################################
fqdn="$(hostname).$(dnsdomainname)"
ip_addr=$(ip a | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

#
# Install epel and update
##################################################################################################################################
sudo yum install -y epel-release
sudo yum update -y
sudo yum -y install -y git gcc gcc-c++ ansible nodejs gettext device-mapper-persistent-data lvm2 bzip2 python3-pip yum-utils policycoreutils-python htop vim
#
# Configure the Firewall & SELinux
##################################################################################################################################
sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
#
sudo semanage port -a -t http_port_t -p tcp 8050
sudo semanage port -a -t http_port_t -p tcp 8051
sudo semanage port -a -t http_port_t -p tcp 8052
sudo setsebool -P httpd_can_network_connect 1
#
# Docker-CE
##################################################################################################################################
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce
sudo systemctl start docker
sudo systemctl enable docker
#
# Docker Compose
sudo pip3 install docker-compose
sudo alternatives --set python /usr/bin/python3
#
# Download, Configure, & Install AWX
##################################################################################################################################
mkdir -p /awx
cd /awx
git clone https://github.com/ansible/awx.git
#
# Configure Inventory File:
pw_list=(pg_password rabbitmq_password admin_password)
sudo touch /.awxpws
#
def_password=$(pwgen -N 1 -s 30)
for pw in ${pw_list[@]}
do
    pw_change="${pw}=''"
    pw_clean="${pw}="
    echo -e "\nusername=$pw\npassword=$def_password" > /.awxpws
    sed -i "s^$pw_change^$pw_clean\'$def_password\'^"
done
unset def_password
inv_key=$(openssl rand -base64 30)
sed -i "S^secret_key=^secret_key=$inv_key^"
echo -e "\nsecret_key=$inv_key" > /.awxpws
unset inv_key
#
sudo mkdir -p /var/lib/pgdocker
#
ansible-playbook -i inventory install.yml