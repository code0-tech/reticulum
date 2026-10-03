data "docker_registry_image" "aquila" {
  count = local.runtime_enabled ? 1 : 0
  name  = "${var.image_registry}/aquila:${var.image_tag}"
}

resource "docker_image" "aquila" {
  count         = local.runtime_enabled ? 1 : 0
  name          = data.docker_registry_image.aquila[0].name
  pull_triggers = [data.docker_registry_image.aquila[0].sha256_digest]
}

resource "docker_container" "aquila" {
  count = local.runtime_enabled ? 1 : 0

  name  = "${var.project_name}-aquila"
  image = docker_image.aquila[0].image_id

  depends_on = [
    docker_container.config_generator,
    docker_container.nats,
  ]

  networks_advanced {
    name = docker_network.default.name
  }

  networks_advanced {
    name = docker_network.aquila[0].name
  }

  env = [
    "AQUILA_CONFIG_PATH=/tmp/generated-configs/aquila.aquila.yml",
    "AQUILA_SERVICE_CONFIG_PATH=/tmp/generated-configs/aquila.service.configuration.json",
  ]

  volumes {
    volume_name    = docker_volume.generated_configs.name
    container_path = "/tmp/generated-configs"
    read_only      = true
  }

  restart = "unless-stopped"
}
