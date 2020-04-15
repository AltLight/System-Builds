#! /bin/bash
#
# This script connects the client to a local yum server.
if [ ! -z dnsdomainname ]
then
    read -rep $'What is the domain for this system?\nex: domain.local\n>' domain
else
    domain=$(dnsdomainname)
fi
#
# Move all default repo config files to archive:
sudo mkdir -p /opt/$domain/Archive
sudo mv /etc/yum.repos.d/*.repo /opt/$domain/Archive
touch local.repo
#
# Create local repo file:
Repo_Dir=(base centosplus extras updates)
#
for Dir in ${Repo_Dir[@]}
do
    echo "[Local-Repository]
    name=$Dir
    baseurl=http://yum.$domain/$Dir
    enabled=0
    gpgcheck=0
    " >> local.repo
done
#
sudo mv local.repo /etc/yum.repos.d/local.repo
#
# Clean Yum and update client
sudo yum clean all
sudo yum update -y
exit 0
