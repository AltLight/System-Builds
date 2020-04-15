# Build_Jenkins
Automated way of installing jenkins service on a Centos 7 minimal server.

Only tested against Centos 7

You will have to create a user ssh key on the Jenkins server, and add the generated public key to Gitlab. See the below
link for more information on how to do the:
  https://help.github.com/en/enterprise/2.18/user/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

The default login for the Jenkins url is:
   •	username = admin
   •	password = 
      o	go back to vm and type: cat /var/lib/jenkins/secrets/initialAdminPassword
      o	Copy the output as the password
