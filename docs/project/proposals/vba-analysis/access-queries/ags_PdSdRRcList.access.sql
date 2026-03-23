/*
 * Объект MS Access: сохранённый запрос ags_PdSdRRcList
 *
 * Назначение: **не фиксированный** SELECT, а общий `QueryDef`, в который VBA подставляет
 * текст SQL перед `OpenRecordset` (выполнение на связанном SQL Server, схема `ags`).
 * Один и тот же объект переиспользуется под разные запросы — смотреть присвоения `.SQL`.
 *
 * Где в коде:
 * - `Module1.bas`: `FindOneKey` (`StringFindSv`), `FindCstAP` — строка вида
 *   `select * from ags.cstAgPn where cstapIpgPnN = '<код>'`;
 * - `Form_ra_a.cls`: тип ПД — `select pdtoKey from ags.cn_PrDocT where pdtoCode = '...'`;
 *   агент — `select * from ags.ogNmF_allVariantsAg where ogNm like '...' and ogaCode = '...'`;
 *   акт — `select * from ags.ogAgFee where oafNum = '...' and ...` (`FindAct`);
 *   свод РР — длинный `sqlStr` с `ags.RRcList` и др. (около строки 7378).
 *
 * Дамп `ags_PdSdRRcList.txt` содержал:
 * 1) пример тела: `SELECT * FROM ags.cstAgPn WHERE cstapIpgPnN = '051-2006733'`;
 * 2) строку ODBC (`ODBC;DSN=FishEye;...`) — это **свойства подключения** linked query, не часть SQL.
 *
 * Диалект: T-SQL / pass-through к MS SQL Server (в Access задаётся как текст `QueryDef.SQL`).
 * Файл в репозитории **не предназначен** для прямого выполнения на сервере без правки параметров.
 *
 * Источник: ags_PdSdRRcList.txt (снято из Access).
 *
 * lastUpdated: 2026-03-19
 */

/* -------------------------------------------------------------------------
 * Пример снимка из Access (литерал из дампа; в проде подставляется из VBA):
 *
 *   SELECT *
 *   FROM ags.cstAgPn
 *   WHERE cstapIpgPnN = '051-2006733';
 *
 * Другие типичные шаблоны (иллюстрация, параметры заменяются в коде):
 *
 *   SELECT pdtoKey FROM ags.cn_PrDocT WHERE pdtoCode = '<код_типа_ПД>';
 *
 *   SELECT * FROM ags.ogNmF_allVariantsAg
 *   WHERE ogNm LIKE '<...>' AND ogaCode = '<...>';
 *
 *   SELECT * FROM ags.ogAgFee
 *   WHERE oafNum = '<...>' AND oafDate = '<...>' AND cstaAg = <agKey>
 *     AND oafY = <год> AND oafM = <месяц>;
 * ------------------------------------------------------------------------- */
