-- Access QueryDef: invDoubleCia
-- Type: SELECT
-- Снято владельцем: 2026-08-24 (не входит в дамп cidu*)
-- Шаг VBA: invDbtDouble (Form_CnInvDbtUpl_gt_File_f)
--
-- Важно: имя шага «invDbt», но FROM — старый контур cnInvAccnt + Smpl + cnInv + inv.
-- Нет HAVING COUNT(*)>1: это DISTINCT iKey, у которых есть хотя бы одна карточка с ciaName IS NOT NULL.
-- Таблица ags.invDbt в запросе не участвует.

SELECT i.iKey
FROM ((ags_cnInvAccnt AS cia
  INNER JOIN ags_cnInvAccntSmpl AS cias ON cia.ciaCnInvAccntSmpl = cias.ciasKey)
  INNER JOIN ags_cnInv AS ci ON cias.ciasCnInv = ci.ciKey)
  INNER JOIN ags_inv AS i ON ci.ciInv = i.iKey
WHERE (((cia.ciaName) Is Not Null))
GROUP BY i.iKey;
