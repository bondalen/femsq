-- Access QueryDef: 24-08_DiagrammObc_Z_cst
-- Type: 0

SELECT *
FROM (SELECT * from [24-08_DiagrammObc_devel]
union all
SELECT * from [24-08_DiagrammObc_01_devel]
)  AS z
WHERE ((Not (z.cstAgPnCode_hook)="всего"))
ORDER BY z.ogNm, z.branchName_Sort, z.cstAgPnCode_sort, z.dateRslt;
