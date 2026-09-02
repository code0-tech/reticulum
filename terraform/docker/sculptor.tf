resource "docker_image" "sculptor" {
  name = "${var.image_registry}/sculptor:${var.image_tag}-${var.image_edition}"
}

resource "docker_container" "sculptor" {
  name  = "${var.project_name}-sculptor"
  image = docker_image.sculptor.image_id

  networks_advanced {
    name = docker_network.default.name
  }

  env = [
    "OPENTELEMETRY_ENABLED=${var.opentelemetry_enabled}",
    "OTEL_SERVICE_NAME=${var.otel_service_name_sculptor}",
    "OTEL_LOGS_ENDPOINT=${var.otel_logs_http_endpoint}",
    "OTEL_METRICS_ENDPOINT=${var.otel_metrics_http_endpoint}",
    "OTEL_TRACES_ENDPOINT=${var.otel_traces_http_endpoint}",
    "NEXT_PUBLIC_OTEL_SERVICE_NAME=${var.otel_service_name_sculptor_clientside}",
    "NEXT_PUBLIC_OTEL_LOGS_ENDPOINT=${var.otel_logs_clientside_http_endpoint}",
    "NEXT_PUBLIC_OTEL_METRICS_ENDPOINT=${var.otel_metrics_clientside_http_endpoint}",
    "NEXT_PUBLIC_OTEL_TRACES_ENDPOINT=${var.otel_traces_clientside_http_endpoint}",
  ]

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
