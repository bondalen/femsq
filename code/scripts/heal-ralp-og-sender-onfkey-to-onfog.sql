-- Heal Docker test only: ralpRa.ralprOgSender onfKey → onfOg (после restore из старого staging).
SET NOCOUNT ON;
UPDATE ra
SET ra.ralprOgSender = n.onfOg
FROM ags.ralpRa ra
INNER JOIN ags.ogNmF n ON n.onfKey = ra.ralprOgSender
WHERE ra.ralprY = 2026
  AND n.onfOg IS NOT NULL
  AND n.onfOg <> ra.ralprOgSender;
SELECT @@ROWCOUNT AS healed_rows;
SELECT COUNT(*) AS as_ogKey FROM ags.ralpRa ra INNER JOIN ags.og o ON o.ogKey = ra.ralprOgSender WHERE ra.ralprY = 2026;
