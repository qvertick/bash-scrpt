#!/bin/bash
echo "Создаю 3 файла..."
touch file1.txt file2.txt file3.txt

if [ -f "file1.txt" ]; then
    echo "Файлы созданы."
else
    echo "Что-то пошло не так..."
fi

for file in *.txt; do
    if [ "$file" = "file2.txt" ]; then
        continue
    fi

    # Выводим имя конкретного файла, который сейчас обрабатывается:
    echo "Проверил файл: $file"
done
