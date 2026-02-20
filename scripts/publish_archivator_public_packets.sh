#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ONEDRIVE_ROOT="${GATEWAY_ONEDRIVE_ROOT:-}"
GWORK_ROOT="${GATEWAY_GWORKSPACE_ROOT:-}"
STAMP="$(date +%Y%m%d_%H%M%S)"

if [[ -z "$ONEDRIVE_ROOT" || -z "$GWORK_ROOT" ]]; then
  echo "Usage: GATEWAY_ONEDRIVE_ROOT=... GATEWAY_GWORKSPACE_ROOT=... $0"
  exit 2
fi

for p in "$ONEDRIVE_ROOT" "$GWORK_ROOT"; do
  if [[ ! -d "$p" ]]; then
    echo "Missing gateway root: $p"
    exit 1
  fi
done

OD_BASE="$ONEDRIVE_ROOT/Exports/LAM_Public/archivator_${STAMP}"
GW_BASE="$GWORK_ROOT/Exports/LAM_Public/archivator_${STAMP}"
mkdir -p "$OD_BASE" "$GW_BASE"

FILES=(
  "README.md"
  "ROADMAP.md"
  "DEV_LOGS.md"
  "SUBTREE_REGISTRY_CONTRACT.md"
  "Archive/Index/ecosystem_file_matrix_latest.tsv"
  "Archive/Index/ecosystem_memory_matrix_report_latest.md"
  "Archive/Index/agent_ecosystem_file_matrix_latest.tsv"
  "Archive/Index/agent_ecosystem_memory_flow_report_latest.md"
  "Archive/Index/github_subtree_matrix_latest.tsv"
  "Archive/Index/github_subtree_report_latest.md"
  "Archive/Index/subtree_drift_matrix_latest.tsv"
  "Archive/Index/subtree_drift_report_latest.md"
  "Archive/Index/subtree_registry.tsv"
  "Archive/Index/subtree_hub_method_matrix_latest.tsv"
  "Archive/Index/agent_matrix_anomaly_report_latest.md"
  "Archive/Index/archivator_extended_agent_matrix_report_latest.md"
)

append_latest_root_file() {
  local pattern="$1"
  local latest
  latest="$(find "$ROOT" -maxdepth 1 -type f -name "$pattern" -printf '%f
' | sort | tail -n 1)"
  if [[ -n "$latest" ]]; then
    FILES+=("$latest")
  fi
}

append_latest_root_file "ECOSYSTEM_DATA_MATRIX_FRAMEWORK_*.md"
append_latest_root_file "ARCHIVATOR_GLOBAL_EXPANSION_AND_GITHUB_SUBTREE_STRATEGY_*.md"
append_latest_root_file "ARCHIVATOR_GLOBAL_WORKSPACE_ANALYSIS_*.md"
append_latest_root_file "AGENT_MEMORY_MATRIX_CODEX_ROAUDTER_COMM_OPERATOR_*.md"
append_latest_root_file "ARCHIVATOR_PROCESS_FLOW_GLOBAL_EXPANSION_*.md"
append_latest_root_file "SUBTREE_FALLBACK_POLICY_*.md"

manifest_od="$OD_BASE/MANIFEST.txt"
manifest_gw="$GW_BASE/MANIFEST.txt"
: > "$manifest_od"

copied=0
for rel in "${FILES[@]}"; do
  src="$ROOT/$rel"
  [[ -f "$src" ]] || continue
  mkdir -p "$OD_BASE/$(dirname "$rel")" "$GW_BASE/$(dirname "$rel")"
  cp -f "$src" "$OD_BASE/$rel"
  cp -f "$src" "$GW_BASE/$rel"
  echo "$rel" >> "$manifest_od"
  copied=$((copied+1))
done

sort -u "$manifest_od" -o "$manifest_od"
cp -f "$manifest_od" "$manifest_gw"

REPORT="$ROOT/Archive/Index/archivator_public_export_report_${STAMP}.md"
{
  echo "# Archivator Public Export Report — $STAMP"
  echo
  echo "- Files exported: $copied"
  echo "- OneDrive packet: $OD_BASE"
  echo "- Google Workspace packet: $GW_BASE"
  echo
  echo "## Manifest"
  echo
  while IFS= read -r line; do
    echo "- $line"
  done < "$manifest_od"
} > "$REPORT"

echo "$REPORT"
