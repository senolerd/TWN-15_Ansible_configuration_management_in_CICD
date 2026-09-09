output "podman_app_address" {
  value = "http://${aws_instance.podman_server.public_ip}:${var.host_port}"
}
