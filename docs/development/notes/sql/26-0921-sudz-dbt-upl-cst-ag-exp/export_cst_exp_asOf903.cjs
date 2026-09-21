#!/usr/bin/env node
/**
 * §4: экспорт узкого Excel строек Exp (yr=901, срезы 901/902/903).
 * Не полный Rslt — только код/имя/правило по кварталам для глаз.
 *
 * Usage: node export_cst_exp_asOf903.cjs
 */
const fs = require('fs');
const path = require('path');
const sql = require('/home/alex/projects/java/spring/vue/femsq/.cursor/dbhub/node_modules/mssql');
const XLSX = require('/home/alex/projects/java/spring/vue/femsq/.cursor/rslt-tools/node_modules/xlsx');

const OUT_DIR = path.join(__dirname, 'artifacts');
const OUT_XLSX = path.join(OUT_DIR, 'cstExp_yr901_asOf903_26-0921.xlsx');
const OUT_JSON = path.join(OUT_DIR, 'cstExp_rebuild_report_26-0921.json');

function loadProps() {
  const text = fs.readFileSync('/home/alex/.femsq/database.properties', 'utf8');
  const o = {};
  for (const line of text.split(/\n/)) {
    const m = line.match(/^([^#=]+)=(.*)$/);
    if (m) o[m[1].trim()] = m[2].trim();
  }
  return o;
}

async function main() {
  const p = loadProps();
  const pool = await sql.connect({
    server: p.host,
    port: Number(p.port || 1433),
    database: p.database,
    user: p.user || p.username,
    password: p.password,
    options: { encrypt: false, trustServerCertificate: true },
    requestTimeout: 600000,
  });

  const report = { generated: new Date().toISOString(), upls: {} };

  for (const upl of [901, 902, 903]) {
    console.log('rebuild', upl);
    const r = await pool.request().query(`EXEC sudz.usp_RebuildDbtUplCstAgExp @dbtUpl = ${upl}`);
    report.upls[upl] = r.recordset[0];
  }

  const summary = await pool.request().query(`
SELECT
    e.duexUpl,
    (SELECT COUNT(*) FROM sudz.DbtUplCstAg c WHERE c.ducaUpl = e.duexUpl) AS canon_n,
    SUM(CASE WHEN e.duexRule = 11 THEN 1 ELSE 0 END) AS n_11,
    SUM(CASE WHEN e.duexName = N'1.2 agent' THEN 1 ELSE 0 END) AS n_12_agent,
    SUM(CASE WHEN e.duexName = N'1.2 multi' THEN 1 ELSE 0 END) AS n_12_multi,
    SUM(CASE WHEN e.duexName = N'1.3 out-gp' THEN 1 ELSE 0 END) AS n_13_out,
    SUM(CASE WHEN e.duexName = N'1.3 agent' THEN 1 ELSE 0 END) AS n_13_agent,
    SUM(CASE WHEN e.duexName = N'1.3 multi' THEN 1 ELSE 0 END) AS n_13_multi,
    SUM(CASE WHEN e.duexRule = 14 THEN 1 ELSE 0 END) AS n_14,
    COUNT(*) AS n_all
FROM sudz.DbtUplCstAgExp AS e
WHERE e.duexUpl IN (901, 902, 903)
GROUP BY e.duexUpl
ORDER BY e.duexUpl;
`);
  report.summary = summary.recordset;

  const mismatch = await pool.request().query(`
SELECT c.ducaUpl, COUNT(*) AS canon_not_in_11
FROM sudz.DbtUplCstAg AS c
WHERE c.ducaUpl IN (901, 902, 903)
  AND NOT EXISTS (
      SELECT 1 FROM sudz.DbtUplCstAgExp AS e
      WHERE e.duexUpl = c.ducaUpl AND e.duexDbt = c.ducaDbt
        AND e.duexRule = 11 AND e.duexCstAgPn = c.ducaCstAgPn
  )
GROUP BY c.ducaUpl ORDER BY c.ducaUpl;
`);
  report.canon_mismatch = mismatch.recordset;

  // Create/refresh view
  const viewSql = fs.readFileSync(path.join(__dirname, '07_CREATE_vw_Yr_DbtFactExp.sql'), 'utf8');
  for (const batch of viewSql.split(/^\s*GO\s*$/gim).map((b) => b.trim()).filter(Boolean)) {
    await pool.request().query(batch);
  }
  console.log('view vw_Yr_DbtFactExp OK');

  const rows = await pool.request().query(`
SELECT
  f.dbtKey,
  f.invNumEnum,
  f.account_num,
  f.CtptOrg,
  MAX(CASE WHEN f.upl_key = 901 THEN f.CstAgPnCode END) AS [QIV_Code],
  MAX(CASE WHEN f.upl_key = 901 THEN f.CstAgPnName END) AS [QIV_Rule],
  MAX(CASE WHEN f.upl_key = 902 THEN f.CstAgPnCode END) AS [QI_Code],
  MAX(CASE WHEN f.upl_key = 902 THEN f.CstAgPnName END) AS [QI_Rule],
  MAX(CASE WHEN f.upl_key = 903 THEN f.CstAgPnCode END) AS [QII_Code],
  MAX(CASE WHEN f.upl_key = 903 THEN f.CstAgPnName END) AS [QII_Rule],
  MAX(CASE WHEN f.upl_key = 903 THEN f.CstAgPnDetail END) AS [QII_Detail]
FROM sudz.vw_Yr_DbtFactExp AS f
WHERE f.yr_key = 901 AND f.upl_key IN (901, 902, 903) AND f.dbtKey IS NOT NULL
GROUP BY f.dbtKey, f.invNumEnum, f.account_num, f.CtptOrg
ORDER BY f.dbtKey;
`);

  fs.mkdirSync(OUT_DIR, { recursive: true });
  const wb = XLSX.utils.book_new();
  const wsAll = XLSX.utils.json_to_sheet(rows.recordset);
  XLSX.utils.book_append_sheet(wb, wsAll, 'cstExp');

  const non11 = rows.recordset.filter(
    (r) =>
      (r.QII_Rule && r.QII_Rule !== '1.1 g_p') ||
      (r.QI_Rule && r.QI_Rule !== '1.1 g_p') ||
      (r.QIV_Rule && r.QIV_Rule !== '1.1 g_p')
  );
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(non11), 'non_1_1');
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(report.summary), 'summary');
  XLSX.writeFile(wb, OUT_XLSX);

  report.export = {
    xlsx: OUT_XLSX,
    rows: rows.recordset.length,
    non_1_1: non11.length,
  };
  fs.writeFileSync(OUT_JSON, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  await pool.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
