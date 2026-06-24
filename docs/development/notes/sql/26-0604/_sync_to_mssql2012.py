#!/usr/bin/env python3
"""
Синхронизация dev SQL (CREATE OR ALTER) → MSSQL2012/ (DROP + CREATE).
Использование: python3 _sync_to_mssql2012.py 03c_CREATE_FUNCTION_fnMasteringCstAgPnSh_2606.sql
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent
MSSQL2012 = ROOT / "MSSQL2012"


def convert_to_2012(text: str, basename: str) -> str:
    """Преобразует dev-скрипт в синтаксис SQL Server 2012."""
    text = text.replace("CREATE OR ALTER FUNCTION", "CREATE FUNCTION")

    header = f"""USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/{basename}
-- Пакет:   docs/development/notes/sql/26-0604/
-- Зеркало dev. Синхронизировано скриптом _sync_to_mssql2012.py
-- =============================================================================

"""
    # Убрать dev-заголовок до первого PRINT или SET ANSI
    m = re.search(r"(PRINT\s|SET ANSI_NULLS)", text)
    body = text[m.start() :] if m else text

    # Вставить DROP перед каждым CREATE FUNCTION, если ещё нет
    def add_drop(match: re.Match) -> str:
        full_name = match.group(1)
        short = full_name.split(".")[-1]
        start = match.start()
        window = body[max(0, start - 300) : start]
        if f"DROP FUNCTION {short}" in window or f"DROP FUNCTION ags.{short}" in window:
            return match.group(0)
        return (
            f"\nIF OBJECT_ID(N'ags.{short}', N'IF') IS NOT NULL\n"
            f"    DROP FUNCTION ags.{short};\n"
            f"IF OBJECT_ID(N'ags.{short}', N'TF') IS NOT NULL\n"
            f"    DROP FUNCTION ags.{short};\n"
            f"IF OBJECT_ID(N'ags.{short}', N'FN') IS NOT NULL\n"
            f"    DROP FUNCTION ags.{short};\n"
            f"GO\n\n"
            f"CREATE FUNCTION ags.{short}"
        )

    body = re.sub(r"CREATE FUNCTION (ags\.\w+)", add_drop, body)

    return header + body


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: _sync_to_mssql2012.py <filename.sql> [filename2.sql ...]")
        return 1

    for arg in sys.argv[1:]:
        src = ROOT / arg
        if not src.exists():
            print(f"SKIP: {src} not found")
            continue
        dst = MSSQL2012 / src.name
        out = convert_to_2012(src.read_text(encoding="utf-8"), src.name)
        dst.write_text(out, encoding="utf-8")
        print(f"OK: {dst} ({len(out)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
