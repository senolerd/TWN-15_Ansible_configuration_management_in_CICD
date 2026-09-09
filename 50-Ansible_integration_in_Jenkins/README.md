Demo Project:
Ansible Integration in Jenkins
Technologies used:
Ansible, Jenkins, DigitalOcean, AWS, Boto3, Docker, Java, Maven, Linux, Git
Project Description:
• Create and configure a dedicated server for Jenkins
• Create and configure a dedicated server for Ansible Control Node
• Write Ansible Playbook, which configures 2 EC2 Instances
• Add sshkey file credentials in Jenkins for Ansible Control Node server and Ansible Managed Node servers
• Configure Jenkins to execute the Ansible Playbook on remote Ansible Control Node server as part of the C/CD pipeline
• So the Jenkinsfile configuration will do the following:
a. Connect to the remote Ansible Control Node server
b. Copy Ansible playbook and configuration files to the remote Ansible Control Node server
c. Copy the ssh keys for the Ansible Managed Node servers to the Ansible Control Node server
d. Install Ansible, Python3 and Boto3 on the Ansible Control Node server
e. With everything installed and copied to the remote Ansible Control Node server, execute the playbook remotely on that Control Node that will configure the 2 EC2 Managed Nodes
Module 15: Configuration Management with Ansible

