#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/Archive/Index"
SUBTREE_MATRIX="${1:-$OUT_DIR/github_subtree_matrix_latest.tsv}"
REGISTRY="$OUT_DIR/subtree_registry.tsv"
TS_UTC="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
EVIDENCE_REF="Archive/Index/github_subtree_report_latest.md"

if [[ ! -f "$SUBTREE_MATRIX" ]]; then
  echo "subtree matrix not found: $SUBTREE_MATRIX" >&2
  exit 2
fi

printf "subtree_path\tupstream_repo\tupstream_ref\tpinned_commit\towner_repo\tsync_cadence\tlast_sync_utc\tevidence_ref\n" > "$REGISTRY"

awk -F '\t' 'NR>1 {printf("%s\t%s\t%s\t%s\n", $1, $4, $5, $2)}' "$SUBTREE_MATRIX" \
  | while IFS=$'\t' read -r repo pinned branch repo_path; do
      upstream_repo="unknown"
      if git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        upstream_repo="$(git -C "$repo_path" remote get-url origin 2>/dev/null || echo unknown)"
      fi
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$repo" "$upstream_repo" "${branch:-main}" "$pinned" "Archivator_Agent" "daily" "$TS_UTC" "$EVIDENCE_REF" >> "$REGISTRY"
    done

echo "$REGISTRY"
