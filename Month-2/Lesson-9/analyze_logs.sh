#!/bin/bash
# Отчёт по логам Nginx за последний час

SMTP_HOST="10.18.19.2"
SMTP_PORT="2525"
MAIL_FROM="report@yourhost.example.com"
EMAIL="admin@example.com"

LOG_FILE="/var/log/nginx/first-access.log"
REPORT_DIR="/tmp/nginx_reports"
REPORT_FILE="$REPORT_DIR/report_$(date '+%Y-%m-%d_%H-%M-%S').txt"
LOCK_FILE="/tmp/analyze_logs.lock"

mkdir -p "$REPORT_DIR"

# --- Защита от двойного запуска ---
exec 200>"$LOCK_FILE"
flock -n 200 || { echo "Скрипт уже запущен."; exit 1; }

# --- Очистка при выходе ---
trap 'rm -f "$LOCK_FILE"; exit' INT TERM EXIT

# --- Временные рамки ---
END_TIME=$(date '+%d/%b/%Y:%H:%M:%S')
START_TIME=$(date -d "1 hour ago" '+%d/%b/%Y:%H:%M:%S')

# --- Извлекаем логи только за последний час ---
TMP_LOG="/tmp/new_logs.txt"
awk -v start="$START_TIME" -v end="$END_TIME" '
  {
    # Формат даты в логе [09/Oct/2025:13:51:39
    gsub(/^\[/, "", $4);
    if ($4 >= start && $4 <= end) print;
  }
' "$LOG_FILE" > "$TMP_LOG"

# Проверяем, есть ли данные
if [[ ! -s "$TMP_LOG" ]]; then
  echo "Нет данных за последний час ($START_TIME — $END_TIME)" > "$REPORT_FILE"
else
  {
    echo "Отчёт по логам Nginx за период:"
    echo "$START_TIME — $END_TIME"
    echo "============================================="
    echo

    echo "🔹 Топ-10 IP-адресов:"
    awk '{print $1}' "$TMP_LOG" | sort | uniq -c | sort -nr | head -10
    echo

    echo "🔹 Топ-10 запрашиваемых URL:"
    awk '{print $7}' "$TMP_LOG" | sort | uniq -c | sort -nr | head -10
    echo

    echo "🔹 Ошибки (4xx и 5xx):"
    awk '$9 ~ /^[45]/' "$TMP_LOG" | awk '{print $9}' | sort | uniq -c | sort -nr
    echo

    echo "🔹 HTTP-коды ответов:"
    awk '{print $9}' "$TMP_LOG" | sort | uniq -c | sort -n
    echo

    echo "============================================="
    echo "Отчёт сформирован: $(date)"
  } > "$REPORT_FILE"
fi

# --- Удаление старых отчётов старше 7 дней ---
find "$REPORT_DIR" -type f -mtime +7 -delete

# --- Отправка письма ---
send_mail_via_curl() {
  local to="$1"
  local subject="$2"
  local bodyfile="$3"

  if ! curl --version 2>/dev/null | grep -qi smtp; then
    echo "curl без поддержки SMTP. Используй python-вариант."
    return 2
  fi

  curl -s --url "smtp://${SMTP_HOST}:${SMTP_PORT}" \
       --mail-from "${MAIL_FROM}" \
       --mail-rcpt "${to}" \
       -T <({
         echo "From: ${MAIL_FROM}"
         echo "To: ${to}"
         echo "Subject: ${subject}"
         echo
         echo "Content-Type: text/plain; charset=utf-8"
         echo
         sed 's/\r$//' "$bodyfile"
       }) \
       --silent --show-error
}

send_mail_via_curl "$EMAIL" "Nginx Log Report: $START_TIME — $END_TIME" "$REPORT_FILE"