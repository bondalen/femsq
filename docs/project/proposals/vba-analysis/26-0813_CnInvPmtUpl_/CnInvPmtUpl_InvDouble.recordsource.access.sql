-- Access: RecordSource формы CnInvPmtUpl>File_f>InvDouble
-- Снято 2026-08-17 (построитель запросов). Подтверждает S68.

SELECT
    d.ciputciCntrPrtNum,
    d.ciputciCntrPrtName,
    d.ciputciCnName,
    d.ciputciCnDate,
    d.ciputciCn_key,
    d.ciputciCsosKey,
    d.ciputciCnInv,
    d.ciputciCiKey,
    d.ciputciCnInvNumCount,
    IIf(IsNull([ciCn]), "", "есть") AS nnn
FROM
    CnInvPmtUplTblCnInv AS d
    LEFT JOIN
        (
            SELECT ci.ciCn, i.inNumNull AS inNum
            FROM ags_cnInv AS ci
                INNER JOIN ags_invNum AS i ON ci.ciInv = i.inInv
        ) AS z
        ON (d.ciputciCnInv = z.inNum) AND (d.ciputciCn_key = z.ciCn)
WHERE
    (((d.ciputciCnInvNumCount) Is Not Null));
