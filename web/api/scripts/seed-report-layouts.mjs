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
 * Extrae la constante exportada de un archivo .ts sin compilar.
 * Busca `export const XXX = { ... }` y evalua el objeto JSON-like.
 */
function extractLayoutFromFile(filePath) {
  let src = readFileSync(filePath, "utf-8");

  // Quitar JSDoc comments
  src = src.replace(/\/\*\*[\s\S]*?\*\//g, "");
  // Quitar line comments
  src = src.replace(/\/\/.*$/gm, "");
  // Quitar `as const`, `as "landscape"`, etc.
  src = src.replace(/\s+as\s+(?:const|"[^"]*"|'[^']*')/g, "");
  // Quitar `export const XXX =` para dejar solo el objeto
  const match = src.match(/export\s+const\s+(\w+)\s*=\s*(\{[\s\S]*\})\s*;?\s*$/);
  if (!match) return null;

  const exportName = match[1];
  const objStr = match[2];

  try {
    // Convertir a JSON valido: quitar trailing commas, quotear keys
    const jsonStr = objStr
      .replace(/,\s*([\]}])/g, "$1")          // trailing commas
      .replace(/(\w+)\s*:/g, '"$1":')         // unquoted keys
      .replace(/""(\w+)"":/g, '"$1":')        // fix double-quoted keys
      .replace(/"(\w+)""/g, '"$1"')           // fix trailing double quotes
      ;

    const layout = JSON.parse(jsonStr);
    return { exportName, layout };
  } catch (e) {
    // Fallback: usar Function constructor (safe — solo literals)
    try {
      const fn = new Function(`return (${objStr})`);
      return { exportName, layout: fn() };
    } catch (e2) {
      console.warn(`  WARN: no se pudo parsear ${basename(filePath)}: ${e2.message}`);
      return null;
    }
  }
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
      const result = extractLayoutFromFile(filePath);
      if (result) {
        const templateId = `${mod}-${basename(file, ".ts")}`;
        layouts.push({
          templateId,
          module: mod,
          file: `${mod}/${file}`,
          exportName: result.exportName,
          layout: result.layout,
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
      sampleData: {},
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
