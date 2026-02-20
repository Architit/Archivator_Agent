# INTERNAL KEY IDENTITY RUNTIME MAPPING CONTRACT

mode: lifeflowstream
security_model: zero trust
scope: coverage-matrix identity classes mapped to runtime RBAC roles for test execution

## Purpose
- Provide deterministic mapping from governance identity classes to currently implemented runtime roles.
- Unblock tuple-level allow/deny execution in Wave-1 without inventing undocumented roles.

## Runtime Source
- implementation: `Trianiuma_MEM_CORE/RAM_MEM/Sys/autopilot_package/service/rbac.py`
- runtime roles detected: `guest`, `resident`, `user`, `avatar`, `admin`, `creator`

## Canonical Mapping (Wave-1 execution scope)
- admin -> admin
- operator -> user
- developer -> user
- service_account -> resident
- machine_to_machine -> resident
- automation_scheduler -> resident

## Path-Class Action Proxies (for RBAC testability)
- cli_local -> allow action: `open`
- api_http_grpc -> allow action: `run`
- inter_service_channel -> allow action: `run`
- inter_gateway_flow -> allow action: `run`
- scheduler_jobs -> allow action: `run`

## Deny Probe Actions
- admin tuple deny probe -> `change_models` (expected deny in current RBAC set)
- non-admin tuples deny probe -> `install` (expected deny for `user`/`resident`)

## Constraints
- This mapping is execution-scoped and does not claim gateway runtime parity (`GW-*` IDs remain governance-level labels).
- Completion remains blocked until key-version validation + MFA evidence are captured where required.
