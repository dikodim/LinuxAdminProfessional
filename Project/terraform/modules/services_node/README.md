# services_node

Каркас общей internal service-VM для:

- `Prometheus`
- `Grafana`
- `VictoriaLogs`
- `node_exporter`, `postgres_exporter`, `blackbox_exporter`
- backup-задач
- `NFS`

Базовая идея:

- VM создаётся Terraform-модулем
- сервисы на ней поднимаются через `docker-compose`
- `NFS` остаётся host-level сервисом, если так удобнее
