#! /bin/bash
#
# This Script will install and configure an Elasticsearch server for my home Network. There are hardcoded IP addresses in this script.
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
sudo firewall-cmd --zone=public --add-port=9200/tcp --permanent
sudo firewall-cmd --zone=public --add-port=9200/udp --permanent
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
# Install and configuire Elasticsearch
#
sudo yum install elasticsearch -y
sudo sed -i "s^#network.host: 192.168.0.1^network.host: 10.8.8.9^" /etc/elasticsearch/elasticsearch.yml
sudo sed -i "s^#http.port: 9200^http.port: 9200^" /etc/elasticsearch/elasticsearch.yml
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch 
#
# Start and Enable Services
# 
sudo systemctl restart elasticsearch