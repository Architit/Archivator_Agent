#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="${1:-$(cd "$ROOT/.." && pwd)}"
TARGETS="${2:-LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE}"
STRICT_MODE="${3:-soft}"
INDEX_DIR="$ROOT/Archive/Index"

if ! mkdir -p "$INDEX_DIR" 2>/dev/null || ! : > "$INDEX_DIR/.refresh_write_probe" 2>/dev/null; then
  echo "global_refresh:warn index_dir_unwritable path=$INDEX_DIR"
  echo "global_refresh:ok"
  exit 0
fi
rm -f "$INDEX_DIR/.refresh_write_probe"


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

echo "global_refresh:ok"
echo "strict_mode=$STRICT_MODE"
echo "workspace_matrix=$ROOT/Archive/Index/ecosystem_memory_matrix_report_latest.md"
echo "agent_matrix=$ROOT/Archive/Index/agent_ecosystem_memory_flow_report_latest.md"
echo "subtree_report=$ROOT/Archive/Index/github_subtree_report_latest.md"
echo "subtree_registry=$ROOT/Archive/Index/subtree_registry.tsv"
echo "anomaly_report=$ROOT/Archive/Index/agent_matrix_anomaly_report_latest.md"
echo "subtree_drift_report=$ROOT/Archive/Index/subtree_drift_report_latest.md"
echo "extended_report=$ROOT/Archive/Index/archivator_extended_agent_matrix_report_latest.md"
