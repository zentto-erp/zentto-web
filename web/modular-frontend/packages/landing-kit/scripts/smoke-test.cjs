#!/usr/bin/env node
/**
 * Smoke test sin framework — valida que el runtime renderer compilado:
 *  1. Parsea el seed real del hotel con Zod.
 *  2. Cubre todos los section types del seed en SECTION_MAP.
 *  3. Resuelve todos los iconIds del seed en ICON_MAP.
 *  4. Rechaza schemas inválidos devolviendo undefined.
 *
 * Ejecutar tras `npm run build`:
 *   node scripts/smoke-test.cjs
 *
 * Exit code 0 = OK; 1 = alguna aserción falló.
 */
"use strict";

const path = require("path");

function fail(msg) {
  console.error("\x1b[31mFAIL:\x1b[0m " + msg);
  process.exit(1);
}

function ok(msg) {
  console.log("\x1b[32mOK\x1b[0m  " + msg);
}

let safeParseSchema, SECTION_MAP, hasIcon, ICON_MAP, seed;
try {
  ({ safeParseSchema } = require("../dist/renderer/schema.zod.js"));
  ({ SECTION_MAP } = require("../dist/renderer/section-map.js"));
  ({ hasIcon, ICON_MAP } = require("../dist/renderer/icon-registry.js"));
  seed = require("../dist/renderer/seeds/hotel.seed.json");
} catch (e) {
  fail(
    "dist no presente o incompleto. Ejecutar `npm run build` antes del smoke test.\n  " +
      e.message,
  );
}

// 1. Zod
const parsed = safeParseSchema(seed);
if (!parsed) fail("seed hotel no parseó con Zod");
ok(
  `Zod: seed hotel (id=${parsed.id}) parseado — ${parsed.landingConfig.sections.length} sections`,
);

// 2. SECTION_MAP cubre todos los types
const types = [...new Set(parsed.landingConfig.sections.map((s) => s.type))];
const missingTypes = types.filter((t) => !(t in SECTION_MAP));
if (missingTypes.length > 0) {
  fail("SECTION_MAP no cubre types del seed: " + missingTypes.join(", "));
}
ok(`SECTION_MAP: cubre ${types.length} types (${types.join(", ")})`);

// 3. Icon registry cubre todos los iconIds
const stack = [seed];
const iconIds = new Set();
while (stack.length > 0) {
  const obj = stack.pop();
  if (obj == null || typeof obj !== "object") continue;
  if (Array.isArray(obj)) {
    obj.forEach((i) => stack.push(i));
    continue;
  }
  for (const [k, v] of Object.entries(obj)) {
    if ((k === "iconId" || k === "logoIconId") && typeof v === "string") {
      iconIds.add(v);
    } else {
      stack.push(v);
    }
  }
}
const missingIcons = [...iconIds].filter((i) => !hasIcon(i));
if (missingIcons.length > 0) {
  fail("ICON_MAP no cubre iconIds del seed: " + missingIcons.join(", "));
}
ok(`ICON_MAP: cubre ${iconIds.size} iconIds del seed; total registrado ${Object.keys(ICON_MAP).length}`);

// 4. Schema inválido → undefined sin lanzar
const invalid = safeParseSchema({ not: "a landing" });
if (invalid !== undefined) fail("schema inválido debería devolver undefined");
ok("safeParseSchema: schema inválido devuelve undefined sin lanzar");

console.log("\n\x1b[32m[SMOKE TEST]\x1b[0m renderer OK — dist/ es funcional.");
