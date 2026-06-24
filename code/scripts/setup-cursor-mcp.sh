#!/bin/bash
# Создаёт .cursor/mcp.json из шаблона по hostname (nb-win → localhost, Fedora → 10.7.0.3).
# Использование: ./code/scripts/setup-cursor-mcp.sh
# Файл .cursor/mcp.json в .gitignore — после git pull запустите этот скрипт на своей машине.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MCP_FILE="$PROJECT_ROOT/.cursor/mcp.json"
HOSTNAME="$(hostname)"

select_template() {
    case "$HOSTNAME" in
        nb-win)
            echo "$PROJECT_ROOT/.cursor/mcp.json.example"
            ;;
        *)
            if [[ "$HOSTNAME" =~ [Ff]edora ]] || [[ "$HOSTNAME" == "alex-fedora" ]]; then
                echo "$PROJECT_ROOT/.cursor/mcp.remote-nb-win.json.example"
            else
                return 1
            fi
            ;;
    esac
}

TEMPLATE="$(select_template)" || {
    echo "Неизвестная машина: $HOSTNAME"
    echo "Скопируйте вручную один из шаблонов в .cursor/mcp.json:"
    echo "  nb-win:   .cursor/mcp.json.example"
    echo "  Fedora:   .cursor/mcp.remote-nb-win.json.example"
    echo "Конфигурации машин: docs/project/project-docs.json → development.environments.machines"
    exit 1
}

mkdir -p "$(dirname "$MCP_FILE")"
cp "$TEMPLATE" "$MCP_FILE"
echo "✓ Создан $MCP_FILE"
echo "  hostname: $HOSTNAME"
echo "  шаблон:   $(basename "$TEMPLATE")"

if [[ ! -f "$PROJECT_ROOT/.cursor/dbhub/node_modules/@bytebase/dbhub/dist/index.js" ]]; then
    echo ""
    echo "DBHub не установлен — запуск setup-dbhub.sh..."
    "$SCRIPT_DIR/setup-dbhub.sh"
fi

echo ""
echo "Перезапустите Cursor или перезагрузите MCP-серверы (Settings → MCP)."
