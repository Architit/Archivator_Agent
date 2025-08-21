#!/usr/bin/env python3
"""
readme_scaffold.py

This script creates or overwrites a README.md file in the specified
archive directory. The README contains a short guide on the archive's
directory structure, step‑by‑step commands for processing data using
the provided tools, notes about the zero‑loss policy and atomic
operations, and information on reading logs and reports.

Usage:
  python readme_scaffold.py --archive <path_to_Archive>

Only the Python standard library is used.
"""

from __future__ import annotations

import argparse
from pathlib import Path


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Write a scaffold README.md for the archive."
    )
    parser.add_argument(
        "--archive",
        required=True,
        help="Path to the archive root where README.md will be written.",
    )
    return parser.parse_args()


def generate_readme() -> str:
    """
    Construct the README content as a Markdown string.
    """
    lines = []
    lines.append("# Руководство по архиву\n")

    # Directory structure
    lines.append("## Структура каталогов\n")
    lines.append("Архив состоит из нескольких ключевых подкаталогов:\n")
    lines.append("- **Raw/ByHash** — хранит неизменённые файлы по их SHA‑256, организованные по поддиректориям для удобства.\n")
    lines.append("- **Raw/ByFile** — копии файлов по исходному имени и времени поступления.\n")
    lines.append("- **DataBlocks/ByFile** — блоки данных, полученные после сегментации исходных файлов.\n")
    lines.append("- **Index** — индексные файлы (`raw.index.jsonl`, `blocks.index.jsonl`, `queue.*.jsonl`) и отчёты проверки.\n")
    lines.append("- **Logs** — файлы логов работы скриптов.\n")
    lines.append("- **_tmp** — временное хранилище для промежуточных файлов во время обработки.\n\n")

    # Commands section
    lines.append("## Команды для Windows PowerShell\n")
    lines.append("Следующие шаги выполняют полный цикл обработки данных. Замените пути на ваши значения.\n")
    lines.append("1. **Архивация RAW** — сохранить файлы в RAW‑слой:\n")
    lines.append("   ```powershell\n")
    lines.append("   python archivator_raw.py --source \"C:\\path\\to\\SourceChats\" --archive \"C:\\path\\to\\Archive\"\n")
    lines.append("   ```\n")
    lines.append("2. **Проверка индекса RAW** — убедиться в целостности сохранённых файлов:\n")
    lines.append("   ```powershell\n")
    lines.append("   python raw_index_verify.py --archive \"C:\\path\\to\\Archive\" --sample 10\n")
    lines.append("   ```\n")
    lines.append("3. **Сегментация блоков** — разрезать файлы на блоки:\n")
    lines.append("   ```powershell\n")
    lines.append("   python segmenter_blocks.py --archive \"C:\\path\\to\\Archive\" --profile analysis --max-chars-per-block 20000 --max-bytes-per-block 1000000\n")
    lines.append("   ```\n")
    lines.append("4. **Формирование очереди** — создать задания для обработки блоков:\n")
    lines.append("   ```powershell\n")
    lines.append("   python queue_maker.py --archive \"C:\\path\\to\\Archive\" --prompt-template analysis_v1\n")
    lines.append("   ```\n")
    lines.append("5. **Просмотр очереди** — вывести первые N задач:\n")
    lines.append("   ```powershell\n")
    lines.append("   python queue_sampler.py --archive \"C:\\path\\to\\Archive\" --limit 20\n")
    lines.append("   ```\n")
    lines.append("6. **Проверка согласованности** — убедиться, что для каждого RAW есть блок:\n")
    lines.append("   ```powershell\n")
    lines.append("   python consistency_check.py --archive \"C:\\path\\to\\Archive\"\n")
    lines.append("   ```\n\n")

    # Zero‑loss policy
    lines.append("## Политика «0% потерь» и атомарности\n")
    lines.append("Наши процессы настроены на полное сохранение данных:\n")
    lines.append("- **Неизменяемость файлов**: исходные файлы копируются в RAW без модификации.\n")
    lines.append("- **Дедупликация**: один и тот же контент сохраняется только один раз по его SHA‑256.\n")
    lines.append("- **Атомарные операции**: перенос файлов осуществляется через `os.replace`, что исключает частичные записи.\n")
    lines.append("- **Файловые блокировки**: индексы и очереди обновляются с использованием lock‑файлов, избегая гонок.\n")
    lines.append("- **Идемпотентность**: повторный запуск скриптов не приводит к появлению дубликатов или потере данных.\n\n")

    # Logs and reports
    lines.append("## Логи и отчёты\n")
    lines.append("Все скрипты ведут журналы в каталоге **Logs**. В случае ошибок обращайтесь к файлам `archivator_raw.log`, `raw_index_verify.log`, `segmenter.log`, `queue_maker.log` и т.д.\n")
    lines.append("Индексные файлы и отчёты (например, `raw_verify_report.json`, `consistency_report.json`, `sample_selection.json`) размещаются в каталоге **Index** или **Logs**. Открывайте их любым текстовым редактором для подробной информации.\n")

    return "\n".join(lines)


def main() -> int:
    args = parse_arguments()
    archive_root = Path(args.archive).resolve()
    readme_path = archive_root / "README.md"
    content = generate_readme()
    try:
        readme_path.parent.mkdir(parents=True, exist_ok=True)
        with readme_path.open("w", encoding="utf-8") as f:
            f.write(content)
    except Exception as exc:
        # If writing fails, print error and return non‑zero exit code
        print(f"Failed to write README: {exc}")
        return 1
    print("README scaffold written")
    return 0


if __name__ == "__main__":
    try:
        exit_code = main()
    except KeyboardInterrupt:
        exit_code = 130
    raise SystemExit(exit_code)