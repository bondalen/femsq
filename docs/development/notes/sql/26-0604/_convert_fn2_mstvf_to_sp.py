#!/usr/bin/env python3
"""MSTVF fnIpgChRsltCstUtl2_2606 → SP spIpgChRsltCstUtl2_2606 (#temp + indexes, этап 14.3)."""
from pathlib import Path
import re

SRC = Path(__file__).with_name("04_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2606.sql")
OUT = Path(__file__).with_name("04b_CREATE_PROCEDURE_spIpgChRsltCstUtl2_2606.sql")

TEMP_TABLES = (
    "raFact2408",
    "raFactRalp",
    "raFactMnrl",
    "raFactPrDoc",
    "agFeeFact",
    "schemeRows",
    "mastMonthEnd",
    "branchCache",
)

INDEX_BLOCK = """
    -- Опционально: индекс #schemeRows (на SQL 2012 prod — seek в allMonthsForIpg)
    CREATE CLUSTERED INDEX IX_schemeRows ON #schemeRows (ipgKey, ipgpCstAgPn, iShKey, mNum);
    CREATE NONCLUSTERED INDEX IX_schemeRows_cpn ON #schemeRows (ipgpCstAgPn);
"""

# Для замера без индексов: INDEX_BLOCK = N''


def add_database_collation(body: str) -> str:
    """#temp в tempdb наследует Latin1 — явный DATABASE_DEFAULT для nvarchar (как у @table)."""

    def fix_block(m: re.Match) -> str:
        block = m.group(0)

        def col(m2: re.Match) -> str:
            base, nullability = m2.group(1), m2.group(2) or ""
            return f"{base} COLLATE DATABASE_DEFAULT{nullability}"

        return re.sub(
            r"(nvarchar\([^)]+\))(\s+(?:NOT\s+)?NULL)?(?!\s+COLLATE)",
            col,
            block,
            flags=re.IGNORECASE,
        )

    return re.sub(
        r"CREATE TABLE #\w+\s*\(.*?\n\s*\)",
        fix_block,
        body,
        flags=re.DOTALL,
    )


def replace_temp_tables(text: str) -> str:
    for name in TEMP_TABLES:
        text = re.sub(
            rf"DECLARE @{name} TABLE",
            f"CREATE TABLE #{name}",
            text,
            count=1,
        )
        text = text.replace(f"@{name}", f"#{name}")
    return add_database_collation(text)


def main() -> None:
    raw = SRC.read_text(encoding="utf-8")
    if "spIpgChRsltCstUtl2_2606" in raw and OUT.exists():
        print("Source already SP? Use 04b output.")
        return

    m = re.search(
        r"CREATE OR ALTER FUNCTION ags\.fnIpgChRsltCstUtl2_2606\s*\(\s*"
        r"@ipgChKey\s+int,\s*@ipgStKey\s+int\s*=\s*NULL,\s*@stCostKey\s+int\s*=\s*NULL\s*\)"
        r"\s*RETURNS @TblRslt TABLE\s*\((.*?)\)\s*AS\s*BEGIN",
        raw,
        re.DOTALL,
    )
    if not m:
        raise SystemExit("fn2 header not found")

    body_start = m.end()
    end_m = re.search(r"\s*RETURN;\s*\nEND\b", raw[body_start:])
    if not end_m:
        raise SystemExit("RETURN; END not found")
    body = raw[body_start : body_start + end_m.start()]

    body = replace_temp_tables(body)

    # После заполнения #schemeRows — индексы (до branchCache и CTE ipgBase)
    marker = "    INSERT INTO #branchCache (cstapbCstAgPn, branch)"
    if marker not in body:
        raise SystemExit("branchCache insert marker not found")
    idx_block = INDEX_BLOCK
    if idx_block.strip():
        body = body.replace(marker, idx_block + "\n" + marker, 1)

    # Финальный результат — SELECT вместо INSERT INTO @TblRslt (CTE + INSERT SELECT)
    body = re.sub(
        r"INSERT INTO @TblRslt\s*\n\s*SELECT",
        "SELECT",
        body,
        count=1,
    )
    body = re.sub(
        r"INSERT INTO #TblRslt\s*\n\s*SELECT",
        "SELECT",
        body,
        count=1,
    )

    header = """USE [FishEye];
GO

-- =============================================================================
-- Файл:    04b_CREATE_PROCEDURE_spIpgChRsltCstUtl2_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: fn2_2606 как SP с #temp + индексы (Ступень 3, этап 14.3).
--   Логика идентична 04 (MSTVF v9.0); UDF не поддерживает #temp на SQL 2012.
-- Зависимости: 03, 03b, 03c, fnMasteringStIpgStCost_2606, fnIpgChDatsV.
-- Автор:   Александр | Дата: 2026-06-15
-- =============================================================================

PRINT N'=== 04b: CREATE PROCEDURE ags.spIpgChRsltCstUtl2_2606 ===';
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE ags.spIpgChRsltCstUtl2_2606
(
    @ipgChKey   int,
    @ipgStKey   int = NULL,
    @stCostKey  int = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
"""

    footer = """
END
GO

PRINT N'=== 04b: ags.spIpgChRsltCstUtl2_2606 создана ===';
GO
"""

    out = header + body + footer
    OUT.write_text(out, encoding="utf-8")
    print(f"Written {OUT} ({len(out)} chars)")


if __name__ == "__main__":
    main()
