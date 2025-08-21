#!/usr/bin/env python3
"""
segmenter_blocks.py

This script reads files from the RAW archive (Archive/Raw/ByFile/**)
and splits them into smaller text blocks suitable for downstream
analysis. It supports multiple character encodings, enforces both
character and byte length limits for each block, assigns metadata
including language detection and tags, and writes the resulting
blocks to JSON files under Archive/DataBlocks/ByFile/…

Features:

* Attempts to decode files using UTF‑8, UTF‑16 (both endiannesses),
  CP1251/CP1252 and Latin‑1. If decoding fails, it falls back to
  replacement decoding and marks the block as damaged.
* Recognises binary files (containing NUL bytes) and produces a
  single block with status="binary".
* Splits text into blocks according to maximum character and byte
  limits. Both constraints must be satisfied.
* Detects language using a simple heuristic: presence of Cyrillic
  characters → "ru"; otherwise, if at least three Dutch markers
  appear → "nl"; else "en".
* Extracts tags by searching for keywords (tech|plan|dialog|ethics|core).
* Maintains an index file (Archive/Index/blocks.index.jsonl) with
  metadata for each block, using a file lock to avoid concurrent
  writes.
* Ensures idempotency by skipping already processed files based on
  their sanitised names recorded in the index.

Usage:
  python segmenter_blocks.py --archive <path_to_Archive> --profile analysis \
    --max-chars-per-block 20000 --max-bytes-per-block 1000000

Only the standard library is used.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import os
import random
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Segment RAW archive files into smaller blocks for analysis."
    )
    parser.add_argument(
        "--archive",
        required=True,
        help="Path to the archive root.",
    )
    parser.add_argument(
        "--profile",
        default="analysis",
        help="Name of the segmentation profile (currently unused).",
    )
    parser.add_argument(
        "--max-chars-per-block",
        type=int,
        default=20000,
        help="Maximum number of characters per block.",
    )
    parser.add_argument(
        "--max-bytes-per-block",
        type=int,
        default=1000000,
        help="Maximum number of UTF‑8 bytes per block.",
    )
    return parser.parse_args()


def setup_logging(archive_root: Path) -> None:
    logs_dir = archive_root / "Logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    log_file = logs_dir / "segmenter.log"
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
        handlers=[
            logging.FileHandler(log_file, encoding="utf-8"),
        ],
    )


def sanitize_name(name: str) -> str:
    # Replace path separators and disallowed characters
    base = name.replace(os.sep, "_").replace("/", "_")
    base = re.sub(r"[^A-Za-z0-9._ -]", "_", base)
    base = base.strip(" .")
    return base or "unnamed"


class FileLock:
    """
    Simple file lock using exclusive creation of a lock file. The lock
    must be manually released.
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

    def __exit__(self, exc_type, exc, tb) -> None:
        self.release()


def load_processed_files(index_path: Path) -> set[str]:
    """
    Read the existing blocks index and return a set of sanitised file
    names that have already been processed. We use the 'src_file'
    field from each entry.
    """
    processed: set[str] = set()
    if index_path.exists():
        try:
            with index_path.open("r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                        src = obj.get("src_file")
                        if src:
                            processed.add(src)
                    except json.JSONDecodeError:
                        continue
        except Exception as exc:
            logging.warning("Failed to read blocks index: %s", exc)
    return processed


def detect_language(text: str) -> str:
    """
    Simple heuristic for language detection:
      * If any Cyrillic character appears, return 'ru'.
      * Else if at least three Dutch markers appear (case insensitive), return 'nl'.
      * Else return 'en'.
    """
    # Cyrillic range includes 0400–04FF, 0500–052F, 2DE0–2DFF (extended), A640–A69F etc.
    # We'll simply search for any character in the basic Cyrillic block.
    if re.search(r"[\u0400-\u04FF]", text):
        return "ru"
    markers = [
        "de",
        "het",
        "je",
        "hij",
        "zij",
        "een",
        "niet",
        "als",
        "met",
        "voor",
        "naar",
        "ik",
        "wij",
    ]
    lower = text.lower()
    count = 0
    for m in markers:
        # Count occurrences of each marker as a whole word or substring
        if lower.count(m) > 0:
            count += 1
        if count >= 3:
            return "nl"
    return "en"


def extract_tags(text: str) -> List[str]:
    """Return a list of unique tags found in the text based on keywords."""
    tags = set()
    for match in re.finditer(r"\b(tech|plan|dialog|ethics|core)\b", text, re.IGNORECASE):
        tags.add(match.group(1).lower())
    return sorted(tags)


def split_into_blocks(
    text: str,
    max_chars: int,
    max_bytes: int,
) -> List[str]:
    """
    Split the given text into blocks such that each block contains at
    most ``max_chars`` Unicode characters and at most ``max_bytes``
    bytes when encoded in UTF‑8. Returns a list of block strings.
    """
    blocks: List[str] = []
    if not text:
        return blocks
    start = 0
    char_count = 0
    byte_count = 0
    for idx, ch in enumerate(text):
        # Determine size of next character in UTF‑8
        ch_bytes = ch.encode("utf-8")
        next_byte_count = len(ch_bytes)
        # If adding this char would exceed either limit, finalize current block
        if char_count + 1 > max_chars or byte_count + next_byte_count > max_bytes:
            blocks.append(text[start:idx])
            start = idx
            char_count = 0
            byte_count = 0
        char_count += 1
        byte_count += next_byte_count
    # Add last block
    if start < len(text):
        blocks.append(text[start:])
    return blocks


def decode_content(raw: bytes) -> Tuple[str, str, str]:
    """
    Attempt to decode the raw bytes using a list of encodings. Returns
    a tuple (text, encoding_used, status). Status is "ok", "damaged"
    or "binary".
    """
    # Check for null bytes to detect likely binary
    if b"\x00" in raw:
        return "", "binary", "binary"
    encodings = ["utf-8", "utf-16", "utf-16-le", "utf-16-be", "cp1251", "cp1252", "latin-1"]
    for enc in encodings:
        try:
            text = raw.decode(enc, errors="strict")
            return text, enc, "ok"
        except UnicodeDecodeError:
            continue
    # Fallback to replacement decoding using UTF‑8
    try:
        text = raw.decode("utf-8", errors="replace")
        return text, "utf-8", "damaged"
    except Exception:
        # Fallback last resort
        try:
            text = raw.decode("latin-1", errors="replace")
            return text, "latin-1", "damaged"
        except Exception:
            # If decoding fails entirely, mark binary
            return "", "binary", "binary"


def process_file(
    file_path: Path,
    sanitized_name: str,
    block_counter: List[int],
    max_chars: int,
    max_bytes: int,
    index_path: Path,
    index_lock_path: Path,
    blocks_root: Path,
    summary_counts: Dict[str, int],
) -> None:
    """
    Process a single RAW file: decode, split into blocks, write JSON
    blocks, and append entries to the blocks index. Updates block
    counters and summary statistics.
    """
    # Read file content as bytes
    try:
        raw = file_path.read_bytes()
    except Exception as exc:
        logging.error("Failed to read RAW file %s: %s", file_path, exc)
        summary_counts["damaged"] += 1
        return
    # Compute parent SHA256 (hash of full file bytes)
    parent_sha = hashlib.sha256(raw).hexdigest()
    # Attempt decoding
    text, encoding_used, status = decode_content(raw)
    if status == "binary":
        # Create a single block for binary data
        block_counter[0] += 1
        blk_id = generate_block_id(block_counter[0])
        block_obj = {
            "block_id": blk_id,
            "parent_sha256": parent_sha,
            "src_file": sanitized_name,
            "seq": 1,
            "total_seqs": 1,
            "encoding": encoding_used,
            "lang": "en",
            "status": "binary",
            "size_bytes": len(raw),
            "hash_sha256": hashlib.sha256(b"").hexdigest(),
            "tags": [],
            "text": "",
        }
        write_block_json(block_obj, blocks_root, sanitized_name)
        append_block_index(index_path, index_lock_path, block_obj)
        summary_counts["binary"] += 1
        summary_counts["blocks"] += 1
        summary_counts["files"] += 1
        return
    # Status ok or damaged
    # If decoded text stripped is empty, treat as binary/damaged accordingly
    if not text.strip():
        # treat as damaged empty
        block_counter[0] += 1
        blk_id = generate_block_id(block_counter[0])
        block_obj = {
            "block_id": blk_id,
            "parent_sha256": parent_sha,
            "src_file": sanitized_name,
            "seq": 1,
            "total_seqs": 1,
            "encoding": encoding_used,
            "lang": "en",
            "status": status,
            "size_bytes": len(raw),
            "hash_sha256": hashlib.sha256(b"").hexdigest(),
            "tags": [],
            "text": "",
        }
        write_block_json(block_obj, blocks_root, sanitized_name)
        append_block_index(index_path, index_lock_path, block_obj)
        if status == "damaged":
            summary_counts["damaged"] += 1
        else:
            summary_counts["binary"] += 1
        summary_counts["blocks"] += 1
        summary_counts["files"] += 1
        return
    # Split text into blocks
    blocks = split_into_blocks(text, max_chars, max_bytes)
    total_seqs = len(blocks)
    lang = detect_language(text)
    tags = extract_tags(text)
    for seq, block_text in enumerate(blocks, start=1):
        block_counter[0] += 1
        blk_id = generate_block_id(block_counter[0])
        encoded = block_text.encode("utf-8")
        block_obj = {
            "block_id": blk_id,
            "parent_sha256": parent_sha,
            "src_file": sanitized_name,
            "seq": seq,
            "total_seqs": total_seqs,
            "encoding": encoding_used,
            "lang": lang,
            "status": status,
            "size_bytes": len(encoded),
            "hash_sha256": hashlib.sha256(encoded).hexdigest(),
            "tags": tags,
            "text": block_text,
        }
        write_block_json(block_obj, blocks_root, sanitized_name)
        append_block_index(index_path, index_lock_path, block_obj)
        summary_counts["blocks"] += 1
        if status == "damaged":
            summary_counts["damaged"] += 1
    summary_counts["files"] += 1


def generate_block_id(counter: int) -> str:
    """Generate a unique block ID with timestamp and counter."""
    ts = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    return f"blk_{ts}_{counter:06d}"


def write_block_json(block_obj: Dict, blocks_root: Path, sanitized_name: str) -> None:
    """Write a block JSON file into the DataBlocks structure."""
    dir_path = blocks_root / sanitized_name
    dir_path.mkdir(parents=True, exist_ok=True)
    block_id = block_obj["block_id"]
    file_path = dir_path / f"{block_id}.json"
    try:
        with file_path.open("w", encoding="utf-8") as f:
            json.dump(block_obj, f, ensure_ascii=False, indent=2)
    except Exception as exc:
        logging.error("Failed to write block file %s: %s", file_path, exc)


def append_block_index(index_path: Path, lock_path: Path, block_obj: Dict) -> None:
    """
    Append a block entry to the blocks index. Uses a file lock to
    coordinate concurrent writes.
    """
    entry = {
        "id": block_obj["block_id"],
        "src_file": block_obj["src_file"],
        "lang": block_obj["lang"],
        "size_bytes": block_obj["size_bytes"],
        "path": str((Path("DataBlocks") / "ByFile" / block_obj["src_file"] / f"{block_obj['block_id']}.json")),
        "tags": block_obj["tags"],
    }
    lock = FileLock(lock_path)
    if not lock.acquire(wait=True):
        logging.error("Could not acquire index lock %s", lock_path)
        return
    try:
        index_path.parent.mkdir(parents=True, exist_ok=True)
        with index_path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except Exception as exc:
        logging.error("Failed to append to block index: %s", exc)
    finally:
        lock.release()


def main() -> None:
    args = parse_arguments()
    archive_root = Path(args.archive).resolve()
    max_chars = args.max_chars_per_block
    max_bytes = args.max_bytes_per_block

    setup_logging(archive_root)
    raw_byfile_root = archive_root / "Raw" / "ByFile"
    blocks_root = archive_root / "DataBlocks" / "ByFile"
    index_dir = archive_root / "Index"
    index_path = index_dir / "blocks.index.jsonl"
    index_lock_path = index_path.with_suffix(index_path.suffix + ".lock")

    processed = load_processed_files(index_path)
    summary_counts = {"blocks": 0, "damaged": 0, "binary": 0, "files": 0}
    block_counter = [0]  # shared mutable counter

    if not raw_byfile_root.exists():
        logging.error("Raw ByFile directory does not exist: %s", raw_byfile_root)
        print("Blocks written: 0, damaged: 0, binary: 0, files: 0")
        return
    # Walk through each sanitised directory
    for dir_entry in raw_byfile_root.iterdir():
        if not dir_entry.is_dir():
            continue
        sanitized_name = dir_entry.name
        # Skip previously processed files by sanitised name
        if sanitized_name in processed:
            continue
        # Process each file in this directory (could be multiple timestamped files)
        for file_entry in dir_entry.iterdir():
            if not file_entry.is_file():
                continue
            try:
                process_file(
                    file_path=file_entry,
                    sanitized_name=sanitized_name,
                    block_counter=block_counter,
                    max_chars=max_chars,
                    max_bytes=max_bytes,
                    index_path=index_path,
                    index_lock_path=index_lock_path,
                    blocks_root=blocks_root,
                    summary_counts=summary_counts,
                )
            except Exception as exc:
                logging.error("Unhandled exception processing %s: %s", file_entry, exc)
    # Print summary
    print(
        f"Blocks written: {summary_counts['blocks']}, "
        f"damaged: {summary_counts['damaged']}, binary: {summary_counts['binary']}, "
        f"files: {summary_counts['files']}"
    )


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("Interrupted.")