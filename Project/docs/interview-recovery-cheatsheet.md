# Шпаргалка для собеседования: удаление и восстановление любой VM

## Общее правило

```bash
cd Project/terraform
terraform destroy -target="$VM"
terraform apply -target="$VM"

cd ../ansible
ansible-playbook -i inventory.ini recover.yml --limit <host>
```

---

## nextcloud-01

```bash
cd Project/terraform
VM='module.nextcloud_cluster.vcd_vm.node["nextcloud-01"]'

terraform destroy -target="$VM"
terraform apply -target="$VM"

cd ../ansible
ansible-playbook -i inventory.ini recover.yml --limit nextcloud-01
```

Проверка:

```bash
ssh -p 2201 ubuntu@185.98.82.7 'hostname && uptime'
```

---

## nextcloud-02

```bash
cd Project/terraform
VM='module.nextcloud_cluster.vcd_vm.node["nextcloud-02"]'

terraform destroy -target="$VM"
terraform apply -target="$VM"

cd ../ansible
ansible-playbook -i inventory.ini recover.yml --limit nextcloud-02
```

Проверка:

```bash
ssh -p 2202 ubuntu@185.98.82.7 'hostname && uptime'
```

---

## postgres-replica

```bash
cd Project/terraform
VM='module.postgres_cluster.vcd_vm.node["postgres-replica"]'

terraform destroy -target="$VM"
terraform apply -target="$VM"

cd ../ansible
ansible-playbook -i inventory.ini recover.yml --limit postgres-replica
```

Проверка:

```bash
ssh -p 2214 ubuntu@185.98.82.7 'sudo -u postgres psql -c "select pg_is_in_recovery();"'
```

Должно быть `t`.

---

## postgres-primary

Сначала failover на replica:

```bash
ssh -p 2214 ubuntu@185.98.82.7 \
  'sudo -u postgres psql -c "SELECT pg_promote(true, 60);"'
```

Переключить Nextcloud на новый primary:

```bash
cd Project/ansible
ansible-playbook -i inventory.ini site.yml \
  --limit nextcloud \
  --tags nextcloud \
  -e postgres_primary_host=192.168.46.14
```

Пересоздать старый primary:

```bash
cd ../terraform
VM='module.postgres_cluster.vcd_vm.node["postgres-primary"]'

terraform destroy -target="$VM"
terraform apply -target="$VM"
```

Поднять его как replica:

```bash
cd ../ansible
ansible-playbook -i inventory.ini site.yml \
  --limit postgres-primary \
  --tags postgres,postgres-primary,metrics,logs \
  -e postgres_role=replica \
  -e postgres_primary_host=192.168.46.14 \
  -e postgres_replica_host=192.168.46.13 \
  -e postgres_force_resync=true
```

### Если нужен простой и восстановление `postgres-primary` с `postgres-replica` через Ansible

После пересоздания VM `postgres-primary`:

```bash
cd Project/ansible
ansible-playbook -i inventory.ini recover.yml \
  --limit postgres-primary \
  -e postgres_restore_source_host=192.168.46.14 \
  -e postgres_restore_force_resync=true
```

Проверка:

```bash
ssh -p 2213 ubuntu@185.98.82.7 'sudo -u postgres psql -c "select pg_is_in_recovery();"'
```

Должно быть `f`.

---

## services-1

После восстановления `services-1` надо перепройти `nextcloud`, потому что от неё зависят:

- NFS
- Grafana
- Prometheus
- VictoriaLogs
- Alertmanager

```bash
cd Project/terraform
VM='module.services_node.vcd_vm.this'

terraform destroy -target="$VM"
terraform apply -target="$VM"
```

```bash
cd ../ansible
export GRAFANA_SMTP_PASSWORD="google-app-password-без-пробелов"
ansible-playbook -i inventory.ini recover.yml --limit services-1
ansible-playbook -i inventory.ini site.yml --limit nextcloud --tags nfs,nextcloud,keepalived
```

Проверка:

```bash
ssh -p 2215 ubuntu@185.98.82.7 'docker ps'
ansible nextcloud -b -m shell -a 'mount | grep /mnt/nextcloud'
```

---

## Что говорить

- `nextcloud-*`: пересоздаю VM через Terraform и докатываю конфиг через Ansible.
- `postgres-replica`: пересоздаю и заново синхронизирую от primary.
- `postgres-primary`: сначала failover на replica, потом старый primary пересоздаю и возвращаю как replica.
- `services-1`: после восстановления обязательно переподнимаю nextcloud-клиенты, потому что они зависят от NFS и сервисной ноды.
