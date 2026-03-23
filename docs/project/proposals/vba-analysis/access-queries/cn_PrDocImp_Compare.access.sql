/*
 * Объект MS Access: сохранённый запрос cn_PrDocImp_Compare
 *
 * Назначение: сверка агрегатов по данным сервера (ags_cn_PrDocP / ags_cn_PrDoc / …)
 * с суммами по строкам локального импорта cn_PrDocImp за год [yyyy]; вычисление
 * compareRslt (все дельты сумм = 0).
 *
 * Параметр: yyyy (Short) — год для фильтра Year(positingDate) и внешнего WHERE.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник текста: cn_PrDocImp_Compare.txt (снято из Access).
 *
 * lastUpdated: 2026-03-21
 */

PARAMETERS yyyy Short;

SELECT
    y.yyyy,
    y.x.account_num,
    y.account_name,
    y.cstapIpgPnN,
    y.summSum,
    y.iSummSum,
    [summSum] - [iSummSum] AS dSummSum,
    y.costSum,
    y.iCostSum,
    [costSum] - [iCostSum] AS dCostSum,
    y.SumTaxSum,
    y.iSumTaxSum,
    [SumTaxSum] - [iSumTaxSum] AS dSumTaxSum,
    y.costVATSum,
    y.icostVATSum,
    [costVATSum] - [icostVATSum] AS dCostVATSum,
    IIf(
        [dSummSum] + [dCostSum] + [dSumTaxSum] + [dCostVATSum] = 0,
        True,
        False
    ) AS compareRslt
FROM (
    SELECT
        x.yyyy,
        x.account_num,
        x.account_name,
        x.cstapIpgPnN,
        x.summSum,
        Sum(i.summ) AS iSummSum,
        x.costSum,
        Sum(i.cost) AS iCostSum,
        x.SumTaxSum,
        Sum(i.SumTax) AS iSumTaxSum,
        x.costVATSum,
        Sum(i.costVAT) AS icostVATSum
    FROM (
        SELECT
            Year([positingDate]) AS yyyy,
            ags_accnt.account_num,
            ags_accnt.account_name,
            ags_cstAgPn.cstapIpgPnN,
            Sum(ags_cn_PrDocP.summ) AS summSum,
            Sum(ags_cn_PrDocP.cost) AS costSum,
            Sum(ags_cn_PrDocP.SumTax) AS SumTaxSum,
            Sum(ags_cn_PrDocP.costVAT) AS costVATSum
        FROM (
            (
                (
                    ags_cn_PrDocP
                    INNER JOIN ags_cn_PrDoc
                        ON ags_cn_PrDocP.pdpPrDoc = ags_cn_PrDoc.cnpdKey
                )
                INNER JOIN ags_cnInvAccntSmpl
                    ON ags_cn_PrDoc.cnpdCnInvAccntSmpl = ags_cnInvAccntSmpl.ciasKey
            )
            INNER JOIN ags_accnt
                ON ags_cnInvAccntSmpl.ciasAccnt = ags_accnt.account_key
        )
            INNER JOIN ags_cstAgPn
                ON ags_cn_PrDocP.pdpCstAgPn = ags_cstAgPn.cstapKey
        GROUP BY
            Year([positingDate]),
            ags_accnt.account_num,
            ags_accnt.account_name,
            ags_cstAgPn.cstapIpgPnN
        HAVING ((Year([positingDate]) = yyyy))
        ORDER BY
            Year([positingDate]),
            ags_accnt.account_num,
            ags_cstAgPn.cstapIpgPnN
    ) AS x
        LEFT JOIN cn_PrDocImp AS i
            ON (x.account_num = i.AccountMain)
            AND (x.cstapIpgPnN = i.pdpCstAgPnStr)
    GROUP BY
        x.yyyy,
        x.account_num,
        x.account_name,
        x.cstapIpgPnN,
        x.summSum,
        x.costSum,
        x.SumTaxSum,
        x.costVATSum
) AS y
WHERE (((y.yyyy) = [yyyy]));
