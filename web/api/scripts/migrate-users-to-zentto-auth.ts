/**
 * Script de migración: usuarios del ERP → zentto-auth microservice.
 *
 * Lee usuarios de la BD del ERP (tabla Usuarios / sec."User")
 * y los crea en zentto-auth via API POST /auth/admin/migrate-user.
 *
 * Uso:
 *   npx tsx scripts/migrate-users-to-zentto-auth.ts
 *
 * Variables de entorno:
 *   AUTH_SERVICE_URL — URL de zentto-auth (ej: http://localhost:4600)
 *   AUTH_ADMIN_KEY   — API key admin de zentto-auth
 *   PG_HOST, PG_PORT, PG_DATABASE, PG_USER, PG_PASSWORD — BD ERP
 */

import pg from "pg";
import dotenv from "dotenv";
dotenv.config();

const AUTH_URL = process.env.AUTH_SERVICE_URL || "http://localhost:4600";
const AUTH_KEY = process.env.AUTH_ADMIN_KEY || "";

const pool = new pg.Pool({
  host: process.env.PG_HOST || "localhost",
  port: Number(process.env.PG_PORT || 5432),
  database: process.env.PG_DATABASE || "datqboxweb",
  user: process.env.PG_USER || "postgres",
  password: process.env.PG_PASSWORD || "",
});

interface ErpUser {
  Cod_Usuario: string;
  Nombre: string;
  Password: string;
  Tipo: string;
  Email?: string;
}

async function getErpUsers(): Promise<ErpUser[]> {
  // Intentar PostgreSQL (sec schema)
  try {
    const result = await pool.query(`
      SELECT "Cod_Usuario", "Nombre", "Password", "Tipo"
      FROM sec."User"
      WHERE "Password" LIKE '$2%'
      ORDER BY "Cod_Usuario"
    `);
    return result.rows;
  } catch {
    // Fallback: SQL Server legacy
    const result = await pool.query(`
      SELECT "Cod_Usuario", "Nombre", "Password", "Tipo"
      FROM "Usuarios"
      WHERE "Password" LIKE '$2%'
      ORDER BY "Cod_Usuario"
    `);
    return result.rows;
  }
}

async function migrateUser(user: ErpUser) {
  const isAdmin = user.Tipo === "ADMIN" || user.Tipo === "SUP" || user.Cod_Usuario.toUpperCase() === "SUP";

  const body = {
    username: user.Cod_Usuario.trim().toUpperCase(),
    passwordHash: user.Password, // bcrypt hash — se copia directamente
    displayName: user.Nombre,
    email: user.Email || null,
    isAdmin,
    isActive: true,
    emailVerified: true,
    appRoles: {
      "zentto-erp": isAdmin ? ["admin"] : ["user"],
    },
  };

  try {
    const res = await fetch(`${AUTH_URL}/auth/admin/migrate-user`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Admin-Key": AUTH_KEY,
      },
      body: JSON.stringify(body),
    });

    if (res.ok) {
      console.log(`  OK: ${user.Cod_Usuario}`);
      return true;
    }

    const err = await res.text();
    if (err.includes("already exists") || err.includes("duplicate")) {
      console.log(`  SKIP: ${user.Cod_Usuario} (ya existe)`);
      return true;
    }

    console.error(`  FAIL: ${user.Cod_Usuario} — ${res.status} ${err}`);
    return false;
  } catch (err) {
    console.error(`  ERROR: ${user.Cod_Usuario} — ${err}`);
    return false;
  }
}

async function main() {
  console.log("=== Migración de usuarios ERP → zentto-auth ===");
  console.log(`Auth URL: ${AUTH_URL}`);
  console.log("");

  const users = await getErpUsers();
  console.log(`Usuarios encontrados: ${users.length}`);
  console.log("");

  let ok = 0;
  let fail = 0;

  for (const user of users) {
    const success = await migrateUser(user);
    if (success) ok++;
    else fail++;
  }

  console.log("");
  console.log(`=== Resultado: ${ok} migrados, ${fail} fallidos ===`);

  await pool.end();
}

main().catch((err) => {
  console.error("Error fatal:", err);
  process.exit(1);
});
