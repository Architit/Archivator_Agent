#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_DIR="$ROOT/Archive/Index"
TSV="${1:-$INDEX_DIR/agent_ecosystem_file_matrix_latest.tsv}"
TS="$(date +%Y%m%d_%H%M%S)"
REPORT="$INDEX_DIR/agent_matrix_anomaly_report_${TS}.md"
LATEST="$INDEX_DIR/agent_matrix_anomaly_report_latest.md"

MIN_OPERATIONAL_FILES="${MIN_OPERATIONAL_FILES:-5}"
MIN_VALIDATION_FILES="${MIN_VALIDATION_FILES:-1}"
MAX_GENERAL_RATIO="${MAX_GENERAL_RATIO:-0.75}"
STRICT_FAIL="${STRICT_FAIL:-0}"

if [[ ! -f "$TSV" ]]; then
  echo "missing matrix file: $TSV" >&2
  exit 2
fi

ANOMALIES=0
WARNINGS=0

{
  echo "# Agent Matrix Anomaly Gate Report — $TS"
  echo
  echo "Matrix source: \`$TSV\`"
  echo
  echo "## Thresholds"
  echo "- MIN_OPERATIONAL_FILES=$MIN_OPERATIONAL_FILES"
  echo "- MIN_VALIDATION_FILES=$MIN_VALIDATION_FILES"
  echo "- MAX_GENERAL_RATIO=$MAX_GENERAL_RATIO"
  echo "- STRICT_FAIL=$STRICT_FAIL"
  echo
  echo "## Checks"
  echo
  echo "| Repository | Check | Value | Threshold | Status |"
  echo "|---|---|---:|---:|---|"
} > "$REPORT"

while IFS= read -r repo; do
  role="$(awk -F '\t' -v r="$repo" 'NR>1 && $1==r{print $2; exit}' "$TSV")"
  min_op="$MIN_OPERATIONAL_FILES"
  min_val="$MIN_VALIDATION_FILES"
  max_gen="$MAX_GENERAL_RATIO"
  if [[ "$role" == "memory_data_lake" || "$role" == "memory_core" ]]; then
    min_op=1
    min_val=1
    max_gen=0.98
  fi

  total="$(awk -F '\t' -v r="$repo" 'NR>1 && $1==r{c++} END{print c+0}' "$TSV")"
  op="$(awk -F '\t' -v r="$repo" 'NR>1 && $1==r && $5=="operational"{c++} END{print c+0}' "$TSV")"
  val="$(awk -F '\t' -v r="$repo" 'NR>1 && $1==r && $6=="validation"{c++} END{print c+0}' "$TSV")"
  gen="$(awk -F '\t' -v r="$repo" 'NR>1 && $1==r && $6=="general"{c++} END{print c+0}' "$TSV")"

  ratio="0"
  if [[ "$total" -gt 0 ]]; then
    ratio="$(awk -v g="$gen" -v t="$total" 'BEGIN{printf("%.4f", g/t)}')"
  fi

  st="ok"
  if [[ "$op" -lt "$min_op" ]]; then
    st="warn"
    WARNINGS=$((WARNINGS+1))
  fi
  printf "| %s | operational files | %s | %s | %s |\n" "$repo" "$op" "$min_op" "$st" >> "$REPORT"

  st="ok"
  if [[ "$val" -lt "$min_val" ]]; then
    st="warn"
    WARNINGS=$((WARNINGS+1))
  fi
  printf "| %s | validation files | %s | %s | %s |\n" "$repo" "$val" "$min_val" "$st" >> "$REPORT"

  st="ok"
  if awk -v r="$ratio" -v m="$max_gen" 'BEGIN{exit !(r>m)}'; then
    st="warn"
    WARNINGS=$((WARNINGS+1))
  fi
  printf "| %s | general stream ratio | %s | %s | %s |\n" "$repo" "$ratio" "$max_gen" "$st" >> "$REPORT"
done < <(awk -F '\t' 'NR>1{repos[$1]=1} END{for (r in repos) print r}' "$TSV" | sort)

{
  echo
  echo "## Summary"
  echo "- warnings=$WARNINGS"
  echo "- anomalies=$ANOMALIES"
} >> "$REPORT"

cp -f "$REPORT" "$LATEST"

if [[ "$STRICT_FAIL" == "1" && "$WARNINGS" -gt 0 ]]; then
  echo "anomaly_gate:fail warnings=$WARNINGS report=$REPORT"
  exit 1
fi

echo "anomaly_gate:ok warnings=$WARNINGS report=$REPORT"
