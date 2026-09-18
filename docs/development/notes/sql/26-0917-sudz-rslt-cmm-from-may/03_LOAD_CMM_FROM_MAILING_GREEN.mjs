/**
 * DEV: новая cnInvCmmGr из зелёных полей Rslt сбор (файл cmm_from_may).
 * yr=901: yr_CmmGr → новая группа; 903 не трогаем.
 *
 *   node 03_LOAD_CMM_FROM_MAILING_GREEN.mjs [--dry]
 *
 * lastUpdated: 2026-09-17
 */
import { createRequire } from "module";
import { writeFileSync, existsSync, mkdirSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import { spawnSync } from "child_process";
import { homedir } from "os";

const __dirname = dirname(fileURLToPath(import.meta.url));
const require = createRequire(
  resolve(__dirname, "../../../../../.cursor/rslt-tools/package.json")
);
const XLSX = require("xlsx");

const XLSX_DEFAULT =
  "/home/alex/Downloads/продОбмен/26-0917_09-41/в_Прод/ags_Yr_DbtChangesRslt_26-0917_cmm_from_may.xlsx";
const YR_KEY = 901;
const TYPE_MERY = 1;
const TYPE_CURATOR = 8;
const CICC_TYPE_CST = 2;
const GR_NAME =
  "[sudz] Rslt сбор QII 2026 asOf903 — зелёные (перенос MAY ПДЗ, 26-0917)";
const GR_NMCS = "S82cmm";
const GR_DATE = "20260917";

function D(v) {
  if (v === null || v === undefined || v === "") return null;
  const n = Number(String(v).replace(/\s/g, "").replace(",", "."));
  if (Number.isNaN(n)) return null;
  return Math.round(n * 100) / 100;
}
function txt(v) {
  if (v === null || v === undefined) return null;
  const s = String(v).replace(/\u00A0/g, " ").trim();
  return s === "" ? null : s;
}
function sqlLiteral(s) {
  return "N'" + String(s).replace(/'/g, "''") + "'";
}
function parseArgs(argv) {
  const o = { dry: false };
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === "--dry") o.dry = true;
    else if (argv[i].startsWith("--")) o[argv[i].slice(2)] = argv[++i];
  }
  return o;
}

function loadByDbt(path) {
  const wb = XLSX.readFile(path, { cellDates: true, raw: true });
  const g = XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]], {
    header: 1,
    defval: null,
    raw: true,
  });
  const byDbt = new Map();
  for (let r = 3; r < g.length; r++) {
    const row = g[r] || [];
    const dbt = D(row[0]);
    if (dbt === null) continue;
    const rec = {
      dbtKey: dbt,
      curator: txt(row[46]),
      mery: txt(row[47]),
      cst: txt(row[48]),
    };
    if (!byDbt.has(dbt)) {
      byDbt.set(dbt, rec);
      continue;
    }
    const prev = byDbt.get(dbt);
    for (const k of ["curator", "mery", "cst"]) {
      if (!prev[k] && rec[k]) prev[k] = rec[k];
    }
  }
  return [...byDbt.values()];
}

function writeSql(rows, outDir) {
  const sqlPath = resolve(outDir, "artifacts/01_LOAD_cmm_from_mailing_green.sql");
  mkdirSync(dirname(sqlPath), { recursive: true });
  const lines = [
    "/* 26-0917 — DEV: новая cnInvCmmGr из зелёных полей Rslt сбор. SQL 2012. */",
    "SET NOCOUNT ON;",
    "SET XACT_ABORT ON;",
    "BEGIN TRAN;",
    "",
    `DECLARE @yr int = ${YR_KEY};`,
    `DECLARE @grName nvarchar(255) = ${sqlLiteral(GR_NAME)};`,
    `DECLARE @grNmCs nvarchar(50) = ${sqlLiteral(GR_NMCS)};`,
    "DECLARE @gr int;",
    "",
    "IF EXISTS (SELECT 1 FROM sudz.cnInvCmmGr WHERE cnicgNmCs = @grNmCs)",
    "  THROW 50000, N'cnInvCmmGr S82cmm already exists', 1;",
    "INSERT INTO sudz.cnInvCmmGr (cnicgNmCs, cnicgDate, cnicgName)",
    `VALUES (@grNmCs, CONVERT(datetime, '${GR_DATE}', 112), @grName);`,
    "SET @gr = SCOPE_IDENTITY();",
    "IF @gr IS NULL THROW 50001, N'cnInvCmmGr INSERT failed', 1;",
    "PRINT N'new cnicgKey=' + CONVERT(varchar(20), @gr);",
    "",
    "IF OBJECT_ID('tempdb..#cmm') IS NOT NULL DROP TABLE #cmm;",
    "CREATE TABLE #cmm (dbtKey int NOT NULL, cnicType int NOT NULL, cnicText nvarchar(max) NOT NULL);",
    "IF OBJECT_ID('tempdb..#cst') IS NOT NULL DROP TABLE #cst;",
    "CREATE TABLE #cst (dbtKey int NOT NULL, code nvarchar(64) NOT NULL);",
  ];

  const cmmRows = [];
  const cstRows = [];
  for (const p of rows) {
    if (p.curator) cmmRows.push([p.dbtKey, TYPE_CURATOR, p.curator]);
    if (p.mery) cmmRows.push([p.dbtKey, TYPE_MERY, p.mery]);
    if (p.cst) cstRows.push([p.dbtKey, p.cst]);
  }

  const CHUNK = 80;
  for (let i = 0; i < cmmRows.length; i += CHUNK) {
    const chunk = cmmRows.slice(i, i + CHUNK);
    lines.push(
      "INSERT INTO #cmm (dbtKey, cnicType, cnicText) VALUES\n" +
        chunk
          .map(([d, t, text]) => `(${d},${t},${sqlLiteral(text)})`)
          .join(",\n") +
        ";"
    );
  }
  for (let i = 0; i < cstRows.length; i += CHUNK) {
    const chunk = cstRows.slice(i, i + CHUNK);
    lines.push(
      "INSERT INTO #cst (dbtKey, code) VALUES\n" +
        chunk.map(([d, c]) => `(${d},${sqlLiteral(c)})`).join(",\n") +
        ";"
    );
  }

  lines.push(`
DELETE c FROM #cmm c WHERE NOT EXISTS (SELECT 1 FROM sudz.Dbt d WHERE d.dbtKey = c.dbtKey);
DELETE c FROM #cst c WHERE NOT EXISTS (SELECT 1 FROM sudz.Dbt d WHERE d.dbtKey = c.dbtKey);

INSERT INTO sudz.cnInvCmm (cnicType, cnicGroup, cnicInv, cnicText, cnicInvAccnt, cnicDbt)
SELECT c.cnicType, @gr, NULL, c.cnicText, c.dbtKey, c.dbtKey
FROM #cmm c;

IF OBJECT_ID('tempdb..#cstR') IS NOT NULL DROP TABLE #cstR;
SELECT c.dbtKey, c.code, pn.cstapKey
INTO #cstR
FROM #cst c
OUTER APPLY (
  SELECT TOP (1) pn.cstapKey
  FROM ags.cstAgPn pn
  WHERE pn.cstapIpgPnN COLLATE DATABASE_DEFAULT = c.code COLLATE DATABASE_DEFAULT
  ORDER BY pn.cstapKey
) pn;

SELECT 'cst_unresolved' AS k, COUNT(*) AS n FROM #cstR WHERE cstapKey IS NULL;
DELETE FROM #cstR WHERE cstapKey IS NULL;

INSERT INTO sudz.cnInvCmmCst (ciccCmmGr, ciccType, ciccCstAgPn, ciccInvAccnt, ciccDbt)
SELECT @gr, ${CICC_TYPE_CST}, r.cstapKey, r.dbtKey, r.dbtKey
FROM #cstR r;

UPDATE sudz.yr SET yr_CmmGr = @gr WHERE yr_key = @yr;
IF @@ROWCOUNT <> 1 THROW 50002, N'yr_CmmGr update failed', 1;

SELECT @gr AS cnicgKey, @grName AS cnicgName;
SELECT 'cnInvCmm' AS t, cnicType, COUNT(*) n FROM sudz.cnInvCmm WHERE cnicGroup = @gr GROUP BY cnicType;
SELECT 'cnInvCmmCst' AS t, ciccType, COUNT(*) n FROM sudz.cnInvCmmCst WHERE ciccCmmGr = @gr GROUP BY ciccType;
SELECT yr_key, yr_CmmGr, yr_CmmGr_New FROM sudz.yr WHERE yr_key = @yr;

COMMIT TRAN;
PRINT N'COMMITTED 26-0917 cmm from mailing green';
`);

  writeFileSync(sqlPath, lines.join("\n"), "utf8");
  return { sqlPath, cmmN: cmmRows.length, cstN: cstRows.length };
}

function applyViaJdbc(sqlPath) {
  const jar =
    process.env.MSSQL_JDBC_JAR ||
    resolve(
      homedir(),
      ".m2/repository/com/microsoft/sqlserver/mssql-jdbc/13.2.0.jre11/mssql-jdbc-13.2.0.jre11.jar"
    );
  if (!existsSync(jar)) throw new Error("mssql-jdbc jar not found: " + jar);
  const javaSrc = "/tmp/S82CmmApply.java";
  writeFileSync(
    javaSrc,
    `
import java.nio.file.*;
import java.sql.*;
import java.util.*;
public class S82CmmApply {
  static Map<String,String> props() throws Exception {
    Map<String,String> m = new LinkedHashMap<>();
    for (String line : Files.readAllLines(Paths.get(System.getProperty("user.home"), ".femsq", "database.properties"))) {
      line = line.trim();
      if (line.isEmpty() || line.startsWith("#") || !line.contains("=")) continue;
      int i = line.indexOf('=');
      m.put(line.substring(0,i).trim(), line.substring(i+1).trim());
    }
    return m;
  }
  static String g(Map<String,String> m, String... keys) {
    for (String k : keys) if (m.containsKey(k) && !m.get(k).isEmpty()) return m.get(k);
    return null;
  }
  public static void main(String[] args) throws Exception {
    Map<String,String> p = props();
    String url = g(p, "url", "jdbc.url");
    String user = g(p, "user", "username");
    String pass = g(p, "password");
    if (url == null) {
      String host = g(p, "host", "server");
      String port = g(p, "port");
      String db = g(p, "database", "db", "name");
      if (port == null || port.isEmpty()) port = "1433";
      url = "jdbc:sqlserver://" + host + ":" + port + ";databaseName=" + db
          + ";encrypt=false;trustServerCertificate=true";
    }
    String sql = Files.readString(Paths.get(args[0]));
    try (Connection c = DriverManager.getConnection(url, user, pass);
         Statement st = c.createStatement()) {
      boolean has = st.execute(sql);
      while (true) {
        if (has) {
          try (ResultSet rs = st.getResultSet()) {
            ResultSetMetaData md = rs.getMetaData();
            int n = md.getColumnCount();
            System.out.println("-- result --");
            while (rs.next()) {
              StringBuilder sb = new StringBuilder();
              for (int i = 1; i <= n; i++) {
                if (i > 1) sb.append(" | ");
                sb.append(md.getColumnLabel(i)).append("=").append(rs.getString(i));
              }
              System.out.println(sb);
            }
          }
        } else {
          int upd = st.getUpdateCount();
          if (upd == -1) break;
          System.out.println("updateCount=" + upd);
        }
        has = st.getMoreResults();
      }
    }
  }
}
`
  );
  const compile = spawnSync("javac", ["-encoding", "UTF-8", "-cp", jar, javaSrc], {
    encoding: "utf8",
  });
  if (compile.status !== 0) {
    throw new Error("javac failed: " + compile.stderr);
  }
  const run = spawnSync(
    "java",
    ["-cp", `/tmp:${jar}`, "S82CmmApply", sqlPath],
    { encoding: "utf8", maxBuffer: 20 * 1024 * 1024 }
  );
  process.stdout.write(run.stdout || "");
  process.stderr.write(run.stderr || "");
  if (run.status !== 0) throw new Error("java apply failed status=" + run.status);
}

const args = parseArgs(process.argv);
const xlsxPath = args.xlsx || XLSX_DEFAULT;
const rows = loadByDbt(xlsxPath);
const stats = {
  dbt: rows.length,
  curator: rows.filter((r) => r.curator).length,
  mery: rows.filter((r) => r.mery).length,
  cst: rows.filter((r) => r.cst).length,
};
console.log("xlsx", xlsxPath);
console.log("stats", stats);
const { sqlPath, cmmN, cstN } = writeSql(rows, __dirname);
console.log("sql", sqlPath, "cmmRows", cmmN, "cstRows", cstN);
if (args.dry) {
  console.log("DRY — SQL written, not applied");
  process.exit(0);
}
applyViaJdbc(sqlPath);
