# Deploy a private container image on EC2 with Podman

Ansible playbook that pulls a private OCI image from a container registry and runs
it inside a Podman pod on a remote EC2 host.

## Layout

| File             | Purpose                                                      |
|------------------|-------------------------------------------------------------|
| `ansible.yaml`   | The playbook (install Podman, registry login, pod, container)|
| `variables.yaml` | Registry, image and networking variables                     |
| `hosts`          | Inventory — the target EC2 instance                          |
| `ansible.cfg`    | Local Ansible defaults (`host_key_checking` disabled)        |

## Requirements

- Ansible with the `containers.podman` collection:
  ```bash
  ansible-galaxy collection install containers.podman
  ```
- SSH access to the EC2 host. The inventory expects the key at
  `~/Downloads/devops-key.pem` and user `ubuntu`.
- The `OCI_REG_TOKEN` environment variable set on the machine that runs the
  playbook — it is used as the registry login password.

## Configuration

Edit `hosts` with your instance IP, SSH user and key path.

Edit `variables.yaml`:

| Variable            | Meaning                                        | Example                                    |
|---------------------|------------------------------------------------|--------------------------------------------|
| `oci_registry`      | Registry host                                  | `docker.io`                                |
| `oci_registry_user` | Registry account / namespace                   | `alkol`                                    |
| `oci_repo`          | Repository and tag                             | `java-maven-app:1.1.0-SNAPSHOT-832e0be-b81`|
| `pod_name`          | Name of the Podman pod                         | `myproject`                                |
| `host_port`         | Port published on the EC2 host                 | `3000`                                     |
| `container_port`    | Port the app listens on inside the container   | `8080`                                     |

## Usage

```bash
export OCI_REG_TOKEN=<registry-token>
ansible-playbook -i hosts ansible.yaml
```

## What the playbook does

1. Installs the `podman` package (with `become`).
2. Logs in to the registry using `oci_registry_user` and `OCI_REG_TOKEN`.
3. Manages a pod that publishes `host_port` -> `container_port`.
4. Runs the container from `{{ oci_registry }}/{{ oci_registry_user }}/{{ oci_repo }}`
   inside the pod.