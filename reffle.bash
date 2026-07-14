#!/bin/bash
while true; do
    clear
    echo "========================================="
    echo "         Управление системой Ubuntu        "
    echo "========================================="
    echo "1. Информация о системе"
    echo "2. Список активных служб"
    echo "3. Использование дисков"
    echo "4. Обновить систему"
    echo "5. Запустить свой скрипт"
    echo "0. Выход"
    echo
    read -p "Ваш выбор (0-5): " choice

    # Удаляем пробелы и проверяем, что введена цифра
    choice=$(echo "$choice" | tr -d '[:space:]')
    if ! [[ "$choice" =~ ^[0-5]$ ]]; then
        echo "Ошибка: введите число от 0 до 5."
        read -p "Нажмите Enter..."
        continue
    fi

    case $choice in
        1) # информация о системе
            clear
            echo "--- ИНФОРМАЦИЯ ---"
            lsb_release -ds
            uname -r
            read -p "Нажмите Enter..."
            ;;
        2) # службы
            clear
            systemctl list-units --type=service --state=running --no-pager | head -n 20
            read -p "Нажмите Enter..."
            ;;
        3) # диски
            clear
            df -h
            read -p "Нажмите Enter..."
            ;;
        4) # обновление
            clear
            sudo apt update && sudo apt upgrade -y
            read -p "Нажмите Enter..."
            ;;
        5) # свой скрипт
            clear
            ./мой_скрипт.sh
            read -p "Нажмите Enter..."
            ;;
        0) echo "Выход."; exit 0 ;;
    esac
done
