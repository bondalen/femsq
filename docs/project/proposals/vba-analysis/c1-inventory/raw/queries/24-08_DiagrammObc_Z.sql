-- Access QueryDef: 24-08_DiagrammObc_Z
-- Type: 0

SELECT *
FROM (SELECT * from [24-08_DiagrammObc_devel]
union all
SELECT * from [24-08_DiagrammObc_01_devel]
)  AS z
ORDER BY z.ogNm, z.branchName_Sort, z.cstAgPnCode_sort, z.dateRslt;
