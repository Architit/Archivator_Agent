#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="${1:-$(cd "$ROOT/.." && pwd)}"
SCHEDULE="${2:-17 2 * * *}"
TARGETS="${3:-LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE}"
MODE="${4:-strict}"
MARK="# ARCHIVATOR_DAILY_REFRESH_JOB"

ONEDRIVE_ROOT="${GATEWAY_ONEDRIVE_ROOT:-}"
GWORK_ROOT="${GATEWAY_GWORKSPACE_ROOT:-}"

if ! command -v crontab >/dev/null 2>&1; then
  echo "crontab is not available on this system"
  exit 2
fi

cmd="cd '$ROOT' && GATEWAY_ONEDRIVE_ROOT='${ONEDRIVE_ROOT}' GATEWAY_GWORKSPACE_ROOT='${GWORK_ROOT}' '$ROOT/scripts/run_daily_refresh_and_export.sh' '$WORK_ROOT' '$TARGETS' '$MODE'"
entry="$SCHEDULE $cmd $MARK"

tmp="$(mktemp)"
crontab -l 2>/dev/null | grep -v "$MARK" > "$tmp" || true
echo "$entry" >> "$tmp"
crontab "$tmp"
rm -f "$tmp"

echo "cron_install:ok"
echo "schedule=$SCHEDULE"
echo "mode=$MODE"
echo "targets=$TARGETS"
