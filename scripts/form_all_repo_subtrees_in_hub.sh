#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="${1:-$(cd "$ROOT/.." && pwd)}"
HUB_DIR="${2:-$ROOT/SubtreeHub}"
PREFIX_ROOT="${3:-repos}"
TS="$(date +%Y%m%d_%H%M%S)"
REPORT="$ROOT/Archive/Index/subtree_hub_formation_report_${TS}.md"
METHOD_TSV="$ROOT/Archive/Index/subtree_hub_method_matrix_${TS}.tsv"
METHOD_TSV_LATEST="$ROOT/Archive/Index/subtree_hub_method_matrix_latest.tsv"
FALLBACK_SNAPSHOT_ON_FAIL="${FALLBACK_SNAPSHOT_ON_FAIL:-1}"

mkdir -p "$ROOT/Archive/Index"

init_hub() {
  if [[ ! -d "$HUB_DIR/.git" ]]; then
    mkdir -p "$HUB_DIR"
    git -C "$HUB_DIR" init -q
    git -C "$HUB_DIR" config user.name "Archivator Subtree Bot"
    git -C "$HUB_DIR" config user.email "archivator-subtree@local"
    echo "# SubtreeHub" > "$HUB_DIR/README.md"
    git -C "$HUB_DIR" add README.md
    git -C "$HUB_DIR" commit -q -m "chore: initialize subtree hub"
  fi
}

commit_or_noop() {
  local hub="$1"
  local msg="$2"
  if git -C "$hub" diff --cached --quiet; then
    echo "noop"
    return 0
  fi
  if git -C "$hub" commit -m "$msg" >/dev/null 2>&1; then
    echo "committed"
    return 0
  fi
  echo "failed"
  return 1
}

if ! git subtree --help >/dev/null 2>&1; then
  echo "git subtree unavailable" >&2
  exit 2
fi

init_hub

repos=()
while IFS= read -r d; do
  repo="$(basename "$d")"
  [[ "$repo" == "Archivator_Agent" ]] && continue
  repos+=("$repo")
done < <(find "$WORK_ROOT" -mindepth 1 -maxdepth 1 -type d -exec test -d "{}/.git" ';' -print | sort)

added=0
updated=0
failed=0

{
  echo "# SubtreeHub Formation Report — $TS"
  echo
  echo "Hub: \`$HUB_DIR\`"
  echo
  echo "| Repository | Branch | Prefix | Status |"
  echo "|---|---|---|---|"
} > "$REPORT"

printf "repository\tbranch\tprefix\tmethod\tstatus\n" > "$METHOD_TSV"

for repo in "${repos[@]}"; do
  repo_path="$WORK_ROOT/$repo"
  branch="$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  [[ "$branch" == "HEAD" ]] && branch="main"
  remote_name="subhub_$(echo "$repo" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '_')"
  prefix="$PREFIX_ROOT/$repo"

  if git -C "$HUB_DIR" remote | grep -qx "$remote_name"; then
    git -C "$HUB_DIR" remote set-url "$remote_name" "$repo_path"
  else
    git -C "$HUB_DIR" remote add "$remote_name" "$repo_path"
  fi

  if ! git -C "$HUB_DIR" fetch "$remote_name" "$branch" --quiet; then
    if [[ "$FALLBACK_SNAPSHOT_ON_FAIL" == "1" ]]; then
      mkdir -p "$HUB_DIR/$prefix"
      rsync -a --delete \
        --exclude '.git' \
        --exclude '.venv' \
        --exclude '__pycache__' \
        --exclude '.pytest_cache' \
        "$repo_path/" "$HUB_DIR/$prefix/"
      git -C "$HUB_DIR" add "$prefix"
      commit_state="$(commit_or_noop "$HUB_DIR" "chore(subtree-fallback): snapshot $repo @ $TS" || true)"
      if [[ "$commit_state" == "committed" ]]; then
        updated=$((updated+1))
        echo "| $repo | $branch | $prefix | snapshot_fallback_after_fetch_failure |" >> "$REPORT"
        printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "snapshot" "fetch_failed_fallback_ok" >> "$METHOD_TSV"
      elif [[ "$commit_state" == "noop" ]]; then
        updated=$((updated+1))
        echo "| $repo | $branch | $prefix | snapshot_fallback_after_fetch_failure_noop |" >> "$REPORT"
        printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "snapshot" "fetch_failed_fallback_noop" >> "$METHOD_TSV"
      else
        failed=$((failed+1))
        echo "| $repo | $branch | $prefix | fetch_failed_and_snapshot_commit_failed |" >> "$REPORT"
        printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "snapshot" "fetch_failed_fallback_commit_failed" >> "$METHOD_TSV"
      fi
    else
      failed=$((failed+1))
      echo "| $repo | $branch | $prefix | fetch_failed |" >> "$REPORT"
      printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "subtree" "fetch_failed" >> "$METHOD_TSV"
    fi
    continue
  fi

  if [[ -d "$HUB_DIR/$prefix" && -n "$(ls -A "$HUB_DIR/$prefix" 2>/dev/null || true)" ]]; then
    if git -C "$HUB_DIR" subtree pull --prefix="$prefix" "$remote_name" "$branch" --squash -m "chore(subtree): update $repo @ $TS" >/dev/null 2>&1; then
      updated=$((updated+1))
      echo "| $repo | $branch | $prefix | updated |" >> "$REPORT"
      printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "subtree" "updated" >> "$METHOD_TSV"
    else
      if [[ "$FALLBACK_SNAPSHOT_ON_FAIL" == "1" ]]; then
        rsync -a --delete \
          --exclude '.git' \
          --exclude '.venv' \
          --exclude '__pycache__' \
          --exclude '.pytest_cache' \
          "$repo_path/" "$HUB_DIR/$prefix/"
        git -C "$HUB_DIR" add "$prefix"
        commit_state="$(commit_or_noop "$HUB_DIR" "chore(subtree-fallback): snapshot update $repo @ $TS" || true)"
        if [[ "$commit_state" == "committed" ]]; then
          updated=$((updated+1))
          echo "| $repo | $branch | $prefix | snapshot_fallback_after_pull_failure |" >> "$REPORT"
          printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "snapshot" "pull_failed_fallback_ok" >> "$METHOD_TSV"
        elif [[ "$commit_state" == "noop" ]]; then
          updated=$((updated+1))
          echo "| $repo | $branch | $prefix | snapshot_fallback_after_pull_failure_noop |" >> "$REPORT"
          printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "snapshot" "pull_failed_fallback_noop" >> "$METHOD_TSV"
        else
          failed=$((failed+1))
          echo "| $repo | $branch | $prefix | pull_failed_and_snapshot_commit_failed |" >> "$REPORT"
          printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "snapshot" "pull_failed_fallback_commit_failed" >> "$METHOD_TSV"
        fi
      else
        failed=$((failed+1))
        echo "| $repo | $branch | $prefix | pull_failed |" >> "$REPORT"
        printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "subtree" "pull_failed" >> "$METHOD_TSV"
      fi
    fi
  else
    if git -C "$HUB_DIR" subtree add --prefix="$prefix" "$remote_name" "$branch" --squash -m "chore(subtree): add $repo @ $TS" >/dev/null 2>&1; then
      added=$((added+1))
      echo "| $repo | $branch | $prefix | added |" >> "$REPORT"
      printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "subtree" "added" >> "$METHOD_TSV"
    else
      if [[ "$FALLBACK_SNAPSHOT_ON_FAIL" == "1" ]]; then
        mkdir -p "$HUB_DIR/$prefix"
        rsync -a --delete \
          --exclude '.git' \
          --exclude '.venv' \
          --exclude '__pycache__' \
          --exclude '.pytest_cache' \
          "$repo_path/" "$HUB_DIR/$prefix/"
        git -C "$HUB_DIR" add "$prefix"
        commit_state="$(commit_or_noop "$HUB_DIR" "chore(subtree-fallback): snapshot add $repo @ $TS" || true)"
        if [[ "$commit_state" == "committed" ]]; then
          added=$((added+1))
          echo "| $repo | $branch | $prefix | snapshot_fallback_after_add_failure |" >> "$REPORT"
          printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "snapshot" "add_failed_fallback_ok" >> "$METHOD_TSV"
        elif [[ "$commit_state" == "noop" ]]; then
          updated=$((updated+1))
          echo "| $repo | $branch | $prefix | snapshot_fallback_after_add_failure_noop |" >> "$REPORT"
          printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "snapshot" "add_failed_fallback_noop" >> "$METHOD_TSV"
        else
          failed=$((failed+1))
          echo "| $repo | $branch | $prefix | add_failed_and_snapshot_commit_failed |" >> "$REPORT"
          printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "snapshot" "add_failed_fallback_commit_failed" >> "$METHOD_TSV"
        fi
      else
        failed=$((failed+1))
        echo "| $repo | $branch | $prefix | add_failed |" >> "$REPORT"
        printf "%s\t%s\t%s\t%s\t%s\n" "$repo" "$branch" "$prefix" "subtree" "add_failed" >> "$METHOD_TSV"
      fi
    fi
  fi
done

{
  echo
  echo "## Summary"
  echo "- added=$added"
  echo "- updated=$updated"
  echo "- failed=$failed"
  echo "- fallback_snapshot_on_fail=$FALLBACK_SNAPSHOT_ON_FAIL"
  echo
  echo "## Method Matrix"
  echo "- \`Archive/Index/$(basename "$METHOD_TSV")\`"
} >> "$REPORT"

cp -f "$METHOD_TSV" "$METHOD_TSV_LATEST"

echo "$REPORT"
