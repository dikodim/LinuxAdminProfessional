# Домашнее задание: Сценарии iptables

## Цель
Настроить port knocking для SSH, проброс порта через inetRouter2 и публикацию nginx с centralServer.

---

## Текст задания

1. Реализовать **knocking port** — centralRouter может подключиться по SSH к inetRouter через knock-скрипт.
2. Добавить **inetRouter2**, видимый с хоста через host-only сеть (192.168.56.40).
3. Запустить **nginx** на centralServer.
4. Пробросить **80-й порт** на inetRouter2:8080 (хост обращается на 192.168.56.40:8080).
5. Дефолтный маршрут в интернет оставить через inetRouter.

**Задание со звёздочкой**: реализовать проброс 80-го порта без маскарадинга.

---

## Схема сети

```
Internet
    |
[inetRouter] 192.168.255.1/30 ← SSH заблокирован, открывается knock-скриптом
    | router-net (192.168.255.0/30)
[centralRouter] 192.168.255.2/30
    |--- dir-net (192.168.0.0/28)
    |        |--- centralServer 192.168.0.2  ← nginx на порту 80
    |        |--- inetRouter2   192.168.0.3  ← DNAT 8080→centralServer:80
    |             192.168.56.40/24 (host-only, виден с хоста)
    |--- office1-central (192.168.255.8/30) → office1Router → office1Server
    |--- office2-central (192.168.255.4/30) → office2Router → office2Server
```

---

## Таблица адресации

| Server        | Interface | IP/Mask              | Сеть           |
|---------------|-----------|----------------------|----------------|
| inetRouter    | eth0      | DHCP (NAT VirtualBox)|                |
|               | enp0s8    | 192.168.255.1/30     | router-net     |
|               | enp0s19   | 192.168.56.10/24     | management     |
| inetRouter2   | eth0      | DHCP (NAT VirtualBox)|                |
|               | enp0s8    | 192.168.0.3/28       | dir-net        |
|               | enp0s19   | 192.168.56.40/24     | host-only      |
| centralRouter | enp0s8    | 192.168.255.2/30     | router-net     |
|               | enp0s9    | 192.168.0.1/28       | dir-net        |
|               | enp0s10   | 192.168.0.33/28      | hw-net         |
|               | enp0s16   | 192.168.0.65/26      | mgt-net        |
|               | enp0s17   | 192.168.255.9/30     | office1-central|
|               | enp0s18   | 192.168.255.5/30     | office2-central|
|               | enp0s19   | 192.168.56.11/24     | management     |
| centralServer | enp0s8    | 192.168.0.2/28       | dir-net        |
|               | enp0s19   | 192.168.56.12/24     | management     |

---

## Особенности реализации

### Port Knocking (inetRouter)
- **knockd** слушает на `enp0s8` (интерфейс в сторону centralRouter)
- Knock-последовательность: `7000 → 8000 → 9000` (TCP SYN)
- По умолчанию iptables: `INPUT DROP` — SSH на enp0s8 заблокирован
- После правильной последовательности knockd добавляет временное правило `ACCEPT` для SSH с IP клиента
- Закрыть обратно: обратная последовательность `9000 → 8000 → 7000`
- SSH с management-сети (enp0s19, 192.168.56.x) всегда открыт — для работы Ansible

### inetRouter2 — проброс порта
- Находится в той же подсети dir-net, что и centralServer (192.168.0.0/28)
- Принимает трафик на порт 8080 через host-only интерфейс (192.168.56.40)
- `PREROUTING DNAT`: 192.168.56.40:8080 → 192.168.0.2:80
- `POSTROUTING MASQUERADE`: centralServer видит inetRouter2 (192.168.0.3) как источник и отвечает напрямую (без routing через centralRouter)
- Дефолтный маршрут в интернет идёт через собственный eth0 (VirtualBox NAT)

### Дефолт в интернет через inetRouter
- centralRouter и все серверы имеют default route через 192.168.255.1 (inetRouter)
- inetRouter2 не участвует в транзитной маршрутизации для остальных VM

### Задание со звёздочкой — без маскарадинга
Вместо MASQUERADE: добавить на centralServer маршрут обратно к host-only подсети через inetRouter2:
```bash
ip route add 192.168.56.0/24 via 192.168.0.3
```
Тогда centralServer отвечает напрямую на хост через inetRouter2, MASQUERADE не нужен.

---

## Проверка

```bash
# Port knocking: с centralRouter выбить SSH на inetRouter
vagrant ssh centralRouter
/usr/local/bin/knock_open.sh
ssh vagrant@192.168.255.1

# Проброс порта: с хоста (или любой VM в 192.168.56.0/24)
curl http://192.168.56.40:8080
# Должен ответить nginx с centralServer

# nginx работает
vagrant ssh centralServer
curl http://localhost
```
