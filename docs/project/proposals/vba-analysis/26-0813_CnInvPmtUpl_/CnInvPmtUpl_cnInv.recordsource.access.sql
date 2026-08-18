-- Access: RecordSource формы CnInvPmtUpl>File_f>InvDouble>invNum>cnInv
-- Снято 2026-08-17 (построитель запросов).

SELECT
    ags_cnInv.ciKey,
    ags_cnInv.ciCn,
    ags_cnInv.ciNote,
    ags_cnInv.ciMark,
    ags_cnInv.ciInv,
    ags_cnInv.ciTimeOfEntry,
    ags_cn.cnName
FROM
    ags_cnInv
    INNER JOIN ags_cn ON ags_cnInv.ciCn = ags_cn.cn_key;
