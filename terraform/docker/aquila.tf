resource "docker_image" "aquila" {
  name = "${var.image_registry}/aquila:${var.image_tag}"
}

resource "docker_container" "aquila" {
  name  = "${var.project_name}-aquila"
  image = docker_image.aquila.image_id

  depends_on = [
    docker_container.config_generator,
    docker_container.nats,
  ]

  networks_advanced {
    name = docker_network.default.name
  }

  networks_advanced {
    name = docker_network.aquila.name
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
