-- Access QueryDef: 24-1224_masteringCompare_q
-- Type: 0

SELECT [24-1224_masteringCompare].cstAgPn, [24-1224_masteringCompare].cstName, [24-1224_masteringCompare].[mastering24_01-11], IIf(IsNull([mastering24_01-11]),0,1000000*[mastering24_01-11]) AS [maseringD644_01-11], [24-1224_masteringCompare_q_db].rowNum AS numF644, [24-1224_masteringCompare_q_db].ag_acceptedTtlAccum, [24-1224_masteringCompare_q_db].np_acceptedTtlAccum, [24-1224_masteringCompare_q_db].masteringAll, [maseringD644_01-11]-[masteringAll] AS delta, Abs([delta]) AS deltaAbsolut, [24-1224_masteringCompare_q_db].ag_lim, [24-1224_masteringCompare_q_db].iv_lim, [24-1224_masteringCompare_q_db].uk_lim
FROM [24-1224_masteringCompare] LEFT JOIN [24-1224_masteringCompare_q_db] ON [24-1224_masteringCompare].cstAgPn = [24-1224_masteringCompare_q_db].cstAgPnCode;
