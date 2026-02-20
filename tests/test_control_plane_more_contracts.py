from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]


def test_subtree_fallback_policy_contains_modes():
    policies = sorted(REPO_ROOT.glob("SUBTREE_FALLBACK_POLICY_*.md"))
    assert policies, "missing SUBTREE_FALLBACK_POLICY_*.md"
    text = policies[-1].read_text(encoding="utf-8")
    assert "`subtree` (preferred)" in text
    assert "`snapshot` (fallback)" in text
    assert "subtree_hub_method_matrix_latest.tsv" in text


def test_daily_runner_has_strict_scope_guard():
    text = (REPO_ROOT / "scripts" / "run_daily_refresh_and_export.sh").read_text(
        encoding="utf-8"
    )
    assert 'MODE="${3:-strict}"' in text
    assert 'ALLOW_NARROW_SCOPE="${ALLOW_NARROW_SCOPE:-0}"' in text
    assert "strict mode requires WORK_ROOT=" in text


def test_daily_runner_has_retry_and_blocked_report_flow():
    text = (REPO_ROOT / "scripts" / "run_daily_refresh_and_export.sh").read_text(
        encoding="utf-8"
    )
    assert "for attempt in 1 2 3" in text
    assert "daily_export_blocked_" in text
    assert "publish_archivator_public_packets.sh" in text


def test_cron_installer_contains_marker_and_targets_mode():
    text = (REPO_ROOT / "scripts" / "install_daily_refresh_cron.sh").read_text(
        encoding="utf-8"
    )
    assert 'MARK="# ARCHIVATOR_DAILY_REFRESH_JOB"' in text
    assert 'TARGETS="${3:-LAM-Codex_Agent Roaudter-agent LAM_Comunication_Agent Operator_Agent LAM_DATA_Src Trianiuma_MEM_CORE}"' in text
    assert 'MODE="${4:-strict}"' in text


def test_subtree_hub_script_records_method_matrix_outputs():
    text = (REPO_ROOT / "scripts" / "form_all_repo_subtrees_in_hub.sh").read_text(
        encoding="utf-8"
    )
    assert "subtree_hub_method_matrix_" in text
    assert "subtree_hub_method_matrix_latest.tsv" in text
    assert 'FALLBACK_SNAPSHOT_ON_FAIL="${FALLBACK_SNAPSHOT_ON_FAIL:-1}"' in text
