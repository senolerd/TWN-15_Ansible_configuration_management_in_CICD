# Provision an EC2 host with Terraform and deploy a private image with Ansible + Podman

Terraform builds the AWS network and an EC2 instance, then hands off to Ansible
(via a `local-exec` provisioner) to install Podman and run a private OCI image
inside a Podman pod on the new host.

This is the Terraform-driven sequel to the plain-Ansible
[`20-podman-over-ec2`](../20-podman-over-ec2) project: same playbook idea, but the
host is now created and wired up as code, and the inventory is discovered
dynamically instead of being hand-written.

## Layout

| File                                   | Purpose                                                                        |
| -------------------------------------- | ---------------------------------------------------------------------------- |
| `providers.tf`                         | Provider requirements (`aws`, `http`, `ansible`); commented S3 backend stub. |
| `variables.tf` / `terraform.tfvars`    | Input variables and their values.                                            |
| `10-main.tf`                           | Calls the `vpc` module.                                                       |
| `20-podman.tf`                         | Ubuntu AMI lookup, the EC2 instance, and the Ansible `local-exec` hand-off. |
| `outputs.tf`                           | `podman_app_address` — the app URL on the new host.                          |
| `modules/vpc/`                         | VPC, public/private subnets, IGW + route table, security group and rules.   |
| `ansible/java-maven-on-ec2-podman.yaml`| Playbook — install Podman, registry login, create pod, run container.       |
| `ansible/podman_servers.aws_ec2.yml`   | `amazon.aws.aws_ec2` dynamic inventory (groups keyed from instance tags).   |
| `ansible/ansible.cfg`                  | Local Ansible defaults (`host_key_checking` disabled).                        |

## What it does

1. **Network** (`modules/vpc`) — a VPC with a public and a private subnet, an
   internet gateway and route table for the public subnet, and one security
   group:
   - egress: allow all;
   - ingress: one rule per entry in `allowed_ports` (only `pod` / port `3000` is
     active by default; `http`, `https`, `ssh` entries are left commented in
     `terraform.tfvars`);
   - ingress: SSH (22) opened automatically to the Terraform runner's own public
     IPv4, looked up at plan time via `https://ipv4.icanhazip.com`, so Ansible
     can reach the host.
2. **Compute** (`20-podman.tf`) — the most recent Canonical Ubuntu 22.04 (Jammy)
   AMI, launched in the public subnet with `key_name = var.keypair_name` and
   tagged `AnsibleGroup = podman-server`.
3. **Configuration hand-off** — a `local-exec` provisioner runs
   `ansible-playbook` from the `ansible/` directory against the AWS EC2 dynamic
   inventory. The playbook targets `tag_AnsibleGroup_podman_server` (the group
   the inventory plugin derives from the `ansible_group` tag) and:
   - updates packages and installs `podman`;
   - logs in to the registry as `oci_registry_user` using `OCI_REG_TOKEN` as the
     password;
   - runs `loginctl enable-linger`;
   - creates a pod publishing `host_port` → `container_port`;
   - runs the container from
     `{{ oci_registry }}/{{ oci_registry_user }}/{{ oci_repo }}` inside the pod.
4. **Output** — `podman_app_address = http://<public_ip>:<host_port>`.

## Requirements

- **Terraform** and **AWS credentials** (see notes below).
- **`ansible-playbook`** on the same machine that runs Terraform, with:
  - `amazon.aws` collection + `boto3`/`botocore` — for the `aws_ec2` dynamic
    inventory;
  - `containers.podman` collection — for the playbook tasks
    (`ansible-galaxy collection install amazon.aws containers.podman`).
- An existing **AWS key pair** named `keypair_name`, with its private key file at
  `keypair_pem` on the runner — Ansible uses it to SSH in.
- **`OCI_REG_TOKEN`** exported on the runner (see notes below).

## Configuration

Set in `terraform.tfvars`:

| Variable            | Meaning                                                    | Example                                     |
| ------------------- | --------------------------------------------------------- | ------------------------------------------- |
| `project_name`      | Name prefix / tag for all resources                       | `my-project`                                |
| `region`            | AWS region for module resources                           | `us-east-1`                                 |
| `vpc_cidr`          | VPC CIDR block                                            | `10.10.0.0/16`                              |
| `subnets`           | Map of `public` / `private` subnets (`cidr`, `az`)        | see file                                    |
| `instance_type`     | EC2 instance type                                         | `t3.micro`                                  |
| `keypair_name`      | Existing AWS key pair; its private key is used by Ansible | `devops-key`                                |
| `keypair_pem`       | Path to that key pair's `.pem` on the runner             | `~/Downloads/devops-key.pem`               |
| `remote_user`       | SSH user for the AMI                                      | `ubuntu`                                    |
| `oci_registry`      | Registry host                                             | `docker.io`                                 |
| `oci_registry_user` | Registry account / namespace                              | `alkol`                                     |
| `oci_repo`          | Repository and tag                                        | `java-maven-app:1.1.0-SNAPSHOT-832e0be-b81` |
| `pod_name`          | Name of the Podman pod                                    | `myproject`                                 |
| `host_port`         | Port published on the EC2 host                            | `3000`                                      |
| `container_port`    | Port the app listens on inside the container             | `8080`                                      |
| `allowed_ports`     | Map of ingress rules (`cidr`, `port`, `protocol`, desc)   | see file                                    |

The S3 backend in `providers.tf` is commented out. To use it, uncomment the
block and pass `-backend-config` for `bucket`, `key` and `region` at
`terraform init`.

## Usage

```bash
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
export OCI_REG_TOKEN=<registry-token>

terraform init
terraform apply

# then open the printed URL
terraform output podman_app_address
```

`terraform destroy` tears the host and network back down.

## Notes

- **AWS credentials.** `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` must be
  exported in the shell before running Terraform.

  ```bash
  export AWS_ACCESS_KEY_ID=AKIA37...
  export AWS_SECRET_ACCESS_KEY=m4xmsWWhc...
  ```

- **Registry token.** `OCI_REG_TOKEN` must be set on the Terraform runner's
  shell — a Docker PAT (`DOCKER_PAT`) or any other token that works as a
  registry password. The Ansible playbook reads it via `lookup('env', ...)` and
  uses it as the `podman_login` password.

- **Ansible inside Terraform is deliberate here.** In decoupled production
  systems, industry best practice discourages running configuration management
  directly from the infrastructure tool. This IaC does it anyway, on purpose, as
  an assignment-driven experiment.
