resource "yandex_kubernetes_cluster" "k8s-yandex" {
  name        = "k8s-yandex"
  description = "description"

  network_id = "${yandex_vpc_network.k8s-network.id}"

  master {
    regional {
      region = "ru-central1"

      location {
        zone      = "${yandex_vpc_subnet.k8s-network-a.zone}"
        subnet_id = "${yandex_vpc_subnet.k8s-network-a.id}"
      }

      location {
        zone      = "${yandex_vpc_subnet.k8s-network-b.zone}"
        subnet_id = "${yandex_vpc_subnet.k8s-network-b.id}"
      }

      location {
        zone      = "${yandex_vpc_subnet.k8s-network-c.zone}"
        subnet_id = "${yandex_vpc_subnet.k8s-network-c.id}"
      }
    }

   version   = "1.21"
    public_ip = true

    maintenance_policy {
      auto_upgrade = true

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

  service_account_id      = "${yandex_iam_service_account.k8s.id}"
  node_service_account_id = "${yandex_iam_service_account.pusher.id}"
  labels = {
    my_key       = "my_value"
    my_other_key = "my_other_value"
  }

  release_channel = "STABLE"
  network_policy_provider = "CALICO"
}