#!/usr/bin/env python3
"""
queue_maker.py

This script creates a queue of tasks from the blocks index of a RAW
archive. Each task corresponds to a block and carries metadata
including a language priority and a prompt template. It ensures that
tasks are not duplicated across runs by checking existing queue
entries. All writes to the queue file are protected with a file
lock.

Usage:
  python queue_maker.py --archive <path_to_Archive> --prompt-template <template_name>

Only the standard library is used.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate task queue entries from blocks index."
    )
    parser.add_argument(
        "--archive",
        required=True,
        help="Path to the archive root.",
    )
    parser.add_argument(
        "--prompt-template",
        required=True,
        help="Name of the prompt template to associate with tasks.",
    )
    return parser.parse_args()


def setup_logging(archive_root: Path) -> None:
    logs_dir = archive_root / "Logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    log_file = logs_dir / "queue_maker.log"
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
        handlers=[logging.FileHandler(log_file, encoding="utf-8")],
    )


class FileLock:
    """
    A simple exclusive file lock implemented via creation of a lock
    file. Use in a with statement for automatic release.
    """

    def __init__(self, lock_path: Path):
        self.lock_path = lock_path
        self._fd: Optional[int] = None

    def acquire(self, wait: bool = False, interval: float = 0.1) -> bool:
        while True:
            try:
                fd = os.open(self.lock_path, os.O_CREAT | os.O_EXCL | os.O_RDWR)
            except FileExistsError:
                if not wait:
                    return False
                time.sleep(interval)
            else:
                self._fd = fd
                return True

    def release(self) -> None:
        if self._fd is not None:
            try:
                os.close(self._fd)
            except Exception:
                pass
            self._fd = None
        try:
            self.lock_path.unlink(missing_ok=True)
        except Exception:
            pass

    def __enter__(self) -> "FileLock":
        acquired = self.acquire(wait=True)
        if not acquired:
            raise RuntimeError(f"Could not acquire lock {self.lock_path}")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.release()


def load_existing_tasks(queue_path: Path) -> Tuple[Set[str], int]:
    """
    Load existing queue entries and return a set of block_ids already
    scheduled along with the next task sequence number (based on the
    maximum numeric suffix in task IDs).
    """
    existing_blocks: Set[str] = set()
    next_seq = 1
    if queue_path.exists():
        try:
            with queue_path.open("r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    blk_id = obj.get("block_id")
                    if blk_id:
                        existing_blocks.add(blk_id)
                    # Determine next task id number
                    tid = obj.get("id")
                    if isinstance(tid, str) and tid.startswith("task_"):
                        try:
                            seq = int(tid.split("_")[1])
                            if seq >= next_seq:
                                next_seq = seq + 1
                        except Exception:
                            continue
        except Exception as exc:
            logging.warning("Failed to read existing queue: %s", exc)
    return existing_blocks, next_seq


def load_blocks_index(index_path: Path) -> List[Dict]:
    """Load the blocks index file and return a list of block entries."""
    blocks: List[Dict] = []
    if not index_path.exists():
        logging.error("Blocks index not found: %s", index_path)
        return blocks
    try:
        with index_path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                    # Expect at least id and path and lang
                    if "id" in obj and "path" in obj and "lang" in obj:
                        blocks.append(obj)
                except json.JSONDecodeError:
                    continue
    except Exception as exc:
        logging.error("Failed to read blocks index %s: %s", index_path, exc)
    return blocks


def compute_priority(lang: str) -> int:
    lang_lower = (lang or "").lower()
    if lang_lower == "ru":
        return 5
    if lang_lower in ("en", "nl"):
        return 4
    return 5


def make_task_id(seq: int) -> str:
    return f"task_{seq:06d}"


def create_tasks(
    blocks: List[Dict],
    existing_blocks: Set[str],
    prompt_template: str,
    start_seq: int,
    archive_root: Path,
) -> Tuple[List[Dict], int]:
    """
    Create new task dictionaries for blocks not already in existing_blocks.
    Returns the list of new tasks and the next sequence number after
    assignment.
    """
    tasks: List[Dict] = []
    seq = start_seq
    timestamp = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    for blk in blocks:
        blk_id = blk.get("id")
        if not blk_id or blk_id in existing_blocks:
            continue
        lang = blk.get("lang", "")
        priority = compute_priority(lang)
        # Compose block_path: prefix with "Archive/" and ensure forward slashes
        rel_path = blk.get("path")  # e.g. DataBlocks/ByFile/.../blk_....json
        block_path = str(Path("Archive") / rel_path)
        task = {
            "id": make_task_id(seq),
            "block_id": blk_id,
            "block_path": block_path,
            "lang": lang,
            "prompt_template": prompt_template,
            "status": "pending",
            "priority": priority,
            "created_at": timestamp,
        }
        tasks.append(task)
        existing_blocks.add(blk_id)
        seq += 1
    return tasks, seq


def append_tasks(queue_path: Path, queue_lock_path: Path, tasks: List[Dict]) -> None:
    """
    Append new tasks to the queue file using a lock for mutual
    exclusion.
    """
    if not tasks:
        return
    lock = FileLock(queue_lock_path)
    if not lock.acquire(wait=True):
        logging.error("Could not acquire queue lock %s", queue_lock_path)
        return
    try:
        queue_path.parent.mkdir(parents=True, exist_ok=True)
        with queue_path.open("a", encoding="utf-8") as f:
            for task in tasks:
                f.write(json.dumps(task, ensure_ascii=False) + "\n")
    except Exception as exc:
        logging.error("Failed to append to queue %s: %s", queue_path, exc)
    finally:
        lock.release()


def main() -> None:
    args = parse_arguments()
    archive_root = Path(args.archive).resolve()
    prompt_template = args.prompt_template
    # Determine queue file name base on prompt template: use text before underscore or full
    base = prompt_template.split("_")[0]
    queue_filename = f"queue.{base}.jsonl"
    index_dir = archive_root / "Index"
    blocks_index_path = index_dir / "blocks.index.jsonl"
    queue_path = index_dir / queue_filename
    queue_lock_path = queue_path.with_suffix(queue_path.suffix + ".lock")

    setup_logging(archive_root)

    # Load existing tasks
    existing_blocks, next_seq = load_existing_tasks(queue_path)
    # Load blocks index
    blocks = load_blocks_index(blocks_index_path)
    # Create new tasks
    new_tasks, _ = create_tasks(blocks, existing_blocks, prompt_template, next_seq, archive_root)
    # Append tasks with lock
    append_tasks(queue_path, queue_lock_path, new_tasks)
    # Output summary
    print(f"Tasks added: {len(new_tasks)}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("Interrupted.")