resource "docker_image" "postgres" {
  name = "postgres:18.3"
}

resource "docker_container" "postgres" {
  name  = "${var.project_name}-postgres"
  image = docker_image.postgres.image_id

  networks_advanced {
    name = docker_network.default.name
  }

  env = [
    "POSTGRES_DB=${var.postgres_db}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${random_password.postgres_password.result}",
  ]

  volumes {
    volume_name    = docker_volume.postgres_data.name
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
