output "nginx_container_hostname" {
  value = local.ide_enabled ? docker_container.nginx[0].hostname : null
}
