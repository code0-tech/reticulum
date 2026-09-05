data "docker_registry_image" "nats" {
  count = local.runtime_enabled ? 1 : 0
  name  = "nats:2.14.4"
}

resource "docker_image" "nats" {
  count         = local.runtime_enabled ? 1 : 0
  name          = data.docker_registry_image.nats[0].name
  pull_triggers = [data.docker_registry_image.nats[0].sha256_digest]
}

resource "docker_container" "nats" {
  count   = local.runtime_enabled ? 1 : 0
  name    = "${var.project_name}-nats"
  image   = docker_image.nats[0].image_id
  command = ["-js"]

  networks_advanced {
    name = docker_network.default.name
  }

  restart = "unless-stopped"
}

