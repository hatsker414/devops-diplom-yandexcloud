resource "yandex_kubernetes_node_group" "node_group1" {
  cluster_id  = yandex_kubernetes_cluster.k8s-yandex.id
  name        = "node-group1"
  description = "worker nodes"
  version     = "1.21"

  labels = {
    "key" = "value"
  }

  instance_template {
    platform_id = "standard-v1"

    network_interface {
      nat = false # Provide a public address, for instance, to access the internet over NAT
      subnet_ids = [yandex_vpc_subnet.private[0].id, yandex_vpc_subnet.private[1].id, yandex_vpc_subnet.private[2].id]
    }

    resources {
      memory        = 2
      cores         = 2
      core_fraction = 5
    }

    boot_disk {
      type = "network-hdd"
      size = 100
    }

  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    location {
      zone = var.zones[0]
    }
    location {
      zone = var.zones[1]
    }
    location {
      zone = var.zones[2]
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "5:00"
      duration   = "3h"
    }

    maintenance_window {
      day        = "friday"
      start_time = "1:00"
      duration   = "4h30m"
    }
  }
}