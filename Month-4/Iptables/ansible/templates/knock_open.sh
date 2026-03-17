#!/bin/bash
# Скрипт port knocking для открытия SSH на inetRouter
# Запускать на centralRouter перед SSH-подключением к 192.168.255.1

TARGET="192.168.255.1"
KNOCK_PORTS="7000 8000 9000"

echo "Отправляем knock-последовательность на ${TARGET}..."

for port in $KNOCK_PORTS; do
    # Открываем TCP-соединение (генерирует SYN-пакет, который видит knockd)
    (echo "" > /dev/tcp/$TARGET/$port) 2>/dev/null || true
    sleep 0.3
done

echo "Готово. SSH открыт на 30 секунд. Подключение:"
echo "  ssh vagrant@${TARGET}"
