#! /bin/bash
#
# Derived From:
#    https://linuxize.com/post/how-to-install-jenkins-on-centos-7/
#
# Install Packages and Dependicies
#
sudo yum -y install epel-release 
sudo yum -y update
sudo yum -y install java-1.8.0-openjdk-devel htop vim git
sudo cp /etc/profile /etc/profile_backup
echo 'export JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk' | sudo tee -a /etc/profile
echo 'export JRE_HOME=/usr/lib/jvm/jre' | sudo tee -a /etc/profile
source /etc/profile
#
# Configure Firewall
#
sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --reload
#
# Install Jenkins
#
user_prompt=$(echo -e "Is Jenkins going to be install from a local rpm or from the yum repo?\n[local] [yum]\n> ")
read -p "$user_prompt" install_type
if [ $install_type = "local" ]
then
        local_install_prompt=$(echo -e "local rpm chosen, is the rpm in the current directory?\n[yes] [no]\n> ")
        read -p "$local_install_prompt" rpm_local
        if [ $rpm_local = "yes" ]
        then
            sudo rpm -ivh jenkins*
        elif [ $rpm_local = "" ]
        then
            echo -e "Move the jenkins rpm file to this current directory ($(pwd)) and run this script again"
            stop
        else
            echo "No valid response given, aborting operations."
            stop
        fi
elif [ $install_type = "yum"  ]
then
        curl --silent --location http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo | sudo tee /etc/yum.repos.d/jenkins.repo
        sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
        sudo yum install jenkins
else
        echo "No valid response given, aborting operations."
        stop
fi
#
# Start and enable service
#
sudo systemctl start jenkins
sudo systemctl enable jenkins
#
# Return information to user
#
init_pass=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
comp_name=$(hostname)
echo -e "\n\n\nThe Jenkins service has been installed and is accessable at the following url:\nhttp://$comp_name:8080\n\nThe tempory password is:\n$init_pass"