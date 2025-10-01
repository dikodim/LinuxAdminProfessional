#!/bin/bash
apt update
apt install -y nfs-kernel-server

ss -tnplu | grep -E '2049|111'

mkdir -p /srv/share/upload
chown -R nobody:nogroup /srv/share
chmod 0777 /srv/share/upload

cat << EOF > /etc/exports
/srv/share 192.168.50.11/32(rw,sync,root_squash)
EOF

exportfs -r

exportfs -s