#!/usr/bin/env node
/**
 * backoffice-setup-totp.cjs — ALERT-2 recovery script
 *
 * Siembra (o rota) el secret TOTP del backoffice directamente en BD. Se usa
 * cuando:
 *   - Se monta un ambiente nuevo y el secret aún no existe en cfg."BackofficeAuth".
 *   - Se pierde el autenticador y no se puede usar el flujo /setup/regenerate.
 *   - La migración del secret desde env var (comportamiento viejo previo a
 *     ALERT-2) no se hizo a tiempo.
 *
 * Es idempotente:
 *   - Sin flags: si ya hay secret en BD, lo muestra y SALE sin escribir.
 *   - `--force`: regenera + imprime nuevo secret (invalida autenticadores previos).
 *   - `--secret <base32>`: usa el secret provisto en lugar de generar uno.
 *
 * Uso:
 *   node scripts/backoffice-setup-totp.cjs
 *   node scripts/backoffice-setup-totp.cjs --force
 *   node scripts/backoffice-setup-totp.cjs --force --secret JBSWY3DPEHPK3PXP
 *
 * Requiere variables de entorno PG_* (mismas que la API). Ver config/env.ts.
 */
"use strict";

const { Client } = require("pg");

function parseArgs(argv) {
  const args = { force: false, secret: null };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--force") args.force = true;
    else if (a === "--secret" && argv[i + 1]) {
      args.secret = argv[++i];
    } else if (a === "--help" || a === "-h") {
      args.help = true;
    }
  }
  return args;
}

function printHelp() {
  console.log(`backoffice-setup-totp.cjs — setup/rotate TOTP secret for backoffice

Usage:
  node scripts/backoffice-setup-totp.cjs             # show or seed (idempotent)
  node scripts/backoffice-setup-totp.cjs --force     # regenerate new secret
  node scripts/backoffice-setup-totp.cjs --force --secret JBSWY3DPEHPK3PXP

Requires PG_HOST, PG_PORT, PG_DATABASE, PG_USER, PG_PASSWORD in env.`);
}

function generateBase32Secret(bytes = 20) {
  // RFC 4648 base32 alphabet, 20 bytes (160 bits) = 32 base32 chars — estándar TOTP.
  const crypto = require("node:crypto");
  const raw = crypto.randomBytes(bytes);
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  let bits = 0;
  let value = 0;
  let out = "";
  for (let i = 0; i < raw.length; i++) {
    value = (value << 8) | raw[i];
    bits += 8;
    while (bits >= 5) {
      out += alphabet[(value >>> (bits - 5)) & 31];
      bits -= 5;
    }
  }
  if (bits > 0) {
    out += alphabet[(value << (5 - bits)) & 31];
  }
  return out;
}

async function main() {
  const args = parseArgs(process.argv);
  if (args.help) {
    printHelp();
    process.exit(0);
  }

  const client = new Client({
    host: process.env.PG_HOST || "localhost",
    port: Number(process.env.PG_PORT || 5432),
    database: process.env.PG_DATABASE || "zentto_prod",
    user: process.env.PG_USER || "postgres",
    password: process.env.PG_PASSWORD || "",
    ssl:
      String(process.env.PG_SSL || "false").toLowerCase() === "true"
        // nosemgrep: bypass-tls-verification — internal Docker network (172.18.0.x), self-signed certs.
        ? { rejectUnauthorized: false }
        : false,
  });

  await client.connect();
  try {
    // Leer valor actual
    const current = await client.query(
      'SELECT "Value", "UpdatedAt" FROM cfg."BackofficeAuth" WHERE "Key" = $1 LIMIT 1',
      ["totp_secret"]
    );
    const already = current.rows[0]?.Value ?? null;

    if (already && !args.force) {
      console.log("[backoffice-setup-totp] Secret ya existe en BD.");
      console.log(
        `  UpdatedAt : ${current.rows[0].UpdatedAt?.toISOString?.() ?? current.rows[0].UpdatedAt}`
      );
      console.log("  Usa --force para regenerar (esto invalida el autenticador actual).");
      return;
    }

    const secret = args.secret || generateBase32Secret(20);
    // SP idempotente con ON CONFLICT
    await client.query(
      "SELECT * FROM usp_cfg_backoffice_auth_set($1, $2)",
      ["totp_secret", secret]
    );

    const action = already ? "ROTADO" : "SEMBRADO";
    console.log(`[backoffice-setup-totp] Secret ${action} correctamente.`);
    console.log("  Key    : totp_secret");
    console.log(`  Secret : ${secret}`);
    console.log(
      "  Escanea este secret (base32) en Google Authenticator / Authy / Bitwarden"
    );
    console.log(
      "  o usa el endpoint POST /v1/backoffice/auth/setup para generar el QR."
    );
    if (already) {
      console.log(
        "  WARNING: el secret anterior quedó invalidado. Actualiza todos los autenticadores."
      );
    }
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error("[backoffice-setup-totp] ERROR:", err?.message ?? err);
  process.exitCode = 1;
});
