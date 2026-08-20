#!/bin/bash

#написал syslogg с двумя g из за того что у меня рили есть такой файл в системе
echo "FFFFff FdsssS fdsddf" > syslogg.txt

FILE="/var/log/syslogg"

if [ -e "$FILE" ]; then
    echo "Файл найден!"
elif [ -f "syslogg.txt" ]; then
    echo "Файл найден!"
else 
    echo "Файла нету в системе."
    exit 1
fi

tail -n 5 syslogg.txt | tr "a-z" "A-Z" > LOG_$(date +%Y-%m-%d).txt

echo "Скрипт завершен"
exit 0
а это уже не выведется)))
