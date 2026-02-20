# Ecosystem Data Matrix Framework — Archivator_Agent (2026-02-17)

## Objective
Define a global matrix model for ecosystem-wide determination, sorting, and indexing of:
- code artifacts,
- documentation artifacts,
- structured/unstructured data,
- operational memory,
- long-term memory,
- archival memory.

## Canonical Matrix Dimensions

### D1. Repository
- Source repository identity (`repo`).

### D2. Artifact Path
- Full workspace-relative path (`path`).

### D3. Domain Class
- `code`
- `docs`
- `data_structured`
- `telemetry`
- `media`
- `other`

### D4. Memory Tier
- `operational` (active execution/process/test/control surfaces)
- `long_term` (governance/contracts/strategic continuity)
- `archival` (historical memory, frozen snapshots, deep archives)

### D5. Volume Signals
- `size_bytes`
- `mtime_utc`

## Implementation Artifact
- Builder script:
  - `scripts/ecosystem_matrix_builder.sh`
- Generated outputs:
  - `Archive/Index/ecosystem_file_matrix_<ts>.tsv`
  - `Archive/Index/ecosystem_memory_matrix_report_<ts>.md`
  - latest pointers:
    - `Archive/Index/ecosystem_file_matrix_latest.tsv`
    - `Archive/Index/ecosystem_memory_matrix_report_latest.md`

## Sorting & Indexing Policy
1. Primary sort key: `repo`.
2. Secondary sort key: `memory_tier`.
3. Tertiary sort key: `domain`.
4. Optional tie-breakers: `size_bytes` desc, `mtime_utc` desc.

## Operational Use Cases
1. Find high-density archival zones by repository.
2. Detect operational-memory overload (too much active-process surface).
3. Track governance drift (long-term memory artifacts missing vs expected).
4. Prepare export/import packages by memory tier.

## Quality Gates
1. Matrix generation must be reproducible from script.
2. Every repo in workspace must have at least one indexed artifact row.
3. Report must include per-repo tier and domain distributions.
4. Matrix must exclude transient technical noise (`.git`, `.venv`, caches).
