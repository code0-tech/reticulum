resource "docker_image" "nats" {
  name = "nats:2.14.4"
}

resource "docker_container" "nats" {
  name    = "${var.project_name}-nats"
  image   = docker_image.nats.image_id
  command = ["-js"]

  networks_advanced {
    name = docker_network.default.name
  }

  restart = "unless-stopped"
}

