terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">=0.13"
    }
  }
}

provider "yandex" {
  token    = local.token
  cloud_id  = local.cloud_id
  folder_id = local.folder_id
  zone      = var.zones[0]
}
