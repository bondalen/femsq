# Эталон структуры ИПГ с прода (C2 / D1.1 §2.0d)

**Дата:** 2026-11-20  
**Задача:** 0081  
**План:** [chat-plan-26-1120-c2-d11-ipg-plans.md](../../chats/chat-plan/chat-plan-26-1120-c2-d11-ipg-plans.md) §2.0c–2.0d  
**Сессия продОбмен:** `~/Downloads/продОбмен/26-1120_14-45/`  
**Статус:** ✅ получено и размещено

## Назначение

Readonly-выгрузка с **прода** таблиц DAG структуры ИПГ / затрат и привязок ИП→пункты.  
На DEV (**не** MERGE): эталон для проверки UI при тестовых внесениях.

## Данные (отПрод)

| | |
|--|--|
| Архив | `отПрод/femsq_ipg_st_etalon_20261120.zip` |
| SHA-256 | `2224e7b14a8511262f01c0f04f1eeee3179009f68611c3aaaef318b2e15942c7` |
| Шара (данные `.tsv`) | `/mnt/nb-win-share/femsq/excel/2026-1120/ipg-st-etalon-prod/` |
| Git | только скрипты/`open`/`README`; **`from-prod/tsv/` в репо не кладём** (лёгкий GitHub) |
| Способ | SSMS SQLCMD Mode (`01c_EXPORT_sqlcmd_mode.sql`) |

**Формат sqlcmd:** UTF-8 BOM; строка заголовка; строка `---`; данные с пробельным выравниванием (**не** TAB). В `ipgPn.ipgpTskCms` бывают переносы строк → `wc -l` больше COUNT; уникальные `ipgpKey` = **13222** (= сетка 00).

### Сверка с 00_COUNTS (14:56)

| Таблица | COUNT | Уник. ключи / строки данных |
|--------|------:|----------------------------:|
| stType | 2 | ✅ |
| st | 180 | ✅ |
| stIpg | 91 | ✅ |
| stIpgNm | 93 | ✅ |
| stCost | 89 | ✅ |
| stCostNm | 158 | ✅ |
| stRel | 180 | ✅ |
| stNet | 5 | ✅ |
| stNetPn | 380 | ✅ |
| ipg | 24 | ✅ |
| ipgCh | 19 | ✅ |
| ipgPn | 13222 | ✅ 13222 ключей (файл длиннее из‑за `\n` в тексте) |
| ipgStPn | 11501 | ✅ |
| ipgSh | 4 | ✅ |
| stIpgOutLimPn_2606 | 9 | ✅ |

## Скрипты пакета

| Файл | Назначение |
|------|------------|
| `MSSQL2012/00_COUNTS_readonly.sql` | Счётчики и обзор |
| `MSSQL2012/01c_EXPORT_sqlcmd_mode.sql` | **Основная** выгрузка (SSMS SQLCMD Mode) |
| `MSSQL2012/01_EXPORT_bcp.cmd` | Запасной BCP |
| `MSSQL2012/01b_EXPORT_powershell.ps1` | Запасной SqlClient |
| `MSSQL2012/02_SCHEMA_columns_readonly.sql` | Метаданные колонок |
| `open/` | Копия для AES `в_Прод` |

## Архивы в_Прод

| Архив | SHA-256 |
|-------|---------|
| `26-1120_14-45_в_Прод_IPG_ST_ETALON.zip` | `311105c3019f2f27282657309b0167581619d15530f21b0cad4cf6bb01ce9a5d` |
| `26-1120_15-31_в_Прод_IPG_ST_ETALON_SQLCMD.zip` | `45aa48f848d1f65953b25027d6da75965586fd95501d5be3719480cf7ebc0f18` |
