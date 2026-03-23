/*
 * Объект MS Access: сохранённый запрос cn_PrDocImp_CnInvExCsosExPdExPnNtOneAccDoc
 *
 * Назначение: цепочка CnInv* — то же ядро, что у `cn_PrDocImp_CnInvExCsosExPdExPnEx` / `PnNt`
 * (агрегат от `cn_PrDocImp_CnInvExCsosExPdEx` + расширение из `cn_PrDocImp`), затем
 * LEFT JOIN к `ags_cn_PrDocP` **без** условия по `accountingDocNull` в ON (чтобы найти
 * совпадение позиции при возможном расхождении учётного документа), и отбор строк,
 * где `ags_cn_PrDocP.accountingDocNull <> y.accountingDocNull`.
 * В результат попадают также `pdpKey` и `accountingDocNull` с сервера.
 *
 * Зависимости: `cn_PrDocImp_CnInvExCsosExPdEx`, таблицы `cn_PrDocImp`, `ags_cn_PrDocP`.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник текста: cn_PrDocImp_CnInvExCsosExPdExPnNtOneAccDoc.txt (снято из Access).
 *
 * lastUpdated: 2026-03-19
 */

SELECT
    y.cn_key,
    y.CnNum,
    y.CnInvNum,
    CDate([y].[CnInvDate]) AS CnInvDate,
    y.ciKey,
    y.inKeyCount,
    y.csosKey,
    y.AccountMain,
    y.ciasKey,
    y.cnpdTpOrd,
    y.cnpdTpOrdKey,
    y.cnpdNumNull,
    y.cnpdDateNull,
    y.cnpdKey,
    y.NumSequentialCount,
    y.pdpCstAgPnStr,
    y.pdpCstAgPnKey,
    y.docOfAccountNumNull,
    y.accountingDocNull,
    y.objectNull,
    ags_cn_PrDocP.pdpKey,
    ags_cn_PrDocP.accountingDocNull
FROM (
    SELECT
        z.cn_key,
        z.CnNum,
        z.CnInvNum,
        z.CnInvDate,
        z.ciKey,
        z.inKeyCount,
        z.csosKey,
        z.AccountMain,
        z.ciasKey,
        z.cnpdTpOrd,
        z.cnpdTpOrdKey,
        z.cnpdNumNull,
        z.cnpdDateNull,
        z.cnpdKey,
        z.NumSequentialCount,
        i.pdpCstAgPnStr,
        i.pdpCstAgPnKey,
        i.docOfAccountNumNull,
        i.accountingDocNull,
        i.objectNull
    FROM (
        SELECT
            e.cn_key,
            e.CnNum,
            e.CnInvNum,
            e.CnInvDate,
            e.ciKey,
            e.inKeyCount,
            e.csosKey,
            e.AccountMain,
            e.ciasKey,
            e.cnpdTpOrd,
            e.cnpdTpOrdKey,
            e.cnpdNumNull,
            e.cnpdDateNull,
            e.cnpdKey,
            Count(i.NumSequential) AS NumSequentialCount
        FROM cn_PrDocImp_CnInvExCsosExPdEx AS e
            LEFT JOIN cn_PrDocImp AS i
                ON (e.CnNum = i.cnpdCnNumNull)
                AND (e.CnInvNum = i.cnpdCnInvNumNull)
                AND (e.CnInvDate = i.cnpdCnInvDateNull)
                AND (e.AccountMain = i.AccountMain)
                AND (e.cnpdTpOrdKey = i.cnpdTpOrdKey)
                AND (e.cnpdNumNull = i.cnpdNumNull)
                AND (e.cnpdDateNull = i.cnpdDateNull)
        GROUP BY
            e.cn_key,
            e.CnNum,
            e.CnInvNum,
            e.CnInvDate,
            e.ciKey,
            e.inKeyCount,
            e.csosKey,
            e.AccountMain,
            e.ciasKey,
            e.cnpdTpOrd,
            e.cnpdTpOrdKey,
            e.cnpdNumNull,
            e.cnpdDateNull,
            e.cnpdKey
    ) AS z
        LEFT JOIN cn_PrDocImp AS i
            ON (z.cnpdDateNull = i.cnpdDateNull)
            AND (z.cnpdNumNull = i.cnpdNumNull)
            AND (z.cnpdTpOrdKey = i.cnpdTpOrdKey)
            AND (z.AccountMain = i.AccountMain)
            AND (z.CnInvDate = i.cnpdCnInvDateNull)
            AND (z.CnInvNum = i.cnpdCnInvNumNull)
            AND (z.CnNum = i.cnpdCnNumNull)
) AS y
    LEFT JOIN ags_cn_PrDocP
        ON (y.objectNull = ags_cn_PrDocP.objectNull)
        AND (y.docOfAccountNumNull = ags_cn_PrDocP.docOfAccountNumNull)
        AND (y.pdpCstAgPnKey = ags_cn_PrDocP.pdpCstAgPn)
        AND (y.cnpdKey = ags_cn_PrDocP.pdpPrDoc)
WHERE (((ags_cn_PrDocP.accountingDocNull) <> [y].[accountingDocNull]));
