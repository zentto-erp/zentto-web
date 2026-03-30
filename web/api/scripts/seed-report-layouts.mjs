#!/usr/bin/env node
/**
 * seed-report-layouts.mjs
 *
 * Inserta los 25 report layouts base en la BD (zentto-cache) como templates
 * publicos (company-wide). Los usuarios pueden luego editarlos con el Designer
 * sin necesitar un deploy.
 *
 * Uso:
 *   node scripts/seed-report-layouts.mjs
 *   node scripts/seed-report-layouts.mjs --base-url http://localhost:3001
 *   node scripts/seed-report-layouts.mjs --base-url https://api.zentto.net
 *
 * Env vars (opcionales):
 *   BASE_URL   — URL base de la API (default: http://localhost:3001)
 *   SEED_USER  — Usuario para auth (default: SUP)
 *   SEED_PASS  — Clave para auth (default: SUP)
 */

import { readFileSync, readdirSync, statSync } from "fs";
import { join, basename, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

/* ── Config ──────────────────────────────────────────────────── */
const args = process.argv.slice(2);
function getArg(name) {
  const eq = args.find((a) => a.startsWith(`--${name}=`));
  if (eq) return eq.split("=").slice(1).join("=");
  const idx = args.indexOf(`--${name}`);
  return idx >= 0 ? args[idx + 1] : undefined;
}
const BASE_URL = getArg("base-url") || process.env.BASE_URL || "http://localhost:3001";
const SEED_USER = getArg("user") || process.env.SEED_USER || "SUP";
const SEED_PASS = getArg("pass") || process.env.SEED_PASS || "SUP";

/* ── Layouts directory (monorepo) ────────────────────────────── */
const LAYOUTS_DIR = join(__dirname, "../../modular-frontend/packages/shared-reports/src/layouts");

/* ── Helpers ─────────────────────────────────────────────────── */
async function request(method, path, body, headers = {}) {
  const url = new URL(path, BASE_URL);
  const res = await fetch(url, {
    method,
    headers: { "Content-Type": "application/json", ...headers },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try { json = JSON.parse(text); } catch { json = { raw: text }; }
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${JSON.stringify(json)}`);
  return json;
}

/**
 * Extrae TODAS las constantes exportadas de un archivo .ts sin compilar.
 * Retorna un Map<exportName, object>.
 */
function extractExportsFromFile(filePath) {
  let src = readFileSync(filePath, "utf-8");
  src = src.replace(/\/\*\*[\s\S]*?\*\//g, ""); // JSDoc
  src = src.replace(/\/\/.*$/gm, "");            // line comments
  src = src.replace(/\s+as\s+(?:const|"[^"]*"|'[^']*')/g, ""); // as const

  const results = new Map();
  const regex = /export\s+const\s+(\w+)\s*=\s*(\{[\s\S]*?\n\});\s*/g;
  let m;
  while ((m = regex.exec(src)) !== null) {
    const name = m[1];
    const objStr = m[2];
    try {
      const fn = new Function(`return (${objStr})`);
      results.set(name, fn());
    } catch {
      // skip unparseable
    }
  }
  return results;
}

/**
 * Recorre layouts/ y extrae todos los layouts por modulo.
 */
function discoverLayouts() {
  const layouts = [];
  const modules = readdirSync(LAYOUTS_DIR).filter((f) => {
    const full = join(LAYOUTS_DIR, f);
    return statSync(full).isDirectory();
  });

  for (const mod of modules) {
    const modDir = join(LAYOUTS_DIR, mod);
    const files = readdirSync(modDir).filter((f) => f.endsWith(".ts") && f !== "index.ts");

    for (const file of files) {
      const filePath = join(modDir, file);
      const exports = extractExportsFromFile(filePath);

      // Find the layout (non-SAMPLE export) and its matching SAMPLE
      let layoutName = null;
      let layoutObj = null;
      let sampleObj = {};

      for (const [name, obj] of exports) {
        if (name.endsWith("_SAMPLE")) {
          sampleObj = obj;
        } else if (obj.version && obj.bands) {
          layoutName = name;
          layoutObj = obj;
        }
      }

      if (layoutObj) {
        const templateId = `${mod}-${basename(file, ".ts")}`;
        layouts.push({
          templateId,
          module: mod,
          file: `${mod}/${file}`,
          exportName: layoutName,
          layout: layoutObj,
          sampleData: sampleObj,
        });
      }
    }
  }

  return layouts;
}

/* ── Main ────────────────────────────────────────────────────── */
async function main() {
  console.log(`\n=== Seed Report Layouts ===`);
  console.log(`API: ${BASE_URL}`);
  console.log(`User: ${SEED_USER}\n`);

  // 1. Discover layouts
  const layouts = discoverLayouts();
  console.log(`Layouts encontrados: ${layouts.length}\n`);

  if (layouts.length === 0) {
    console.error("ERROR: No se encontraron layouts en", LAYOUTS_DIR);
    process.exit(1);
  }

  // 2. Authenticate
  let token;
  try {
    const auth = await request("POST", "/v1/auth/login", {
      usuario: SEED_USER,
      clave: SEED_PASS,
    });
    token = auth.token;
    console.log("Auth OK\n");
  } catch (err) {
    console.error("ERROR auth:", err.message);
    console.error("Asegurese de que la API esta corriendo y las credenciales son correctas.");
    process.exit(1);
  }

  const headers = { Authorization: `Bearer ${token}` };

  // 3. Seed each layout as public template
  let ok = 0;
  let fail = 0;

  for (const item of layouts) {
    const id = item.templateId;
    const body = {
      name: item.layout.name || id,
      layout: item.layout,
      sampleData: item.sampleData || {},
    };

    try {
      await request("PUT", `/v1/reportes/public/${id}`, body, headers);
      console.log(`  OK    ${id}  (${item.layout.name || "?"})`);
      ok++;
    } catch (err) {
      console.log(`  FAIL  ${id}  => ${err.message}`);
      fail++;
    }
  }

  console.log(`\n--- Resultado ---`);
  console.log(`Total: ${layouts.length} | OK: ${ok} | FAIL: ${fail}`);
  console.log(`Endpoint usado: PUT /v1/reportes/public/:id\n`);

  if (fail > 0) process.exit(1);
}

main().catch((err) => {
  console.error("Fatal:", err);
  process.exit(1);
});
