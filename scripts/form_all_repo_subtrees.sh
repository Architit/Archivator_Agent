#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="${1:-$(cd "$ROOT/.." && pwd)}"
SUBTREE_ROOT="${2:-Subtrees}"
HOST_REPO="$(basename "$ROOT")"
TS="$(date +%Y%m%d_%H%M%S)"
REPORT="$ROOT/Archive/Index/subtree_formation_report_${TS}.md"

if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "host is not a git repo: $ROOT" >&2
  exit 2
fi

if ! git subtree --help >/dev/null 2>&1; then
  echo "git subtree is unavailable on this system" >&2
  exit 2
fi

mkdir -p "$ROOT/$SUBTREE_ROOT" "$ROOT/Archive/Index"

repos=()
while IFS= read -r d; do
  repo="$(basename "$d")"
  [[ "$repo" == "$HOST_REPO" ]] && continue
  repos+=("$repo")
done < <(find "$WORK_ROOT" -mindepth 1 -maxdepth 1 -type d -name "*" \
  -exec test -d "{}/.git" ';' -print | sort)

added=0
updated=0
failed=0

{
  echo "# Subtree Formation Report — $TS"
  echo
  echo "| Repository | Branch | Prefix | Status |"
  echo "|---|---|---|---|"
} > "$REPORT"

for repo in "${repos[@]}"; do
  repo_path="$WORK_ROOT/$repo"
  prefix="$SUBTREE_ROOT/$repo"
  remote_name="subtree_$(echo "$repo" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '_')"
  branch="$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  [[ "$branch" == "HEAD" ]] && branch="main"

  if git -C "$ROOT" remote | grep -qx "$remote_name"; then
    git -C "$ROOT" remote set-url "$remote_name" "$repo_path"
  else
    git -C "$ROOT" remote add "$remote_name" "$repo_path"
  fi

  if ! git -C "$ROOT" fetch "$remote_name" "$branch" --quiet; then
    failed=$((failed+1))
    echo "| $repo | $branch | $prefix | fetch_failed |" >> "$REPORT"
    continue
  fi

  if [[ -d "$ROOT/$prefix" && -n "$(ls -A "$ROOT/$prefix" 2>/dev/null || true)" ]]; then
    if git -C "$ROOT" subtree pull --prefix="$prefix" "$remote_name" "$branch" --squash -m "chore(subtree): update $repo @ $TS" >/dev/null 2>&1; then
      updated=$((updated+1))
      echo "| $repo | $branch | $prefix | updated |" >> "$REPORT"
    else
      failed=$((failed+1))
      echo "| $repo | $branch | $prefix | pull_failed |" >> "$REPORT"
    fi
  else
    if git -C "$ROOT" subtree add --prefix="$prefix" "$remote_name" "$branch" --squash -m "chore(subtree): add $repo @ $TS" >/dev/null 2>&1; then
      added=$((added+1))
      echo "| $repo | $branch | $prefix | added |" >> "$REPORT"
    else
      failed=$((failed+1))
      echo "| $repo | $branch | $prefix | add_failed |" >> "$REPORT"
    fi
  fi
done

{
  echo
  echo "## Summary"
  echo "- added=$added"
  echo "- updated=$updated"
  echo "- failed=$failed"
} >> "$REPORT"

echo "$REPORT"
