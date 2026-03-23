/*
 * Объект MS Access: сохранённый запрос cn_PrDocImp_CnInv
 *
 * Назначение: агрегация по импорту cn_PrDocImp (строки с заполненным csosKey) —
 * группировка по договору, «нормализованным» номеру/дате счёт-фактуры (Null →
 * литерал "NullИлиПусто" / дата #1/1/1900#), счёту и ключам договора/организации;
 * джойн к серверным ags_cnInvAccntSmpl / ags_cnInv / ags_inv / ags_accnt / ags_invNum;
 * внешний LEFT JOIN ags_invNum и Count(inKey) как iNumCount.
 *
 * Связь с другими запросами: в навигаторе Access обычно идут запросы с префиксом
 * cn_PrDocImp_CnInv* (например cn_PrDocImp_CnInvNt, …), которые могут ссылаться друг
 * на друга. Этот файл — **один** объект; при упрощении цепочки лишние запросы
 * можно убрать в БД и здесь отдельно (см. план S.2.2).
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник текста: cn_PrDocImp_CnInv.txt (снято из Access).
 *
 * lastUpdated: 2026-03-21
 */

SELECT
    z.cnpdCnNum,
    z.CnInvNum,
    z.CnInvDate,
    z.AccountMain,
    z.cn_key,
    z.csosKey,
    z.PrDocCount,
    y.ciasKey,
    Count(ags_invNum.inKey) AS iNumCount
FROM (
    (
        SELECT
            i.cnpdCnNum,
            IIf(IsNull([cnpdCnInvNum]), "NullИлиПусто", [cnpdCnInvNum]) AS CnInvNum,
            IIf(IsNull([cnpdCnInvDate]), #1/1/1900#, [cnpdCnInvDate]) AS CnInvDate,
            i.AccountMain,
            i.cn_key,
            i.csosKey,
            Count(i.NumSequential) AS PrDocCount
        FROM cn_PrDocImp AS i
        WHERE (((i.csosKey) Is Not Null))
        GROUP BY
            i.cnpdCnNum,
            IIf(IsNull([cnpdCnInvNum]), "NullИлиПусто", [cnpdCnInvNum]),
            IIf(IsNull([cnpdCnInvDate]), #1/1/1900#, [cnpdCnInvDate]),
            i.AccountMain,
            i.cn_key,
            i.csosKey
        ORDER BY
            i.cnpdCnNum,
            IIf(IsNull([cnpdCnInvDate]), #1/1/1900#, [cnpdCnInvDate])
    ) AS z
        LEFT JOIN (
            SELECT
                n.inNumNull,
                i.iDate,
                i.iDateNull,
                s.ciasCn_s_org_smpl,
                a.account_num,
                s.ciasKey
            FROM (
                (
                    (
                        ags_cnInvAccntSmpl AS s
                        INNER JOIN ags_cnInv
                            ON s.ciasCnInv = ags_cnInv.ciKey
                    )
                    INNER JOIN ags_inv AS i
                        ON ags_cnInv.ciInv = i.iKey
                )
                INNER JOIN ags_accnt AS a
                    ON s.ciasAccnt = a.account_key
            )
                INNER JOIN ags_invNum AS n
                    ON i.iKey = n.inInv
        ) AS y
            ON (z.CnInvNum = y.inNumNull)
            AND (z.CnInvDate = y.iDateNull)
            AND (z.AccountMain = y.account_num)
            AND (z.csosKey = y.ciasCn_s_org_smpl)
    )
)
LEFT JOIN ags_invNum
    ON z.CnInvNum = ags_invNum.inNumNull
GROUP BY
    z.cnpdCnNum,
    z.CnInvNum,
    z.CnInvDate,
    z.AccountMain,
    z.cn_key,
    z.csosKey,
    z.PrDocCount,
    y.ciasKey;
