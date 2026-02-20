from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from archivator_raw import find_existing_byhash_blob
from segmenter_blocks import detect_language, load_processed_files


def test_archivator_global_refresh_does_not_fail_on_unbound_root(tmp_path: Path):
    script = REPO_ROOT / "scripts" / "archivator_global_refresh.sh"
    proc = subprocess.run(
        ["bash", str(script), str(tmp_path), "MissingRepo", "soft"],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    out = (proc.stdout + proc.stderr).lower()
    assert proc.returncode == 0, out
    assert "unbound variable" not in out


def test_find_existing_byhash_blob_supports_legacy_sha_with_extension(tmp_path: Path):
    sha = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    byhash_root = tmp_path
    nested = byhash_root / sha[:2] / sha[2:4]
    nested.mkdir(parents=True, exist_ok=True)
    legacy = nested / f"{sha}.txt"
    legacy.write_text("data", encoding="utf-8")
    assert find_existing_byhash_blob(str(byhash_root), sha) == str(legacy)


def test_detect_language_avoids_substring_false_positives_for_dutch():
    assert detect_language("Under parameter spike.") == "en"
    assert detect_language("de het niet") == "nl"


def test_load_processed_files_supports_per_source_blob_tracking(tmp_path: Path):
    index = tmp_path / "blocks.index.jsonl"
    records = [
        {"src_file": "doc", "source_blob": "2026-01-01_000000.txt"},
        {"src_file": "legacy-doc"},
    ]
    index.write_text("".join(json.dumps(r) + "\n" for r in records), encoding="utf-8")
    processed_pairs, legacy_dirs = load_processed_files(index)
    assert ("doc", "2026-01-01_000000.txt") in processed_pairs
    assert "legacy-doc" in legacy_dirs
