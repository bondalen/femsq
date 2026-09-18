/**
 * S80.1 — DEV backfill sudz.DbtUplCstAg from Access Rslt Excel when ags g_p
 * for 901/902/903 is missing (fnCiasDbtUplCst path empty).
 *
 * Match: softBase → softAmt (QI-only) → invAcc; GEN inv = base col C or QI col Q.
 * Insert: (dbtKey, 901, QIV CstAgPnKey), (dbtKey, 902, QI CstAgPnKey).
 * Carry: 902 → 903 where DbtValue@903 exists and duca@903 absent.
 *
 * Usage:
 *   node 03_BACKFILL_DbtUplCstAg_FROM_ACCESS_EXCEL.mjs [--dry] [--json OUT.json]
 *
 * Apply uses JDBC via inline Java (same ~/.femsq/database.properties as other tools).
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
  "../26-0831-sudz-dbt-slot-link/artifacts/ags_Yr_DbtChangesRslt_901_asOf903_s80_cst_26-0916.xlsx"
);

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
  return t.toUpperCase();
}
function softBase(acc, inv, ttl, o) {
  return [String(acc ?? "").trim(), invNorm(inv), m0(ttl), m0(o)].join("|");
}
/** Soft key with QI amounts — needed for QI-only rows (base inv/ttl empty on GEN).
 *  Omit погашено: asOf≥903 GEN packs QII into col 31, Access 26-0505 keeps погашено there. */
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
/** Base inv (col 2) or QI inv (col 16) — FEMSQ QI-only puts СФ in QI band. */
function rowInv(row) {
  const b = String(row?.[2] ?? "").trim();
  if (b) return b;
  return String(row?.[16] ?? "").trim();
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

function buildPairs(refPath, genPath) {
  const gR = loadGrid(refPath);
  const gG = loadGrid(genPath);
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
    withCst: 0,
    softMatch: 0,
    softQiMatch: 0,
    invAccMatch: 0,
    miss: 0,
    amb: 0,
    n901: 0,
    n902: 0,
  };

  for (let r = 3; r < gR.length; r++) {
    const row = gR[r] || [];
    const inv = rowInv(row);
    if (!String(row[1] ?? "").trim() && !inv) continue;
    const ck901 = D(row[12]);
    const ck902 = D(row[26]);
    if (ck901 === null && ck902 === null) continue;
    stats.withCst++;
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
      if (ck901 !== null) stats.n901++;
      if (ck902 !== null) stats.n902++;
      pairs.push({
        dbtKey: hits[0].dbtKey,
        cst901: ck901,
        cst902: ck902,
        how,
        acc: String(row[1] ?? "").trim(),
        inv,
        accessRow: r + 1,
        genRow: hits[0].row,
      });
    } else if (hits.length > 1) stats.amb++;
    else stats.miss++;
  }
  return { pairs, stats };
}

function writeSqlBatches(pairs, outDir) {
  const rows = [];
  for (const p of pairs) {
    if (p.cst901 !== null) rows.push([p.dbtKey, 901, p.cst901]);
    if (p.cst902 !== null) rows.push([p.dbtKey, 902, p.cst902]);
  }
  // dedupe (dbt,upl) keep last
  const map = new Map();
  for (const [d, u, c] of rows) map.set(`${d}|${u}`, [d, u, c]);
  const uniq = [...map.values()];

  const sqlPath = resolve(outDir, "artifacts/stage2_s80_dbtuplcstag_insert_26-0916.sql");
  const lines = [
    "/* S80.1 generated INSERT — DEV Access Excel backfill */",
    "SET NOCOUNT ON;",
    "SET XACT_ABORT ON;",
    "BEGIN TRAN;",
    "IF OBJECT_ID('tempdb..#s80') IS NOT NULL DROP TABLE #s80;",
    "CREATE TABLE #s80 (dbtKey int NOT NULL, upl int NOT NULL, cstapKey int NOT NULL);",
  ];
  const CHUNK = 200;
  for (let i = 0; i < uniq.length; i += CHUNK) {
    const chunk = uniq.slice(i, i + CHUNK);
    lines.push(
      "INSERT INTO #s80 (dbtKey, upl, cstapKey) VALUES\n" +
        chunk.map(([d, u, c]) => `(${d},${u},${c})`).join(",\n") +
        ";"
    );
  }
  lines.push(`
-- drop unknown FK targets
DELETE s FROM #s80 s
WHERE NOT EXISTS (SELECT 1 FROM sudz.Dbt d WHERE d.dbtKey = s.dbtKey)
   OR NOT EXISTS (SELECT 1 FROM sudz.cn_inv_dbt_upl u WHERE u.upl_key = s.upl)
   OR NOT EXISTS (SELECT 1 FROM ags.cstAgPn p WHERE p.cstapKey = s.cstapKey);

PRINT N'candidates after FK filter:';
SELECT upl, COUNT(*) n FROM #s80 GROUP BY upl ORDER BY upl;

INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn)
SELECT s.dbtKey, s.upl, s.cstapKey
FROM #s80 s
WHERE NOT EXISTS (
  SELECT 1 FROM sudz.DbtUplCstAg d
  WHERE d.ducaDbt = s.dbtKey AND d.ducaUpl = s.upl
);

PRINT N'inserted 901/902 = ' + CONVERT(varchar(20), @@ROWCOUNT);

-- carry 902 → 903 where Value@903 exists
INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn)
SELECT DISTINCT idd.iddDbt, 903, duca.ducaCstAgPn
FROM sudz.DbtValue dv
JOIN sudz.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
JOIN sudz.DbtUplCstAg duca ON duca.ducaDbt = idd.iddDbt AND duca.ducaUpl = 902
WHERE dv.dvUpl = 903
  AND idd.iddDbt IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sudz.DbtUplCstAg x
    WHERE x.ducaDbt = idd.iddDbt AND x.ducaUpl = 903
  );

PRINT N'inserted 903 carry = ' + CONVERT(varchar(20), @@ROWCOUNT);

SELECT ducaUpl, COUNT(*) n FROM sudz.DbtUplCstAg
WHERE ducaUpl IN (901,902,903) GROUP BY ducaUpl ORDER BY 1;

COMMIT TRAN;
PRINT N'COMMITTED S80.1';
`);
  writeFileSync(sqlPath, lines.join("\n"), "utf8");
  return { sqlPath, uniqN: uniq.length };
}

function applyViaJdbc(sqlPath) {
  const propsPath = resolve(homedir(), ".femsq/database.properties");
  if (!existsSync(propsPath)) throw new Error("no ~/.femsq/database.properties");
  const jar =
    process.env.MSSQL_JDBC_JAR ||
    resolve(
      homedir(),
      ".m2/repository/com/microsoft/sqlserver/mssql-jdbc/13.2.0.jre11/mssql-jdbc-13.2.0.jre11.jar"
    );
  if (!existsSync(jar)) throw new Error("mssql-jdbc jar not found: " + jar);

  const javaSrc = resolve("/tmp/S80Apply.java");
  writeFileSync(
    javaSrc,
    `
import java.nio.file.*;
import java.sql.*;
import java.util.*;
public class S80Apply {
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
      for (String batch : sql.split("(?m)^GO\\s*$")) {
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
    ["-cp", `/tmp:${jar}`, "S80Apply", sqlPath],
    { encoding: "utf8", maxBuffer: 20 * 1024 * 1024 }
  );
  process.stdout.write(run.stdout || "");
  process.stderr.write(run.stderr || "");
  if (run.status !== 0) throw new Error("java apply failed status=" + run.status);
}

const args = parseArgs(process.argv);
const refPath = args.ref || REF_DEFAULT;
const genPath = args.gen || GEN_DEFAULT;
const { pairs, stats } = buildPairs(refPath, genPath);
mkdirSync(resolve(__dirname, "artifacts"), { recursive: true });
const jsonPath =
  args.json ||
  resolve(__dirname, "artifacts/stage2_s80_dbtuplcstag_from_access_26-0916.json");
writeFileSync(
  jsonPath,
  JSON.stringify(
    {
      created: new Date().toISOString(),
      gate: "S80.1",
      ref: refPath,
      gen: genPath,
      stats,
      pairsN: pairs.length,
      sample: pairs.slice(0, 20),
    },
    null,
    2
  ),
  "utf8"
);
console.log("stats", stats, "pairs", pairs.length);
console.log("json", jsonPath);

const { sqlPath, uniqN } = writeSqlBatches(pairs, __dirname);
console.log("sql", sqlPath, "uniq inserts(pre-filter)", uniqN);

if (args.dry) {
  console.log("DRY — SQL written, not applied");
  process.exit(0);
}
applyViaJdbc(sqlPath);
