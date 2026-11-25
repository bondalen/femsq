# Недостающие `cstAgPn` с прода (C2 / O1 · G5 · prep §3.2.4)

**Дата:** 2026-11-25  
**Задача:** 0081  
**План:** [chat-plan-26-1120-c2-d11-ipg-plans.md](../../chats/chat-plan/chat-plan-26-1120-c2-d11-ipg-plans.md) §3.2.4  
**Сессия продОбмен:** `~/Downloads/продОбмен/26-1125_09-50/`  
**Стенд дыр:** `FishEye_prod_noM6` · load**8** / `sql_0.xlsx` · **92** кода

## Назначение

Readonly-выгрузка с **прода** строк `ags.cstAgPn` (+ родители `cstAg` / `cst` / `ogAg`) для кодов САК, которых нет на noM6, но которые нужны для bulk apply пунктов ИП A.

**На прод:** только чтение.  
**На DEV:** после возврата — точечный INSERT (отдельный шаг; не MERGE всей таблицы).

## Содержимое

| Файл | Назначение |
|------|------------|
| `MSSQL2012/00_COUNTS_readonly.sql` | identity + found/missing из 92 |
| `MSSQL2012/01c_EXPORT_sqlcmd_mode.sql` | SQLCMD Mode → `.tsv` |
| `MSSQL2012/missing_codes_load8.csv` | список 92 кодов (справка) |
| `open/` | копия для AES `в_Прод` |
| `from-prod/` | ответ оператора (в git не кладём) |

## Архив в_Прод

| Архив | Пароль |
|-------|--------|
| `26-1125_09-50_в_Прод_CSTAGPN_MISSING.zip` | пароль обмена продОбмен (AES-256) |

Рядом: `.sha256`.

## Порядок

1. Отправить zip с канала продОбмен.
2. SSMS → `SPB-05-NV-SQL1` / `FishEye`, Windows auth.
3. Выполнить `00` → сетки в Cursor / `RETURN_TEMPLATE`.
4. `01c` (SQLCMD Mode) → каталог `C:\Temp\femsq_cstagpn_missing_20261125\*.tsv`.
5. AES-ZIP каталога → `отПрод/` этой сессии.
6. На noM6: import (следующий шаг после получения).

**Запрещено:** DDL/DML на прод; BACKUP; выкладка JAR.

## Результат на noM6 (2026-11-25)

Импорт выполнен на `FishEye_prod_noM6` (DEV only):

| Таблица | Было на noM6 из 92-цепочки | Добавлено |
|--------|---------------------------:|----------:|
| `ogAg` | 9/9 | 0 |
| `cst` | 89/92 | **3** |
| `cstAg` | 68/92 | **24** |
| `cstAgPn` | 0/92 | **92** |

Сверка load8: **398/398** кодов находятся в `ags.cstAgPn` (`missing=0`).

Имена `cstapCstName*` / `cstapOgName` — computed; в INSERT не входят.
