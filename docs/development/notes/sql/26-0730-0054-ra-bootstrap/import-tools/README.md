# 0054.4 — VBA → INSERT *.sql → dry-run на Docker → prod

## 1. На Access (prod `.accdb`)

1. Alt+F11 → Insert → Module → вставить `mod_0054_4_ExportRaSql.bas`
2. Immediate (`Ctrl+G`):
   ```vb
   ExportAllRaSql "C:\Temp\femsq_0054_import"
   ```
3. В папке появятся `00_RUN_ORDER.txt`, `01_ra_at.sql` … `08_ra_f.sql`
4. Заархивировать папку (AES zip, пароль `au#LL891`) и вернуть на Fedora

**Не** перелинковывать `ra_a`.

## 2. Проверка здесь (Docker `10.7.0.3`, без порчи UAT)

Не применять сырые INSERT в `ags.ra_*` на Docker (там уже есть ключи UAT, в т.ч. `adt_key=14`).

Скрипт dry-run: `MSSQL2012/dry-run/10_SHADOW_load_and_verify.sql`  
(агент прогонит после получения zip: создаст `ags_i_*` shadow-таблицы → загрузит → сверит counts/PK → DROP).

Критерии OK dry-run:
- все файлы парсятся без синтаксических ошибок;
- counts shadow = counts Access (из PRINT / числа INSERT);
- нет дублей PK;
- FK-порядок соблюдён (`dir`/`at`/`ft` до `ra_a`/`ra_f`).

## 3. Prod (`SPB-05-NV-SQL1`)

После успешного dry-run — те же `01`…`08` в SSMS на FishEye (таблицы пустые кроме seed `ra_at`/`ra_ft` — для них upsert).

Пути `ra_dir.dir`: при необходимости отдельный UPDATE под путь, читаемый FEMSQ.
