#!/usr/bin/env node
/* eslint-disable @typescript-eslint/no-var-requires */
/**
 * Emite `dist/tokens.css` con las CSS variables de Zentto Design Tokens.
 *
 * Invocado desde `npm run build` tras `tsc -p tsconfig.build.json`. Si
 * `dist/index.js` no existe, corre el build TypeScript automáticamente.
 */
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const pkgDir = path.resolve(__dirname, '..');
const distDir = path.join(pkgDir, 'dist');
const entry = path.join(distDir, 'index.js');

if (!fs.existsSync(entry)) {
  console.log('[design-tokens] dist/index.js no existe — ejecutando tsc…');
  const r = spawnSync('npx', ['tsc', '-p', path.join(pkgDir, 'tsconfig.build.json')], {
    stdio: 'inherit',
    shell: true,
    cwd: pkgDir,
  });
  if (r.status !== 0) {
    console.error('[design-tokens] tsc falló.');
    process.exit(r.status || 1);
  }
}

const mod = require(entry);
const designTokens = mod.designTokens || mod.default;
const tokensToCss = mod.tokensToCss;

if (!designTokens || typeof tokensToCss !== 'function') {
  console.error('[design-tokens] dist/index.js no exporta designTokens/tokensToCss.');
  process.exit(1);
}

const css = tokensToCss(designTokens);
const outFile = path.join(distDir, 'tokens.css');
fs.writeFileSync(outFile, css, 'utf8');
console.log(`[design-tokens] ${path.relative(process.cwd(), outFile)} (${css.length} bytes)`);
