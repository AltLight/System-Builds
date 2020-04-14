#! /bin/bash
#
# Derived From:
#    https://linuxize.com/post/how-to-install-jenkins-on-centos-7/
#
# Install Packages and Dependicies
#
sudo yum -y install epel-release 
sudo yum -y update
sudo yum -y install java-1.8.0-openjdk-devel htop vim wget
sudo cp /etc/profile /etc/profile_backup
echo 'export JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk' | sudo tee -a /etc/profile
echo 'export JRE_HOME=/usr/lib/jvm/jre' | sudo tee -a /etc/profile
source /etc/profile
#
# Configure Firewall
#
PERM="--permanent"
SERV="$PERM --service=jenkins"
#
sudo firewall-cmd $PERM --new-service=jenkins
sudo firewall-cmd $SERV --set-short="Jenkins ports"
sudo firewall-cmd $SERV --set-description="Jenkins port exceptions"
sudo firewall-cmd $SERV --add-port=8080/tcp
sudo firewall-cmd $PERM --add-service=jenkins
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --reload
#
# Install Jenkins
#
rpm=$(ls | grep jenkins*.rpm)
if [ -z $rpm ]
then
    echo -e "\n\nNo jenkins rpm was could be found in the current directory ($(pwd)), trying to download from the internet...\n\n"
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    sudo yum -y install jenkins
else
    echo -e "The following rpm was found and will be installed:\n\n$rpm\n"
    sudo rpm -ivh $rpm
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

echo -e "\n\n\nThe Jenkins service has been installed and is accessable at the following url:\\nnhttp://$comp_name:8080\n\nThe tempory password is:\n$init_pass\n\nService status:\n\n$(sudo systemctl status jenkins)\n\n"
exit 0
