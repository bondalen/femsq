#!/bin/bash
# Скрипт для запуска MS SQL Server
# Поддерживает запуск через Docker или проверку Windows службы

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SA_PASSWORD="${SA_PASSWORD:-kolob_OK1}"
DB_NAME="${DB_NAME:-FishEye}"
PORT="${PORT:-1433}"

echo "=== Запуск MS SQL Server ==="
echo "Порт: $PORT"
echo "База данных: $DB_NAME"
echo ""

# Функция проверки доступности порта
check_port() {
    local port=$1
    if timeout 2 bash -c "cat < /dev/null > /dev/tcp/localhost/$port" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Проверка, запущен ли уже SQL Server
if check_port $PORT; then
    echo "✓ SQL Server уже запущен на порту $PORT"
    exit 0
fi

# Попытка запуска через Docker
if command -v docker &> /dev/null; then
    echo "Попытка запуска через Docker..."
    
    # Проверка существующего контейнера
    if docker ps -a --format '{{.Names}}' | grep -q "^mssql-server$"; then
        echo "Запуск существующего контейнера..."
        docker start mssql-server
    else
        echo "Создание нового контейнера..."
        docker run -d \
            --name mssql-server \
            -e "ACCEPT_EULA=Y" \
            -e "SA_PASSWORD=$SA_PASSWORD" \
            -e "MSSQL_PID=Developer" \
            -p "$PORT:1433" \
            mcr.microsoft.com/mssql/server:2022-latest
    fi
    
    # Ожидание готовности
    echo "Ожидание готовности SQL Server..."
    for i in {1..30}; do
        if check_port $PORT; then
            echo "✓ SQL Server запущен и готов к работе"
            exit 0
        fi
        sleep 2
    done
    
    echo "⚠ SQL Server запущен, но еще не готов (проверьте логи: docker logs mssql-server)"
    exit 0
fi

# Попытка запуска через Windows службу (если доступно)
if command -v wsl.exe &> /dev/null; then
    echo "Попытка запуска через Windows службу..."
    WIN_STATUS=$(wsl.exe -d Ubuntu-24.04 -e bash -c "powershell.exe -Command \"Get-Service -Name '*SQL*' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Status\" 2>&1" | tr -d '\r\n')
    
    if [ "$WIN_STATUS" = "Stopped" ]; then
        echo "Запуск Windows службы SQL Server..."
        wsl.exe -d Ubuntu-24.04 -e bash -c "powershell.exe -Command \"Start-Service MSSQLSERVER\" 2>&1" || true
        sleep 5
        
        if check_port $PORT; then
            echo "✓ SQL Server запущен через Windows службу"
            exit 0
        fi
    elif [ "$WIN_STATUS" = "Running" ]; then
        echo "✓ SQL Server уже запущен на Windows"
        # Проверка доступности через Windows IP
        WIN_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1)
        if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$WIN_IP/$PORT" 2>/dev/null; then
            echo "✓ SQL Server доступен на $WIN_IP:$PORT"
            echo "⚠ Внимание: Обновите DSN в .cursor/mcp.json на $WIN_IP вместо localhost"
            exit 0
        fi
    fi
fi

echo "❌ Не удалось запустить SQL Server"
echo ""
echo "Возможные решения:"
echo "1. Установите Docker Desktop и включите WSL2 интеграцию"
echo "2. Установите SQL Server на Windows и запустите службу вручную"
echo "3. Используйте удаленный SQL Server и обновите настройки подключения"
exit 1
