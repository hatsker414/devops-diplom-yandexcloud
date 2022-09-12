resource "yandex_vpc_network" "k8s-network" {
  name = "yc-net"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public0"
  zone           = var.zones[0]
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = var.public_v4_cidr_blocks[0]
}


resource "yandex_vpc_subnet" "private" {
  count          = local.private_subnets
  name           = "private${count.index}"
  zone           = var.zones[count.index]
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = var.private_v4_cidr_blocks[count.index]
  route_table_id = yandex_vpc_route_table.vpc-1-rt.id
}

resource "yandex_compute_instance" "nat-vm" {
  name        = "nat-instance"
  platform_id = "standard-v1"
  zone        = var.zones[0]

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  scheduling_policy {
    # !прерываемая!
    preemptible = (terraform.workspace == "stage") ? true : false
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1" # nat-instance-ubuntu
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public.id
    ip_address = "192.168.10.254"
    nat        = true
  }

}

resource "yandex_vpc_route_table" "vpc-1-rt" {
  name       = "nat-gateway"
  network_id = yandex_vpc_network.k8s-network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat-vm.network_interface.0.ip_address
  }
}

