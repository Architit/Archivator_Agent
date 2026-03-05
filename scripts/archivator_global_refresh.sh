#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="${1:-$(cd "$ROOT/.." && pwd)}"
TARGETS="${2:-LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE}"
STRICT_MODE="${3:-soft}"
INDEX_DIR="$ROOT/Archive/Index"

require_executable() {
  local path="$1"
  if [[ ! -x "$path" ]]; then
    echo "global_refresh:fail precondition_failure missing_executable path=$path"
    exit 20
  fi
}

require_executable "$ROOT/scripts/ecosystem_matrix_builder.sh"
require_executable "$ROOT/scripts/agent_ecosystem_matrix_builder.sh"
require_executable "$ROOT/scripts/subtree_registry_sync.sh"
require_executable "$ROOT/scripts/agent_matrix_anomaly_gate.sh"
require_executable "$ROOT/scripts/subtree_dependency_drift_gate.sh"
require_executable "$ROOT/scripts/extended_agent_matrix_report.sh"
require_executable "$ROOT/scripts/gateway_io.sh"

if ! mkdir -p "$INDEX_DIR" 2>/dev/null || ! : > "$INDEX_DIR/.refresh_write_probe" 2>/dev/null; then
  echo "global_refresh:fail precondition_failure index_dir_unwritable path=$INDEX_DIR"
  exit 20
fi
rm -f "$INDEX_DIR/.refresh_write_probe"

CYCLE_ID="$(date +%Y%m%d_%H%M%S)"
echo "global_refresh:cycle_start cycle_id=$CYCLE_ID strict_mode=$STRICT_MODE"

# Phase 1: semantic index refresh loop.
"$ROOT/scripts/ecosystem_matrix_builder.sh" "$WORK_ROOT" >/dev/null
"$ROOT/scripts/agent_ecosystem_matrix_builder.sh" "$WORK_ROOT" "$TARGETS" >/dev/null
"$ROOT/scripts/subtree_registry_sync.sh" "$ROOT/Archive/Index/github_subtree_matrix_latest.tsv" >/dev/null
if [[ "$STRICT_MODE" == "strict" ]]; then
  STRICT_FAIL=1 "$ROOT/scripts/agent_matrix_anomaly_gate.sh" "$ROOT/Archive/Index/agent_ecosystem_file_matrix_latest.tsv" >/dev/null
  STRICT_FAIL=1 "$ROOT/scripts/subtree_dependency_drift_gate.sh" "$WORK_ROOT" "$ROOT/Archive/Index/subtree_registry.tsv" >/dev/null
else
  STRICT_FAIL=0 "$ROOT/scripts/agent_matrix_anomaly_gate.sh" "$ROOT/Archive/Index/agent_ecosystem_file_matrix_latest.tsv" >/dev/null
  STRICT_FAIL=0 "$ROOT/scripts/subtree_dependency_drift_gate.sh" "$WORK_ROOT" "$ROOT/Archive/Index/subtree_registry.tsv" >/dev/null
fi
"$ROOT/scripts/extended_agent_matrix_report.sh" \
  "$ROOT/Archive/Index/agent_ecosystem_file_matrix_latest.tsv" \
  "$ROOT/Archive/Index/subtree_registry.tsv" \
  "$ROOT/Archive/Index/agent_matrix_anomaly_report_latest.md" >/dev/null
echo "global_refresh:semantic_index_hook=ok cycle_id=$CYCLE_ID index_dir=$INDEX_DIR"

# Phase 2: physical archive loop.
EXPORT_LOG="$(mktemp)"
trap 'rm -f "$EXPORT_LOG"' EXIT
if ! GATEWAY_EXPORT_DIR="${GATEWAY_EXPORT_DIR:-$ROOT/.gateway/export}" "$ROOT/scripts/gateway_io.sh" export >"$EXPORT_LOG" 2>&1; then
  echo "global_refresh:fail physical_archive_export_failed cycle_id=$CYCLE_ID"
  cat "$EXPORT_LOG"
  exit 21
fi
ARCHIVE_PATH="$(sed -n 's/.*archive=\(.*\)$/\1/p' "$EXPORT_LOG" | tail -n 1)"
if [[ -z "$ARCHIVE_PATH" || ! -f "$ARCHIVE_PATH" ]]; then
  echo "global_refresh:fail physical_archive_missing cycle_id=$CYCLE_ID"
  exit 21
fi
echo "global_refresh:physical_archive_hook=ok cycle_id=$CYCLE_ID archive=$ARCHIVE_PATH"
echo "global_refresh:hybrid_cycle=ok cycle_id=$CYCLE_ID semantic_index=Archive/Index physical_archive=$ARCHIVE_PATH"

echo "global_refresh:ok"
echo "strict_mode=$STRICT_MODE"
echo "workspace_matrix=$ROOT/Archive/Index/ecosystem_memory_matrix_report_latest.md"
echo "agent_matrix=$ROOT/Archive/Index/agent_ecosystem_memory_flow_report_latest.md"
echo "subtree_report=$ROOT/Archive/Index/github_subtree_report_latest.md"
echo "subtree_registry=$ROOT/Archive/Index/subtree_registry.tsv"
echo "anomaly_report=$ROOT/Archive/Index/agent_matrix_anomaly_report_latest.md"
echo "subtree_drift_report=$ROOT/Archive/Index/subtree_drift_report_latest.md"
echo "extended_report=$ROOT/Archive/Index/archivator_extended_agent_matrix_report_latest.md"
