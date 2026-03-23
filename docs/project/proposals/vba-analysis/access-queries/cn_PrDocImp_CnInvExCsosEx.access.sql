/*
 * Объект MS Access: сохранённый запрос cn_PrDocImp_CnInvExCsosEx
 *
 * Назначение: расширяет результат запроса cn_PrDocImp_CnInvEx (алиас e) джойном к cn_PrDocImp
 * по совпадению CnInvDate/CnInvNum/CnNum с Null-safe полями импорта; добавляет csosKey и AccountMain.
 * Затем LEFT JOIN к подзапросу y (ags_cnInvAccntSmpl / ags_cnInv / ags_inv / ags_accnt / ags_invNum)
 * по ciKey, ciasCn_s_org_smpl и account_num. HAVING: y.ciasKey Is Not Null.
 *
 * Зависимость: в Access должен существовать сохранённый запрос cn_PrDocImp_CnInvEx
 * (см. cn_PrDocImp_CnInvEx.access.sql).
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник текста: cn_PrDocImp_CnInvExCsosEx.txt (снято из Access).
 *
 * lastUpdated: 2026-03-21
 */

SELECT
    z.cn_key,
    z.CnNum,
    z.CnInvNum,
    z.CnInvDate,
    z.ciKey,
    z.inKeyCount,
    z.csosKey,
    z.AccountMain,
    y.ciasKey
FROM (
    SELECT
        e.cn_key,
        e.CnNum,
        e.CnInvNum,
        e.CnInvDate,
        e.ciKey,
        e.inKeyCount,
        i.csosKey,
        i.AccountMain
    FROM cn_PrDocImp_CnInvEx AS e
        LEFT JOIN cn_PrDocImp AS i
            ON (e.CnInvDate = i.cnpdCnInvDateNull)
            AND (e.CnInvNum = i.cnpdCnInvNumNull)
            AND (e.CnNum = i.cnpdCnNumNull)
    GROUP BY
        e.cn_key,
        e.CnNum,
        e.CnInvNum,
        e.CnInvDate,
        e.ciKey,
        e.inKeyCount,
        i.csosKey,
        i.AccountMain
) AS z
    LEFT JOIN (
        SELECT
            n.inNumNull,
            i.iDate,
            i.iDateNull,
            ci.ciKey,
            s.ciasCn_s_org_smpl,
            a.account_num,
            s.ciasKey
        FROM (
            (
                (
                    ags_cnInvAccntSmpl AS s
                    INNER JOIN ags_cnInv AS ci
                        ON s.ciasCnInv = ci.ciKey
                )
                INNER JOIN ags_inv AS i
                    ON ci.ciInv = i.iKey
            )
            INNER JOIN ags_accnt AS a
                ON s.ciasAccnt = a.account_key
        )
            INNER JOIN ags_invNum AS n
                ON i.iKey = n.inInv
    ) AS y
        ON (z.ciKey = y.ciKey)
        AND (z.csosKey = y.ciasCn_s_org_smpl)
        AND (z.AccountMain = y.account_num)
GROUP BY
    z.cn_key,
    z.CnNum,
    z.CnInvNum,
    z.CnInvDate,
    z.ciKey,
    z.inKeyCount,
    z.csosKey,
    z.AccountMain,
    y.ciasKey
HAVING (((y.ciasKey) Is Not Null));
