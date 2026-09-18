output "jenkins_ui_address" {
  value = "http://${aws_instance.jenkins.public_dns}:8080"
}

output "jenkins_public_public_dns" {
  value = aws_instance.jenkins.public_dns
}

# output "ansible_public_public_dns" {
#   value = aws_instance.ansible-controller.public_dns
# }


# Output variables what will be pulled by Ansible
output "jenkins_apt_pkcs" { value = var.jenkins_apt_pkcs }
output "ansible_ctl_apt_pkcs" { value = var.ansible_ctl_apt_pkcs }
output "jenkins_plugins" {value = var.jenkins_plugins }

