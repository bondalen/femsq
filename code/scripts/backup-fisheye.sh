#!/usr/bin/env bash
# Резервное копирование БД FishEye из Docker-контейнера femsq-mssql.
# Файлы .bak сохраняются на диск D: (Windows) /mnt/d/... (WSL), вне docker_data.vhdx.
#
# Использование:
#   ./code/scripts/backup-fisheye.sh [daily|manual|before-docker|archive]
#   BACKUP_LABEL=pre-docker ./code/scripts/backup-fisheye.sh before-docker
#
# Переменные (опционально):
#   CONTAINER_NAME, DB_NAME, SA_PASSWORD / FEMSQ_DB_PASSWORD
#   BACKUP_ROOT — корень (по умолчанию /mnt/d/Backups/femsq/database)
#   DAILY_KEEP — сколько daily-копий хранить (по умолчанию 7)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONTAINER_NAME="${CONTAINER_NAME:-femsq-mssql}"
DB_NAME="${DB_NAME:-FishEye}"
BACKUP_KIND="${1:-daily}"
BACKUP_LABEL="${BACKUP_LABEL:-}"
DAILY_KEEP="${DAILY_KEEP:-7}"
CONTAINER_STAGING="/var/opt/mssql/backup/femsq_staging.bak"

# --- цвета ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}=== $* ===${NC}"; }
ok() { echo -e "${GREEN}✓ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
err() { echo -e "${RED}✗ $*${NC}" >&2; }

# --- пароль и имя БД из ~/.femsq/database.properties ---
load_db_config() {
    local props="${FEMSQ_CONFIG_PATH:-$HOME/.femsq/database.properties}"
    if [[ -f "$props" ]]; then
        if [[ -z "${SA_PASSWORD:-}" && -z "${FEMSQ_DB_PASSWORD:-}" ]]; then
            local p
            p="$(grep -E '^[[:space:]]*password[[:space:]]*=' "$props" 2>/dev/null | head -1 | sed -E 's/^[[:space:]]*password[[:space:]]*=[[:space:]]*//; s/[[:space:]]*$//')"
            if [[ -n "$p" ]]; then
                SA_PASSWORD="$p"
            fi
        fi
        if [[ "$DB_NAME" == "FishEye" ]]; then
            local d
            d="$(grep -E '^[[:space:]]*database[[:space:]]*=' "$props" 2>/dev/null | head -1 | sed -E 's/^[[:space:]]*database[[:space:]]*=[[:space:]]*//; s/[[:space:]]*$//')"
            if [[ -n "$d" ]]; then
                DB_NAME="$d"
            fi
        fi
    fi

    if [[ -z "${SA_PASSWORD:-}" && -z "${FEMSQ_DB_PASSWORD:-}" ]]; then
        local env_file="${PROJECT_ROOT}/code/config/env/femsq-db.env"
        if [[ -f "$env_file" ]]; then
            # shellcheck disable=SC1090
            source "$env_file"
            SA_PASSWORD="${FEMSQ_DB_PASSWORD:-}"
            if [[ "$DB_NAME" == "FishEye" && -n "${FEMSQ_DB_NAME:-}" ]]; then
                DB_NAME="$FEMSQ_DB_NAME"
            fi
        fi
    fi

    SA_PASSWORD="${SA_PASSWORD:-${FEMSQ_DB_PASSWORD:-kolob_OK1}}"
}

# --- каталог бэкапов на хосте ---
resolve_backup_root() {
    if [[ -n "${BACKUP_ROOT:-}" ]]; then
        echo "$BACKUP_ROOT"
        return
    fi
    if [[ -d /mnt/d/Backups ]]; then
        echo "/mnt/d/Backups/femsq/database"
    elif [[ -d /mnt/d ]]; then
        echo "/mnt/d/Backups/femsq/database"
    else
        echo "${HOME}/Backups/femsq/database"
    fi
}

validate_kind() {
    case "$BACKUP_KIND" in
        daily|manual|before-docker|archive) ;;
        *)
            err "Неизвестный тип: $BACKUP_KIND"
            echo "Допустимо: daily, manual, before-docker, archive"
            exit 1
            ;;
    esac
}

rotate_daily_backups() {
    local dir="$1"
    local keep="$2"
    mapfile -t old_files < <(ls -1t "$dir"/"${DB_NAME}"_*.bak 2>/dev/null || true)
    local count=${#old_files[@]}
    if (( count <= keep )); then
        return
    fi
    local i
    for (( i = keep; i < count; i++ )); do
        rm -f "${old_files[$i]}"
        warn "Удалён старый daily-бэкап: ${old_files[$i]}"
    done
}

main() {
    validate_kind
    load_db_config

    local backup_root
    backup_root="$(resolve_backup_root)"
    local target_dir="${backup_root}/${BACKUP_KIND}"
    mkdir -p "$target_dir"

    local ts label_suffix dest_name dest_path
    ts="$(date +%Y%m%d_%H%M%S)"
    label_suffix=""
    if [[ -n "$BACKUP_LABEL" ]]; then
        label_suffix="_${BACKUP_LABEL}"
    fi
    dest_name="${DB_NAME}_${ts}${label_suffix}.bak"
    dest_path="${target_dir}/${dest_name}"

    log "Резервное копирование FishEye"
    echo "Контейнер:  $CONTAINER_NAME"
    echo "База:       $DB_NAME"
    echo "Тип:        $BACKUP_KIND"
    echo "Назначение: $dest_path"
    echo ""

    if ! command -v docker &>/dev/null; then
        err "docker не найден"
        exit 1
    fi

    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        err "Контейнер '$CONTAINER_NAME' не запущен (docker start $CONTAINER_NAME)"
        exit 1
    fi

    local sqlcmd="/opt/mssql-tools18/bin/sqlcmd"
    if ! docker exec "$CONTAINER_NAME" test -x "$sqlcmd"; then
        sqlcmd="/opt/mssql-tools/bin/sqlcmd"
        if ! docker exec "$CONTAINER_NAME" test -x "$sqlcmd"; then
            err "sqlcmd не найден в контейнере"
            exit 1
        fi
    fi

    docker exec "$CONTAINER_NAME" mkdir -p /var/opt/mssql/backup
    docker exec "$CONTAINER_NAME" rm -f "$CONTAINER_STAGING"

    log "BACKUP DATABASE (в контейнере)..."
    docker exec "$CONTAINER_NAME" "$sqlcmd" \
        -S localhost -U sa -P "$SA_PASSWORD" -C \
        -Q "BACKUP DATABASE [${DB_NAME}] TO DISK = N'${CONTAINER_STAGING}' WITH INIT, COMPRESSION, STATS = 10"

    if ! docker exec "$CONTAINER_NAME" test -f "$CONTAINER_STAGING"; then
        err "Файл бэкапа не создан в контейнере: $CONTAINER_STAGING"
        exit 1
    fi

    log "Копирование на хост..."
    docker cp "${CONTAINER_NAME}:${CONTAINER_STAGING}" "$dest_path"
    docker exec "$CONTAINER_NAME" rm -f "$CONTAINER_STAGING"

    local size_human
    size_human="$(du -h "$dest_path" | cut -f1)"
    ok "Создан: $dest_path ($size_human)"

    if [[ "$BACKUP_KIND" == "daily" ]]; then
        rotate_daily_backups "$target_dir" "$DAILY_KEEP"
        ok "Ротация daily: хранится не более $DAILY_KEEP файлов ${DB_NAME}_*.bak"
    fi

    echo ""
    echo "Восстановление (пример, в тестовую БД):"
    echo "  docker cp \"$dest_path\" ${CONTAINER_NAME}:/var/opt/mssql/backup/restore.bak"
    echo "  docker exec -it $CONTAINER_NAME $sqlcmd -S localhost -U sa -P '***' -C -Q \\"
    echo "    \"RESTORE DATABASE [FishEye_restore_test] FROM DISK = N'/var/opt/mssql/backup/restore.bak' WITH REPLACE, MOVE ...\""
}

main "$@"
