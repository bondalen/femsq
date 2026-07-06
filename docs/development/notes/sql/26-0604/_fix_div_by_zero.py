#!/usr/bin/env python3
"""Патч деления на 0: NULLIF в знаменателях (оба стека)."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]  # femsq/

PERCENTBRN_FILES = [
    Path(__file__).resolve().parent / "05a_PATCH_PercentBrn_fnIpgChDats_2606.sql",
    Path(__file__).resolve().parent / "05b_PATCH_PercentBrn_ipgChRl_2606.sql",
    Path(__file__).resolve().parent / "05c_PATCH_PercentBrn_plan_LmMn_2606.sql",
    Path(__file__).resolve().parent / "MSSQL2012/05a_PATCH_PercentBrn_fnIpgChDats_2606.sql",
    Path(__file__).resolve().parent / "MSSQL2012/05b_PATCH_PercentBrn_ipgChRl_2606.sql",
    Path(__file__).resolve().parent / "MSSQL2012/05c_PATCH_PercentBrn_plan_LmMn_2606.sql",
]

SPMSTRG_FILES = [
    ROOT / "code/scripts/spMstrg_2408_SaveToTables.sql",
    ROOT / "docs/development/notes/sql/26-0416/CREATE_PROCEDURE_ags_spMstrg_2408.sql",
    ROOT / "docs/development/notes/sql/26-0416/CREATE_PROCEDURE_ags_spMstrg_2408_ipgSt.sql",
    ROOT / "docs/development/notes/sql/26-0416/CREATE_PROCEDURE_ags_spMstrg_2408_SaveToTables.sql",
    ROOT / "docs/development/notes/sql/26-0416/CREATE_PROCEDURE_ags_spMstrg_2408_SaveToTables_ipgSt.sql",
]

PB_DENOMS = [
    ("w.ag_lim", "NULLIF(w.ag_lim, 0)"),
    ("w.iv_lim", "NULLIF(w.iv_lim, 0)"),
    ("w.uk_lim", "NULLIF(w.uk_lim, 0)"),
    ("w.ag_PlAccum", "NULLIF(w.ag_PlAccum, 0)"),
    ("w.iv_PlAccum", "NULLIF(w.iv_PlAccum, 0)"),
    ("w.uk_PlAccum", "NULLIF(w.uk_PlAccum, 0)"),
]


def patch_percentbrn(text: str) -> str:
    for old, new in PB_DENOMS:
        # не трогать уже пропатченные NULLIF
        text = re.sub(rf"/(?!NULLIF\(){re.escape(old)}\b", f"/{new}", text)
    return text


def patch_spmstrg(text: str) -> str:
    # bare division on p.ag_lim (legacy Access-style)
    text = re.sub(
        r"\(p\.ag_PlFulfillment \+ p\.ag_PlOverFulfillment\)/p\.ag_lim",
        "CASE WHEN p.ag_lim IS NULL OR p.ag_lim = 0 THEN NULL "
        "ELSE (ISNULL(p.ag_PlFulfillment,0)+ISNULL(p.ag_PlOverFulfillment,0))/NULLIF(p.ag_lim,0) END",
        text,
        flags=re.IGNORECASE,
    )
    # CASE ... /p.ag_lim in ELSE
    text = re.sub(
        r"/p\.ag_lim\b",
        "/NULLIF(p.ag_lim, 0)",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"/p\.ag_PlAccum\b",
        "/NULLIF(p.ag_PlAccum, 0)",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"/p\.ag_Pl\b",
        "/NULLIF(p.ag_Pl, 0)",
        text,
        flags=re.IGNORECASE,
    )
    # IIf(..., p.ag_acceptedTtl/p.ag_Pl) → CASE + NULLIF (already may have NULLIF from above)
    text = re.sub(
        r"IIf\s*\(\s*p\.ag_Pl\s+is\s+null\s+Or\s+p\.ag_Pl\s*=\s*0\s*,\s*Null\s*,\s*p\.ag_acceptedTtl/NULLIF\(p\.ag_Pl,\s*0\)\s*\)",
        "CASE WHEN p.ag_Pl IS NULL OR p.ag_Pl = 0 THEN NULL ELSE p.ag_acceptedTtl/NULLIF(p.ag_Pl,0) END",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"IIf\s*\(\s*p\.ag_PlAccum\s+is\s+null\s+Or\s+p\.ag_PlAccum\s*=\s*0\s*,\s*Null\s*,\s*p\.ag_PlFulfillment/NULLIF\(p\.ag_PlAccum,\s*0\)\s*\)",
        "CASE WHEN p.ag_PlAccum IS NULL OR p.ag_PlAccum = 0 THEN NULL ELSE p.ag_PlFulfillment/NULLIF(p.ag_PlAccum,0) END",
        text,
        flags=re.IGNORECASE,
    )
    return text


def main() -> None:
    for path in PERCENTBRN_FILES:
        if not path.exists():
            print(f"SKIP (missing): {path}")
            continue
        orig = path.read_text(encoding="utf-8")
        patched = patch_percentbrn(orig)
        if patched != orig:
            path.write_text(patched, encoding="utf-8")
            print(f"PATCH PercentBrn: {path}")
        else:
            print(f"OK (no change): {path}")

    for path in SPMSTRG_FILES:
        if not path.exists():
            print(f"SKIP (missing): {path}")
            continue
        orig = path.read_text(encoding="utf-8", errors="replace")
        patched = patch_spmstrg(orig)
        if patched != orig:
            path.write_text(patched, encoding="utf-8")
            print(f"PATCH spMstrg: {path}")
        else:
            print(f"OK (no change): {path}")


if __name__ == "__main__":
    main()
