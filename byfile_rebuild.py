#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
byfile_rebuild.py (v2, resilient)
Перестраивает Archive/Raw/ByFile по правилу:
  ByFile/<basename-only>/<YYYY-MM-DD_HHMMSS><ext>
— Берёт данные либо из raw.index.jsonl, либо напрямую сканирует ByHash.
"""

import os, json, shutil, re, sys, argparse, datetime, pathlib, glob, stat

FORBIDDEN = r'\\/:*?"<>|'
def sanitize_stem(name: str) -> str:
    stem = pathlib.Path(name).stem
    stem = "".join(("_" if c in FORBIDDEN else c) for c in stem).strip().lower()
    stem = "-".join(stem.split())
    stem = "".join(ch if (ch.isalnum() or ch in "-_.") else "_" for ch in stem)
    return stem[:64] or "unnamed"

def iso_from_mtime(p: str) -> str:
    try:
        ts = datetime.datetime.utcfromtimestamp(os.stat(p).st_mtime)
    except Exception:
        ts = datetime.datetime.utcnow()
    return ts.strftime("%Y-%m-%d_%H%M%S")

def tolerant_jsonl(path: str):
    if not os.path.isfile(path):
        return []
    out, buf = [], ""
    with open(path, "r", encoding="utf-8-sig", errors="replace") as f:
        for raw in f:
            line = raw.strip()
            if not line: continue
            try:
                out.append(json.loads(line)); continue
            except Exception:
                buf += line
                try:
                    out.append(json.loads(buf)); buf=""
                except Exception:
                    pass
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--archive", required=True)
    ap.add_argument("--reset", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    archive = os.path.abspath(args.archive)
    idx_path = os.path.join(archive, "Index", "raw.index.jsonl")
    byhash_root = os.path.join(archive, "Raw", "ByHash", "sha256")
    byfile_root = os.path.join(archive, "Raw", "ByFile")
    os.makedirs(byfile_root, exist_ok=True)

    if args.reset and not args.dry_run:
        shutil.rmtree(byfile_root, ignore_errors=True)
        os.makedirs(byfile_root, exist_ok=True)

    created = skipped = errors = 0

    # 1) Пытаемся по индексу
    recs = tolerant_jsonl(idx_path)
    if recs:
        for rec in recs:
            try:
                byhash_rel = rec.get("byhash") or ""
                original   = rec.get("original") or ""
                ext        = rec.get("ext") or ""
                byhash_abs = os.path.join(archive, byhash_rel.replace("/", os.sep))
                if not os.path.isfile(byhash_abs):
                    errors += 1; continue
                stem = sanitize_stem(os.path.basename(original) or os.path.basename(byhash_abs))
                dest_dir = os.path.join(byfile_root, stem)
                os.makedirs(dest_dir, exist_ok=True)
                ts = (rec.get("mtime_src") or "").replace(":","").replace("-","").replace("T","_").replace("Z","")
                if not ts or len(ts) < 8:
                    ts = iso_from_mtime(byhash_abs)
                dest = os.path.join(dest_dir, f"{ts}{ext}")
                if os.path.exists(dest):
                    skipped += 1; continue
                if args.dry_run:
                    print(f"{byhash_abs} -> {dest}")
                else:
                    shutil.copy2(byhash_abs, dest)
                    created += 1
            except Exception:
                errors += 1

    # 2) Если индекса нет/кривой — сканируем ByHash напрямую
    if created == 0 and skipped == 0:
        for path in glob.glob(os.path.join(byhash_root, "*", "*", "*")):
            if not os.path.isfile(path): continue
            stem = sanitize_stem(os.path.basename(path))
            dest_dir = os.path.join(byfile_root, stem)
            os.makedirs(dest_dir, exist_ok=True)
            ts = iso_from_mtime(path)
            # ext из имени (последняя точка)
            _, ext = os.path.splitext(path)
            dest = os.path.join(dest_dir, f"{ts}{ext}")
            try:
                if os.path.exists(dest):
                    skipped += 1; continue
                if args.dry_run:
                    print(f"{path} -> {dest}")
                else:
                    shutil.copy2(path, dest)
                    created += 1
            except Exception:
                errors += 1

    print(f"ByFile rebuilt: created={created}, skipped={skipped}, errors={errors}")

if __name__ == "__main__":
    main()
