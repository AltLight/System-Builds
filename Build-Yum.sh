#! /bin/bash
#
# Website for full detailed instructions:
#    https://www.tecmint.com/setup-local-http-yum-repository-on-centos-7/
#
# Get Inital configuration.
#
# Get Dependencies and update packages
#
FQDN=$(hostname --fqdn)
sudo yum install epel-release nginx policycoreutils-devel createrepo yum-utils yum-cron -y
#
# Configure the Firewall
#
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --reload
#
# Create & Populate the Yum Directory.
#
sudo mkdir -p /var/www/html/repos/centos7
#
Repo_Dir=(base centosplus extras updates)
#
# Create the Repo Data
for Dir in ${Repo_Dir[@]}
do
    mkdir -p /var/www/html/repos/centos7/$Dir
    sudo reposync -g -l -d -m --repoid=$Dir --newest-only --download-metadata --download_path=/var/www/html/repos/$Dir
    sudo touch /var/www/html/repos/centos7/$Dir/comps.xml
    sudo createrepo -g comps.xml /var/www/html/repos/centos7/$Dir/
done
#
# Configure NGINX
#
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
semodule -i nginx.pp
#
sudo touch /etc/nginx/conf.d/repos.conf
sudo echo "server {
        listen   80;
        server_name  "$FQDN";
        root   /var/www/html/repos;
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
}" > /etc/nginx/conf.d/repos.conf
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
    createrepo -g comps.xml /var/www/html/repos/$Repo/  
done' >> /etc/cron.daily/repo-update
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
echo -e "\nThe url for the yum repo is:\nhttp://$FQDN"
