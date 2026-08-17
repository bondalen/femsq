# Access-local буфер загрузки свода (CnInvDbtUpl*) — съём 2026-08-11/12

**Чат:** «0069 Загрузка выгрузки. UI» · этап 1 плана §5.6 (S61c)  
**Метод:** `DumpTableDef_Extended` + `ExportTableCsvUtf8`

## Итог по пяти таблицам

| Таблица | Строк | PK | Persist | Артефакты |
|--------|------:|----|---------|-----------|
| `CnInvDbtUplFile` | 19 | `cidufKey` | да (1:1 upl) | dump, `.table.md`, `.data.csv` (логи отдельно) |
| `CnInvDbtUplFileSh` | 114 | `cidufsKey` | да (1:N File) | dump, csv, `.table.md` |
| `CnInvDbtUplTbl` | 1548 | нет | эфемерный | dump, csv, `.table.md` |
| `CnInvDbtUplTblCnInv` | 0 | нет | эфемерный | dump, `.table.md` |
| `CnInvDbtUplFileInvDouble` | 0 | `cidufiKey` | эфемерный (clear on load) | dump, `.table.md` |

## Связи (факт)

```text
ags.cn_inv_dbt_upl.upl_key
        ↑ логически cidufUpload (unique)
CnInvDbtUplFile.cidufKey
        ↓ Relation cidufKey → cidufsFile
CnInvDbtUplFileSh  (лист, account_key, проверять?)
        ↓ cidufsKey ≈ cidutSheet; cidufUpload ≈ cidutUnloadKey
CnInvDbtUplTbl  (строки Excel, перезапись)
        ↓ SQL воронки
CnInvDbtUplTblCnInv  (новые СФ)
CnInvDbtUplFileInvDouble  (очередь ручного разбора; cidufiCiduf → File)
```

## Следующий шаг (этап 2–4 §5.6)

Карта → решение имён/`sudz` DDL → apply DEV. UI после DDL.

**Вне scope дампа:** `*Old`, `CnInvPmtUpl*`.
