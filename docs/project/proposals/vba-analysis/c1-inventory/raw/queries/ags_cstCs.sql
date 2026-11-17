-- Access QueryDef: ags_cstCs
-- Type: 0

SELECT ags_cst.cstKey, ags_cst.cstName, ags_cst.cstMark, PlainText(Left([cstName],255)) AS nm255
FROM ags_cst;
