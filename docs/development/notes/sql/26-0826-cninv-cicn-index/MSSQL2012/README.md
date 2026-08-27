# MSSQL2012 — индекс `ags.cnInv(ciCn)`

Синтаксис SQL Server 2012: без `DROP IF EXISTS` / без `CREATE OR ALTER`.  
Перед CREATE — проверка через `sys.indexes` (как в корневом `01_`, совместимо с 2012).

Применение на prod: только эта папка, после бэкапа (см. `sql-server-deployment-rules.md`).
