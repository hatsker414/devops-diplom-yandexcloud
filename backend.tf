terraform {
  backend "s3" {
    endpoint = "storage.yandexcloud.net"
    bucket   = "hatskerbucket"
    key        = "diplom/terraform.tfstate" # path to my tfstate file in the bucket
    region     = "ru-central1-a"
    access_key = "YCAJEB55Oj2A066twt-wio17a"
    secret_key = "YCPXRiRvaB22cF8GN-8YK1aoFQYQ6Y7sJzO0Vha1"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}