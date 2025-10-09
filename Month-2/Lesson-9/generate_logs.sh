#!/bin/bash
NGINX_URL="http://localhost:8081"    # адрес твоего Nginx
INTERVAL=1                      # интервал между запросами (сек)
REQUESTS=100                    # сколько запросов отправить

# Список тестовых URL
URLS=(
    "/"
    "/index.html"
    "/api/status"
    "/api/data?id=42"
    "/login"
    "/static/css/style.css"
    "/images/logo.png"
    "/docs/manual.pdf"
)

# Список "фейковых" IP для X-Forwarded-For
IPS=(
    "192.168.1.10"
    "10.0.0.25"
    "172.16.5.3"
    "185.22.45.101"
    "77.88.55.22"
    "93.184.216.34"
    "203.0.113.50"
    "198.51.100.77"
)

# Используем trap для аккуратного выхода
trap 'echo "Остановка скрипта..."; exit 0' INT TERM

echo "🚀 Запускаем генерацию запросов к $NGINX_URL ($REQUESTS запросов)..."

for ((i=1; i<=REQUESTS; i++)); do
    # Выбираем случайный URL и IP
    URL=${URLS[$RANDOM % ${#URLS[@]}]}
    IP=${IPS[$RANDOM % ${#IPS[@]}]}

    # С вероятностью 1/5 добавляем ошибочный запрос
    if (( RANDOM % 5 == 0 )); then
        URL="/nonexistent$(date +%s)"
    fi

    # Формируем заголовки
    curl -s -o /dev/null -w "%{http_code} " \
        -H "X-Forwarded-For: $IP" \
        "$NGINX_URL$URL"

    echo "[$i] $IP → $URL"

    sleep "$INTERVAL"
done

echo "✅ Генерация завершена!"