#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="${1:-$(cd "$ROOT/.." && pwd)}"
OUT_DIR="$ROOT/Archive/Index"
TS="$(date +%Y%m%d_%H%M%S)"
TSV="$OUT_DIR/ecosystem_file_matrix_${TS}.tsv"
MD="$OUT_DIR/ecosystem_memory_matrix_report_${TS}.md"
LATEST_TSV="$OUT_DIR/ecosystem_file_matrix_latest.tsv"
LATEST_MD="$OUT_DIR/ecosystem_memory_matrix_report_latest.md"

mkdir -p "$OUT_DIR"

classify_domain() {
  local rel="$1"
  case "$rel" in
    *.py|*.sh|*.ps1|*.ts|*.tsx|*.js|*.jsx|*.go|*.rs|*.java|*.cs|*.cpp|*.c|*.h|*.hpp|*.toml|*.yaml|*.yml|*.ini)
      echo "code"
      ;;
    *.md|*.rst|*.adoc|*.txt)
      echo "docs"
      ;;
    *.json|*.jsonl|*.csv|*.tsv|*.xml|*.yaml.data|*.parquet|*.db|*.sqlite)
      echo "data_structured"
      ;;
    *.log)
      echo "telemetry"
      ;;
    *.jpg|*.jpeg|*.png|*.gif|*.webp|*.svg|*.mp4|*.wav|*.mp3)
      echo "media"
      ;;
    *)
      echo "other"
      ;;
  esac
}

classify_memory_tier() {
  local rel="$1"
  case "$rel" in
    */Archive/*|*/SourceChats/*|*/LAM_MEM_*|*/LRAM/*|*.tgz|*.zip|*.7z)
      echo "archival"
      ;;
    */scripts/*|*/tests/*|*/src/*|*/.github/workflows/*|*/devkit/*)
      echo "operational"
      ;;
    */ROADMAP.md|*/DEV_LOGS.md|*/WORKFLOW_SNAPSHOT_*|*/SYSTEM_STATE*|*/INTERACTION_PROTOCOL.md|*/CONTRACT*.md|*/GATEWAY_ACCESS_CONTRACT.md|*/TEST_*MATRIX*.md|*/STRATEGY*.md)
      echo "long_term"
      ;;
    *)
      echo "long_term"
      ;;
  esac
}

printf "repo\tpath\tdomain\tmemory_tier\tsize_bytes\tmtime_utc\n" > "$TSV"

while IFS= read -r -d '' f; do
  rel="${f#$WORK_ROOT/}"
  repo="${rel%%/*}"
  domain="$(classify_domain "$rel")"
  tier="$(classify_memory_tier "$rel")"
  size="$(stat -c '%s' "$f" 2>/dev/null || echo 0)"
  mtime="$(date -u -d "@$(stat -c '%Y' "$f")" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo unknown)"
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$repo" "$rel" "$domain" "$tier" "$size" "$mtime" >> "$TSV"
done < <(find "$WORK_ROOT" -type f \
  -not -path "*/.git/*" \
  -not -path "*/.venv/*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/.pytest_cache/*" \
  -print0)

{
  echo "# Ecosystem Memory Matrix Report — $TS"
  echo
  echo "Work root: \`$WORK_ROOT\`"
  echo
  echo "## 1. Repository Footprint (files / bytes)"
  echo
  echo "| Repository | Files | Bytes |"
  echo "|---|---:|---:|"
  awk -F '\t' 'NR>1{cnt[$1]++; sz[$1]+=$5} END {for (r in cnt) printf("| %s | %d | %d |\n", r, cnt[r], sz[r])}' "$TSV" | sort
  echo
  echo "## 2. Memory Tier Distribution"
  echo
  echo "| Repository | Operational | Long Term | Archival |"
  echo "|---|---:|---:|---:|"
  awk -F '\t' 'NR>1{k[$1 FS $4]++} END {for (r in seen){} } {if(NR>1) repos[$1]=1} END {for (r in repos) {o=k[r FS "operational"]+0; l=k[r FS "long_term"]+0; a=k[r FS "archival"]+0; printf("| %s | %d | %d | %d |\n", r,o,l,a)}}' "$TSV" | sort
  echo
  echo "## 3. Domain Distribution"
  echo
  echo "| Repository | Code | Docs | Data Structured | Telemetry | Media | Other |"
  echo "|---|---:|---:|---:|---:|---:|---:|"
  awk -F '\t' 'NR>1{k[$1 FS $3]++; repos[$1]=1} END {for (r in repos) {printf("| %s | %d | %d | %d | %d | %d | %d |\n", r, k[r FS "code"]+0, k[r FS "docs"]+0, k[r FS "data_structured"]+0, k[r FS "telemetry"]+0, k[r FS "media"]+0, k[r FS "other"]+0)}}' "$TSV" | sort
  echo
  echo "## 4. Top Archival Density Paths (sample)"
  echo
  echo "| Repository | Path | Bytes |"
  echo "|---|---|---:|"
  awk -F '\t' 'NR>1 && $4=="archival"{printf("%s\t%s\t%s\n",$1,$2,$5)}' "$TSV" | sort -t $'\t' -k3,3nr | awk -F '\t' 'NR<=30{printf("| %s | `%s` | %s |\n",$1,$2,$3)}'
  echo
  echo "## Artifacts"
  echo "- File matrix TSV: \`$TSV\`"
  echo "- Latest TSV pointer: \`$LATEST_TSV\`"
  echo "- Latest report pointer: \`$LATEST_MD\`"
} > "$MD"

cp -f "$TSV" "$LATEST_TSV"
cp -f "$MD" "$LATEST_MD"

echo "$MD"
