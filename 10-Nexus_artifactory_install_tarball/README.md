# Nexus Repository Manager — Tarball Install / Upgrade

Ansible playbook that installs (or upgrades) [Sonatype Nexus Repository
Manager 3](https://help.sonatype.com/repomanager3) on a target host from the
official `.tar.gz` distribution.

The playbook is idempotent for upgrades: the `sonatype-work` directory (which
holds artifacts, blob stores, and configuration) is preserved, while the
`nexus-<version>` application directory is replaced with the new release.

## Layout

| File                         | Purpose                                                        |
| ---------------------------- | ------------------------------------------------------------- |
| `nexus-tarball-install.yaml` | The playbook — install/upgrade tasks.                         |
| `variables.yaml`             | User-tunable variables (user, install dir, tarball URL).     |
| `hosts`                      | Inventory — defines the `nexus_server` group.                 |
| `ansible.cfg`                | Local Ansible defaults (`host_key_checking` disabled).       |

## Variables

Set in `variables.yaml`:

| Variable            | Default                                                                        | Description                              |
| ------------------- | ---------------------------------------------------------------------------- | --------------------------------------- |
| `nexus_user`        | `nexus`                                                                       | Service account that owns and runs Nexus. |
| `nexus_dir`         | `/opt/nexus`                                                                  | Install root. Holds `nexus` symlink, `nexus-<version>/`, and `sonatype-work/`. |
| `nexus_tarball_url` | `https://download.sonatype.com/nexus/3/nexus-3.92.2-01-linux-x86_64.tar.gz` | Release to install. Change this and re-run to upgrade. |

## Inventory

`hosts` defines a single target under `[nexus_server]`. Update the address and
connection details for your environment:

```ini
[nexus_server]
192.168.1.222 ansible_ssh_private_key_file=~/.ssh/id_rsa ansible_user=admin
```

## Requirements

- Ansible on the control machine, with the `ansible.posix` collection
  (`ansible-galaxy collection install ansible.posix`) for the `firewalld` and
  `acl` tasks.
- SSH access to the target as a user with `sudo` privileges (tasks use
  `become`).
- A RHEL/CentOS-family target: uses `firewalld` and the `acl` package.
<!-- - A JRE/JDK on the target as required by the chosen Nexus version. -->

## Usage

Install:

```bash
ansible-playbook -i hosts nexus-tarball-install.yaml
```

Upgrade: edit `nexus_tarball_url` in `variables.yaml` to the new release, then
run the same command. The playbook stops the running instance, swaps the
application directory, repoints the `nexus` symlink, and restarts.

On success it prints:

```
Nexus started. To access, use http://<host>:8081
```

## What the playbook does

1. Creates the `nexus` user and home directory.
2. Installs `acl` and opens TCP `8081` in the `firewalld` public zone.
3. Creates `{{ nexus_dir }}` and a temp download dir under `/tmp/{{ nexus_user }}`.
4. Downloads and extracts the tarball.
5. Moves `sonatype-work` into `{{ nexus_dir }}` **only on first install**
   (`creates` guard preserves existing data on upgrades).
6. If an instance is running (detected via `nexus.pid`), stops it and waits for
   the process to exit.
7. Moves the new `nexus-<version>` dir into place and links `{{ nexus_dir }}/nexus` to it.
8. Fixes ownership recursively, starts Nexus as the `nexus` user, and waits for
   port `8081` to come up.

## Notes

- `host_key_checking` is disabled in `ansible.cfg` for convenience — remove this
  for stricter environments.
- The default Nexus port `8081` is assumed throughout (firewall rule and
  readiness check).
