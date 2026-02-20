# Archivator Extended Agent Matrix Report — 20260217_035120

## Scope
- LAM-Codex_Agent
- Roaudter-agent
- LAM_Comunication_Agent
- Operator_Agent
- LAM_DATA_Src
- Trianiuma_MEM_CORE

## Footprint

| Repository | Role | Files | Bytes |
|---|---|---:|---:|
| LAM-Codex_Agent | codex_core | 54 | 68034 |
| LAM_Comunication_Agent | communication_bus | 28 | 39847 |
| LAM_DATA_Src | memory_data_lake | 237 | 16859659 |
| Operator_Agent | operator_control | 27 | 111995 |
| Roaudter-agent | routing_core | 56 | 90713 |
| Trianiuma_MEM_CORE | memory_core | 9490 | 382412789 |

## Memory Tier Mix

| Repository | Operational | Long Term | Archival |
|---|---:|---:|---:|
| LAM-Codex_Agent | 35 | 19 | 0 |
| LAM_Comunication_Agent | 14 | 14 | 0 |
| LAM_DATA_Src | 3 | 234 | 0 |
| Operator_Agent | 13 | 14 | 0 |
| Roaudter-agent | 41 | 15 | 0 |
| Trianiuma_MEM_CORE | 717 | 8718 | 55 |

## Process Stream Mix

| Repository | Routing | Transport | Execution | Contract Control | Validation | Orchestration | Governance | General |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| LAM-Codex_Agent | 0 | 3 | 1 | 4 | 7 | 3 | 4 | 32 |
| LAM_Comunication_Agent | 0 | 2 | 0 | 4 | 2 | 3 | 4 | 13 |
| LAM_DATA_Src | 0 | 0 | 0 | 4 | 1 | 2 | 3 | 227 |
| Operator_Agent | 0 | 1 | 3 | 9 | 1 | 2 | 3 | 8 |
| Roaudter-agent | 10 | 0 | 1 | 4 | 17 | 5 | 4 | 15 |
| Trianiuma_MEM_CORE | 0 | 0 | 0 | 4 | 662 | 2 | 6 | 8816 |

## Subtree Registry Snapshot

| Subtree | Upstream | Ref | Commit | Cadence |
|---|---|---|---|---|
| LAM-Codex_Agent | https://github.com/Architit/LAM-Codex_Agent.git | main | `886a4a3` | daily |
| LAM_Comunication_Agent | https://github.com/Architit/LAM_Communication_Agent.git | main | `f0373fb` | daily |
| LAM_DATA_Src | https://github.com/Architit/LAM_DATA_Src.git | main | `0f3555e` | daily |
| Operator_Agent | https://github.com/Architit/Operator_Agent.git | main | `76f38c6` | daily |
| Roaudter-agent | https://github.com/Architit/Roaudter-agent.git | master | `7faf14f` | daily |
| Trianiuma_MEM_CORE | https://github.com/Architit/Trianiuma_MEM_CORE.git | main | `4ed0e979` | daily |

## Anomaly Gate
- Source: `/home/architit/work/Archivator_Agent/Archive/Index/agent_matrix_anomaly_report_latest.md`
## Summary
- warnings=0
- anomalies=0

## Recommendation
1. Keep strict refresh mode enabled for daily runs.
2. Track memory-heavy repositories ('LAM_DATA_Src', 'Trianiuma_MEM_CORE') with role-aware thresholds.
3. Regenerate subtree registry after each target-repo topology change.
