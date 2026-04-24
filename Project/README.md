# Terraform vCD / NSX-V Edge Lab

Новая ветка для переписывания `Project` под стек:

- `Terraform` как основной инструмент описания инфраструктуры
- `VMware Cloud Director (vCD)` как целевая платформа
- `NSX-V Edge` для реализации DMZ, routed-сетей, NAT и north-south трафика
- `Prometheus + Grafana` вместо Zabbix
- единая service-нода для `Prometheus`, `Grafana`, `VictoriaLogs`, `backup` и `NFS`

## Целевая схема

- `NSX-V Edge` публикует frontend Nextcloud в DMZ-сегмент
- `Nextcloud` размещается в DMZ как application tier
- `PostgreSQL primary/replica` размещается во внутреннем сегменте и ставится нативно пакетами на VM
- единая service-нода размещается во внутреннем сегменте и несёт:
  `Prometheus`, `Grafana`, `VictoriaLogs`, exporters, `backup` и `NFS`

## Что меняется по сравнению со старым стендом

- Больше не считаем `Vagrant` и VirtualBox основной платформой
- DMZ реализуется на уровне `NSX-V`, а не отдельной VM `firewall`
- PostgreSQL больше не планируется в контейнерах, только нативной установкой пакетами на отдельных VM
- Мониторинг строится вокруг `Prometheus`, `Grafana`, `node_exporter`, `postgres_exporter`, `blackbox_exporter`
- логи планируем складывать в `VictoriaLogs`
- backup и NFS объединяются с monitoring в одну internal service-VM
- сервисный стек для этой VM удобнее держать через `docker-compose`

## Структура

```text
Project/
├── compose/
│   └── services-node/
│       ├── docker-compose.yml
│       ├── prometheus.yml
│       └── grafana/
│           └── provisioning/
│               └── datasources/
│                   └── datasources.yml
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
│       └── services_node/
└── ansible/
```

## Первый этап

Сейчас в ветке заложен именно новый каркас:

- провайдер и переменные для `vcd`
- модульная декомпозиция под `NSX-V edge`, `Nextcloud`, `PostgreSQL` и общую service-ноду
- стартовый `docker-compose`-контур для service-ноды
- пример `terraform.tfvars`

Текущее разделение по способу деплоя:

- `PostgreSQL` на `postgres`-нодах: нативно пакетами на Ubuntu VM
- service-нода: `docker-compose` для `Prometheus`, `Grafana`, `VictoriaLogs` и связанных сервисов

Следующий шаг после этого каркаса:

1. описать `vcd` provider и naming conventions под твой tenant
2. реализовать routed-сети и edge gateway
3. вынести VM-группы в отдельные модули
4. определить, что оставляем в `Ansible`, а что полностью описываем через cloud-init/user-data

## Guest Customization

Для VM теперь можно централизованно задать `guest customization` в `terraform.tfvars`:

- `vm_customization.admin_password` задаёт пароль внутри блока `customization`
- `vm_customization.ssh_authorized_key` прокидывает публичный SSH-ключ через `customization.initscript`
- если указать оба поля, применятся и пароль, и ключ
- если блок `vm_customization` не задавать, VM создаются как раньше, без guest customization

Пример:

```hcl
vm_customization = {
  admin_password     = "ChangeMe123!"
  ssh_authorized_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleReplaceMeWithYourRealPublicKey user@host"
}
```

Сейчас ключ добавляется в `authorized_keys` для `root` и `ubuntu`, если такие пользователи присутствуют в шаблоне VM.

## Развертывание через Ansible

Полная инструкция по запуску Ansible лежит здесь:

- [docs/ansible-deploy-runbook.md](docs/ansible-deploy-runbook.md)

Короткий запуск после `terraform apply`:

```bash
cd Project/ansible
export GRAFANA_SMTP_PASSWORD="google-app-password-без-пробелов"
ansible all -m ping
ansible-playbook -i inventory.ini site.yml
```

## Grafana SMTP через Google

Grafana на service-ноде настроена на отправку уведомлений через Gmail SMTP:

- SMTP host: `smtp.gmail.com:587`
- STARTTLS policy: `MandatoryStartTLS`
- отправитель по умолчанию: значение `GRAFANA_SMTP_USER`

Перед запуском Ansible передайте Google account и app password:

```bash
export GRAFANA_SMTP_USER="your.name@gmail.com"
export GRAFANA_SMTP_PASSWORD="your-google-app-password"
export GRAFANA_SMTP_FROM_ADDRESS="$GRAFANA_SMTP_USER"

cd Project/ansible
ansible-playbook -i inventory.ini site.yml --tags services
```

По умолчанию для `GRAFANA_SMTP_USER` и `GRAFANA_SMTP_FROM_ADDRESS` используется `dmitrij.naumov.14@gmail.com`, поэтому достаточно передать только `GRAFANA_SMTP_PASSWORD`, если этот адрес остаётся отправителем.

Для Google нужен именно app password, а не обычный пароль аккаунта. Если SMTP временно не нужен, можно переопределить `grafana_smtp_enabled=false`.
Если Google показывает app password группами через пробелы, передавайте его в `GRAFANA_SMTP_PASSWORD` одной строкой без пробелов.

Prometheus-правила из `/etc/prometheus/alerts.yml` отображаются в Grafana как `Data source-managed`. Такие алерты маршрутизируются не через Grafana Contact Points напрямую, а через `Alertmanager`: `Prometheus -> Alertmanager -> email`. В service-stack включен контейнер `alertmanager`, Prometheus отправляет ему firing/resolved события, а Alertmanager использует те же Gmail SMTP-настройки.

Адрес получателя по умолчанию совпадает с `GRAFANA_SMTP_FROM_ADDRESS`. Чтобы отправлять уведомления на другой email:

```bash
export ALERTMANAGER_EMAIL_TO="ops@example.com"
```

## Текущие исходные данные

- tenant portal: [B2B-service-kubernetes-group](https://dcloud.ru/tenant/B2B-service-kubernetes-group)
- vDC / datacenter: `b2b-k8s-test-kube-version2_vc4`
- NSX-V Edge: `b2b-k8s-test-kube-version2_vc4-egde`
- external network: `SM-internet-2820`
- VM template: `Ubuntu-22_04_16G`
- app/template version reference: `vcd-ch-app-ver:1.0.0:oX2M3`

Для `Terraform vcd provider` в примере используется API endpoint того же хоста:

- `https://dcloud.ru/api`

`org` в примере ниже выведен из tenant path как `B2B-service-kubernetes-group`.

## Примечание

Старые `Vagrant`/legacy-файлы пока физически ещё лежат в репозитории как база, от которой мы отделились. Дальше развиваем именно `terraform`-направление на этой ветке.
