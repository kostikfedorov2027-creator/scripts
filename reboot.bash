#!/bin/bash

set -e

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Запустите с sudo: sudo $0"
   exit 1
fi

echo "🔍 Проверка установки cron..."

# Проверяем, установлен ли пакет cron
if ! dpkg -l | grep -q "^ii  cron "; then
    echo "📦 cron не найден. Устанавливаем..."
    apt update
    apt install -y cron
    echo "✅ cron установлен."
else
    echo "✅ cron уже установлен."
fi

# Убеждаемся, что сервис запущен и добавлен в автозагрузку
if systemctl is-active --quiet cron; then
    echo "✅ Сервис cron уже запущен."
else
    echo "🔄 Запускаем сервис cron..."
    systemctl enable cron
    systemctl start cron
    echo "✅ Сервис cron запущен."
fi

# Время: 4:00 утра
MINUTE=0
HOUR=4

echo "🕒 Добавляем задание в crontab..."

# Удаляем предыдущие записи о перезагрузке (чтобы избежать дублирования)
crontab -l 2>/dev/null | grep -v "/sbin/reboot" | crontab - 2>/dev/null || true

# Добавляем новое задание
(crontab -l 2>/dev/null; echo "$MINUTE $HOUR * * * /sbin/reboot") | crontab -

echo "✅ Готово! Перезагрузка будет выполняться каждый день в $HOUR:$MINUTE."
echo "Проверить задания можно командой: sudo crontab -l"