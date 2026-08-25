-- Access QueryDef: ciduCnCtptInvExistAccNot
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT x.cidutCntrPrtNum, x.cidutCntrPrtName, x.cidutCnName, x.cidutCnDate, x.cn_key, x.cidutCnInv, x.ciKey, x.cidutAccount, x.account_num, w.ciaKey
FROM (select
            Z.cidutCntrPrtNum , Z.cidutCntrPrtName, Z.cidutCnName, Z.cidutCnDate, Z.cn_key, Z.cidutCnInv, Z.ciKey, y.cidutAccount, y.account_num
        from
            ciduCnCtptExistInvAll  as z
            Left Join
                (
                    select
                        i.cidutCntrPrtNum,
                        i.cidutCnName, i.cidutCnNameNull,
                        i.cidutCnDate, i.cidutCnDateNull, ii.account_num,
                        i.cidutCnInv, i.cidutCnInvNull,
                        i.cidutAccount
                    from
                        CnInvDbtUplTbl As i
                        inner Join
                            ags_accnt as ii on i.cidutAccount = ii.account_key
                ) as y on z.cidutCntrPrtNum = y.cidutCntrPrtNum and z.cidutCnNameNull = y.cidutCnNameNull
                    and z.cidutCnDateNull = y.cidutCnDateNull and z.cidutCnInvNull = y.cidutCnInvNull
    )  AS x LEFT JOIN ags_cnInvAccnt AS w ON (x.ciKey = w.ciaCnInv) AND (x.cidutAccount = w.ciaAccnt)
WHERE (((w.ciaKey) Is Null));
