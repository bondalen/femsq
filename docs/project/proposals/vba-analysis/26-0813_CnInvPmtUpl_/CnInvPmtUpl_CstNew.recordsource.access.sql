-- Access: RecordSource формы CnInvPmtUpl>File_f>CstNew
-- Снято 2026-08-17 (построитель запросов формы).
-- Это обёртка над QueryDef CnInvPmtUplTbl_CstNew (алиасы Выражение1…5 — Access).
-- SQL самого QueryDef ещё не снят (открыть запрос из Nav).

SELECT
    [CnInvPmtUplTbl_CstNew].[cacOrNull] AS Выражение1,
    [CnInvPmtUplTbl_CstNew].[sh] AS Выражение2,
    [CnInvPmtUplTbl_CstNew].[ipCode] AS Выражение3,
    [CnInvPmtUplTbl_CstNew].[pirIDnew] AS Выражение4,
    [CnInvPmtUplTbl_CstNew].[pirName] AS Выражение5
FROM CnInvPmtUplTbl_CstNew;
