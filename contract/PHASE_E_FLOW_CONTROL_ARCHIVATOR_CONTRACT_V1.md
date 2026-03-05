# PHASE_E_FLOW_CONTROL_ARCHIVATOR_CONTRACT_V1

## Scope
- owner_repo: `Archivator_Agent`
- phase: `PHASE_E_WAVE_1`
- task_id: `phaseE_archivator_flow_control_wave1_execution`
- status: `DONE`

## Objective
Extend archivator flow-control governance markers for Phase E wave-1 while preserving hybrid refresh runtime invariants.

## Required Markers
- `phase_e_flow_control_archivator_contract=ok`
- `phase_e_cbfc_refresh_path=ok`
- `phase_e_heartbeat_marker_scan=ok`
- `phase_e_outlier_isolation_marker_scan=ok`

## Test Wiring Contract
- `scripts/test_entrypoint.sh --flow-control` MUST execute Phase E archivator flow-control checks.
- `scripts/test_entrypoint.sh --patch-runtime` MUST remain green as non-regression gate.

## Constraints
- derivation_only execution
- fail-fast on violated preconditions
- no-new-agents-or-repos
