/*
 * C2 §3.5.1.5 — verify sync cstAgPn после B (DEV noM6).
 * lastUpdated: 2026-11-26
 */
SET NOCOUNT ON;

SELECT
  (SELECT COUNT(*) FROM ags.cstAgPn) AS cstAgPn_cnt_expect_4559,
  (SELECT COUNT(*) FROM ags.cstAg) AS cstAg_cnt,
  (SELECT COUNT(*) FROM ags.cst) AS cst_cnt,
  (SELECT COUNT(*) FROM ags.ogAg) AS ogAg_cnt;

SELECT COUNT(*) AS remap_temp_left
FROM ags.cstAgPn WHERE cstapIpgPnN LIKE N'__REMAP_%';

SELECT COUNT(*) AS dup_codes
FROM (
  SELECT cstapIpgPnN FROM ags.cstAgPn GROUP BY cstapIpgPnN HAVING COUNT(*)>1
) d;

SELECT cstapKey, cstapIpgPnN FROM ags.cstAgPn
WHERE cstapKey IN (3804,4417,4418,4422,4423,4443,4448,4555,4577,4583,4584,4585,4586,4587,4588)
ORDER BY cstapKey;

-- ожидаемые коды (контроль)
SELECT v.cstapKey, v.expect_code, p.cstapIpgPnN AS actual,
       CASE WHEN p.cstapIpgPnN = v.expect_code THEN N'OK' ELSE N'FAIL' END AS chk
FROM (VALUES
  (3804, N'051-1002605'),
  (4417, N'051-2007134'),
  (4418, N'051-2007135'),
  (4422, N'014-2007423'),
  (4423, N'014-2007424'),
  (4443, N'051-1007114'),
  (4448, N'051-1006267'),
  (4555, N'051-2006707'),
  (4577, N'051-2007384'),
  (4583, N'051-2007329'),
  (4584, N'051-2007330'),
  (4585, N'051-2006008'),
  (4586, N'051-2005977'),
  (4587, N'051-2000986'),
  (4588, N'051-2001510')
) v(cstapKey, expect_code)
LEFT JOIN ags.cstAgPn p ON p.cstapKey = v.cstapKey
ORDER BY v.cstapKey;
GO
