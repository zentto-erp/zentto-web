/**
 * sp-contracts-crm-redesign.test.ts
 *
 * Verifica que los 15 SPs del ADR-CRM-001 (Contact / Company / Deal)
 * existen en PostgreSQL. Idempotente y solo lectura.
 */
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import pg from "pg";
import "dotenv/config";

const REQUIRED_CRM_SPS = [
  // Company
  "usp_crm_company_list",
  "usp_crm_company_detail",
  "usp_crm_company_upsert",
  "usp_crm_company_delete",
  "usp_crm_company_search",
  // Contact
  "usp_crm_contact_list",
  "usp_crm_contact_detail",
  "usp_crm_contact_upsert",
  "usp_crm_contact_delete",
  "usp_crm_contact_search",
  "usp_crm_contact_promote_to_customer",
  // Deal
  "usp_crm_deal_list",
  "usp_crm_deal_detail",
  "usp_crm_deal_upsert",
  "usp_crm_deal_move_stage",
  "usp_crm_deal_close_won",
  "usp_crm_deal_close_lost",
  "usp_crm_deal_delete",
  "usp_crm_deal_search",
  "usp_crm_deal_timeline",
  // Lead conversion
  "usp_crm_lead_convert",
];

const REQUIRED_CRM_TABLES: Array<[string, string]> = [
  ["crm", "Company"],
  ["crm", "Contact"],
  ["crm", "Deal"],
  ["crm", "DealLine"],
  ["crm", "DealHistory"],
];

let pool: pg.Pool;

beforeAll(() => {
  pool = process.env.PG_CONNECTION_STRING
    ? new pg.Pool({ connectionString: process.env.PG_CONNECTION_STRING })
    : new pg.Pool({
        host: process.env.PG_HOST ?? "127.0.0.1",
        port: Number(process.env.PG_PORT ?? 5432),
        database: process.env.PG_DATABASE ?? "zentto_prod",
        user: process.env.PG_USER ?? "zentto_app",
        password: process.env.PG_PASSWORD ?? "",
        ssl:
          process.env.PG_SSL === "true" ? { rejectUnauthorized: false } : false, // nosemgrep: bypass-tls-verification
      });
});

afterAll(async () => {
  await pool.end();
});

describe("CRM Redesign (ADR-CRM-001) â€” Tablas", () => {
  for (const [schema, table] of REQUIRED_CRM_TABLES) {
    it(`${schema}.${table} debe existir`, async () => {
      const r = await pool.query(
        `SELECT 1 FROM information_schema.tables
          WHERE table_schema = $1 AND table_name = $2 LIMIT 1`,
        [schema, table],
      );
      expect(r.rowCount).toBe(1);
    });
  }

  it('crm."Lead" debe tener columna "ConvertedToDealId"', async () => {
    const r = await pool.query(
      `SELECT data_type FROM information_schema.columns
        WHERE table_schema='crm' AND table_name='Lead' AND column_name='ConvertedToDealId'`,
    );
    expect(r.rowCount).toBe(1);
    expect(r.rows[0].data_type).toBe("bigint");
  });
});

describe("CRM Redesign (ADR-CRM-001) â€” Funciones PL/pgSQL", () => {
  for (const fn of REQUIRED_CRM_SPS) {
    it(`${fn} debe existir en public`, async () => {
      const r = await pool.query(
        `SELECT 1 FROM pg_proc p
          JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE p.proname = $1 AND n.nspname = 'public' LIMIT 1`,
        [fn],
      );
      expect(r.rowCount).toBe(1);
    });
  }
});
