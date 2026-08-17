# Таблица Access: `CnInvDbtUplFileInvDouble`

**Статус:** структура снята (2026-08-12). **Данных нет** (`RecordCount=0`) — CSV не нужен.  
**Источник:** [`CnInvDbtUplFileInvDouble.dump.utf8.txt`](./CnInvDbtUplFileInvDouble.dump.utf8.txt)  
**Тип:** локальная Access; очередь ручного разбора «повторяющихся СФ» (подформа InvDouble).  
**Очищается** в начале `btnCidufLoad` (`TableRecordsClear`).  
**PK:** `cidufiKey` (Autoincrement). Relations в дампе нет (логический FK `cidufiCiduf` → File).

## Поля

| Поле | DAO | Size | Description |
|------|-----|------|-------------|
| `cidufiKey` | dbLong, PK, AutoInc | 4 | ключ повторяющегося счёта-фактуры |
| `cidufiCiduf` | dbLong | 4 | ключ файла выгрузки (`cidufKey`) |
| `cidufiCnNnn` | dbLong | 4 | порядковый номер договора |
| `cidufiCnNum` | dbText | 255 | номер договора |
| `cidufiCnKey` | dbLong | 4 | ключ договора |
| `cidufiInvNnn` | dbLong | 4 | порядковый номер СФ у договора |
| `cidufiInvNum` | dbText | 255 | номер счёта-фактуры |
| `cidufiInvNumCount` | dbText | 255 | сколько раз встречался ранее (! тип Text, не Long) |

## Для FEMSQ / SQL

- Не путать с VIEW `ags.cn_inv_dbt_double`.
- Staging очереди неоднозначностей; часто пуста после успешной загрузки.
- `cidufiInvNumCount` как `nvarchar` или `int` — уточнить по VBA при переносе.

**lastUpdated:** 2026-08-12
