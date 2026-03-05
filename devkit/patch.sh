#!/usr/bin/env bash
set -euo pipefail

# DevKit patch helper.
#
# Usage:
#   cat change.patch | devkit/patch.sh
#
# Reads a unified diff from stdin, applies it via git in a reproducible way,
# and stages the result (canonical diff).

usage() {
  cat <<'USAGE'
DevKit patch helper.

Usage:
  cat change.patch | devkit/patch.sh --sha256 <hex>
  devkit/patch.sh --file <path> --sha256 <hex> [--task-id <id>] [--spec-file <path>]

Reads a unified diff, applies it via git in a reproducible way,
and stages the result.

Options:
  -h, --help          Show this help and exit.
  --file <path>       Read patch from file instead of stdin.
  --sha256 <hex>      Expected SHA-256 for patch artifact (required).
  --task-id <id>      Task identifier for integrity trace tuple.
  --spec-file <path>  Declarative task spec file used to compute spec_hash.
USAGE
}

PATCH_INPUT_FILE=""
EXPECTED_PATCH_SHA256="${PATCH_SHA256:-}"
TASK_ID="${TASK_ID:-unknown_task}"
SPEC_FILE="${TASK_SPEC_FILE:-}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --file)
      shift
      PATCH_INPUT_FILE="${1:-}"
      if [ -z "$PATCH_INPUT_FILE" ]; then
        echo "ERROR: --file requires a path argument" >&2
        echo >&2
        usage >&2
        exit 2
      fi
      ;;
    --sha256)
      shift
      EXPECTED_PATCH_SHA256="${1:-}"
      if [ -z "$EXPECTED_PATCH_SHA256" ]; then
        echo "ERROR: --sha256 requires a 64-hex argument" >&2
        exit 3
      fi
      ;;
    --task-id)
      shift
      TASK_ID="${1:-}"
      if [ -z "$TASK_ID" ]; then
        echo "ERROR: --task-id requires a value" >&2
        exit 3
      fi
      ;;
    --spec-file)
      shift
      SPEC_FILE="${1:-}"
      if [ -z "$SPEC_FILE" ]; then
        echo "ERROR: --spec-file requires a path argument" >&2
        exit 3
      fi
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      echo >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if ! command -v sha256sum >/dev/null 2>&1; then
  echo "ERROR: precondition_failure missing_sha256sum" >&2
  exit 3
fi

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git not found in PATH" >&2
  exit 2
fi

if [ -z "$EXPECTED_PATCH_SHA256" ]; then
  echo "ERROR: precondition_failure missing_patch_sha256" >&2
  exit 3
fi

if ! [[ "$EXPECTED_PATCH_SHA256" =~ ^[0-9a-fA-F]{64}$ ]]; then
  echo "ERROR: precondition_failure invalid_patch_sha256 expected_64_hex" >&2
  exit 3
fi
EXPECTED_PATCH_SHA256="$(printf '%s' "$EXPECTED_PATCH_SHA256" | tr '[:upper:]' '[:lower:]')"

# Spec is optional for backward compatibility; if absent we keep explicit null hash.
SPEC_HASH="spec_hash_unset"
if [ -n "$SPEC_FILE" ]; then
  if [ ! -r "$SPEC_FILE" ] || [ -d "$SPEC_FILE" ]; then
    echo "ERROR: precondition_failure unreadable_spec_file path=$SPEC_FILE" >&2
    exit 3
  fi
  SPEC_HASH="$(sha256sum -- "$SPEC_FILE" | awk '{print $1}')"
fi

# Must run inside a git worktree.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: not inside a git repository" >&2
  exit 2
fi

PATCH_FILE="$(mktemp)"
trap 'rm -f "$PATCH_FILE"' EXIT

if [ -n "$PATCH_INPUT_FILE" ]; then
  if [ ! -r "$PATCH_INPUT_FILE" ] || [ -d "$PATCH_INPUT_FILE" ]; then
    echo "ERROR: patch file not readable: $PATCH_INPUT_FILE" >&2
    exit 2
  fi
  if [ ! -s "$PATCH_INPUT_FILE" ]; then
    echo "ERROR: empty patch input" >&2
    exit 2
  fi
  cat -- "$PATCH_INPUT_FILE" > "$PATCH_FILE"
else
  # Read patch from stdin.
  if [ -t 0 ]; then
    echo "ERROR: no patch provided on stdin (pipe a .patch into devkit/patch.sh)" >&2
    echo >&2
    usage >&2
    exit 2
  fi

  # Prime stdin: fail fast on empty non-tty stdin (e.g. </dev/null), while preserving full stream.
  if ! IFS= read -r -n 1 first_char; then
    echo "ERROR: empty patch input" >&2
    exit 2
  fi
  printf %s "$first_char" > "$PATCH_FILE"
  cat >> "$PATCH_FILE"

  if [ ! -s "$PATCH_FILE" ]; then
    echo "ERROR: empty patch input" >&2
    exit 2
  fi
fi

ARTIFACT_HASH="$(sha256sum -- "$PATCH_FILE" | awk '{print $1}')"
if [ "$ARTIFACT_HASH" != "$EXPECTED_PATCH_SHA256" ]; then
  echo "ERROR: integrity_mismatch expected=$EXPECTED_PATCH_SHA256 actual=$ARTIFACT_HASH" >&2
  echo "trace: task_id=$TASK_ID spec_hash=$SPEC_HASH artifact_hash=$ARTIFACT_HASH apply_result=integrity_mismatch"
  exit 10
fi

APPLY_ERR_FILE="$(mktemp)"
trap 'rm -f "$PATCH_FILE" "$APPLY_ERR_FILE"' EXIT
if ! git apply --check --3way "$PATCH_FILE" 2>"$APPLY_ERR_FILE"; then
  err_msg="$(tr '\n' ' ' <"$APPLY_ERR_FILE" | sed 's/[[:space:]]\+/ /g')"
  echo "ERROR: conflict_detected $err_msg" >&2
  echo "trace: task_id=$TASK_ID spec_hash=$SPEC_HASH artifact_hash=$ARTIFACT_HASH apply_result=conflict_detected"
  exit 11
fi

# Apply and stage. Use 3-way merge, fail-fast on any conflict/apply error.
if ! git apply --index --3way "$PATCH_FILE" 2>"$APPLY_ERR_FILE"; then
  err_msg="$(tr '\n' ' ' <"$APPLY_ERR_FILE" | sed 's/[[:space:]]\+/ /g')"
  echo "ERROR: conflict_detected $err_msg" >&2
  echo "trace: task_id=$TASK_ID spec_hash=$SPEC_HASH artifact_hash=$ARTIFACT_HASH apply_result=conflict_detected"
  exit 11
fi

echo "OK: patch applied and staged."
echo "trace: task_id=$TASK_ID spec_hash=$SPEC_HASH artifact_hash=$ARTIFACT_HASH apply_result=applied"
git --no-pager diff --cached --stat
