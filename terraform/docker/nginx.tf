data "docker_registry_image" "nginx" {
  count = local.ide_enabled ? 1 : 0
  name  = "nginx:1.31.3-alpine-otel"
}

resource "docker_image" "nginx" {
  count         = local.ide_enabled ? 1 : 0
  name          = data.docker_registry_image.nginx[0].name
  pull_triggers = [data.docker_registry_image.nginx[0].sha256_digest]
}

resource "docker_container" "nginx" {
  count = local.ide_enabled ? 1 : 0

  name  = "${var.project_name}-nginx"
  image = docker_image.nginx[0].image_id

  env = var.nginx_env

  depends_on = [
    docker_container.config_generator,
    docker_container.sagittarius_rails_web,
    docker_container.sagittarius_rails_cable,
    docker_container.sagittarius_gateway,
    docker_container.sculptor,
  ]

  networks_advanced {
    name = docker_network.default.name
  }

  dynamic "networks_advanced" {
    for_each = var.nginx_additional_network != null ? [var.nginx_additional_network] : []
    content {
      name = networks_advanced.value
    }
  }

  volumes {
    volume_name    = docker_volume.generated_configs.name
    container_path = "/tmp/generated-configs"
    read_only      = true
  }

  dynamic "upload" {
    for_each = var.tls_key != null ? [var.tls_key] : []
    content {
      file    = "/etc/nginx/certs/tls.key"
      content = upload.value
    }
  }
  dynamic "upload" {
    for_each = var.tls_cert != null ? [var.tls_cert] : []
    content {
      file    = "/etc/nginx/certs/tls.crt"
      content = upload.value
    }
  }

  entrypoint = [
    "sh", "-c",
    <<-EOT
      cp /tmp/generated-configs/nginx.default.conf /etc/nginx/conf.d/default.conf
      if [ -s /tmp/generated-configs/nginx.otel.conf ]; then
        sed -i '1i load_module modules/ngx_otel_module.so;' /etc/nginx/nginx.conf
        cp /tmp/generated-configs/nginx.otel.conf /etc/nginx/conf.d/otel.conf
      fi
      nginx -t
      exec nginx -g 'daemon off;'
    EOT
  ]

  dynamic "ports" {
    for_each = var.http_port != null ? [var.http_port] : []
    content {
      internal = 80
      external = ports.value
      ip       = var.nginx_bind_ip
    }
  }

  dynamic "ports" {
    for_each = var.https_port != null ? [var.https_port] : []
    content {
      internal = 443
      external = ports.value
      ip       = var.nginx_bind_ip
    }
  }

  restart = "unless-stopped"
}
