#! /bin/bash
#
# This Script will install and configure an Logstash server for my home Network. There are hardcoded IP addresses in this script.
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
sudo firewall-cmd --zone=public --add-port=5525/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5525/udp --permanent
sudo firewall-cmd --zone=public --add-port=5526/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5526/udp --permanent
sudo firewall-cmd --zone=public --add-port=5527/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5527/udp --permanent
sudo firewall-cmd --zone=public --add-port=5528/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5528/udp --permanent
sudo firewall-cmd --zone=public --add-port=5529/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5529/udp --permanent
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
# Install and Configure Logstash
#
sudo yum install logstash -y
sudo systemctl daemon-reload
sudo systemctl enable logstash
#
# Configure logstash.yml

sudo sed -i "s^# pipeline.workers: 2^pipeline.workers: 1^" /etc/logstash/logstash.yml
sudo sed -i "s^# node.name: test^node.name: Logstash^" /etc/logstash/logstash.yml
#
# Create logstash patterns:
#
sudo mkdir -p /etc/logstash/patterns
# TODO Copy Patterns files to the above directory!
#
# Configure GeoLite Database
#
cd /etc/logstash/
sudo wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz
sudo gunzip GeoLite2-City.mmdb.gz
cd ~/
#
# Create logstash conf files:
#
# TODO Copy the *.conf files to /etc/logstash/conf.d/
#
# Configure Multiple Pipelines:
mv /etc/logstash/pipelines.yml /etc/logstash/pipelines.yml.orig
touch /etc/logstash/pipelines.yml
echo "
- pipeline.id: winlogbeat
  path.config: "/etc/logstash/conf.d/winlogbeat.cfg"
  pipeline.workers: 1
  queue.type: persisted
- pipeline.id:  pfsense
  path.config: "/etc/logstash/conf.d/pfsense.cfg"
  pipeline.workers: 1
  queue.type: persisted
- pipeline.id:  cisco
  path.config: "/etc/logstash/conf.d/cisco.cfg"
  pipeline.workers: 1
  queue.type: persisted
- pipeline.id:  syslog
  path.config: "/etc/logstash/conf.d/syslog.cfg"
  pipeline.workers: 1
  queue.type: persisted
- pipeline.id:  pihole
  path.config: "/etc/logstash/conf.d/pihole.cfg"
  pipeline.workers: 1
  queue.type: persisted
" >> /etc/logstash/pipelines.yml
# Start and Enable Services
#
sudo systemctl restart logstash