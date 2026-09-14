
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
    
• Personal opinion summary: This assignments purpose, creating ephemeral/custom ansible playbooks, transferring them to Ansible controller to set/change workstations. Multi-layer automation practice. I add another sub-layer with .terraform-IaC to create environment instead of installing environment manually.  



## .terraform-IaC
It is not part of the assignment, just creating the environment. 
### IaC summary;
- Jenkins server: Ubuntu with EC2  "devops-key" EC2 key-pair for "ubuntu" user. "openjdk-25-jre", "ansible", "python3-boto3" apt packages are being installed initially. Has its own EC2 security group with SSH and 80080 allowed from Terraform runner IP. Also "ssh-agent" plugin is being installed but Jenkins needs a restart after setting up (ToDo: Should be fixed).
- Ansible Controller server: Ubuntu with EC2  "devops-key" EC2 key-pair for "ubuntu" user. "ansible", "python3-boto3" apt packages are being installed initially. Has its own EC2 security group with SSH allowed from Terraform runner IP for initial setup and controlling purpose, not overlay assignment workflow.
- Workstation servers: Ubuntu with EC2  "devops-key" EC2 key-pair for "ubuntu" user. They have their own security group and can accept SSH from only Ansible controller and "80", "443", "8080" ports globally. (ToDo: Modify this part after the project done)



- Infra has Terrafrom IaC for creating environment for assignment. The ec2 instances aws EC2 key-pair (named "devops-key") created by $USER's default ssh private key. Jenkins, Ansible Controller, and the two workstations can be connected via ubuntu user and private ssh key as identity credential file.

- Jenkins and Ansible instances accept ssh from Terraform runner IP address. Worker nodes accept SSH only from Ansible controller server. Worker nodes can serve from ["80", "443", "8080"] tcp ports by default IaC setting. IaC is created the way can bootstrap workstations with required packages by "workstation_apt_pkcs" at tfvars file but intentionally left blank for complying assignment' order that everything going to be done should be by an ansible playbook passed by Jenkins pipeline. 

- To make Pipeline more autonomous (not setting Ansible server's IP in somewhere in the Jenkins) Ansible Controller's ip address will be get by ansible's aws dynamic inventory plugin that installed on Jenkins server. For this purpose, pipeline will be need AWS credentials as "Username/Password" type Jenkins credential with aws_access_key_id set "username" and "aws_secret_access_key" set password, and the "Treat username as secret" is checked (optional) at Jenkins credential creation window. This credential will be used as temporary environment variable when they are needed. 