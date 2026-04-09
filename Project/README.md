# Infrastructure Scheme

Проект поднимает стенд в одной приватной сети:

- `192.168.46.0/24` — общая внутренняя сеть для Nextcloud, БД, мониторинга и служебных сервисов

## Scheme

```text
                          Vagrant host / NAT
                                  |
                             [ firewall ]
                          192.168.46.1
                                  |
             ---------------------------------------------------
             |            |            |           |           |
      VIP 192.168.46.10  nextcloud-1  nextcloud-2 postgres-1  postgres-2
             |            192.168.46.11 192.168.46.12 192.168.46.13 192.168.46.14
             |
          monitor
       192.168.46.15

           spare
        192.168.46.16
```

`VIP 192.168.46.10` плавает между `nextcloud-1` и `nextcloud-2` через `keepalived`.

## Hosts

| Host | IP | Назначение | Роли / сервисы |
| --- | --- | --- | --- |
| `firewall` | `192.168.46.1` | Отдельный узел с локальной фильтрацией `nftables` | `firewall` (`nftables`) |
| `nextcloud-1` | `192.168.46.11` | Основной frontend/backend узел Nextcloud | `docker`, `certs`, `nfs(client)`, `nextcloud`, `keepalived` MASTER, `zabbix(agent)`, `rsyslog(client)` |
| `nextcloud-2` | `192.168.46.12` | Резервный узел Nextcloud | `docker`, `certs`, `nfs(client)`, `nextcloud`, `keepalived` BACKUP, `zabbix(agent)`, `rsyslog(client)` |
| `postgres-1` | `192.168.46.13` | Primary PostgreSQL для Nextcloud | `docker`, `postgres(primary)`, `backup`, `zabbix(agent)`, `rsyslog(client)` |
| `postgres-2` | `192.168.46.14` | Replica PostgreSQL | `docker`, `postgres(replica)`, `zabbix(agent)`, `rsyslog(client)` |
| `monitor` | `192.168.46.15` | Центр служебных сервисов | `docker`, `nfs(server)`, `zabbix(server)`, `rsyslog(server)` |
| `spare` | `192.168.46.16` | Универсальный запасной хост для быстрого разворота профиля любого существующего узла | По умолчанию без ролей, профиль разворачивается через `ansible/spare.yml` |

## Spare Host

`spare` не включен в основной `ansible/playbook.yml`, поэтому не участвует в базовом разворачивании стенда и не влияет на рабочие узлы.

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

Для профиля `postgres-replica` по умолчанию включен `postgres_force_resync=true`, чтобы запасная нода сразу могла синхронизироваться с primary.

Если `spare` должен не просто получить роль, а именно заменить рабочий узел в прод-схеме, то для зависимых сервисов может понадобиться дополнительное переключение:

- для `monitor` нужно перевести клиентов на новый `nfs_server` / `zabbix_server` / `rsyslog_server`
- для `postgres-primary` нужно перенаправить приложения и реплику на новый primary
- для `firewall` стоит отдельно согласовать IP-адрес запасного узла и доступ к нему со стороны остальных машин
