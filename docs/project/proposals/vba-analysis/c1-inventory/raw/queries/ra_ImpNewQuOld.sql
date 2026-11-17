-- Access QueryDef: ra_ImpNewQuOld
-- Type: 0

SELECT i.rainRow, i.rainRaNum, i.rainRaDate, DateSerial(Year([rainRaDate]),Month([rainRaDate]),IIf(Day([rainRaDate])<16,15,Day(DateAdd("d",-1,DateAdd("m",1,DateSerial(Year([rainRaDate]),Month([rainRaDate]),1)))))) AS rainRaDatePeriod, p.key AS periodKey, i.rainCstAgPnStr, c.cstapKey, i.rainSign, o.ogKey
FROM ((ra_ImpNew AS i LEFT JOIN ags_cstAgPn AS c ON i.rainCstAgPnStr = c.cstapIpgPnN) LEFT JOIN ags_ogNmF_allVariantsNoRepeat AS o ON i.rainSender = o.ogNm255) LEFT JOIN ags_ra_period AS p ON i.rainRaDate = p.rap_datePeriod;
