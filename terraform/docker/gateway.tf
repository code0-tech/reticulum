resource "docker_image" "sagittarius_gateway" {
  name = "${var.image_registry}/sagittarius-gateway:${var.image_tag}"
}

resource "docker_container" "sagittarius_gateway" {
  name  = "${var.project_name}-sagittarius-gateway"
  image = docker_image.sagittarius_gateway.image_id

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
