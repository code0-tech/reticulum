variable "project_name" {
  description = "Prefix used for container, network and volume names (mirrors the compose 'name:' key)."
  type        = string
  default     = "codezero"
}

variable "image_registry" {
  description = "Registry host that application images are pulled from."
  type        = string
  default     = "registry.gitlab.com/code0-tech/packages"
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
  type    = string
  default = "localhost"
}

variable "http_port" {
  description = "Host port mapped to nginx's internal port 80. Set to null to not publish HTTP."
  type        = number
  default     = 80
}

variable "https_port" {
  description = "Host port mapped to nginx's internal port 443. Set to null to not publish HTTPS."
  type        = number
  default     = 443
}

variable "nginx_bind_ip" {
  description = <<-EOT
    Host IP address to bind the published nginx ports to. Defaults to null,
    which binds on all interfaces (0.0.0.0). Set to "127.0.0.1" to expose the
    ports on localhost only (e.g. when running behind an external reverse
    proxy).
  EOT
  type        = string
  default     = null
}

variable "nginx_env" {
  description = <<-EOT
    Additional environment variables to set on the nginx container, as a list of
    "KEY=value" strings. Useful when running behind a reverse proxy such as
    nginx-proxy (e.g. ["VIRTUAL_HOST=example.com", "VIRTUAL_PORT=80"]).
    Empty by default.
  EOT
  type        = list(string)
  default     = []
}

variable "nginx_additional_network" {
  description = <<-EOT
    Name of an optional additional (externally managed) Docker network to
    attach the nginx container to, in addition to the module's default network.
    Useful for joining a reverse-proxy network such as nginx-proxy. The network
    must already exist; it is not created by this module. Defaults to null (no
    additional network).
  EOT
  type        = string
  default     = null
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

variable "enabled_profiles" {
  description = <<-EOT
    Which service profiles to start. Valid values:
      - "ide":         sculptor, sagittarius (web/background/grpc/cable/gateway), postgres, nginx
      - "runtime":     aquila, taurus, nats
      - "ide_velorum": velorum (requires "ide")
    Defaults to ["ide", "runtime"] (previous behaviour with velorum off).
  EOT
  type        = list(string)
  default     = ["ide", "runtime"]

  validation {
    condition     = length(setsubtract(toset(var.enabled_profiles), toset(["ide", "runtime", "ide_velorum"]))) == 0
    error_message = "enabled_profiles may only contain: \"ide\", \"runtime\", \"ide_velorum\"."
  }

  validation {
    condition     = !contains(var.enabled_profiles, "ide_velorum") || contains(var.enabled_profiles, "ide")
    error_message = "Profile \"ide_velorum\" requires \"ide\" to also be enabled."
  }
}

variable "few_shots_external_config_path" {
  description = "Absolute host path to velorum.few_shots_external.configuration.json."
  type        = string
  default     = "{}"
}

variable "otel_service_name_sculptor" {
  type    = string
  default = "sculptor"
}

variable "otel_service_name_sagittarius_web" {
  type    = string
  default = "sagittarius-web"
}

variable "otel_service_name_sagittarius_cable" {
  type    = string
  default = "sagittarius-cable"
}

variable "otel_service_name_sagittarius_grpc" {
  type    = string
  default = "sagittarius-grpc"
}

variable "otel_service_name_sagittarius_background" {
  type    = string
  default = "sagittarius-background"
}

variable "otel_service_name_sagittarius_gateway" {
  type    = string
  default = "sagittarius-gateway"
}

variable "otel_service_name_nginx" {
  type    = string
  default = "nginx"
}

variable "otel_service_name_aquila" {
  type    = string
  default = "aquila"
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
  default = "sculptor-clientside"
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
  description = "Overrides of predefined config generator variables"
  type        = list(string)
  sensitive   = true
  default     = []
}

variable "aquila_actions" {
  description = <<-EOT
    Aquila actions to register, keyed by a short name (letters/digits, no
    underscores). Each entry is rendered by the config-generator into
    aquila.service.configuration.json via AQUILA_ACTION_<KEY>_* env vars.
  EOT
  type = map(object({
    identifier = string
    token      = string
  }))
  default = {}
}

variable "velorum_models" {
  description = <<-EOT
    Velorum models to register, keyed by a short name (letters/digits, no
    underscores). Each entry is rendered by the config-generator into
    velorum.models.configuration.json via VELORUM_MODEL_<KEY>_* env vars.
  EOT
  type = map(object({
    identifier   = string
    name         = string
    capabilities = list(string)
    provider     = string
    api          = string
    auth         = string
    token_cost   = number
  }))
  default = {}
}

locals {
  ide_enabled     = contains(var.enabled_profiles, "ide")
  runtime_enabled = contains(var.enabled_profiles, "runtime")
  velorum_enabled = contains(var.enabled_profiles, "ide_velorum")

  default_config_generator_env = [
    "HOSTNAME=${var.hostname}",
    "HTTP_PORT=${coalesce(var.http_port, 80)}",
    "HTTPS_PORT=${coalesce(var.https_port, 443)}",
    "SSL_ENABLED=${var.ssl_enabled}",
    "SSL_CERT_FILE=/etc/nginx/certs/tls.crt",
    "SSL_KEY_FILE=/etc/nginx/certs/tls.key",

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

    "VELORUM_ENABLED=${local.velorum_enabled}",

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

    "OPENTELEMETRY_SERVICE_NAME_SAGITTARIUS_WEB=${var.otel_service_name_sagittarius_web}",
    "OPENTELEMETRY_SERVICE_NAME_SAGITTARIUS_CABLE=${var.otel_service_name_sagittarius_cable}",
    "OPENTELEMETRY_SERVICE_NAME_SAGITTARIUS_GRPC=${var.otel_service_name_sagittarius_grpc}",
    "OPENTELEMETRY_SERVICE_NAME_SAGITTARIUS_BACKGROUND=${var.otel_service_name_sagittarius_background}",
    "OPENTELEMETRY_SERVICE_NAME_SAGITTARIUS_GATEWAY=${var.otel_service_name_sagittarius_gateway}",
    "OPENTELEMETRY_SERVICE_NAME_NGINX=${var.otel_service_name_nginx}",
    "OPENTELEMETRY_SERVICE_NAME_AQUILA=${var.otel_service_name_aquila}",
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

  # Flatten aquila_actions into AQUILA_ACTION_<KEY>_* env lines.
  aquila_action_env = flatten([
    for k, a in var.aquila_actions : [
      "AQUILA_ACTION_${upper(k)}_IDENTIFIER=${a.identifier}",
      "AQUILA_ACTION_${upper(k)}_TOKEN=${a.token}",
    ]
  ])

  # Flatten velorum_models into VELORUM_MODEL_<KEY>_* env lines.
  velorum_model_env = flatten([
    for k, m in var.velorum_models : [
      "VELORUM_MODEL_${upper(k)}_IDENTIFIER=${m.identifier}",
      "VELORUM_MODEL_${upper(k)}_NAME=${m.name}",
      "VELORUM_MODEL_${upper(k)}_CAPABILITIES=${join(",", m.capabilities)}",
      "VELORUM_MODEL_${upper(k)}_PROVIDER=${m.provider}",
      "VELORUM_MODEL_${upper(k)}_API=${m.api}",
      "VELORUM_MODEL_${upper(k)}_AUTH=${m.auth}",
      "VELORUM_MODEL_${upper(k)}_TOKEN_COST=${m.token_cost}",
    ]
  ])

  default_keys  = [for line in local.default_config_generator_env : split("=", line)[0]]
  override_keys = [for line in var.config_generator_env : split("=", line)[0]]
  default_unset = [
    for i, line in local.default_config_generator_env :
    line if !contains(local.override_keys, local.default_keys[i])
  ]
  config_generator_env = concat(
    local.default_unset,
    local.aquila_action_env,
    local.velorum_model_env,
    var.config_generator_env,
  )
}
