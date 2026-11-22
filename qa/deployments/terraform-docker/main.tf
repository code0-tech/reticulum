terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

provider "docker" {
  host = "tcp://docker:2376/"

  cert_path = pathexpand("/certs/client")
}

variable "IMAGE_REGISTRY" {
  type = string
}

variable "IMAGE_TAG" {
  type = string
}

variable "IMAGE_EDITION" {
  type = string
}

variable "ACTION_IMAGE_TAG" {
  type = string
}
