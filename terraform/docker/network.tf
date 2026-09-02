resource "docker_network" "default" {
  name = "${var.project_name}-default"
}

resource "docker_network" "aquila" {
  name = "${var.project_name}-aquila"
}

resource "docker_volume" "generated_configs" {
  name = "${var.project_name}-generated-configs"
}

resource "docker_volume" "postgres_data" {
  name = "${var.project_name}-postgres-data"
}
