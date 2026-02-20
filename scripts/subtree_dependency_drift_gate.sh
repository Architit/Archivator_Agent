#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="${1:-$(cd "$ROOT/.." && pwd)}"
REGISTRY="${2:-$ROOT/Archive/Index/subtree_registry.tsv}"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_TSV="$ROOT/Archive/Index/subtree_drift_matrix_${TS}.tsv"
OUT_MD="$ROOT/Archive/Index/subtree_drift_report_${TS}.md"
LATEST_TSV="$ROOT/Archive/Index/subtree_drift_matrix_latest.tsv"
LATEST_MD="$ROOT/Archive/Index/subtree_drift_report_latest.md"
STRICT_FAIL="${STRICT_FAIL:-0}"

if [[ ! -f "$REGISTRY" ]]; then
  echo "missing registry: $REGISTRY" >&2
  exit 2
fi

printf "subtree_path\texpected_remote\texpected_ref\texpected_commit\tactual_remote\tactual_ref\tactual_commit\tstatus\n" > "$OUT_TSV"

drifts=0
checked=0

while IFS=$'\t' read -r subtree_path expected_remote expected_ref expected_commit owner cadence last_sync evidence; do
  [[ "$subtree_path" == "subtree_path" ]] && continue
  repo_path="$WORK_ROOT/$subtree_path"
  status="ok"
  actual_remote="n/a"
  actual_ref="n/a"
  actual_commit="n/a"

  if [[ ! -d "$repo_path" ]]; then
    status="missing_repo_path"
  elif ! git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    status="not_git_repo"
  else
    actual_remote="$(git -C "$repo_path" remote get-url origin 2>/dev/null || echo unknown)"
    actual_ref="$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
    actual_commit="$(git -C "$repo_path" rev-parse --short HEAD 2>/dev/null || echo unknown)"

    if [[ "$actual_remote" != "$expected_remote" ]]; then
      status="remote_drift"
    fi
    if [[ "$status" == "ok" && "$actual_ref" != "$expected_ref" ]]; then
      status="ref_drift"
    fi
    if [[ "$status" == "ok" && "$actual_commit" != "$expected_commit" ]]; then
      status="commit_drift"
    fi
  fi

  if [[ "$status" != "ok" ]]; then
    drifts=$((drifts+1))
  fi
  checked=$((checked+1))

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$subtree_path" "$expected_remote" "$expected_ref" "$expected_commit" \
    "$actual_remote" "$actual_ref" "$actual_commit" "$status" >> "$OUT_TSV"
done < "$REGISTRY"

{
  echo "# Subtree Dependency Drift Report — $TS"
  echo
  echo "- Registry: \`$REGISTRY\`"
  echo "- Work root: \`$WORK_ROOT\`"
  echo "- Checked: $checked"
  echo "- Drifts: $drifts"
  echo "- STRICT_FAIL=$STRICT_FAIL"
  echo
  echo "## Drift Matrix"
  echo
  echo "| Subtree | Expected Ref | Expected Commit | Actual Ref | Actual Commit | Status |"
  echo "|---|---|---|---|---|---|"
  awk -F '\t' 'NR>1{printf("| %s | %s | `%s` | %s | `%s` | %s |\n",$1,$3,$4,$6,$7,$8)}' "$OUT_TSV" | sort
  echo
  echo "## Artifacts"
  echo "- Drift matrix TSV: \`$OUT_TSV\`"
  echo "- Latest drift matrix: \`$LATEST_TSV\`"
  echo "- Latest drift report: \`$LATEST_MD\`"
} > "$OUT_MD"

cp -f "$OUT_TSV" "$LATEST_TSV"
cp -f "$OUT_MD" "$LATEST_MD"

if [[ "$STRICT_FAIL" == "1" && "$drifts" -gt 0 ]]; then
  echo "subtree_drift_gate:fail drifts=$drifts report=$OUT_MD"
  exit 1
fi

echo "subtree_drift_gate:ok drifts=$drifts report=$OUT_MD"
