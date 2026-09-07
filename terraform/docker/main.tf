terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "docker_network" "default" {
  name = "${var.project_name}-default"
}

resource "docker_network" "aquila" {
  count = local.runtime_enabled ? 1 : 0
  name  = "${var.project_name}-aquila"
}

resource "docker_volume" "generated_configs" {
  name = "${var.project_name}-generated-configs"
}

resource "docker_volume" "postgres_data" {
  count = local.ide_enabled ? 1 : 0
  name  = "${var.project_name}-postgres-data"
}
