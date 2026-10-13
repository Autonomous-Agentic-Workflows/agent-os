#!/usr/bin/env node
/**
 * fleet-tools - a zero-dependency Model Context Protocol (stdio) server that
 * exposes every repo registered in ../../registry.json as callable tools.
 *
 * Protocol: JSON-RPC 2.0, newline-delimited, over stdin/stdout.
 * Nothing but JSON-RPC is ever written to stdout (logs go to stderr).
 *
 * Register in ~/.config/opencode/opencode.jsonc:
 *   "fleet-tools": {
 *     "type": "local",
 *     "command": ["node", "P:\\agent-os\\tools\\mcp\\fleet-tools\\server.js"],
 *     "enabled": true
 *   }
 */
import readline from "node:readline";
import fs from "node:fs";
import path from "node:path";
import http from "node:http";
import https from "node:https";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REGISTRY_PATH = path.resolve(__dirname, "..", "..", "registry.json");
const SERVER_INFO = { name: "fleet-tools", version: "1.0.0" };
const DEFAULT_PROTOCOL = "2024-11-05";

function log(...a) {
  process.stderr.write("[fleet-tools] " + a.join(" ") + "\n");
}

function loadRegistry() {
  const raw = fs.readFileSync(REGISTRY_PATH, "utf8");
  return JSON.parse(raw);
}

function send(msg) {
  process.stdout.write(JSON.stringify(msg) + "\n");
}

function ok(id, result) {
  send({ jsonrpc: "2.0", id, result });
}

function err(id, code, message, data) {
  send({ jsonrpc: "2.0", id, error: { code, message, ...(data ? { data } : {}) } });
}

// ---------------------------------------------------------------- tool defs
const TOOLS = [
  {
    name: "fleet_list",
    description:
      "List every external repo registered as a fleet tool (id, name, kind, status, summary).",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "fleet_info",
    description:
      "Full registry entry for one tool id: paths, interfaces, setup steps, invoke command, skills, secrets.",
    inputSchema: {
      type: "object",
      properties: { id: { type: "string", description: "Tool id, e.g. 'paperclip'." } },
      required: ["id"],
      additionalProperties: false,
    },
  },
  {
    name: "fleet_health",
    description:
      "Probe tools: checks repo paths exist and HTTP interfaces respond. Omit id to probe all.",
    inputSchema: {
      type: "object",
      properties: { id: { type: "string", description: "Optional single tool id." } },
      additionalProperties: false,
    },
  },
  {
    name: "fleet_invoke",
    description:
      "Run a tool's declared command (whitelisted from the registry; no arbitrary shell). " +
      "For long-running services pass the exact declared command and expect a timeout.",
    inputSchema: {
      type: "object",
      properties: {
        id: { type: "string" },
        command: { type: "string", description: "Optional; must match a declared command for the tool." },
        timeout_ms: { type: "integer", description: "Default 20000." },
      },
      required: ["id"],
      additionalProperties: false,
    },
  },
];

// ---------------------------------------------------------------- helpers
function declaredCommands(entry) {
  const cmds = new Set();
  const walk = (o) => {
    if (!o || typeof o !== "object") return;
    for (const [k, v] of Object.entries(o)) {
      if (typeof v === "string" && ["run", "dev", "start", "build", "setup"].includes(k)) {
        // setup may be an array of strings
        cmds.add(v);
      } else if (Array.isArray(v) && k === "setup") {
        for (const s of v) if (typeof s === "string") cmds.add(s);
      } else if (typeof v === "object") {
        walk(v);
      }
    }
  };
  walk(entry.interfaces || {});
  for (const s of entry.setup || []) cmds.add(s);
  return [...cmds];
}

function httpUrls(entry) {
  const urls = [];
  const walk = (o) => {
    if (!o || typeof o !== "object") return;
    for (const [k, v] of Object.entries(o)) {
      if (typeof v === "string" && /^https?:\/\//.test(v)) urls.push(v);
      else if (typeof v === "object") walk(v);
    }
  };
  walk(entry.interfaces || {});
  return urls;
}

function probeHttp(url, timeoutMs = 1500) {
  return new Promise((resolve) => {
    let settled = false;
    const done = (r) => {
      if (!settled) {
        settled = true;
        resolve(r);
      }
    };
    if (/\/docs$|\/mcp$/.test(url)) {
      // still just probe; 404 is fine -> means reachable
    }
    const lib = url.startsWith("https") ? https : http;
    let req;
    try {
      req = lib.get(url, { timeout: timeoutMs }, (res) => {
        res.resume();
        done({ up: true, status: res.statusCode });
      });
    } catch (e) {
      return done({ up: false, error: String(e) });
    }
    req.on("timeout", () => {
      req.destroy();
      done({ up: false, error: "timeout" });
    });
    req.on("error", (e) => done({ up: false, error: e.code || e.message }));
  });
}

function runCommand(cmd, cwd, timeoutMs = 20000) {
  return new Promise((resolve) => {
    const child = spawn(cmd, { cwd: cwd && fs.existsSync(cwd) ? cwd : undefined, shell: true });
    let out = "";
    let err = "";
    const timer = setTimeout(() => {
      try {
        child.kill();
      } catch {}
    }, timeoutMs);
    child.stdout.on("data", (d) => (out += d));
    child.stderr.on("data", (d) => (err += d));
    child.on("close", (code) => {
      clearTimeout(timer);
      resolve({ code, stdout: out.slice(-8000), stderr: err.slice(-8000) });
    });
    child.on("error", (e) => {
      clearTimeout(timer);
      resolve({ code: -1, error: String(e) });
    });
  });
}

function text(s) {
  return { content: [{ type: "text", text: typeof s === "string" ? s : JSON.stringify(s, null, 2) }] };
}

// ---------------------------------------------------------------- call handlers
async function callTool(name, args) {
  const reg = loadRegistry();
  const tools = reg.tools || [];

  if (name === "fleet_list") {
    const rows = tools.map((t) => ({
      id: t.id,
      name: t.name,
      kind: t.kind,
      status: t.status,
      language: t.language,
      summary: t.summary,
    }));
    return text(JSON.stringify(rows, null, 2));
  }

  if (name === "fleet_info") {
    const t = tools.find((x) => x.id === args.id);
    if (!t) return { ...text(`No tool with id '${args.id}'. Known: ${tools.map((x) => x.id).join(", ")}`), isError: true };
    return text(JSON.stringify(t, null, 2));
  }

  if (name === "fleet_health") {
    const targets = args.id ? tools.filter((t) => t.id === args.id) : tools;
    if (args.id && targets.length === 0) return { ...text(`No tool with id '${args.id}'.`), isError: true };
    const results = await Promise.all(
      targets.map(async (t) => {
        const pathExists = t.path ? fs.existsSync(t.path) : null;
        const urls = httpUrls(t);
        const probes = [];
        for (const u of urls) probes.push({ url: u, ...(await probeHttp(u)) });
        return {
          id: t.id,
          status: t.status,
          path: t.path,
          path_exists: pathExists,
          http: probes,
          summary: t.summary,
        };
      })
    );
    return text(JSON.stringify(results, null, 2));
  }

  if (name === "fleet_invoke") {
    const t = tools.find((x) => x.id === args.id);
    if (!t) return { ...text(`No tool with id '${args.id}'.`), isError: true };
    const allowed = declaredCommands(t);
    const cmd = args.command || t.interfaces?.http?.run || allowed[0];
    if (!cmd) return { ...text(`Tool '${t.id}' declares no runnable command. See fleet_info.`), isError: true };
    if (!allowed.includes(cmd)) {
      return {
        ...text(
          `Refused: '${cmd}' is not a declared command for '${t.id}'.\nAllowed:\n` +
            allowed.map((c) => "  - " + c).join("\n")
        ),
        isError: true,
      };
    }
    const timeoutMs = Number.isInteger(args.timeout_ms) ? args.timeout_ms : 20000;
    const res = await runCommand(cmd, t.path, timeoutMs);
    return text(`$ (cwd=${t.path}) ${cmd}\n\n` + JSON.stringify(res, null, 2));
  }

  return { ...text(`Unknown tool '${name}'.`), isError: true };
}

// ---------------------------------------------------------------- transport
const rl = readline.createInterface({ input: process.stdin });

rl.on("line", async (line) => {
  const s = line.trim();
  if (!s) return;
  let msg;
  try {
    msg = JSON.parse(s);
  } catch (e) {
    log("bad json:", e.message);
    return;
  }
  const { id, method, params } = msg;

  // notifications (no id) -> never respond
  if (method === "notifications/initialized" || (method && method.startsWith("notifications/"))) {
    return;
  }

  try {
    if (method === "initialize") {
      const pv = params?.protocolVersion || DEFAULT_PROTOCOL;
      ok(id, {
        protocolVersion: pv,
        capabilities: { tools: { listChanged: false } },
        serverInfo: SERVER_INFO,
      });
      return;
    }
    if (method === "ping") {
      ok(id, {});
      return;
    }
    if (method === "tools/list") {
      ok(id, { tools: TOOLS });
      return;
    }
    if (method === "tools/call") {
      const { name, arguments: args } = params || {};
      const result = await callTool(name, args || {});
      ok(id, result);
      return;
    }
    err(id, -32601, `Method not found: ${method}`);
  } catch (e) {
    log("handler error:", e?.stack || String(e));
    if (id !== undefined) err(id, -32603, `Internal error: ${e?.message || String(e)}`);
  }
});

rl.on("close", () => process.exit(0));
log("ready; registry =", REGISTRY_PATH);
