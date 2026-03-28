/**
 * sp-contracts-mssql.test.ts
 *
 * Valida TODOS los stored procedures de SQL Server (zentto_dev) automáticamente.
 * Equivalente de sp-contracts.test.ts pero para SQL Server 2012.
 *
 * - Escanea sys.procedures en tiempo real
 * - Verifica que tablas canónicas existan
 * - Verifica que SPs críticos existan y sean ejecutables
 * - Solo lectura — no modifica datos
 *
 * Variables de entorno:
 *   MSSQL_SERVER, MSSQL_DATABASE, MSSQL_USER, MSSQL_PASSWORD
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import sql from "mssql";
import "dotenv/config";

// ────────────────────────────────────────────────────────────────────────────
// Conexión
// ────────────────────────────────────────────────────────────────────────────

let pool: sql.ConnectionPool;

beforeAll(async () => {
  pool = await sql.connect({
    server: process.env.MSSQL_SERVER ?? "DELLXEONE31545",
    database: process.env.MSSQL_DATABASE ?? "zentto_dev",
    user: process.env.MSSQL_USER ?? "sa",
    password: process.env.MSSQL_PASSWORD ?? "1234",
    options: {
      encrypt: false,
      trustServerCertificate: true,
    },
    connectionTimeout: 10000,
    requestTimeout: 30000,
  });
});

afterAll(async () => {
  await pool.close();
});

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

interface SpInfo {
  schema_name: string;
  name: string;
  param_count: number;
}

async function getAllProcedures(): Promise<SpInfo[]> {
  const r = await pool.request().query(`
    SELECT
      SCHEMA_NAME(p.schema_id) AS schema_name,
      p.name,
      (SELECT COUNT(*) FROM sys.parameters pm WHERE pm.object_id = p.object_id) AS param_count
    FROM sys.procedures p
    WHERE p.name LIKE 'usp_%' OR p.name LIKE 'sp_%'
    ORDER BY p.name
  `);
  return r.recordset;
}

async function getTableCount(): Promise<number> {
  const r = await pool.request().query(
    "SELECT COUNT(*) AS cnt FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'"
  );
  return r.recordset[0].cnt;
}

async function getSchemaTableCounts(): Promise<Record<string, number>> {
  const r = await pool.request().query(`
    SELECT TABLE_SCHEMA, COUNT(*) AS cnt
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = 'BASE TABLE'
    GROUP BY TABLE_SCHEMA
    ORDER BY TABLE_SCHEMA
  `);
  const result: Record<string, number> = {};
  for (const row of r.recordset) {
    result[row.TABLE_SCHEMA] = row.cnt;
  }
  return result;
}

async function tableExists(schema: string, table: string): Promise<boolean> {
  const r = await pool.request().query(
    `SELECT OBJECT_ID('${schema}.${table}', 'U') AS id`
  );
  return r.recordset[0].id !== null;
}

async function spExists(name: string): Promise<boolean> {
  const r = await pool.request().query(
    `SELECT OBJECT_ID('dbo.${name}', 'P') AS id`
  );
  return r.recordset[0].id !== null;
}

// ────────────────────────────────────────────────────────────────────────────
// Test 1: DB bootstrapped
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts MSSQL — DB bootstrapped", () => {
  it("debe tener al menos 100 tablas", async () => {
    const count = await getTableCount();
    expect(count, `Solo hay ${count} tablas`).toBeGreaterThanOrEqual(100);
    console.log(`  ℹ  Total tablas: ${count}`);
  });

  it("debe tener al menos 15 schemas de negocio", async () => {
    const counts = await getSchemaTableCounts();
    const businessSchemas = Object.keys(counts).filter(
      (s) => !["dbo", "guest", "INFORMATION_SCHEMA", "sys"].includes(s)
    );
    expect(businessSchemas.length).toBeGreaterThanOrEqual(15);
    console.log(`  ℹ  Schemas de negocio: ${businessSchemas.join(", ")}`);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Test 2: Tablas canónicas críticas
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts MSSQL — tablas canónicas", () => {
  const criticalTables = [
    ["sec", "User"],
    ["sec", "Role"],
    ["sec", "UserRole"],
    ["sec", "AuthIdentity"],
    ["sec", "AuthToken"],
    ["cfg", "Country"],
    ["cfg", "Company"],
    ["cfg", "Branch"],
    ["cfg", "ExchangeRateDaily"],
    ["mstr", "Customer"],
    ["mstr", "Supplier"],
    ["mstr", "Employee"],
    ["mstr", "Product"],
    ["acct", "Account"],
    ["acct", "JournalEntry"],
    ["acct", "JournalEntryLine"],
    ["ar", "ReceivableDocument"],
    ["ar", "ReceivableApplication"],
    ["ap", "PayableDocument"],
    ["ap", "PayableApplication"],
    ["pos", "WaitTicket"],
    ["pos", "SaleTicket"],
    ["rest", "OrderTicket"],
    ["rest", "DiningTable"],
    ["fin", "BankAccount"],
    ["fin", "BankMovement"],
    ["hr", "PayrollType"],
    ["hr", "PayrollConcept"],
    ["hr", "PayrollBatch"],
    ["pay", "PaymentMethods"],
    ["inv", "Warehouse"],
    ["inv", "ProductLot"],
    ["inv", "ProductSerial"],
    ["logistics", "Carrier"],
    ["logistics", "DeliveryNote"],
    ["crm", "Pipeline"],
    ["crm", "Lead"],
    ["mfg", "BillOfMaterials"],
    ["fleet", "Vehicle"],
    ["store", "ProductReview"],
    ["zsys", "TenantDatabase"],
    ["zsys", "License"],
    ["fiscal", "CountryConfig"],
    ["fiscal", "TaxRate"],
  ];

  for (const [schema, table] of criticalTables) {
    it(`${schema}.${table} debe existir`, async () => {
      const exists = await tableExists(schema, table);
      expect(exists, `Tabla ${schema}.${table} no existe`).toBe(true);
    });
  }
});

// ────────────────────────────────────────────────────────────────────────────
// Test 3: SPs críticos existen
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts MSSQL — SPs críticos", () => {
  const criticalSPs = [
    "usp_Sec_User_Authenticate",
    "usp_Sec_User_GetType",
    "usp_Sec_User_GetModuleAccess",
    "usp_Sec_User_ListCompanyAccesses_Default",
    "usp_Sec_User_GetCompanyAccesses",
    "usp_Sec_User_UpdatePassword",
    "usp_Cfg_ResolveContext",
    "usp_Cfg_AppSetting_List",
    "usp_Cfg_AppSetting_Upsert",
    "usp_Sys_HealthCheck",
    "usp_Sys_GetTableColumns",
  ];

  for (const sp of criticalSPs) {
    it(`${sp} debe existir`, async () => {
      const exists = await spExists(sp);
      expect(exists, `SP ${sp} no existe`).toBe(true);
    });
  }
});

// ────────────────────────────────────────────────────────────────────────────
// Test 4: Conteo general de SPs
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts MSSQL — conteo de SPs", () => {
  it("debe tener al menos 200 stored procedures", async () => {
    const procs = await getAllProcedures();
    expect(
      procs.length,
      `Solo hay ${procs.length} SPs — puede faltar ejecutar los scripts`
    ).toBeGreaterThanOrEqual(200);
    console.log(`  ℹ  Total SPs: ${procs.length}`);
  });

  it("muestra resumen de SPs por prefijo", async () => {
    const procs = await getAllProcedures();
    const byPrefix: Record<string, number> = {};
    for (const p of procs) {
      const prefix = p.name.split("_").slice(0, 2).join("_");
      byPrefix[prefix] = (byPrefix[prefix] || 0) + 1;
    }

    console.log("\n  📊 SPs por prefijo:");
    const sorted = Object.entries(byPrefix).sort((a, b) => b[1] - a[1]);
    for (const [prefix, count] of sorted) {
      console.log(`     ${prefix.padEnd(30)} ${count}`);
    }
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Test 5: Seed data
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts MSSQL — seed data", () => {
  it("debe tener al menos 1 usuario", async () => {
    const r = await pool.request().query("SELECT COUNT(*) AS c FROM sec.[User]");
    expect(r.recordset[0].c).toBeGreaterThanOrEqual(1);
  });

  it("debe tener al menos 1 company", async () => {
    const r = await pool.request().query("SELECT COUNT(*) AS c FROM cfg.Company");
    expect(r.recordset[0].c).toBeGreaterThanOrEqual(1);
  });

  it("debe tener al menos 3 países", async () => {
    const r = await pool.request().query("SELECT COUNT(*) AS c FROM cfg.Country");
    expect(r.recordset[0].c).toBeGreaterThanOrEqual(3);
  });

  it("debe tener al menos 1 branch", async () => {
    const r = await pool.request().query("SELECT COUNT(*) AS c FROM cfg.Branch");
    expect(r.recordset[0].c).toBeGreaterThanOrEqual(1);
  });
});

// ────────────────────────────────────────────────────────────────────────────
// Test 6: SPs ejecutables (smoke test)
// ────────────────────────────────────────────────────────────────────────────

describe("SP Contracts MSSQL — smoke tests", () => {
  it("usp_Sys_HealthCheck se ejecuta sin error", async () => {
    const r = await pool.request().execute("dbo.usp_Sys_HealthCheck");
    expect(r.recordset.length).toBeGreaterThanOrEqual(1);
  });

  it("usp_Sec_User_Authenticate devuelve usuario sa", async () => {
    const r = await pool
      .request()
      .input("CodUsuario", "sa")
      .execute("dbo.usp_Sec_User_Authenticate");
    expect(r.recordset.length).toBe(1);
    expect(r.recordset[0].Cod_Usuario).toBe("sa");
  });

  it("usp_Cfg_ResolveContext devuelve contexto válido", async () => {
    const r = await pool
      .request()
      .input("UserCode", sql.NVarChar(60), "sa")
      .execute("dbo.usp_Cfg_ResolveContext");
    expect(r.recordset.length).toBeGreaterThanOrEqual(1);
  });

  it("usp_Cfg_AppSetting_List se ejecuta sin error", async () => {
    const r = await pool
      .request()
      .input("CompanyId", sql.Int, 1)
      .execute("dbo.usp_Cfg_AppSetting_List");
    expect(r.recordset).toBeDefined();
  });
});
