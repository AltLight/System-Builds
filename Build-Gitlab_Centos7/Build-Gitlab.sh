#! /bin/bash
#
# Install dependicies and updates:
sudo yum -y install epel-release
sudo yum -y update
sudo yum install -y curl policycoreutils-python openssh-server openssh-clients cockpit vim htop
sudo systemctl enable sshd
sudo systemctl start sshd
#
# Configure the Firewall:
#
sudo firewall-cmd --add-service=http --zone=public --permanent 
sudo firewall-cmd --add-service=https --zone=public --permanent 
sudo firewall-cmd --add-service=cockpit --zone=public --permanent 
sudo firewall-cmd --add-port=9090/tcp --zone=public --permanent 
sudo firewall-cmd --reload
#
# Install and configure mail notification client:
#
sudo yum install postfix -y
sudo systemctl enable postfix
sudo systemctl start postfix
#
# Add GitLab package repo and install <-- package:
#
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash
#
# Install gitlab:
#
echo -e "What is the domain for this system?\nex: domain.local\n> "
read -p '' domain
#
echo -e "Are you connected to the internet, and if so do you want to enable https?\n[yes] or [no]\n"
read -p '' https
#
if [ $https = "yes" ]
then
    url="https://gitlab.$domain"
elif [ $https = "no" ]
then
    url="http://gitlab.$domain"
else
    echo "no valid response given, aborting operations"
    exit 1
fi
#
sudo EXTERNAL_URL=$url yum install -y gitlab-ce
exit 0