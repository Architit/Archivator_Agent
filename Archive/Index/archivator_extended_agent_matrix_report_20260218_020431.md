# Archivator Extended Agent Matrix Report — 20260218_020431

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
| LAM-Codex_Agent | codex_core | 99 | 473992 |
| LAM_Comunication_Agent | communication_bus | 73 | 445773 |
| LAM_DATA_Src | memory_data_lake | 291 | 17310513 |
| Operator_Agent | operator_control | 80 | 526602 |
| Roaudter-agent | routing_core | 101 | 496788 |
| Trianiuma_MEM_CORE | memory_core | 9545 | 382865484 |

## Memory Tier Mix

| Repository | Operational | Long Term | Archival |
|---|---:|---:|---:|
| LAM-Codex_Agent | 35 | 19 | 45 |
| LAM_Comunication_Agent | 14 | 14 | 45 |
| LAM_DATA_Src | 8 | 238 | 45 |
| Operator_Agent | 19 | 15 | 46 |
| Roaudter-agent | 41 | 15 | 45 |
| Trianiuma_MEM_CORE | 723 | 8722 | 100 |

## Process Stream Mix

| Repository | Routing | Transport | Execution | Contract Control | Validation | Orchestration | Governance | General |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| LAM-Codex_Agent | 0 | 3 | 1 | 4 | 7 | 3 | 4 | 77 |
| LAM_Comunication_Agent | 0 | 2 | 0 | 4 | 2 | 3 | 4 | 58 |
| LAM_DATA_Src | 0 | 0 | 0 | 4 | 5 | 3 | 3 | 276 |
| Operator_Agent | 0 | 1 | 3 | 9 | 6 | 3 | 3 | 55 |
| Roaudter-agent | 10 | 0 | 1 | 4 | 17 | 5 | 4 | 60 |
| Trianiuma_MEM_CORE | 0 | 0 | 0 | 4 | 667 | 3 | 6 | 8865 |

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
- warnings=2
- anomalies=0

## Recommendation
1. Keep strict refresh mode enabled for daily runs.
2. Track memory-heavy repositories ('LAM_DATA_Src', 'Trianiuma_MEM_CORE') with role-aware thresholds.
3. Regenerate subtree registry after each target-repo topology change.
