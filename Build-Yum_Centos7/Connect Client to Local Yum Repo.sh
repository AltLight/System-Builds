#! /bin/bash
#
# This script connects the client to a local yum server.
compname=$(hostname)
if [ -z dnsdomainname ]
then
    read -rep $'What is the domain for this system?\nex: domain.local\n>' domain
    fqdn="$compname.$domain"
    sed -i "$ a $ipaddr $fqdn $compname" /etc/hosts
    sed -i "$ a DOMAIN=\"$domain\"" /etc/sysconfig/network-scripts/*$ipint*
else
    domain=$(dnsdomainname)
fi
#
# Move all default repo config files to archive:
sudo mkdir -p /etc/yum.repos.d/Archive
sudo mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/Archive
#
# Create local repo file:
Repo_Dir=(base centosplus extras updates)
#
cd /etc/yum.repos.d/
for Dir in ${Repo_Dir[@]}
do
    file_name="local-$Dir.repo"
    touch $file_name
    dot_domain=".$domain"
    echo -e "[local-$Dir]
name=CentOS $Dir
baseurl=http://yum$dot_domain/$Dir/
enabled=1
gpgcheck=0" >> $file_name
    yum --enablerepo=local-$Dir
done
cd ~
#
# Clean Yum and update client
sudo yum clean all
sudo yum update -y
exit 0