/*
 * Объект MS Access: сохранённый запрос cn_PrDocImp_CnInvEx
 *
 * Назначение: по строкам cn_PrDocImp с заполненным cn_key — группировка по ключу договора,
 * «Null-safe» номерам/дате СФ (cnpdCnNumNull, cnpdCnInvNumNull, cnpdCnInvDateNull);
 * LEFT JOIN к ags_cnInv / ags_inv / ags_invNum (подзапрос y) по дате, номеру СФ и cn_key = ciCn;
 * затем LEFT JOIN ags_invNum по x.CnInvNum = ags_invNum.inNum и Count(inKey) AS inKeyCount.
 * Итог фильтруется HAVING ciKey Is Not Null.
 *
 * Связь: типичное звено цепочки cn_PrDocImp_CnInv* (рядом в навигаторе — CnInvExCsosNt и др.).
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник текста: cn_PrDocImp_CnInvEx.txt (снято из Access).
 *
 * lastUpdated: 2026-03-21
 */

SELECT
    x.cn_key,
    x.CnNum,
    x.CnInvNum,
    x.CnInvDate,
    x.ciKey,
    Count(ags_invNum.inKey) AS inKeyCount
FROM (
    SELECT
        z.cn_key,
        z.CnNum,
        z.CnInvNum,
        z.CnInvDate,
        y.ciKey
    FROM (
        SELECT
            i.cn_key,
            i.cnpdCnNumNull AS CnNum,
            i.cnpdCnInvNumNull AS CnInvNum,
            i.cnpdCnInvDateNull AS CnInvDate
        FROM cn_PrDocImp AS i
        WHERE (((i.cn_key) Is Not Null))
        GROUP BY
            i.cn_key,
            i.cnpdCnNumNull,
            i.cnpdCnInvNumNull,
            i.cnpdCnInvDateNull
    ) AS z
        LEFT JOIN (
            SELECT
                ci.ciKey,
                ci.ciCn,
                i.iDateNull,
                n.inNumNull
            FROM (ags_cnInv AS ci INNER JOIN ags_inv AS i ON ci.ciInv = i.iKey)
                INNER JOIN ags_invNum AS n
                    ON i.iKey = n.inInv
        ) AS y
            ON (z.CnInvDate = y.iDateNull)
            AND (z.CnInvNum = y.inNumNull)
            AND (z.cn_key = y.ciCn)
    GROUP BY
        z.cn_key,
        z.CnNum,
        z.CnInvNum,
        z.CnInvDate,
        y.ciKey
) AS x
    LEFT JOIN ags_invNum
        ON x.CnInvNum = ags_invNum.inNum
GROUP BY
    x.cn_key,
    x.CnNum,
    x.CnInvNum,
    x.CnInvDate,
    x.ciKey
HAVING (((x.ciKey) Is Not Null));
