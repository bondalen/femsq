#!/bin/bash
# =============================================================================
# run_gate_21_4_5.sh — этап 21.4.5: agency-spot re-check (07n 849/1862 + 07t)
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/run_agency_golden_21_3.sh"
