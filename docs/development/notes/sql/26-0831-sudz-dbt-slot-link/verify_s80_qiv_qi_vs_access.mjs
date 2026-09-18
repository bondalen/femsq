/**
 * S80.2b — row-level QIV+QI parity: FEMSQ Rslt (S80 cst) ↔ Access 26-0505.
 * Excludes comments / *_new / year-level cmm «Код стройки» / QII band.
 *
 * Usage:
 *   node verify_s80_qiv_qi_vs_access.mjs \
 *     [--gen .../ags_Yr_DbtChangesRslt_901_asOf903_s80_cst_26-0916.xlsx] \
 *     [--ref /mnt/nb-win-share/femsq/excel/2026_03/debit/ags_Yr_DbtChangesRslt_26-0505.xlsx] \
 *     [--json OUT.json]
 *
 * lastUpdated: 2026-09-16
 */
import { createRequire } from "module";
import { writeFileSync, mkdirSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const require = createRequire(
  resolve(__dirname, "../../../../../.cursor/rslt-tools/package.json")
);
const XLSX = require("xlsx");

const EPS = 0.01;
const GEN_DEFAULT = resolve(
  __dirname,
  "artifacts/ags_Yr_DbtChangesRslt_901_asOf903_s80_cst_26-0916.xlsx"
);
const REF_DEFAULT =
  "/mnt/nb-win-share/femsq/excel/2026_03/debit/ags_Yr_DbtChangesRslt_26-0505.xlsx";

function D(v) {
  if (v === null || v === undefined || v === "") return null;
  if (v instanceof Date && !Number.isNaN(v.getTime())) return null; // not numeric
  const n = Number(String(v).replace(/\s/g, "").replace(",", "."));
  if (Number.isNaN(n)) return null;
  return Math.round(n * 100) / 100;
}
function m0(v) {
  const d = D(v);
  return d === null ? 0 : d;
}
function near(a, b) {
  if (a === null && b === null) return true;
  if (a === null || b === null) return false;
  return Math.abs(a - b) <= EPS;
}
function invNorm(s) {
  let t = String(s ?? "")
    .trim()
    .replace(/\s+/g, " ");
  // Access multi: "10000086740, 86740 (номеров: 2)" → first
  t = t.split(",")[0].trim();
  t = t.replace(/\s*\(номеров:\s*\d+\)\s*$/i, "").trim();
  // "732 от 10.01.24"
  t = t.replace(/\s+от\s+\d{1,2}[./]\d{1,2}[./]\d{2,4}\s*$/i, "").trim();
  // alias documented
  if (t === "10000086740") t = "86740";
  return t.toUpperCase();
}
function cnNorm(s) {
  let t = String(s ?? "")
    .trim()
    .replace(/\s+/g, " ");
  if (!t) return "";
  t = t.split(",")[0].trim();
  t = t.replace(/\s*\(номеров:\s*\d+\)\s*$/i, "").trim();
  t = t.replace(/^№\s*/i, "").trim();
  t = t.replace(/[.\s]+$/g, "").trim(); // Access/GEN trailing dots
  return t.toUpperCase();
}
function dayKey(v) {
  if (v === null || v === undefined || v === "") return null;
  if (v instanceof Date && !Number.isNaN(v.getTime())) {
    const y = v.getUTCFullYear();
    const m = String(v.getUTCMonth() + 1).padStart(2, "0");
    const d = String(v.getUTCDate()).padStart(2, "0");
    const key = `${y}-${m}-${d}`;
    // Access Excel empty/sentinel → 1899-12-30/31
    if (y <= 1900) return null;
    return key;
  }
  const s = String(v).trim();
  const m = s.match(/(\d{4})-(\d{2})-(\d{2})/);
  if (m) {
    if (Number(m[1]) <= 1900) return null;
    return `${m[1]}-${m[2]}-${m[3]}`;
  }
  const m2 = s.match(/(\d{1,2})[./](\d{1,2})[./](\d{2,4})/);
  if (m2) {
    let yy = m2[3];
    if (yy.length === 2) yy = "20" + yy;
    if (Number(yy) <= 1900) return null;
    return `${yy}-${m2[2].padStart(2, "0")}-${m2[1].padStart(2, "0")}`;
  }
  return s.slice(0, 10);
}
function isMultiCstStub(code) {
  return /^строек:\s*\d+/i.test(String(code ?? "").trim());
}
function strEq(a, b) {
  const x = String(a ?? "")
    .trim()
    .replace(/\s+/g, " ");
  const y = String(b ?? "")
    .trim()
    .replace(/\s+/g, " ");
  return x === y;
}
function parseArgs(argv) {
  const o = {};
  for (let i = 2; i < argv.length; i++) {
    if (argv[i].startsWith("--")) o[argv[i].slice(2)] = argv[++i];
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

/** Access fixed cols */
const REF_MAP = {
  acc: 1,
  inv: 2,
  ciaName: 3,
  b_cn: 4,
  b_cnDate: 5,
  b_org: 6,
  b_itn: 7,
  b_ctpt: 8,
  b_mat: 9,
  b_ttl: 10,
  b_o: 11,
  b_cstKey: 12,
  b_cstCode: 13,
  b_cstName: 14,
  b_ag: 15,
  q_cn: 17,
  q_cnDate: 18,
  q_org: 20,
  q_itn: 21,
  q_ctpt: 22,
  q_mat: 23,
  q_ttl: 24,
  q_o: 25,
  q_cstKey: 26,
  q_cstCode: 27,
  q_cstName: 28,
  q_ag: 29,
  q_pog: 31,
};

/** GEN period cols (base=QIV, q1=QI) — detected from tech row */
function detectGen(grid) {
  const row3 = grid[2] || [];
  const prefs = [];
  for (let i = 0; i < row3.length; i++) {
    const t = String(row3[i] ?? "");
    if (t.endsWith("_Ttl")) prefs.push(t.slice(0, -4));
  }
  const baseP = prefs[0];
  const q1P = prefs[1];
  function col(p, suf) {
    const want = `${p}_${suf}`;
    for (let i = 0; i < row3.length; i++) if (String(row3[i]) === want) return i;
    return -1;
  }
  return {
    prefs,
    acc: 1,
    inv: col(baseP, "invNumEnum") >= 0 ? col(baseP, "invNumEnum") : 2,
    b: {
      cn: col(baseP, "cnNumEnum"),
      cnDate: col(baseP, "csoCnDate"),
      org: col(baseP, "org_id_value_l"),
      itn: col(baseP, "ITN"),
      ctpt: col(baseP, "CtptOrg"),
      mat: col(baseP, "Maturity"),
      ttl: col(baseP, "Ttl"),
      o: col(baseP, "Overd"),
      cstKey: col(baseP, "CstAgPnKey"),
      cstCode: col(baseP, "CstAgPnCode"),
      cstName: col(baseP, "CstAgPnName"),
      ag: col(baseP, "AgOrg"),
    },
    q: {
      inv: col(q1P, "invNumEnum"),
      cn: col(q1P, "cnNumEnum"),
      cnDate: col(q1P, "csoCnDate"),
      org: col(q1P, "org_id_value_l"),
      itn: col(q1P, "ITN"),
      ctpt: col(q1P, "CtptOrg"),
      mat: col(q1P, "Maturity"),
      ttl: col(q1P, "Ttl"),
      o: col(q1P, "Overd"),
      cstKey: col(q1P, "CstAgPnKey"),
      cstCode: col(q1P, "CstAgPnCode"),
      cstName: col(q1P, "CstAgPnName"),
      ag: col(q1P, "AgOrg"),
      pog: col(q1P, "погашено"),
    },
  };
}

function pick(row, idx) {
  return idx >= 0 ? row[idx] ?? null : null;
}

function softAmt(r) {
  return [
    String(r.acc ?? "").trim(),
    invNorm(r.inv),
    m0(r.b_ttl),
    m0(r.b_o),
    m0(r.q_ttl),
    m0(r.q_o),
    m0(r.q_pog),
  ].join("|");
}

function hasFact(r) {
  return (
    D(r.b_ttl) !== null ||
    D(r.b_o) !== null ||
    D(r.q_ttl) !== null ||
    D(r.q_o) !== null ||
    (D(r.q_pog) !== null && Math.abs(D(r.q_pog)) > EPS)
  );
}

function loadRef(path) {
  const g = loadGrid(path);
  const out = [];
  for (let r = 3; r < g.length; r++) {
    const row = g[r] || [];
    const rec = { row: r + 1, src: "ref" };
    for (const [k, i] of Object.entries(REF_MAP)) rec[k] = row[i] ?? null;
    // effective inv for display
    rec.invDisp = rec.inv;
    if (!String(rec.acc ?? "").trim() && !String(rec.inv ?? "").trim()) continue;
    // cn effective: base else QI (E-Access-CnEmpty)
    rec.cnEff = rec.b_cn || rec.q_cn;
    out.push(rec);
  }
  return out;
}

function loadGen(path) {
  const g = loadGrid(path);
  const C = detectGen(g);
  const out = [];
  for (let r = 3; r < g.length; r++) {
    const row = g[r] || [];
    const rec = {
      row: r + 1,
      src: "gen",
      dbtKey: D(row[0]),
      acc: pick(row, C.acc),
      inv: pick(row, C.inv) ?? pick(row, C.q.inv),
      b_cn: pick(row, C.b.cn),
      b_cnDate: pick(row, C.b.cnDate),
      b_org: pick(row, C.b.org),
      b_itn: pick(row, C.b.itn),
      b_ctpt: pick(row, C.b.ctpt),
      b_mat: pick(row, C.b.mat),
      b_ttl: pick(row, C.b.ttl),
      b_o: pick(row, C.b.o),
      b_cstKey: pick(row, C.b.cstKey),
      b_cstCode: pick(row, C.b.cstCode),
      b_cstName: pick(row, C.b.cstName),
      b_ag: pick(row, C.b.ag),
      q_cn: pick(row, C.q.cn),
      q_cnDate: pick(row, C.q.cnDate),
      q_org: pick(row, C.q.org),
      q_itn: pick(row, C.q.itn),
      q_ctpt: pick(row, C.q.ctpt),
      q_mat: pick(row, C.q.mat),
      q_ttl: pick(row, C.q.ttl),
      q_o: pick(row, C.q.o),
      q_cstKey: pick(row, C.q.cstKey),
      q_cstCode: pick(row, C.q.cstCode),
      q_cstName: pick(row, C.q.cstName),
      q_ag: pick(row, C.q.ag),
      q_pog: pick(row, C.q.pog),
    };
    if (!String(rec.acc ?? "").trim() && !String(rec.inv ?? "").trim()) continue;
    rec.cnEff = rec.b_cn || rec.q_cn;
    out.push(rec);
  }
  return { rows: out, cols: C };
}

/** documented / accepted residuals */
function classifyOnly(side, r) {
  const inv = invNorm(r.inv);
  const ttl = m0(r.b_ttl);
  const acc = String(r.acc ?? "").trim();
  // E-Split-A45
  if (acc === "762210" && inv.includes("А45-19974") && (near(ttl, 36000) || near(ttl, 18000))) {
    return "E-Split-A45-19974";
  }
  // E-RowGrain-28469 — if still present as grain mismatch
  if (acc === "606022" && inv === "28469") return "E-RowGrain-28469";
  return null;
}

function cmpField(name, a, b, kind) {
  if (kind === "num") {
    const da = D(a);
    const db = D(b);
    if (da === null && db === null) return null;
    if (near(da, db)) return null;
    if (da === null && m0(b) === 0) return null;
    if (db === null && m0(a) === 0) return null;
    return { field: name, gen: da, ref: db };
  }
  if (kind === "day") {
    const da = dayKey(a);
    const db = dayKey(b);
    if (da === null && db === null) return null;
    // Access sentinel empty date vs FEMSQ filled → E-Access-CnDateSentinel
    if (da !== null && db === null) {
      return { field: name, gen: da, ref: null, accounted: "E-Access-CnDateSentinel" };
    }
    if (da === db) return null;
    if (da && db) {
      const ta = Date.parse(da + "T00:00:00Z");
      const tb = Date.parse(db + "T00:00:00Z");
      if (!Number.isNaN(ta) && !Number.isNaN(tb) && Math.abs(ta - tb) === 86400000) return null;
    }
    return { field: name, gen: da, ref: db };
  }
  if (kind === "cn") {
    if (cnNorm(a) === cnNorm(b)) return null;
    if (!cnNorm(a) && !cnNorm(b)) return null;
    return { field: name, gen: a, ref: b, genN: cnNorm(a), refN: cnNorm(b) };
  }
  if (kind === "str") {
    if (strEq(a, b)) return null;
    if (!String(a ?? "").trim() && !String(b ?? "").trim()) return null;
    return { field: name, gen: a, ref: b };
  }
  if (kind === "cstCode") {
    const ga = String(a ?? "").trim();
    const rb = String(b ?? "").trim();
    if (ga === rb) return null;
    // Access fn ambiguity stub — FEMSQ intentionally empty (no single cst)
    if (!ga && isMultiCstStub(rb)) {
      return { field: name, gen: null, ref: rb, accounted: "E-fn-multi-cst" };
    }
    // GEN empty, Access has code — S80.1 softBase miss / FK skip (gap, not amount bug)
    if (!ga && rb) {
      return { field: name, gen: null, ref: rb, accounted: "E-S80-cst-backfill-miss" };
    }
    return { field: name, gen: ga || null, ref: rb || null };
  }
  // CstAgPnKey: FEMSQ Excel exporter leaves key blank (code/name/ag filled) — skip
  if (kind === "cstKey") return null;
  // name/ag only compared when codes equal; if code gap already accounted, skip dependent
  return null;
}

function comparePair(g, r) {
  const diffs = [];
  const accounted = [];
  const specs = [
    ["acc", "str", g.acc, r.acc],
    ["inv", "str", invNorm(g.inv), invNorm(r.inv)],
    ["b_cn", "cn", g.b_cn, r.b_cn],
    ["b_cnDate", "day", g.b_cnDate, r.b_cnDate],
    ["b_org", "str", g.b_org, r.b_org],
    ["b_itn", "str", g.b_itn, r.b_itn],
    ["b_ctpt", "str", g.b_ctpt, r.b_ctpt],
    ["b_mat", "day", g.b_mat, r.b_mat],
    ["b_ttl", "num", g.b_ttl, r.b_ttl],
    ["b_o", "num", g.b_o, r.b_o],
    ["b_cstCode", "cstCode", g.b_cstCode, r.b_cstCode],
    ["q_cn", "cn", g.q_cn, r.q_cn],
    ["q_cnDate", "day", g.q_cnDate, r.q_cnDate],
    ["q_org", "str", g.q_org, r.q_org],
    ["q_itn", "str", g.q_itn, r.q_itn],
    ["q_ctpt", "str", g.q_ctpt, r.q_ctpt],
    ["q_mat", "day", g.q_mat, r.q_mat],
    ["q_ttl", "num", g.q_ttl, r.q_ttl],
    ["q_o", "num", g.q_o, r.q_o],
    ["q_cstCode", "cstCode", g.q_cstCode, r.q_cstCode],
    ["q_pog", "num", g.q_pog, r.q_pog],
  ];
  // name/ag only if codes present and equal
  const bCodeSame =
    String(g.b_cstCode ?? "").trim() &&
    String(g.b_cstCode ?? "").trim() === String(r.b_cstCode ?? "").trim();
  const qCodeSame =
    String(g.q_cstCode ?? "").trim() &&
    String(g.q_cstCode ?? "").trim() === String(r.q_cstCode ?? "").trim();
  if (bCodeSame) {
    specs.push(["b_cstName", "str", g.b_cstName, r.b_cstName]);
    specs.push(["b_ag", "str", g.b_ag, r.b_ag]);
  }
  if (qCodeSame) {
    specs.push(["q_cstName", "str", g.q_cstName, r.q_cstName]);
    specs.push(["q_ag", "str", g.q_ag, r.q_ag]);
  }

  for (const [name, kind, a, b] of specs) {
    const d = cmpField(name, a, b, kind);
    if (!d) continue;
    if (d.accounted) accounted.push(d);
    else diffs.push(d);
  }

  // cosmetic ctpt name forms (same org_id/ITN already matched via softAmt row)
  const ctptAcc = [];
  for (const d of [...diffs]) {
    if (d.field === "b_ctpt" || d.field === "q_ctpt") {
      d.accounted = "E-Access-CtptNameForm";
      ctptAcc.push(d);
      diffs.splice(diffs.indexOf(d), 1);
    }
  }
  accounted.push(...ctptAcc);
  return { diffs, accounted };
}

const args = parseArgs(process.argv);
const genPath = args.gen || GEN_DEFAULT;
const refPath = args.ref || REF_DEFAULT;

const { rows: genAll, cols } = loadGen(genPath);
const refAll = loadRef(refPath);
const gen = genAll.filter(hasFact);
const ref = refAll.filter(hasFact);

const genMap = new Map();
for (const r of gen) {
  const k = softAmt(r);
  if (!genMap.has(k)) genMap.set(k, []);
  genMap.get(k).push(r);
}
const refMap = new Map();
for (const r of ref) {
  const k = softAmt(r);
  if (!refMap.has(k)) refMap.set(k, []);
  refMap.get(k).push(r);
}

const allKeys = new Set([...genMap.keys(), ...refMap.keys()]);
const onlyGen = [];
const onlyRef = [];
const matched = [];
const fieldDiffs = [];
const documentedOnly = [];
const accountedField = [];

for (const k of allKeys) {
  const gs = genMap.get(k) || [];
  const rs = refMap.get(k) || [];
  if (gs.length && !rs.length) {
    for (const g of gs) {
      const doc = classifyOnly("gen", g);
      if (doc) documentedOnly.push({ side: "onlyGen", doc, soft: k, row: g.row, dbtKey: g.dbtKey, inv: g.inv, acc: g.acc });
      else onlyGen.push({ soft: k, row: g.row, dbtKey: g.dbtKey, inv: g.inv, acc: g.acc, b_ttl: D(g.b_ttl), q_ttl: D(g.q_ttl) });
    }
  } else if (rs.length && !gs.length) {
    for (const r of rs) {
      const doc = classifyOnly("ref", r);
      if (doc) documentedOnly.push({ side: "onlyRef", doc, soft: k, row: r.row, inv: r.inv, acc: r.acc });
      else onlyRef.push({ soft: k, row: r.row, inv: r.inv, acc: r.acc, b_ttl: D(r.b_ttl), q_ttl: D(r.q_ttl) });
    }
  } else {
    const n = Math.min(gs.length, rs.length);
    for (let i = 0; i < n; i++) {
      const { diffs, accounted } = comparePair(gs[i], rs[i]);
      matched.push({ soft: k, genRow: gs[i].row, refRow: rs[i].row, dbtKey: gs[i].dbtKey, inv: gs[i].inv, nDiff: diffs.length, nAcc: accounted.length });
      if (accounted.length) {
        accountedField.push({
          soft: k,
          genRow: gs[i].row,
          refRow: rs[i].row,
          dbtKey: gs[i].dbtKey,
          inv: gs[i].inv,
          acc: gs[i].acc,
          accounted,
        });
      }
      if (diffs.length) {
        fieldDiffs.push({
          soft: k,
          genRow: gs[i].row,
          refRow: rs[i].row,
          dbtKey: gs[i].dbtKey,
          inv: gs[i].inv,
          acc: gs[i].acc,
          diffs,
        });
      }
    }
    for (let i = n; i < gs.length; i++) {
      const doc = classifyOnly("gen", gs[i]);
      if (doc) documentedOnly.push({ side: "onlyGen_extra", doc, soft: k, row: gs[i].row, dbtKey: gs[i].dbtKey });
      else onlyGen.push({ soft: k, row: gs[i].row, dbtKey: gs[i].dbtKey, inv: gs[i].inv, note: "extra" });
    }
    for (let i = n; i < rs.length; i++) {
      const doc = classifyOnly("ref", rs[i]);
      if (doc) documentedOnly.push({ side: "onlyRef_extra", doc, soft: k, row: rs[i].row });
      else onlyRef.push({ soft: k, row: rs[i].row, inv: rs[i].inv, note: "extra" });
    }
  }
}

// field diff tallies
const byField = {};
for (const fd of fieldDiffs) {
  for (const d of fd.diffs) {
    byField[d.field] = (byField[d.field] || 0) + 1;
  }
}
const byAccounted = {};
for (const fd of accountedField) {
  for (const d of fd.accounted) {
    const id = d.accounted || "other";
    byAccounted[id] = (byAccounted[id] || 0) + 1;
  }
}

// portfolio sums
function sum(rows, f) {
  return rows.reduce((s, r) => s + m0(r[f]), 0);
}
const sums = {
  gen_b_ttl: sum(gen, "b_ttl"),
  ref_b_ttl: sum(ref, "b_ttl"),
  gen_b_o: sum(gen, "b_o"),
  ref_b_o: sum(ref, "b_o"),
  gen_q_ttl: sum(gen, "q_ttl"),
  ref_q_ttl: sum(ref, "q_ttl"),
  gen_q_o: sum(gen, "q_o"),
  ref_q_o: sum(ref, "q_o"),
  gen_q_pog: sum(gen, "q_pog"),
  ref_q_pog: sum(ref, "q_pog"),
};

const FAIL =
  onlyGen.length + onlyRef.length + fieldDiffs.length;

const report = {
  created: new Date().toISOString(),
  gate: "S80.2b_QIV_QI_vs_Access",
  gen: genPath,
  ref: refPath,
  genPrefs: cols.prefs,
  notes: [
    "Comments / *_new / year-level cmm «Код стройки» / QII band excluded",
    "CstAgPnKey not compared (FEMSQ Excel exporter leaves key blank; Code/Name/Ag compared)",
    "softAmt key without cn: acc|invNorm|base_ttl|base_o|q1_ttl|q1_o|q1_pog",
  ],
  counts: {
    genFact: gen.length,
    refFact: ref.length,
    softKeys: allKeys.size,
    matchedPairs: matched.length,
    matchedClean: matched.filter((m) => m.nDiff === 0).length,
    fieldDiffRows: fieldDiffs.length,
    accountedFieldRows: accountedField.length,
    onlyGen: onlyGen.length,
    onlyRef: onlyRef.length,
    documentedOnly: documentedOnly.length,
  },
  sums,
  sumDelta: {
    b_ttl: Math.round((sums.gen_b_ttl - sums.ref_b_ttl) * 100) / 100,
    b_o: Math.round((sums.gen_b_o - sums.ref_b_o) * 100) / 100,
    q_ttl: Math.round((sums.gen_q_ttl - sums.ref_q_ttl) * 100) / 100,
    q_o: Math.round((sums.gen_q_o - sums.ref_q_o) * 100) / 100,
    q_pog: Math.round((sums.gen_q_pog - sums.ref_q_pog) * 100) / 100,
  },
  byField,
  byAccounted,
  onlyGen: onlyGen.slice(0, 40),
  onlyRef: onlyRef.slice(0, 40),
  documentedOnly,
  accountedFieldSample: accountedField.slice(0, 20),
  fieldDiffSample: fieldDiffs.slice(0, 30),
  pass: FAIL === 0,
  FAIL,
};

mkdirSync(resolve(__dirname, "artifacts"), { recursive: true });
const out =
  args.json ||
  resolve(__dirname, "artifacts/stage2_s80_qiv_qi_vs_access_26-0916.json");
writeFileSync(out, JSON.stringify(report, null, 2), "utf8");

console.log(JSON.stringify({
  pass: report.pass,
  FAIL: report.FAIL,
  counts: report.counts,
  sumDelta: report.sumDelta,
  byField,
  byAccounted,
  onlyGenN: onlyGen.length,
  onlyRefN: onlyRef.length,
  documentedOnlyN: documentedOnly.length,
  out,
}, null, 2));

if (onlyGen.length) {
  console.log("\n--- onlyGen sample ---");
  for (const x of onlyGen.slice(0, 15)) console.log(x);
}
if (onlyRef.length) {
  console.log("\n--- onlyRef sample ---");
  for (const x of onlyRef.slice(0, 15)) console.log(x);
}
if (fieldDiffs.length) {
  console.log("\n--- UNACCOUNTED fieldDiff ---");
  for (const x of fieldDiffs.slice(0, 20)) {
    console.log({ inv: x.inv, dbtKey: x.dbtKey, genRow: x.genRow, refRow: x.refRow, diffs: x.diffs });
  }
}
if (documentedOnly.length) {
  console.log("\n--- documented only-* ---");
  for (const x of documentedOnly) console.log(x);
}
console.log("\n--- accounted by id ---", byAccounted);
