-- =============================================================================
-- DEV-only rollback §4.3 fixture FEMSQ_O2_43_* на ipg 27 / chain 507.
-- =============================================================================
SET NOCOUNT ON;

DECLARE @ipg int = 27;
DECLARE @ipgCh int = 507;

BEGIN TRAN;

UPDATE ags.ipgChRl SET ipgcrUtPlGr = NULL
WHERE ipgcrChain = @ipgCh AND ipgcrIpg = @ipg
  AND ipgcrUtPlGr IN (SELECT iuplgKey FROM ags.ipgUtPlGr WHERE iuplgIpg = @ipg AND iuplgNm LIKE N'FEMSQ_O2_43_%');

UPDATE ags.ipgChRl_2606 SET ipgcrvUtPlGr = NULL
WHERE ipgcrvChain = @ipgCh AND ipgcrvIpg = @ipg
  AND ipgcrvUtPlGr IN (SELECT iuplgKey FROM ags.ipgUtPlGr WHERE iuplgIpg = @ipg AND iuplgNm LIKE N'FEMSQ_O2_43_%');

DELETE m
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags.ipgUtPlP p ON p.iuplpKey = m.iuplpmPlPn
INNER JOIN ags.ipgUtPl u ON u.iuplKey = p.iuplpPl
WHERE u.iuplIpg = @ipg AND u.iuplNm LIKE N'FEMSQ_O2_43_%';

DELETE p
FROM ags.ipgUtPlP p
INNER JOIN ags.ipgUtPl u ON u.iuplKey = p.iuplpPl
WHERE u.iuplIpg = @ipg AND u.iuplNm LIKE N'FEMSQ_O2_43_%';

DELETE gp
FROM ags.ipgUtPlGrP gp
INNER JOIN ags.ipgUtPlGr g ON g.iuplgKey = gp.iuplgpGr
WHERE g.iuplgIpg = @ipg AND g.iuplgNm LIKE N'FEMSQ_O2_43_%';

DELETE FROM ags.ipgUtPlGr WHERE iuplgIpg = @ipg AND iuplgNm LIKE N'FEMSQ_O2_43_%';
DELETE FROM ags.ipgUtPl WHERE iuplIpg = @ipg AND iuplNm LIKE N'FEMSQ_O2_43_%';

COMMIT;
SELECT N'rollback done' AS status;
GO
