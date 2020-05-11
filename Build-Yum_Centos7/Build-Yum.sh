#! /bin/bash
#
# Website for full detailed instructions:
#    https://www.tecmint.com/setup-local-http-yum-repository-on-centos-7/
#
# Get Inital configuration.
#
# Set script variables
#
urlpath='/var/www/html/repos/centos7/'
compname=$(hostname)
ipaddr=$(ip address show | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d'/')
ipint=$(ip address show | grep 'state UP' | awk '{print $2}' | cut -f1 -d ':')
#
if [ -z dnsdomainname ]
then
    read -rep $'What is the domain for this system?\nex: domain.local\n>' domain
    fqdn="$compname.$domain"
    sed -i "$ a $ipaddr $fqdn $compname" /etc/hosts
    sed -i "$ a DOMAIN=\"$domain\"" /etc/sysconfig/network-scripts/*$ipint*
else
    domain=$(dnsdomainname)
    fqdn="$compname.$domain"    
fi
#
# Get Dependencies and update packages
#
sudo yum install -y epel-release
yum update -y
sudo yum install -y nginx policycoreutils-devel createrepo yum-utils yum-cron
#
# Create the NGINX/Yum Directory.
#
sudo mkdir -p $urlpath
#
# Sync Centos & local repos:
Repo_Dir=(base centosplus extras updates)
#
# Create the Repo Data
for Dir in ${Repo_Dir[@]}
do
    mkdir -p $urlpath/$Dir
    sudo reposync -g -l -d -m --repoid=$Dir --newest-only --download-metadata --download_path=$urlpath/$Dir
    sudo touch $urlpath/$Dir/comps.xml
    sudo createrepo -g comps.xml $urlpath/$Dir/
done
#
# Configure NGINX
#
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
semodule -i nginx.pp
#
nginx_conf=$(ls /etc/nginx/conf.d/ | grep repos.conf)
if [ ! -z $nginx_conf ]
then
    sudo rm -f $nginx_conf
fi
#
cp -f /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
cd /etc/nginx/conf.d/
touch repos.conf
echo "server {
    listen   80;
    server_name  $fqdn;
    root   $urlpath;
    location / {
            index  index.php index.html index.htm;
            autoindex on;
            try_files \$uri \$uri/ =404;
    }

    error_page 404 /404.html;
        location = /40x.html {
    }

    error_page 500 502 503 504 /50x.html;
        location = /50x.html {
    }
}" > repos.conf
cd ~
#
# Configure daily update cron job
#
# Configure Cron update task:
sudo touch /etc/cron.daily/repo-update
#
sudo echo '#!/bin/bash
##specify all local repositories in a single variable
#
Local_Repos=(base centosplus extras updates)
#
# loop to update repos one at a time 
#
for Repo in ${Local_Repos[@]}
do
    reposync -g -l -d -m --repoid=$Repo --newest-only --download-metadata --download_path=/var/www/html/repos/centos7/
    createrepo -g comps.xml /var/www/html/repos/centos7/$Repo/  
done' > /etc/cron.daily/repo-update
#
sudo sed -i "\$a59 23 * * * root /etc/cron.daily/repo-update" /etc/crontab
sudo chmod 755 /etc/cron.daily/repo-update
#
# Configure the Firewall and SeLinux
#
# sudo sed -i "s^SELINUX=enforcing^SELINUX=disabled^" /etc/sysconfig/selinux
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --reload
#
sudo setsebool -P httpd_can_network_connect on
setsebool -P httpd_read_user_content 1
semodule -i nginx.pp
#
#  Enable and Start Services
chcon -Rt httpd_sys_content_t /var/www/
sudo systemctl enable nginx
sudo systemctl restart nginx
sudo systemctl enable yum-cron
sudo systemctl restart yum-cron
#
echo -e "\n\nThe url for the yum repo is:\nhttp://$fqdn/"
exit 0