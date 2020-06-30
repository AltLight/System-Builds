#! /bin/bash
#
# This Script will install and configure an ELK server for my home Network. There are hardcoded IP addresses in this script.
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
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=5601 --permanent
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=udp:toport=5601 --permanent
sudo firewall-cmd --zone=public --add-forward-port=port=443:proto=tcp:toport=5601 --permanent
sudo firewall-cmd --zone=public --add-forward-port=port=443:proto=udp:toport=5601 --permanent
sudo firewall-cmd --zone=public --add-port=9200/tcp --permanent
sudo firewall-cmd --zone=public --add-port=9200/udp --permanent
sudo firewall-cmd --zone=public --add-port=5601/tcp --permanent
sudo firewall-cmd --zone=public --add-port=5601/udp --permanent
sudo firewall-cmd --zone=public --add-port=5524/udp --permanent
sudo firewall-cmd --zone=public --add-port=5525/udp --permanent
sudo firewall-cmd --zone=public --add-port=5044/udp --permanent
sudo firewall-cmd --reload
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
sudo sed -i "s^#network.host: 192.168.0.1^network.host: 10.8.5.60^" /etc/elasticsearch/elasticsearch.yml
sudo sed -i "s^#http.port: 9200^http.port: 9200^" /etc/elasticsearch/elasticsearch.yml
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch 
#
# Install and Configure Kibana
#
sudo yum install kibana -y
sudo sed -i "s^#logging.quiet: false^logging.quiet: true^" /etc/kibana/kibana.yml
sudo sed -i "s^#server.port: 5601^server.port: 5601^" /etc/kibana/kibana.yml
sudo sed -i 's^#server.host: "localhost"^server.host: "10.8.5.60"^' /etc/kibana/kibana.yml
sudo sed -i 's^#elasticsearch.hosts: ["http://localhost:9200"]^elasticsearch.hosts: ["http://10.8.5.60:9200"]^' /etc/kibana/kibana.yml
sudo systemctl daemon-reload
sudo systemctl enable kibana
#
# Install and Configure Logstash
#
sudo yum install logstash -y
sudo systemctl daemon-reload
sudo systemctl enable logstash
sudo sed -i "s^# node.name: test^node.name: Logstash^" /etc/logstash/logstash.yml
#
# Create logstash patterns:
#
sudo mkdir -p /etc/logstash/patterns
sudo touch /etc/logstash/patterns/pfsense_2_4_2.grok
sudo echo "
# GROK Custom Patterns (add to patterns directory and reference in GROK filter for pfSense events):
# GROK Patterns for pfSense 2.4.2 Logging Format
#
# Created 27 Jan 2015 by J. Pisano (Handles TCP, UDP, and ICMP log entries)
# Edited 14 Feb 2015 by Elijah Paul elijah.paul@gmail.com
# Edited 10 Mar 2015 by Bernd Zeimetz <bernd@bzed.de>
# Edited 28 Oct 2017 by Brian Turek <brian.turek@gmail.com>
# Edited 5 Jan 2017 by Andrew Wilson <andrew@3ilson.com>
# taken from https://gist.github.com/elijahpaul/3d80030ac3e8138848b5
#
# - Adjusted IPv4 to accept pfSense 2.4.2
# - Adjusted IPv6 to accept pfSense 2.4.2
#
# TODO: Add/expand support for IPv6 messages.
#
PFSENSE_LOG_ENTRY %{PFSENSE_LOG_DATA}%{PFSENSE_IP_SPECIFIC_DATA}%{PFSENSE_IP_DATA}%{PFSENSE_PROTOCOL_DATA}?
PFSENSE_LOG_DATA %{INT:rule},%{INT:sub_rule}?,,%{INT:tracker},%{WORD:iface},%{WORD:reason},%{WORD:action},%{WORD:direction},
PFSENSE_IP_DATA %{INT:length},%{IP:src_ip},%{IP:dest_ip},
PFSENSE_IP_SPECIFIC_DATA %{PFSENSE_IPv4_SPECIFIC_DATA}|%{PFSENSE_IPv6_SPECIFIC_DATA}
PFSENSE_IPv4_SPECIFIC_DATA (?<ip_ver>(4)),%{BASE16NUM:tos},%{WORD:ecn}?,%{INT:ttl},%{INT:id},%{INT:offset},%{WORD:flags},%{INT:proto_id},%{WORD:proto},
PFSENSE_IPv6_SPECIFIC_DATA (?<ip_ver>(6)),%{BASE16NUM:IPv6_Flag1},%{WORD:IPv6_Flag2},%{WORD:flow_label},%{WORD:proto_type},%{INT:proto_id},
PFSENSE_PROTOCOL_DATA %{PFSENSE_UDP_DATA}|%{PFSENSE_TCP_DATA}|%{PFSENSE_ICMP_DATA}|%{PFSENSE_IGMP_DATA}|%{PFSENSE_IPv6_VAR}
PFSENSE_UDP_DATA %{INT:src_port},%{INT:dest_port},%{INT:data_length}
PFSENSE_TCP_DATA %{INT:src_port},%{INT:dest_port},%{INT:data_length},%{WORD:tcp_flags},%{INT:sequence_number},%{INT:ack_number},%{INT:tcp_window},%{DATA:urg_data},%{GREEDYDATA:tcp_options}
PFSENSE_IGMP_DATA datalength=%{INT:data_length}
PFSENSE_ICMP_DATA %{PFSENSE_ICMP_TYPE}%{PFSENSE_ICMP_RESPONSE}
PFSENSE_ICMP_TYPE (?<icmp_type>(request|reply|unreachproto|unreachport|unreach|timeexceed|paramprob|redirect|maskreply|needfrag|tstamp|tstampreply)),
PFSENSE_ICMP_RESPONSE %{PFSENSE_ICMP_ECHO_REQ_REPLY}|%{PFSENSE_ICMP_UNREACHPORT}| %{PFSENSE_ICMP_UNREACHPROTO}|%{PFSENSE_ICMP_UNREACHABLE}|%{PFSENSE_ICMP_NEED_FLAG}|%{PFSENSE_ICMP_TSTAMP}|%{PFSENSE_ICMP_TSTAMP_REPLY}
PFSENSE_ICMP_ECHO_REQ_REPLY %{INT:icmp_echo_id},%{INT:icmp_echo_sequence}
PFSENSE_ICMP_UNREACHPORT %{IP:icmp_unreachport_dest_ip},%{WORD:icmp_unreachport_protocol},%{INT:icmp_unreachport_port}
PFSENSE_ICMP_UNREACHPROTO %{IP:icmp_unreach_dest_ip},%{WORD:icmp_unreachproto_protocol}
PFSENSE_ICMP_UNREACHABLE %{GREEDYDATA:icmp_unreachable}
PFSENSE_ICMP_NEED_FLAG %{IP:icmp_need_flag_ip},%{INT:icmp_need_flag_mtu}
PFSENSE_ICMP_TSTAMP %{INT:icmp_tstamp_id},%{INT:icmp_tstamp_sequence}
PFSENSE_ICMP_TSTAMP_REPLY %{INT:icmp_tstamp_reply_id},%{INT:icmp_tstamp_reply_sequence},%{INT:icmp_tstamp_reply_otime},%{INT:icmp_tstamp_reply_rtime},%{INT:icmp_tstamp_reply_ttime}

PFSENSE_IPv6_VAR %{WORD:Type},%{WORD:Option},%{WORD:Flags},%{WORD:Flags}

# PFSENSE
PFSENSE_CARP_DATA (%{WORD:carp_type}),(%{INT:carp_ttl}),(%{INT:carp_vhid}),(%{INT:carp_version}),(%{INT:carp_advbase}),(%{INT:carp_advskew})
PFSENSE_APP (%{DATA:pfsense_APP}):
PFSENSE_APP_DATA (%{PFSENSE_APP_LOGOUT}|%{PFSENSE_APP_LOGIN}|%{PFSENSE_APP_ERROR}|%{PFSENSE_APP_GEN})
PFSENSE_APP_LOGIN (%{DATA:pfsense_ACTION}) for user \'(%{DATA:pfsense_USER})\' from: (%{GREEDYDATA:pfsense_REMOTE_IP})
PFSENSE_APP_LOGOUT User (%{DATA:pfsense_ACTION}) for user \'(%{DATA:pfsense_USER})\' from: (%{GREEDYDATA:pfsense_REMOTE_IP})
PFSENSE_APP_ERROR webConfigurator (%{DATA:pfsense_ACTION}) for \'(%{DATA:pfsense_USER})\' from (%{GREEDYDATA:pfsense_REMOTE_IP})
PFSENSE_APP_GEN (%{GREEDYDATA:pfsense_ACTION})

# SNORT
PFSENSE_SNORT %{SPACE}\[%{NUMBER:ids_gen_id}:%{NUMBER:ids_sig_id}:%{NUMBER:ids_sig_rev}\]%{SPACE}%{GREEDYDATA:ids_desc}%{SPACE}\[Classification:%{SPACE}%{GREEDYDATA:ids_class}\]%{SPACE}\[Priority:%{SPACE}%{NUMBER:ids_pri}\]%{SPACE}{%{WORD:ids_proto}}%{SPACE}%{IP:ids_src_ip}:%{NUMBER:ids_src_port}%{SPACE}->%{SPACE}%{IP:ids_dest_ip}:%{NUMBER:ids_dest_port}" >> /etc/logstash/patterns/pfsense_2_4_2.grok
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
sudo touch /etc/logstash/conf.d/01-logs.conf
sudo echo 'input {
  udp {
    port => 5525
    type => "syslog"
  }
  udp {
    port => 5044
    type => "beats"
  }
}
filter {
  if [host] =~ /\/10\.8\.0\.1\// {
    mutate {
      add_field => [ "ip_address", "%{host}" ]
      remove_tag => [ "syslog" ]
      add_tag => [ "firewall" ]
    }
	  grok {
      match => [ "message", "<(?<evtid>.*)>(?<datetime>(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+(?:(?:0[1-9])|(?:[12][0-9])|(?:3[01])|[1-9]) (?:2[0123]|[01]?[0-9]):(?:[0-5][0-9]):(?:[0-5][0-9])) (?<prog>.*?): (?<msg>.*)" ]
    }
	  mutate {
      gsub => ["datetime","  "," "]
    }
    date {
      match => [ "datetime", "MMM dd HH:mm:ss" ]
      timezone => "America/Chicago"
    }
    mutate {
      replace => [ "message", "%{msg}" ]
    }
    mutate {
      remove_field => [ "msg", "datetime" ]
    }
    if [prog] =~ /^snort/ {
      mutate {
        add_tag => [ "SnortIDPS" ]
      }
      grok {
        patterns_dir => ["/etc/logstash/patterns"]
        match => [ "message", "%{PFSENSE_SNORT}"]
      }
      if ![geoip] and [ids_src_ip] !~ /^(10\.|192\.168\.)/ {
        geoip {
          add_tag => [ "GeoIP" ]
          source => "ids_src_ip"
          database => "/etc/logstash/GeoLite2-City.mmdb"
        }
      }
      if [prog] =~ /^snort/ {
        mutate {
          add_tag => [ "ET-Sig" ]
          add_field => [ "Signature_Info", "http://doc.emergingthreats.net/bin/view/Main/%{[ids_sig_id]}" ]
        }
      }
    }
    if [prog] =~ /^charon$/ {
      mutate {
        add_tag => [ "ipsec" ]
      }
    }
    if [prog] =~ /^barnyard2/ {
      mutate {
        add_tag => [ "barnyard2" ]
      }
    }
    if [prog] =~ /^openvpn/ {
      mutate {
        add_tag => [ "openvpn" ]
      }
    }
    if [prog] =~ /^ntpd/ {
      mutate {
        add_tag => [ "ntpd" ]
      }
    }
    if [prog] =~ /^php-fpm/ {
      mutate {
        add_tag => [ "web_portal" ]
      }
      grok {
          patterns_dir => ["/etc/logstash/patterns"]
          match => [ "message", "%{PFSENSE_APP}%{PFSENSE_APP_DATA}"]
      }
      mutate {
          lowercase => [ pfsense_ACTION ]
      }
    }
    if [prog] =~ /^apinger/ {
      mutate {
        add_tag => [ "apinger" ]
      }
    }
    if [prog] =~ /^filterlog$/ {
        mutate {
            remove_field => [ "msg", "datetime" ]
        }
        grok {
            add_tag => [ "firewall" ]
            patterns_dir => ["/etc/logstash/patterns"]
            match => [ "message", "%{PFSENSE_LOG_DATA}%{PFSENSE_IP_SPECIFIC_DATA}%{PFSENSE_IP_DATA}%{PFSENSE_PROTOCOL_DATA}",
                       "message", "%{PFSENSE_IPv4_SPECIFIC_DATA}%{PFSENSE_IP_DATA}%{PFSENSE_PROTOCOL_DATA}",
                       "message", "%{PFSENSE_IPv6_SPECIFIC_DATA}%{PFSENSE_IP_DATA}%{PFSENSE_PROTOCOL_DATA}"]
        }
        mutate {
            lowercase => [ proto ]
        }
        if ![geoip] and [src_ip] !~ /^(10\.8\.)/ {
          geoip {
            add_tag => [ "GeoIP" ]
            source => "src_ip"
            database => "/etc/logstash/GeoLite2-City.mmdb"
          }
        }
    }
    mutate {
      remove_tag => [ "_grokparsefailure", "_geoip_lookup_failure " ]
    }
  }
  if [host] =~ /\/10\.8\.0\.250\// or /\/10\.8\.0\.251\// or /\/10\.8\.0\.252\// {
	  grok {
      match => ["message", "%{SYSLOG5424PRI}%{NUMBER:log_sequence#}: %{CISCOTIMESTAMP:log_date}: %%{CISCO_REASON:facility}-%{INT:severity_level}-%{CISCO_REASON:facility_mnemonic}: %{GREEDYDATA:message}" ]
    }
    mutate {
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "ip_address", "%{host}" ]
      add_tag => [ "cisco" ]
      remove_tag => "syslog"
      remove_tag => [ "_grokparsefailure" ]
      remove_tag => [ "_geoip_lookup_failure " ]
    }
    mutate {
      remove_field => [ "host", "syslog_hostname", "syslog_message", "syslog_timestamp", "_score", "_type" ]
    }
  } 
  if "syslog" in [tags] {
    dns {
      reverse => [ "host" ]
      action => "replace"
    }
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
    }
    mutate {
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "ip_address", "%{host}" ]
      add_field => [ "HostName", "%{syslog_hostname}" ]
      add_tag => [ "syslog" ]
      remove_field => [ "host", "syslog_hostname", "syslog_message", "syslog_timestamp", "_score", "_type" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM  dd HH:mm:ss" ]
      locale => "en"
    }
    if !("_grokparsefailure" in [tags]) {
      mutate {
        replace => [ "@source_host", "%{syslog_hostname}" ]
        replace => [ "@message", "%{syslog_message}" ]
        add_field => [ "ip_address", "%{host}" ]
        remove_tag => [ "_grokparsefailure" ]
        remove_field => [ "syslog_hostname", "syslog_message", "syslog_timestamp" ]
      }
    }
  }
}
output {
  elasticsearch {
    hosts => ["http://10.8.5.60:9200"]
  	sniffing => true
    index => "logstash-%{+YYYY.MM.dd}" 
  }
}' >> /etc/logstash/conf.d/01-logs.conf
#
# Start and Enable Services
#
sudo systemctl restart elasticsearch 
sudo systemctl restart kibana
sudo systemctl restart logstash