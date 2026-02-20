# INCIDENT REPORT — SUBTREE PROTOCOL VIOLATION
Date: 2026-02-17
Severity: CRITICAL

## Summary
Detected mismatch between declared operation (git subtree migration) and actual action (filesystem path copy without git-subtree history workflow).

## Impact
- Created untracked subtree-like directories in multiple repos.
- No git-subtree commit lineage created.

## Containment Actions
1. Enumerated all target paths from Phase II/III reports.
2. Created backup archives of created prefix directories.
3. Removed created prefix directories from working trees.
4. Preserved evidence and rollback archives under:
   /tmp/INCIDENT_SUBTREE_PROTOCOL_VIOLATION_2026-02-17

## Required Corrective Action
- Re-execute migration using real `git subtree add/pull` with explicit remote/revision strategy.
- Keep governance in HOLD until approved execution plan for true subtree operations.
