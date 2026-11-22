variable "docker_networks" {
  type    = list(string)
  default = null
}

variable "identifier" {
  type = string
}

variable "image" {
  type = object({
    name          = string
    sha256_digest = string
  })
}

variable "aquila_url" {
  type = string
}
