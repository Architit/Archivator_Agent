#!/usr/bin/env python3
"""
queue_sampler.py

This script prints the first N tasks from the analysis queue in the
RAW archive and saves the selection to a JSON file. Tasks are
expected to be stored in ``Archive/Index/queue.analysis.jsonl``.

Usage:
  python queue_sampler.py --archive <path_to_Archive> --limit 20

Only the standard library is used.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import List, Dict


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Display the first N tasks from the analysis queue."
    )
    parser.add_argument(
        "--archive",
        required=True,
        help="Path to the archive root.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=20,
        help="Number of tasks to display.",
    )
    return parser.parse_args()


def load_queue(queue_path: Path) -> List[Dict]:
    """Load all tasks from the queue file. Returns an empty list if missing."""
    tasks: List[Dict] = []
    if queue_path.exists():
        try:
            with queue_path.open("r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                        if all(k in obj for k in ("block_id", "lang", "block_path")):
                            tasks.append(obj)
                    except json.JSONDecodeError:
                        continue
        except Exception:
            # Silent failure; return what we have
            pass
    return tasks


def write_selection(selection: List[Dict], dest_path: Path) -> None:
    """Write the selected tasks to the given JSON file."""
    try:
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        with dest_path.open("w", encoding="utf-8") as f:
            json.dump(selection, f, ensure_ascii=False, indent=2)
    except Exception:
        # Fail silently
        pass


def main() -> None:
    args = parse_arguments()
    archive_root = Path(args.archive).resolve()
    limit = args.limit
    queue_path = archive_root / "Index" / "queue.analysis.jsonl"
    tasks = load_queue(queue_path)
    selection = tasks[: limit] if limit > 0 else tasks
    for task in selection:
        block_id = task.get("block_id", "")
        lang = task.get("lang", "")
        block_path = task.get("block_path", "")
        print(f"{block_id} {lang} {block_path}")
    # Save JSON report
    report_path = archive_root / "Index" / "sample_selection.json"
    write_selection(selection, report_path)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass