#!/usr/bin/env python3
"""
generate_checklist_pdf.py
Генерация PDF чеклиста дня деплоя из Markdown (docs/deployment/).
Автор: Александр | Дата: 2026-06-16
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

from fpdf import FPDF
from fpdf.enums import XPos, YPos

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[5]
CHECKLIST_MD = REPO_ROOT / "docs/deployment/db-upgrade-spMstrg-2606-deploy-day-checklist.md"
FONT = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
FONT_B = Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")
LINE_H = 4.2


def clean_md(text: str) -> str:
    """Убирает разметку Markdown для plain-text в PDF."""
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    return text.strip()


def parse_table_row(line: str) -> list[str] | None:
    """Разбирает строку markdown-таблицы на ячейки."""
    if not line.startswith("|"):
        return None
    return [clean_md(c) for c in line.strip().strip("|").split("|")]


def is_separator_row(cells: list[str]) -> bool:
    """Строка-разделитель |---|---|."""
    return bool(cells) and all(re.fullmatch(r":?-{1,}:?", c.replace(" ", "")) for c in cells)


def col_widths(pdf: FPDF, n: int) -> list[float]:
    """Ширины столбцов под доступную ширину страницы."""
    w = pdf.epw
    if n == 2:
        return [w * 0.32, w * 0.68]
    if n == 3:
        return [w * 0.38, w * 0.42, w * 0.20]
    if n == 4:
        return [w * 0.07, w * 0.43, w * 0.07, w * 0.43]
    return [w / n] * n


class ChecklistPDF(FPDF):
    """PDF-документ чеклиста с кириллицей."""

    def __init__(self) -> None:
        super().__init__(orientation="P", unit="mm", format="A4")
        self.set_margins(15, 15, 15)
        self.set_auto_page_break(auto=True, margin=15)
        self.add_font("DV", "", str(FONT))
        self.add_font("DV", "B", str(FONT_B))

    def ensure_space(self, need_mm: float) -> None:
        """Добавляет страницу, если блок не помещается."""
        if self.get_y() + need_mm > self.h - self.b_margin:
            self.add_page()

    def write_paragraph(self, text: str, size: int = 9) -> None:
        """Абзац обычного текста."""
        self.set_font("DV", size=size)
        self.multi_cell(self.epw, LINE_H, clean_md(text))
        self.ln(1)

    def write_heading(self, text: str, level: int) -> None:
        """Заголовок H1/H2/H3."""
        sizes = {1: 14, 2: 12, 3: 10}
        self.ln(2 if level > 1 else 0)
        self.set_font("DV", "B", sizes.get(level, 10))
        self.multi_cell(self.epw, LINE_H + 1, clean_md(text))
        self.ln(1)
        self.set_font("DV", size=9)

    def write_codeblock(self, lines: list[str]) -> None:
        """Блок кода (моноширинный мелкий шрифт)."""
        self.ln(1)
        self.set_fill_color(245, 245, 245)
        self.set_font("DV", size=7)
        for line in lines:
            self.ensure_space(LINE_H)
            self.cell(self.epw, LINE_H, line[:120], new_x=XPos.LMARGIN, new_y=YPos.NEXT, fill=True)
        self.ln(2)
        self.set_font("DV", size=9)

    def write_table(self, rows: list[list[str]]) -> None:
        """Таблица с рамками (fpdf2.table API)."""
        if not rows:
            return
        rows = [r for r in rows if not is_separator_row(r)]
        if not rows:
            return

        ncols = max(len(r) for r in rows)
        rows = [r + [""] * (ncols - len(r)) for r in rows]
        widths = tuple(col_widths(self, ncols))

        self.ln(2)
        self.ensure_space(LINE_H * 3)

        with self.table(col_widths=widths, line_height=LINE_H, text_align="LEFT") as table:
            for row_idx, row in enumerate(rows):
                pdf_row = table.row()
                for cell in row:
                    self.set_font("DV", "B" if row_idx == 0 else "", 8)
                    pdf_row.cell(clean_md(cell))

        self.ln(3)
        self.set_font("DV", size=9)


def md_to_pdf(md_path: Path, pdf_path: Path) -> None:
    """Конвертирует чеклист Markdown в PDF."""
    if not FONT.exists():
        raise FileNotFoundError(f"Шрифт не найден: {FONT}")

    lines = md_path.read_text(encoding="utf-8").splitlines()
    pdf = ChecklistPDF()
    pdf.add_page()

    in_code = False
    code_buf: list[str] = []
    table_buf: list[list[str]] = []

    def flush_table() -> None:
        nonlocal table_buf
        if table_buf:
            pdf.write_table(table_buf)
            table_buf = []

    for raw in lines:
        line = raw.rstrip()

        if in_code:
            if line.startswith("```"):
                pdf.write_codeblock(code_buf)
                code_buf = []
                in_code = False
            else:
                code_buf.append(line)
            continue

        if line.startswith("```"):
            flush_table()
            in_code = True
            continue

        cells = parse_table_row(line)
        if cells is not None:
            table_buf.append(cells)
            continue

        flush_table()

        if line.strip() == "---":
            pdf.ln(2)
            continue
        if line.strip() == "":
            pdf.ln(2)
            continue
        if line.startswith("# "):
            pdf.write_heading(line[2:], 1)
        elif line.startswith("## "):
            pdf.write_heading(line[3:], 2)
        elif line.startswith("### "):
            pdf.write_heading(line[4:], 3)
        elif line.startswith("> "):
            pdf.write_paragraph(line[2:], size=8)
        else:
            pdf.write_paragraph(line)

    if in_code and code_buf:
        pdf.write_codeblock(code_buf)
    flush_table()

    pdf_path.parent.mkdir(parents=True, exist_ok=True)
    pdf.output(str(pdf_path))


def main() -> int:
    out = (
        Path(sys.argv[1])
        if len(sys.argv) > 1
        else SCRIPT_DIR / "templates/03_docs/db-upgrade-spMstrg-2606-deploy-day-checklist.pdf"
    )
    if not CHECKLIST_MD.exists():
        print(f"ERROR: {CHECKLIST_MD} not found", file=sys.stderr)
        return 1
    md_to_pdf(CHECKLIST_MD, out)
    print(f"PDF: {out} ({out.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
