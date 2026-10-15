resource "random_password" "initial_runtime_token" {
  length  = 32
  special = false
}

resource "random_password" "taurus_aquila_token" {
  length  = 32
  special = false
}

resource "random_password" "sagittarius_db_encryption_primary_key" {
  length  = 32
  special = false
}

resource "random_password" "sagittarius_db_encryption_deterministic_key" {
  length  = 32
  special = false
}

resource "random_password" "sagittarius_db_encryption_key_derivation_salt" {
  length  = 32
  special = false
}

resource "random_password" "sagittarius_rails_secret_key_base" {
  length  = 32
  special = false
}

resource "random_password" "sagittarius_gateway_jwt_secret" {
  length  = 32
  special = false
}

resource "random_password" "velorum_jwt_secret" {
  length  = 32
  special = false
}

resource "random_password" "postgres_password" {
  length  = 32
  special = false
}
