
Task: Demo Project
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





- Infra has Terrafrom IaC for creating environment for assignment. The ec2 instances aws keypair (named "devops-key") created by $USER's default ssh private key. Jenkins, Ansible, and the two workstations can be connected via ubuntu user and private ssh key as identity credential file. 
- Jenkins and Ansible instances accept ssh from Terraform runner IP address. Worker nodes accept SSH only from Ansible controller server. Worker nodes can serve from ["80", "443", "8080"] tcp ports by default IaC setting. IaC is created the way can bootstrap workstations with required packages by "workstation_apt_pkcs" at tfvars file but intentionally left blank for complying assignment' order that everything going to be done should be by an ansible playbook passed by Jenkins pipeline. 

- To make Pipeline more autonomous (not setting Ansible server's IP in somewhere in the Jenkins) Ansible Controller's ip address will be get by ansible's aws dynamic inventory plugin that installed on Jenkins server. For this purpose, pipeline will be need AWS credentials as "Username/Password" type Jenkins credential with aws_access_key_id set "username" and "aws_secret_access_key" set password, and the "Treat username as secret" is checked (optional) at Jenkins credential creation window. This credential will be used as temporary environment variable when they are needed. 