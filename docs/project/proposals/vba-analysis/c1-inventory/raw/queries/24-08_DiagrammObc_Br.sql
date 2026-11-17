-- Access QueryDef: 24-08_DiagrammObc_Br
-- Type: 0

SELECT z.ogNm, Count(z.branchName) AS countBranch
FROM (SELECT a.ogNm, a.branchName FROM ags_fnIpgChRsltCstUtlPercentBrn_2408_tbl_part_2 AS a GROUP BY a.ogNm, a.branchName HAVING (((a.ogNm) Is Not Null) AND ((a.branchName) Is Not Null)))  AS z
GROUP BY z.ogNm;
