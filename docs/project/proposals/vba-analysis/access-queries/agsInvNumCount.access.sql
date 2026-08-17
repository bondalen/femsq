/*
 * Объект MS Access: сохранённый запрос agsInvNumCount
 *
 * Назначение: сколько различных inv приходится на один нормализованный номер СФ
 * (inNumNull). Используется в логе CnInvConcat / очереди InvDouble.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник: снято из Access (чат 2026-08-15).
 *
 * lastUpdated: 2026-08-15
 */

SELECT
    z.inNumNull,
    Count(z.inInv) AS inNumCount
FROM (
    SELECT
        inum.inNumNull,
        inum.inInv
    FROM ags_invNum AS inum
    GROUP BY
        inum.inNumNull,
        inum.inInv
) AS z
GROUP BY
    z.inNumNull;
