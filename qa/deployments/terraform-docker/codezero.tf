module "codezero" {
  source = "../../../terraform/docker"

  image_registry = var.IMAGE_REGISTRY
  image_tag = var.IMAGE_TAG
  image_edition = var.IMAGE_EDITION

  initial_root_mail = "root@code0.tech"
  initial_root_password = "root"

  enabled_profiles = ["ide", "runtime"]

  aquila_actions = {
    rest = {
      identifier = "rest"
      token      = module.rest_action.action_token
    }
    cron = {
      identifier = "cron"
      token      = module.cron_action.action_token
    }
  }
}
