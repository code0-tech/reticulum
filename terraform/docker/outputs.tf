output "nginx_container_hostname" {
  value = local.ide_enabled ? docker_container.nginx[0].hostname : null
}

output "aquila_network" {
  value = {
    id   = local.runtime_enabled ? docker_network.aquila[0].id : null
    name = local.runtime_enabled ? docker_network.aquila[0].name : null
  }
}
