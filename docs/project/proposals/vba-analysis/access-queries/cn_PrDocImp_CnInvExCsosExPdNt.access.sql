/*
 * Объект MS Access: сохранённый запрос cn_PrDocImp_CnInvExCsosExPdNt
 *
 * Назначение: вариант цепочки **PdEx** для случая «документ на сервере не сопоставлен»
 * по полному ключу шапки: внутренний блок `z` + `ags_cn_PrDoc AS d` с GROUP BY и
 * `HAVING d.cnpdKey Is Null`. Далее `y` — повторный LEFT JOIN к `ags_cn_PrDoc` только по
 * `cnpdNumNull` и `cnpdDateNull`; в выборку попадает `ags_cn_PrDoc.cnpdKey AS NumDate`.
 * Внешний уровень `x` — `Count(x.NumDate) AS NumDateCount` по ключам строки буфера.
 *
 * Примечание: в подзапросе до алиаса `y` в SELECT только `d.cnpdKey`; в Access столбец
 * доступен как `y.cnpdKey` (не ключ строки `cn_PrDocImp` — после `HAVING Is Null` он Null).
 *
 * Зависимости: `cn_PrDocImp_CnInvExCsosEx`, таблицы `cn_PrDocImp`, `ags_cn_PrDoc`.
 * В коде: `Form_ra_a.cls` → `OpenRecordset("cn_PrDocImp_CnInvExCsosExPdNt", …)`.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник текста: cn_PrDocImp_CnInvExCsosExPdNt.txt (снято из Access).
 *
 * lastUpdated: 2026-03-19
 */

SELECT
    x.cn_key,
    x.CnNum,
    x.CnInvNum,
    x.CnInvDate,
    x.ciKey,
    x.inKeyCount,
    x.csosKey,
    x.AccountMain,
    x.ciasKey,
    x.cnpdTpOrd,
    x.cnpdTpOrdKey,
    x.cnpdNumNull,
    x.cnpdDateNull,
    x.cnpdKey,
    Count(x.NumDate) AS NumDateCount
FROM (
    SELECT
        y.cn_key,
        y.CnNum,
        y.CnInvNum,
        y.CnInvDate,
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
        ags_cn_PrDoc.cnpdKey AS NumDate
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
            d.cnpdKey
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
                i.cnpdTpOrd,
                i.cnpdTpOrdKey,
                i.cnpdNumNull,
                i.cnpdDateNull
            FROM cn_PrDocImp_CnInvExCsosEx AS e
                LEFT JOIN cn_PrDocImp AS i
                    ON (e.CnNum = i.cnpdCnNumNull)
                    AND (e.CnInvNum = i.cnpdCnInvNumNull)
                    AND (e.CnInvDate = i.cnpdCnInvDateNull)
                    AND (e.AccountMain = i.AccountMain)
        ) AS z
            LEFT JOIN ags_cn_PrDoc AS d
                ON (z.cnpdTpOrdKey = d.cnpdTpOrd)
                AND (z.cnpdDateNull = d.cnpdDateNull)
                AND (z.cnpdNumNull = d.cnpdNumNull)
                AND (z.ciasKey = d.cnpdCnInvAccntSmpl)
        GROUP BY
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
            d.cnpdKey
        HAVING (((d.cnpdKey) Is Null))
    ) AS y
        LEFT JOIN ags_cn_PrDoc
            ON (y.cnpdNumNull = ags_cn_PrDoc.cnpdNumNull)
            AND (y.cnpdDateNull = ags_cn_PrDoc.cnpdDateNull)
    GROUP BY
        y.cn_key,
        y.CnNum,
        y.CnInvNum,
        y.CnInvDate,
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
        ags_cn_PrDoc.cnpdKey
) AS x
GROUP BY
    x.cn_key,
    x.CnNum,
    x.CnInvNum,
    x.CnInvDate,
    x.ciKey,
    x.inKeyCount,
    x.csosKey,
    x.AccountMain,
    x.ciasKey,
    x.cnpdTpOrd,
    x.cnpdTpOrdKey,
    x.cnpdNumNull,
    x.cnpdDateNull,
    x.cnpdKey;
