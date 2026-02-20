# Subtree Fallback Policy — 2026-02-17

## Purpose

Define deterministic strategy for repository ingestion into `SubtreeHub` when native `git subtree` transport fails.

## Modes

1. `subtree` (preferred)
- `git subtree add/pull --squash`
- Preserves upstream lineage semantics.

2. `snapshot` (fallback)
- Workspace rsync snapshot (excluding `.git`, `.venv`, caches) committed into hub prefix.
- Used when subtree fetch/add/pull fails due transport/object issues.

## Automatic Decision Rules

Applied by:
- `scripts/form_all_repo_subtrees_in_hub.sh`

Rules:
1. Attempt native subtree first.
2. If fetch/add/pull fails and `FALLBACK_SNAPSHOT_ON_FAIL=1`, apply snapshot fallback.
3. Record method and status to:
   - `Archive/Index/subtree_hub_method_matrix_latest.tsv`
4. Keep fallback events auditable in formation report and commit history.

## Daily Runner Integration

- `scripts/run_daily_refresh_and_export.sh` executes subtree hub sync by default:
  - `DAILY_SUBTREE_HUB_SYNC=1`
- Failure policy:
  - `SUBTREE_HUB_FAIL_POLICY=warn` (default) keeps daily control plane alive.
  - `SUBTREE_HUB_FAIL_POLICY=strict` fails daily run on subtree hub sync failure.

## Safety Constraints

1. Strict mode daily run requires full workspace scope unless explicitly overridden.
2. Snapshot fallback must never include `.git` internals.
3. Every fallback event must produce machine-readable evidence (`method matrix`) and human-readable report.
