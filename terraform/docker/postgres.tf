data "docker_registry_image" "postgres" {
  count = local.ide_enabled ? 1 : 0
  name  = "postgres:18.3"
}

resource "docker_image" "postgres" {
  count         = local.ide_enabled ? 1 : 0
  name          = data.docker_registry_image.postgres[0].name
  pull_triggers = [data.docker_registry_image.postgres[0].sha256_digest]
}

resource "docker_container" "postgres" {
  count = local.ide_enabled ? 1 : 0

  name  = "${var.project_name}-postgres"
  image = docker_image.postgres[0].image_id

  networks_advanced {
    name = docker_network.default.name
  }

  env = [
    "POSTGRES_DB=${var.postgres_db}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${random_password.postgres_password.result}",
  ]

  volumes {
    volume_name    = docker_volume.postgres_data[0].name
    container_path = "/var/lib/postgresql"
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.postgres_user} -d ${var.postgres_db}"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }

  restart = "unless-stopped"
}
