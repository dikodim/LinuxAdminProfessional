# Terraform vCD / NSX-V Edge Lab

Новая ветка для переписывания `Project` под стек:

- `Terraform` как основной инструмент описания инфраструктуры
- `VMware Cloud Director (vCD)` как целевая платформа
- `NSX-V Edge` для реализации DMZ, routed-сетей, NAT и north-south трафика
- `Prometheus + Grafana` вместо Zabbix
- отдельный backup-узел вместо старого backup-роля внутри PostgreSQL

## Целевая схема

- `NSX-V Edge` публикует frontend Nextcloud в DMZ-сегмент
- `Nextcloud` размещается в DMZ как application tier
- `PostgreSQL primary/replica` размещается во внутреннем сегменте
- `Prometheus`, `Grafana` и exporters размещаются во внутреннем сегменте
- `Backup` размещается во внутреннем сегменте и собирает бэкапы PostgreSQL и служебных данных

## Что меняется по сравнению со старым стендом

- Больше не считаем `Vagrant` и VirtualBox основной платформой
- DMZ реализуется на уровне `NSX-V`, а не отдельной VM `firewall`
- Мониторинг строится вокруг `Prometheus`, `Grafana`, `node_exporter`, `postgres_exporter`, `blackbox_exporter`
- Бэкапы выделяются в отдельный контур

## Структура

```text
Project/
├── terraform/
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── nsxv_edge/
│       ├── nextcloud_cluster/
│       ├── postgres_cluster/
│       ├── monitoring_stack/
│       └── backup_stack/
└── ansible/
```

## Первый этап

Сейчас в ветке заложен именно новый каркас:

- провайдер и переменные для `vcd`
- модульная декомпозиция под `NSX-V edge`, `Nextcloud`, `PostgreSQL`, `monitoring`, `backup`
- пример `terraform.tfvars`

Следующий шаг после этого каркаса:

1. описать `vcd` provider и naming conventions под твой tenant
2. реализовать routed-сети и edge gateway
3. вынести VM-группы в отдельные модули
4. определить, что оставляем в `Ansible`, а что полностью описываем через cloud-init/user-data

## Текущие исходные данные

- tenant portal: [B2B-service-kubernetes-group](https://dcloud.ru/tenant/B2B-service-kubernetes-group)
- vDC / datacenter: `b2b-k8s-test-kube-version2_vc4`
- NSX-V Edge: `b2b-k8s-test-kube-version2_vc4-egde`

Для `Terraform vcd provider` в примере используется API endpoint того же хоста:

- `https://dcloud.ru/api`

`org` в примере ниже выведен из tenant path как `B2B-service-kubernetes-group`.

## Примечание

Старые `Vagrant`/legacy-файлы пока физически ещё лежат в репозитории как база, от которой мы отделились. Дальше развиваем именно `terraform`-направление на этой ветке.
