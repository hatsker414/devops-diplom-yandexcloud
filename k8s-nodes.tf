resource "yandex_kubernetes_node_group" "mynodes" {
  cluster_id  = "${yandex_kubernetes_cluster.k8s-yandex.id}"
  name        = "mynodes"
  description = "description"
  version     = "1.21"

  labels = {
    "key" = "value"
  }

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids = [yandex_vpc_subnet.k8s-network-a.id]
    }

    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

  }

  scale_policy {
    auto_scale {
      min = 3
      max = 6
      initial = 3
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "03:00"
      duration   = "3h"
    }
    maintenance_window {
      day        = "friday"
      start_time = "02:00"
      duration   = "4h30m"
    }
  }
}
