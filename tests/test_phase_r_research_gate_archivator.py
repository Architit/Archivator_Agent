from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]


def test_phase_r_archivator_markers() -> None:
    text = (
        REPO_ROOT / "contract" / "PHASE_R_RESEARCH_GATE_ARCHIVATOR_CONTRACT_V1.md"
    ).read_text(encoding="utf-8")
    assert "phase_r_research_gate_archivator_contract=ok" in text
    assert "phase_r_transport_benchmark_matrix=ok" in text
    assert "phase_r_vector_engine_benchmark_matrix=ok" in text
    assert "phase_r_wake_on_demand_trigger_check=ok" in text
