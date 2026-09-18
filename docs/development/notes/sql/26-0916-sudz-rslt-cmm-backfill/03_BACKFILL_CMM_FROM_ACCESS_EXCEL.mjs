/**
 * S81.1 — DEV backfill cnInvCmm / cnInvCmmCst from Access Rslt Excel
 * (куратор / мероприятия / год. код стройки → yr_CmmGr; *_new → yr_CmmGr_New).
 *
 * Match: softBase → softQi → invAcc (GEN inv = base C or QI Q), same as S80.
 * Target group: sudz.yr.yr_CmmGr / yr_CmmGr_New for yr=901 (903 / 904).
 * Join key for Rslt exporter: cnicInvAccnt / ciccInvAccnt = dbtKey (+ cnicDbt/ciccDbt).
 *
 * Usage:
 *   node 03_BACKFILL_CMM_FROM_ACCESS_EXCEL.mjs [--dry] [--json OUT.json]
 *
 * lastUpdated: 2026-09-16
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

const REF_DEFAULT =
  "/mnt/nb-win-share/femsq/excel/2026_03/debit/ags_Yr_DbtChangesRslt_26-0505.xlsx";
const GEN_DEFAULT = resolve(
  __dirname,
  "../26-0831-sudz-dbt-slot-link/artifacts/ags_Yr_DbtChangesRslt_901_asOf903_s80_cst_final_26-0916.xlsx"
);

const YR_KEY = 901;
const TYPE_MERY = 1;
const TYPE_CURATOR = 8;
const CICC_TYPE_CST = 2; // «Код стройки» (старый)
const CICC_TYPE_CST_NEW = 1; // «Код стройки новый»

const EPS = 0.01;
function D(v) {
  if (v === null || v === undefined || v === "") return null;
  const n = Number(String(v).replace(/\s/g, "").replace(",", "."));
  if (Number.isNaN(n)) return null;
  return Math.round(n * 100) / 100;
}
function m0(v) {
  const d = D(v);
  return d === null ? 0 : d;
}
function invNorm(s) {
  let t = String(s ?? "")
    .trim()
    .replace(/\s+/g, " ");
  const cut = t.split(",")[0].trim();
  t = cut.replace(/\s*\(номеров:\s*\d+\)\s*$/i, "").trim();
  if (t === "10000086740") t = "86740";
  return t.toUpperCase();
}
function softBase(acc, inv, ttl, o) {
  return [String(acc ?? "").trim(), invNorm(inv), m0(ttl), m0(o)].join("|");
}
function softQi(acc, inv, bTtl, bO, qTtl, qO) {
  return [
    String(acc ?? "").trim(),
    invNorm(inv),
    m0(bTtl),
    m0(bO),
    m0(qTtl),
    m0(qO),
  ].join("|");
}
function rowInv(row) {
  const b = String(row?.[2] ?? "").trim();
  if (b) return b;
  return String(row?.[16] ?? "").trim();
}
function txt(v) {
  if (v === null || v === undefined) return null;
  const s = String(v).trim();
  return s === "" ? null : s;
}
function parseArgs(argv) {
  const o = { dry: false };
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === "--dry") o.dry = true;
    else if (argv[i].startsWith("--")) o[argv[i].slice(2)] = argv[++i];
  }
  return o;
}
function loadGrid(path) {
  const wb = XLSX.readFile(path, { cellDates: true, raw: true });
  return XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]], {
    header: 1,
    defval: null,
    raw: true,
  });
}
function pushMap(map, key, rec) {
  if (!map.has(key)) map.set(key, []);
  map.get(key).push(rec);
}

/**
 * Access 26-0505 (2 bands): year cmm at 32/33/34, *_new at 36/37/38.
 * Detect by header text so QII GEN is not required for REF.
 */
function detectRefCmm(g) {
  const h1 = g[1] || [];
  const h2 = g[2] || [];
  const cell = (i) => String(h1[i] ?? h2[i] ?? "").trim();
  const findExact = (re) => {
    for (let i = 0; i < Math.max(h1.length, h2.length); i++) {
      if (re.test(cell(i))) return i;
    }
    return null;
  };
  const findIncludes = (re) => {
    for (let i = 0; i < Math.max(h1.length, h2.length); i++) {
      if (re.test(cell(i))) return i;
    }
    return null;
  };
  // Year-level «Код стройки» — без префикса квартала (не col 13/27).
  const cst =
    findExact(/^Код стройки$/i) ??
    findIncludes(/^Код стройки$/i) ??
    34;
  return {
    curator: findIncludes(/^Куратор от Управления$/i) ?? 32,
    mery:
      findIncludes(/^Мероприятия по погашению дебиторской задолженности$/i) ??
      33,
    cst,
    curatorNew: findIncludes(/Куратор.*новый/i) ?? 36,
    meryNew: findIncludes(/Мероприятия.*новый/i) ?? 37,
    cstNew: findIncludes(/Код стройки.*новый|cstAgPn_new/i) ?? 38,
  };
}

function buildPairs(refPath, genPath) {
  const gR = loadGrid(refPath);
  const gG = loadGrid(genPath);
  const C = detectRefCmm(gR);
  const genBySoft = new Map();
  const genBySoftQi = new Map();
  const genByInvAcc = new Map();
  for (let r = 3; r < gG.length; r++) {
    const row = gG[r] || [];
    const dbt = D(row[0]);
    if (dbt === null) continue;
    const inv = rowInv(row);
    const rec = { row: r + 1, dbtKey: dbt, acc: row[1], inv };
    pushMap(genBySoft, softBase(row[1], inv, row[10], row[11]), rec);
    pushMap(
      genBySoftQi,
      softQi(row[1], inv, row[10], row[11], row[24], row[25]),
      rec
    );
    const ik = [String(row[1] ?? "").trim(), invNorm(inv)].join("|");
    if (invNorm(inv)) pushMap(genByInvAcc, ik, rec);
  }

  const pairs = [];
  const stats = {
    withCmm: 0,
    softMatch: 0,
    softQiMatch: 0,
    invAccMatch: 0,
    miss: 0,
    amb: 0,
    nCurator: 0,
    nMery: 0,
    nCst: 0,
    nCuratorNew: 0,
    nMeryNew: 0,
    nCstNew: 0,
  };

  for (let r = 3; r < gR.length; r++) {
    const row = gR[r] || [];
    const inv = rowInv(row);
    if (!String(row[1] ?? "").trim() && !inv) continue;
    const curator = txt(row[C.curator]);
    const mery = txt(row[C.mery]);
    const cst = txt(row[C.cst]);
    const curatorNew = txt(row[C.curatorNew]);
    const meryNew = txt(row[C.meryNew]);
    const cstNew = txt(row[C.cstNew]);
    if (!curator && !mery && !cst && !curatorNew && !meryNew && !cstNew) continue;
    stats.withCmm++;
    if (curator) stats.nCurator++;
    if (mery) stats.nMery++;
    if (cst) stats.nCst++;
    if (curatorNew) stats.nCuratorNew++;
    if (meryNew) stats.nMeryNew++;
    if (cstNew) stats.nCstNew++;

    const k = softBase(row[1], inv, row[10], row[11]);
    let hits = genBySoft.get(k) || [];
    let how = "softBase";
    if (hits.length !== 1) {
      const kq = softQi(row[1], inv, row[10], row[11], row[24], row[25]);
      const qiHits = genBySoftQi.get(kq) || [];
      if (qiHits.length === 1) {
        hits = qiHits;
        how = "softQi";
      } else if (hits.length === 0) {
        hits = qiHits;
        how = "softQi";
      }
    }
    if (hits.length !== 1) {
      const ik = [String(row[1] ?? "").trim(), invNorm(inv)].join("|");
      const invHits = genByInvAcc.get(ik) || [];
      if (invHits.length === 1) {
        hits = invHits;
        how = "invAcc";
      } else if (hits.length === 0) {
        hits = invHits;
        how = "invAcc";
      }
    }
    if (hits.length === 1) {
      if (how === "softBase") stats.softMatch++;
      else if (how === "softQi") stats.softQiMatch++;
      else stats.invAccMatch++;
      pairs.push({
        dbtKey: hits[0].dbtKey,
        how,
        acc: String(row[1] ?? "").trim(),
        inv,
        accessRow: r + 1,
        genRow: hits[0].row,
        curator,
        mery,
        cst,
        curatorNew,
        meryNew,
        cstNew,
      });
    } else if (hits.length > 1) stats.amb++;
    else stats.miss++;
  }
  return { pairs, stats, cols: C };
}

function sqlLiteral(s) {
  return "N'" + String(s).replace(/'/g, "''") + "'";
}

function writeSql(pairs, outDir) {
  const sqlPath = resolve(outDir, "artifacts/stage2_s81_cmm_from_access_26-0916.sql");
  const lines = [
    "/* S81.1 generated — DEV Access Excel → cnInvCmm / cnInvCmmCst */",
    "SET NOCOUNT ON;",
    "SET XACT_ABORT ON;",
    "BEGIN TRAN;",
    "",
    `DECLARE @yr int = ${YR_KEY};`,
    "DECLARE @grOld int = (SELECT yr_CmmGr FROM sudz.yr WHERE yr_key = @yr);",
    "DECLARE @grNew int = (SELECT yr_CmmGr_New FROM sudz.yr WHERE yr_key = @yr);",
    "IF @grOld IS NULL THROW 50001, N'yr_CmmGr is NULL', 1;",
    "IF @grNew IS NULL THROW 50002, N'yr_CmmGr_New is NULL', 1;",
    "PRINT N'grOld=' + CONVERT(varchar(20), @grOld) + N' grNew=' + CONVERT(varchar(20), @grNew);",
    "",
    "IF OBJECT_ID('tempdb..#cmm') IS NOT NULL DROP TABLE #cmm;",
    "CREATE TABLE #cmm (",
    "  dbtKey int NOT NULL,",
    "  isNew bit NOT NULL,",
    "  cnicType int NOT NULL,",
    "  cnicText nvarchar(max) NOT NULL",
    ");",
    "IF OBJECT_ID('tempdb..#cst') IS NOT NULL DROP TABLE #cst;",
    "CREATE TABLE #cst (",
    "  dbtKey int NOT NULL,",
    "  isNew bit NOT NULL,",
    "  code nvarchar(64) NOT NULL",
    ");",
  ];

  const cmmRows = [];
  const cstRows = [];
  for (const p of pairs) {
    if (p.curator) cmmRows.push([p.dbtKey, 0, TYPE_CURATOR, p.curator]);
    if (p.mery) cmmRows.push([p.dbtKey, 0, TYPE_MERY, p.mery]);
    if (p.curatorNew) cmmRows.push([p.dbtKey, 1, TYPE_CURATOR, p.curatorNew]);
    if (p.meryNew) cmmRows.push([p.dbtKey, 1, TYPE_MERY, p.meryNew]);
    if (p.cst) cstRows.push([p.dbtKey, 0, p.cst]);
    if (p.cstNew) cstRows.push([p.dbtKey, 1, p.cstNew]);
  }

  const CHUNK = 100;
  for (let i = 0; i < cmmRows.length; i += CHUNK) {
    const chunk = cmmRows.slice(i, i + CHUNK);
    lines.push(
      "INSERT INTO #cmm (dbtKey, isNew, cnicType, cnicText) VALUES\n" +
        chunk
          .map(
            ([d, n, t, text]) =>
              `(${d},${n},${t},${sqlLiteral(text)})`
          )
          .join(",\n") +
        ";"
    );
  }
  for (let i = 0; i < cstRows.length; i += CHUNK) {
    const chunk = cstRows.slice(i, i + CHUNK);
    lines.push(
      "INSERT INTO #cst (dbtKey, isNew, code) VALUES\n" +
        chunk.map(([d, n, c]) => `(${d},${n},${sqlLiteral(c)})`).join(",\n") +
        ";"
    );
  }

  lines.push(`
-- drop unknown dbt
DELETE c FROM #cmm c WHERE NOT EXISTS (SELECT 1 FROM sudz.Dbt d WHERE d.dbtKey = c.dbtKey);
DELETE c FROM #cst c WHERE NOT EXISTS (SELECT 1 FROM sudz.Dbt d WHERE d.dbtKey = c.dbtKey);

PRINT N'#cmm after FK:';
SELECT isNew, cnicType, COUNT(*) n FROM #cmm GROUP BY isNew, cnicType ORDER BY 1,2;
PRINT N'#cst after FK:';
SELECT isNew, COUNT(*) n FROM #cst GROUP BY isNew ORDER BY 1;

-- resolve codes → cstapKey
IF OBJECT_ID('tempdb..#cstR') IS NOT NULL DROP TABLE #cstR;
SELECT c.dbtKey, c.isNew, c.code,
       pn.cstapKey,
       CASE WHEN c.isNew = 1 THEN ${CICC_TYPE_CST_NEW} ELSE ${CICC_TYPE_CST} END AS ciccType
INTO #cstR
FROM #cst c
OUTER APPLY (
  SELECT TOP (1) pn.cstapKey
  FROM ags.cstAgPn pn
  WHERE pn.cstapIpgPnN COLLATE DATABASE_DEFAULT = c.code COLLATE DATABASE_DEFAULT
  ORDER BY pn.cstapKey
) pn;

PRINT N'cst unresolved:';
SELECT COUNT(*) n FROM #cstR WHERE cstapKey IS NULL;
DELETE FROM #cstR WHERE cstapKey IS NULL;

-- upsert cnInvCmm (old + new groups)
;WITH src AS (
  SELECT c.dbtKey, c.cnicType, c.cnicText,
         CASE WHEN c.isNew = 1 THEN @grNew ELSE @grOld END AS cnicGroup
  FROM #cmm c
)
MERGE sudz.cnInvCmm AS t
USING src AS s
ON t.cnicGroup = s.cnicGroup AND t.cnicInvAccnt = s.dbtKey AND t.cnicType = s.cnicType
WHEN MATCHED THEN UPDATE SET
  t.cnicText = s.cnicText,
  t.cnicDbt = s.dbtKey
WHEN NOT MATCHED THEN INSERT (cnicType, cnicGroup, cnicInv, cnicText, cnicInvAccnt, cnicDbt)
  VALUES (s.cnicType, s.cnicGroup, NULL, s.cnicText, s.dbtKey, s.dbtKey);

PRINT N'cnInvCmm MERGE done';

;WITH src AS (
  SELECT r.dbtKey, r.ciccType, r.cstapKey,
         CASE WHEN r.isNew = 1 THEN @grNew ELSE @grOld END AS ciccCmmGr
  FROM #cstR r
)
MERGE sudz.cnInvCmmCst AS t
USING src AS s
ON t.ciccCmmGr = s.ciccCmmGr AND t.ciccInvAccnt = s.dbtKey AND t.ciccType = s.ciccType
WHEN MATCHED THEN UPDATE SET
  t.ciccCstAgPn = s.cstapKey,
  t.ciccDbt = s.dbtKey
WHEN NOT MATCHED THEN INSERT (ciccCmmGr, ciccType, ciccCstAgPn, ciccInvAccnt, ciccDbt)
  VALUES (s.ciccCmmGr, s.ciccType, s.cstapKey, s.dbtKey, s.dbtKey);

PRINT N'cnInvCmmCst MERGE done';

SELECT 'cnInvCmm' AS t, cnicGroup, cnicType, COUNT(*) n
FROM sudz.cnInvCmm WHERE cnicGroup IN (@grOld, @grNew)
GROUP BY cnicGroup, cnicType ORDER BY 2,3;
SELECT 'cnInvCmmCst' AS t, ciccCmmGr, ciccType, COUNT(*) n
FROM sudz.cnInvCmmCst WHERE ciccCmmGr IN (@grOld, @grNew)
GROUP BY ciccCmmGr, ciccType ORDER BY 2,3;

COMMIT TRAN;
PRINT N'COMMITTED S81.1';
`);

  writeFileSync(sqlPath, lines.join("\n"), "utf8");
  return {
    sqlPath,
    cmmN: cmmRows.length,
    cstN: cstRows.length,
  };
}

function applyViaJdbc(sqlPath) {
  const jar =
    process.env.MSSQL_JDBC_JAR ||
    resolve(
      homedir(),
      ".m2/repository/com/microsoft/sqlserver/mssql-jdbc/13.2.0.jre11/mssql-jdbc-13.2.0.jre11.jar"
    );
  if (!existsSync(jar)) throw new Error("mssql-jdbc jar not found: " + jar);

  const javaSrc = resolve("/tmp/S81Apply.java");
  writeFileSync(
    javaSrc,
    `
import java.nio.file.*;
import java.sql.*;
import java.util.*;
public class S81Apply {
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
    String url = g(p, "url", "jdbc.url", "spring.datasource.url");
    String user = g(p, "user", "username", "jdbc.user", "spring.datasource.username");
    String pass = g(p, "password", "jdbc.password", "spring.datasource.password");
    if (url == null) {
      String host = g(p, "host", "server", "jdbc.host");
      String port = g(p, "port", "jdbc.port");
      String db = g(p, "database", "db", "jdbc.database", "name");
      if (host == null || db == null) throw new IllegalStateException("no jdbc url/host");
      if (port == null || port.isEmpty()) port = "1433";
      url = "jdbc:sqlserver://" + host + ":" + port + ";databaseName=" + db
          + ";encrypt=false;trustServerCertificate=true";
    }
    String sql = Files.readString(Paths.get(args[0]));
    try (Connection c = DriverManager.getConnection(url, user, pass);
         Statement st = c.createStatement()) {
      for (String batch : sql.split("(?m)^GO\\\\s*$")) {
        String b = batch.trim();
        if (b.isEmpty()) continue;
        boolean has = st.execute(b);
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
}
`,
    "utf8"
  );
  const compile = spawnSync("javac", ["-cp", jar, javaSrc], { encoding: "utf8" });
  if (compile.status !== 0) {
    throw new Error("javac failed: " + compile.stderr);
  }
  const run = spawnSync(
    "java",
    ["-cp", `/tmp:${jar}`, "S81Apply", sqlPath],
    { encoding: "utf8", maxBuffer: 20 * 1024 * 1024 }
  );
  process.stdout.write(run.stdout || "");
  process.stderr.write(run.stderr || "");
  if (run.status !== 0) throw new Error("java apply failed status=" + run.status);
}

const args = parseArgs(process.argv);
const refPath = args.ref || REF_DEFAULT;
const genPath = args.gen || GEN_DEFAULT;
const { pairs, stats, cols } = buildPairs(refPath, genPath);
mkdirSync(resolve(__dirname, "artifacts"), { recursive: true });
const jsonPath =
  args.json ||
  resolve(__dirname, "artifacts/stage2_s81_cmm_from_access_26-0916.json");
writeFileSync(
  jsonPath,
  JSON.stringify(
    {
      created: new Date().toISOString(),
      gate: "S81.1",
      ref: refPath,
      gen: genPath,
      cols,
      stats,
      pairsN: pairs.length,
      sample: pairs.slice(0, 15),
    },
    null,
    2
  ),
  "utf8"
);
console.log("stats", stats, "pairs", pairs.length, "cols", cols);
console.log("json", jsonPath);

const { sqlPath, cmmN, cstN } = writeSql(pairs, __dirname);
console.log("sql", sqlPath, "cmmRows", cmmN, "cstRows", cstN);

if (args.dry) {
  console.log("DRY — SQL written, not applied");
  process.exit(0);
}
applyViaJdbc(sqlPath);
