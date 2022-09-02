terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = ">=0.67.0"
    }
  }
}

provider "yandex" {
  token = "AQAAAAAE97yXAATuwYVVlW1580hVnXlyK9bBKi8"
  cloud_id  = "b1g452hd5sue1nnbqako"
  folder_id = "b1glh44698ke0dcg2atn"
}
