#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
raw_index_verify.py (v2)
Проверяет RAW-слой архива:
- Считывает Archive/Index/raw.index.jsonl (терпим к пустым/«мусорным» строкам и BOM).
- Для каждой записи проверяет наличие файла в Raw/ByHash/sha256/**.
- Поддерживает относительные пути в поле "byhash" (соединяет с --archive).
- Дополнительно может выборочно пересчитать sha256 для N файлов ( --sample N ).
- Пишет отчёт в Archive/Logs/raw_verify_report.json.
- Код возврата: 0 если missing=0 и mismatched=0, иначе 2.

Запуск:
  python raw_index_verify.py --archive "C:\\...\\Archivator_Agent\\Archive" --sample 10
"""

import argparse, os, json, hashlib, datetime, sys

def utc_now_iso():
    # Безопасно для разных версий Python
    return datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

def tolerant_jsonl(path: str):
    """Читает JSONL: пропускает пустые строки, терпим к BOM и «склеенному» JSON."""
    if not os.path.isfile(path):
        return []
    out, buf = [], ""
    with open(path, "r", encoding="utf-8-sig", errors="replace") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            # пробуем как одиночный json
            try:
                out.append(json.loads(line))
                continue
            except Exception:
                # возможно, многострочный json — копим буфер
                buf += line
                try:
                    obj = json.loads(buf)
                    out.append(obj)
                    buf = ""
                except Exception:
                    pass
    return out

def abs_byhash_path(archive_root: str, rec: dict) -> str:
    """
    Возвращает абсолютный путь до файла в ByHash.
    1) Если в индексе есть относительный rec["byhash"] → приклеиваем к archive_root.
    2) Иначе восстанавливаем по sha256: Raw/ByHash/sha256/aa/bb/sha256 + ext.
    """
    byhash_rel = rec.get("byhash")
    if byhash_rel:
        return os.path.join(archive_root, byhash_rel.replace("/", os.sep))
    sha = rec.get("sha256")
    ext = rec.get("ext", "")
    if not sha or len(sha) < 4:
        return ""
    aa, bb = sha[:2], sha[2:4]
    return os.path.join(archive_root, "Raw", "ByHash", "sha256", aa, bb, sha + ext)

def sha256_file(path: str, bufsize: int = 4 * 1024 * 1024) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            b = f.read(bufsize)
            if not b:
                break
            h.update(b)
    return h.hexdigest()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--archive", required=True, help="Путь к корню Archive")
    ap.add_argument("--sample", type=int, default=0, help="Сколько файлов пересчитать по sha256 (случайные записи)")
    args = ap.parse_args()

    archive = os.path.abspath(args.archive)
    index_path = os.path.join(archive, "Index", "raw.index.jsonl")
    logs_dir = os.path.join(archive, "Logs")
    os.makedirs(logs_dir, exist_ok=True)
    report_path = os.path.join(logs_dir, "raw_verify_report.json")

    records = tolerant_jsonl(index_path)
    total = len(records)

    missing = 0
    mismatched = 0
    ok = 0

    # Список кандидатов для семплирования (просто первые N уникальных с файлами)
    to_sample = args.sample if args.sample and args.sample > 0 else 0
    sampled = 0

    for rec in records:
        try:
            bh_abs = abs_byhash_path(archive, rec)
            if not bh_abs or not os.path.isfile(bh_abs):
                missing += 1
                continue

            # Пересчёт хэша (семпл)
            if to_sample and sampled < to_sample:
                calc = sha256_file(bh_abs)
                if calc != rec.get("sha256"):
                    mismatched += 1
                else:
                    ok += 1
                sampled += 1
            else:
                ok += 1

        except Exception:
            missing += 1  # любая ошибка чтения трактуется как отсутствие

    summary = {
        "timestamp": utc_now_iso(),
        "archive": archive,
        "index_path": index_path,
        "total": total,
        "unique_hint": len({r.get("sha256") for r in records if r.get("sha256")}),
        "missing": missing,
        "mismatched": mismatched,
        "sampled": sampled,
        "ok": ok
    }

    # Сохраняем отчёт
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)

    print(f"Summary: total={summary['total']}, unique={summary['unique_hint']}, "
          f"missing={summary['missing']}, mismatched={summary['mismatched']}, "
          f"sampled={summary['sampled']}, ok={summary['ok']}")

    # Код возврата
    if summary["missing"] == 0 and summary["mismatched"] == 0:
        sys.exit(0)
    else:
        sys.exit(2)

if __name__ == "__main__":
    main()
