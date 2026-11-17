-- Access QueryDef: 24-1028_читалка_комм
-- Type: 0

SELECT ags_cnInvCmm.cnicInvAccnt, ags_cnInvCmm.cnicText, ags_cnInvCmmTp.cnictName, ags_cnInvCmmGr.cnicgDate, ags_cnInvCmmGr.cnicgName
FROM (ags_cnInvCmm INNER JOIN ags_cnInvCmmGr ON ags_cnInvCmm.cnicGroup = ags_cnInvCmmGr.cnicgKey) INNER JOIN ags_cnInvCmmTp ON ags_cnInvCmm.cnicType = ags_cnInvCmmTp.cnictKey
ORDER BY ags_cnInvCmm.cnicInvAccnt, ags_cnInvCmmGr.cnicgDate DESC;
