resource "docker_image" "config_generator" {
  name = "${var.image_registry}/config-generator:${var.image_tag}"
}

resource "docker_container" "config_generator" {
  name  = "${var.project_name}-config-generator"
  image = docker_image.config_generator.image_id

  networks_advanced {
    name = docker_network.default.name
  }

  volumes {
    volume_name    = docker_volume.generated_configs.name
    container_path = "/generated-configs"
  }

  env = local.config_generator_env

  restart = "no"
}
