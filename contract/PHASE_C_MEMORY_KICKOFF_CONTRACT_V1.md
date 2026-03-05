# PHASE_C_MEMORY_KICKOFF_CONTRACT_V1

version: v1.0.0
last_updated_utc: 2026-03-05T00:00:00Z
status: ACTIVE

## Purpose
- Start Phase C (Memory) using existing Archivator skeleton only.
- Preserve hybrid memory loop: physical archive + semantic index refresh.
- Provide deterministic, verifiable readiness markers for next memory waves.

## Required Memory Markers
1. `scripts/archivator_global_refresh.sh` MUST emit:
   - `global_refresh:semantic_index_hook=ok`
   - `global_refresh:physical_archive_hook=ok`
   - `global_refresh:hybrid_cycle=ok`
2. Runtime output MUST reference `Archive/Index` latest artifacts.
3. Kickoff evidence MUST be recorded in `gov/report` and `chronolog`.

## Isolation and Scope
- No new agents/repositories are allowed.
- Changes must remain inside `Archivator_Agent` scope.
- Memory kickoff is contracts-first and evidence-first.

## Verification Surface
- `tests/test_phase_c_memory_kickoff.py`
- `scripts/test_entrypoint.sh --memory`
- `scripts/test_entrypoint.sh --all`
