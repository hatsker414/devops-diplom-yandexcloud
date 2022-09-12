locals {
  token           = "AQAAAAAE97yXAATuwYVVlW1580hVnXlyK9bBKi8"
  folder_id       = "b1glh44698ke0dcg2atn"
  cloud_id        = "b1g452hd5sue1nnbqako"
  public_subnets  = 1
  private_subnets = length(var.zones)
}

variable "zones" {
  type = list(string)
  default = [
    "ru-central1-a",
    "ru-central1-b",
    "ru-central1-c"
  ]
}

variable "private_v4_cidr_blocks" {
  type = list(list(string))
  default = [
    ["192.168.20.0/24"],
    ["192.168.40.0/24"],
    ["192.168.60.0/24"]
  ]
}

variable "public_v4_cidr_blocks" {
  type = list(list(string))
  default = [
    ["192.168.10.0/24"],
    ["192.168.30.0/24"],
    ["192.168.50.0/24"]
  ]
}
