#! /bin/bash
#
# This Script will install and configure an Kibana server for my home Network. There are hardcoded IP addresses in this script.
#
# Get Inital configuration.
#
initial-config.sh
#
# Get Dependencies
#
sudo yum install wget java -y
#
# Configure the Firewall
#
sudo firewall-cmd --zone=public --add-port=7611/tcp --permanent
sudo firewall-cmd --zone=public --add-port=7611/udp --permanent
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=7611 --permanent
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=udp:toport=7611 --permanent
sudo firewall-cmd --zone=public --add-forward-port=port=443:proto=tcp:toport=7611 --permanent
sudo firewall-cmd --zone=public --add-forward-port=port=443:proto=udp:toport=7611 --permanent
#
# Set up elk repo:
#
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
sudo touch /etc/yum.repos.d/elasticsearch.repo
echo "
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md" >> /etc/yum.repos.d/elasticsearch.repo
#
# Install and Configure Kibana
#
sudo yum install kibana -y
udo sed -i 's^#server.name: "your-hostname"^server.name: "kibana"^' /etc/kibana/kibana.yml
sudo sed -i "s^#logging.quiet: false^logging.quiet: true^" /etc/kibana/kibana.yml
sudo sed -i "s^#server.port: 5601^server.port: 7611^" /etc/kibana/kibana.yml
sudo sed -i 's^#server.host: "localhost"^server.host: "10.8.7.11"^' /etc/kibana/kibana.yml
sudo sed -i 's^#elasticsearch.hosts: ["http://localhost:9200"]^elasticsearch.hosts: ["http://10.8.8.9:9200"]^' /etc/kibana/kibana.yml
sudo systemctl daemon-reload
sudo systemctl enable kibana
#
# Start and Enable Services
# 
sudo systemctl restart kibana
