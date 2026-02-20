#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="${1:-$(cd "$ROOT/.." && pwd)}"
EXPECTED_STRICT_ROOT="$(cd "$ROOT/.." && pwd)"
TARGETS="${2:-LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE}"
MODE="${3:-strict}"
ALLOW_NARROW_SCOPE="${ALLOW_NARROW_SCOPE:-0}"
DAILY_SUBTREE_HUB_SYNC="${DAILY_SUBTREE_HUB_SYNC:-1}"
SUBTREE_HUB_FAIL_POLICY="${SUBTREE_HUB_FAIL_POLICY:-warn}"
LOG_DIR="$ROOT/Archive/Logs"
TS="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/daily_refresh_${TS}.log"

mkdir -p "$LOG_DIR"

if [[ "$MODE" == "strict" && "$WORK_ROOT" != "$EXPECTED_STRICT_ROOT" && "$ALLOW_NARROW_SCOPE" != "1" ]]; then
  echo "[daily] blocked: strict mode requires WORK_ROOT=$EXPECTED_STRICT_ROOT (got: $WORK_ROOT)"
  echo "[daily] set ALLOW_NARROW_SCOPE=1 only for diagnostic/local runs"
  exit 2
fi

{
  echo "[daily] started ts=$TS mode=$MODE"
  "$ROOT/scripts/archivator_global_refresh.sh" "$WORK_ROOT" "$TARGETS" "$MODE"
  if [[ "$DAILY_SUBTREE_HUB_SYNC" == "1" ]]; then
    if "$ROOT/scripts/form_all_repo_subtrees_in_hub.sh" "$WORK_ROOT" "$ROOT/SubtreeHub" repos; then
      echo "[daily] subtree_hub_sync:ok"
    else
      echo "[daily] subtree_hub_sync:failed policy=$SUBTREE_HUB_FAIL_POLICY"
      if [[ "$SUBTREE_HUB_FAIL_POLICY" == "strict" ]]; then
        echo "[daily] subtree_hub_sync strict policy triggered fail"
        exit 1
      fi
    fi
  else
    echo "[daily] subtree_hub_sync skipped (DAILY_SUBTREE_HUB_SYNC=0)"
  fi
  if [[ -n "${GATEWAY_ONEDRIVE_ROOT:-}" && -n "${GATEWAY_GWORKSPACE_ROOT:-}" ]]; then
    export_ok=0
    for attempt in 1 2 3; do
      if "$ROOT/scripts/publish_archivator_public_packets.sh"; then
        export_ok=1
        echo "[daily] export ok attempt=$attempt"
        break
      fi
      echo "[daily] export retry attempt=$attempt failed"
      sleep 2
    done
    if [[ "$export_ok" -ne 1 ]]; then
      blocked_report="$ROOT/Archive/Index/daily_export_blocked_${TS}.md"
      {
        echo "# Daily Export Blocked — $TS"
        echo
        echo "- reason: gateway export failed after retries"
        echo "- onedrive_root: ${GATEWAY_ONEDRIVE_ROOT}"
        echo "- gworkspace_root: ${GATEWAY_GWORKSPACE_ROOT}"
        echo "- log_file: $LOG_FILE"
      } > "$blocked_report"
      echo "[daily] export blocked report=$blocked_report"
    fi
  else
    echo "[daily] export skipped: gateway env vars are not set"
  fi
  echo "[daily] completed"
} | tee "$LOG_FILE"

echo "$LOG_FILE"
