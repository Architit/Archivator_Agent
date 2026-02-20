# MODULE DEPENDENCY MAP V2

version: v2.0.0
status: ACTIVE
effective_utc: 2026-02-16T06:06:10Z
scope: ecosystem module dependency topology

## Dependency Graph (declared)
| from_module | to_module | dependency_type | impact_class | rationale | status |
|---|---|---|---|---|---|
| MOD-CONTRACT-GOV | MOD-GOV-CORE | governance | MI_CRITICAL | protocol and write-order authority | ACTIVE |
| MOD-POLICY-GOV | MOD-GOV-CORE | governance | MI_HIGH | policy binding to core interaction protocol | ACTIVE |
| MOD-MODULE-GOV | MOD-GOV-CORE | governance | MI_HIGH | module lifecycle and gate orchestration | ACTIVE |
| MOD-SECURITY-IDENTITY | MOD-POLICY-GOV | policy | MI_HIGH | identity controls constrained by policy stack | ACTIVE |
| MOD-ARCHIVE | MOD-CONTRACT-GOV | evidence | MI_HIGH | ASR and evidence trace closure | ACTIVE |
| MOD-RELEASE-GATE | MOD-CONTRACT-GOV | release | MI_CRITICAL | release decisions derive from contract gates | ACTIVE |
| MOD-MIGRATION | MOD-RELEASE-GATE | release | MI_HIGH | migration readiness drives release path | ACTIVE |
| MOD-DEADLOOP-GUARD | MOD-GOV-CORE | runtime_flow | MI_HIGH | anti-loop gating depends on governance flow | ACTIVE |
| MOD-OBSERVABILITY | MOD-GOV-CORE | state_sync | MI_CRITICAL | SoT synchronization and checkpoint evidence | ACTIVE |

## Constraints
- Circular dependencies are prohibited.
- Any `MI_CRITICAL` edge change requires explicit redecision artifact and ASR.
- Missing dependency declaration is `MV_DEPENDENCY_CONFLICT`.
