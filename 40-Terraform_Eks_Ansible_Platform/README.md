This is unfinished work of snap/ephemeral full cluster and development platform workflow. At the destroying part having problem
with gateway's ALB and its Security Group removal automation. Will be look at later. 



Creating EKS with terraform then deploying a Java Maven application over K8s with LoadBalancer

# AWS credential should be set before running this terraform
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=m4xms...


- There are two custom terraform modules will be used written by me.
- Addressing what is different between "dev" and "prod" environment

python3 -m venv .venv
required packages are freezed to requirements.txt file
interpreter_python = "../.venv/bin/python3.9" at local_exec



ansible helm module asks Helm's version 3. Helm module using system's helm binary cli. Terraform runner machine should have Helm v3

