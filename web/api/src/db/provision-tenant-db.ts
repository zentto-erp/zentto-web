/**
 * provision-tenant-db.ts — Crea una BD dedicada para un tenant
 *
 * Flujo: CREATE DATABASE → extensiones → goose up → seeds config+starter → registrar en sys.TenantDatabase
 */
import { Client } from "pg";
import { execSync } from "node:child_process";
import { env } from "../config/env.js";
import { getMasterPool, getTenantPool } from "./pg-pool-manager.js";
import { invalidateTenantCache } from "./tenant-resolver.js";
import { obs } from "../modules/integrations/observability.js";

export interface ProvisionResult {
  ok: boolean;
  dbName: string;
  error?: string;
}

export async function provisionTenantDatabase(
  companyId: number,
  companyCode: string,
): Promise<ProvisionResult> {
  // Sanitizar nombre de BD
  const dbName = `zentto_tenant_${companyCode.toLowerCase().replace(/[^a-z0-9]/g, "_")}`;

  // Conexión admin (sin database específica, para CREATE DATABASE)
  const adminClient = new Client({
    host: env.pg?.host || process.env.PG_HOST || "localhost",
    port: env.pg?.port || Number(process.env.PG_PORT) || 5432,
    user: env.pg?.user || process.env.PG_USER || "postgres",
    password: env.pg?.password || process.env.PG_PASSWORD || "",
    database: "postgres", // Conectar a BD sistema para CREATE DATABASE
  });

  obs.audit("tenant.db.provision.start", { module: "provision-db", companyId, companyCode, dbName });

  try {
    await adminClient.connect();

    // 1. Verificar si la BD ya existe
    const exists = await adminClient.query(
      "SELECT 1 FROM pg_database WHERE datname = $1",
      [dbName],
    );
    if (exists.rows.length === 0) {
      await adminClient.query(`CREATE DATABASE "${dbName}" OWNER zentto_app`);
      obs.log("info", `[provision] BD creada: ${dbName}`, { companyId });
    } else {
      obs.log("info", `[provision] BD ya existe: ${dbName}`, { companyId });
    }
    await adminClient.end();

    // 2. Crear extensiones en la nueva BD
    const tenantPool = getTenantPool({ dbName });
    await tenantPool.query("CREATE EXTENSION IF NOT EXISTS pg_trgm");
    await tenantPool.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"');
    await tenantPool.query("CREATE EXTENSION IF NOT EXISTS btree_gin");
    obs.log("info", `[provision] Extensiones activadas en ${dbName}`, { companyId });

    // 3. Ejecutar goose migrations
    const gooseBin = process.env.GOOSE_BIN || "goose";
    const migrationsDir =
      process.env.GOOSE_DIR || "/app/migrations/postgres";
    const pgHost = env.pg?.host || process.env.PG_HOST || "localhost";
    const pgPort = env.pg?.port || Number(process.env.PG_PORT) || 5432;
    const pgUser = env.pg?.user || process.env.PG_USER || "postgres";
    const pgPassword = env.pg?.password || process.env.PG_PASSWORD || "";
    const dbUrl = `postgres://${pgUser}:${pgPassword}@${pgHost}:${pgPort}/${dbName}?sslmode=disable`;

    obs.log("info", `[provision] Iniciando goose migrations en ${dbName}`, { companyId, migrationsDir });
    execSync(`${gooseBin} -dir "${migrationsDir}" postgres "${dbUrl}" up`, {
      timeout: 300_000, // 5 min max
      stdio: "inherit",
    });
    obs.audit("tenant.db.migrations.ok", { module: "provision-db", companyId, dbName });

    // 4. Ejecutar seeds config + starter (via psql)
    const seedsDir = process.env.SEEDS_DIR || "/opt/zentto/sqlweb-pg";
    try {
      execSync(
        `PGPASSWORD="${pgPassword}" psql -U "${pgUser}" -h "${pgHost}" -p ${pgPort} -d "${dbName}" -v ON_ERROR_STOP=0 -f "${seedsDir}/run-seeds-config.sql"`,
        { timeout: 120_000, stdio: "inherit", cwd: seedsDir },
      );
      execSync(
        `PGPASSWORD="${pgPassword}" psql -U "${pgUser}" -h "${pgHost}" -p ${pgPort} -d "${dbName}" -v ON_ERROR_STOP=0 -f "${seedsDir}/run-seeds-starter.sql"`,
        { timeout: 120_000, stdio: "inherit", cwd: seedsDir },
      );
      obs.audit("tenant.db.seeds.ok", { module: "provision-db", companyId, dbName });
    } catch (seedErr: any) {
      console.warn(`[provision] Seeds warning for ${dbName}:`, seedErr.message);
      obs.error(`tenant.db.seeds.warning: ${seedErr.message}`, { companyId, dbName });
      // No fallar por seeds — la BD ya tiene el schema
    }

    // 5. Registrar en sys.TenantDatabase (BD master)
    const masterPool = getMasterPool();
    await masterPool.query(
      `SELECT * FROM usp_sys_tenantdb_register($1, $2, $3)`,
      [companyId, companyCode, dbName],
    );
    obs.audit("tenant.db.registered", { module: "provision-db", companyId, companyCode, dbName });

    // 6. Invalidar cache
    invalidateTenantCache(companyId);

    obs.audit("tenant.db.provision.complete", { module: "provision-db", companyId, dbName });
    console.log(`[provision] BD ${dbName} creada para CompanyId=${companyId}`);
    return { ok: true, dbName };
  } catch (err: any) {
    console.error(`[provision] Error creando BD para ${companyCode}:`, err.message);
    obs.error(`tenant.db.provision.error: ${err.message}`, { module: "provision-db", companyId, companyCode, dbName });
    try {
      await adminClient.end();
    } catch {
      /* ya cerrada */
    }
    return { ok: false, dbName, error: err.message };
  }
}
