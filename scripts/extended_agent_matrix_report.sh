#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_DIR="$ROOT/Archive/Index"
TSV="${1:-$INDEX_DIR/agent_ecosystem_file_matrix_latest.tsv}"
SUBTREE="${2:-$INDEX_DIR/subtree_registry.tsv}"
ANOMALY="${3:-$INDEX_DIR/agent_matrix_anomaly_report_latest.md}"
TS="$(date +%Y%m%d_%H%M%S)"
OUT="$INDEX_DIR/archivator_extended_agent_matrix_report_${TS}.md"
LATEST="$INDEX_DIR/archivator_extended_agent_matrix_report_latest.md"

if [[ ! -f "$TSV" ]]; then
  echo "missing matrix file: $TSV" >&2
  exit 2
fi

{
  echo "# Archivator Extended Agent Matrix Report — $TS"
  echo
  echo "## Scope"
  echo "- LAM-Codex_Agent"
  echo "- Roaudter-agent"
  echo "- LAM_Comunication_Agent"
  echo "- Operator_Agent"
  echo "- LAM_DATA_Src"
  echo "- Trianiuma_MEM_CORE"
  echo
  echo "## Footprint"
  echo
  echo "| Repository | Role | Files | Bytes |"
  echo "|---|---|---:|---:|"
  awk -F '\t' 'NR>1{cnt[$1]++; sz[$1]+=$7; role[$1]=$2} END {for (r in cnt) printf("| %s | %s | %d | %d |\n", r, role[r], cnt[r], sz[r])}' "$TSV" | sort
  echo
  echo "## Memory Tier Mix"
  echo
  echo "| Repository | Operational | Long Term | Archival |"
  echo "|---|---:|---:|---:|"
  awk -F '\t' 'NR>1{repos[$1]=1; k[$1 FS $5]++} END {for (r in repos) printf("| %s | %d | %d | %d |\n", r, k[r FS "operational"]+0, k[r FS "long_term"]+0, k[r FS "archival"]+0)}' "$TSV" | sort
  echo
  echo "## Process Stream Mix"
  echo
  echo "| Repository | Routing | Transport | Execution | Contract Control | Validation | Orchestration | Governance | General |"
  echo "|---|---:|---:|---:|---:|---:|---:|---:|---:|"
  awk -F '\t' 'NR>1{repos[$1]=1; k[$1 FS $6]++} END {for (r in repos) printf("| %s | %d | %d | %d | %d | %d | %d | %d | %d |\n", r, k[r FS "routing"]+0, k[r FS "transport"]+0, k[r FS "execution"]+0, k[r FS "contract_control"]+0, k[r FS "validation"]+0, k[r FS "orchestration"]+0, k[r FS "governance"]+0, k[r FS "general"]+0)}' "$TSV" | sort
  echo
  echo "## Subtree Registry Snapshot"
  if [[ -f "$SUBTREE" ]]; then
    echo
    echo "| Subtree | Upstream | Ref | Commit | Cadence |"
    echo "|---|---|---|---|---|"
    awk -F '\t' 'NR>1{printf("| %s | %s | %s | `%s` | %s |\n",$1,$2,$3,$4,$6)}' "$SUBTREE" | sort
  else
    echo
    echo "- subtree registry missing: $SUBTREE"
  fi
  echo
  echo "## Anomaly Gate"
  echo "- Source: \`$ANOMALY\`"
  if [[ -f "$ANOMALY" ]]; then
    awk '/## Summary/{flag=1} flag{print}' "$ANOMALY"
  else
    echo "- anomaly report missing"
  fi
  echo
  echo "## Recommendation"
  echo "1. Keep strict refresh mode enabled for daily runs."
  echo "2. Track memory-heavy repositories ('LAM_DATA_Src', 'Trianiuma_MEM_CORE') with role-aware thresholds."
  echo "3. Regenerate subtree registry after each target-repo topology change."
} > "$OUT"

cp -f "$OUT" "$LATEST"
echo "$OUT"
