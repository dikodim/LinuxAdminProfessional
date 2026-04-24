# Развертывание стенда через Ansible

Эта инструкция запускается после `terraform apply`, когда VM уже созданы и SSH DNAT работает.

## Что разворачивает Ansible

- `services-1`: Docker, NFS, Prometheus, Grafana, VictoriaLogs, Alertmanager.
- `postgres-primary`: PostgreSQL primary, node exporter, postgres exporter, backup.
- `postgres-replica`: PostgreSQL replica, node exporter, postgres exporter.
- `nextcloud-01` и `nextcloud-02`: Docker, Nextcloud, NFS client, keepalived, exporters.

## Быстрый полный запуск

```bash
cd Project/ansible

export GRAFANA_SMTP_PASSWORD="google-app-password-без-пробелов"

ansible all -m ping
ansible-playbook -i inventory.ini site.yml
```

Если отправитель Gmail не `dmitrij.naumov.14@gmail.com`, задай его явно:

```bash
export GRAFANA_SMTP_USER="your.name@gmail.com"
export GRAFANA_SMTP_FROM_ADDRESS="$GRAFANA_SMTP_USER"
export GRAFANA_SMTP_PASSWORD="google-app-password-без-пробелов"
```

Если уведомления должны уходить на другой адрес:

```bash
export ALERTMANAGER_EMAIL_TO="ops@example.com"
```

## Проверка SSH до запуска

```bash
cd Project/ansible

ansible all -m ping
```

Если `ping` не проходит, сначала проверь DNAT/Firewall и доступность портов:

```bash
ssh -p 2201 ubuntu@185.98.82.7 'hostname' # nextcloud-01
ssh -p 2202 ubuntu@185.98.82.7 'hostname' # nextcloud-02
ssh -p 2213 ubuntu@185.98.82.7 'hostname' # postgres-primary
ssh -p 2214 ubuntu@185.98.82.7 'hostname' # postgres-replica
ssh -p 2215 ubuntu@185.98.82.7 'hostname' # services-1
```

## Запуск по частям

Сначала сервисная нода:

```bash
cd Project/ansible
export GRAFANA_SMTP_PASSWORD="google-app-password-без-пробелов"
ansible-playbook -i inventory.ini site.yml --tags services
```

Потом PostgreSQL:

```bash
ansible-playbook -i inventory.ini site.yml --tags postgres
```

Потом Nextcloud:

```bash
ansible-playbook -i inventory.ini site.yml --tags nextcloud
```

Метрики и логи можно прогнать отдельно:

```bash
ansible-playbook -i inventory.ini site.yml --tags metrics,logs
```

## Проверки после полного запуска

На services-ноде:

```bash
ssh -p 2215 ubuntu@185.98.82.7 'docker ps'
```

Prometheus:

```bash
curl -s http://192.168.46.15:9090/-/ready
```

Nextcloud через публичный IP:

```bash
curl -kI --resolve nextcloud.local:443:185.98.82.7 https://nextcloud.local/
```

PostgreSQL primary:

```bash
ssh -p 2213 ubuntu@185.98.82.7 'sudo -u postgres psql -c "select pg_is_in_recovery();"'
```

На primary должно быть `f`, на replica должно быть `t`:

```bash
ssh -p 2214 ubuntu@185.98.82.7 'sudo -u postgres psql -c "select pg_is_in_recovery();"'
```

## Восстановление одной VM после пересоздания Terraform

После `terraform apply -target=...` запускай `recover.yml` только на нужный host.

Nextcloud:

```bash
cd Project/ansible
ansible-playbook -i inventory.ini recover.yml --limit nextcloud-01
ansible-playbook -i inventory.ini recover.yml --limit nextcloud-02
```

PostgreSQL replica:

```bash
ansible-playbook -i inventory.ini recover.yml --limit postgres-replica
```

Services:

```bash
export GRAFANA_SMTP_PASSWORD="google-app-password-без-пробелов"
ansible-playbook -i inventory.ini recover.yml --limit services-1
```

## Важные файлы

- `inventory.ini`: адреса, SSH-порты и группы хостов.
- `group_vars/all.yml`: IP-адреса, пароли приложений, домены, настройки PostgreSQL, Nextcloud, Grafana и Alertmanager.
- `site.yml`: полный деплой всего стенда.
- `recover.yml`: повторная настройка одной VM после пересоздания.
