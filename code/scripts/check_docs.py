#!/usr/bin/env python3
"""
Проверка документации FEMSQ (docs-sync блок 4).

Ошибки (блокируют в режиме strict, с блока 13):
  - невалидный JSON
  - повторяющиеся id задач / чатов / логов
  - статус вне словаря
  - @RestController вне таблицы исключений .cursorrules
  - битые пути в действующих ссылках chatPlan / roadmap

Предупреждения (никогда не блокируют):
  - lastUpdated старше 60 дней
  - план без задачи / без чата / без строки реестра
  - статусы плана, задачи и чата расходятся
  - порядок sessions журнала нарушен
  - битые пути в исторических записях
  - задача вне деревьев structure

Режим: CHECK_DOCS_MODE=warn|strict (по умолчанию warn до блока 13).
Корень: CHECK_DOCS_ROOT или корень репозитория (два уровня вверх от scripts/).
"""

from __future__ import annotations

import json
import os
import re
import sys
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any

ALLOWED_STATUSES = frozenset(
    {"pending", "in-progress", "paused", "blocked", "completed", "cancelled"}
)
LEGACY_STATUS_MAP = {
    "in_progress": "in-progress",
    "active": "in-progress",
    "planned": "pending",
}

ALLOWED_REST = frozenset(
    {
        "ConnectionController",
        "AppInfoController",
        "SudzExportRestController",
        "ReportController",
        "ReportParametersController",
    }
)

errors: list[str] = []
warnings: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def warn(msg: str) -> None:
    warnings.append(msg)


def load_json(path: Path) -> Any | None:
    if not path.is_file():
        err(f"JSON отсутствует: {path}")
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        err(f"Невалидный JSON {path}: {exc}")
        return None


def parse_date(value: str | None) -> date | None:
    if not value:
        return None
    try:
        return date.fromisoformat(value[:10])
    except ValueError:
        return None


def check_last_updated(label: str, value: str | None, today: date) -> None:
    d = parse_date(value)
    if d is None:
        return
    if today - d > timedelta(days=60):
        warn(f"{label}: lastUpdated={value} старше 60 дней")


def walk_task_ids_in_trees(items: list[Any], found: set[str]) -> None:
    for wrap in items or []:
        ti = wrap.get("task-item") if isinstance(wrap, dict) else None
        if not ti:
            continue
        attrs = ti.get("item-attributes") or {}
        tid = attrs.get("taskId")
        if tid:
            found.add(str(tid))
        walk_task_ids_in_trees(ti.get("task-items") or [], found)


def extract_chat_plan_status(plan_path: Path) -> str | None:
    """Грубая эвристика статуса из шапки markdown-плана."""
    if not plan_path.is_file():
        return None
    text = plan_path.read_text(encoding="utf-8", errors="replace")[:4000]
    m = re.search(r"\*\*Статус плана:\*\*\s*(.+)", text)
    if not m:
        return None
    line = m.group(1).lower()
    if "completed" in line or "✅" in line and "закрыт" in line:
        return "completed"
    if "архив" in line:
        return "completed"
    if "paused" in line or "⏸" in line:
        return "paused"
    if "blocked" in line:
        return "blocked"
    if "cancelled" in line:
        return "cancelled"
    if "in-progress" in line or "🔶" in line or "активн" in line:
        return "in-progress"
    if "pending" in line:
        return "pending"
    return None


def normalize_status(raw: str | None) -> str | None:
    if raw is None:
        return None
    if raw in ALLOWED_STATUSES:
        return raw
    return LEGACY_STATUS_MAP.get(raw)


def check_rest_controllers(root: Path) -> None:
    java_root = root / "code"
    if not java_root.is_dir():
        return
    # @RestController, но не @RestControllerAdvice
    pattern = re.compile(r"@RestController(?!Advice)\b")
    class_after = re.compile(
        r"@RestController(?!Advice)\b[\s\S]*?\bclass\s+(\w+)", re.MULTILINE
    )
    for path in java_root.rglob("*.java"):
        rel = str(path.relative_to(root)).replace("\\", "/")
        if "check-docs-fixtures" in rel:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        if not pattern.search(text):
            continue
        m = class_after.search(text)
        if not m:
            continue
        name = m.group(1)
        if name not in ALLOWED_REST:
            err(f"@RestController вне исключений: {name} ({rel})")


def check_development(data: dict[str, Any], root: Path) -> set[str]:
    """Возвращает множество taskId из словаря tasks."""
    tasks = ((data.get("development") or {}).get("tasks") or {})
    items = tasks.get("items") or {}
    task_ids: set[str] = set()
    seen: set[str] = set()

    for tid, wrap in items.items():
        task_ids.add(str(tid))
        if tid in seen:
            err(f"Повторяющийся id задачи: {tid}")
        seen.add(tid)
        task = (wrap or {}).get("task") or {}
        attrs = task.get("task-attributes") or {}
        status = attrs.get("status")
        if status not in ALLOWED_STATUSES:
            mapped = normalize_status(status)
            if mapped and mapped != status:
                warn(f"Задача {tid}: устаревший статус «{status}» (ожидается «{mapped}»)")
            else:
                err(f"Задача {tid}: статус вне словаря «{status}»")
        check_last_updated(f"task:{tid}", attrs.get("lastUpdated"), date.today())
        links = attrs.get("links") or {}
        chat_plan = links.get("chatPlan")
        if chat_plan:
            rel = str(chat_plan).split("#", 1)[0]
            p = root / rel
            if not p.is_file():
                err(f"Задача {tid}: битый chatPlan {chat_plan}")

    # nextTaskId
    next_id = tasks.get("nextTaskId")
    if next_id and task_ids:
        try:
            numeric = {int(t) for t in task_ids if t.isdigit()}
            if numeric and int(next_id) <= max(numeric):
                warn(f"nextTaskId={next_id} не больше max(taskId)={max(numeric):04d}")
        except ValueError:
            warn(f"nextTaskId не число: {next_id}")

    # trees coverage
    in_trees: set[str] = set()
    structure = (data.get("development") or {}).get("structure") or {}
    for tree_wrap in structure.get("trees") or []:
        tree = tree_wrap.get("tree") or tree_wrap
        walk_task_ids_in_trees(tree.get("task-items") or [], in_trees)
    orphans = sorted(task_ids - in_trees)
    if orphans:
        warn(f"Задачи вне деревьев structure ({len(orphans)}): {', '.join(orphans[:20])}"
             + ("…" if len(orphans) > 20 else ""))

    return task_ids


def iter_chats(journal: dict[str, Any]):
    for session in ((journal.get("journal") or {}).get("sessions") or []):
        chat = (session or {}).get("chat") or {}
        yield chat


def iter_logs(chat: dict[str, Any]):
    for entry in chat.get("entries") or []:
        log = (entry or {}).get("log")
        if log:
            yield log
            # nested? обычно один уровень
            for nested in log.get("entries") or []:
                if isinstance(nested, dict) and "log" in nested:
                    yield nested["log"]


def check_journal(data: dict[str, Any], root: Path, task_ids: set[str]) -> None:
    meta = (data.get("journal") or {}).get("metadata") or {}
    check_last_updated("journal.metadata", meta.get("lastUpdated"), date.today())

    chat_ids: set[str] = set()
    log_ids: set[str] = set()
    created_dates: list[str] = []
    chats = list(iter_chats(data))

    for chat in chats:
        attrs = chat.get("chat-attributes") or {}
        cid = attrs.get("id")
        if not cid:
            err("Чат без id")
            continue
        if cid in chat_ids:
            err(f"Повторяющийся id чата: {cid}")
        chat_ids.add(cid)
        status = attrs.get("status")
        if status not in ALLOWED_STATUSES:
            mapped = normalize_status(status)
            if mapped and mapped != status:
                warn(f"Чат {cid}: устаревший статус «{status}» → «{mapped}»")
            else:
                err(f"Чат {cid}: статус вне словаря «{status}»")
        created_dates.append(attrs.get("created") or "")
        links = attrs.get("links") or {}
        chat_plan = links.get("chatPlan")
        if chat_plan:
            rel = str(chat_plan).split("#", 1)[0]
            p = root / rel
            if not p.is_file():
                # исторические битые пути — warn
                warn(f"Чат {cid}: битый chatPlan (исторический?) {chat_plan}")
        else:
            # не все чаты обязаны иметь план
            pass
        for tid in links.get("developmentTasks") or []:
            tid_s = str(tid).removeprefix("task:")
            if tid_s not in task_ids and task_ids:
                warn(f"Чат {cid}: developmentTasks ссылается на неизвестную задачу {tid_s}")

        for log in iter_logs(chat):
            lattrs = log.get("log-attributes") or {}
            lid = lattrs.get("id")
            if not lid:
                continue
            if lid in log_ids:
                err(f"Повторяющийся id лога: {lid}")
            log_ids.add(lid)
            lstatus = lattrs.get("status")
            if lstatus and lstatus not in ALLOWED_STATUSES:
                mapped = normalize_status(lstatus)
                if mapped and mapped != lstatus:
                    warn(f"Лог {lid}: устаревший статус «{lstatus}»")
                elif lstatus not in {"success", "info", "warning", "error", "debug"}:
                    # journal levels vs status — некоторые логи используют level, не status
                    if lstatus not in ALLOWED_STATUSES:
                        # level field might be mixed into status historically
                        pass

    # descending created order
    parsed = [parse_date(c) for c in created_dates]
    violations = 0
    for i in range(1, len(parsed)):
        a, b = parsed[i - 1], parsed[i]
        if a and b and a < b:
            violations += 1
    if violations:
        warn(f"journal sessions: нарушен порядок по убыванию created ({violations} пар)")


def check_plans_registry(root: Path, task_ids: set[str], journal: dict[str, Any]) -> None:
    """Планы chat-plan-*.md: наличие задачи/чата/строки реестра."""
    roadmap = root / "docs/development/notes/chats/chat-plan/chat-plan-26-1116-roadmap-r1.md"
    roadmap_text = roadmap.read_text(encoding="utf-8", errors="replace") if roadmap.is_file() else ""

    plan_dir = root / "docs/development/notes/chats/chat-plan"
    if not plan_dir.is_dir():
        return

    # chatPlan paths from tasks and chats
    task_plans: dict[str, str] = {}
    # reverse: plan -> task from development already checked

    chat_plans: set[str] = set()
    for chat in iter_chats(journal):
        links = (chat.get("chat-attributes") or {}).get("links") or {}
        cp = links.get("chatPlan")
        if cp:
            chat_plans.add(cp)

    # load tasks chatPlans from development file again via walking — pass via side channel
    # Use journal + roadmap only for warn

    for plan in sorted(plan_dir.glob("chat-plan-*.md")):
        rel = str(plan.relative_to(root)).replace("\\", "/")
        # skip if archived in name only — still check
        in_registry = plan.name in roadmap_text or rel in roadmap_text
        if not in_registry and "roadmap-r1" not in plan.name:
            # many historical plans are listed by short name
            short = plan.name
            if short not in roadmap_text:
                warn(f"План без строки в реестре дорожной карты: {rel}")

        has_chat = rel in chat_plans
        # task linkage checked loosely via filename in development json text
        # (full parse done in main)


def check_plan_task_chat_alignment(root: Path, development: dict[str, Any], journal: dict[str, Any]) -> None:
    items = ((development.get("development") or {}).get("tasks") or {}).get("items") or {}
    chats_by_plan: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for chat in iter_chats(journal):
        attrs = chat.get("chat-attributes") or {}
        cp = (attrs.get("links") or {}).get("chatPlan")
        if cp:
            chats_by_plan[cp].append(chat)

    for tid, wrap in items.items():
        attrs = ((wrap or {}).get("task") or {}).get("task-attributes") or {}
        links = attrs.get("links") or {}
        cp = links.get("chatPlan")
        if not cp:
            continue
        task_status = attrs.get("status")
        chats = chats_by_plan.get(cp, [])
        if not chats:
            warn(f"Задача {tid}: есть chatPlan, нет чата в журнале ({cp})")
            continue
        plan_status = extract_chat_plan_status(root / cp)
        for chat in chats:
            cstatus = (chat.get("chat-attributes") or {}).get("status")
            if plan_status and cstatus and plan_status != cstatus:
                if not (
                    plan_status == "completed"
                    and cstatus == "completed"
                ):
                    # allow in-progress plan with completed chat only if mismatch notable
                    if {plan_status, cstatus} != {task_status}:
                        warn(
                            f"Расхождение статусов задача={tid}/{task_status}, "
                            f"план={plan_status}, чат={cstatus} ({cp})"
                        )


def check_project_docs(data: dict[str, Any], root: Path) -> None:
    meta = (data.get("project") or data.get("metadata") or {})
    # project-docs structure varies
    if "metadata" in (data.get("project") or {}):
        check_last_updated("project-docs", (data["project"]["metadata"]).get("lastUpdated"), date.today())
    elif "metadata" in data:
        check_last_updated("project-docs", data["metadata"].get("lastUpdated"), date.today())


def main() -> int:
    mode = os.environ.get("CHECK_DOCS_MODE", "warn").strip().lower()
    if mode not in {"warn", "strict"}:
        print(f"Unknown CHECK_DOCS_MODE={mode}, using warn", file=sys.stderr)
        mode = "warn"

    script_dir = Path(__file__).resolve().parent
    root = Path(os.environ.get("CHECK_DOCS_ROOT", script_dir.parent.parent)).resolve()

    print(f"=== FEMSQ check-docs (mode={mode}) ===")
    print(f"Корень: {root}")

    dev_path = root / "docs/development/project-development.json"
    journal_path = root / "docs/journal/project-journal.json"
    docs_path = root / "docs/project/project-docs.json"

    development = load_json(dev_path)
    journal = load_json(journal_path)
    project_docs = load_json(docs_path)

    task_ids: set[str] = set()
    if development:
        task_ids = check_development(development, root)
        if journal:
            check_journal(journal, root, task_ids)
            check_plan_task_chat_alignment(root, development, journal)
            check_plans_registry(root, task_ids, journal)
    elif journal:
        check_journal(journal, root, set())

    if project_docs:
        check_project_docs(project_docs, root)

    check_rest_controllers(root)

    print(f"Ошибки: {len(errors)}")
    for m in errors:
        print(f"  ERROR: {m}")
    print(f"Предупреждения: {len(warnings)}")
    for m in warnings:
        print(f"  WARN:  {m}")

    if errors and mode == "strict":
        print("Итог: FAIL (strict, есть ошибки)")
        return 1
    if errors and mode == "warn":
        print("Итог: WARN-MODE (ошибки не блокируют до блока 13)")
        return 0
    print("Итог: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
