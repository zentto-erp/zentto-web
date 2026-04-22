#!/usr/bin/env node
/**
 * Post-build: copia JSON (seeds) y otros assets estáticos de src/ → dist/
 * preservando la estructura relativa.
 *
 * tsc NO copia archivos que no son .ts/.tsx aunque tenga `resolveJsonModule`.
 */
"use strict";
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const SRC = path.join(ROOT, "src");
const DIST = path.join(ROOT, "dist");

const EXTENSIONS_TO_COPY = [".json"];

function walk(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      // skip __tests__
      if (entry.name === "__tests__") continue;
      walk(fullPath);
    } else if (entry.isFile()) {
      const ext = path.extname(entry.name).toLowerCase();
      if (!EXTENSIONS_TO_COPY.includes(ext)) continue;
      const rel = path.relative(SRC, fullPath);
      const target = path.join(DIST, rel);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.copyFileSync(fullPath, target);
      // eslint-disable-next-line no-console
      console.log(`[copy-assets] ${rel}`);
    }
  }
}

if (!fs.existsSync(SRC)) {
  console.error(`[copy-assets] src/ no existe: ${SRC}`);
  process.exit(1);
}
if (!fs.existsSync(DIST)) {
  console.warn(`[copy-assets] dist/ no existe, skip (¿tsc falló?)`);
  process.exit(0);
}

walk(SRC);
