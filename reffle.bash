#!/bin/bash

# Скрипт с меню выбора для Ubuntu
# Автор: (ваше имя)
# Версия: 1.0

# Функция для вывода заголовка
show_header() {
    clear
    echo "========================================="
    echo "         Управление системой Ubuntu        "
    echo "========================================="
    echo
}

# Функция для паузы (ожидание нажатия Enter)
pause() {
    echo
    echo "Нажмите Enter, чтобы продолжить..."
    read -r
}

# Функция для пункта 1: информация о системе
system_info() {
    show_header
    echo "--- ИНФОРМАЦИЯ О СИСТЕМЕ ---"
    echo "Дистрибутив: $(lsb_release -ds)"
    echo "Ядро: $(uname -r)"
    echo "Архитектура: $(uname -m)"
    echo "Загрузка: $(uptime -p)"
    echo "Память:"
    free -h
    pause
}

# Функция для пункта 2: список активных служб
list_services() {
    show_header
    echo "--- АКТИВНЫЕ СЛУЖБЫ (systemd) ---"
    systemctl list-units --type=service --state=running --no-pager | head -n 20
    echo
    echo "Показаны первые 20 служб. Полный список можно посмотреть командой 'systemctl'."
    pause
}

# Функция для пункта 3: проверка дискового пространства
disk_usage() {
    show_header
    echo "--- ИСПОЛЬЗОВАНИЕ ДИСКА ---"
    df -h
    pause
}

# Функция для пункта 4: обновление системы (требует sudo)
update_system() {
    show_header
    echo "--- ОБНОВЛЕНИЕ СИСТЕМЫ ---"
    echo "Для обновления требуются права суперпользователя."
    echo "Будут выполнены: sudo apt update && sudo apt upgrade -y"
    echo
    read -p "Продолжить? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo apt update && sudo apt upgrade -y
    else
        echo "Обновление отменено."
    fi
    pause
}

# Функция для пункта 5: выход
exit_script() {
    echo "Выход из скрипта. До свидания!"
    exit 0
}

# Основной цикл меню
while true; do
    show_header
    echo "Выберите один из пунктов меню:"
    echo
    PS3="Ваш выбор (введите номер): "
    options=("Информация о системе" "Список активных служб" "Использование дисков" "Обновить систему" "Выход")
    select opt in "${options[@]}"; do
        case $opt in
            "Информация о системе")
                system_info
                break
                ;;
            "Список активных служб")
                list_services
                break
                ;;
            "Использование дисков")
                disk_usage
                break
                ;;
            "Обновить систему")
                update_system
                break
                ;;
            "Выход")
                exit_script
                ;;
            *)
                echo "Неверный выбор. Пожалуйста, выберите номер от 1 до ${#options[@]}."
                ;;
        esac
    done
done
