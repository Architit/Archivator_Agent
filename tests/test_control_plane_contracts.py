from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]


def test_control_plane_scripts_exist_and_executable():
    scripts = [
        "scripts/archivator_global_refresh.sh",
        "scripts/agent_ecosystem_matrix_builder.sh",
        "scripts/subtree_registry_sync.sh",
        "scripts/subtree_dependency_drift_gate.sh",
        "scripts/run_daily_refresh_and_export.sh",
        "scripts/publish_archivator_public_packets.sh",
        "scripts/form_all_repo_subtrees_in_hub.sh",
    ]
    for rel in scripts:
        path = REPO_ROOT / rel
        assert path.exists(), f"missing script: {rel}"
        assert path.stat().st_mode & 0o111, f"script not executable: {rel}"


def test_latest_index_artifacts_exist():
    index = REPO_ROOT / "Archive" / "Index"
    required = [
        "agent_ecosystem_file_matrix_latest.tsv",
        "agent_ecosystem_memory_flow_report_latest.md",
        "github_subtree_matrix_latest.tsv",
        "github_subtree_report_latest.md",
        "subtree_registry.tsv",
        "subtree_drift_matrix_latest.tsv",
        "subtree_drift_report_latest.md",
        "archivator_extended_agent_matrix_report_latest.md",
        "subtree_hub_method_matrix_latest.tsv",
    ]
    missing = [name for name in required if not (index / name).exists()]
    assert not missing, f"missing latest index artifacts: {missing}"


def test_patch_helper_has_integrity_chain_markers():
    text = (REPO_ROOT / "devkit" / "patch.sh").read_text(encoding="utf-8")
    assert "missing_patch_sha256" in text
    assert "integrity_mismatch" in text
    assert "artifact_hash" in text
    assert "spec_hash" in text
    assert "apply_result=" in text


def test_global_refresh_has_hybrid_cycle_hooks():
    text = (REPO_ROOT / "scripts" / "archivator_global_refresh.sh").read_text(
        encoding="utf-8"
    )
    assert "semantic_index_hook=ok" in text
    assert "physical_archive_hook=ok" in text
    assert "hybrid_cycle=ok" in text
    assert "gateway_io.sh\" export" in text
