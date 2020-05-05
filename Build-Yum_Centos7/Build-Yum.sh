#! /bin/bash
#
# Website for full detailed instructions:
#    https://www.tecmint.com/setup-local-http-yum-repository-on-centos-7/
#
# Get Inital configuration.
#
# Set script variables
##################################################################################################################################
compname=$(hostname)
if [ ! -z dnsdomainname ]
then
    read -rep $'What is the domain for this system?\nex: domain.local\n>' domain
else
    domain=$(dnsdomainname)
fi
fqdn="$compname.$domain"
# Get Dependencies and update packages
##################################################################################################################################
sudo yum install epel-release  -y
sudo yum install nginx policycoreutils-devel createrepo yum-utils yum-cron -y
#
# Configure the Firewall and SeLinux
#
# sudo sed -i "s^SELINUX=enforcing^SELINUX=disabled^" /etc/sysconfig/selinux
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --reload
#
# Create the NGINX/Yum Directory.
##################################################################################################################################
sudo mkdir -p /var/www/html/repos/centos7
#
# Sync Centos & local repos:
Repo_Dir=(base centosplus extras updates)
#
# Create the Repo Data
for Dir in ${Repo_Dir[@]}
do
    mkdir -p /var/www/html/repos/centos7/$Dir
    sudo reposync -g -l -d -m --repoid=$Dir --newest-only --download-metadata --download_path=/var/www/html/repos/centos7/$Dir
    sudo touch /var/www/html/repos/centos7/$Dir/comps.xml
    sudo createrepo -g comps.xml /var/www/html/repos/centos7/$Dir/
done
#
# Configure NGINX
##################################################################################################################################
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
semodule -i nginx.pp
#
nginx_conf=$(ls /etc/nginx/conf.d/ | grep repos.conf)
if [ ! -z $nginx_conf ]
then
    sudo rm -f $nginx_conf
fi
#
touch repos.conf
echo "server {
        listen   80;
        server_name  "$fqdn";
        root   /var/www/html/repos/centos7;
        location / {
                index  index.php index.html index.htm;
                autoindex on;	#enable listing of directory index
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
}" >> repos.conf
sudo mv repos.congf /etc/nginx/conf.d/repos.conf
#
# Configure daily update cron job
##################################################################################################################################
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
#  Enable and Start Services
chcon -Rt httpd_sys_content_t /var/www/
sudo systemctl enable nginx
sudo systemctl restart nginx
sudo systemctl enable yum-cron
sudo systemctl restart yum-cron
#
echo -e "\n\nThe url for the yum repo is:\nhttp://$fqdn/"
exit 0
