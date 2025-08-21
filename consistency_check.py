#!/usr/bin/env python3
"""
consistency_check.py

This script verifies that every raw file referenced in the RAW index
has at least one corresponding block entry in the DataBlocks index.
It compares the set of SHA‑256 hashes from ``raw.index.jsonl`` against
the set of ``parent_sha256`` values extracted from block JSON files
listed in ``blocks.index.jsonl``.

Usage:
  python consistency_check.py --archive <path_to_Archive>

Outputs a summary to stdout and writes a JSON report to
``Archive/Logs/consistency_report.json``.  Returns exit code 0 if no
missing blocks are found, otherwise returns 2.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Set


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check consistency between raw files and data blocks."
    )
    parser.add_argument(
        "--archive",
        required=True,
        help="Path to the archive root.",
    )
    return parser.parse_args()


def read_raw_index(index_path: Path) -> Set[str]:
    """Read raw.index.jsonl and return a set of SHA‑256 hashes."""
    sha_set: Set[str] = set()
    if not index_path.exists():
        return sha_set
    try:
        with index_path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if line.startswith("{"):
                    try:
                        obj = json.loads(line)
                        sha = obj.get("sha256")
                        if sha:
                            sha_set.add(sha)
                    except json.JSONDecodeError:
                        continue
                else:
                    sha_set.add(line)
    except Exception:
        pass
    return sha_set


def read_blocks_parent_hashes(
    blocks_index_path: Path, archive_root: Path
) -> Set[str]:
    """
    Read blocks.index.jsonl and extract the set of parent_sha256 values
    from the corresponding block JSON files. Missing or invalid files
    are ignored.
    """
    parent_hashes: Set[str] = set()
    if not blocks_index_path.exists():
        return parent_hashes
    try:
        with blocks_index_path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                rel_path = obj.get("path")
                if not rel_path:
                    continue
                block_path = archive_root / rel_path
                try:
                    with block_path.open("r", encoding="utf-8") as bf:
                        block_obj = json.load(bf)
                    parent_sha = block_obj.get("parent_sha256")
                    if parent_sha:
                        parent_hashes.add(parent_sha)
                except Exception:
                    # Skip missing or unreadable block files
                    continue
    except Exception:
        pass
    return parent_hashes


def write_report(report_path: Path, report: Dict) -> None:
    try:
        report_path.parent.mkdir(parents=True, exist_ok=True)
        with report_path.open("w", encoding="utf-8") as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
    except Exception:
        pass


def main() -> int:
    args = parse_arguments()
    archive_root = Path(args.archive).resolve()
    raw_index_path = archive_root / "Index" / "raw.index.jsonl"
    blocks_index_path = archive_root / "Index" / "blocks.index.jsonl"
    raw_hashes = read_raw_index(raw_index_path)
    block_parent_hashes = read_blocks_parent_hashes(blocks_index_path, archive_root)
    missing = sorted(raw_hashes - block_parent_hashes)
    # Summary output
    print(
        f"RAW files: {len(raw_hashes)}, Blocks: {len(block_parent_hashes)}, Missing blocks for RAW: {len(missing)}"
    )
    # Write report
    report = {
        "raw_count": len(raw_hashes),
        "block_count": len(block_parent_hashes),
        "missing_count": len(missing),
        "missing": missing,
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }
    report_path = archive_root / "Logs" / "consistency_report.json"
    write_report(report_path, report)
    # Return code
    return 0 if not missing else 2


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)