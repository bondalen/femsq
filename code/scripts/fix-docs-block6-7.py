#!/usr/bin/env python3
"""
Одноразовый фикс docs-sync блоков 6.2–6.4 и 7:
  - нормализация статусов (in_progress/active/planned → словарь)
  - суффиксы дублирующихся id логов (+ обновление displayName)
  - сортировка sessions по убыванию created
  - статусы задач по известным закрытым планам (Р-02…Р-05)
  - сирота задач → узел 02.05.99 «Вне деревьев (авто)»
"""

from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEV = ROOT / "docs/development/project-development.json"
JOURNAL = ROOT / "docs/journal/project-journal.json"

ALLOWED = {"pending", "in-progress", "paused", "blocked", "completed", "cancelled"}
LEGACY = {
    "in_progress": "in-progress",
    "active": "in-progress",
    "planned": "pending",
}

# Задачи → целевой статус по сверке с закрытыми планами (docs-sync 6.2 / Р-02…Р-05)
TASK_STATUS_FIXES = {
    # 0069 СУДЗ — план 0802 paused (R2), не completed
    "0069": "paused",
    "0075": "paused",  # 0802
    "0071": "paused",
    # 0077 0922 — план completed
    "0077": "completed",
    # 0054 / 0048 — прод ревизий JAR 156, планы закрыты в блоке 12
    "0054": "completed",
    "0048": "completed",
    # модуль отчётов 0027–0032 — используется
    "0027": "completed",
    "0028": "completed",
    "0029": "completed",
    "0030": "completed",
    "0031": "completed",
    "0032": "completed",
    # корневые
    "0001": "completed",
    "0002": "completed",
    "0003": "completed",
    "0007": "completed",
    "0008": "completed",
    "0018": "completed",
}

# Чаты: id → status (планы закрыты, чат ещё open)
CHAT_STATUS_FIXES = {
    # по Р-08 / расхождениям baseline — закрыть чаты закрытых планов
    "chat-2026-10-19-001": "completed",  # 1019
    "chat-2026-09-22-001": "completed",  # 0922 if exists
    "chat-2026-09-21-001": "completed",
    "chat-2026-10-12-001": "completed",
    "chat-2026-08-19-001": "completed",  # 0819
}


def norm_status(s: str | None) -> str | None:
    if s is None:
        return None
    if s in ALLOWED:
        return s
    return LEGACY.get(s, s)


def fix_display_status(display: str, new_status: str) -> str:
    """Обновляет фрагмент (status, priority) в displayName если есть."""
    return re.sub(
        r"\((in_progress|in-progress|active|pending|paused|blocked|completed|cancelled),",
        f"({new_status},",
        display,
        count=1,
    )


def walk_fix_status(obj):
    if isinstance(obj, dict):
        if "status" in obj and isinstance(obj["status"], str):
            ns = norm_status(obj["status"])
            if ns and ns != obj["status"] and ns in ALLOWED:
                obj["status"] = ns
        for v in obj.values():
            walk_fix_status(v)
    elif isinstance(obj, list):
        for v in obj:
            walk_fix_status(v)


def collect_log_ids(journal: dict) -> list[tuple[dict, str]]:
    """Список (log-attributes dict, id)."""
    out = []
    for session in journal.get("journal", {}).get("sessions", []):
        chat = session.get("chat") or {}
        for entry in chat.get("entries") or []:
            log = entry.get("log")
            if not log:
                continue
            attrs = log.get("log-attributes") or {}
            lid = attrs.get("id")
            if lid:
                out.append((log, lid))
    return out


def uniquify_log_ids(journal: dict) -> int:
    """Вторые и далее дубликаты получают суффикс -a, -b, … (Д4)."""
    seen: dict[str, int] = defaultdict(int)
    changed = 0
    for log, lid in collect_log_ids(journal):
        attrs = log["log-attributes"]
        n = seen[lid]
        seen[lid] = n + 1
        if n == 0:
            continue
        # суффикс: a, b, c…
        suffix = chr(ord("a") + n - 1) if n <= 26 else f"x{n}"
        new_id = f"{lid}-{suffix}"
        attrs["id"] = new_id
        dn = log.get("displayName") or ""
        if lid in dn:
            log["displayName"] = dn.replace(lid, new_id)
        changed += 1
    return changed


def sort_sessions(journal: dict) -> None:
    sessions = journal.get("journal", {}).get("sessions") or []

    def key(sess):
        chat = sess.get("chat") or {}
        attrs = chat.get("chat-attributes") or {}
        return attrs.get("created") or ""

    sessions.sort(key=key, reverse=True)
    journal["journal"]["sessions"] = sessions


def fix_chat_statuses(journal: dict) -> int:
    n = 0
    for session in journal.get("journal", {}).get("sessions", []):
        chat = session.get("chat") or {}
        attrs = chat.get("chat-attributes") or {}
        cid = attrs.get("id")
        # normalize
        old = attrs.get("status")
        ns = norm_status(old)
        if ns and ns != old and ns in ALLOWED:
            attrs["status"] = ns
            if chat.get("displayName"):
                chat["displayName"] = fix_display_status(chat["displayName"], ns)
            n += 1
        # explicit fixes for closed plans
        if cid in CHAT_STATUS_FIXES:
            target = CHAT_STATUS_FIXES[cid]
            if attrs.get("status") != target:
                attrs["status"] = target
                if chat.get("displayName"):
                    chat["displayName"] = fix_display_status(chat["displayName"], target)
                n += 1
        # heuristic: chatPlan points to completed plan file status in name "completed"
        # Also: if status is active/in_progress but displayName says completed — already handled

        # Broad Р-08: if links.chatPlan basename matches known completed plans from roadmap close
        cp = (attrs.get("links") or {}).get("chatPlan") or ""
        completed_plans = (
            "chat-plan-26-1019",
            "chat-plan-26-0922",
            "chat-plan-26-0921",
            "chat-plan-26-1012",
            "chat-plan-26-0819",
            "chat-plan-26-0725",
            "chat-plan-26-0722",
            "chat-plan-26-0720",
            "chat-plan-26-0707",
            "chat-plan-26-0508",
            "chat-plan-26-0323",
            "chat-plan-26-0911",
            "chat-plan-26-1117-c1",
            "chat-plan-26-1117-femsq-table",
        )
        if attrs.get("status") not in {"completed", "cancelled"} and any(p in cp for p in completed_plans):
            # don't auto-complete 0802 (paused R2) or 0918
            if "0802-sudz" in cp or "0918-sudz" in cp:
                if attrs.get("status") not in {"paused", "completed"}:
                    attrs["status"] = "paused"
                    if chat.get("displayName"):
                        chat["displayName"] = fix_display_status(chat["displayName"], "paused")
                    n += 1
            else:
                attrs["status"] = "completed"
                if chat.get("displayName"):
                    chat["displayName"] = fix_display_status(chat["displayName"], "completed")
                n += 1
    return n


def fix_tasks(dev: dict) -> tuple[int, set[str]]:
    items = dev["development"]["tasks"]["items"]
    n = 0
    all_ids = set(items.keys())
    for tid, wrap in items.items():
        task = wrap.get("task") or {}
        attrs = task.get("task-attributes") or {}
        old = attrs.get("status")
        ns = norm_status(old)
        if tid in TASK_STATUS_FIXES:
            target = TASK_STATUS_FIXES[tid]
            if attrs.get("status") != target:
                attrs["status"] = target
                if task.get("displayName"):
                    task["displayName"] = fix_display_status(task["displayName"], target)
                n += 1
        elif ns and ns != old and ns in ALLOWED:
            attrs["status"] = ns
            if task.get("displayName"):
                task["displayName"] = fix_display_status(task["displayName"], ns)
            n += 1
        # strip fragment-only uniqueness — keep path with # as informational OK for checker now
    return n, all_ids


def walk_tree_ids(items, found: set[str]) -> None:
    for wrap in items or []:
        ti = wrap.get("task-item")
        if not ti:
            continue
        tid = (ti.get("item-attributes") or {}).get("taskId")
        if tid:
            found.add(str(tid))
        walk_tree_ids(ti.get("task-items") or [], found)


def ensure_orphans_in_tree(dev: dict, all_ids: set[str]) -> int:
    in_trees: set[str] = set()
    trees = dev["development"]["structure"]["trees"]
    features = None
    for tw in trees:
        tree = tw.get("tree") or tw
        walk_tree_ids(tree.get("task-items") or [], in_trees)
        if (tree.get("tree-attributes") or {}).get("treeId") == "features":
            features = tree
    orphans = sorted(all_ids - in_trees)
    if not orphans or features is None:
        return 0

    # find 02.05
    parent_05 = None
    for wrap in features.get("task-items") or []:
        ti = wrap.get("task-item")
        if (ti.get("item-attributes") or {}).get("structureId") == "02.05":
            parent_05 = ti
            break
    if parent_05 is None:
        return 0

    # remove existing 02.05.99 if re-run
    children = parent_05.setdefault("task-items", [])
    children[:] = [
        c
        for c in children
        if (c.get("task-item", {}).get("item-attributes") or {}).get("structureId") != "02.05.99"
    ]

    orphan_items = []
    for i, tid in enumerate(orphans, start=1):
        orphan_items.append(
            {
                "task-item": {
                    "displayName": f"📦 Вне дерева (авто) → {tid}",
                    "item-attributes": {
                        "structureId": f"02.05.99.{i:02d}",
                        "taskId": tid,
                        "positionInParent": i,
                        "comment": "Авторазмещение docs-sync 6.3; перенести в тематическое дерево при удобстве",
                    },
                    "task-items": [],
                }
            }
        )

    children.append(
        {
            "task-item": {
                "displayName": f"📦 Задачи вне деревьев — авто (docs-sync 6.3). № 02.05.99 ({len(orphans)})",
                "item-attributes": {
                    "structureId": "02.05.99",
                    "taskId": None,
                    "positionInParent": 99,
                    "comment": "Временный контейнер сирот до ручной раскладки",
                },
                "task-items": orphan_items,
            }
        }
    )
    return len(orphans)


def main() -> None:
    journal = json.loads(JOURNAL.read_text(encoding="utf-8"))
    # 7.1 already backed up externally

    # normalize nested statuses in journal (log-attributes may use completed etc.)
    walk_fix_status(journal)
    dup = uniquify_log_ids(journal)
    chat_n = fix_chat_statuses(journal)
    sort_sessions(journal)
    journal["journal"]["metadata"]["lastUpdated"] = "2026-11-17"

    JOURNAL.write_text(json.dumps(journal, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"journal: log id suffixes={dup}, chat status fixes≈{chat_n}, sessions sorted")

    dev = json.loads(DEV.read_text(encoding="utf-8"))
    walk_fix_status(dev)
    task_n, all_ids = fix_tasks(dev)
    orphans = ensure_orphans_in_tree(dev, all_ids)
    # nextTaskId already 0094
    if "metadata" in dev.get("development", {}):
        dev["development"]["metadata"]["lastUpdated"] = "2026-11-17"
    DEV.write_text(json.dumps(dev, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"development: task status fixes={task_n}, orphans placed={orphans}")


if __name__ == "__main__":
    main()
