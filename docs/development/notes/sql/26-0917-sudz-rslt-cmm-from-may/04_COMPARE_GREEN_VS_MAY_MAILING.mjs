/**
 * Сверка зелёных полей Rslt сбор (группа 905) с файлом рассылки MAY.
 *
 *   node 04_COMPARE_GREEN_VS_MAY_MAILING.mjs
 *
 * lastUpdated: 2026-09-17
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

const GEN_DEFAULT = resolve(
  __dirname,
  "artifacts/ags_Yr_DbtChangesRslt_901_asOf903_s82cmm_905_26-0917.xlsx"
);
const REF_DEFAULT =
  "/home/alex/Downloads/продОбмен/26-0917_09-41/в_Прод/ags_Yr_DbtChangesRslt_26-0917_cmm_from_may.xlsx";

function txt(v) {
  if (v === null || v === undefined) return null;
  const s = String(v).replace(/\u00A0/g, " ").replace(/\r\n/g, "\n").trim();
  return s === "" ? null : s;
}
function nrm(v) {
  const t = txt(v);
  return t === null ? null : t.replace(/\s+/g, " ");
}
function D(v) {
  if (v === null || v === undefined || v === "") return null;
  const n = Number(String(v).replace(/\s/g, "").replace(",", "."));
  if (Number.isNaN(n)) return null;
  return Math.round(n * 100) / 100;
}
function sheetRows(path) {
  const wb = XLSX.readFile(path, { cellDates: true, raw: true });
  const g = XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]], {
    header: 1,
    defval: null,
    raw: true,
  });
  const tech = g[1] || [];
  const idx = {};
  for (let i = 0; i < tech.length; i++) {
    const k = String(tech[i] ?? "").trim();
    if (k) idx[k] = i;
  }
  return { g, idx, sheet: wb.SheetNames[0] };
}
function col(idx, ...names) {
  for (const n of names) if (idx[n] != null) return idx[n];
  return null;
}

const genPath = process.argv[2] || GEN_DEFAULT;
const refPath = process.argv[3] || REF_DEFAULT;
const gen = sheetRows(genPath);
const ref = sheetRows(refPath);

const C = {
  dbt: col(gen.idx, "dbtKey") ?? 0,
  cur: col(gen.idx, "Куратор от Управления") ?? 46,
  mery: col(gen.idx, "Мероприятия по погашению дебиторской задолженности") ?? 47,
  cst: col(gen.idx, "Код стройки") ?? 48,
  name: col(gen.idx, "Код стройкиN") ?? 49,
  curNew: col(gen.idx, "cur_new"),
  meryNew: col(gen.idx, "mery_new"),
  cstNew: col(gen.idx, "cstAgPn_new"),
  overdQiv: 11,
};

function loadByDbt(pack) {
  const by = new Map();
  for (let r = 3; r < pack.g.length; r++) {
    const row = pack.g[r] || [];
    const dbt = D(row[C.dbt]);
    if (dbt === null) continue;
    const rec = {
      row: r + 1,
      curator: nrm(row[C.cur]),
      mery: nrm(row[C.mery]),
      cst: nrm(row[C.cst]),
      name: nrm(row[C.name]),
      curatorRaw: txt(row[C.cur]),
      meryRaw: txt(row[C.mery]),
      overdQiv: D(row[C.overdQiv]),
      curNew: nrm(C.curNew != null ? row[C.curNew] : null),
      meryNew: nrm(C.meryNew != null ? row[C.meryNew] : null),
      cstNew: nrm(C.cstNew != null ? row[C.cstNew] : null),
    };
    if (!by.has(dbt)) by.set(dbt, rec);
  }
  return by;
}

const genBy = loadByDbt(gen);
const refBy = loadByDbt(ref);
const genKeys = [...genBy.keys()];
const refKeys = [...refBy.keys()];
const onlyGen = genKeys.filter((k) => !refBy.has(k));
const onlyRef = refKeys.filter((k) => !genBy.has(k));
const both = genKeys.filter((k) => refBy.has(k));

function fieldDiffs(field) {
  const d = { same: 0, bothEmpty: 0, genOnly: 0, refOnly: 0, change: 0, samples: [] };
  for (const k of both) {
    const a = genBy.get(k)[field];
    const b = refBy.get(k)[field];
    if (a === b) {
      if (a == null) d.bothEmpty++;
      else d.same++;
    } else if (a && !b) {
      d.genOnly++;
      if (d.samples.length < 8) d.samples.push({ dbt: k, gen: a, ref: b });
    } else if (!a && b) {
      d.refOnly++;
      if (d.samples.length < 8) d.samples.push({ dbt: k, gen: a, ref: b });
    } else {
      d.change++;
      if (d.samples.length < 8) d.samples.push({ dbt: k, gen: a && a.slice(0, 80), ref: b && b.slice(0, 80) });
    }
  }
  return d;
}

function filled(map, field) {
  let n = 0;
  for (const v of map.values()) if (v[field]) n++;
  return n;
}

const qivBoth = both.filter((k) => (refBy.get(k).overdQiv || 0) > 0);
function fieldDiffsOn(keys, field) {
  const d = { same: 0, bothEmpty: 0, genOnly: 0, refOnly: 0, change: 0 };
  for (const k of keys) {
    const a = genBy.get(k)[field];
    const b = refBy.get(k)[field];
    if (a === b) {
      if (a == null) d.bothEmpty++;
      else d.same++;
    } else if (a && !b) d.genOnly++;
    else if (!a && b) d.refOnly++;
    else d.change++;
  }
  return d;
}

let newFilled = 0;
for (const v of genBy.values()) {
  if (v.curNew || v.meryNew || v.cstNew) newFilled++;
}

const report = {
  created: new Date().toISOString(),
  gen: genPath,
  ref: refPath,
  cols: C,
  rows: { gen: gen.g.length - 3, ref: ref.g.length - 3, genDbt: genBy.size, refDbt: refBy.size },
  keyDelta: { onlyGen: onlyGen.length, onlyRef: onlyRef.length, both: both.length, onlyGenSample: onlyGen.slice(0, 10), onlyRefSample: onlyRef.slice(0, 10) },
  filled: {
    gen: { curator: filled(genBy, "curator"), mery: filled(genBy, "mery"), cst: filled(genBy, "cst"), name: filled(genBy, "name") },
    ref: { curator: filled(refBy, "curator"), mery: filled(refBy, "mery"), cst: filled(refBy, "cst"), name: filled(refBy, "name") },
  },
  diffs: {
    curator: fieldDiffs("curator"),
    mery: fieldDiffs("mery"),
    cst: fieldDiffs("cst"),
    name: fieldDiffs("name"),
  },
  qivOverd: {
    n: qivBoth.length,
    curator: fieldDiffsOn(qivBoth, "curator"),
    mery: fieldDiffsOn(qivBoth, "mery"),
    cst: fieldDiffsOn(qivBoth, "cst"),
    name: fieldDiffsOn(qivBoth, "name"),
  },
  genNewFilled: newFilled,
};

const jsonPath = resolve(__dirname, "artifacts/compare_green_905_vs_may_mailing.json");
mkdirSync(dirname(jsonPath), { recursive: true });
writeFileSync(jsonPath, JSON.stringify(report, null, 2), "utf8");

function show(title, d) {
  console.log(
    title,
    "same=" + d.same,
    "bothEmpty=" + d.bothEmpty,
    "genOnly=" + d.genOnly,
    "refOnly=" + d.refOnly,
    "CHANGE=" + d.change
  );
}

console.log("gen", genPath);
console.log("ref", refPath);
console.log("rows", report.rows);
console.log("keyDelta", report.keyDelta.onlyGen, report.keyDelta.onlyRef, "both", both.length);
console.log("filled gen", report.filled.gen);
console.log("filled ref", report.filled.ref);
console.log("gen *_new filled dbt", newFilled);
show("куратор", report.diffs.curator);
show("мероприятия", report.diffs.mery);
show("код", report.diffs.cst);
show("имя", report.diffs.name);
console.log("--- QIV-overd n=" + qivBoth.length);
show("  куратор", report.qivOverd.curator);
show("  мероприятия", report.qivOverd.mery);
show("  код", report.qivOverd.cst);
show("  имя", report.qivOverd.name);
for (const f of ["curator", "mery", "cst", "name"]) {
  const s = report.diffs[f].samples;
  if (s.length) {
    console.log("samples", f);
    for (const x of s) console.log(" ", x);
  }
}
console.log("json", jsonPath);
