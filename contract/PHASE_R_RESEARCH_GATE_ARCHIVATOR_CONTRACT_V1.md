# PHASE_R_RESEARCH_GATE_ARCHIVATOR_CONTRACT_V1

status: ACTIVE
derivation_mode: DERIVATION_ONLY

## Scope
- repository: `Archivator_Agent`
- phase: `R` (Research Gate)
- task_id: `phaseR_archivator_wave1_execution`

## Required Markers
- `phase_r_research_gate_archivator_contract=ok`
- `phase_r_transport_benchmark_matrix=ok`
- `phase_r_vector_engine_benchmark_matrix=ok`
- `phase_r_wake_on_demand_trigger_check=ok`

## Benchmark Matrix (must be evidence-backed)
- transport: `ZeroMQ` vs `gRPC` vs `FastAPI`
- vector engine: `FAISS` vs `LanceDB` vs `SQLite-vec/SQLite-VSS`
- wake-on-demand: `systemd/socket-activation` trigger readiness and cold-start behavior

## Fail-Fast
- missing matrix dimension => `BLOCKED`
- missing comparable metric tuple => `BLOCKED`
- ambiguous evidence source => `BLOCKED`

## Protocol Marker
- `phase_r_research_gate_archivator_contract=ok`
