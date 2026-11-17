-- Access QueryDef: ralpRaSumTestRslt
-- Type: 0

SELECT ralprsNum, ralprsSenderStr, ralprsSender, ralprsArrived, arrived.[Count-ralprKey] AS arrivedCount, iif(iif(isnull(ralprsArrived),0,ralprsArrived)-iif(isnull(arrivedCount),0,arrivedCount)=0,null,iif(isnull(ralprsArrived),0,ralprsArrived)-iif(isnull(arrivedCount),0,arrivedCount)) AS arrivedDifference, ralprsInProcess, InProcess.[Count-ralprKey] AS inProcessCount, iif(iif(isnull(ralprsInProcess),0,ralprsInProcess)-iif(isnull(inProcessCount),0,inProcessCount)=0,null,iif(isnull(ralprsInProcess),0,ralprsInProcess)-iif(isnull(inProcessCount),0,inProcessCount)) AS InProcessDifference, ralprsSended, sended.[Count-ralprKey] AS sendCount, iif(iif(isnull(ralprsSended),0,ralprsSended)-iif(isnull(sendCount),0,sendCount)=0,null,iif(isnull(ralprsSended),0,ralprsSended)-iif(isnull(sendCount),0,sendCount)) AS SendedDifference, ralprsReturned, returned.[Count-ralprKey] AS returnCount, iif(iif(isnull(ralprsReturned),0,ralprsReturned)-iif(isnull(returnCount),0,returnCount)=0,null,iif(isnull(ralprsReturned),0,ralprsReturned)-iif(isnull(returnCount),0,returnCount)) AS ReturnedDifference, ralprsAccepted, sended.[Sum-ralpraCostAndVat] AS sendSum, iif(iif(isnull(ralprsAccepted),0,ralprsAccepted)-iif(isnull(sendSum),0,sendSum)=0,null,iif(isnull(ralprsAccepted),0,ralprsAccepted)-iif(isnull(sendSum),0,sendSum)) AS AcceptedDifference, ralprsY, ralprsAdtKey
FROM (((ralpRaSumTest LEFT JOIN (SELECT ags_ralpRa.ralprY, ags_ralpRa.ralprOgSender, Sum(ags_ralpRaAu.ralpraCostAndVat) AS [Sum-ralpraCostAndVat], Count(ags_ralpRa.ralprKey) AS [Count-ralprKey]
			FROM ags_ralpRa INNER JOIN ags_ralpRaAu ON ags_ralpRa.ralprKey = ags_ralpRaAu.ralpraRa
			GROUP BY ags_ralpRa.ralprY, ags_ralpRa.ralprOgSender, ags_ralpRaAu.ralpraStatus
			HAVING (((ags_ralpRaAu.ralpraStatus)=2))
		)  AS sended ON (ralpRaSumTest.ralprsY = sended.ralprY) AND (ralpRaSumTest.ralprsSender = sended.ralprOgSender)) LEFT JOIN (SELECT ags_ralpRa.ralprY, ags_ralpRa.ralprOgSender, Count(ags_ralpRa.ralprKey) AS [Count-ralprKey]
			FROM ags_ralpRa INNER JOIN ags_ralpRaAu ON ags_ralpRa.ralprKey = ags_ralpRaAu.ralpraRa
			GROUP BY ags_ralpRa.ralprY, ags_ralpRa.ralprOgSender, ags_ralpRaAu.ralpraStatus
			HAVING (((ags_ralpRaAu.ralpraStatus)=3))
		)  AS returned ON (ralpRaSumTest.ralprsY = returned.ralprY) AND (ralpRaSumTest.ralprsSender = returned.ralprOgSender)) LEFT JOIN (SELECT ags_ralpRa.ralprY, ags_ralpRa.ralprOgSender, Count(ags_ralpRa.ralprKey) AS [Count-ralprKey]
			FROM ags_ralpRa INNER JOIN ags_ralpRaAu ON ags_ralpRa.ralprKey = ags_ralpRaAu.ralpraRa
			GROUP BY ags_ralpRa.ralprY, ags_ralpRa.ralprOgSender, ags_ralpRaAu.ralpraStatus
			HAVING (((ags_ralpRaAu.ralpraStatus)=1))
		)  AS InProcess ON (ralpRaSumTest.ralprsY = InProcess.ralprY) AND (ralpRaSumTest.ralprsSender = InProcess.ralprOgSender)) LEFT JOIN (SELECT ags_ralpRa.ralprY, ags_ralpRa.ralprOgSender, Count(ags_ralpRa.ralprKey) AS [Count-ralprKey]
			FROM ags_ralpRa INNER JOIN ags_ralpRaAu ON ags_ralpRa.ralprKey = ags_ralpRaAu.ralpraRa
			GROUP BY ags_ralpRa.ralprY, ags_ralpRa.ralprOgSender
		)  AS arrived ON (ralpRaSumTest.ralprsY = arrived.ralprY) AND (ralpRaSumTest.ralprsSender = arrived.ralprOgSender);
