# Удаление и восстановление стенда

Короткая логика:

1. Terraform создаёт и удаляет VM.
2. VM создаются как standalone `vcd_vm`, без явных `vcd_vapp`.
3. Размер root-диска задаётся через `override_template_disk` внутри `vcd_vm`.
4. После создания VM Ansible настраивает ОС и сервисы.

## Полностью удалить стенд и развернуть заново

Снести старый стенд и поднять новый:

```bash
terraform plan -destroy
terraform destroy
terraform apply
```

После `apply` дождись SSH:

```bash
ssh -p 2201 ubuntu@185.98.82.7 'hostname; uptime' # nextcloud-01
ssh -p 2202 ubuntu@185.98.82.7 'hostname; uptime' # nextcloud-02
ssh -p 2213 ubuntu@185.98.82.7 'hostname; uptime' # postgres-primary
ssh -p 2214 ubuntu@185.98.82.7 'hostname; uptime' # postgres-replica
ssh -p 2215 ubuntu@185.98.82.7 'hostname; uptime' # services-1
```

Потом настрой весь стенд:

```bash
cd ../ansible
export GRAFANA_SMTP_PASSWORD="google-app-password-без-пробелов"
ansible-playbook -i inventory.ini site.yml
```

Проверки:

```bash
curl -kI --resolve nextcloud.local:443:185.98.82.7 https://nextcloud.local/
ssh -p 2215 ubuntu@185.98.82.7 'docker ps'
```

## Удалить и создать одну VM

Теперь root-диск отдельно указывать не надо. Указываем только VM target.

### nextcloud-01

```bash
cd Project/terraform
VM='module.nextcloud_cluster.vcd_vm.node["nextcloud-01"]'

terraform destroy -target="$VM"
terraform apply -target="$VM"

cd ../ansible
ansible-playbook -i inventory.ini recover.yml --limit nextcloud-01
```

### nextcloud-02

```bash
cd Project/terraform
VM='module.nextcloud_cluster.vcd_vm.node["nextcloud-02"]'

terraform destroy -target="$VM"
terraform apply -target="$VM"

cd ../ansible
ansible-playbook -i inventory.ini recover.yml --limit nextcloud-02
```

### postgres-replica

```bash
cd Project/terraform
VM='module.postgres_cluster.vcd_vm.node["postgres-replica"]'

terraform destroy -target="$VM"
terraform apply -target="$VM"

cd ../ansible
ansible-playbook -i inventory.ini recover.yml --limit postgres-replica
```

Replica пересобирается с primary через `pg_basebackup`.

### postgres-primary

Если жива `postgres-replica`, сначала делаем failover:

```bash
ssh -p 2214 ubuntu@185.98.82.7 \
  'sudo -u postgres psql -c "SELECT pg_promote(true, 60);"'
```

Переключаем Nextcloud на новый primary:

```bash
cd Project/ansible
ansible-playbook -i inventory.ini site.yml \
  --limit nextcloud \
  --tags nextcloud \
  -e postgres_primary_host=192.168.46.14
```

Потом создаём старую primary заново:

```bash
cd ../terraform
VM='module.postgres_cluster.vcd_vm.node["postgres-primary"]'

terraform destroy -target="$VM"
terraform apply -target="$VM"
```

И поднимаем её как replica от нового primary:

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

Коротко для собеседования: при потере primary не восстанавливаем его из воздуха, а переключаемся на replica, потом пересоздаём старый primary и подключаем его обратно как replica.

### services-1

```bash
cd Project/terraform
VM='module.services_node.vcd_vm.this'

terraform destroy -target="$VM"
terraform apply -target="$VM"

cd ../ansible
export GRAFANA_SMTP_PASSWORD="google-app-password-без-пробелов"
ansible-playbook -i inventory.ini recover.yml --limit services-1
```

## Что говорить на собеседовании

VM пересоздаётся Terraform-командой:

```bash
terraform destroy -target="$VM"
terraform apply -target="$VM"
```

Root-диск не отдельный Terraform-ресурс. Размер root-диска задаётся в VM через `override_template_disk`.

После этого Ansible восстанавливает конфигурацию:

```bash
ansible-playbook -i inventory.ini recover.yml --limit <host>
```
