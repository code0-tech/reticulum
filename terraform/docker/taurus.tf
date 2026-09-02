resource "docker_image" "taurus" {
  name = "${var.image_registry}/taurus:${var.image_tag}"
}

resource "docker_container" "taurus" {
  name  = "${var.project_name}-taurus"
  image = docker_image.taurus.image_id

  depends_on = [
    docker_container.nats,
    docker_container.aquila,
  ]

  networks_advanced {
    name = docker_network.default.name
  }

  env = [
    "MODE=dynamic",
    "AQUILA_URL=http://${docker_container.aquila.name}:8081",
    "NATS_URL=nats://${docker_container.nats.name}:4222",
    "AQUILA_TOKEN=${random_password.taurus_aquila_token.result}",
    "AQUILA_GRPC_CONNECT_TIMEOUT_SECS=${var.aquila_grpc_connect_timeout_secs}",
    "AQUILA_GRPC_REQUEST_TIMEOUT_SECS=${var.aquila_grpc_request_timeout_secs}",
    "ENVIRONMENT=DEVELOPMENT"
  ]

  restart = "unless-stopped"
}
