# Access: таблицы и запросы (артефакты для репозитория)

**Назначение:** в этой папке — по одному файлу на **каждую задокументированную** локальную таблицу и **каждый сохранённый запрос** MS Access, плюс общие модули VBA для снятия метаданных.

**lastUpdated:** 2026-03-23

---

## Именование и учёт количества объектов

| Шаблон имени | Один файл = | Пример |
|--------------|-------------|--------|
| **`{ИмяТаблицы}.table.md`** | одна **таблица** | `ra_ImpNew.table.md` |
| **`{ИмяЗапроса}.access.sql`** | один **запрос** (QueryDef) | `ra_ImpNewQuRa.access.sql` |
| **`DumpTableDef_*.bas`** | общий **модуль** (не считается в «число таблиц») | `DumpTableDef_RaImpNew.bas` |
| **`{ИмяТаблицы}.dump.utf8.txt`** | опционально: полный текстовый дамп DAO | `ra_ImpNew.dump.utf8.txt` |

**Практическое правило:** число файлов `*.table.md` ≈ число описанных таблиц; число `*.access.sql` ≈ число вынесенных в репозиторий запросов. Всё содержание по одной таблице (типы полей, Caption/Description, индексы, подводные камни) держим **в одном** `{Имя}.table.md` — без отдельных «справочников подписей».

**SQL Server objects (`ags.*`)**: как правило, **не оформляем** отдельными `*.access.sql` (это не named Access QueryDef и/или SQL server logic). Для проверки структуры и содержания при необходимости используем DBHub (метаданные/`TOP N`), а в документации оставляем ссылки в `chat-plan`/в примечаниях к таблицам Access.

Порядок работы при снятии сведений и передаче ассистенту: **[MS-ACCESS-OBJECTS-CAPTURE.md](../MS-ACCESS-OBJECTS-CAPTURE.md)**.

---

## Текущий состав (по мере наполнения)

| Таблицы (`*.table.md`) | Запросы (`*.access.sql`) |
|-------------------------|---------------------------|
| `ra_ImpNew.table.md`, `cn_PrDocImp.table.md`, `ralpRaAuTest.table.md`, `ralpRaSumTest.table.md`, `ags_ogAgFeePnTest.table.md`, `ogAgFeePnTest.table.md` | `ra_ImpNewQu.access.sql`, `ra_ImpNewQuRa.access.sql`, `ra_ImpNewQuRc.access.sql`, `ags_PdSdRRcList.access.sql`, `cn_PrDocImp_Compare.access.sql`, `cn_PrDocImp_Cn.access.sql`, `cn_PrDocImp_CnInv.access.sql`, `cn_PrDocImp_CnInvNt.access.sql`, `cn_PrDocImp_CnInvEx.access.sql`, `cn_PrDocImp_CnInvExCsosEx.access.sql`, `cn_PrDocImp_CnInvExCsosNt.access.sql`, `cn_PrDocImp_CnInvExCsosExPdEx.access.sql`, `cn_PrDocImp_CnInvExCsosExPdNt.access.sql`, `cn_PrDocImp_CnInvExCsosExPdExPnEx.access.sql`, `cn_PrDocImp_CnInvExCsosExPdExPnNt.access.sql`, `cn_PrDocImp_CnInvExCsosExPdExPnNtOneAccDoc.access.sql`, `cn_PrDocImp_CnInvExCsosExPdExPnNtIn.access.sql`, `cn_PrDocImp_CnInvExCsosExPdExPnExRs.access.sql`, `ralpRaAuTestQuRa.access.sql`, `ralpRaAuTestQuAu.access.sql` |

Примечание по Type 5 (`ra_ImpNewQuRa` / `ra_ImpNewQuRc`): политика сумм зафиксирована как версия-эволюция `1:N` — новая запись в `ags.ra_summ` / `ags.ra_change_summ` добавляется только при отличии от latest, при равенстве пропускается.
