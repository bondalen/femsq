-- Access QueryDef: Запрос14
-- Type: 0

SELECT cia.ciaName, cia.ciaKey, cias.ciasKey, cn.cnnNum, [in].inNum, a.account_num
FROM ((((((ags_cnInvAccnt AS cia INNER JOIN ags_cnInvAccntSmpl AS cias ON cia.ciaCnInvAccntSmpl = cias.ciasKey) INNER JOIN ags_cnInv AS ci ON cias.ciasCnInv = ci.ciKey) INNER JOIN ags_inv AS i ON ci.ciInv = i.iKey) INNER JOIN ags_cn AS c ON ci.ciCn = c.cn_key) INNER JOIN ags_accnt AS a ON cias.ciasAccnt = a.account_key) INNER JOIN ags_cnNum AS cn ON c.cn_key = cn.cnnCn) INNER JOIN ags_invNum AS [in] ON i.iKey = [in].inInv
WHERE (((cia.ciaName) Is Not Null));
