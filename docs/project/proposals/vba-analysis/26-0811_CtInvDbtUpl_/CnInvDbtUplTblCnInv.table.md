# Таблица Access: `CnInvDbtUplTblCnInv`

**Статус:** структура снята (2026-08-12). **Данных в снимке нет** (`RecordCount=0`) — CSV не требуется.  
**Источник:** [`CnInvDbtUplTblCnInv.dump.utf8.txt`](./CnInvDbtUplTblCnInv.dump.utf8.txt)  
**Тип:** локальная Access; промежуточный буфер воронки (новые СФ для уже найденных договоров).  
**LastUpdated TableDef:** 12.01.2022 (давно не менялась метаданными).  
**PK / индексы / Relations:** нет.

## Назначение

Наполняется сохранённым SQL (`SqlLong` / `SqlCnCtptExistInvNot`) перед вставкой в `ags.inv` / `invNum` / `cnInv`. В текущем снимке после загрузки upl=26 буфер пуст (все СФ уже сопоставлены или шаг не оставлял хвост).

## Поля

| Поле | DAO | Size | Примечание |
|------|-----|------|------------|
| `cidutciCnName` | dbText | 255 | номер договора (текст) |
| `cidutciCn_key` | dbLong | 4 | ключ договора `cn` |
| `cidutciCnInv` | dbText | 255 | текст СФ из свода |
| `cidutciCiKey` | dbLong | 4 | ключ `cnInv` (после создания?) |
| `inNumCount` | dbLong | 4 | число номеров СФ (агрегат в SQL) |

Поля `cidutciCntrPrt*` / `cidutciCnDate` из закомментированного SQL в `SqlLong.bas` в **текущем** TableDef **отсутствуют** (схема упростилась с 2022).

## Для FEMSQ / SQL

- Нужна как staging воронки (часто пустая между прогонами).
- CSV снимка нечего снимать; при UAT воронки — выгрузить после dry-run с «новыми» СФ.

**lastUpdated:** 2026-08-12
