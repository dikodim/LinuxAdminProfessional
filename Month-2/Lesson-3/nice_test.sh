#!/usr/bin/env bash

LOGFILE="nice_test.log"
echo "=== TEST STARTED $(date) ===" | tee "$LOGFILE"

# Более эффективная CPU-нагрузка
cpu_load() {
    local count=0
    for ((i=0; i<1000000; i++)); do
        count=$((count + i))
    done
    echo $count > /dev/null
}

export -f cpu_load

echo "Запускаю тест..." | tee -a "$LOGFILE"

# Запускаем процессы и сразу замеряем время старта
START1=$(date +%s.%N)
nice -n 0 bash -c 'for i in {1..50}; do cpu_load; done' &
PID1=$!

START2=$(date +%s.%N)  
nice -n 10 bash -c 'for i in {1..50}; do cpu_load; done' &
PID2=$!

echo "PID1: $PID1, PID2: $PID2" | tee -a "$LOGFILE"
echo "Ожидаю завершения процессов..." | tee -a "$LOGFILE"

wait $PID1
END1=$(date +%s.%N)

wait $PID2
END2=$(date +%s.%N)

TIME1=$(echo "$END1 - $START1" | bc)
TIME2=$(echo "$END2 - $START2" | bc)

echo "" | tee -a "$LOGFILE"
echo "--- Результаты ---" | tee -a "$LOGFILE"
echo "Процесс nice 0  завершился за:  $TIME1 сек" | tee -a "$LOGFILE"
echo "Процесс nice 10 завершился за:  $TIME2 сек" | tee -a "$LOGFILE"

DIFF=$(echo "$TIME2 - $TIME1" | bc)
echo "Разница (nice10 - nice0): $DIFF сек" | tee -a "$LOGFILE"

echo "=== TEST FINISHED $(date) ===" | tee -a "$LOGFILE"