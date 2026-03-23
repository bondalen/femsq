/*
 * Объект MS Access: сохранённый запрос cn_PrDocImp_CnInvExCsosExPdExPnNtIn
 *
 * Назначение: детализация строк из `cn_PrDocImp_CnInvExCsosExPdExPnNt` (`q`): JOIN к строке
 * буфера `cn_PrDocImp` (`i`) и к позиции `ags_cn_PrDocP` (`d`); вычисляются признаки
 * совпадения `pdpCstAgPnKey`, `accountingDoc`, `object` между буфером и БД.
 *
 * Зависимости: `cn_PrDocImp_CnInvExCsosExPdExPnNt`, таблицы `cn_PrDocImp`, `ags_cn_PrDocP`.
 * В коде: `Form_ra_a.cls` → `OpenRecordset("cn_PrDocImp_CnInvExCsosExPdExPnNtIn", …)`.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник текста: cn_PrDocImp_CnInvExCsosExPdExPnNtIn.txt (снято из Access).
 *
 * lastUpdated: 2026-03-19
 */

SELECT
    q.CnNum,
    q.CnInvNum,
    q.CnInvDate,
    q.AccountMain,
    q.cnpdTpOrd,
    q.cnpdNumNull,
    q.cnpdDateNull,
    q.cnpdKey,
    q.pdpCstAgPnKey,
    d.pdpCstAgPn AS pdpCstAgPnKeyBd,
    IIf([i].[pdpCstAgPnKey] = [pdpCstAgPnKeyBd], True, False) AS pdpCstAgPnKeyEqual,
    i.NumSequential,
    i.StatusOfDICtext,
    i.satstusOfOUKVtext,
    i.summ,
    i.cost,
    i.SumTax,
    i.costVAT,
    i.SPPelement,
    i.docOfAccountNum,
    d.docOfAccountNum AS docOfAccountNumBd,
    d.pdpKey,
    i.AccountDate,
    i.positingDate,
    i.accountingDoc,
    d.accountingDoc AS accountingDocBd,
    IIf([i].[accountingDoc] = [accountingDocBd], True, False) AS accountingDocEqual,
    i.agent,
    i.TextOfAgent,
    i.prjctDefinition,
    i.prjctDefinitionSort,
    i.prjctHierarchyLevel,
    i.ParentSppElementNum,
    i.object,
    d.object AS objectBd,
    IIf([i].[object] = [objectBd], True, False) AS objectEqual,
    i.cstDSW,
    i.raNum,
    i.raDate,
    i.CorrectionNum,
    i.CorrectionDate,
    i.accountingDocName,
    i.purchasingGroup,
    i.purchasingGroupName,
    i.textOfCreditor,
    i.supplierTIN,
    i.supplierKPP,
    q.NumSequentialCount,
    q.pdpCstAgPnStr,
    q.docOfAccountNumNull,
    q.accountingDocNull,
    q.objectNull
FROM (
    (
        cn_PrDocImp_CnInvExCsosExPdExPnNt AS q
        LEFT JOIN cn_PrDocImp AS i
            ON (q.objectNull = i.objectNull)
            AND (q.accountingDocNull = i.accountingDocNull)
            AND (q.docOfAccountNumNull = i.docOfAccountNumNull)
            AND (q.pdpCstAgPnKey = i.pdpCstAgPnKey)
            AND (q.cnpdNumNull = i.cnpdNumNull)
            AND (q.cnpdTpOrdKey = i.cnpdTpOrdKey)
            AND (q.AccountMain = i.AccountMain)
            AND (q.CnInvNum = i.cnpdCnInvNumNull)
            AND (q.CnNum = i.cnpdCnNumNull)
    )
    LEFT JOIN ags_cn_PrDocP AS d
        ON (q.cnpdKey = d.pdpPrDoc)
        AND (q.docOfAccountNumNull = d.docOfAccountNumNull)
);
