#!/usr/bin/env node
/**
 * sync-tools.mjs - generate the downstream tool artifacts from registry.json:
 *
 *   1. ../commands/tools/index.md  + ../commands/tools/<id>.md   (agent-os commands)
 *   2. C:\Users\jayla\AppData\Roaming\npm\fleet.cmd              (facade)
 *   3. C:\Users\jayla\AppData\Roaming\npm\<cli>.cmd              (per-tool shims)
 *
 * Adding a tool = add one registry.json entry, re-run this script.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const TOOLS_DIR = __dirname; // P:\agent-os\tools
const REPO_ROOT = path.resolve(__dirname, ".."); // P:\agent-os
const REG = JSON.parse(fs.readFileSync(path.join(TOOLS_DIR, "registry.json"), "utf8"));
const CMD_DIR = path.join(REPO_ROOT, "commands", "tools");
const NPM_BIN = "C:\\Users\\jayla\\AppData\\Roaming\\npm";
const FLEET_CLI = "P:\\agent-os\\tools\\mcp\\fleet-tools\\cli.js";
const CRLF = "\r\n";

fs.mkdirSync(CMD_DIR, { recursive: true });
fs.mkdirSync(NPM_BIN, { recursive: true });

const wrote = [];

// ------------------------------------------------------------ command docs
function renderCommand(t) {
  const lines = [];
  lines.push(`# ${t.name} (\`${t.id}\`)`);
  lines.push("");
  lines.push(t.summary);
  lines.push("");
  lines.push("## Basics");
  lines.push("");
  lines.push(`- **Repo**: \`${t.repo}\``);
  lines.push(`- **Path**: \`${t.path}\``);
  lines.push(`- **Kind**: ${t.kind} (${t.language})`);
  lines.push(`- **Status**: \`${t.status}\``);
  lines.push(`- **CLI**: \`${t.invoke_cli || "-"}\``);
  lines.push("");
  if (t.interfaces) {
    lines.push("## Interfaces");
    lines.push("");
    lines.push("```json");
    lines.push(JSON.stringify(t.interfaces, null, 2));
    lines.push("```");
    lines.push("");
  }
  if (t.setup && t.setup.length) {
    lines.push("## Setup (if `status: needs-setup`)");
    lines.push("");
    t.setup.forEach((s) => lines.push(`- \`${s}\``));
    lines.push("");
  }
  if (t.skills && t.skills.length) {
    lines.push("## Skills shipped");
    lines.push("");
    t.skills.forEach((s) => lines.push(`- \`${s}\``));
    lines.push("");
  }
  if (t.secrets && t.secrets.length) {
    lines.push("## Secrets required");
    lines.push("");
    t.secrets.forEach((s) => lines.push(`- ${s}`));
    lines.push("");
  }
  if (t.notes) {
    lines.push("## Notes");
    lines.push("");
    lines.push(t.notes);
    lines.push("");
  }
  lines.push("## How agents use it");
  lines.push("");
  lines.push("Via the **fleet-tools** MCP server:");
  lines.push("");
  lines.push("```");
  lines.push(`fleet_info({ id: "${t.id}" })     # full entry`);
  lines.push(`fleet_health({ id: "${t.id}" })   # probe path + ports`);
  lines.push(`fleet_invoke({ id: "${t.id}" })   # run the declared command`);
  lines.push("```");
  lines.push("");
  if (t.invoke_cli) {
    lines.push(`Or from any shell (shim on PATH): \`${t.invoke_cli} --help\``);
    lines.push("");
  }
  return lines.join("\n");
}

function renderIndex() {
  const lines = [];
  lines.push("# Fleet Tools");
  lines.push("");
  lines.push("External repos registered as tools for the agent fleet. Canonical source:");
  lines.push("`agent-os/tools/registry.json`. One command file per tool:");
  lines.push("");
  lines.push("| Command | id | kind | status |");
  lines.push("|---|---|---|---|");
  REG.tools.forEach((t) => lines.push(`| ${t.id} | \`${t.id}\` | ${t.kind} | \`${t.status}\` |`));
  lines.push("");
  lines.push("## MCP access");
  lines.push("");
  lines.push("The `fleet-tools` MCP server exposes `fleet_list`, `fleet_info`,");
  lines.push("`fleet_health` and `fleet_invoke`. The `fleet` CLI mirrors it:");
  lines.push("");
  lines.push("```");
  lines.push("fleet list");
  lines.push("fleet info <id>");
  lines.push("fleet health [id]");
  lines.push("fleet invoke <id> [command]");
  lines.push("fleet mcp          # run the MCP server on stdio");
  lines.push("```");
  lines.push("");
  return lines.join("\n");
}

fs.writeFileSync(path.join(CMD_DIR, "index.md"), renderIndex(), "utf8");
wrote.push("commands/tools/index.md");
for (const t of REG.tools) {
  fs.writeFileSync(path.join(CMD_DIR, `${t.id}.md`), renderCommand(t), "utf8");
  wrote.push(`commands/tools/${t.id}.md`);
}

// ------------------------------------------------------------ shims
function cmd(lines) {
  return lines.join(CRLF) + CRLF;
}

// explicit shim bodies; fallback = informational
const SHIMS = {
  fleet: () =>
    cmd([
      "@echo off",
      `node "${FLEET_CLI}" %*`,
    ]),
  paperclipai: (t) =>
    cmd([
      "@echo off",
      "setlocal",
      `set "ENTRY=${t.path}\\cli\\dist\\index.js"`,
      'if not exist "%ENTRY%" (',
      "  echo [fleet] paperclip is not built yet.",
      `  echo   cd /d "${t.path}\\cli" ^&^& npm install ^&^& npm run build`,
      "  exit /b 1",
      ")",
      'node "%ENTRY%" %*',
      "endlocal",
    ]),
  agl: (t) =>
    cmd([
      "@echo off",
      "setlocal",
      `set "S=${t.venv || "."}\\Scripts"`,
      'set "CLI="',
      'if exist "%S%\\agl.exe" set "CLI=%S%\\agl.exe"',
      'if not defined CLI if exist "%S%\\agl-server.exe" set "CLI=%S%\\agl-server.exe"',
      'if not defined CLI if exist "%S%\\agl-controller.exe" set "CLI=%S%\\agl-controller.exe"',
      "if not defined CLI (",
      "  echo [fleet] agent-lightning CLI not found in %S%",
      "  exit /b 1",
      ")",
      '"%CLI%" %*',
      "exit /b %errorlevel%",
      "endlocal",
    ]),
  orchestrator: (t) =>
    cmd([
      "@echo off",
      "setlocal",
      `set "PYTHONPATH=${t.path}\\src"`,
      `set "PY=${t.venv || "python"}\\Scripts\\python.exe"`,
      `cd /d "${t.path}"`,
      '"%PY%" -m vertex_orchestrator.server %*',
      "endlocal",
    ]),
  mindmap: (t) =>
    cmd([
      "@echo off",
      "setlocal",
      `set "PY=${t.venv || "python"}\\Scripts\\python.exe"`,
      `cd /d "${t.path}"`,
      '"%PY%" -m uvicorn backend.app:app --reload %*',
      "endlocal",
    ]),
  "memory-palace": (t) =>
    cmd([
      "@echo off",
      "setlocal",
      `cd /d "${t.path}"`,
      "if not exist node_modules (",
      "  echo [fleet] installing memory-palace deps...",
      "  call npm install",
      ")",
      "call npm run dev %*",
      "endlocal",
    ]),
};

function fallbackShim(t) {
  const first = t.setup?.[0] || "(no setup declared)";
  return cmd([
    "@echo off",
    `echo [fleet] ${t.id} - ${t.kind} (${t.status})`,
    `echo   repo: ${t.path}`,
    `echo   setup: ${first}`,
    `echo   see: P:\\agent-os\\commands\\tools\\${t.id}.md`,
  ]);
}

// facade always
{
  const p = path.join(NPM_BIN, "fleet.cmd");
  fs.writeFileSync(p, SHIMS.fleet(), "utf8");
  wrote.push(`npm\\fleet.cmd`);
}

const cliNames = new Set();
for (const t of REG.tools) {
  const cli = t.invoke_cli;
  if (!cli) continue;
  if (cliNames.has(cli)) continue;
  cliNames.add(cli);
  const body = SHIMS[cli] ? SHIMS[cli](t) : fallbackShim(t);
  const p = path.join(NPM_BIN, `${cli}.cmd`);
  fs.writeFileSync(p, body, "utf8");
  wrote.push(`npm\\${cli}.cmd`);
}

console.log("sync-tools: wrote");
for (const w of wrote) console.log("  " + w);
