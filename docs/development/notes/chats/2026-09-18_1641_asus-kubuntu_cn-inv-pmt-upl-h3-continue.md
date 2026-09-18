# Резюме / handoff: CnInvPmtUpl H3 apply закрыт — продолжение с H4

**Дата:** 2026-09-18 16:41 (+03)  
**От:** агент asus-kubuntu (чат 0819 / 0076 H3)  
**Кому:** новый чат Cursor — продолжить канон 1.1.1.2  
**Машина:** asus-kubuntu; SQL FishEye `10.7.0.3:1433`; SMB `/mnt/nb-win-share`; JAR **0.1.0.297**  

Дубликаты:

1. SMB-шара: `/mnt/nb-win-share/2026-09-18_1641_asus-kubuntu_cn-inv-pmt-upl-h3-continue.md`
2. Репозиторий: `docs/development/notes/chats/2026-09-18_1641_asus-kubuntu_cn-inv-pmt-upl-h3-continue.md`
3. Резюме: `docs/development/notes/chats/chat-resume/chat-resume-26-0918-cn-inv-pmt-upl-h3.md`

---

## Запрос для нового чата (скопировать в первое сообщение)

```
Продолжите FEMSQ CnInvPmtUpl (экран D / 1.1.1.2) по плану chat-plan-26-0819 §4.3.

Стоп-точка 2026-09-18: H3 apply (шаги 3/5/7/9/10/12) закрыт на pm=8 (export_767502), JAR 0.1.0.297.
Handoff: docs/development/notes/chats/2026-09-18_1641_asus-kubuntu_cn-inv-pmt-upl-h3-continue.md
План: docs/development/notes/chats/chat-plan/chat-plan-26-0819-cn-inv-pmt-upl.md §4.3

Следующий срез: H4 — apply воронки на остальных пакетах (pm 3/4/5/6; Tbl уже загружены), затем H5 g_p→902, H6 DbtUplCstAg, H7 Rslt.

Ограничения: UAT apply через UI браузера Cursor; ожидания ≤45 с (для InsPm apply на больших пакетах — до ~60 с на шаг); не смешивать с 0918 mailing / деревом B / S80 backfill, пока владелец не скажет иначе.
```

---

## Где стоим

| Срез §4.3 | Статус |
|-----------|--------|
| H0–H2 | ✅ |
| **H3** apply 3/5/7/9/10/12 | ✅ UAT UI pm=8 dry→apply→dry |
| **H4** 5 пакетов → apply → `cn_inv_pm` | ◐ Excel→Tbl ✅; apply только **pm=8** |
| H5 `g_p` ↔ 902 | ☐ |
| H6 `DbtUplCstAg` / fn | ☐ |
| H7 Rslt vs `26-0505` | ☐ |

**Решение A:** 5× `cn_inv_pm_upl` + File на каждый `export_*`.

### UAT pm=8 (export_767502_26-0422, 583 стр. Tbl)

| Шаг | dry → apply → dry |
|-----|-------------------|
| 3 CnNot | empty (уже было) |
| 5 AgNot | 115/114 → 114 → 1 left (BUIRG 15) |
| 7 InvNot | 2 → 2 (ci 96053/96054) → 0 |
| 9 AcNot | 2 → 2 (cias 103366/103367) → 0 |
| 10 DocNot | 127 → 127 → 0 |
| 12 InsPm | **303 → 303 → 0** (~50 с на apply-шаг; вся воронка ~60 с) |

JAR на момент закрытия: **`femsq-web-0.1.0.297-SNAPSHOT.jar`** (порт 8080).

### Пакеты на DEV (Tbl уже есть)

| pmKey | name | Tbl rows | H3 apply |
|-------|------|----------|----------|
| 3 | export_606012 | 4909 | ☐ |
| 4 | export_606022 | 721 | ☐ |
| 5 | export_761010 | 990 | ☐ |
| 6 | export_767501 | 7481 | ☐ |
| 8 | export_767502 | 583 | ✅ |

Пути Excel: `/mnt/nb-win-share/femsq/excel/2026_03/debit/export_*_26-0422.XLSX` (в File часто Windows `D:\wire-guard-share-nb-win\…`).

---

## Код (ориентиры)

- Runner: `SudzPmtUplFunnelRunner` — apply 3/5/7/9/10/12
- DAO: `JdbcSudzDao` — `sqlPmtUplInsPmNot` (inline ExtPm CTE + EXCEPT; без ExtPmTbl)
- Логи: `SudzPmtUpl*NotLoadLog`
- UI: префикс чекбоксов; Pinia `selectUpl(pmKey)` если FemsqTable не синхронизирует выбор
- flTbl=0 при funnel-only; flLoad=Обновлять для apply

---

## Не трогать без просьбы

- chat-plan-26-0918-sudz-rslt-prod-mailing (рассылка Rslt)
- S80 / QI vs Access backfill verify scripts
- Дерево B / feQuLib layout

---

## Следующие действия (рекомендуемый порядок)

1. **H4:** на pm=3 (или по одному) UI dry→apply→dry префикс до `cipuInsPmNotLoad`; таймауты UI 45–60 с; InsPm на 7k строк может быть долгим.
2. **H5:** связать pm_upl с dbt **902** через `g_p` (UI C и/или mutation).
3. **H6–H7:** канон строек / Rslt verify.

Проверка окружения в начале чата по `.cursorrules` (hostname, DBHub, SQL, mcp DSN).
