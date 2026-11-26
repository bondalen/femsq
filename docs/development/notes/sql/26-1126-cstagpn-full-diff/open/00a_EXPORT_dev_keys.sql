/* noM6: список кодов уже на DEV (для сверки после import). Только чтение. */
SET NOCOUNT ON;
SELECT cstapKey, cstapIpgPnN
FROM ags.cstAgPn
ORDER BY cstapKey;
GO
