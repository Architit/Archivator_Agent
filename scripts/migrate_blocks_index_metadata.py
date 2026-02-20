#!/usr/bin/env python3
"""Migrate Archive/Index/blocks.index.jsonl to include source_blob and parent_sha256.

The script is safe by default (dry-run). In write mode it creates a timestamped
backup before replacing the index file.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import shutil
from pathlib import Path, PurePosixPath
from typing import Dict, List, Optional, Set, Tuple


def utc_stamp() -> str:
    return dt.datetime.now(dt.UTC).strftime("%Y%m%d_%H%M%S")


def utc_iso() -> str:
    return dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Backfill source_blob/parent_sha256 in blocks.index.jsonl"
    )
    parser.add_argument("--archive", required=True, help="Path to Archive root")
    parser.add_argument(
        "--write",
        action="store_true",
        help="Apply changes in-place (default is dry-run)",
    )
    parser.add_argument(
        "--report-dir",
        default=None,
        help="Directory for migration report (default: <archive>/Logs)",
    )
    return parser.parse_args()


def parse_byfile_rel(byfile_rel: str) -> Tuple[str, str]:
    rel = byfile_rel.replace("\\", "/")
    parts = PurePosixPath(rel).parts
    # expected: Raw / ByFile / <src_file> / <blob>
    if len(parts) >= 4 and parts[0] == "Raw" and parts[1] == "ByFile":
        return parts[2], parts[3]
    return "", ""


def load_raw_mappings(raw_index_path: Path) -> Tuple[Dict[Tuple[str, str], Set[str]], Dict[str, Set[str]]]:
    by_src_sha: Dict[Tuple[str, str], Set[str]] = {}
    by_src_only: Dict[str, Set[str]] = {}
    if not raw_index_path.exists():
        return by_src_sha, by_src_only

    with raw_index_path.open("r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            byfile = obj.get("byfile", "")
            sha = obj.get("sha256", "")
            src_file, source_blob = parse_byfile_rel(byfile)
            if not src_file or not source_blob:
                continue
            by_src_only.setdefault(src_file, set()).add(source_blob)
            if sha:
                by_src_sha.setdefault((src_file, sha), set()).add(source_blob)

    return by_src_sha, by_src_only


def load_block_payload(archive_root: Path, rel_path: str) -> Dict:
    if not rel_path:
        return {}
    normalized = rel_path.replace("\\", "/")
    block_path = archive_root / PurePosixPath(normalized)
    if not block_path.exists():
        return {}
    try:
        with block_path.open("r", encoding="utf-8") as bf:
            return json.load(bf)
    except Exception:
        return {}


def migrate_blocks_index(
    archive_root: Path,
    by_src_sha: Dict[Tuple[str, str], Set[str]],
    by_src_only: Dict[str, Set[str]],
) -> Tuple[List[str], Dict]:
    index_path = archive_root / "Index" / "blocks.index.jsonl"
    if not index_path.exists():
        raise FileNotFoundError(f"missing index: {index_path}")

    output_lines: List[str] = []
    stats = {
        "total_lines": 0,
        "json_lines": 0,
        "changed_lines": 0,
        "filled_parent_sha256": 0,
        "filled_source_blob": 0,
        "unresolved_source_blob": 0,
        "invalid_json_lines": 0,
        "missing_block_files": 0,
        "unresolved_samples": [],
    }

    with index_path.open("r", encoding="utf-8", errors="replace") as f:
        for line_no, raw in enumerate(f, start=1):
            stats["total_lines"] += 1
            stripped = raw.strip()
            if not stripped:
                output_lines.append(raw)
                continue
            try:
                obj = json.loads(stripped)
            except json.JSONDecodeError:
                stats["invalid_json_lines"] += 1
                output_lines.append(raw)
                continue

            stats["json_lines"] += 1
            changed = False

            src_file = obj.get("src_file", "")
            source_blob = obj.get("source_blob", "")
            parent_sha = obj.get("parent_sha256", "")
            rel_path = obj.get("path", "")

            block_payload = load_block_payload(archive_root, rel_path)
            if rel_path and not block_payload:
                stats["missing_block_files"] += 1

            if not parent_sha:
                payload_sha = block_payload.get("parent_sha256", "")
                if payload_sha:
                    obj["parent_sha256"] = payload_sha
                    parent_sha = payload_sha
                    changed = True
                    stats["filled_parent_sha256"] += 1

            if not source_blob:
                payload_blob = block_payload.get("source_blob", "")
                chosen = ""
                if payload_blob:
                    chosen = payload_blob
                elif src_file and parent_sha:
                    candidates = by_src_sha.get((src_file, parent_sha), set())
                    if len(candidates) == 1:
                        chosen = next(iter(candidates))
                if not chosen and src_file:
                    src_candidates = by_src_only.get(src_file, set())
                    if len(src_candidates) == 1:
                        chosen = next(iter(src_candidates))

                if chosen:
                    obj["source_blob"] = chosen
                    changed = True
                    stats["filled_source_blob"] += 1
                else:
                    stats["unresolved_source_blob"] += 1
                    if len(stats["unresolved_samples"]) < 20:
                        stats["unresolved_samples"].append(
                            {
                                "line": line_no,
                                "id": obj.get("id", ""),
                                "src_file": src_file,
                                "parent_sha256": parent_sha,
                            }
                        )

            if changed:
                stats["changed_lines"] += 1

            output_lines.append(json.dumps(obj, ensure_ascii=False) + "\n")

    return output_lines, stats


def main() -> int:
    args = parse_args()
    archive_root = Path(args.archive).resolve()
    index_path = archive_root / "Index" / "blocks.index.jsonl"
    raw_index_path = archive_root / "Index" / "raw.index.jsonl"
    report_dir = Path(args.report_dir).resolve() if args.report_dir else (archive_root / "Logs")
    report_dir.mkdir(parents=True, exist_ok=True)

    by_src_sha, by_src_only = load_raw_mappings(raw_index_path)
    output_lines, stats = migrate_blocks_index(archive_root, by_src_sha, by_src_only)

    backup_path: Optional[Path] = None
    if args.write:
        backup_path = index_path.with_suffix(index_path.suffix + f".bak.{utc_stamp()}")
        shutil.copy2(index_path, backup_path)
        tmp_path = index_path.with_suffix(index_path.suffix + ".tmp")
        with tmp_path.open("w", encoding="utf-8") as out:
            out.writelines(output_lines)
        os.replace(tmp_path, index_path)

    report = {
        "timestamp": utc_iso(),
        "archive": str(archive_root),
        "mode": "write" if args.write else "dry-run",
        "index_path": str(index_path),
        "raw_index_path": str(raw_index_path),
        "backup_path": str(backup_path) if backup_path else "",
        "stats": stats,
    }

    report_path = report_dir / f"blocks_index_migration_report_{utc_stamp()}.json"
    with report_path.open("w", encoding="utf-8") as rf:
        json.dump(report, rf, ensure_ascii=False, indent=2)

    print(
        f"mode={report['mode']} changed={stats['changed_lines']} "
        f"filled_source_blob={stats['filled_source_blob']} "
        f"filled_parent_sha256={stats['filled_parent_sha256']} "
        f"unresolved_source_blob={stats['unresolved_source_blob']} "
        f"report={report_path}"
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
