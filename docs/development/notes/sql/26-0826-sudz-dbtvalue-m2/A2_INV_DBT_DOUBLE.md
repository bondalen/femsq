# A2 — экран двоящих долгов СФ (messages v1, 2026-08-26)

**JAR:** `0.1.0.222-SNAPSHOT`  
**Сегм. 20 / 21**

## Hotfix + Create var (ранее)

- `loadLauncher` / `selectUpl`; Create var для ambiguous.
- Smoke var: `ciud=1800` → var **10134** → slot **10131**.

## A2-messages v1

Универсальная панель **«Сообщения»** под Excel (текстовый канал по строке очереди).

| Артефакт | Содержание |
|----------|------------|
| DDL | `ciudReasonDetail nvarchar(max)` — пакет `26-0826-sudz-inv-dbt-double-messages/` |
| Rebuild | блок `[queue.build]` со всеми сработавшими OR-критериями; DELETE только `open`; refresh detail у `created`/`deferred` |
| UI | `SudzInvDbtDoubleView` — `<pre>` под Excel-кандидатом |

Формат v1:

```text
[queue.build]
reason=multi|ambiguous
• ambiguous_fk: cnn|invNum|cnn+invNum
• multi_ctx: contexts=N
• hist_invDbt: slots=N
• hist_named_cia: named=N
• hist_cid: multi_upl=N
• current_tbl: excel_rows=N
```

(только сработавшие строки).

## Smoke (upl 910, `invDbtLoad` flLoad=false)

- inserted open **131**, detailRefresh **133** (включая created).
- `iKey=329` (created):  
  `hist_named_cia: named=2` + `hist_cid: multi_upl=2`.
- ambiguous sample: `ambiguous_fk: cnn`.

## Остаток

- Live-блоки в ту же панель (`[row.select]` …).
- `ciaName` в old sums; defer/bulk.
- **B2** / **B3**.
