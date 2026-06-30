#!/usr/bin/env python3
"""Generate 05b from 05a: plan-JOIN ipgChRl → ipgChRl_2606."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
src = ROOT / "05a_PATCH_PercentBrn_fnIpgChDats_2606.sql"
dst = ROOT / "05b_PATCH_PercentBrn_ipgChRl_2606.sql"

text = src.read_text(encoding="utf-8")

text = text.replace(
    "05a_PATCH_PercentBrn_fnIpgChDats_2606.sql",
    "05b_PATCH_PercentBrn_ipgChRl_2606.sql",
    1,
)
text = text.replace(
    "Назначение: Этап 20.2 — @dt из fnIpgChDats_2606 + ipgChRl_2606; убрать legacy UNION 01.01.",
    "Назначение: Этап 21.2 — plan-JOIN gap/gip/gup: ipgChRl → ipgChRl_2606 (ipgcrv*).\n"
    "--   Кумулятивно включает этап 20.2 (календарь fnIpgChDats_2606). Применять после 05a или вместо повторного 05a.",
    1,
)
text = text.replace(
    "=== 05a: PATCH PercentBrn_2606 fnIpgChDats_2606 ===",
    "=== 05b: PATCH PercentBrn_2606 plan-JOIN ipgChRl_2606 ===",
    1,
)
text = text.replace(
    "=== 05a: fnIpgChRsltCstUtlPercentBrn_2606 patched ===",
    "=== 05b: fnIpgChRsltCstUtlPercentBrn_2606 patched (plan-JOIN ipgChRl_2606) ===",
    1,
)

# Year lookup
text = re.sub(
    r"from ags\.ipgChRl c\s+join ags\.ipg i on c\.ipgcrIpg = i\.ipgKey",
    "from ags.ipgChRl_2606 c\n\t\t\t\t\t\t\t\t\tjoin ags.ipg i on c.ipgcrvIpg = i.ipgKey",
    text,
)
text = text.replace("where c.ipgcrChain = @ipgChKey", "where c.ipgcrvChain = @ipgChKey")

# Plan-JOIN subqueries (gap: one-line select; gip/gup: multiline)
plan_block = re.compile(
    r"(select\s+)(ipgcrChain, ipgcrIpg,)([\s\S]*?from ags\.)ipgChRl( r[\s\S]*?join ags\.ipgUtPlGr g on r\.)ipgcrUtPlGr",
    re.MULTILINE,
)

def repl_plan(m: re.Match[str]) -> str:
    sel = m.group(1)
    if m.group(2).startswith("ipgcrChain"):
        cols = "r.ipgcrvChain AS ipgcrChain, r.ipgcrvIpg AS ipgcrIpg,"
    else:
        cols = "r.ipgcrvChain AS ipgcrChain, r.ipgcrvIpg AS ipgcrIpg,"
    return f"{sel}{cols}{m.group(3)}ipgChRl_2606{m.group(4)}ipgcrvUtPlGr"

text, n = plan_block.subn(repl_plan, text)
if n != 3:
    raise SystemExit(f"expected 3 plan-JOIN replacements, got {n}")

if re.search(r"from ags\.ipgChRl\b", text):
    raise SystemExit("legacy ipgChRl still present")

dst.write_text(text, encoding="utf-8")
print(f"Wrote {dst.name}, plan blocks={n}")
