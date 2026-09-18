# TWN-15 — Ansible Configuration Management in CI/CD

TechWorld with Nana bootcamp assignment (TWN-15), split into progressive
sub-projects that build on each other: starting from a plain Ansible
playbook, through Terraform-provisioned infrastructure, up to a full
Jenkins → Ansible CI/CD hand-off.

Each sub-project is self-contained with its own `README.md`, Ansible
playbooks, and (where applicable) Terraform code.

## Sub-projects

| # | Project | Summary |
|---|---------|---------|
| [10](10-Nexus_artifactory_install_tarball) | **Nexus Repository Manager — Tarball Install** | Idempotent Ansible playbook that installs/upgrades Sonatype Nexus 3 from the official tarball on a single target host, preserving `sonatype-work` across upgrades. |
| [20](20-Podman_over_EC2) | **Deploy a Private Container Image on EC2 with Podman** | Ansible playbook that installs Podman on a hand-provisioned EC2 host, logs in to a private registry, and runs the app in a Podman pod. |
| [30](30-Terraform_Ansible_EC2_Podman) | **Terraform + Ansible + Podman on EC2** | Terraform-driven sequel to #20: provisions the VPC/EC2 host as code and hands off to the same Podman playbook via a dynamic AWS EC2 inventory and a `local-exec` provisioner. |
| [40](40-Terraform_Eks_Ansible_Platform) | **Terraform EKS + Ansible Platform** *(work in progress)* | Creates an EKS cluster with Terraform and deploys a Java/Maven app over Kubernetes with a LoadBalancer, using Ansible's Helm module. Cluster teardown (ALB/Security Group cleanup) is not yet solved. |
| [50](50-Ansible_integration_in_Jenkins) | **Ansible Integration in Jenkins** | The capstone: a Jenkins pipeline that never touches target servers directly — it hands the job to a dedicated Ansible Control Node, which resolves workstation targets at run time via AWS EC2 dynamic inventory. Includes an optional Terraform underlay to stand up all three EC2 roles (Jenkins, Ansible Controller, workstations). |

## Common threads

- **Ansible** is the configuration-management tool throughout; later
  projects layer **Terraform** (infrastructure) and **Jenkins**
  (CI/CD orchestration) on top.
- Target workloads are run with **Podman**, not Docker.
- From #30 onward, inventories are resolved **dynamically** from AWS EC2
  tags (`amazon.aws.aws_ec2` plugin) instead of hand-written host files —
  each project deliberately removes one more hardcoded piece of the last.

See each sub-project's own `README.md` for requirements, variables, and
usage instructions.
