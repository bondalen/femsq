#!/usr/bin/env python3
"""
Сравнение перечней документов RALP в Excel-файлах март/июль.

Ключ: (№ отчета col P, Дата col C, Код проекта col A, ДО col H) с нормализацией num.
Соответствует строкам, попадающим в staging при загрузке снимка.
"""
import re
import zipfile
from collections import Counter
from datetime import date, timedelta
from pathlib import Path
from xml.etree import ElementTree as ET

NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
MARCH = Path("/mnt/nb-win-share/femsq/excel/2026_03/(2026)_Аренда_рабочий.xlsx")
JULY = Path("/mnt/nb-win-share/femsq/excel/2026-07/(2026)_Аренда_рабочий.xlsx")
SHEET = "Аренда_Земли"

# Фиксированные колонки листа «Аренда_Земли» (0-based)
COL = dict(num=15, date=2, cst=0, og=7, cost=14, note=19, arrived=20, sent=21, returned=22, presented=25)


def col_letters_to_index(col: str) -> int:
    n = 0
    for c in col:
        n = n * 26 + (ord(c.upper()) - 64)
    return n - 1


def excel_serial_to_date(serial: float) -> date:
    n = int(float(serial))
    if n < 60:
        return date(1899, 12, 31) + timedelta(days=n)
    return date(1899, 12, 30) + timedelta(days=n)


def parse_date_val(val):
    if val is None:
        return None
    s = str(val).strip()
    if re.fullmatch(r"\d+(\.\d+)?", s):
        return excel_serial_to_date(s)
    m = re.search(r"(\d{2})\.(\d{2})\.(\d{4})", s)
    return date(int(m.group(3)), int(m.group(2)), int(m.group(1))) if m else None


def norm_num(num, presented):
    if num is None:
        return None
    s = str(num).strip()
    if not s:
        return None
    pres = str(presented).strip().lower() in ("1", "true", "да", "yes", "x")
    return s.replace("-", "/", 1) if pres and "-" in s else s


def load_sheet_rows(path: Path, sheet_name: str):
    with zipfile.ZipFile(path) as z:
        sst = []
        if "xl/sharedStrings.xml" in z.namelist():
            root = ET.fromstring(z.read("xl/sharedStrings.xml"))
            for si in root.findall("m:si", NS):
                sst.append("".join((t.text or "") for t in si.findall(".//m:t", NS)))
        wb = ET.fromstring(z.read("xl/workbook.xml"))
        sheets = {
            sh.get("{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"): sh.get("name")
            for sh in wb.find("m:sheets", NS)
        }
        rels = {
            r.get("Id"): r.get("Target")
            for r in ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))
            if "worksheet" in r.get("Type", "")
        }
        rid = next(k for k, v in sheets.items() if v == sheet_name)
        sh = ET.fromstring(z.read("xl/" + rels[rid].lstrip("/")))
        rows = {}
        for row in sh.findall(".//m:sheetData/m:row", NS):
            ri = int(row.get("r"))
            cells = {}
            for c in row.findall("m:c", NS):
                ref = c.get("r")
                ci = col_letters_to_index(re.match(r"([A-Z]+)", ref).group(1))
                v = c.find("m:v", NS)
                if v is None or v.text is None:
                    continue
                cells[ci] = sst[int(v.text)] if c.get("t") == "s" else v.text
            rows[ri] = cells
    return rows


def extract_docs(path: Path):
    rows = load_sheet_rows(path, SHEET)
    docs = []
    for ri in sorted(rows):
        if ri < 3:
            continue
        cells = rows[ri]

        def g(k):
            return cells.get(COL[k])

        dt = parse_date_val(g("date"))
        num = norm_num(g("num"), g("presented"))
        if not num or not dt:
            continue
        docs.append(
            {
                "row": ri,
                "num": num,
                "date": dt,
                "cst": str(g("cst") or "").strip(),
                "og": str(g("og") or "").strip(),
                "arrived": str(g("arrived") or "").strip(),
                "sent": str(g("sent") or "").strip(),
                "returned": str(g("returned") or "").strip(),
                "note": str(g("note") or "").strip(),
                "cost": str(g("cost") or "").strip(),
            }
        )
    return docs


def ra_key(d):
    return (d["num"], d["date"], d["cst"], d["og"])


def au_state(d):
    return (d["arrived"], d["sent"], d["returned"], d["note"], d["cost"])


def main():
    march = extract_docs(MARCH)
    july = extract_docs(JULY)
    bm = {ra_key(d): d for d in march}
    bj = {ra_key(d): d for d in july}
    km, kj = set(bm), set(bj)
    only_m, only_j, both = km - kj, kj - km, km & kj
    diff = [k for k in both if au_state(bm[k]) != au_state(bj[k])]

    print("=== Перечень документов RALP (лист Аренда_Земли) ===")
    for label, docs, keys in [("MARCH", march, km), ("JULY", july, kj)]:
        mc = Counter(d["date"].month for d in docs)
        print(f"{label}: rows={len(docs)} unique={len(keys)} months={dict(sorted(mc.items()))}")
    print(f"only_march={len(only_m)} only_july={len(only_j)} both={len(both)} state_diff={len(diff)}")
    if only_j:
        print("only_july (first):", sorted(only_j, key=lambda x: x[1])[:3])
        print("only_july (last): ", sorted(only_j, key=lambda x: x[1])[-3:])
    if diff:
        k = diff[0]
        print("state_diff example:", k)
        print("  march:", au_state(bm[k]))
        print("  july: ", au_state(bj[k]))


if __name__ == "__main__":
    main()
