-- Access QueryDef: ra_ImpNewQu
-- Type: 0

SELECT z.rainRow, z.rainRaNum, z.rainRaDate, z.rainRaDatePeriod, p.key AS periodKey, z.rainCstAgPnStr, z.rainSign, c.cstapKey, o.ogKey
FROM (((SELECT i.rainRow, i.rainRaNum, i.rainRaDate, DateSerial(Year([rainRaDate]),Month([rainRaDate]),IIf(Day([rainRaDate])<16,15,Day(DateAdd("d",-1,DateAdd("m",1,DateSerial(Year([rainRaDate]),Month([rainRaDate]),1)))))) AS rainRaDatePeriod, i.rainCstAgPnStr, i.rainSign, i.rainSender FROM ra_ImpNew AS i)  AS z LEFT JOIN ags_cstAgPn AS c ON z.rainCstAgPnStr = c.cstapIpgPnN) LEFT JOIN ags_ogNmF_allVariantsNoRepeat AS o ON z.rainSender = o.ogNm255) LEFT JOIN ags_ra_period AS p ON z.rainRaDatePeriod = p.rap_datePeriod;
