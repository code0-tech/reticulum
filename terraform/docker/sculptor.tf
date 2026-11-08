data "docker_registry_image" "sculptor" {
  count = local.ide_enabled ? 1 : 0
  name  = "${var.image_registry}/sculptor:${var.image_tag}-${var.image_edition}"
}

resource "docker_image" "sculptor" {
  count         = local.ide_enabled ? 1 : 0
  name          = data.docker_registry_image.sculptor[0].name
  pull_triggers = [data.docker_registry_image.sculptor[0].sha256_digest]
}

resource "docker_container" "sculptor" {
  count = local.ide_enabled ? 1 : 0

  name  = "${var.project_name}-sculptor"
  image = docker_image.sculptor[0].image_id

  networks_advanced {
    name = docker_network.default.name
  }

  env = concat([
    "OPENTELEMETRY_ENABLED=${var.opentelemetry.enabled}",
    "OTEL_SERVICE_NAME=${var.opentelemetry.service_names.sculptor}",
    "OTEL_LOGS_ENDPOINT=${var.opentelemetry.logs_http_endpoint}",
    "OTEL_METRICS_ENDPOINT=${var.opentelemetry.metrics_http_endpoint}",
    "OTEL_TRACES_ENDPOINT=${var.opentelemetry.traces_http_endpoint}",
    "NEXT_PUBLIC_OTEL_SERVICE_NAME=${var.opentelemetry.service_names.sculptor_clientside}",
    "NEXT_PUBLIC_OTEL_LOGS_ENDPOINT=${var.opentelemetry.logs_clientside_http_endpoint}",
    "NEXT_PUBLIC_OTEL_METRICS_ENDPOINT=${var.opentelemetry.metrics_clientside_http_endpoint}",
    "NEXT_PUBLIC_OTEL_TRACES_ENDPOINT=${var.opentelemetry.traces_clientside_http_endpoint}",
  ], var.sculptor_env)

  entrypoint = [
    "sh", "-c",
    <<-EOT
      if [ "$OPENTELEMETRY_ENABLED" != 'true' ]; then
        echo 'UNSET OTEL'
        unset OTEL_SERVICE_NAME OTEL_LOGS_ENDPOINT OTEL_METRICS_ENDPOINT OTEL_TRACES_ENDPOINT
        unset NEXT_PUBLIC_OTEL_SERVICE_NAME NEXT_PUBLIC_OTEL_LOGS_ENDPOINT NEXT_PUBLIC_OTEL_METRICS_ENDPOINT NEXT_PUBLIC_OTEL_TRACES_ENDPOINT
      fi
      exec npm run start
    EOT
  ]

  restart = "unless-stopped"
}
