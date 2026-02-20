from __future__ import annotations

import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "scripts" / "run_daily_refresh_and_export.sh"


def test_daily_runner_blocks_narrow_scope_in_strict_mode():
    proc = subprocess.run(
        ["bash", str(SCRIPT), "/tmp", "A B", "strict"],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    assert proc.returncode == 2
    out = proc.stdout + proc.stderr
    expected = str(REPO_ROOT.parent)
    assert f"strict mode requires WORK_ROOT={expected}" in out
