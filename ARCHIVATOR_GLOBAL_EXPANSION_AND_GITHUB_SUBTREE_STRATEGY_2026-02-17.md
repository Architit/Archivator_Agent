# Archivator Global Expansion and GitHub Subtree Strategy — 2026-02-17

## Mission
Scale `Archivator_Agent` from local archival toolchain to ecosystem-level memory/index control plane with subtree-aware architecture.

## Global Architecture Target

### Layer L0 — Ingestion
- Inputs:
  - workspace repositories,
  - external imports (OneDrive / Google Workspace),
  - staged sync payloads.
- Output:
  - normalized file stream for indexing.

### Layer L1 — Classification
- Domain classification (`code/docs/data/telemetry/media/other`).
- Memory-tier mapping (`operational/long_term/archival`).

### Layer L2 — Indexing
- Raw index (`raw.index.jsonl` lineage).
- Block index (`blocks.index.jsonl` lineage).
- Ecosystem matrix index (`ecosystem_file_matrix_*.tsv`).

### Layer L3 — Governance & Strategy
- Contract documents and roadmap synchronization.
- Drift detection between claimed architecture and indexed reality.

### Layer L4 — External Publication
- Gateway-based export packages for public-level strategy artifacts.
- Cross-system propagation evidence (OneDrive/GWorkspace/GitHub).

## Process Flow (Global)
1. Scan workspace and external inputs.
2. Build deterministic matrix.
3. Aggregate by repo/tier/domain.
4. Detect hotspots:
  - operational overload,
  - archival bloat,
  - governance under-coverage.
5. Emit strategy deltas into roadmap/logs.
6. Publish public intelligence packages externally.

## GitHub Subtree Strategy

### Why Subtree for Global Archivator Scale
- Preserves monorepo-like visibility with polyrepo ownership.
- Avoids submodule runtime dependency breaks during indexing.
- Enables deterministic snapshots for historical memory chains.

### Subtree Expansion Model
1. `subtree_registry`:
  - canonical map of subtree path -> upstream repo -> pinned commit/tag.
2. `subtree_sync_window`:
  - controlled update cycles (e.g., daily/weekly).
3. `subtree_evidence_pack`:
  - include commit delta, index delta, matrix delta.
4. `subtree_reconciliation`:
  - compare subtree content with gateway exports and ecosystem matrix.

### Mandatory Subtree Controls
- No unmanaged subtree path allowed.
- Every subtree update must regenerate matrix and archival index deltas.
- Every subtree update must be traceable in `DEV_LOGS.md`.

## Expansion Waves

### Wave G1 — Matrix Foundation (done/in progress)
- Introduce ecosystem matrix framework and builder script.
- Produce per-repo tier/domain distributions.

### Wave G2 — Process Flow Hardening
- Add scheduled matrix rebuild cadence.
- Add anomaly flags for index drift and memory-tier imbalance.

### Wave G3 — Subtree Integration
- Introduce subtree registry contract and sync procedure.
- Add subtree delta analysis into matrix reports.

### Wave G4 — Ecosystem Control Plane
- Consolidate Archivator outputs into operator-facing strategy dashboard artifacts.
- Establish cross-repo policy gates driven by matrix evidence.

## Immediate Action Backlog
1. Generate and persist latest matrix artifacts under `Archive/Index`.
2. Add subtree registry contract document (`SUBTREE_REGISTRY_CONTRACT.md`).
3. Add matrix anomaly thresholds and fail/warn policy.
4. Add scheduled execution script for nightly global matrix refresh.
