# Hotfix 0.1.0.156 — RALP reconcile: лимит 2100 параметров SQL Server

**Дата:** 2026-10-14  
**Сервер приложения:** prod FEMSQ (thin **0.1.0.155** → **0.1.0.156**)  
**БД:** SPB-05-NV-SQL1 / FishEye / SQL Server 2012 SP4  
**Ветка:** `hotfix/ralp-sql-2100-params-156` (база `1b4bd4b` = 155 / 0054.9)  
**Симптом:** ревизия type=3 FAILED на сверке: `errorCode=8003`,  
`The incoming request has too many parameters. The server supports a maximum of 2100 parameters.`  
**Факт на проде:** `SELECT COUNT(*) FROM ags.ralpRa WHERE ralprY = 2026` → **2292**  
**Excel:** `(2026)_Аренда_рабочий.xlsx` (снимок `/mnt/nb-win-share/femsq/excel/2026-1014/`)

### Краткий порядок для оператора

1. Бэкап `ralpRa`/`ralpRaAu` за 2026 (SSMS).  
2. Stop FEMSQ (ярлык остановки **155** подходит, если он гасит процесс, а не ищет имя JAR).  
3. Заменить thin **156** + `lib/femsq-database`/`femsq-reports` **156**.  
4. Скопировать `desktop\*.bat` в каталог приложения и запустить `Создать-ярлыки-на-рабочем-столе.bat`. Дальше — ярлык **FEMSQ запуск 156**. Ярлык на **155** оставить для отката.  
5. Dry-run type=3, **AddRA=off** → COMPLETED, без 8003.  
6. Apply type=3, **AddRA=on** → VERIFY → **снять AddRA**.  
7. При проблеме: вернуть файлы **155** и ярлык запуска на 155; домен — из bak шага 1.

### Ярлыки

Готовые скрипты — в пакете, каталог `desktop\` (кодировка Windows-1251):

| Файл | Назначение |
|------|------------|
| `FEMSQ-запуск-156.bat` | Запуск thin **156**, Java `jdk-23.0.1` (не PATH) |
| `FEMSQ-остановка.bat` | Остановка `java.exe` с `femsq-web` + `JarLauncher` |
| `Создать-ярлыки-на-рабочем-столе.bat` | Кладёт на рабочий стол `FEMSQ запуск 156.lnk` и `FEMSQ остановка.lnk` |

Порядок: скопировать три bat **в каталог приложения** (рядом с thin JAR) → двойной щелчок по `Создать-ярлыки-на-рабочем-столе.bat`. Ярлыки `.lnk` с абсолютным путём прода заранее не собираются: путь каталога на сервере известен только там.

Старый ярлык запуска **155** не удалять до приёмки.

Пакет: `/home/alex/femsq-test/to_prod_26-1014_ralp156/` (см. ниже).

## Суть фикса

В `RalpReconcileService` (только `femsq-web`):

1. `loadDomainRaAu` — вместо `WHERE ralpraRa IN (?×N)` → `JOIN ags.ralpRa` по `ralprY = ?` (1 параметр).
2. `deleteByKeys` / `loadRaNums` — чанки по **500** ключей (`BULK_IN_CHUNK`).
3. `updateStagingRefs` — `executeBatch` каждые 500 строк.

**Без DDL.** SQL-артефакты на сервере БД не меняются.

Тот же код интегрирован в текущую линию main (347+), чтобы баг не вернулся при полном деплое.

## Почему не «текущий» thin с main

На проде стоит **155**. Main уже **347** с СУДЗ и др. Положить 347 thin на `lib/` от 155 — высокий риск обвала. Hotfix собран **от базы 155** + один класс.

## Состав пакета на прод

| Артефакт | Нужен? | Примечание |
|----------|--------|------------|
| `femsq-web-0.1.0.156-SNAPSHOT-thin.jar` | **да** | замена thin 155 |
| `femsq-database-0.1.0.156-SNAPSHOT.jar` | **да*** | в `lib/` рядом с thin; та же версия (checker) |
| `femsq-reports-0.1.0.156-SNAPSHOT.jar` | **да*** | то же |
| Полный `lib/` (Spring, POI, JDBC…) | **нет** | не трогать |
| SQL DDL | **нет** | — |

\* Версии `femsq-*` в `lib/` должны совпадать с thin (как при 153→154→155). Содержимое database/reports от 155 **не менялось** логикой фикса — только номер версии при сборке монорепо.

Архив JAR: `/home/alex/Downloads/продОбмен/26-1015_09-30/в_Прод/26-1014_ralp156.zip`.  
Архив SQL: `…/в_Прод/26-1015_ralp156-sql.zip` (`MSSQL2012/01` бэкап, `02` сверка, `03` откат; августовские bak не трогает).  
Оба AES-256, пароль как у пакетов RALP 04.08: `au#LL891`.

---

## Порядок внедрения на прод

### 0. Pre-flight (до Stop)

1. Убедиться: на приложении thin **155**, Java 23, `lib/` целый.
2. На БД FishEye:
   ```sql
   SELECT COUNT(*) AS ralpRa_2026 FROM ags.ralpRa WHERE ralprY = 2026;
   -- ожидаемо ≥ 2101 (факт 2026-10-14: 2292)
   ```
3. Скопировать пакет 156 на сервер приложения (рядом с текущим каталогом деплоя), **не** перекрывая running files до Stop.
4. Сделать копию текущего thin 155 и двух `femsq-*` 155 (откат файлов).

### 1. Бэкап домена RALP (SSMS, год 2026)

По аналогии с `docs/development/notes/sql/26-0804-0054-ralp-apply-rollback/MSSQL2012/01_BACKUP_before_apply.sql`  
(или свежий скрипт с суффиксом `_bak_20261014`): таблицы `ags.ralpRa` / `ags.ralpRaAu` за `ralprY = 2026`.

Не запускать apply, пока бэкап не подтверждён (`COUNT` bak ≈ 2292).

### 2. Stop → замена артефактов → Start

1. Остановить FEMSQ существующим ярлыком остановки (или `stop` script).
2. Заменить:
   - thin `…155…-thin.jar` → `femsq-web-0.1.0.156-SNAPSHOT-thin.jar`
   - в `lib/`: `femsq-database` и `femsq-reports` **155 → 156**
3. Запуск **новым** ярлыком/скриптом: первый аргумент `femsq-web-0.1.0.156-SNAPSHOT-thin.jar`, Java **`jdk-23.0.1`** (как у 155). Ярлык на файл 155 оставить для отката.
4. Health / status OK; в логе старта — версия **0.1.0.156**, без `Version mismatch` по `femsq-*`.

### 3. Dry-run type=3 (AddRA = выкл)

UI: ревизия 2026, файл аренды, **только type=3**, SUMMARY, **AddRA=false**.

Ожидание:

- Stage 1: ~2292 строк в промежуточную RALP (как на скрине 14.10).
- Сверка: **COMPLETED**, **нет** `errorCode=8003` / «too many parameters».
- В логе: домен загружен (`ralpRa≈2292`), счётчики dry-run без падения.

При FAILED с 8003 — **не** включать AddRA; откатить thin/lib на 155.

### 4. Apply type=3 (AddRA = вкл) — только после успешного dry-run

1. AddRA=true, тот же файл / type=3, SUMMARY.
2. Дождаться COMPLETED.
3. VERIFY на БД (счётчики vs bak), по аналогии с `02_VERIFY_after_apply.sql`.
4. **Снять AddRA** в UI.

Ожидание: идемпотентность на повторном dry-run (unchanged ≈ объём года, deleted 0 или осознанные orphan по политике).

### 5. Откат

| Уровень | Действие |
|---------|----------|
| Только приложение | Stop → вернуть thin+`femsq-*` **155** → Start |
| Домен после apply | `03_ROLLBACK_from_bak` из бэкапа шага 1 (не путать с мартовским Docker-trim) |

---

## Готовый пакет (собрано 2026-10-14)

Каталог (вне git): `/home/alex/femsq-test/to_prod_26-1014_ralp156/`

| Файл | Назначение |
|------|------------|
| `femsq-web-0.1.0.156-SNAPSHOT-thin.jar` | thin → корень деплоя |
| `lib-updates/femsq-database-0.1.0.156-SNAPSHOT.jar` | в `lib/` |
| `lib-updates/femsq-reports-0.1.0.156-SNAPSHOT.jar` | в `lib/` |
| `desktop/FEMSQ-запуск-156.bat` | в каталог приложения |
| `desktop/FEMSQ-остановка.bat` | в каталог приложения |
| `desktop/Создать-ярлыки-на-рабочем-столе.bat` | один раз на сервере → ярлыки рабочего стола |
| `SHA256SUMS.txt` | контроль целостности |

Сборка: worktree `femsq-hotfix-ralp-156`, ветка `hotfix/ralp-sql-2100-params-156`,  
`mvn package -Dmaven.test.skip=true -Dexec.skip=true` (precompile reports на базе 155 падает — `exec.skip`), затем thin без `BOOT-INF/lib`.

Unit: `RalpReconcileServiceTest.partitionForInClause_splitsAboveSqlServerLimit` (2292 → 5 чанков по 500).

## Связь с main (347+)

Тот же diff в `RalpReconcileService` / тест на **main** — обязателен до следующего полного деплоя.  
Не деплоить main 347 на прод вместо 156.

## Критерий приёмки

- [x] thin 156 + `femsq-*` 156 на prod, health OK (15.10.2026)
- [x] dry-run type=3 COMPLETED при `ralpRa_2026` = 2292
- [x] нет 8003 в логе сверки
- [x] apply + VERIFY: изменено строк = 161 (обновления существующих Au), ra/au без прироста; AddRA снят
- [x] фикс есть в main (не только в hotfix-ветке)
