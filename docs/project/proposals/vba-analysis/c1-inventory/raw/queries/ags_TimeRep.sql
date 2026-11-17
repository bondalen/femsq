-- Access QueryDef: ags_TimeRep
-- Type: 0

SELECT ags_TimeRsltM.yKey, ags_TimeRsltM.yyyy, ags_TimeRsltM.mKey, ags_TimeRsltM.mNum, ags_TimeRsltM.mNm, ags_TimeRsltM.ogaKey, ags_TimeRsltM.ogNm
FROM ags_TimeRsltM
GROUP BY ags_TimeRsltM.yKey, ags_TimeRsltM.yyyy, ags_TimeRsltM.mKey, ags_TimeRsltM.mNum, ags_TimeRsltM.mNm, ags_TimeRsltM.ogaKey, ags_TimeRsltM.ogNm
HAVING (((ags_TimeRsltM.yyyy)=2021))
ORDER BY ags_TimeRsltM.yyyy, ags_TimeRsltM.mNum, ags_TimeRsltM.ogNm;
