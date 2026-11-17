-- Access QueryDef: ra_period_sender
-- Type: 128

SELECT ags_ra.ra_period, ags_ra.ra_org_sender
FROM ags_ra
UNION SELECT ags_ra_change.ra_period, ags_ra_change.ra_org_sender
FROM ags_ra_change;
