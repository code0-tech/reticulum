data "docker_registry_image" "rest_action" {
  name = "ghcr.io/code0-tech/centaurus/ci-builds/rest-action:${var.ACTION_IMAGE_TAG}"
}

module "rest_action" {
  source = "./action"

  identifier = "rest"
  aquila_url = "codezero-aquila:8081"
  image = {
    name          = data.docker_registry_image.rest_action.name
    sha256_digest = data.docker_registry_image.rest_action.sha256_digest
  }

  docker_networks = [
    module.codezero.aquila_network.name,
  ]
}

data "docker_registry_image" "cron_action" {
  name = "ghcr.io/code0-tech/centaurus/ci-builds/cron-action:${var.ACTION_IMAGE_TAG}"
}

module "cron_action" {
  source = "./action"

  identifier = "cron"
  aquila_url = "codezero-aquila:8081"
  image = {
    name          = data.docker_registry_image.cron_action.name
    sha256_digest = data.docker_registry_image.cron_action.sha256_digest
  }

  docker_networks = [
    module.codezero.aquila_network.name,
  ]
}
