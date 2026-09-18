#!/usr/bin/env node
/**
 * S79.3 + S79.4 — кандидаты QII «погашено» + sum-match twin в GEN и Tbl@902/@903.
 *
 * Usage:
 *   node verify_s79_qii_pog_twins.mjs \
 *     --gen .../ags_Yr_DbtChangesRslt_901_asOf903_d4_post902_26-0916.xlsx \
 *     --tbl docs/.../artifacts/stage2_s79_tbl_902_903.json \
 *     [--json OUT.json]
 *
 * Tbl dump: JSON array [{upl, acc, inv, cn, debt, overd, key}, ...]
 */
import { createRequire } from "module";
import { readFileSync, writeFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const require = createRequire(
  resolve(__dirname, "../../../../../.cursor/rslt-tools/package.json")
);
const XLSX = require("xlsx");

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

function near(a, b) {
  if (a === null || b === null) return false;
  return Math.abs(a - b) <= EPS;
}

function invNorm(s) {
  let t = String(s ?? "")
    .trim()
    .replace(/\s+/g, " ");
  const cut = t.split(",")[0].trim();
  t = cut.replace(/\s*\(номеров:\s*\d+\)\s*$/i, "").trim();
  return t.toUpperCase();
}

function parseArgs(argv) {
  const o = {};
  for (let i = 2; i < argv.length; i++) {
    if (argv[i].startsWith("--")) o[argv[i].slice(2)] = argv[++i];
  }
  return o;
}

function loadSheet(path) {
  const wb = XLSX.readFile(path, { cellDates: true, raw: true });
  const ws = wb.Sheets[wb.SheetNames[0]];
  return XLSX.utils.sheet_to_json(ws, { header: 1, defval: null, raw: true });
}

function detectCols(grid) {
  const row3 = grid[2] || [];
  const ttlPrefs = [];
  const by = new Map();
  for (let i = 0; i < row3.length; i++) {
    const v = row3[i];
    if (v == null || v === "") continue;
    const tech = String(v);
    if (tech.endsWith("_Ttl")) ttlPrefs.push({ i, p: tech.slice(0, -4) });
    for (const suf of [
      "_Ttl",
      "_Overd",
      "_погашено",
      "_invNumEnum",
      "_cnNumEnum",
      "_Maturity",
    ]) {
      if (tech.endsWith(suf)) by.set(tech, i);
    }
  }
  if (ttlPrefs.length < 3) {
    throw new Error(`need >=3 *_Ttl, got ${ttlPrefs.length}`);
  }
  const pick = (p, s) => {
    const k = p + s;
    if (!by.has(k)) throw new Error(`missing ${k}`);
    return by.get(k);
  };
  const [b, q1, q2] = ttlPrefs;
  return {
    dbt: 0,
    acc: 1,
    base: {
      inv: pick(b.p, "_invNumEnum"),
      cn: pick(b.p, "_cnNumEnum"),
      ttl: pick(b.p, "_Ttl"),
      o: pick(b.p, "_Overd"),
      mat: by.get(b.p + "_Maturity") ?? null,
    },
    q1: {
      inv: pick(q1.p, "_invNumEnum"),
      cn: pick(q1.p, "_cnNumEnum"),
      ttl: pick(q1.p, "_Ttl"),
      o: pick(q1.p, "_Overd"),
      pog: pick(q1.p, "_погашено"),
      mat: by.get(q1.p + "_Maturity") ?? null,
    },
    q2: {
      inv: pick(q2.p, "_invNumEnum"),
      cn: pick(q2.p, "_cnNumEnum"),
      ttl: pick(q2.p, "_Ttl"),
      o: pick(q2.p, "_Overd"),
      pog: pick(q2.p, "_погашено"),
      mat: by.get(q2.p + "_Maturity") ?? null,
    },
    prefixes: { base: b.p, q1: q1.p, q2: q2.p },
  };
}

function cell(row, i) {
  return i == null ? null : row[i] ?? null;
}

function loadGen(path) {
  const grid = loadSheet(path);
  const cols = detectCols(grid);
  const rows = [];
  for (let r = 3; r < grid.length; r++) {
    const row = grid[r] || [];
    const rec = {
      row: r + 1,
      dbtKey: D(cell(row, cols.dbt)) ?? cell(row, cols.dbt),
      acc: String(cell(row, cols.acc) ?? "").trim(),
      base_inv: cell(row, cols.base.inv),
      base_cn: cell(row, cols.base.cn),
      base_ttl: D(cell(row, cols.base.ttl)),
      base_o: D(cell(row, cols.base.o)),
      base_mat: cell(row, cols.base.mat),
      q1_inv: cell(row, cols.q1.inv),
      q1_cn: cell(row, cols.q1.cn),
      q1_ttl: D(cell(row, cols.q1.ttl)),
      q1_o: D(cell(row, cols.q1.o)),
      q1_pog: D(cell(row, cols.q1.pog)),
      q1_mat: cell(row, cols.q1.mat),
      q2_inv: cell(row, cols.q2.inv),
      q2_cn: cell(row, cols.q2.cn),
      q2_ttl: D(cell(row, cols.q2.ttl)),
      q2_o: D(cell(row, cols.q2.o)),
      q2_pog: D(cell(row, cols.q2.pog)),
      q2_mat: cell(row, cols.q2.mat),
    };
    if (!rec.acc && rec.base_ttl == null && rec.q1_ttl == null && rec.q2_ttl == null) {
      continue;
    }
    rows.push(rec);
  }
  return { rows, cols };
}

function lastInv(r) {
  return invNorm(r.q2_inv || r.q1_inv || r.base_inv);
}

function lastCn(r) {
  return String(r.q2_cn || r.q1_cn || r.base_cn || "").trim();
}

function hasQ2Fact(r) {
  return r.q2_ttl !== null || r.q2_o !== null;
}

function isDocumented(r) {
  const inv = lastInv(r);
  if (inv === "86740" || inv === "10000086740") return "E-Access-Missing-86740";
  if (inv.includes("А45-19974") || inv.includes("A45-19974")) return "E-Split-A45-19974";
  return null;
}

function buildCandidates(rows) {
  const out = [];
  for (const r of rows) {
    if (r.q2_pog === null || r.q2_pog === 0) continue;
    const kind = hasQ2Fact(r) ? "partial_reduce" : "full_disappear";
    // same-slot reduction: still has q2 fact on this band → not P1 disappearance
    const sameSlotReduce = kind === "partial_reduce";
    out.push({
      row: r.row,
      dbtKey: r.dbtKey,
      acc: r.acc,
      inv: lastInv(r),
      cn: lastCn(r),
      kind,
      sameSlotReduce,
      base_ttl: r.base_ttl,
      base_o: r.base_o,
      q1_ttl: r.q1_ttl,
      q1_o: r.q1_o,
      q1_pog: r.q1_pog,
      q2_ttl: r.q2_ttl,
      q2_o: r.q2_o,
      q2_pog: r.q2_pog,
      q2_mat: r.q2_mat,
      q1_mat: r.q1_mat,
      base_mat: r.base_mat,
      documented: isDocumented(r),
      searchAmounts: uniqueAmounts([
        r.q2_pog,
        r.base_ttl,
        r.base_o,
        r.q1_ttl,
        r.q1_o,
        // full debt often = overd for overdue portfolio
      ]),
    });
  }
  return out;
}

function uniqueAmounts(arr) {
  const out = [];
  for (const a of arr) {
    if (a === null || a === 0) continue;
    if (!out.some((x) => near(x, a))) out.push(a);
  }
  return out;
}

function findGenTwins(cand, allRows) {
  const hits = [];
  for (const r of allRows) {
    if (r.row === cand.row) continue;
    if (String(r.dbtKey) === String(cand.dbtKey)) continue;
    const amounts = [
      ["base_ttl", r.base_ttl],
      ["base_o", r.base_o],
      ["q1_ttl", r.q1_ttl],
      ["q1_o", r.q1_o],
      ["q2_ttl", r.q2_ttl],
      ["q2_o", r.q2_o],
    ];
    for (const S of cand.searchAmounts) {
      for (const [field, v] of amounts) {
        if (near(S, v)) {
          hits.push({
            source: "gen",
            field,
            amount: v,
            matchOn: S,
            row: r.row,
            dbtKey: r.dbtKey,
            acc: r.acc,
            inv: lastInv(r),
            cn: lastCn(r),
            sameInv: lastInv(r) === cand.inv,
          });
        }
      }
    }
  }
  return dedupeHits(hits);
}

function findTblTwins(cand, tblRows) {
  const hits = [];
  for (const t of tblRows) {
    // skip exact same inv+acc on any upl as "self-like" only if also same debt was the disappearing one —
    // still report if inv differs OR (same inv but different enough context)
    for (const S of cand.searchAmounts) {
      if (near(S, D(t.debt))) {
        hits.push({
          source: "tbl",
          field: "cidutDebt",
          amount: D(t.debt),
          matchOn: S,
          upl: t.upl,
          key: t.key,
          acc: t.acc,
          inv: invNorm(t.inv),
          cn: String(t.cn ?? "").trim(),
          overd: D(t.overd),
          sameInv: invNorm(t.inv) === cand.inv,
        });
      }
      if (near(S, D(t.overd))) {
        hits.push({
          source: "tbl",
          field: "cidutDebtOverdue",
          amount: D(t.overd),
          matchOn: S,
          upl: t.upl,
          key: t.key,
          acc: t.acc,
          inv: invNorm(t.inv),
          cn: String(t.cn ?? "").trim(),
          overd: D(t.overd),
          sameInv: invNorm(t.inv) === cand.inv,
        });
      }
    }
  }
  return dedupeHits(hits);
}

function dedupeHits(hits) {
  const seen = new Set();
  const out = [];
  for (const h of hits) {
    const k = [
      h.source,
      h.upl ?? "",
      h.row ?? "",
      h.dbtKey ?? "",
      h.key ?? "",
      h.field,
      h.amount,
      h.inv,
    ].join("|");
    if (seen.has(k)) continue;
    seen.add(k);
    out.push(h);
  }
  return out;
}

function classify(cand, genHits, tblHits) {
  if (cand.documented) {
    return { clazz: "documented", reason: cand.documented };
  }
  // partial reduce on same band = Overd dropped while Value still there → not P1
  if (cand.sameSlotReduce) {
    const foreign = [...genHits, ...tblHits].filter((h) => !h.sameInv);
    if (foreign.length === 0) {
      return {
        clazz: "likely-true",
        reason: "partial_reduce_same_slot_no_foreign_twin",
      };
    }
    // foreign twin while still present → suspicious re-appearance elsewhere
    if (foreign.length === 1) {
      return { clazz: "suspect", reason: "partial_reduce_but_foreign_twin", twins: foreign };
    }
    return { clazz: "ambiguous", reason: "partial_reduce_multi_foreign_twin", twins: foreign };
  }

  // full disappear
  const foreign = [...genHits, ...tblHits].filter((h) => !h.sameInv);
  const selfish = [...genHits, ...tblHits].filter((h) => h.sameInv);
  // twin on same inv in Tbl@903 while Rslt shows disappear — continuity/var change
  const foreignDebt = foreign.filter(
    (h) => h.field === "cidutDebt" || h.field === "base_ttl" || h.field === "q1_ttl" || h.field === "q2_ttl"
  );

  if (foreignDebt.length === 0 && foreign.length === 0) {
    // only same-inv hits (e.g. still in Tbl under same inv) or nothing
    if (selfish.some((h) => h.source === "tbl" && h.upl === 903)) {
      return {
        clazz: "suspect",
        reason: "full_disappear_but_same_inv_still_in_tbl903",
        twins: selfish.filter((h) => h.upl === 903),
      };
    }
    return { clazz: "likely-true", reason: "full_disappear_no_twin" };
  }
  if (foreignDebt.length === 1 || (foreignDebt.length === 0 && foreign.length === 1)) {
    return {
      clazz: "suspect",
      reason: "full_disappear_foreign_twin",
      twins: foreignDebt.length ? foreignDebt : foreign,
    };
  }
  return {
    clazz: "ambiguous",
    reason: "full_disappear_multi_twin",
    twins: foreignDebt.length ? foreignDebt : foreign,
  };
}

function main() {
  const args = parseArgs(process.argv);
  if (!args.gen || !args.tbl) {
    console.error("Need --gen and --tbl");
    process.exit(2);
  }
  const { rows, cols } = loadGen(args.gen);
  const tblRows = JSON.parse(readFileSync(args.tbl, "utf8"));
  const candidates = buildCandidates(rows);

  const classified = [];
  const counts = {
    documented: 0,
    "likely-true": 0,
    suspect: 0,
    ambiguous: 0,
  };

  for (const c of candidates) {
    const genHits = findGenTwins(c, rows);
    const tblHits = findTblTwins(c, tblRows);
    const cls = classify(c, genHits, tblHits);
    counts[cls.clazz] = (counts[cls.clazz] || 0) + 1;
    classified.push({
      ...c,
      class: cls.clazz,
      classReason: cls.reason,
      genTwinCount: genHits.length,
      tblTwinCount: tblHits.length,
      foreignTwinCount: [...genHits, ...tblHits].filter((h) => !h.sameInv).length,
      twins: (cls.twins || [...genHits, ...tblHits].filter((h) => !h.sameInv)).slice(0, 12),
    });
  }

  // sort: suspect/ambiguous first by q2_pog desc
  const rank = { suspect: 0, ambiguous: 1, documented: 2, "likely-true": 3 };
  classified.sort((a, b) => {
    const ra = rank[a.class] ?? 9;
    const rb = rank[b.class] ?? 9;
    if (ra !== rb) return ra - rb;
    return (b.q2_pog || 0) - (a.q2_pog || 0);
  });

  const sumPog = candidates.reduce((s, c) => s + m0(c.q2_pog), 0);
  const report = {
    created: new Date().toISOString(),
    gate: "S79.3+S79.4",
    sources: { gen: args.gen, tbl: args.tbl },
    gen_prefixes: cols.prefixes,
    gen_rows: rows.length,
    tbl_rows: tblRows.length,
    candidates: candidates.length,
    sum_q2_pog: Math.round(sumPog * 100) / 100,
    byKind: {
      full_disappear: candidates.filter((c) => c.kind === "full_disappear").length,
      partial_reduce: candidates.filter((c) => c.kind === "partial_reduce").length,
    },
    byClass: counts,
    top_suspect: classified.filter((c) => c.class === "suspect").slice(0, 40),
    top_ambiguous: classified.filter((c) => c.class === "ambiguous").slice(0, 20),
    all: classified,
  };

  console.log("=== S79.3/4 QII погашено + twin ===");
  console.log(
    `candidates=${report.candidates} full=${report.byKind.full_disappear} partial=${report.byKind.partial_reduce}`
  );
  console.log(`∑ q2_pog=${report.sum_q2_pog}`);
  console.log("byClass", counts);
  console.log(
    "top suspect:",
    report.top_suspect
      .slice(0, 8)
      .map((c) => `${c.acc}|${c.inv}|pog=${c.q2_pog}|${c.classReason}`)
      .join("\n  ")
  );

  if (args.json) {
    writeFileSync(args.json, JSON.stringify(report, null, 2), "utf8");
    console.log("wrote", args.json);
  }
}

main();
