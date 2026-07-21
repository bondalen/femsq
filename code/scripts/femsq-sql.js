#!/usr/bin/env node
/**
 * Выполнить T-SQL через npm-пакет mssql из .cursor/dbhub (без sqlcmd).
 *
 * Использование:
 *   node code/scripts/femsq-sql.js "SELECT 1 AS x"
 *   echo "SELECT 1" | node code/scripts/femsq-sql.js
 *
 * DSN: ~/.femsq/database.properties (host, port, database, username, password)
 */
"use strict";

const fs = require("fs");
const path = require("path");
const os = require("os");

const propsPath = process.env.FEMSQ_DB_PROPS || path.join(os.homedir(), ".femsq", "database.properties");
if (!fs.existsSync(propsPath)) {
  console.error("Не найден", propsPath);
  process.exit(1);
}

const props = Object.fromEntries(
  fs
    .readFileSync(propsPath, "utf8")
    .split(/\r?\n/)
    .filter((l) => l && !l.startsWith("#") && l.includes("="))
    .map((l) => {
      const i = l.indexOf("=");
      return [l.slice(0, i).trim(), l.slice(i + 1).trim()];
    })
);

const sqlText = process.argv[2] || fs.readFileSync(0, "utf8");
if (!sqlText.trim()) {
  console.error("Пустой SQL");
  process.exit(1);
}

const mssqlPath = path.resolve(__dirname, "../../.cursor/dbhub/node_modules/mssql");
const sql = require(mssqlPath);

async function main() {
  const pool = await sql.connect({
    server: props.host || "localhost",
    port: Number(props.port || 1433),
    database: props.database,
    user: props.username,
    password: props.password,
    options: {
      encrypt: false,
      trustServerCertificate: true,
    },
  });
  try {
    const result = await pool.request().query(sqlText);
    if (Array.isArray(result.recordsets)) {
      for (const rs of result.recordsets) {
        if (!rs || !rs.length) continue;
        const cols = Object.keys(rs[0]);
        console.log(cols.join("\t"));
        for (const row of rs) {
          console.log(cols.map((c) => (row[c] == null ? "" : String(row[c]))).join("\t"));
        }
        console.log("");
      }
    }
  } finally {
    await sql.close();
  }
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
