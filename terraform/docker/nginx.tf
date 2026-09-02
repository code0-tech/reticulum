resource "docker_image" "nginx" {
  name = "nginx:1.31.3-alpine-otel"
}

resource "docker_container" "nginx" {
  name  = "${var.project_name}-nginx"
  image = docker_image.nginx.image_id

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

  volumes {
    volume_name    = docker_volume.generated_configs.name
    container_path = "/tmp/generated-configs"
    read_only      = true
  }
 
  dynamic "upload" {
    for_each = var.tls_key != null ? [var.tls_key] : []
    content {
      file    =  "/etc/nginx/certs/tls.key"
      content = upload.value
    }
  }
  dynamic "upload" {
    for_each = var.tls_cert != null ? [var.tls_cert] : []
    content {
      file    =  "/etc/nginx/certs/tls.crt"
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

  ports {
    internal = 80
    external = var.http_port
  }

  ports {
    internal = 443
    external = var.https_port
  }

  restart = "unless-stopped"
}
