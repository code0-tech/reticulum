data "docker_registry_image" "sagittarius_gateway" {
  count = local.ide_enabled ? 1 : 0
  name  = "${var.image_registry}/sagittarius-gateway:${var.image_tag}"
}

resource "docker_image" "sagittarius_gateway" {
  count         = local.ide_enabled ? 1 : 0
  name          = data.docker_registry_image.sagittarius_gateway[0].name
  pull_triggers = [data.docker_registry_image.sagittarius_gateway[0].sha256_digest]
}

resource "docker_container" "sagittarius_gateway" {
  count = local.ide_enabled ? 1 : 0

  name  = "${var.project_name}-sagittarius-gateway"
  image = docker_image.sagittarius_gateway[0].image_id

  depends_on = [
    docker_container.config_generator,
    docker_container.sagittarius_grpc,
  ]

  networks_advanced {
    name = docker_network.default.name
  }

  env = [
    "GATEWAY_CONFIG_PATH=/tmp/generated-configs/sagittarius-gateway.gateway.yml",
  ]

  volumes {
    volume_name    = docker_volume.generated_configs.name
    container_path = "/tmp/generated-configs"
    read_only      = true
  }

  restart = "unless-stopped"
}
