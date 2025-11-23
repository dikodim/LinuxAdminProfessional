#!/bin/bash

DISK1="/dev/sdb"
DISK2="/dev/sdc"

echo "Форматируем диски в ext4..."
mkfs.ext4 -F $DISK1
mkfs.ext4 -F $DISK2

echo "Создаем точки монтирования..."
mkdir -p /mnt/disk1
mkdir -p /mnt/disk2

echo "Монтируем диски..."
mount $DISK1 /mnt/disk1
mount $DISK2 /mnt/disk2

echo "Добавляем в fstab..."
echo "$DISK1    /mnt/disk1    ext4    defaults    0    2" >> /etc/fstab
echo "$DISK2    /mnt/disk2    ext4    defaults    0    2" >> /etc/fstab

echo "Готово! Проверяем монтирование:"
df -h | grep /mnt/disk