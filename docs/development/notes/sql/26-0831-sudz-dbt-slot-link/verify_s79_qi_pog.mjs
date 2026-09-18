#!/usr/bin/env node
/**
 * S79.1 — gate QI «погашено»: FEMSQ GEN ↔ Access 26-0505 (только строки с q1_pog≠∅).
 * S79.2 — регрессия QI asOf902 → asOf903 (колонки base/QI / q1_pog).
 *
 * Usage:
 *   node verify_s79_qi_pog.mjs \
 *     --ref /mnt/nb-win-share/femsq/excel/2026_03/debit/ags_Yr_DbtChangesRslt_26-0505.xlsx \
 *     --gen .../ags_Yr_DbtChangesRslt_901_asOf903_d4_post902_26-0916.xlsx \
 *     [--as902 .../ags_Yr_DbtChangesRslt_901_asOf902_s778_26-0915.xlsx] \
 *     [--json OUT.json]
 */
import { createRequire } from "module";
import { writeFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const require = createRequire(
  resolve(__dirname, "../../../../../.cursor/rslt-tools/package.json")
);
const XLSX = require("xlsx");

const REF_COLS = {
  acc: 1, // 0-based within row array = Excel col B → index 1
  inv: 2,
  cn: 4,
  base_ttl: 10,
  base_o: 11,
  q1_ttl: 24,
  q1_o: 25,
  q1_pog: 31,
};

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
  // Access multi-num: "10000086740, 86740 (номеров: 2)" → первый сегмент
  const cut = t.split(",")[0].trim();
  t = cut.replace(/\s*\(номеров:\s*\d+\)\s*$/i, "").trim();
  return t.toUpperCase();
}

function hasQiOrBaseFact(r) {
  return (
    D(r.base_ttl) !== null ||
    D(r.base_o) !== null ||
    D(r.q1_ttl) !== null ||
    D(r.q1_o) !== null ||
    (D(r.q1_pog) !== null && D(r.q1_pog) !== 0)
  );
}

function loadSheet(path) {
  const wb = XLSX.readFile(path, { cellDates: true, raw: true });
  const ws = wb.Sheets[wb.SheetNames[0]];
  return XLSX.utils.sheet_to_json(ws, { header: 1, defval: null, raw: true });
}

/** Access REF: fixed columns; data from row 4 (1-based) → index 3 */
function loadRefRows(path) {
  const grid = loadSheet(path);
  const out = [];
  for (let r = 3; r < grid.length; r++) {
    const row = grid[r] || [];
    const rec = { row: r + 1 };
    for (const [k, i] of Object.entries(REF_COLS)) {
      rec[k] = row[i] ?? null;
    }
    if (!String(rec.acc ?? "").trim() && !String(rec.inv ?? "").trim()) continue;
    out.push(rec);
  }
  return out;
}

/** FEMSQ GEN: detect columns from row3 (tech names) */
function detectGenCols(grid) {
  const row3 = grid[2] || [];
  const ttlPrefs = [];
  const bySuffix = new Map();
  for (let i = 0; i < row3.length; i++) {
    const v = row3[i];
    if (v == null || v === "") continue;
    const tech = String(v);
    if (tech.endsWith("_Ttl")) {
      ttlPrefs.push({ i, p: tech.slice(0, -4) });
    }
    for (const suf of ["_Ttl", "_Overd", "_погашено"]) {
      if (tech.endsWith(suf)) bySuffix.set(tech, i);
    }
  }
  if (ttlPrefs.length < 2) {
    throw new Error(`GEN: need >=2 *_Ttl in row3, got ${ttlPrefs.length}`);
  }
  const pick = (prefix, suf) => {
    const key = prefix + suf;
    if (!bySuffix.has(key)) throw new Error(`GEN column missing: ${key}`);
    return bySuffix.get(key);
  };
  let cnCol = 4;
  for (let i = 0; i < row3.length; i++) {
    if (row3[i] && String(row3[i]).endsWith("_cnNumEnum")) {
      cnCol = i;
      break;
    }
  }
  const base_p = ttlPrefs[0].p;
  const q1_p = ttlPrefs[1].p;
  return {
    acc: 1,
    inv: 2,
    cn: cnCol,
    base_ttl: pick(base_p, "_Ttl"),
    base_o: pick(base_p, "_Overd"),
    q1_ttl: pick(q1_p, "_Ttl"),
    q1_o: pick(q1_p, "_Overd"),
    q1_pog: pick(q1_p, "_погашено"),
    prefixes: { base: base_p, q1: q1_p },
  };
}

function loadGenRows(path) {
  const grid = loadSheet(path);
  const cols = detectGenCols(grid);
  const out = [];
  for (let r = 3; r < grid.length; r++) {
    const row = grid[r] || [];
    const rec = { row: r + 1 };
    for (const [k, i] of Object.entries(cols)) {
      if (k === "prefixes") continue;
      rec[k] = row[i] ?? null;
    }
    if (!String(rec.acc ?? "").trim() && !String(rec.inv ?? "").trim()) continue;
    out.push(rec);
  }
  return { rows: out, cols };
}

/** Soft key S79.1: acc|invNorm|base_o|q1_o|q1_pog (без cn; base/q1 ttl optional for pog gate) */
function pogKey(r) {
  return [
    String(r.acc ?? "").trim(),
    invNorm(r.inv),
    D(r.base_o),
    D(r.q1_o),
    D(r.q1_pog),
  ].join("|");
}

function softAmtKey(r) {
  return [
    String(r.acc ?? "").trim(),
    invNorm(r.inv),
    D(r.base_ttl),
    D(r.base_o),
    D(r.q1_ttl),
    D(r.q1_o),
    D(r.q1_pog),
  ].join("|");
}

function isPogRow(r) {
  const p = D(r.q1_pog);
  return p !== null && p !== 0;
}

function countKeys(rows, keyFn) {
  const c = new Map();
  for (const r of rows) {
    const k = keyFn(r);
    c.set(k, (c.get(k) || 0) + 1);
  }
  return c;
}

function multisetDiff(a, b) {
  const onlyA = [];
  const onlyB = [];
  const keys = new Set([...a.keys(), ...b.keys()]);
  for (const k of keys) {
    const ca = a.get(k) || 0;
    const cb = b.get(k) || 0;
    if (ca > cb) onlyA.push({ key: k, n: ca - cb });
    if (cb > ca) onlyB.push({ key: k, n: cb - ca });
  }
  return { onlyA, onlyB };
}

/** Whitelist documented Access/FEMSQ inv aliases (реестр ошибок эталона). */
function softAmtWhitelistPair(refKey, genKey) {
  // softAmt: acc|inv|base_ttl|base_o|q1_ttl|q1_o|q1_pog
  const rp = refKey.split("|");
  const gp = genKey.split("|");
  if (rp.length < 7 || gp.length < 7) return false;
  if (rp[0] !== gp[0]) return false;
  for (let i = 2; i < 7; i++) {
    if (rp[i] !== gp[i]) return false;
  }
  const ri = rp[1];
  const gi = gp[1];
  // E-Access / alias: Access «10000086740…» ↔ FEMSQ «86740» (реестр E-Access-Missing-86740*)
  if (ri === "10000086740" && gi === "86740") return true;
  if (ri === "86740" && gi === "10000086740") return true;
  // E-Split-A45
  if (
    (ri.includes("А45-19974") || ri.includes("A45-19974")) &&
    (gi.includes("А45-19974") || gi.includes("A45-19974"))
  ) {
    const btR = Number(rp[2]);
    const btG = Number(gp[2]);
    if ((btR === 36000 && btG === 18000) || (btR === 18000 && btG === 36000)) {
      return true;
    }
  }
  return false;
}

function filterDocumentedSoftDiff(onlyRef, onlyGen) {
  const usedGen = new Set();
  const remainingRef = [];
  let skipped = 0;
  for (const r of onlyRef) {
    let matched = false;
    for (let i = 0; i < onlyGen.length; i++) {
      if (usedGen.has(i)) continue;
      if (softAmtWhitelistPair(r.key, onlyGen[i].key)) {
        usedGen.add(i);
        skipped += Math.min(r.n, onlyGen[i].n);
        matched = true;
        break;
      }
    }
    if (!matched) remainingRef.push(r);
  }
  const remainingGen = onlyGen.filter((_, i) => !usedGen.has(i));
  return { remainingRef, remainingGen, skipped };
}

function sumField(rows, field) {
  let s = 0;
  for (const r of rows) s += m0(r[field]);
  return Math.round(s * 100) / 100;
}

function parseArgs(argv) {
  const o = {};
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith("--")) {
      const k = a.slice(2);
      o[k] = argv[++i];
    }
  }
  return o;
}

function main() {
  const args = parseArgs(process.argv);
  if (!args.ref || !args.gen) {
    console.error("Need --ref and --gen");
    process.exit(2);
  }

  const refRows = loadRefRows(args.ref);
  const { rows: genRows, cols: genCols } = loadGenRows(args.gen);

  const refPog = refRows.filter(isPogRow);
  const genPog = genRows.filter(isPogRow);

  const refPogMs = countKeys(refPog, pogKey);
  const genPogMs = countKeys(genPog, pogKey);
  const pogDiff = multisetDiff(refPogMs, genPogMs);

  const refSoft = countKeys(refPog, softAmtKey);
  const genSoft = countKeys(genPog, softAmtKey);
  const softDiff = multisetDiff(refSoft, genSoft);
  const { remainingRef: softOnlyRef, remainingGen: softOnlyGen, skipped: wlSkip } =
    filterDocumentedSoftDiff(softDiff.onlyA, softDiff.onlyB);

  const sums = {
    ref_q1_pog: sumField(refRows, "q1_pog"),
    gen_q1_pog: sumField(genRows, "q1_pog"),
    ref_pog_rows: refPog.length,
    gen_pog_rows: genPog.length,
  };
  sums.q1_pog_ok = sums.ref_q1_pog === sums.gen_q1_pog;

  const s791 = {
    gate: "S79.1",
    pogKey_onlyInRef: pogDiff.onlyA.length,
    pogKey_onlyInGen: pogDiff.onlyB.length,
    softAmt_onlyInRef: softOnlyRef.length,
    softAmt_onlyInGen: softOnlyGen.length,
    softAmt_whitelistSkipped: wlSkip,
    pass:
      sums.q1_pog_ok &&
      softOnlyRef.length === 0 &&
      softOnlyGen.length === 0,
    sample_onlyRef: softOnlyRef.slice(0, 15),
    sample_onlyGen: softOnlyGen.slice(0, 15),
  };

  let s792 = null;
  if (args.as902) {
    const { rows: r902 } = loadGenRows(args.as902);
    const rows903f = genRows.filter(hasQiOrBaseFact);
    const rows902f = r902.filter(hasQiOrBaseFact);
    const keys903 = countKeys(rows903f, softAmtKey);
    const keys902 = countKeys(rows902f, softAmtKey);
    const d = multisetDiff(keys902, keys903);
    const sum902 = sumField(r902, "q1_pog");
    const sum903 = sumField(genRows, "q1_pog");
    s792 = {
      gate: "S79.2",
      sum_q1_pog_902: sum902,
      sum_q1_pog_903: sum903,
      sum_ok: sum902 === sum903,
      rows902_fact: rows902f.length,
      rows903_fact: rows903f.length,
      onlyIn902: d.onlyA.length,
      onlyIn903: d.onlyB.length,
      pass: sum902 === sum903 && d.onlyA.length === 0 && d.onlyB.length === 0,
      sample_only902: d.onlyA.slice(0, 10),
      sample_only903: d.onlyB.slice(0, 10),
      note: "compare softAmtKey on rows with base/QI fact only (ignore empty QII-only shells)",
    };
  }

  const report = {
    created: new Date().toISOString(),
    gate: "S79.1 (+ optional S79.2)",
    sources: { ref: args.ref, gen: args.gen, as902: args.as902 || null },
    gen_cols: genCols,
    rows: { ref: refRows.length, gen: genRows.length },
    sums,
    s791,
    s792,
    pass: s791.pass && (s792 ? s792.pass : true),
  };

  console.log("=== S79.1 QI погашено vs Access ===");
  console.log(
    `rows ref=${refRows.length} gen=${genRows.length}; pogRows ref=${refPog.length} gen=${genPog.length}`
  );
  console.log(
    `∑ q1_pog ref=${sums.ref_q1_pog} gen=${sums.gen_q1_pog} ok=${sums.q1_pog_ok}`
  );
  console.log(
    `softAmt onlyRef=${s791.softAmt_onlyInRef} onlyGen=${s791.softAmt_onlyInGen} whitelistSkip=${s791.softAmt_whitelistSkipped}`
  );
  console.log(`S79.1 pass=${s791.pass}`);
  if (s792) {
    console.log("=== S79.2 регрессия asOf902→asOf903 ===");
    console.log(
      `∑ q1_pog 902=${s792.sum_q1_pog_902} 903=${s792.sum_q1_pog_903} ok=${s792.sum_ok}`
    );
    console.log(
      `softAmt only902=${s792.onlyIn902} only903=${s792.onlyIn903} pass=${s792.pass}`
    );
  }
  console.log(`OVERALL pass=${report.pass}`);

  if (args.json) {
    writeFileSync(args.json, JSON.stringify(report, null, 2), "utf8");
    console.log("wrote", args.json);
  }
  process.exit(report.pass ? 0 : 1);
}

main();
