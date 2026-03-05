# GitHub Subtree Readiness Report — 20260305_030429

## Target Scope
- LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE

## Repository Topology

| Repository | Git Kind | HEAD | Branch | Remotes | Dirty | Tracked Files | Subtree Candidate |
|---|---|---|---|---:|---|---:|---|
| LAM-Codex_Agent | standalone | `e650536` | main | 1 | yes | 314 | yes |
| LAM_Comunication_Agent | standalone | `fbf0b63` | main | 1 | yes | 279 | yes |
| LAM_DATA_Src | standalone | `32702b3` | main | 1 | no | 122 | yes |
| Operator_Agent | standalone | `553760a` | main | 1 | yes | 285 | yes |
| Roaudter-agent | standalone | `6c55aa2` | master | 1 | yes | 301 | yes |
| Trianiuma_MEM_CORE | standalone | `c49d0e72` | main | 1 | yes | 9741 | yes |

## Controls
- Every candidate must be represented in `SUBTREE_REGISTRY_CONTRACT.md` policy flow.
- Any update to candidate repositories must trigger matrix regeneration and delta evidence packaging.

## Artifacts
- Subtree matrix TSV: `/home/architit/work/Archivator_Agent/Archive/Index/github_subtree_matrix_20260305_030429.tsv`
- Latest subtree TSV pointer: `/home/architit/work/Archivator_Agent/Archive/Index/github_subtree_matrix_latest.tsv`
- Latest subtree report pointer: `/home/architit/work/Archivator_Agent/Archive/Index/github_subtree_report_latest.md`
