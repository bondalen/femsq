/*
 * Объект MS Access: сохранённый запрос cn_PrDocImp_CnInvExCsosExPdExPnExRs
 *
 * Назначение: финальное звено цепочки CnInv* — строки cn_PrDocImp_CnInvExCsosExPdExPnEx (e)
 * сопоставляются с исходной строкой cn_PrDocImp (i) и с серверной позицией ags_cn_PrDocP (b);
 * для каждого поля пара i/b и флаг rs* (IIf равенства; для части полей — учёт обоих Null).
 * Итоговый флаг rslt — логическое AND всех rs*.
 *
 * Замечание: в исходном Access для rsPurchasingGroup в IIf указано сравнение accountingDocName;
 * при расхождении с бизнес-логикой проверьте запрос в конструкторе Access.
 *
 * Зависимости: cn_PrDocImp_CnInvExCsosExPdExPnEx, таблицы cn_PrDocImp, ags_cn_PrDocP.
 *
 * Диалект: Microsoft Access SQL (Jet/ACE). Не исполнять как есть на SQL Server.
 *
 * Источник текста: cn_PrDocImp_CnInvExCsosExPdExPnExRs.txt (снято из Access).
 *
 * lastUpdated: 2026-03-19
 */

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
    e.NumSequentialCount,
    e.pdpCstAgPnStr,
    e.pdpCstAgPnKey,
    e.docOfAccountNumNull,
    e.accountingDocNull,
    e.objectNull,
    e.pdpKey,
    i.StatusOfDICtext,
    b.StatusOfDICtext,
    IIf([i]![StatusOfDICtext] = [b]![StatusOfDICtext], True, False) AS RsStatusOfDICtext,
    i.satstusOfOUKVtext,
    b.satstusOfOUKVtext,
    IIf([i].[satstusOfOUKVtext] = [b].[satstusOfOUKVtext], True, False) AS rsStatusOfOUKVtext,
    i.summ,
    b.summ,
    IIf([i].[summ] = [b].[summ], True, False) AS rsSumm,
    i.cost,
    b.cost,
    IIf([i].[cost] = [b].[cost], True, False) AS rsCost,
    i.SumTax,
    b.SumTax,
    IIf([i].[SumTax] = [b].[SumTax], True, False) AS rsSumTax,
    i.costVAT,
    b.costVAT,
    IIf([i].[costVAT] = [b].[costVAT], True, False) AS rsCostVAT,
    i.SPPelement,
    b.SPPelement,
    IIf([i].[SPPelement] = [b].[SPPelement], True, False) AS rsSPPelement,
    i.AccountDate,
    b.AccountDate,
    IIf([i].[AccountDate] = [b].[AccountDate], True, False) AS rsAccountDate,
    i.positingDate,
    b.positingDate,
    IIf([i].[positingDate] = [b].[positingDate], True, False) AS rsPositingDate,
    i.agent,
    b.agent,
    IIf(
        [i].[agent] = [b].[agent] Or (IsNull([i].[agent]) And IsNull([b].[agent])),
        True,
        False
    ) AS rsAgent,
    i.TextOfAgent,
    b.TextOfAgent,
    IIf(
        [i].[TextOfAgent] = [b].[TextOfAgent] Or (IsNull([i].[TextOfAgent]) And IsNull([b].[TextOfAgent])),
        True,
        False
    ) AS rsTextOfAgent,
    i.prjctDefinition,
    b.prjctDefinition,
    IIf([i].[prjctDefinition] = [b].[prjctDefinition], True, False) AS rsPrjctDefinition,
    i.prjctDefinitionSort,
    b.prjctDefinitionSort,
    IIf([i].[prjctDefinitionSort] = [b].[prjctDefinitionSort], True, False) AS rsPrjctDefinitionSort,
    i.prjctHierarchyLevel,
    b.prjctHierarchyLevel,
    IIf(
        [i].[prjctHierarchyLevel] = [b].[prjctHierarchyLevel],
        True,
        False
    ) AS rsPrjctHierarchyLevel,
    i.ParentSppElementNum,
    b.ParentSppElementNum,
    IIf(
        [i].[ParentSppElementNum] = [b].[ParentSppElementNum]
        Or (IsNull([i].[ParentSppElementNum]) And IsNull([b].[ParentSppElementNum])),
        True,
        False
    ) AS rsParentSppElementNum,
    i.cstDSW,
    b.cstDSW,
    IIf(
        i.cstDSW = b.cstDSW Or (IsNull(i.cstDSW) And IsNull(b.cstDSW)),
        True,
        False
    ) AS rsCstDSW,
    i.raNum,
    b.raNum,
    IIf(
        [i].[raNum] = [b].[raNum] Or (IsNull([i].[raNum]) And IsNull([b].[raNum])),
        True,
        False
    ) AS rsRaNum,
    i.raDate,
    b.raDate,
    IIf(
        [i].[raDate] = [b].[raDate] Or (IsNull([i].[raDate]) And IsNull([b].[raDate])),
        True,
        False
    ) AS rsRaDate,
    i.CorrectionNum,
    b.CorrectionNum,
    IIf(
        [i].[CorrectionNum] = [b].[CorrectionNum]
        Or (IsNull([i].[CorrectionNum]) And IsNull([b].[CorrectionNum])),
        True,
        False
    ) AS rsCorrectionNum,
    i.CorrectionDate,
    b.CorrectionDate,
    IIf(
        [i].[CorrectionDate] = [b].[CorrectionDate]
        Or (IsNull([i].[CorrectionDate]) And IsNull([b].[CorrectionDate])),
        True,
        False
    ) AS rsCorrectionDate,
    i.accountingDocName,
    b.accountingDocName,
    IIf([i].[accountingDocName] = [b].[accountingDocName], True, False) AS rsAccountingDocName,
    i.purchasingGroup,
    b.purchasingGroup,
    IIf([i].[accountingDocName] = [b].[accountingDocName], True, False) AS rsPurchasingGroup,
    i.purchasingGroupName,
    b.purchasingGroupName,
    IIf([i].[purchasingGroupName] = [b].[purchasingGroupName], True, False) AS rsPurchasingGroupName,
    RsStatusOfDICtext
        And rsStatusOfOUKVtext
        And rsSumm
        And rsCost
        And rsSumTax
        And rsCostVAT
        And rsSPPelement
        And rsAccountDate
        And rsPositingDate
        And rsAgent
        And rsTextOfAgent
        And rsPrjctDefinition
        And rsPrjctDefinitionSort
        And rsPrjctHierarchyLevel
        And rsParentSppElementNum
        And rsCstDSW
        And rsRaNum
        And rsRaDate
        And rsCorrectionNum
        And rsCorrectionDate
        And rsAccountingDocName
        And rsPurchasingGroup
        And rsPurchasingGroupName AS rslt
FROM (
    (
        cn_PrDocImp_CnInvExCsosExPdExPnEx AS e
        LEFT JOIN cn_PrDocImp AS i
            ON (e.objectNull = i.objectNull)
            AND (e.accountingDocNull = i.accountingDocNull)
            AND (e.docOfAccountNumNull = i.docOfAccountNumNull)
            AND (e.pdpCstAgPnKey = i.pdpCstAgPnKey)
            AND (CDate(e.cnpdDateNull) = CDate(i.cnpdDateNull))
            AND (e.cnpdNumNull = i.cnpdNumNull)
            AND (e.cnpdTpOrdKey = i.cnpdTpOrdKey)
            AND (e.AccountMain = i.AccountMain)
            AND (CDate(e.CnInvDate) = CDate(i.cnpdCnInvDateNull))
            AND (e.CnInvNum = i.cnpdCnInvNumNull)
            AND (e.CnNum = i.cnpdCnNumNull)
    )
    LEFT JOIN ags_cn_PrDocP AS b
        ON e.pdpKey = b.pdpKey
);
