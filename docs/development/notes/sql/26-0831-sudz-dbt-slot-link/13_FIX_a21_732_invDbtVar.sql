/*
 * A2.1 — data fix: invNum alias + invDbtVar@901 для Tbl «732» на hist slot 8898.
 * Запускать после clean apply с A2 (entity) но до A2.1 (var label), либо для починки 901.
 * lastUpdated: 2026-09-01
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @iKey int = 54310;
DECLARE @slot int = 8898;
DECLARE @upl int = 901;
DECLARE @tblInv nvarchar(255) = N'732';

BEGIN TRANSACTION;

IF NOT EXISTS (
    SELECT 1 FROM ags.invNum AS n
    WHERE n.inInv = @iKey AND LTRIM(RTRIM(ISNULL(n.inNum, N''))) = @tblInv
)
BEGIN
    INSERT INTO ags.invNum (inNum, inInv, inTimeOfEntry)
    VALUES (@tblInv, @iKey, GETDATE());
END;

DECLARE @inKey732 int = (
    SELECT n.inKey FROM ags.invNum AS n
    WHERE n.inInv = @iKey AND LTRIM(RTRIM(ISNULL(n.inNum, N''))) = @tblInv
);

DECLARE @cnn int;
DECLARE @acc int;
DECLARE @cso int;

SELECT TOP 1
    @cnn = v.idvvCnNum,
    @acc = v.idvvAccnt,
    @cso = v.idvvCn_s_org
FROM sudz.invDbtVar AS v
INNER JOIN sudz.DbtValue AS dv ON dv.dvInvDbtVar = v.idvvKey
WHERE dv.dvInvDbt = @slot AND dv.dvUpl = 801;

DECLARE @idvv int = (
    SELECT v.idvvKey FROM sudz.invDbtVar AS v
    WHERE v.idvvCnNum = @cnn
      AND v.idvvInvNum = @inKey732
      AND v.idvvAccnt = @acc
      AND v.idvvCn_s_org = @cso
);

IF @idvv IS NULL
BEGIN
    INSERT INTO sudz.invDbtVar (idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org, idvvTimeOfEntry)
    VALUES (@cnn, @inKey732, @acc, @cso, GETDATE());
    SET @idvv = SCOPE_IDENTITY();
END;

IF NOT EXISTS (
    SELECT 1 FROM sudz.invDbtDbtVar AS b
    WHERE b.iddvInvDbt = @slot AND b.iddvInvDbtVar = @idvv
)
BEGIN
    INSERT INTO sudz.invDbtDbtVar (iddvInvDbt, iddvInvDbtVar, iddvTimeOfEntry)
    VALUES (@slot, @idvv, GETDATE());
END;

UPDATE sudz.DbtValue
SET dvInvDbtVar = @idvv
WHERE dvInvDbt = @slot AND dvUpl = @upl;

COMMIT TRANSACTION;

SELECT dv.dvUpl, CAST(dv.dvTtl AS decimal(19, 2)) AS ttl,
       n.inNum AS var_inv, id.idKey AS slot, id.idInv AS iKey
FROM sudz.DbtValue AS dv
INNER JOIN sudz.invDbt AS id ON id.idKey = dv.dvInvDbt
INNER JOIN sudz.invDbtVar AS v ON v.idvvKey = dv.dvInvDbtVar
INNER JOIN ags.invNum AS n ON n.inKey = v.idvvInvNum
WHERE id.idKey = @slot AND dv.dvUpl IN (801, 802, 803, @upl)
ORDER BY dv.dvUpl;

GO
