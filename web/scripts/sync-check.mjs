import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const root = resolve(process.cwd());
const openApiPath = resolve(root, "contracts/openapi.yaml");
const statusPath = resolve(root, "STATUS.md");

const openapi = readFileSync(openApiPath, "utf8");
const status = readFileSync(statusPath, "utf8");

const requiredPaths = [
  "/v1/auth/login",
  "/v1/facturas",
  "/v1/facturas/{numFact}",
  "/v1/facturas/{numFact}/detalle"
];

const requiredStatusBlocks = [
  "## Carril Backend",
  "## Carril Frontend",
  "### Backlog",
  "### En curso",
  "### Hecho"
];

let ok = true;

for (const p of requiredPaths) {
  if (!openapi.includes(p)) {
    ok = false;
    console.error(`[sync-check] falta endpoint en contrato: ${p}`);
  }
}

for (const b of requiredStatusBlocks) {
  if (!status.includes(b)) {
    ok = false;
    console.error(`[sync-check] falta bloque en STATUS: ${b}`);
  }
}

if (!ok) {
  process.exit(1);
}

console.log("[sync-check] contrato y tablero en formato valido");
