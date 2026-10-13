#!/usr/bin/env node
/**
 * fleet - CLI facade over the agent-os fleet tool registry.
 *
 *   fleet list                 list registered tools
 *   fleet info <id>            full registry entry
 *   fleet health [id]          probe paths + HTTP interfaces
 *   fleet invoke <id> [cmd]    run a tool's declared command
 *   fleet mcp                  run the fleet-tools MCP server on stdio
 *   fleet path                 print the registry path
 */
import fs from "node:fs";
import path from "node:path";
import http from "node:http";
import https from "node:https";
import { spawnSync, spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REG_PATH = path.resolve(__dirname, "..", "..", "registry.json");

function load() {
  return JSON.parse(fs.readFileSync(REG_PATH, "utf8"));
}
function probe(url, t = 1500) {
  return new Promise((res) => {
    let done = false;
    const fin = (r) => {
      if (!done) {
        done = true;
        res(r);
      }
    };
    const lib = url.startsWith("https") ? https : http;
    let req;
    try {
      req = lib.get(url, { timeout: t }, (r) => {
        r.resume();
        fin({ up: true, status: r.statusCode });
      });
    } catch (e) {
      return fin({ up: false, error: String(e) });
    }
    req.on("timeout", () => {
      req.destroy();
      fin({ up: false, error: "timeout" });
    });
    req.on("error", (e) => fin({ up: false, error: e.code || e.message }));
  });
}
function collect(obj, key, out) {
  if (!obj || typeof obj !== "object") return out;
  for (const [k, v] of Object.entries(obj)) {
    if (k === key && typeof v === "string") out.push(v);
    else if (typeof v === "object") collect(v, key, out);
  }
  return out;
}
function httpUrls(entry) {
  const out = [];
  const walk = (o) => {
    if (!o || typeof o !== "object") return;
    for (const v of Object.values(o)) {
      if (typeof v === "string" && /^https?:\/\//.test(v)) out.push(v);
      else if (typeof v === "object") walk(v);
    }
  };
  walk(entry.interfaces || {});
  return out;
}
function declaredCommands(entry) {
  const s = new Set();
  collect(entry.interfaces, "run", []);
  for (const k of ["run", "dev", "start", "build"]) collect(entry.interfaces, k, []).forEach((c) => s.add(c));
  for (const c of entry.setup || []) s.add(c);
  return [...s];
}

const [cmd, ...rest] = process.argv.slice(2);
const reg = load();

if (cmd === "path") {
  console.log(REG_PATH);
} else if (cmd === "list" || !cmd) {
  for (const t of reg.tools) console.log(`${t.id.padEnd(18)} ${t.kind.padEnd(14)} ${t.status.padEnd(12)} ${t.summary}`);
} else if (cmd === "info") {
  const t = reg.tools.find((x) => x.id === rest[0]);
  if (!t) {
    console.error("unknown id. known: " + reg.tools.map((x) => x.id).join(", "));
    process.exit(1);
  }
  console.log(JSON.stringify(t, null, 2));
} else if (cmd === "health") {
  const targets = rest[0] ? reg.tools.filter((t) => t.id === rest[0]) : reg.tools;
  (async () => {
    for (const t of targets) {
      const exists = t.path ? fs.existsSync(t.path) : null;
      const probes = [];
      for (const u of httpUrls(t)) probes.push(`${u} -> ${JSON.stringify(await probe(u))}`);
      console.log(`${t.id}: path=${exists} ${probes.join("  ")}`);
    }
  })();
} else if (cmd === "invoke") {
  const t = reg.tools.find((x) => x.id === rest[0]);
  if (!t) {
    console.error("unknown id. known: " + reg.tools.map((x) => x.id).join(", "));
    process.exit(1);
  }
  const allowed = declaredCommands(t);
  const c = rest.slice(1).join(" ") || t.interfaces?.http?.run || allowed[0];
  if (!c || !allowed.includes(c)) {
    console.error(`refused: not a declared command for '${t.id}'. allowed:\n` + allowed.map((x) => "  - " + x).join("\n"));
    process.exit(1);
  }
  console.log(`$ (cwd=${t.path}) ${c}`);
  const r = spawnSync(c, { cwd: fs.existsSync(t.path) ? t.path : undefined, shell: true, stdio: "inherit" });
  process.exit(r.status ?? 1);
} else if (cmd === "mcp") {
  const child = spawn(process.execPath, [path.join(__dirname, "server.js")], { stdio: "inherit" });
  child.on("exit", (code) => process.exit(code ?? 0));
} else {
  console.error("usage: fleet list | info <id> | health [id] | invoke <id> [cmd] | mcp | path");
  process.exit(1);
}
