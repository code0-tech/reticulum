variable "project_name" {
  description = "Prefix used for container, network and volume names (mirrors the compose 'name:' key)."
  type        = string
  default     = "codezero"
}

variable "image_registry" {
  description = "Registry host that application images are pulled from."
  type        = string
}

variable "image_tag" {
  description = "Tag applied to sagittarius/gateway/sculptor/velorum/aquila/taurus images."
  type        = string
}

variable "image_edition" {
  description = "Edition suffix appended to the sagittarius/sculptor image tags (e.g. 'ce', 'ee')."
  type        = string
}

variable "postgres_db" {
  type    = string
  default = "sagittarius_production"
}

variable "postgres_user" {
  type    = string
  default = "sagittarius"
}

variable "initial_root_password" {
  type      = string
  sensitive = true
}

variable "initial_root_mail" {
  type = string
}

variable "aquila_grpc_connect_timeout_secs" {
  type    = string
  default = "5"
}

variable "aquila_grpc_request_timeout_secs" {
  type    = string
  default = "30"
}

variable "hostname" {
  type        = string
  default     = "localhost"
}

variable "http_port" {
  type    = number
  default = 80
}

variable "https_port" {
  type    = number
  default = 443
}

variable "opentelemetry_enabled" {
  type    = bool
  default = false
}

variable "ssl_enabled" {
  type    = bool
  default = false
}

variable "tls_key" {
  description = "Key Value for the nginx (not the path, the real value)"
  type        = string
  default     = null
}

variable "tls_cert" {
  description = "Cert Value for the nginx (not the path, the real value)"
  type        = string
  default     = null
}

variable "enable_velorum" {
  description = "Whether to start the velorum container (compose's 'ide_velorum' profile, off by default)."
  type        = bool
  default     = false
}

variable "few_shots_external_config_path" {
  description = "Absolute host path to velorum.few_shots_external.configuration.json."
  type        = string
  default     = "{}"
}

variable "otel_service_name_sculptor" {
  type    = string
  default = ""
}

variable "otel_logs_http_endpoint" {
  type    = string
  default = ""
}

variable "otel_metrics_http_endpoint" {
  type    = string
  default = ""
}

variable "otel_traces_http_endpoint" {
  type    = string
  default = ""
}

variable "otel_service_name_sculptor_clientside" {
  type    = string
  default = ""
}

variable "otel_logs_clientside_http_endpoint" {
  type    = string
  default = ""
}

variable "otel_metrics_clientside_http_endpoint" {
  type    = string
  default = ""
}

variable "otel_traces_clientside_http_endpoint" {
  type    = string
  default = ""
}

variable "config_generator_env" {
  description = <<-EOT
    Full replacement for compose's `env_file: .env` on the config-generator
    container. List every KEY=value pair it needs to render the generated
    configs (sagittarius.*.yml, aquila.*.yml, nginx.*.conf, etc).
  EOT
  type        = list(string)
  sensitive   = true
  default     = []
}

locals {
  default_config_generator_env = [
    "HOSTNAME=${var.hostname}",
    "HTTP_PORT=${var.http_port}",
    "HTTPS_PORT=${var.https_port}",
    "SSL_ENABLED=${var.ssl_enabled}",
    "SSL_CERT_FILE=",
    "SSL_KEY_FILE=",

    "INITIAL_ROOT_PASSWORD=${var.initial_root_password}",
    "INITIAL_ROOT_MAIL=${var.initial_root_mail}",
    "INITIAL_RUNTIME_TOKEN=${random_password.initial_runtime_token.result}",

    "AQUILA_LOG_LEVEL=info",
    "AQUILA_NATS_URL=nats://${var.project_name}-nats:4222",
    "AQUILA_NATS_BUCKET=flow_store",
    "AQUILA_BACKEND_URL=http://${var.project_name}-nginx:80",
    "AQUILA_BACKEND_TOKEN=${random_password.initial_runtime_token.result}",
    "AQUILA_BACKEND_UNARY_TIMEOUT_SECS=10",
    "AQUILA_GRPC_HOST=0.0.0.0",
    "AQUILA_GRPC_PORT=8081",
    "AQUILA_GRPC_HEALTH_SERVICE=false",

    "TAURUS_AQUILA_TOKEN=${random_password.taurus_aquila_token.result}",

    "AQUILA_GRPC_CONNECT_TIMEOUT_SECS=${var.aquila_grpc_connect_timeout_secs}",
    "AQUILA_GRPC_REQUEST_TIMEOUT_SECS=${var.aquila_grpc_request_timeout_secs}",

    "VELORUM_ENABLED=${var.enable_velorum}",

    "IMAGE_REGISTRY=${var.image_registry}",
    "IMAGE_TAG=${var.image_tag}",
    "IMAGE_EDITION=${var.image_edition}",

    "SAGITTARIUS_DB_ENCRYPTION_PRIMARY_KEY=${random_password.sagittarius_db_encryption_primary_key.result}",
    "SAGITTARIUS_DB_ENCRYPTION_DETERMINISTIC_KEY=${random_password.sagittarius_db_encryption_deterministic_key.result}",
    "SAGITTARIUS_DB_ENCRYPTION_KEY_DERIVATION_SALT=${random_password.sagittarius_db_encryption_key_derivation_salt.result}",
    "SAGITTARIUS_RAILS_SECRET_KEY_BASE=${random_password.sagittarius_rails_secret_key_base.result}",

    "SAGITTARIUS_GATEWAY_LOG_LEVEL=info",
    "SAGITTARIUS_GATEWAY_JWT_SECRET=${random_password.sagittarius_gateway_jwt_secret.result}",
    "SAGITTARIUS_GATEWAY_JWT_TTL_SECONDS=300",

    "VELORUM_HOST=${var.project_name}-velorum",
    "VELORUM_PORT=50051",
    "VELORUM_JWT_SECRET=${random_password.velorum_jwt_secret.result}",

    "OPENTELEMETRY_ENABLED=${var.opentelemetry_enabled}",
    "OPENTELEMETRY_GRPC_HOST=http://localhost:4317",
    "OPENTELEMETRY_LOGS_HTTP_ENDPOINT=${var.otel_logs_http_endpoint}",
    "OPENTELEMETRY_METRICS_HTTP_ENDPOINT=${var.otel_metrics_http_endpoint}",
    "OPENTELEMETRY_TRACES_HTTP_ENDPOINT=${var.otel_traces_http_endpoint}",
    "OPENTELEMETRY_LOGS_CLIENTSIDE_HTTP_ENDPOINT=${var.otel_logs_clientside_http_endpoint}",
    "OPENTELEMETRY_METRICS_CLIENTSIDE_HTTP_ENDPOINT=${var.otel_metrics_clientside_http_endpoint}",
    "OPENTELEMETRY_TRACES_CLIENTSIDE_HTTP_ENDPOINT=${var.otel_traces_clientside_http_endpoint}",

    "OPENTELEMETRY_SERVICE_NAME_SAGITTARIUS_WEB=sagittarius-web",
    "OPENTELEMETRY_SERVICE_NAME_SAGITTARIUS_CABLE=sagittarius-cable",
    "OPENTELEMETRY_SERVICE_NAME_SAGITTARIUS_GRPC=sagittarius-grpc",
    "OPENTELEMETRY_SERVICE_NAME_SAGITTARIUS_BACKGROUND=sagittarius-background",
    "OPENTELEMETRY_SERVICE_NAME_SAGITTARIUS_GATEWAY=sagittarius-gateway",
    "OPENTELEMETRY_SERVICE_NAME_NGINX=nginx",
    "OPENTELEMETRY_SERVICE_NAME_SCULPTOR=${var.otel_service_name_sculptor}",
    "OPENTELEMETRY_SERVICE_NAME_SCULPTOR_CLIENTSIDE=${var.otel_service_name_sculptor_clientside}",

    "SAGITTARIUS_RAILS_HOST=${var.project_name}-sagittarius-rails-web",
    "SAGITTARIUS_RAILS_PORT=3000",
    "SAGITTARIUS_CABLE_HOST=${var.project_name}-sagittarius-rails-cable",
    "SAGITTARIUS_CABLE_PORT=3000",
    "SAGITTARIUS_GRPC_HOST=${var.project_name}-sagittarius-grpc",
    "SAGITTARIUS_GRPC_PORT=50051",
    "SAGITTARIUS_GATEWAY_HOST=${var.project_name}-sagittarius-gateway",
    "SAGITTARIUS_GATEWAY_PORT=50051",
    "SAGITTARIUS_LOG_LEVEL=info",
    "SAGITTARIUS_RAILS_WEB_THREADS=3",
    "SAGITTARIUS_RAILS_GRPC_THREADS=6",
    "SAGITTARIUS_DB_POOL_SIZE=8",

    "SCULPTOR_HOST=${var.project_name}-sculptor",
    "SCULPTOR_PORT=3000",

    "POSTGRES_HOST=${var.project_name}-postgres",
    "POSTGRES_PORT=5432",
    "POSTGRES_DB=${var.postgres_db}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${random_password.postgres_password.result}",
  ]

  default_keys  = [for line in local.default_config_generator_env : split("=", line)[0]]
  override_keys = [for line in var.config_generator_env : split("=", line)[0]]
  default_unset = [
    for i, line in local.default_config_generator_env :
    line if !contains(local.override_keys, local.default_keys[i])
  ]
  config_generator_env = concat(local.default_unset, var.config_generator_env)
}
