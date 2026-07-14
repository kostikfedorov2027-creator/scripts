#!/bin/bash

show_info() {
    echo "--- ИНФОРМАЦИЯ О СИСТЕМЕ ---"
    lsb_release -ds
    uname -r
    uname -m
    uptime -p
    free -h
}

show_services() {
    echo "--- АКТИВНЫЕ СЛУЖБЫ ---"
    systemctl list-units --type=service --state=running --no-pager | head -n 20
}

show_disk() {
    echo "--- ИСПОЛЬЗОВАНИЕ ДИСКА ---"
    df -h
}

update_system() {
    echo "--- ОБНОВЛЕНИЕ СИСТЕМЫ ---"
    read -p "Выполнить sudo apt update && sudo apt upgrade -y? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo apt update && sudo apt upgrade -y
    else
        echo "Отменено."
    fi
}

while true; do
    echo "========================================="
    echo "         Управление системой Ubuntu        "
    echo "========================================="
    echo "1. Информация о системе"
    echo "2. Список активных служб"
    echo "3. Использование дисков"
    echo "4. Обновить систему"
    echo "0. Выход"
    echo
    read -p "Ваш выбор (0-4): " choice

    case $choice in
        1) show_info ;;
        2) show_services ;;
        3) show_disk ;;
        4) update_system ;;
        0) echo "Выход."; exit 0 ;;
        *) echo "Неверный выбор. Попробуйте снова." ;;
    esac

    echo
    read -p "Нажмите Enter, чтобы продолжить..."
    echo
done
