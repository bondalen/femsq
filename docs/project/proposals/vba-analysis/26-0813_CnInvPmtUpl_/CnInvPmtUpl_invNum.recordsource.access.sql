-- Access: RecordSource формы CnInvPmtUpl>File_f>InvDouble>invNum
-- Снято 2026-08-17 (построитель запросов).

SELECT
    ags_invNum.inKey,
    ags_invNum.inNum,
    ags_invNum.inNote,
    ags_invNum.inInv,
    ags_invNum.inTimeOfEntry,
    ags_invNum.inNumNull
FROM ags_invNum;
