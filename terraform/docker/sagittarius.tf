resource "docker_image" "sagittarius" {
  name = "${var.image_registry}/sagittarius:${var.image_tag}-${var.image_edition}"
}

resource "docker_container" "sagittarius_rails_web" {
  name  = "${var.project_name}-sagittarius-rails-web"
  image = docker_image.sagittarius.image_id

  depends_on = [
    docker_container.config_generator,
    docker_container.postgres,
  ]

  networks_advanced {
    name = docker_network.default.name
  }

  env = [
    "INITIAL_ROOT_PASSWORD=${var.initial_root_password}",
    "INITIAL_ROOT_MAIL=${var.initial_root_mail}",
    "INITIAL_RUNTIME_TOKEN=${random_password.initial_runtime_token.result}",
    "SAGITTARIUS_CONFIG_FILES=${join(",", [
      "/tmp/generated-configs/sagittarius.sagittarius.yml",
      "/tmp/generated-configs/sagittarius.sagittarius-web.yml",
    ])}",
  ]

  volumes {
    volume_name    = docker_volume.generated_configs.name
    container_path = "/tmp/generated-configs"
    read_only      = true
  }

  healthcheck {
    test     = ["CMD-SHELL", "curl --fail http://localhost:3000/health/liveness"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }

  restart = "unless-stopped"
}

resource "docker_container" "sagittarius_rails_background" {
  name  = "${var.project_name}-sagittarius-rails-background"
  image = docker_image.sagittarius.image_id

  depends_on = [
    docker_container.config_generator,
    docker_container.sagittarius_rails_web,
  ]

  networks_advanced {
    name = docker_network.default.name
  }

  env = [
    "SAGITTARIUS_CONFIG_FILES=${join(",", [
      "/tmp/generated-configs/sagittarius.sagittarius.yml",
      "/tmp/generated-configs/sagittarius.sagittarius-background.yml",
    ])}",
  ]

  volumes {
    volume_name    = docker_volume.generated_configs.name
    container_path = "/tmp/generated-configs"
    read_only      = true
  }

  command = ["bundle", "exec", "good_job"]
  restart = "unless-stopped"
}

resource "docker_container" "sagittarius_grpc" {
  name  = "${var.project_name}-sagittarius-grpc"
  image = docker_image.sagittarius.image_id

  depends_on = [
    docker_container.config_generator,
    docker_container.sagittarius_rails_web,
  ]

  networks_advanced {
    name = docker_network.default.name
  }

  env = [
    "SAGITTARIUS_CONFIG_FILES=${join(",", [
      "/tmp/generated-configs/sagittarius.sagittarius.yml",
      "/tmp/generated-configs/sagittarius.sagittarius-grpc.yml",
    ])}",
  ]

  volumes {
    volume_name    = docker_volume.generated_configs.name
    container_path = "/tmp/generated-configs"
    read_only      = true
  }

  command = ["bin/grpc_server"]
  restart = "unless-stopped"
}

resource "docker_container" "sagittarius_rails_cable" {
  name  = "${var.project_name}-sagittarius-rails-cable"
  image = docker_image.sagittarius.image_id

  depends_on = [
    docker_container.config_generator,
    docker_container.sagittarius_rails_web,
  ]

  networks_advanced {
    name = docker_network.default.name
  }

  env = [
    "SAGITTARIUS_CONFIG_FILES=${join(",", [
      "/tmp/generated-configs/sagittarius.sagittarius.yml",
      "/tmp/generated-configs/sagittarius.sagittarius-cable.yml",
    ])}",
  ]

  volumes {
    volume_name    = docker_volume.generated_configs.name
    container_path = "/tmp/generated-configs"
    read_only      = true
  }

  command = ["bundle", "exec", "puma", "config.cable.ru"]
  restart = "unless-stopped"
}
