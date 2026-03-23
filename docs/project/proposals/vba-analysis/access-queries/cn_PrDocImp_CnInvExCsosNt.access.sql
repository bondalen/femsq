/*
 * Объект MS Access: сохранённый запрос cn_PrDocImp_CnInvExCsosNt
 *
 * Назначение: зеркало `cn_PrDocImp_CnInvExCsosEx`, но:
 * — во внутреннем подзапросе `z` добавлен LEFT JOIN к `ags_accnt` по `i.AccountMain = a.account_num`
 *   и в результат попадает `a.account_key`;
 * — после LEFT JOIN к серверному блоку `y` (как в CsosEx) отбор **`HAVING y.ciasKey Is Null`**
 *   (связка счёт-фактура ↔ cias на сервере **не** найдена).
 *
 * Зависимости: `cn_PrDocImp_CnInvEx`, таблицы `cn_PrDocImp`, `ags_accnt`, `ags_cnInvAccntSmpl`,
 * `ags_cnInv`, `ags_inv`, `ags_invNum`.
 *
 * В коде: `Form_ra_a.cls` → `OpenRecordset("cn_PrDocImp_CnInvExCsosNt", …)`.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник текста: cn_PrDocImp_CnInvExCsosNt.txt (снято из Access).
 *
 * lastUpdated: 2026-03-19
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
    z.account_key,
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
        i.AccountMain,
        a.account_key
    FROM (
        cn_PrDocImp_CnInvEx AS e
        LEFT JOIN cn_PrDocImp AS i
            ON (e.CnNum = i.cnpdCnNumNull)
            AND (e.CnInvNum = i.cnpdCnInvNumNull)
            AND (e.CnInvDate = i.cnpdCnInvDateNull)
    )
        LEFT JOIN ags_accnt AS a
            ON i.AccountMain = a.account_num
    GROUP BY
        e.cn_key,
        e.CnNum,
        e.CnInvNum,
        e.CnInvDate,
        e.ciKey,
        e.inKeyCount,
        i.csosKey,
        i.AccountMain,
        a.account_key
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
        ON (z.AccountMain = y.account_num)
        AND (z.csosKey = y.ciasCn_s_org_smpl)
        AND (z.ciKey = y.ciKey)
GROUP BY
    z.cn_key,
    z.CnNum,
    z.CnInvNum,
    z.CnInvDate,
    z.ciKey,
    z.inKeyCount,
    z.csosKey,
    z.AccountMain,
    z.account_key,
    y.ciasKey
HAVING (((y.ciasKey) Is Null));
