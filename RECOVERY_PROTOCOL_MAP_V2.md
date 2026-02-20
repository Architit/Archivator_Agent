# RECOVERY PROTOCOL MAP V2

version: v2.0.0
status: ACTIVE
effective_utc: 2026-02-16T09:16:10Z
scope: ecosystem recovery topology map

## Recovery Map
| recovery_domain | trigger | block_state | primary_protocol | verification_surface |
|---|---|---|---|---|
| governance | decision conflict / missing closure | BLOCKED_PENDING_GOVERNANCE_DECISION_ON_CONFLICT | `GOVERNANCE_DECISION_PROTOCOL_V2.md` | `GOV_STATUS.md` + `DEV_LOGS.md` |
| tooling | unsafe shell composition / parser mismatch | BLOCKED_PENDING_ENVIRONMENT_DECISION_ON_CONFLICT | `TOOL_EXECUTION_SAFETY_PROTOCOL_V2.md` | preflight output + logs |
| environment | profile mismatch / runtime gate fault | BLOCKED_PENDING_ENVIRONMENT_DECISION_ON_CONFLICT | `ENVIRONMENT_RUNTIME_PROTOCOL_V2.md` | `GOV_STATUS.md` + snapshot |
| interface | interface transition conflict | BLOCKED_PENDING_INTERFACE_DECISION_ON_CONFLICT | `INTERFACE_LIFECYCLE_PROTOCOL_V2.md` | interface compliance report |
| logic | consistency/transition fault | BLOCKED_PENDING_LOGIC_DECISION_ON_CONFLICT | `LOGIC_LIFECYCLE_PROTOCOL_V2.md` | logic gates + logs |
| profile | profile compatibility mismatch | BLOCKED_PENDING_PROFILE_DECISION_ON_CONFLICT | `PROFILE_LIFECYCLE_PROTOCOL_V2.md` | profile gates + logs |
| deadloop | repetitive non-converging cycles | BLOCKED_PENDING_REMEDIATION | `ECOSYSTEM_ANTI_SAMSARA_DEADLOOP_PROTOCOL.md` | watchdog tuple + closure SLA |

## Cross-Map Rule
- if two or more domains are impacted, recovery sequence is:
  governance -> tooling/environment -> interface/logic/profile -> reactivation.
