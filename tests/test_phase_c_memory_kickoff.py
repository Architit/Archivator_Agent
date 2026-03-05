from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]


def test_phase_c_contract_exists_and_has_required_markers():
    text = (REPO_ROOT / "contract" / "PHASE_C_MEMORY_KICKOFF_CONTRACT_V1.md").read_text(encoding="utf-8")
    assert "PHASE_C_MEMORY_KICKOFF_CONTRACT_V1" in text
    assert "global_refresh:semantic_index_hook=ok" in text
    assert "global_refresh:physical_archive_hook=ok" in text
    assert "global_refresh:hybrid_cycle=ok" in text
    assert "Archive/Index" in text


def test_archivator_global_refresh_emits_hybrid_memory_markers():
    text = (REPO_ROOT / "scripts" / "archivator_global_refresh.sh").read_text(encoding="utf-8")
    assert "global_refresh:semantic_index_hook=ok" in text
    assert "global_refresh:physical_archive_hook=ok" in text
    assert "global_refresh:hybrid_cycle=ok" in text
    assert "workspace_matrix=" in text
    assert "agent_matrix=" in text
    assert "subtree_report=" in text


def test_phase_c_reports_exist():
    gov_report = REPO_ROOT / "gov" / "report" / "phaseC_kickoff_2026-03-05.md"
    chronolog_report = REPO_ROOT / "chronolog" / "PHASE_C_KICKOFF_REPORT_2026-03-05.md"
    assert gov_report.exists(), f"missing report: {gov_report}"
    assert chronolog_report.exists(), f"missing report: {chronolog_report}"
