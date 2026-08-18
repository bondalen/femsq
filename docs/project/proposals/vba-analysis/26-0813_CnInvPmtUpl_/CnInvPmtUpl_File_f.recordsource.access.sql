-- Access: RecordSource формы CnInvPmtUpl>File_f
-- Снято 2026-08-18 (конструктор → построитель запросов).
-- Все 7 полей локальной CnInvPmtUplFile; ничего не отсечено.

SELECT
    CnInvPmtUplFile.cipufKey,
    CnInvPmtUplFile.cipufUpload,
    CnInvPmtUplFile.cipufPath,
    CnInvPmtUplFile.cipufFlLoad,
    CnInvPmtUplFile.cipufLoadingProgress,
    CnInvPmtUplFile.cipufFlTbl,
    CnInvPmtUplFile.cipufSheet
FROM CnInvPmtUplFile;
