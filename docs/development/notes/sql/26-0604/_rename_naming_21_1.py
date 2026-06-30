#!/usr/bin/env python3
"""Этап 21.1: массовая замена имён объектов стека _2606 в SQL/скриптах пакета 26-0604."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent

# Порядок важен: сначала длинные / уникальные идентификаторы
REPLACEMENTS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"fnIpgChRlEnd_2606"), "fnIpgChRlEnd_2606"),
    (re.compile(r"fnIpgChDats_2606"), "fnIpgChDats_2606"),
    (re.compile(r"vIpgChRl_2606"), "vIpgChRl_2606"),
    (re.compile(r"ipgChRl_2606"), "ipgChRl_2606"),
    (re.compile(r"stIpgOutLimPn_2606(?!_2606)"), "stIpgOutLimPn_2606"),
]

# Имена файлов в комментариях и README
FILE_RENAMES: list[tuple[str, str]] = [
    ("01_CREATE_TABLE_ipgChRl_2606.sql", "01_CREATE_TABLE_ipgChRl_2606.sql"),
    ("02_CREATE_FUNCTION_fnIpgChDats_2606.sql", "02_CREATE_FUNCTION_fnIpgChDats_2606.sql"),
    ("10a_CREATE_TABLE_stIpgOutLimPn_2606.sql", "10a_CREATE_TABLE_stIpgOutLimPn_2606.sql"),
    ("10c_SEED_stIpgOutLimPn_2606.sql", "10c_SEED_stIpgOutLimPn_2606.sql"),
    (
        "05a_PATCH_PercentBrn_fnIpgChDats_2606.sql",
        "05a_PATCH_PercentBrn_fnIpgChDats_2606.sql",
    ),
]

EXTENSIONS = {".sql", ".sh", ".py", ".md", ".txt"}


def transform(text: str) -> str:
    for pattern, repl in REPLACEMENTS:
        text = pattern.sub(repl, text)
    for old, new in FILE_RENAMES:
        text = text.replace(old, new)
    return text


def main() -> None:
    changed: list[Path] = []
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file():
            continue
        if path.name.startswith("01b_MIGRATE"):
            continue
        if path.suffix.lower() not in EXTENSIONS:
            continue
        if ".bak" in path.suffixes or path.suffix == ".bak":
            continue
        original = path.read_text(encoding="utf-8")
        updated = transform(original)
        if updated != original:
            path.write_text(updated, encoding="utf-8")
            changed.append(path)
    print(f"Updated {len(changed)} files")
    for p in changed:
        print(f"  {p.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
