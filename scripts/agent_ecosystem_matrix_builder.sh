#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="${1:-$(cd "$ROOT/.." && pwd)}"
TARGETS_RAW="${2:-LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE}"
OUT_DIR="$ROOT/Archive/Index"
TS="$(date +%Y%m%d_%H%M%S)"

AGENT_TSV="$OUT_DIR/agent_ecosystem_file_matrix_${TS}.tsv"
AGENT_MD="$OUT_DIR/agent_ecosystem_memory_flow_report_${TS}.md"
SUBTREE_TSV="$OUT_DIR/github_subtree_matrix_${TS}.tsv"
SUBTREE_MD="$OUT_DIR/github_subtree_report_${TS}.md"

LATEST_AGENT_TSV="$OUT_DIR/agent_ecosystem_file_matrix_latest.tsv"
LATEST_AGENT_MD="$OUT_DIR/agent_ecosystem_memory_flow_report_latest.md"
LATEST_SUBTREE_TSV="$OUT_DIR/github_subtree_matrix_latest.tsv"
LATEST_SUBTREE_MD="$OUT_DIR/github_subtree_report_latest.md"

mkdir -p "$OUT_DIR"

read -r -a TARGETS <<< "$TARGETS_RAW"

repo_role() {
  case "$1" in
    LAM-Codex_Agent) echo "codex_core" ;;
    Roaudter-agent) echo "routing_core" ;;
    LAM_Comunication_Agent) echo "communication_bus" ;;
    Operator_Agent) echo "operator_control" ;;
    LAM_DATA_Src) echo "memory_data_lake" ;;
    Trianiuma_MEM_CORE) echo "memory_core" ;;
    *) echo "unknown_agent" ;;
  esac
}

classify_domain() {
  local rel="$1"
  case "$rel" in
    *.py|*.sh|*.ps1|*.ts|*.tsx|*.js|*.jsx|*.go|*.rs|*.java|*.cs|*.cpp|*.c|*.h|*.hpp|*.toml|*.yaml|*.yml|*.ini)
      echo "code"
      ;;
    *.md|*.rst|*.adoc|*.txt)
      echo "docs"
      ;;
    *.json|*.jsonl|*.csv|*.tsv|*.xml|*.sqlite|*.db)
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
    */Archive/*|*/SourceChats/*|*/memory/*|*/archive/*|*/logs/*|*.tgz|*.zip|*.7z)
      echo "archival"
      ;;
    */src/*|*/scripts/*|*/tests/*|*/agent/*|*/schemas/*|*/reqs/*)
      echo "operational"
      ;;
    */ROADMAP.md|*/DEV_LOGS.md|*/WORKFLOW_SNAPSHOT_*|*/SYSTEM_STATE*|*/INTERACTION_PROTOCOL.md|*/GATEWAY_ACCESS_CONTRACT.md|*/WB01_*|*/TEST_*MATRIX*.md|*/README.md)
      echo "long_term"
      ;;
    *)
      echo "long_term"
      ;;
  esac
}

classify_process_stream() {
  local rel="$1"
  case "$rel" in
    */src/*/providers/*|*/src/*/router.py|*/src/*/policy.py|*/src/*/registry.py)
      echo "routing"
      ;;
    */src/*/integrations/*|*/src/agents/com_agent.py|*/src/interfaces/com_agent_interface.py|*/agent/queue_manager.py)
      echo "transport"
      ;;
    */src/*/core/*|*/src/*/core.py|*/agent/block_reader.py|*/agent/result_writer.py|*/agent/error_writer.py)
      echo "execution"
      ;;
    */schemas/*|*/WORKFLOW_SNAPSHOT_CONTRACT.md|*/SYSTEM_STATE_CONTRACT.md|*/INTERACTION_PROTOCOL.md|*/GATEWAY_ACCESS_CONTRACT.md)
      echo "contract_control"
      ;;
    */tests/*)
      echo "validation"
      ;;
    */scripts/*)
      echo "orchestration"
      ;;
    */README.md|*/ROADMAP.md|*/DEV_LOGS.md|*/WB01_*)
      echo "governance"
      ;;
    *)
      echo "general"
      ;;
  esac
}

printf "repo\tagent_role\tpath\tdomain\tmemory_tier\tprocess_stream\tsize_bytes\tmtime_utc\n" > "$AGENT_TSV"

for repo in "${TARGETS[@]}"; do
  repo_path="$WORK_ROOT/$repo"
  if [[ ! -d "$repo_path" ]]; then
    continue
  fi
  role="$(repo_role "$repo")"
  while IFS= read -r -d '' f; do
    rel="${f#$WORK_ROOT/}"
    domain="$(classify_domain "$rel")"
    tier="$(classify_memory_tier "$rel")"
    stream="$(classify_process_stream "$rel")"
    size="$(stat -c '%s' "$f" 2>/dev/null || echo 0)"
    mtime="$(date -u -d "@$(stat -c '%Y' "$f")" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo unknown)"
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
      "$repo" "$role" "$rel" "$domain" "$tier" "$stream" "$size" "$mtime" >> "$AGENT_TSV"
  done < <(find "$repo_path" -type f \
    -not -path "*/.git/*" \
    -not -path "*/.venv/*" \
    -not -path "*/__pycache__/*" \
    -not -path "*/.pytest_cache/*" \
    -not -name "*.pyc" \
    -not -name "desktop.ini" \
    -print0)
done

{
  head -n 1 "$AGENT_TSV"
  tail -n +2 "$AGENT_TSV" | sort -t $'\t' -k1,1 -k5,5 -k6,6 -k3,3
} > "${AGENT_TSV}.sorted"
mv "${AGENT_TSV}.sorted" "$AGENT_TSV"

{
  echo "# Agent Ecosystem Memory/Flow Report — $TS"
  echo
  echo "Work root: \`$WORK_ROOT\`"
  echo "Targets: \`$TARGETS_RAW\`"
  echo
  echo "## 1. Repository Footprint"
  echo
  echo "| Repository | Agent Role | Files | Bytes |"
  echo "|---|---|---:|---:|"
  awk -F '\t' 'NR>1{cnt[$1]++; sz[$1]+=$7; role[$1]=$2} END {for (r in cnt) printf("| %s | %s | %d | %d |\n", r, role[r], cnt[r], sz[r])}' "$AGENT_TSV" | sort
  echo
  echo "## 2. Memory Tier Distribution"
  echo
  echo "| Repository | Operational | Long Term | Archival |"
  echo "|---|---:|---:|---:|"
  awk -F '\t' 'NR>1{repos[$1]=1; k[$1 FS $5]++} END {for (r in repos) printf("| %s | %d | %d | %d |\n", r, k[r FS "operational"]+0, k[r FS "long_term"]+0, k[r FS "archival"]+0)}' "$AGENT_TSV" | sort
  echo
  echo "## 3. Process Stream Distribution"
  echo
  echo "| Repository | Routing | Transport | Execution | Contract Control | Validation | Orchestration | Governance | General |"
  echo "|---|---:|---:|---:|---:|---:|---:|---:|---:|"
  awk -F '\t' 'NR>1{repos[$1]=1; k[$1 FS $6]++} END {for (r in repos) printf("| %s | %d | %d | %d | %d | %d | %d | %d | %d |\n", r, k[r FS "routing"]+0, k[r FS "transport"]+0, k[r FS "execution"]+0, k[r FS "contract_control"]+0, k[r FS "validation"]+0, k[r FS "orchestration"]+0, k[r FS "governance"]+0, k[r FS "general"]+0)}' "$AGENT_TSV" | sort
  echo
  echo "## 4. Largest Files (Top 40)"
  echo
  echo "| Repository | Path | Stream | Tier | Bytes |"
  echo "|---|---|---|---|---:|"
  awk -F '\t' 'NR>1{printf("%s\t%s\t%s\t%s\t%s\n",$1,$3,$6,$5,$7)}' "$AGENT_TSV" | sort -t $'\t' -k5,5nr | awk -F '\t' 'NR<=40{printf("| %s | `%s` | %s | %s | %s |\n",$1,$2,$3,$4,$5)}'
  echo
  echo "## Artifacts"
  echo "- Agent matrix TSV: \`$AGENT_TSV\`"
  echo "- Latest TSV pointer: \`$LATEST_AGENT_TSV\`"
  echo "- Latest report pointer: \`$LATEST_AGENT_MD\`"
} > "$AGENT_MD"

printf "repo\trepo_path\tgit_kind\thead_commit\tbranch\tremote_count\tis_dirty\ttracked_files\tsubtree_candidate\n" > "$SUBTREE_TSV"
for repo in "${TARGETS[@]}"; do
  repo_path="$WORK_ROOT/$repo"
  [[ -d "$repo_path" ]] || continue

  git_kind="none"
  if [[ -d "$repo_path/.git" ]]; then
    git_kind="standalone"
  elif [[ -f "$repo_path/.git" ]]; then
    git_kind="linked_gitdir"
  fi

  head_commit="n/a"
  branch="n/a"
  remote_count=0
  is_dirty="unknown"
  tracked_files=0
  subtree_candidate="no"

  if git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    head_commit="$(git -C "$repo_path" rev-parse --short HEAD 2>/dev/null || echo n/a)"
    branch="$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo n/a)"
    remote_count="$(git -C "$repo_path" remote | wc -l | tr -d ' ')"
    if [[ -z "$(git -C "$repo_path" status --porcelain 2>/dev/null)" ]]; then
      is_dirty="no"
    else
      is_dirty="yes"
    fi
    tracked_files="$(git -C "$repo_path" ls-files | wc -l | tr -d ' ')"
    if [[ "${remote_count:-0}" -gt 0 ]]; then
      subtree_candidate="yes"
    fi
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$repo" "$repo_path" "$git_kind" "$head_commit" "$branch" "$remote_count" "$is_dirty" "$tracked_files" "$subtree_candidate" >> "$SUBTREE_TSV"
done

{
  head -n 1 "$SUBTREE_TSV"
  tail -n +2 "$SUBTREE_TSV" | sort -t $'\t' -k1,1
} > "${SUBTREE_TSV}.sorted"
mv "${SUBTREE_TSV}.sorted" "$SUBTREE_TSV"

{
  echo "# GitHub Subtree Readiness Report — $TS"
  echo
  echo "## Target Scope"
  echo "- $TARGETS_RAW"
  echo
  echo "## Repository Topology"
  echo
  echo "| Repository | Git Kind | HEAD | Branch | Remotes | Dirty | Tracked Files | Subtree Candidate |"
  echo "|---|---|---|---|---:|---|---:|---|"
  awk -F '\t' 'NR>1{printf("| %s | %s | `%s` | %s | %s | %s | %s | %s |\n",$1,$3,$4,$5,$6,$7,$8,$9)}' "$SUBTREE_TSV"
  echo
  echo "## Controls"
  echo "- Every candidate must be represented in \`SUBTREE_REGISTRY_CONTRACT.md\` policy flow."
  echo "- Any update to candidate repositories must trigger matrix regeneration and delta evidence packaging."
  echo
  echo "## Artifacts"
  echo "- Subtree matrix TSV: \`$SUBTREE_TSV\`"
  echo "- Latest subtree TSV pointer: \`$LATEST_SUBTREE_TSV\`"
  echo "- Latest subtree report pointer: \`$LATEST_SUBTREE_MD\`"
} > "$SUBTREE_MD"

cp -f "$AGENT_TSV" "$LATEST_AGENT_TSV"
cp -f "$AGENT_MD" "$LATEST_AGENT_MD"
cp -f "$SUBTREE_TSV" "$LATEST_SUBTREE_TSV"
cp -f "$SUBTREE_MD" "$LATEST_SUBTREE_MD"

echo "$AGENT_MD"
echo "$SUBTREE_MD"
