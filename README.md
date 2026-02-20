# Archivator_Agent

Utility repository for archival processing, segmentation, queue generation, and raw index verification.

## Tooling Surface
- `archivator_raw.py`
- `segmenter_blocks.py`
- `queue_maker.py`
- `queue_sampler.py`
- `raw_index_verify.py`
- `consistency_check.py`
- `byfile_rebuild.py`

## Local Validation
```bash
./.venv/bin/python -m pytest -q
scripts/test_entrypoint.sh --all
```

Modes:
- `scripts/test_entrypoint.sh --governance`
- `scripts/test_entrypoint.sh --control`

## AESS Integration
- Autostart hook: `scripts/aess_autostart.sh`
- Optional runtime service hook: `scripts/aess_service_start.sh` (create if background service startup is required)

## Global Ecosystem Matrix
- Build global classification/sort/index matrix across workspace:
```bash
scripts/ecosystem_matrix_builder.sh /home/architit/work
```
- Latest outputs:
  - `Archive/Index/ecosystem_file_matrix_latest.tsv`
  - `Archive/Index/ecosystem_memory_matrix_report_latest.md`

## Agent Matrix (Codex / Roaudter / Communication / Operator)
- Build focused ecosystem matrix with process streams + memory tiers:
```bash
scripts/agent_ecosystem_matrix_builder.sh /home/architit/work
```
- Latest outputs:
  - `Archive/Index/agent_ecosystem_file_matrix_latest.tsv`
  - `Archive/Index/agent_ecosystem_memory_flow_report_latest.md`
  - `Archive/Index/github_subtree_matrix_latest.tsv`
  - `Archive/Index/github_subtree_report_latest.md`
  - `Archive/Index/subtree_registry.tsv`
  - `Archive/Index/archivator_extended_agent_matrix_report_latest.md`

- Extended target set:
```bash
scripts/agent_ecosystem_matrix_builder.sh /home/architit/work \
  "LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE"
```

## Global Refresh (Control Plane)
```bash
scripts/archivator_global_refresh.sh /home/architit/work
```

- Strict mode:
```bash
scripts/archivator_global_refresh.sh /home/architit/work \
  "LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE" \
  strict
```

## Anomaly Gate
```bash
scripts/agent_matrix_anomaly_gate.sh Archive/Index/agent_ecosystem_file_matrix_latest.tsv
```

## Public Export (OneDrive / Google Workspace)
```bash
GATEWAY_ONEDRIVE_ROOT=/path/to/OneDrive \
GATEWAY_GWORKSPACE_ROOT=/path/to/GoogleWorkspace \
scripts/publish_archivator_public_packets.sh
```

## Subtree Drift Gate
```bash
STRICT_FAIL=1 scripts/subtree_dependency_drift_gate.sh \
  /home/architit/work \
  Archive/Index/subtree_registry.tsv
```

## Daily Automation
```bash
scripts/run_daily_refresh_and_export.sh \
  /home/architit/work \
  "LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE" \
  strict
```

Install cron job (idempotent):
```bash
scripts/install_daily_refresh_cron.sh
```

## Git Subtree Formation (All Repositories)
Primary formation in clean hub repository:
```bash
scripts/form_all_repo_subtrees_in_hub.sh /home/architit/work /home/architit/work/Archivator_Agent/SubtreeHub repos
```

Notes:
- `git subtree add/pull` requires a clean working tree; production formation is done in `SubtreeHub`.
- Reconciliation evidence:
  - `Archive/Index/subtree_hub_formation_report_20260217_040306.md`
  - `Archive/Index/subtree_hub_reconciliation_20260217_040306.md`
  - `Archive/Index/subtree_hub_method_matrix_latest.tsv`
  - `SUBTREE_FALLBACK_POLICY_2026-02-17.md`

Daily runner includes subtree hub sync stage (default on):
- `DAILY_SUBTREE_HUB_SYNC=1`
- `SUBTREE_HUB_FAIL_POLICY=warn|strict`
