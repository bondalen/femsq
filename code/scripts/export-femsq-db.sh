#!/usr/bin/env bash
set -euo pipefail
# Load FEMSQ database environment variables for current shell
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../config/env/femsq-db.env"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Env file not found: ${ENV_FILE}" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "${ENV_FILE}"
# Show summary (mask password)
echo "FEMSQ_DB_HOST=${FEMSQ_DB_HOST}"
echo "FEMSQ_DB_PORT=${FEMSQ_DB_PORT}"
echo "FEMSQ_DB_NAME=${FEMSQ_DB_NAME}"
echo "FEMSQ_DB_USER=${FEMSQ_DB_USER}"
echo "FEMSQ_DB_PASSWORD=******"
echo "FEMSQ_DB_AUTH_MODE=${FEMSQ_DB_AUTH_MODE}"
