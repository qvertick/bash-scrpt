#!/usr/bin/env bash
set -euo pipefail

# цвета для терминала
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
YELLOW_BOLD='\033[1;33m'
BLUE='\033[0;35m'
NC='\033[0m' # Сброс цвета (NoColor)
DARK_GRAY='\033[0;90m'

TARGET="${1:-}"

#==========================================================#

# Если аргумент не передан, спрашиваем пользователя
if [ -z "$TARGET" ]; then
    echo -e "${YELLOW}[?]${NC} Вы не указали путь к файлу или папке. ${DARK_GRAY}(./script.sh ..(файл))${NC}"
    echo -e -n "К какому файлу/папке хотите добавить права?:${YELLOW} "
    read TARGET
fi

# Проверяем снова: если пользователь ничего не ввел и просто нажал Enter
if [ -z "$TARGET" ]; then
    echo -e "${RED}[ERROR] Путь не передан. Завершение работы.${NC}"
    exit 1
fi

# Если по точному совпадению объекта нет — сначала ищем замену
if [ ! -e "$TARGET" ]; then
    echo -e "${RED}[ERROR]${NC} Объект '$TARGET' не найден по точному совпадению!"
    echo -e "${YELLOW}[SEARCH]${NC} Ищу похожие файлы (без учета регистра)..."

    # Ищем файлы с похожим именем в текущей папке
    SUGGESTIONS=$(find . -maxdepth 2 -iname "*$TARGET*" 2>/dev/null)

    if [ -n "$SUGGESTIONS" ]; then
        echo -e "${YELLOW}[?] Возможно, вы имели в виду один из этих файлов:${NC}"

        # Превращаем список в нумерованный массив
        mapfile -t FILE_LIST <<< "$SUGGESTIONS"
        for i in "${!FILE_LIST[@]}"; do
            echo -e "  ${GREEN}$((i+1)))${NC} ${FILE_LIST[$i]}"
        done

        # Красивый цветной запрос номера
        echo -e -n "Введите номер файла (${BLUE}1-${#FILE_LIST[@]}${NC}) или ${RED}0${NC} для отмены: "
        read CHOICE

        # Проверка выбора
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -gt 0 ] && [ "$CHOICE" -le "${#FILE_LIST[@]}" ]; then
            TARGET="${FILE_LIST[$((CHOICE-1))]}"
        else
            echo -e "${RED}[CANCEL]${NC} Операция отменена."
            exit 1
        fi
    else
        echo -e "${RED}[ERROR]${NC} Похожих файлов в ${YELLOW_BOLD}$(pwd)${NC} не найдено."
        exit 1
    fi
fi

# Точка выполнения chmod (вызывается только если файл существует)
if [ -f "$TARGET" ]; then
    echo -e "${GREEN}[CHMOD]${NC} изменяю права для.. ${RED}$TARGET${NC}"
    chmod 755 "$TARGET"
    echo -e "${GREEN}[SUCCESS]${NC} Файл найден и права выставлены!"
elif [ -d "$TARGET" ]; then
    echo -e "${GREEN}[CHMOD]${NC} изменяю права для.. ${RED}$TARGET${NC}"
    chmod -R 755 "$TARGET"
    echo -e "${GREEN}[SUCCESS]${NC} Директория найдена и права выставлены!"
fi

echo ""

echo "Итоговый статус объекта: "
STAT_OUT=$(stat -c "${GREEN}%A ${RED}%U(%u) ${GREEN}%y${NC}" "$TARGET")
echo -e "$STAT_OUT"

# Предлагаем добавить объект в PATH
echo ""
echo -e -n "Хотите добавить этот объект в ${YELLOW}system PATH${NC}, чтобы запускать ${YELLOW_BOLD}отовсюду?${NC} ${BLUE}(y/n)${NC}: "
read ANSWER

if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
    # Спрашиваем имя команды
    echo -e -n "Как хотите назвать команду для запуска? ${RED}(по умолчанию: fixscrpt)${NC}: "
    read SCRIPT_NAME

    SCRIPT_NAME="${SCRIPT_NAME:-fixscrpt}"
    BIN_DIR="$HOME/.local/bin"

    mkdir -p "$BIN_DIR"

    # Создаем симлинк ($TARGET — если делаем ссылку на обработанный файл, $0 — если на сам скрипт)
    ln -sf "$(readlink -f "$TARGET")" "$BIN_DIR/$SCRIPT_NAME"
    echo -e "${GREEN}[SUCCESS]${NC} Симлинк создан в $BIN_DIR/$SCRIPT_NAME"

    # Выбор оболочки
    echo ""
    echo -e "${YELLOW}[?] Какую оболочку используешь?${NC}"
    echo -e "  ${GREEN}1)${NC} Fish"
    echo -e "  ${GREEN}2)${NC} Bash"
    echo -e "  ${GREEN}3)${NC} Zsh"
    echo -e "  ${GREEN}4)${NC} Другая (вывести команду вручную)"
    echo -e -n "Выбери номер (${BLUE}1-4${NC}): "
    read SHELL_CHOICE

    case "$SHELL_CHOICE" in
        1)
            if command -v fish &>/dev/null; then
                fish -c "fish_add_path $BIN_DIR" &>/dev/null
                echo -e "${GREEN}[PATH]${NC} Добавлен путь через ${YELLOW_BOLD}fish_add_path${NC}! Всё сразу работает."
            else
                echo -e "${YELLOW}[PATH]${NC} Добавь строку ${YELLOW_BOLD}fish_add_path $BIN_DIR${NC} в ~/.config/fish/config.fish"
            fi
            ;;
        2)
            if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
                echo -e "${GREEN}[PATH]${NC} Прописал экспорт в ${YELLOW}~/.bashrc${NC}"
            fi
            ;;
        3)
            if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
                echo -e "${GREEN}[PATH]${NC} Прописал экспорт в ${YELLOW}~/.zshrc${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}[PATH]${NC} Для твоей оболочки добавь эту директорию в PATH вручную:"
            echo -e "       ${YELLOW_BOLD}$BIN_DIR${NC}"
            ;;
    esac

    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} Готово! Вызывай команду из любой точки под именем: ${YELLOW_BOLD}$SCRIPT_NAME${NC}"
fi

echo -e "${GREEN}[SUCCESS]${NC} Скрипт успешно выполнен и завершен."
