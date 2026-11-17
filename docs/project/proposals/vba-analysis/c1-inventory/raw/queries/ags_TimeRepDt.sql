-- Access QueryDef: ags_TimeRepDt
-- Type: 0

SELECT ags_TimeRsltM.yKey, ags_TimeRsltM.yyyy, ags_TimeRsltM.mKey, ags_TimeRsltM.mNum, ags_TimeRsltM.mCs, ags_TimeRsltM.mNm, ags_TimeRsltM.mQ, ags_TimeRsltM.mHy, ags_TimeRsltM.ipgKey, ags_TimeRsltM.ipgNm, ags_TimeRsltM.cstaInvestor, ags_TimeRsltM.ogaKey, ags_TimeRsltM.ogNm, ags_TimeRsltM.typeGr, ags_TimeRsltM.typeGrTtl, ags_TimeRsltM.lim, ags_TimeRsltM.iShKey, ags_TimeRsltM.iShNm, ags_TimeRsltM.limPlan, ags_TimeRsltM.presented, ags_TimeRsltM.presentedAccum, ags_TimeRsltM.accepted, ags_TimeRsltM.acceptedAccum, ags_TimeRsltM.agFeePresented, ags_TimeRsltM.agFeePresentedAccum, ags_TimeRsltM.agFeeAccepted, ags_TimeRsltM.agFeeAcceptedAccum, ags_TimeRsltM.presentedRalp, ags_TimeRsltM.presentedRalpAccum, ags_TimeRsltM.acceptedRalp, ags_TimeRsltM.acceptedRalpAccum, ags_TimeRsltM.storageSum, ags_TimeRsltM.storageSumAccum, ags_TimeRsltM.cctSum, ags_TimeRsltM.cctSumAccum, ags_TimeRsltM.MnrlSum, ags_TimeRsltM.MnrlSumAccum, ags_TimeRsltM.presentedTtl, ags_TimeRsltM.presentedTtlAccum, ags_TimeRsltM.acceptedTtl, ags_TimeRsltM.acceptedTtlAccum, ags_TimeRsltM.restOfLimit, ags_TimeRsltM.percentDev
FROM ags_TimeRsltM
WHERE (((ags_TimeRsltM.yyyy)=2021) AND ((ags_TimeRsltM.ipgKey)=1 Or (ags_TimeRsltM.ipgKey) Is Null))
ORDER BY ags_TimeRsltM.typeGrTtl;
