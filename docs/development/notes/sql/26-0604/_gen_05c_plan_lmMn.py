#!/usr/bin/env python3
"""Generate 05c from 05b: plan columns from ipgUtPlPnLmMn @212 (Решение 22, этап 21.4.3)."""
from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent
src = ROOT / "05b_PATCH_PercentBrn_ipgChRl_2606.sql"
dst = ROOT / "05c_PATCH_PercentBrn_plan_LmMn_2606.sql"
dst_m2012 = ROOT / "MSSQL2012/05c_PATCH_PercentBrn_plan_LmMn_2606.sql"

# Подзапрос: помесячный и накопленный план @ stCost 212 из LmMn (млн → те же имена колонок, что iuplpM*).
LM_MN_SUBQUERY = """\
(
\t\t\t\t\t\t\t\t\t\t\t\tSELECT
\t\t\t\t\t\t\t\t\t\t\t\t\tpn.ipgpKey AS iuplpIpgPn,
\t\t\t\t\t\t\t\t\t\t\t\t\t@ipgChKey AS ipgcrChain,
\t\t\t\t\t\t\t\t\t\t\t\t\tMAX(up.iuplpSubAg) AS iuplpSubAg,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 1  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM01,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 2  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM02,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 3  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM03,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 4  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM04,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 5  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM05,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 6  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM06,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 7  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM07,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 8  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM08,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 9  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM09,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 10 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM10,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 11 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM11,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn = 12 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM12,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn <= 2  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM02Accum,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn <= 3  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM03Accum,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn <= 4  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM04Accum,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn <= 5  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM05Accum,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn <= 6  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM06Accum,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn <= 7  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM07Accum,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn <= 8  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM08Accum,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn <= 9  THEN mn.iuplpmLim ELSE 0 END) AS iuplpM09Accum,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn <= 10 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM10Accum,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn <= 11 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM11Accum,
\t\t\t\t\t\t\t\t\t\t\t\t\tSUM(CASE WHEN mn.iuplpmMn <= 12 THEN mn.iuplpmLim ELSE 0 END) AS iuplpM12Accum
\t\t\t\t\t\t\t\t\t\t\t\tFROM ags.ipgPn pn
\t\t\t\t\t\t\t\t\t\t\t\t\tINNER JOIN ags.ipgUtPlP up ON up.iuplpIpgPn = pn.ipgpKey
\t\t\t\t\t\t\t\t\t\t\t\t\tINNER JOIN ags.ipgChRl_2606 v
\t\t\t\t\t\t\t\t\t\t\t\t\t\tON v.ipgcrvIpg = pn.ipgpIpg AND v.ipgcrvChain = @ipgChKey
\t\t\t\t\t\t\t\t\t\t\t\t\tINNER JOIN ags.ipgUtPlGrP gp
\t\t\t\t\t\t\t\t\t\t\t\t\t\tON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = v.ipgcrvUtPlGr
\t\t\t\t\t\t\t\t\t\t\t\t\tINNER JOIN ags.ipgUtPlPnLmMn mn
\t\t\t\t\t\t\t\t\t\t\t\t\t\tON mn.iuplpmPlPn = up.iuplpKey AND mn.iuplpmStCost = 212
\t\t\t\t\t\t\t\t\t\t\t\tGROUP BY pn.ipgpKey
\t\t\t\t\t\t\t\t\t\t\t\t)"""

# Старый подзапрос (iuplpM* с ipgUtPlP) — три копии gap/gip/gup
OLD_BLOCK = re.compile(
    r"\(\s*"
    r"select\s+r\.ipgcrvChain AS ipgcrChain, r\.ipgcrvIpg AS ipgcrIpg, iuplpIpgPn, iuplpSubAg\s*"
    r", iuplpM01[\s\S]*?"
    r"join ags\.ipgUtPlP n on p\.iuplgpPl = n\.iuplpPl\s*"
    r"\)",
    re.IGNORECASE,
)


def main() -> None:
    text = src.read_text(encoding="utf-8")
    text = text.replace(
        "05b_PATCH_PercentBrn_ipgChRl_2606.sql",
        "05c_PATCH_PercentBrn_plan_LmMn_2606.sql",
        1,
    )
    text = text.replace(
        "Назначение: Этап 21.2 — plan-JOIN gap/gip/gup: ipgChRl → ipgChRl_2606 (ipgcrv*).\n"
        "--   Кумулятивно включает этап 20.2 (календарь fnIpgChDats_2606). Применять после 05a или вместо повторного 05a.",
        "Назначение: Этап 21.4.3 — plan-колонки ag_Pl/iv_Pl из ipgUtPlPnLmMn @ stCost 212 (Решение 22).\n"
        "--   Кумулятивно: 20.2 (fnIpgChDats_2606), 21.2 (ipgChRl_2606), div-by-zero. Применять после 05b или вместо 05b.",
        1,
    )
    text = text.replace(
        "=== 05b: PATCH PercentBrn_2606 plan-JOIN ipgChRl_2606 ===",
        "=== 05c: PATCH PercentBrn_2606 plan from LmMn @212 ===",
        1,
    )
    text = text.replace(
        "=== 05b: fnIpgChRsltCstUtlPercentBrn_2606 patched (plan-JOIN ipgChRl_2606) ===",
        "=== 05c: fnIpgChRsltCstUtlPercentBrn_2606 patched (plan from LmMn @212) ===",
        1,
    )

    text, n = OLD_BLOCK.subn(LM_MN_SUBQUERY, text)
    if n != 3:
        raise SystemExit(f"expected 3 LmMn subquery replacements, got {n}")

    if "join ags.ipgUtPlP n on p.iuplgpPl = n.iuplpPl" in text:
        raise SystemExit("legacy ipgUtPlP plan subquery still present")

    dst.write_text(text, encoding="utf-8")
    dst_m2012.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(dst, dst_m2012)
    print(f"Wrote {dst.name}, LmMn blocks={n}")
    print(f"Copied to {dst_m2012}")


if __name__ == "__main__":
    main()
