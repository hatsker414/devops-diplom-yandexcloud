# Дипломный практикум в Яндекс.Облако
  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:

### Создание облачной инфраструктуры

Подготавливаю облачную инфраструктуру в ЯО при помощи terraform.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
```bash
yc iam service-account create terraform
yc iam key create --service-account-name terraform -o terraform.json
yc config set service-account-key terraform.json
export TF_VAR_yc_token=$(yc iam create-token)
SERVICE_ACCOUNT_ID=$(yc iam service-account get --name terraform --format json | jq -r .id)
FOLDER_ID=$(yc iam service-account get --name terraform --format json | jq -r .folder_id)
yc resource-manager folder add-access-binding $FOLDER_ID --role editor --subject 
yc iam service-account add-access-binding $SERVICE_ACCOUNT_ID --role editor 
serviceAccount:$SERVICE_ACCOUNT_ID
```
2. Подготавливаю backend на Terraform Cloud 
#### backend.tf
```tf
# backend.tf
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
```
```bash
$ cat ~/.terraformrc
credentials "app.terraform.io" {
token = "Place your token here"
}
```
3. Настраиваю workspaces  
```bash
$ terraform workspace new stage && terraform workspace new prod
Created and switched to workspace "stage"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
Created and switched to workspace "prod"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
$ terraform workspace select stage
Switched to workspace "stage".
```
4. Создаю VPC с подсетями в разных зонах доступности.
#### networks.tf
```# Create ya.cloud VPC
resource "yandex_vpc_network" "k8s-network" {
  name = "yc-net"
}
# Create ya.cloud public subnet
resource "yandex_vpc_subnet" "k8s-network-a" {
  name           = "public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}
resource "yandex_vpc_subnet" "k8s-network-b" {
  name           = "public-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}
resource "yandex_vpc_subnet" "k8s-network-c" {
  name           = "public-c"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.k8s-network.id
  v4_cidr_blocks = ["192.168.30.0/24"]
}
```

5. Проверяю команду terraform apply без дополнительных ручных действий.

```bash
$ alexp@lair:~/yandex-cloud-terraform$ terraform apply
yandex_container_registry.diplom: Refreshing state... [id=crp9g918mgr8c4a0geee]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # yandex_container_registry_iam_binding.pusher will be created
  + resource "yandex_container_registry_iam_binding" "pusher" {
      + id          = (known after apply)
      + members     = (known after apply)
      + registry_id = "crp9g918mgr8c4a0geee"
      + role        = "editor"
    }

  # yandex_iam_service_account.k8s will be created
  + resource "yandex_iam_service_account" "k8s" {
      + created_at = (known after apply)
      + folder_id  = "b1glh44698ke0dcg2atn"
      + id         = (known after apply)
      + name       = "k8s"
    }

  # yandex_iam_service_account.pusher will be created
  + resource "yandex_iam_service_account" "pusher" {
      + created_at = (known after apply)
      + folder_id  = "b1glh44698ke0dcg2atn"
      + id         = (known after apply)
      + name       = "pusher"
    }

  # yandex_kubernetes_cluster.k8s-yandex will be created
  + resource "yandex_kubernetes_cluster" "k8s-yandex" {
      + cluster_ipv4_range       = (known after apply)
      + cluster_ipv6_range       = (known after apply)
      + created_at               = (known after apply)
      + description              = "description"
      + folder_id                = (known after apply)
      + health                   = (known after apply)
      + id                       = (known after apply)
      + labels                   = {
          + "my_key"       = "my_value"
          + "my_other_key" = "my_other_value"
        }
      + log_group_id             = (known after apply)
      + name                     = "k8s-yandex"
      + network_id               = (known after apply)
      + network_policy_provider  = "CALICO"
      + node_ipv4_cidr_mask_size = 24
      + node_service_account_id  = (known after apply)
      + release_channel          = "STABLE"
      + service_account_id       = (known after apply)
      + service_ipv4_range       = (known after apply)
      + service_ipv6_range       = (known after apply)
      + status                   = (known after apply)

      + master {
          + cluster_ca_certificate = (known after apply)
          + external_v4_address    = (known after apply)
          + external_v4_endpoint   = (known after apply)
          + internal_v4_address    = (known after apply)
          + internal_v4_endpoint   = (known after apply)
          + public_ip              = true
          + version                = "1.21"
          + version_info           = (known after apply)

          + maintenance_policy {
              + auto_upgrade = true

              + maintenance_window {
                  + day        = "friday"
                  + duration   = "4h30m"
                  + start_time = "02:00"
                }
              + maintenance_window {
                  + day        = "monday"
                  + duration   = "3h"
                  + start_time = "03:00"
                }
            }

          + regional {
              + region = "ru-central1"

              + location {
                  + subnet_id = (known after apply)
                  + zone      = "ru-central1-a"
                }
              + location {
                  + subnet_id = (known after apply)
                  + zone      = "ru-central1-b"
                }
              + location {
                  + subnet_id = (known after apply)
                  + zone      = "ru-central1-c"
                }
            }

          + zonal {
              + subnet_id = (known after apply)
              + zone      = (known after apply)
            }
        }
    }

  # yandex_kubernetes_node_group.mynodes will be created
  + resource "yandex_kubernetes_node_group" "mynodes" {
      + cluster_id        = (known after apply)
      + created_at        = (known after apply)
      + description       = "description"
      + id                = (known after apply)
      + instance_group_id = (known after apply)
      + labels            = {
          + "key" = "value"
        }
      + name              = "mynodes"
      + status            = (known after apply)
      + version           = "1.21"
      + version_info      = (known after apply)

      + allocation_policy {
          + location {
              + subnet_id = (known after apply)
              + zone      = "ru-central1-a"
            }
        }

      + deploy_policy {
          + max_expansion   = (known after apply)
          + max_unavailable = (known after apply)
        }

      + instance_template {
          + metadata                  = (known after apply)
          + nat                       = (known after apply)
          + network_acceleration_type = (known after apply)
          + platform_id               = "standard-v2"

          + boot_disk {
              + size = 64
              + type = "network-hdd"
            }

          + container_runtime {
              + type = (known after apply)
            }

          + network_interface {
              + ipv4       = true
              + ipv6       = (known after apply)
              + nat        = true
              + subnet_ids = (known after apply)
            }

          + resources {
              + core_fraction = (known after apply)
              + cores         = 2
              + gpus          = 0
              + memory        = 4
            }

          + scheduling_policy {
              + preemptible = false
            }
        }

      + maintenance_policy {
          + auto_repair  = true
          + auto_upgrade = true

          + maintenance_window {
              + day        = "friday"
              + duration   = "4h30m"
              + start_time = "02:00"
            }
          + maintenance_window {
              + day        = "monday"
              + duration   = "3h"
              + start_time = "03:00"
            }
        }

      + scale_policy {
          + auto_scale {
              + initial = 3
              + max     = 6
              + min     = 3
            }
        }
    }

  # yandex_resourcemanager_folder_iam_member.k8s-editor will be created
  + resource "yandex_resourcemanager_folder_iam_member" "k8s-editor" {
      + folder_id = "b1glh44698ke0dcg2atn"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "editor"
    }

  # yandex_vpc_network.k8s-network will be created
  + resource "yandex_vpc_network" "k8s-network" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "yc-net"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.k8s-network-a will be created
  + resource "yandex_vpc_subnet" "k8s-network-a" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "public-a"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.10.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.k8s-network-b will be created
  + resource "yandex_vpc_subnet" "k8s-network-b" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "public-b"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.20.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

  # yandex_vpc_subnet.k8s-network-c will be created
  + resource "yandex_vpc_subnet" "k8s-network-c" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "public-c"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.30.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-c"
    }

Plan: 10 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + cluster_external_v4_endpoint = (known after apply)
  + cluster_id                   = (known after apply)
  + registry_id                  = "crp9g918mgr8c4a0geee"
  Changes to Outputs:
  + cluster_external_v4_endpoint = (known after apply)
  + cluster_id                   = (known after apply)
  + registry_id                  = "crp9g918mgr8c4a0geee"

Do you want to perform these actions in workspace "stage"?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```
---
### Создание Kubernetes кластера
Cоздаю Kubernetes кластер на базе предварительно созданной инфраструктуры используя Yandex Managed Service for Kubernetes
#### k8s-cluster.tf
```resource "yandex_kubernetes_cluster" "k8s-yandex" {
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
```
Создаю воркеры
#### k8s-nodes.tf
```resource "yandex_kubernetes_node_group" "mynodes" {
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
```
Получаю адрес и id кластера
#### outputs.tf
```
output "cluster_external_v4_endpoint" {
  value = yandex_kubernetes_cluster.k8s-yandex.master.0.external_v4_endpoint
}

output "cluster_id" {
  value = yandex_kubernetes_cluster.k8s-yandex.id
}
```
Создаю конфиг kubernetes
```bash
$ yc managed-kubernetes cluster get-credentials --id $(terraform output -json cluster_id | sed 's/\"//g') --external

Context 'yc-k8s-yandex' was added as default to kubeconfig '/home/alexp/.kube/config'.
Check connection to cluster using 'kubectl cluster-info --kubeconfig /home/alexp/.kube/config'.

Note, that authentication depends on 'yc' and its config profile 'default'.
To access clusters using the Kubernetes API, please use Kubernetes Service Account.
```

![img](img/03.png)

Команда `kubectl get pods --all-namespaces`.
![img](img/01.png)
---
### Создание тестового приложения
1. Git репозиторий с тестовым приложением и Dockerfile.
[nginx](https://github.com/hatsker414/nginx)

2. Регистр с собранным docker image. 
![img](img/02.png)
---
### Подготовка cистемы мониторинга и деплой приложения

# Деплою в кластер prometheus-stack
1. Cтавим helm ```sudo snap install helm --classic```

```bash
 kubectl create namespace netology
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
$ helm install --namespace netology stable prometheus-community/kube-prometheus-stack
```
![img](img/04.png)

переключаемся на namespace netology 
``` kubectl config set-context --current --namespace=netology```

Настраиваю Grafana на LoadBalancer.
```bash
$ KUBE_EDITOR="nano" kubectl edit svc stable-grafana
```
```yaml
  selector:
    app.kubernetes.io/instance: stable
    app.kubernetes.io/name: grafana
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```
Меняю на 
```yaml
  selector:
    app.kubernetes.io/instance: stable
    app.kubernetes.io/name: grafana
  sessionAffinity: None
  type: LoadBalancer
```
![img](img/06.png)
![img](img/05.png)

[Grafana admin panel](http://84.252.130.125/d/efa86fd1d0c121a26444b636a3f509a8/kubernetes-compute-resources-cluster?orgId=1&refresh=10s)
admin
prom-operator

[опубликованое приложение](http://130.193.37.8/)


### Установка и настройка CI/CD

Настраиваю CI/CD GitLab

[Репозиторий](https://gitlab.com/n2818/my_dip/-/tree/main)

1. Настройка gitlab:
```bash
$ kubectl -n kube-system get secrets -o json | \
> jq -r '.items[] | select(.metadata.name | startswith("gitlab-admin")) | .data.token' | \
> base64 --decode 
```
Устанавливаю переменные:
![img](img/07.png)

KUBE_TOKEN - token пользователя terraform  
KUBE_URL - адрес кластера  
REGISTRYID - id Container Registry  
OAUTH - oauth token для авторизации в yc    

Интерфейс ci/cd сервиса доступен по [ссылке](https://gitlab.com/n2818/my_dip)  
При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.  


![img](img/08.png)

![img](img/09.png)

## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)

---
## Как правильно задавать вопросы дипломному руководителю?

Что поможет решить большинство частых проблем:

1. Попробовать найти ответ сначала самостоятельно в интернете или в 
  материалах курса и ДЗ и только после этого спрашивать у дипломного 
  руководителя. Скилл поиска ответов пригодится вам в профессиональной 
  деятельности.
2. Если вопросов больше одного, то присылайте их в виде нумерованного 
  списка. Так дипломному руководителю будет проще отвечать на каждый из 
  них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой 
  покажите, где не получается.

Что может стать источником проблем:

1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». 
  Дипломный руководитель не сможет ответить на такой вопрос без 
  дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения курсового проекта на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители работающие разработчики, которые занимаются, кроме преподавания, 
  своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)

