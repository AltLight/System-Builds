#! /bin/bash
#
# This script connects the client to a local yum server.
echo "What is the domain for this system?"
echo "ex: your.domain"
read -p '' domain
#
# Move all default repo config files to archive:
sudo mkdir -p /opt/$domain/Archive
sudo mv /etc/yum.repos.d/*.repo /opt/$domain/Archive
#
# Create local repo file:
Repo_Dir=(base centosplus extras updates)
#
for Dir in ${Repo_Dir[@]}
do
    sudo echo "
    [Local-Repository]
    name=Centos $Dir
    baseurl=http://yum.$domain/$Dir
    enabled=0
    gpgcheck=0
    " >> /etc/yum.repos.d/local.repo
done
#
# Clean Yum and update client
sudo yum clean all
sudo yum update -y