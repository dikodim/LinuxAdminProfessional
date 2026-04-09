# Infrastructure Scheme

Проект поднимает стенд из двух изолированных сетей:

- `192.168.36.0/24` — DMZ для фронтенд-узлов Nextcloud
- `192.168.46.0/24` — Internal для БД, мониторинга и служебных сервисов

Роль маршрутизатора и фильтрации трафика выполняет `firewall`.

## Scheme

```text
                          Vagrant host / NAT
                                  |
                             [ firewall ]
                     DMZ 192.168.36.1 | 192.168.46.1 Internal
                            /                         \
                           /                           \
             DMZ 192.168.36.0/24               Internal 192.168.46.0/24
              |         |         |              |          |          |
              |         |         |              |          |          |
      VIP 192.168.36.10 |         |      postgres-1   postgres-2   monitor
              |         |         |      192.168.46.13 192.168.46.14 192.168.46.15
         nextcloud-1  nextcloud-2 spare
         192.168.36.11 192.168.36.12 DMZ: 192.168.36.16
                                       INT: 192.168.46.16
```

`VIP 192.168.36.10` плавает между `nextcloud-1` и `nextcloud-2` через `keepalived`.

## Hosts

| Host | IP | Назначение | Роли / сервисы |
| --- | --- | --- | --- |
| `firewall` | `192.168.36.1`, `192.168.46.1` | Маршрутизация между DMZ и Internal, фильтрация трафика | `firewall` (`nftables`, IP forwarding) |
| `nextcloud-1` | `192.168.36.11` | Основной frontend/backend узел Nextcloud в DMZ | `docker`, `certs`, `nfs(client)`, `nextcloud`, `keepalived` MASTER, `zabbix(agent)`, `rsyslog(client)` |
| `nextcloud-2` | `192.168.36.12` | Резервный узел Nextcloud в DMZ | `docker`, `certs`, `nfs(client)`, `nextcloud`, `keepalived` BACKUP, `zabbix(agent)`, `rsyslog(client)` |
| `postgres-1` | `192.168.46.13` | Primary PostgreSQL для Nextcloud | `docker`, `postgres(primary)`, `backup`, `zabbix(agent)`, `rsyslog(client)` |
| `postgres-2` | `192.168.46.14` | Replica PostgreSQL | `docker`, `postgres(replica)`, `zabbix(agent)`, `rsyslog(client)` |
| `monitor` | `192.168.46.15` | Центр служебных сервисов | `docker`, `nfs(server)`, `zabbix(server)`, `rsyslog(server)` |
| `spare` | `192.168.36.16`, `192.168.46.16` | Универсальный запасной хост для быстрого разворота профиля любого существующего узла | По умолчанию без ролей, профиль разворачивается через `ansible/spare.yml` |

## Spare Host

`spare` не включен в основной `ansible/playbook.yml`, поэтому не участвует в базовом разворачивании стенда и не влияет на рабочие узлы.

## Rebuild Any Host

Для полного пересоздания любой VM с нуля используй:

```bash
bash rebuild-node.sh firewall
bash rebuild-node.sh nextcloud-1
bash rebuild-node.sh nextcloud-2
bash rebuild-node.sh postgres-1
bash rebuild-node.sh postgres-2
bash rebuild-node.sh monitor
```

Что делает скрипт:

- удаляет выбранную VM через `vagrant destroy -f`
- поднимает её заново через `vagrant up --no-provision`
- активирует локальный `.venv`
- накатывает только нужный хост через `ansible-playbook --limit`

Для `postgres-2` скрипт автоматически добавляет `postgres_force_resync=true`, чтобы реплика могла заново синхронизироваться с primary.

Поднять запасной хост:

```bash
vagrant up spare
```

Накатить на него профиль существующего узла:

```bash
ansible-playbook -i ansible/inventory.ini ansible/spare.yml -e spare_profile=nextcloud
ansible-playbook -i ansible/inventory.ini ansible/spare.yml -e spare_profile=monitor
ansible-playbook -i ansible/inventory.ini ansible/spare.yml -e spare_profile=postgres-primary
ansible-playbook -i ansible/inventory.ini ansible/spare.yml -e spare_profile=postgres-replica
ansible-playbook -i ansible/inventory.ini ansible/spare.yml -e spare_profile=firewall
```

Доступные значения `spare_profile`:

- `nextcloud`
- `monitor`
- `postgres-primary`
- `postgres-replica`
- `firewall`

Для профиля `nextcloud` можно при необходимости переопределить VRRP-параметры:

```bash
ansible-playbook -i ansible/inventory.ini ansible/spare.yml \
  -e spare_profile=nextcloud \
  -e spare_keepalived_state=BACKUP \
  -e spare_keepalived_priority=90
```

Для полного пересоздания `spare` с нужным профилем:

```bash
bash rebuild-node.sh spare nextcloud
bash rebuild-node.sh spare monitor
bash rebuild-node.sh spare postgres-primary
bash rebuild-node.sh spare postgres-replica
bash rebuild-node.sh spare firewall
```

Для профиля `postgres-replica` по умолчанию включен `postgres_force_resync=true`, чтобы запасная нода сразу могла синхронизироваться с primary.

Если `spare` должен не просто получить роль, а именно заменить рабочий узел в прод-схеме, то для зависимых сервисов может понадобиться дополнительное переключение:

- для `monitor` нужно перевести клиентов на новый `nfs_server` / `zabbix_server` / `rsyslog_server`
- для `postgres-primary` нужно перенаправить приложения и реплику на новый primary
- для `firewall` профиль уже использует `spare_dmz_ip` и `spare_internal_ip` как адреса нового шлюза

## PostgreSQL Failover

Для ручного failover на реплику через Ansible:

```bash
ansible-playbook -i ansible/inventory.ini ansible/failover-postgres.yml
```

Playbook:

- выполняет `pg_promote()` на `postgres-2`
- ждёт, пока `postgres-2` выйдет из recovery
- перекатывает `nextcloud-1` и `nextcloud-2`, чтобы они ходили уже на новый primary
- обновляет `ansible/group_vars/all.yml`, чтобы следующий `provision` не вернул старый primary

Проверка после failover:

```bash
vagrant ssh postgres-2 -c "sudo docker exec postgres psql -U postgres -c 'select pg_is_in_recovery();'"
vagrant ssh nextcloud-1 -c "sudo docker exec nextcloud bash -lc 'PGPASSWORD=nextcloudpassword psql -h 192.168.46.14 -U nextcloud -d nextcloud -p 5432 -c \"select 1;\"'"
```

## PostgreSQL Restore From Replica

Если нужно восстановить `nextcloud`-базу на `postgres-1` из живой `postgres-2`, используй:

```bash
ansible-playbook -i ansible/inventory.ini ansible/restore-postgres-from-replica.yml
```

Playbook:

- делает `pg_dump` на `postgres-2`
- переносит дамп на control host
- пересоздаёт базу `nextcloud` на `postgres-1`
- восстанавливает туда данные из реплики

Это playbook именно для восстановления приложения из живой replica. Для failover без restore используй `ansible/failover-postgres.yml`.

## PostgreSQL Monitoring In Zabbix

На `postgres-1` и `postgres-2` роль автоматически:

- ставит `zabbix-agent2-plugin-postgresql`
- создаёт пользователя БД `zbx_monitor`
- выдаёт ему роль `pg_monitor`
- разрешает доступ в `pg_hba.conf`

Для этих хостов в Zabbix используй шаблон `PostgreSQL by Zabbix agent 2` и задай макросы:

```text
{$PG.URI}=tcp://127.0.0.1:5432
{$PG.USER}=zbx_monitor
{$PG.PASSWORD}=zbx_monitor_password
{$PG.DATABASE}=postgres
```

Если у хоста уже висит старый шаблон `PostgreSQL by Zabbix agent`, его лучше снять и заменить на `PostgreSQL by Zabbix agent 2`.
