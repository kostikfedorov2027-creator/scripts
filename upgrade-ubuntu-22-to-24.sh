#!/bin/bash
# Скрипт для обновления Ubuntu 22.04 LTS до 24.04 LTS
# ВНИМАНИЕ: Процесс требует ручного вмешательства и не может быть отменён после запуска!

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}==================================================${NC}"
echo -e "${YELLOW}   Обновление Ubuntu 22.04 LTS -> 24.04 LTS${NC}"
echo -e "${YELLOW}==================================================${NC}"

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Запустите с sudo: sudo $0${NC}"
   exit 1
fi

# Проверка текущей версии
CURRENT_VERSION=$(lsb_release -rs)
if [[ "$CURRENT_VERSION" != "22.04" ]]; then
    echo -e "${RED}❌ Текущая версия Ubuntu: $CURRENT_VERSION${NC}"
    echo -e "${RED}   Скрипт предназначен только для Ubuntu 22.04 LTS${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Текущая версия: Ubuntu $CURRENT_VERSION LTS${NC}"

# Проверка свободного места (рекомендуется минимум 5 ГБ)[reference:0]
FREE_SPACE=$(df / | awk 'NR==2 {print $4}')
FREE_SPACE_GB=$((FREE_SPACE / 1024 / 1024))
if [[ $FREE_SPACE_GB -lt 5 ]]; then
    echo -e "${RED}❌ Недостаточно свободного места: ${FREE_SPACE_GB}ГБ (нужно минимум 5ГБ)${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Свободного места: ${FREE_SPACE_GB}ГБ${NC}"

# ПРедупреждение о резервном копировании
echo -e "${YELLOW}⚠️  ВАЖНО: Перед обновлением рекомендуется создать резервную копию системы!${NC}"
echo -e "${YELLOW}   Для виртуальной машины — сделайте снапшот.${NC}"
echo -e "${YELLOW}   Для физического сервера — используйте Timeshift или другие средства.${NC}"
read -p "Продолжить обновление? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Обновление отменено."
    exit 0
fi

# 1. Обновление текущей системы
echo -e "${GREEN}📦 Шаг 1: Обновление пакетов текущей системы...${NC}"
apt update
apt upgrade -y
apt dist-upgrade -y
apt autoremove -y
apt autoclean -y[reference:1]

# Проверка необходимости перезагрузки после обновления ядра
if [[ -f /var/run/reboot-required ]]; then
    echo -e "${YELLOW}⚠️  Требуется перезагрузка для применения обновлений ядра.${NC}"
    read -p "Перезагрузить сейчас? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Перезагрузка..."
        reboot
        exit 0
    else
        echo -e "${YELLOW}⚠️  Перезагрузка отложена. Рекомендуется перезагрузиться перед обновлением до 24.04.${NC}"
    fi
fi

# 2. Установка update-manager-core
echo -e "${GREEN}📦 Шаг 2: Установка update-manager-core...${NC}"
apt install -y update-manager-core[reference:2]

# 3. Настройка /etc/update-manager/release-upgrades
echo -e "${GREEN}📦 Шаг 3: Настройка параметров обновления...${NC}"
RELEASE_UPGRADES="/etc/update-manager/release-upgrades"
if grep -q "^Prompt=" "$RELEASE_UPGRADES"; then
    sed -i 's/^Prompt=.*/Prompt=lts/' "$RELEASE_UPGRADES"
else
    echo "Prompt=lts" >> "$RELEASE_UPGRADES"
fi
echo -e "${GREEN}✅ Установлено Prompt=lts${NC}"[reference:3]

# 4. Запуск обновления
echo -e "${GREEN}🚀 Шаг 4: Запуск обновления до Ubuntu 24.04 LTS...${NC}"
echo -e "${YELLOW}⚠️  ВНИМАНИЕ:${NC}"
echo -e "   - Процесс требует ручного подтверждения на нескольких этапах[reference:4]"
echo -e "   - При SSH-подключении будет запущен дополнительный SSH-демон на порту 1022[reference:5]"
echo -e "   - После запуска процесс НЕЛЬЗЯ отменить[reference:6]"
echo -e "   - Обновление может занять продолжительное время"
read -p "Начать обновление? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Обновление отменено."
    exit 0
fi

# Запуск do-release-upgrade
do-release-upgrade

# Проверка результата
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Обновление завершено успешно!${NC}"
    echo -e "${YELLOW}⚠️  Требуется перезагрузка для применения изменений.${NC}"
    read -p "Перезагрузить сейчас? (y/N): " -n 1 -r
    echo""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    else
        echo -e "${YELLOW}⚠️  Перезагрузка отложена. Выполните 'sudo reboot' позже.${NC}"
    fi
else
    echo -e "${RED}❌ Ошибка при обновлении. Проверьте логи.${NC}"
    exit 1
fi
