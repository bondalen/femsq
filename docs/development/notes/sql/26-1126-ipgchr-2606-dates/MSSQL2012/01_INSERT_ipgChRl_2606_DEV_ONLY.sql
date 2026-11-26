/*
 * C2 §3.5.2 — даты членства ipgChRl_2606 для цепей 507–510 (DEV noM6).
 * Без CREATE OR ALTER. Идемпотентно: IF NOT EXISTS по (chain, ipg).
 * lastUpdated: 2026-11-26
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRAN;

/* 507 → ipg 27 */
IF NOT EXISTS (SELECT 1 FROM ags.ipgChRl_2606 WHERE ipgcrvChain = 507 AND ipgcrvIpg = 27)
INSERT INTO ags.ipgChRl_2606 (ipgcrvChain, ipgcrvIpg, ipgcrvStr, ipgcrvUtPlGr, ipgcrvEnd)
SELECT 507, 27, i.ipgStr, NULL, NULL
FROM ags.ipg i WHERE i.ipgKey = 27;

/* 508 → ipg 28 */
IF NOT EXISTS (SELECT 1 FROM ags.ipgChRl_2606 WHERE ipgcrvChain = 508 AND ipgcrvIpg = 28)
INSERT INTO ags.ipgChRl_2606 (ipgcrvChain, ipgcrvIpg, ipgcrvStr, ipgcrvUtPlGr, ipgcrvEnd)
SELECT 508, 28, i.ipgStr, NULL, NULL
FROM ags.ipg i WHERE i.ipgKey = 28;

/* 509 → ipg 29 */
IF NOT EXISTS (SELECT 1 FROM ags.ipgChRl_2606 WHERE ipgcrvChain = 509 AND ipgcrvIpg = 29)
INSERT INTO ags.ipgChRl_2606 (ipgcrvChain, ipgcrvIpg, ipgcrvStr, ipgcrvUtPlGr, ipgcrvEnd)
SELECT 509, 29, i.ipgStr, NULL, NULL
FROM ags.ipg i WHERE i.ipgKey = 29;

/* 510 → ipg 30 */
IF NOT EXISTS (SELECT 1 FROM ags.ipgChRl_2606 WHERE ipgcrvChain = 510 AND ipgcrvIpg = 30)
INSERT INTO ags.ipgChRl_2606 (ipgcrvChain, ipgcrvIpg, ipgcrvStr, ipgcrvUtPlGr, ipgcrvEnd)
SELECT 510, 30, i.ipgStr, NULL, NULL
FROM ags.ipg i WHERE i.ipgKey = 30;

COMMIT;

SELECT ipgcrvKey, ipgcrvChain, ipgcrvIpg, ipgcrvStr, ipgcrvEnd
FROM ags.ipgChRl_2606
WHERE ipgcrvChain BETWEEN 507 AND 510
ORDER BY ipgcrvChain;
GO
