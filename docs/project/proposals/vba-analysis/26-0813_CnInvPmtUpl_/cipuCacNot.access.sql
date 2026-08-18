-- Access QueryDef: cipuCacNot
-- Шаг 2 btnUpload: уникальные cacOrNull из Excel, для которых нет пары в ags_cstAgPn
-- (LEFT JOIN уже в CnInvPmtUplTblNull → p.cstapCsta; здесь HAVING cstapCsta Is Null).
-- VBA: OpenRecordset, только лог (не INSERT). Источник вкладки «стройки новые» (CnInvPmtUplTbl_CstNew).
-- Снято 2026-08-17 (режим SQL из Nav, вкладка cipuCacNot).
-- Access: HAVING по полю из GROUP BY законен, даже если поле не в SELECT
-- (конструктор кладёт cstapCsta в GROUP BY, чтобы HAVING его видел).
-- Эквивалент: DISTINCT cacOrNull WHERE cacOrNull Is Not Null AND cstapCsta Is Null.

SELECT a.cacOrNull
FROM CnInvPmtUplTblNull AS a
WHERE (((a.cacOrNull) Is Not Null))
GROUP BY a.cacOrNull, a.cstapCsta
HAVING (((a.cstapCsta) Is Null));
