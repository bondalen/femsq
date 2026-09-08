#!/usr/bin/env python3
"""Применить скрипты песочницы test_sudz_sm (GO-batches)."""

from __future__ import annotations

import sys
from pathlib import Path

import pymssql

from write_sm_xlsx import write_sandbox_xlsx

HERE = Path(__file__).resolve().parent
FULL_SCRIPTS = [
    "00_CREATE_SCHEMA.sql",
    "01_CREATE_TABLES.sql",
    "02_SEED_BASE.sql",
    "03_PROBE_STRICT.sql",
    "04_RELAX.sql",
    "05_SPLIT_111.sql",
    "06_MERGE_112_113.sql",
    "07_STATUS.sql",
]
CMM_SCRIPTS = [
    "09_CREATE_CMM.sql",
    "10_SEED_CMM.sql",
    "12_MERGEBACK_111.sql",
    "11_RSLT_SKETCH.sql",
]


def load_props() -> dict[str, str]:
    props: dict[str, str] = {}
    for line in Path.home().joinpath(".femsq/database.properties").read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        props[k.strip()] = v.strip()
    return props


def batches(sql: str) -> list[str]:
    out: list[str] = []
    buf: list[str] = []
    for line in sql.splitlines():
        if line.strip().upper() == "GO":
            chunk = "\n".join(buf).strip()
            if chunk:
                out.append(chunk)
            buf = []
        else:
            buf.append(line)
    chunk = "\n".join(buf).strip()
    if chunk:
        out.append(chunk)
    return out


def cell(v) -> str:
    if v is None:
        return ""
    return str(v).replace("|", "/")


def md_table(headers: list[str], rows: list[tuple]) -> str:
    line = "| " + " | ".join(headers) + " |"
    sep = "| " + " | ".join("---" for _ in headers) + " |"
    body = "\n".join(
        "| " + " | ".join(cell(c) for c in row) + " |" for row in rows
    )
    return "\n".join([line, sep, body])


def write_sketch_report(cur) -> Path:
    out = HERE / "SKETCH.md"

    def q(sql: str) -> list[tuple]:
        cur.execute(sql)
        return list(cur.fetchall())

    def cmm_cell(text, gr_flag, merged: bool) -> str:
        if merged:
            return "↑ слито с строкой выше"
        flag = " · углубленно" if gr_flag else ""
        return f"{text}{flag}" if text else ""

    def fact_cell(ttl, merged: bool, first_label: str | None = None) -> str:
        if merged:
            return "↑ слито с строкой выше"
        label = f" · {first_label}" if first_label else ""
        return f"{ttl}{label}"

    a_rows = q(
        """
        SELECT
            CAST(dv.dvTtl AS decimal(19, 0)),
            dv.dvInvDbt,
            (SELECT c2.cmmText FROM test_sudz_sm.cmm c2
             JOIN test_sudz_sm.DbtValue dv2 ON dv2.dvKey = c2.cmmDv
             JOIN test_sudz_sm.invDbtDbt idd2 ON idd2.iddInvDbt = dv2.dvInvDbt
             WHERE idd2.iddDbt = 111 AND dv2.dvUpl = 201 AND c2.cmmKind = N'mery'),
            (SELECT CASE WHEN EXISTS (
                SELECT 1 FROM test_sudz_sm.cnInvGr g2
                JOIN test_sudz_sm.DbtValue dv2 ON dv2.dvKey = g2.cnigDv
                JOIN test_sudz_sm.invDbtDbt idd2 ON idd2.iddInvDbt = dv2.dvInvDbt
                WHERE idd2.iddDbt = 111 AND dv2.dvUpl = 201 AND g2.cnigCmmGr = 201
             ) THEN 1 ELSE 0 END),
            c.cmmText,
            CASE WHEN gr.cnigKey IS NULL THEN 0 ELSE 1 END
        FROM test_sudz_sm.DbtValue dv
        JOIN test_sudz_sm.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
        LEFT JOIN test_sudz_sm.cmm c ON c.cmmDv = dv.dvKey AND c.cmmGr = 202 AND c.cmmKind = N'mery'
        LEFT JOIN test_sudz_sm.cnInvGr gr ON gr.cnigDv = dv.dvKey AND gr.cnigCmmGr = 202
        WHERE idd.iddDbt = 111 AND dv.dvUpl = 202
        ORDER BY dv.dvInvDbt
        """
    )
    b_rows = q(
        """
        SELECT
            CAST((SELECT dvTtl FROM test_sudz_sm.DbtValue v
                  JOIN test_sudz_sm.invDbtDbt b ON b.iddInvDbt = v.dvInvDbt
                  WHERE b.iddDbt = 111 AND v.dvUpl = 201) AS decimal(19, 0)),
            c.cmmText,
            CASE WHEN gr.cnigKey IS NULL THEN 0 ELSE 1 END
        FROM test_sudz_sm.DbtValue dv
        JOIN test_sudz_sm.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
        LEFT JOIN test_sudz_sm.cmm c ON c.cmmDv = dv.dvKey AND c.cmmGr = 202 AND c.cmmKind = N'mery'
        LEFT JOIN test_sudz_sm.cnInvGr gr ON gr.cnigDv = dv.dvKey AND gr.cnigCmmGr = 202
        WHERE idd.iddDbt = 111 AND dv.dvUpl = 202
        ORDER BY dv.dvInvDbt
        """
    )
    c_rows = q(
        """
        SELECT
            CAST((SELECT dvTtl FROM test_sudz_sm.DbtValue v
                  JOIN test_sudz_sm.invDbtDbt b ON b.iddInvDbt = v.dvInvDbt
                  WHERE b.iddDbt = 111 AND v.dvUpl = 210) AS decimal(19, 0)),
            c.cmmText,
            CASE WHEN gr.cnigKey IS NULL THEN 0 ELSE 1 END
        FROM test_sudz_sm.DbtValue dv
        JOIN test_sudz_sm.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
        LEFT JOIN test_sudz_sm.cmm c ON c.cmmDv = dv.dvKey AND c.cmmGr = 209 AND c.cmmKind = N'mery'
        LEFT JOIN test_sudz_sm.cnInvGr gr ON gr.cnigDv = dv.dvKey AND gr.cnigCmmGr = 209
        WHERE idd.iddDbt = 111 AND dv.dvUpl = 209
        ORDER BY dv.dvInvDbt
        """
    )
    m = q(
        """
        SELECT dv.dvInvDbt, CAST(dv.dvTtl AS decimal(19, 0)), c.cmmText,
               CASE WHEN gr.cnigKey IS NULL THEN N'' ELSE N'углубленно' END
        FROM test_sudz_sm.DbtValue dv
        JOIN test_sudz_sm.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
        LEFT JOIN test_sudz_sm.cmm c ON c.cmmDv = dv.dvKey AND c.cmmGr = 201
        LEFT JOIN test_sudz_sm.cnInvGr gr ON gr.cnigDv = dv.dvKey AND gr.cnigCmmGr = 201
        WHERE idd.iddDbt = 112 AND dv.dvUpl = 201
        ORDER BY dv.dvInvDbt
        """
    )
    tl = q(
        """
        SELECT dv.dvUpl, COUNT(*) AS n, CAST(SUM(dv.dvTtl) AS decimal(19, 0)) AS s
        FROM test_sudz_sm.DbtValue dv
        JOIN test_sudz_sm.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
        WHERE idd.iddDbt = 111
        GROUP BY dv.dvUpl
        ORDER BY dv.dvUpl
        """
    )

    a_md = [
        (
            fact_cell(r[0], False),
            cmm_cell(r[2], r[3], merged=(i > 0)),
            cmm_cell(r[4], r[5], merged=False),
        )
        for i, r in enumerate(a_rows)
    ]
    b_md = [
        (
            fact_cell(r[0], merged=(i > 0), first_label="одна ячейка на две строки"),
            cmm_cell(r[1], r[2], merged=False),
        )
        for i, r in enumerate(b_rows)
    ]
    c_md = [
        (
            fact_cell(r[0], merged=(i > 0), first_label="снова целый после merge-back"),
            cmm_cell(r[1], r[2], merged=False),
        )
        for i, r in enumerate(c_rows)
    ]

    text = "\n".join(
        [
            "# Макет Rslt — песочница split/merge",
            "",
            "Откройте Preview. Канон полос — Excel-листы A и C: `ags_Yr_DbtChangesRslt_sm_sandbox.xlsx`.",
            "",
            "**Как читать:** «↑ слито с строкой выше» = в Excel одна ячейка, растянутая на две строки. "
            "Зерно комментариев = число Value **того** среза, к которому относится группа, а не крайней полосы фактов.",
            "",
            "## Долг 111 — сколько строк на срезе",
            "",
            md_table(["выгрузка", "число Value", "сумма"], tl),
            "",
            "201: целый → 202–209: split 2×18000 → 210: снова целый.",
            "",
            "## Полоса A — крайний 202 (две строки факта), старые с 201 (одна ячейка)",
            "",
            "Как если открыть QI на 202, а «старые» взять с 201.",
            "",
            md_table(["факт 202", "старые комментарии (201)", "новые комментарии (202)"], a_md),
            "",
            "## Полоса B — крайний 201 (одна ячейка факта), старые с 202 (две ячейки)",
            "",
            "Обратная картинка: смотрим «назад» с целого среза на уже разделённый.",
            "",
            md_table(["факт 201", "старые комментарии (202)"], b_md),
            "",
            "## Полоса C — крайний 210 (снова целый), старые с 209 (ещё две доли)",
            "",
            "После обратного слияния на 210: факт снова одна ячейка 36000, комментарии предшествующего среза остаются двумя.",
            "",
            md_table(["факт 210", "старые комментарии (209)"], c_md),
            "",
            "## Долг 112 после слияния канонов (срез 201)",
            "",
            md_table(["слот", "сумма", "комментарий", "группа"], m),
            "",
            "Две бывшие задолженности (112 и 113) стали одним `Dbt`; две строки Value и два комментария сохранились.",
            "",
        ]
    )
    out.write_text(text, encoding="utf-8")
    return out


def main() -> None:
    props = load_props()
    conn = pymssql.connect(
        server=props["host"],
        port=int(props.get("port", "1433")),
        user=props.get("username") or props.get("user"),
        password=props["password"],
        database=props.get("database", "FishEye"),
        autocommit=True,
    )
    cur = conn.cursor()
    if "--cmm" in sys.argv:
        names = CMM_SCRIPTS
    elif "--report" in sys.argv or "--xlsx" in sys.argv:
        names = []
    else:
        names = FULL_SCRIPTS
    for name in names:
        path = HERE / name
        print(f"=== {name} ===")
        for i, batch in enumerate(batches(path.read_text()), start=1):
            try:
                cur.execute(batch)
                while True:
                    if cur.description:
                        rows = cur.fetchall()
                        if rows:
                            if name.startswith("11"):
                                print(f"  [{i}] {len(rows)} row(s) → SKETCH.md")
                            else:
                                print(f"  [{i}] {len(rows)} row(s): {rows[:8]}")
                    if not cur.nextset():
                        break
            except Exception as exc:
                print(f"  [{i}] FAIL: {exc}")
                if name.startswith("03"):
                    continue
                raise
    if "--cmm" in sys.argv or "--report" in sys.argv or "--xlsx" in sys.argv:
        report = write_sketch_report(cur)
        xlsx = write_sandbox_xlsx(cur, HERE)
        print("отчёт:", report)
        print("excel:", xlsx)
    conn.close()
    print("done")


if __name__ == "__main__":
    main()
