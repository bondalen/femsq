# Резюме / handoff: 0076 закрыт — продолжение на asus-kubuntu

**Дата:** 2026-09-20 22:57 (+03)  
**От:** агент nb-win (чат 0819 / 0076 H7 C')  
**Кому:** новый чат Cursor на **asus-kubuntu**  
**Машина сейчас:** nb-win (WSL2); SQL FishEye Docker `femsq-mssql`; JAR **0.1.0.304**; SMB `D:\wire-guard-share-nb-win` → `/mnt/d/wire-guard-share-nb-win`

Дубликаты:

1. SMB-шара: `/mnt/d/wire-guard-share-nb-win/2026-09-20_2257_nb-win_to_asus-kubuntu_0076-closed-continue.md`  
   (на asus: обычно `/mnt/nb-win-share/2026-09-20_2257_nb-win_to_asus-kubuntu_0076-closed-continue.md`)
2. Репозиторий: `docs/development/notes/chats/2026-09-20_2257_nb-win_to_asus-kubuntu_0076-closed-continue.md`

---

## Запрос для нового чата (скопировать в первое сообщение)

```
Продолжите FEMSQ на asus-kubuntu после закрытия канона CnInvPmtUpl 1.1.1.2.

Стоп-точка 2026-09-20 (nb-win): задача 0076 и план chat-plan-26-0819 §0a закрыты; H7 FAIL=0 vs Access 26-0505; JAR 0.1.0.304.
Handoff: docs/development/notes/chats/2026-09-20_2257_nb-win_to_asus-kubuntu_0076-closed-continue.md
План закрыт: docs/development/notes/chats/chat-plan/chat-plan-26-0819-cn-inv-pmt-upl.md
Журнал: chat-2026-09-18-001 completed; log-2026-09-20-002

Сначала: git pull; проверка окружения (машина asus-kubuntu, DBHub, SQL 10.7.0.3:1433, SMB); сопоставление с project-docs.json.
Затем спросите владельца следующий приоритет (кандидаты ниже). Не открывать заново 0076 / S80 backfill без запроса.

Кандидаты: карта 0802 (0071 / 1.1.1.3); 0075 шаг 2 UI gate погашений (later); план 0819 §4 этапы 3–4 (вкладка g_p на C, КСДСФ) — только если владелец скажет.
```

---

## Что закрыто

| Критерий §0a | Итог |
|--------------|------|
| 1 Apply 5× export → `cn_inv_pm` | ✅ H4 |
| 2 `g_p` → 902 | ✅ H5 |
| 3 `DbtUplCstAg` fn+g_p | ✅ H6 + C' |
| 4 Rslt QI ↔ `26-0505` стройки | ✅ H7 FAIL=**0** |
| 5 План + журнал + 0076 | ✅ 2026-09-20 |

**H7 C' (корневой фикс):** `invDbtCia.idcCia` → `cnInvAccnt` → smpl → pm (не `idcCia` как ciasKey); `raw_doc` + link при `LEN(dvDocBase)≥8`.  
Rebuild: `docs/development/notes/sql/26-0920-sudz-pm-upl-key-decollide/03_REBUILD_DbtUplCstAg_902_cia_link.sql` → **1580** @902.  
Verify: `…/artifacts/h7_s80_qiv_qi_vs_access_fixC_26-0920-1348.json` (gitignore artifacts — на nb-win локально).

**QI pm keys:** apply на **47–51** (не 3–8); `g_p`@902 на эти ключи.

---

## Состояние DEV для asus-kubuntu

| | |
|--|--|
| Git | `main` — после pull должен быть коммит закрытия 0076 / H7 C' |
| SQL | FishEye на nb-win WG `10.7.0.3:1433` (канон после decommission cr-ubu) |
| Excel SMB | `//10.7.0.3/wire-guard-share-nb-win` → `/mnt/nb-win-share` |
| Эталон Rslt | `…/femsq/excel/2026_03/debit/ags_Yr_DbtChangesRslt_26-0505.xlsx` |
| JAR на nb-win | `0.1.0.304-SNAPSHOT` :8080 (на asus — собрать/запустить свой) |

### Чеклист старта на asus-kubuntu

1. `git pull origin main` в `/home/alex/projects/femsq` (и feQuLib при сборке frontend).
2. Проверка окружения по `.cursorrules` → машина `asus-kubuntu`, DBHub, порт SQL.
3. SMB: mount nb-win share; прочитать этот handoff с шары.
4. Не пересобирать H7 / не трогать `DbtUplCstAg`@902 без нужды — канон уже сверен.
5. Спросить владельца: что дальше.

---

## Вне scope (не делать «по инерции»)

- Повторный Excel-бэкфилл S80 вместо fn+g_p  
- Дерево mailing **0918**  
- Прод / D644  
- Этапы 0819 §4 **3–4** без явного запроса  

---

**Автор handoff:** агент nb-win · 2026-09-20
