data "docker_registry_image" "velorum" {
  count = local.velorum_enabled ? 1 : 0
  name  = "${var.image_registry}/velorum:${var.image_tag}-${var.image_edition}"
}

resource "docker_image" "velorum" {
  count         = local.velorum_enabled ? 1 : 0
  name          = data.docker_registry_image.velorum[0].name
  pull_triggers = [data.docker_registry_image.velorum[0].sha256_digest]
}

resource "docker_container" "velorum" {
  count = local.velorum_enabled ? 1 : 0

  name  = "${var.project_name}-velorum"
  image = docker_image.velorum[0].image_id

  depends_on = [docker_container.config_generator]

  networks_advanced {
    name = docker_network.default.name
  }

  env = [
    "SECURITY_TOKEN=${random_password.velorum_jwt_secret.result}",
  ]

  upload {
    file    = "/velorum/few_shots_external.configuration.json"
    content = var.few_shots_external_config_path
  }

  volumes {
    volume_name    = docker_volume.generated_configs.name
    container_path = "/tmp/generated-configs"
    read_only      = true
  }

  entrypoint = [
    "sh", "-c",
    <<-EOT
      cp /tmp/generated-configs/velorum.models.configuration.json models.configuration.json
      exec uv run main.py
    EOT
  ]

  restart = "unless-stopped"
}
