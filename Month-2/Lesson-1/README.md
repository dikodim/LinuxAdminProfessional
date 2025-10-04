Цель домашнего задания:  
- Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).
- Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).
- Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.


### Задание №1
```bash
[root@OTUS log]# cat <<EOF > /etc/default/otus
WORD="OTUS"
LOG=/var/log/otus.log
EOF

[root@OTUS log]# cat <<EOF > /var/log/otus.log
OTUS
ALERT
ALERt
logs
otUS
OTUS
alert
EOF

[root@OTUS log]# cat <<EOF > /opt/genlog-otus.sh
#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi
EOF

[root@OTUS log]# chmod +x /opt/genlog-otus.sh
[root@OTUS log]# cat <<EOF > /etc/systemd/system/otus.service
[Unit]
Description=My otus service

[Service]
Type=oneshot
EnvironmentFile=/etc/default/otus
ExecStart=/opt/genlog-otus.sh $WORD $LOG
EOF


[root@OTUS log]# cat <<EOF > /etc/systemd/system/otus.timer
[Unit]
Description=Run otus script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=otus.service

[Install]
WantedBy=multi-user.target
EOF

[root@OTUS log]# systemctl enable otus.timer --now
Created symlink /etc/systemd/system/multi-user.target.wants/otus.timer → /etc/systemd/system/otus.timer

[root@OTUS log]# tail /var/log/messages | grep -i word
Oct  4 10:41:21 OTUS root[16776]: Sat Oct  4 10:41:21 UTC 2025: I found word, Master!
Oct  4 10:41:47 OTUS root[16792]: Sat Oct  4 10:41:47 UTC 2025: I found word, Master!
```

### Задание №2
```bash
root@krbrs-server:~# apt install spawn-fcgi php php-cgi php-cli \
 apache2 libapache2-mod-fcgid -y
Setting up apache2-utils (2.4.58-1ubuntu8.8) ...
Setting up php (2:8.3+93ubuntu2) ...
Setting up apache2-bin (2.4.58-1ubuntu8.8) ...
Setting up libapache2-mod-php8.3 (8.3.6-0ubuntu0.24.04.5) ...
Package apache2 is not configured yet. Will defer actions by package libapache2-mod-php8.3.

Creating config file /etc/php/8.3/apache2/php.ini with new version
No module matches
Setting up libapache2-mod-fcgid (1:2.3.9-4) ...
Package apache2 is not configured yet. Will defer actions by package libapache2-mod-fcgid.
Setting up apache2 (2.4.58-1ubuntu8.8) ...
Enabling module mpm_event.
Enabling module authz_core.
Enabling module authz_host.
Enabling module authn_core.
Enabling module auth_basic.
Enabling module access_compat.
Enabling module authn_file.
Enabling module authz_user.
Enabling module alias.
Enabling module dir.
Enabling module autoindex.
Enabling module env.
Enabling module mime.
Enabling module negotiation.
Enabling module setenvif.
Enabling module filter.
Enabling module deflate.
Enabling module status.
Enabling module reqtimeout.
Enabling conf charset.
Enabling conf localized-error-pages.
Enabling conf other-vhosts-access-log.
Enabling conf security.
Enabling conf serve-cgi-bin.
Enabling site 000-default.
info: Switch to mpm prefork for package libapache2-mod-php8.3
Module mpm_event disabled.
Enabling module mpm_prefork.
info: Executing deferred 'a2enmod php8.3' for package libapache2-mod-php8.3
Enabling module php8.3.
info: Executing deferred 'a2enmod fcgid' for package libapache2-mod-fcgid
Enabling module fcgid.
Created symlink /etc/systemd/system/multi-user.target.wants/apache2.service → /usr/lib/systemd/system/apache2.service.
Created symlink /etc/systemd/system/multi-user.target.wants/apache-htcacheclean.service → /usr/lib/systemd/system/apache-htcacheclean.service.
Processing triggers for ufw (0.36.2-6) ...
Processing triggers for man-db (2.12.0-4build2) ...
Processing triggers for libc-bin (2.39-0ubuntu8.6) ...
Processing triggers for php8.3-cli (8.3.6-0ubuntu0.24.04.5) ...
Processing triggers for php8.3-cgi (8.3.6-0ubuntu0.24.04.5) ...
Processing triggers for libapache2-mod-php8.3 (8.3.6-0ubuntu0.24.04.5) ...
Scanning processes...

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
root@krbrs-server:~# mkdir /etc/spawn-fcgi
root@krbrs-server:~# cat <<EOF > /etc/spawn-fcgi/fcgi.conf
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"
EOF

cat <<EOF > /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

root@krbrs-server:~# systemctl start spawn-fcgi
root@krbrs-server:~# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; preset: enabled)
     Active: active (running) since Sat 2025-10-04 11:01:31 UTC; 48min ago
   Main PID: 12304 (php-cgi)
      Tasks: 33 (limit: 2073)
     Memory: 19.1M (peak: 19.3M)
        CPU: 46ms
     CGroup: /system.slice/spawn-fcgi.service
             ├─12304 /usr/bin/php-cgi
             ├─12305 /usr/bin/php-cgi
             ├─12306 /usr/bin/php-cgi
             ├─12307 /usr/bin/php-cgi
             ├─12308 /usr/bin/php-cgi
             ├─12309 /usr/bin/php-cgi
             ├─12310 /usr/bin/php-cgi
             ├─12311 /usr/bin/php-cgi
             ├─12312 /usr/bin/php-cgi
             ├─12313 /usr/bin/php-cgi
             ├─12314 /usr/bin/php-cgi
             ├─12315 /usr/bin/php-cgi
             ├─12316 /usr/bin/php-cgi
             ├─12317 /usr/bin/php-cgi
             ├─12318 /usr/bin/php-cgi
             ├─12319 /usr/bin/php-cgi
             ├─12320 /usr/bin/php-cgi
             ├─12321 /usr/bin/php-cgi
             ├─12322 /usr/bin/php-cgi
             ├─12323 /usr/bin/php-cgi
             ├─12324 /usr/bin/php-cgi
             ├─12325 /usr/bin/php-cgi
             ├─12326 /usr/bin/php-cgi
             ├─12327 /usr/bin/php-cgi
             ├─12328 /usr/bin/php-cgi
             ├─12329 /usr/bin/php-cgi
             ├─12330 /usr/bin/php-cgi
             ├─12331 /usr/bin/php-cgi
             ├─12332 /usr/bin/php-cgi
             ├─12333 /usr/bin/php-cgi
             ├─12334 /usr/bin/php-cgi
             ├─12335 /usr/bin/php-cgi
             └─12336 /usr/bin/php-cgi

Oct 04 11:01:31 krbrs-server systemd[1]: Started spawn-fcgi.service - Spawn-fcgi startup service by Otus.
Oct 04 11:01:50 krbrs-server systemd[1]: /etc/systemd/system/spawn-fcgi.service:7: PIDFile= references a path below legacy directory /var/run/, updating /var/run/spawn-fcgi.pid → /run/spa>
Oct 04 11:01:51 krbrs-server systemd[1]: /etc/systemd/system/spawn-fcgi.service:7: PIDFile= references a path below legacy directory /var/run/, updating /var/run/spawn-fcgi.pid → /run/spa>
Oct 04 11:43:00 krbrs-server systemd[1]: /etc/systemd/system/spawn-fcgi.service:7: PIDFile= references a path below legacy directory /var/run/, updating /var/run/spawn-fcgi.pid → /run/spa

```

### Задание №3
```bash

cat <<EOF > /etc/systemd/system/nginx@.service

# Stop dance for nginx
# =======================
#
# ExecStop sends SIGSTOP (graceful stop) to the nginx process.
# If, after 5s (--retry QUIT/5) nginx is still running, systemd takes control
# and sends SIGTERM (fast shutdown) to the main process.
# After another 5s (TimeoutStopSec=5), and if nginx is alive, systemd sends
# SIGKILL to all the remaining processes in the process group (KillMode=mixed).
#
# nginx signals reference doc:
# http://nginx.org/en/docs/control.html
#
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx-%I.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-%I.conf -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx-%I.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

root@krbrs-server:~# cat /etc/nginx/nginx-first.conf
user www-data;
worker_processes auto;
pid /run/nginx-first.pid;
error_log /var/log/nginx/first-error.log;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
}

http {
        server {
                listen 8081 default_server;
                listen [::]:8081 default_server;
                root /var/www/html;
        ...
        }
    ...
}

root@krbrs-server:~# cat /etc/nginx/nginx-second.conf
user www-data;
worker_processes auto;
pid /run/nginx-second.pid;
error_log /var/log/nginx/second-error.log;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
}

http {
        server {
                listen 8082 default_server;
                listen [::]:8081 default_server;
                root /var/www/html;
        ...
        }
    ...
}

root@krbrs-server:~# vi /etc/nginx/nginx-second.conf
root@krbrs-server:~# nginx -t -c /etc/nginx/nginx-second.conf
nginx: the configuration file /etc/nginx/nginx-second.conf syntax is ok
nginx: configuration file /etc/nginx/nginx-second.conf test is successful
root@krbrs-server:~# vi /etc/nginx/nginx-first.conf
root@krbrs-server:~# nginx -t -c /etc/nginx/nginx-first.conf
nginx: the configuration file /etc/nginx/nginx-first.conf syntax is ok
nginx: configuration file /etc/nginx/nginx-first.conf test is successful

root@krbrs-server:~# systemctl start nginx@first
root@krbrs-server:~# systemctl start nginx@second

root@krbrs-server:~# systemctl is-active nginx@first
active
root@krbrs-server:~# systemctl is-active nginx@second
active

root@krbrs-server:~# ss -ntlp | grep -i nginx
LISTEN 0      511          0.0.0.0:8082      0.0.0.0:*    users:(("nginx",pid=12881,fd=5),("nginx",pid=12880,fd=5),("nginx",pid=12879,fd=5))
LISTEN 0      511          0.0.0.0:8081      0.0.0.0:*    users:(("nginx",pid=12872,fd=5),("nginx",pid=12871,fd=5),("nginx",pid=12870,fd=5))
LISTEN 0      511             [::]:8082         [::]:*    users:(("nginx",pid=12881,fd=6),("nginx",pid=12880,fd=6),("nginx",pid=12879,fd=6))
LISTEN 0      511             [::]:8081         [::]:*    users:(("nginx",pid=12872,fd=6),("nginx",pid=12871,fd=6),("nginx",pid=12870,fd=6))

root@krbrs-server:~# curl -LIk http://localhost:8081
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Sat, 04 Oct 2025 11:51:09 GMT
Content-Type: text/html
Content-Length: 10671
Last-Modified: Sat, 04 Oct 2025 10:54:08 GMT
Connection: keep-alive
ETag: "68e0fcd0-29af"
Accept-Ranges: bytes

root@krbrs-server:~# curl -LIk http://localhost:8082
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Sat, 04 Oct 2025 11:51:11 GMT
Content-Type: text/html
Content-Length: 10671
Last-Modified: Sat, 04 Oct 2025 10:54:08 GMT
Connection: keep-alive
ETag: "68e0fcd0-29af"
Accept-Ranges: bytes

```