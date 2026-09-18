# 50 — Ansible Integration in Jenkins

**TWN-15 Bootcamp assignment / portfolio demo project**

A CI pipeline where **Jenkins never touches the target servers directly**. Instead, Jenkins hands the configuration-management job off to a dedicated **Ansible Control Node**, which resolves its targets at run time through an **AWS EC2 dynamic inventory** — no server IP is ever hardcoded anywhere in the pipeline or repo.

> Technologies: AWS (EC2, VPC), Terraform, Ansible, Jenkins, Groovy, Python3/Boto3, Podman, Ubuntu 22.04, Git/GitHub

---

## 1. Concept

The project is split into two layers, on purpose:

| Layer | Tool | Responsibility |
|---|---|---|
| **Underlay** | Terraform (`_terraform-IaC/`, optional) | One-shot provisioning of the VPC, the 3 EC2 roles, security groups, and initial software bootstrap. Not part of the graded assignment — it just saves me from clicking through the AWS console every time I want a clean environment. |
| **Overlay** | Jenkins + Ansible (`Jenkinsfile`, `utils.groovy`, `ansible/`) | The actual assignment: a running Jenkins instance picks up this repo, ships an Ansible playbook to the Control Node, and has *it* configure the workstation fleet. |

Because the two layers are decoupled, the overlay pipeline works the same way whether the three servers were hand-built following §3 below, or spun up in one `terraform apply`.

---

## 2. Architecture

```
                                     GitHub repo
                                           │
                                           │ (webhook: push → build, optional)
                                           ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │ JENKINS EC2                             tag: AnsibleGroup=jenkins_controller │
   │ SG: 22+8080 from "my IP", 8080 from GitHub webhook CIDRs                     │
   │                                                                              │
   │  Jenkinsfile (utils.groovy)                                                  │
   │   1. __init__                — resolve Ansible Ctrl's private IP             │
   │   2. Preparing Ctrl Node     — rsync playbooks + ssh key over                │
   │   3. Running playbook        — ssh in, trigger ansible-playbook              │
   └──────────────────────────────────────────────────────────────────────────────┘
                                           │ ssh / rsync  (credential: devops_ssh_priv)
                                           │ IP resolved via `ansible-inventory --host`
                                           ▼
   ┌──────────────────────────────────────────────────────────────────────────────┐
   │ ANSIBLE CONTROLLER EC2                  tag: AnsibleGroup=ansible_controller │
   │ SG: 22 only from Jenkins SG (by reference, not by IP)                        │
   │                                                                              │
   │  receives: ansible/{ansible.cfg, dyn-hosts.aws_ec2.yaml,                     │
   │            deploy-on-workstations.yaml} + devops_ssh_priv_key                │
   │  runs: ansible-playbook -i dyn-hosts.aws_ec2.yaml                            │
   │          deploy-on-workstations.yaml                                         │
   │  (AWS creds passed in only as scoped env vars, for the                       │
   │   aws_ec2 dynamic-inventory plugin to resolve workstation IPs)               │
   └──────────────────────────────────────────────────────────────────────────────┘
                                           │ ssh  (devops-key)
                                           │ targets discovered dynamically, not hardcoded
                  ┌────────────────────────┴──────────┐
                  ▼                                   ▼
   ┌─────────────────────────────┐     ┌─────────────────────────────┐
   │ WORKSTATION EC2 #0          │     │ WORKSTATION EC2 #1          │  tag: AnsibleGroup=workstation
   │ SG: 22 only from            │     │ SG: 22 only from            │  SG: 80/443/8080 public
   │  Ansible Ctrl SG,           │     │  Ansible Ctrl SG,           │
   │  apps public on 80/443/8080 │     │  apps public on 80/443/8080 │
   │  → Podman installed         │     │  → Podman installed         │
   └─────────────────────────────┘     └─────────────────────────────┘
```

Every SG-to-SG rule above is expressed as `referenced_security_group_id`, not as a CIDR/IP — so the whole chain keeps working even if instances are stopped/started and get new addresses.

---

## 3. Repository layout

```
50-Ansible_integration_in_Jenkins/
├── Jenkinsfile                     # 3-stage overlay pipeline (loads utils.groovy)
├── utils.groovy                    # shared-lib style helper: getAnsibleServerIp(),
│                                    #   copyConfigsToAnsibleController(), runAnsiblePlaybook()
├── ansible/                         # <-- what actually gets shipped to the Control Node
│   ├── ansible.cfg                  #   points at the dynamic inventory + the shipped private key
│   ├── dyn-hosts.aws_ec2.yaml       #   amazon.aws.aws_ec2 dynamic inventory, grouped by AnsibleGroup tag
│   └── deploy-on-workstations.yaml  #   the graded playbook: waits for SSH, installs Podman
└── _terraform-IaC/                  # optional underlay, not graded
    ├── 10-infra.tf                  #   VPC, subnets (4 AZs), IGW/route table, GitHub-IP/my-IP lookups
    ├── 20-ec2_jenkins.tf            #   Jenkins EC2 + SG (my IP + GitHub webhook ranges)
    ├── 30-ec2_ansible_controller.tf #   Ansible EC2 + SG (SSH only from Jenkins SG)
    ├── 40-ec2_workstations.tf       #   2x workstation EC2 + SG (SSH only from Ansible SG)
    ├── providers.tf / variables.tf / terraform.tfvars / output.tf
    └── ansible/                      #   bootstrap playbooks Terraform runs via local-exec
        ├── 10-jenkins-bootstrap.yaml    #   installs apt pkgs, downloads jenkins.war, systemd unit,
        │                                #   grabs initial admin password, installs plugins
        ├── 20-ansible-ctr-bootstrap.yaml#   installs apt pkgs (ansible, python3-boto3)
        ├── 30-workstations-bootstrap.yaml
        ├── ansible.cfg / dynamic.aws_ec2.yaml
        └── jenkins_svc_unit.j2          #   systemd --user unit template for `java -jar jenkins.war`
```

---

## 4. Manual infrastructure requirements (the graded part)

If you skip Terraform entirely, this is what needs to exist by hand before the pipeline can run:

### AWS side
- An EC2 key pair named `devops-key`, imported from a "Terraform runner"-owned private key.
- An IAM user with an access key pair and enough permissions to describe/create EC2 resources.
- Both are referenced from Jenkins as credentials (see §6).

### Jenkins Server
- Ubuntu EC2, SG allows `22` + `8080` from *your* IP and from GitHub's webhook IPv4/IPv6 ranges.
- Packages: `openjdk-25-jre`, `ansible`, `python3-boto3`.
- Jenkins itself (WAR + systemd unit, built by hand or via the bootstrap playbook below).
- Plugins: `ssh-agent`, `ssh-steps`.

### Ansible Controller
- Ubuntu EC2, SG allows `22` **only** from the Jenkins SG.
- Tag `AnsibleGroup=ansible_controller` — required for the dynamic inventory plugin to find it.
- Packages: `ansible`, `python3-boto3`.

### Workstations
- Ubuntu EC2(s), SG allows `22` **only** from the Ansible Controller SG, plus app ports (80/443/8080) open to the world.
- Tag `AnsibleGroup=workstation` — same reason.

All three roles share the `devops-key` EC2 key pair under the `ubuntu` user.

---

## 5. Optional Terraform underlay

`_terraform-IaC/` is a convenience layer I built to avoid manually re-creating the above every time — **it is not part of the assignment**.

What it does:
1. Creates a VPC with 4 AZs × {public, private} subnets, an IGW, and a public route table.
2. Looks up your current public IP (`api.ipify.org`) and GitHub's webhook CIDR ranges (`api.github.com/meta`) at plan time, and uses them directly in the Jenkins SG ingress rules.
3. Creates the Jenkins, Ansible Controller, and 2× Workstation instances with the SGs/tags described above.
4. Runs one `local-exec` Ansible bootstrap playbook per instance right after creation (`10-jenkins-bootstrap.yaml`, `20-ansible-ctr-bootstrap.yaml`, `30-workstations-bootstrap.yaml`), which:
   - waits for SSH, installs the apt packages Terraform passes it via `terraform output -json`,
   - on Jenkins: downloads `jenkins.war`, deploys it as a `systemd --user` service (via `jenkins_svc_unit.j2`), waits for the initial-admin-password file, copies it out to `JENKINS_INITIAL_ADMIN_KEY_DELETE_ME_LATER.txt` (gitignored — delete it once you've logged in and set up real credentials), then installs the requested plugins and restarts the service.
5. Outputs the Jenkins URL (`http://<public-dns>:8080`).

```bash
cd _terraform-IaC
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
terraform init
terraform apply
```

Note: the Ansible Controller's IP is deliberately **not** an output consumed by the pipeline — the whole point of the dynamic inventory is that Jenkins looks it up itself at run time (see §6).

---

## 6. Jenkins pipeline (the overlay, graded part)

`Jenkinsfile` runs three stages, delegating the actual work to `utils.groovy`:

1. **`__init__`** — `getAnsibleServerIp()` resolves the Control Node's *private* IP with:
   ```bash
   ansible-inventory -i ansible/dyn-hosts.aws_ec2.yaml --host AnsibleGroup_ansible_controller \
     | python3 -c "import sys,json; print(json.load(sys.stdin)['private_ip_address'])"
   ```
   using AWS creds injected only for this step, and stores it as `env.ANSIBLE_SERVER`. No IP is ever committed to the repo.

2. **`Preparing Ansible Controller`** — `copyConfigsToAnsibleController()` opens an `sshagent` session with the `devops_ssh_priv` key and:
   - sanity-pings the Control Node over SSH,
   - `rsync`s the private key itself over (so the Control Node can later SSH into the workstations),
   - `rsync`s the whole `ansible/` directory over.

3. **`Running playbook for Workstations`** — `runAnsiblePlaybook()` SSHes into the Control Node and runs:
   ```bash
   ANSIBLE_CONFIG=ansible/ansible.cfg \
   ansible-playbook -i ansible/dyn-hosts.aws_ec2.yaml ansible/deploy-on-workstations.yaml
   ```
   with the AWS access key/secret passed as env vars scoped to that single SSH command — needed by the `amazon.aws.aws_ec2` inventory plugin on the *Control Node* to resolve the workstation IPs.

The playbook itself (`deploy-on-workstations.yaml`) is intentionally short — it waits for SSH and installs **Podman** — since the goal of the assignment is proving the Jenkins→Ansible hand-off works, not the payload.

### Required Jenkins credentials

| Credential ID | Kind | Value |
|---|---|---|
| `aws_acc_key_and_sec` | Username with password | Username = IAM `aws_access_key_id`, Password = `aws_secret_access_key` |
| `devops_ssh_priv` | SSH Username with private key | Private key half of the `devops-key` EC2 key pair |

### Required Jenkins plugins

`ssh-agent`, `ssh-steps` (plus whatever `git`/pipeline plugins ship by default).

---

## 7. Design notes / why it's built this way

- **Dynamic inventory over static IPs**, both for Jenkins→Ansible Controller and Controller→Workstations, so the pipeline survives instance restarts/replacements without a single config edit. This is the whole point of the exercise, not an implementation detail.
- **SG-to-SG references** (`referenced_security_group_id`) instead of `/32` CIDRs for controller↔workstation and jenkins↔controller traffic — same reasoning, one layer down.
- **Credentials scoped per step** in `utils.groovy` (`withCredentials` blocks around single `sh`/`ssh` calls) rather than exported globally for the whole pipeline run.
- **Podman, not Docker**, on the workstations — rootless-by-default fits an assignment where the workstation's only inbound trust is the Ansible Controller.
- The Terraform bootstrap deliberately keeps a commented-out Podman/container-based alternative for running Jenkins itself (see the bottom of `10-jenkins-bootstrap.yaml`) — left in as a note-to-self for a future iteration, not dead code to be proud of.
