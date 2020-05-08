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
sudo mv -f /etc/yum.repos.d/*.repo /opt/$domain/Archive

#
# Create local repo file:
Repo_Dir=(base centosplus extras updates)
#
for Dir in ${Repo_Dir[@]}
do
    file_name="local-$dir.repo"
    touch $file_name
    dot_domian=".$domain"
    echo -e "[Local-$Dir]
    name=$Dir
    baseurl=http://yum$dot_domain/$Dir
    enabled=1
    gpgcheck=0
    " >> $file_name
    mv $file_name /etc/yum.repos.d/$file_name
    yum --enablerepo=local-$Dir
done
#
# Clean Yum and update client
sudo yum clean all
sudo yum update -y
exit 0