#!/bin/bash
# Скрипт для обновления Ubuntu 22.04 LTS до 24.04 LTS
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}==================================================${NC}"
echo -e "${YELLOW}   Обновление Ubuntu 22.04 LTS -> 24.04 LTS${NC}"
echo -e "${YELLOW}==================================================${NC}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Запустите с sudo: sudo $0${NC}"
   exit 1
fi

CURRENT_VERSION=$(lsb_release -rs)
if [[ "$CURRENT_VERSION" != "22.04" ]]; then
    echo -e "${RED}❌ Текущая версия Ubuntu: $CURRENT_VERSION${NC}"
    echo -e "${RED}   Скрипт предназначен только для Ubuntu 22.04 LTS${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Текущая версия: Ubuntu $CURRENT_VERSION LTS${NC}"

FREE_SPACE=$(df / | awk 'NR==2 {print $4}')
FREE_SPACE_GB=$((FREE_SPACE / 1024 / 1024))
if [[ $FREE_SPACE_GB -lt 5 ]]; then
    echo -e "${RED}❌ Недостаточно свободного места: ${FREE_SPACE_GB}ГБ (нужно минимум 5ГБ)${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Свободного места: ${FREE_SPACE_GB}ГБ${NC}"

echo -e "${YELLOW}⚠️  ВАЖНО: Перед обновлением рекомендуется создать резервную копию системы!${NC}"
read -p "Продолжить обновление? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Обновление отменено."
    exit 0
fi

echo -e "${GREEN}📦 Шаг 1: Обновление пакетов текущей системы...${NC}"
apt update
apt upgrade -y
apt dist-upgrade -y
apt autoremove -y
apt autoclean -y

if [[ -f /var/run/reboot-required ]]; then
    echo -e "${YELLOW}⚠️  Требуется перезагрузка для применения обновлений ядра.${NC}"
    read -p "Перезагрузить сейчас? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
        exit 0
    else
        echo -e "${YELLOW}⚠️  Перезагрузка отложена. Рекомендуется перезагрузиться перед обновлением до 24.04.${NC}"
    fi
fi

echo -e "${GREEN}📦 Шаг 2: Установка update-manager-core...${NC}"
apt install -y update-manager-core

echo -e "${GREEN}📦 Шаг 3: Настройка параметров обновления...${NC}"
RELEASE_UPGRADES="/etc/update-manager/release-upgrades"
if grep -q "^Prompt=" "$RELEASE_UPGRADES"; then
    sed -i 's/^Prompt=.*/Prompt=lts/' "$RELEASE_UPGRADES"
else
    echo "Prompt=lts" >> "$RELEASE_UPGRADES"
fi
echo -e "${GREEN}✅ Установлено Prompt=lts${NC}"

echo -e "${GREEN}🚀 Шаг 4: Запуск обновления до Ubuntu 24.04 LTS...${NC}"
echo -e "${YELLOW}⚠️  ВНИМАНИЕ:${NC}"
echo -e "   - Процесс требует ручного подтверждения на нескольких этапах"
echo -e "   - При SSH-подключении будет запущен дополнительный SSH-демон на порту 1022"
echo -e "   - После запуска процесс НЕЛЬЗЯ отменить"
read -p "Начать обновление? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Обновление отменено."
    exit 0
fi

do-release-upgrade

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Обновление завершено успешно!${NC}"
    read -p "Перезагрузить сейчас? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    else
        echo -e "${YELLOW}⚠️  Перезагрузка отложена. Выполните 'sudo reboot' позже.${NC}"
    fi
else
    echo -e "${RED}❌ Ошибка при обновлении. Проверьте логи.${NC}"
    exit 1
fi
