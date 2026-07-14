#!/bin/bash

# --------------------------------------------------
#  Цвета ANSI
# --------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m' # No Color

# --------------------------------------------------
#  Функция для центрирования текста по ширине терминала
# --------------------------------------------------
center() {
    local text="$1"
    local width=$(tput cols)
    local padding=$(( ((width - ${#text})+8) / 2 ))
    printf "%*s%s%*s\n" $padding "" "$text" $padding ""
}

# --------------------------------------------------
#  Отображение красивого меню
# --------------------------------------------------
show_menu() {
    clear
    local width=$(tput cols)
    local line=$(printf "%${width}s" "" | tr ' ' '=')

    # Верхняя рамка
    echo -e "${CYAN}${line}${NC}"
    echo -e "${CYAN}║${NC}  $(center "${BOLD}Сборище скриптов от Reffle${NC}")  ${CYAN}║${NC}"
    echo -e "${CYAN}${line}${NC}"
    echo

    # Пункты с цветными номерами
    echo -e "  ${YELLOW}Система${NC}"
    echo -e "  ${GREEN}1.${NC} Информация о системе"
    echo -e "  ${GREEN}2.${NC} Список активных служб"
    echo -e "  ${GREEN}3.${NC} Использование дисков"
    echo -e "  ${GREEN}4.${NC} Обновить пакеты"
    echo -e "  ${GREEN}5.${RED} Обновить систему до версии UBUNTU 24.04 LTS${NC}"
    echo -e "  ${YELLOW}Тесты${NC}"
    echo -e "  ${GREEN}6.${NC} Цензорчек"
    echo -e "  ${YELLOW}Автоматизация${NC}"
    echo -e "  ${GREEN}7.${NC} Добовление задания для автоперезагрузки"
    echo -e "  ${YELLOW}RemnaWare & RemnaNode${NC}"
    echo -e "  ${GREEN}8.${NC} Перезагрузка ноды Remnaware"
    echo
    echo -e "  ${RED}0.${NC} Выход"
    echo
    echo -e "${CYAN}${line}${NC}"
    echo
}

# --------------------------------------------------
#  Функции для каждого пункта
# --------------------------------------------------
info() {
    clear
    echo -e "${BOLD}${BLUE}--- ИНФОРМАЦИЯ О СИСТЕМЕ ---${NC}"
    echo -e "${YELLOW}Дистрибутив:${NC} $(lsb_release -ds)"
    echo -e "${YELLOW}Ядро:${NC} $(uname -r)"
    echo -e "${YELLOW}Архитектура:${NC} $(uname -m)"
    echo -e "${YELLOW}Время работы:${NC} $(uptime -p)"
    echo -e "${YELLOW}Память:${NC}"
    free -h
}

services() {
    clear
    echo -e "${BOLD}${BLUE}--- АКТИВНЫЕ СЛУЖБЫ (первые 20) ---${NC}"
    systemctl list-units --type=service --state=running --no-pager | head -n 20
}

disk() {
    clear
    echo -e "${BOLD}${BLUE}--- ИСПОЛЬЗОВАНИЕ ДИСКОВ ---${NC}"
    df -h
}

update_packages() {
    clear
    echo -e "${BOLD}${BLUE}--- ОБНОВЛЕНИЕ ПАКЕТОВ ---${NC}"
    read -p "Выполнить sudo apt update && sudo apt upgrade -y? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo apt update && sudo apt upgrade -y
    else
        echo -e "${YELLOW}Отменено.${NC}"
    fi
}

upgrade_os() {
    wget -O upgrade.sh https://raw.githubusercontent.com/kostikfedorov2027-creator/scripts/refs/heads/main/upgrade-ubuntu-22-to-24.sh && sed -i 's/\bcho\b/echo/g' upgrade.sh && sudo bash upgrade.sh
}

censorship() {
    clear
    echo -e "${BOLD}${MAGENTA}--- ЦЕНЗОРЧЕК ---${NC}"
    wget -qO- censorcheck.tlab.pw | bash
}

crone() {
    wget -qO- https://raw.githubusercontent.com/kostikfedorov2027-creator/scripts/refs/heads/main/reboot.bash | bash
}

restart_remnanode() {
    cd /opt/remnanode && docker compose down && docker compose up -d && docker compose logs -f -t
}

# --------------------------------------------------
#  Пауза с красивым сообщением
# --------------------------------------------------
pause() {
    echo
    echo -e "${CYAN}Нажмите Enter, чтобы продолжить...${NC}"
    read -r
}

# --------------------------------------------------
#  Основной цикл
# --------------------------------------------------
while true; do
    show_menu
    read -p "Ваш выбор (0-8): " choice

    # Очистка ввода от пробелов и проверка
    choice=$(echo "$choice" | tr -d '[:space:]')
    if ! [[ "$choice" =~ ^[0-8]$ ]]; then
        echo -e "${RED}Ошибка: введите число от 0 до 8.${NC}"
        sleep 1
        continue
    fi

    # Выполнение
    case "$choice" in
        1) info ;;
        2) services ;;
        3) disk ;;
        4) update_packages ;;
        5) upgrade_os ;;
        6) censorship ;;
        7) crone ;;
        8) restart_remnanode ;;
        0) echo -e "${GREEN}Покеда!${NC}"; exit 0 ;;
    esac

    pause
done
