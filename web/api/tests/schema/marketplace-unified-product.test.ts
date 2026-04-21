/**
 * marketplace-unified-product.test.ts
 *
 * Valida la migración 00158 — vista store."UnifiedProduct" + SPs asociados.
 * Cubre el hueco P0 #1 detectado en docs/architecture/marketplace-flow-audit.md:
 * los productos merchant aprobados deben aparecer en el storefront público.
 *
 * Casos:
 *   1. Vista existe y expone las columnas esperadas.
 *   2. Producto merchant 'approved' (con merchant 'approved') aparece.
 *   3. Producto merchant 'pending_review' NO aparece.
 *   4. Producto merchant approved de un merchant 'suspended' NO aparece.
 *   5. SP usp_store_product_list incluye merchant cuando p_include_merchant=true.
 *   6. SP usp_store_product_list filtra por p_merchant_slug.
 *   7. SP usp_store_product_getbycode retorna columnas merchant* populadas.
 *   8. SP usp_store_merchant_public_get retorna merchant si está approved.
 *
 * Se skipea limpiamente si PG no está disponible o la migración 00158 no
 * está aplicada. El test crea un tenant de fixtures temporal (CompanyId
 * 999999 reservado) para no contaminar data real.
 *
 * Variables de entorno:
 *   PG_CONNECTION_STRING  o  PG_HOST + PG_PORT + PG_DATABASE + PG_USER + PG_PASSWORD
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import pg from "pg";
import "dotenv/config";

const TEST_COMPANY_ID = 999_158; // Aislado por CompanyId — no choca con seeds
const SLUG_APPROVED   = `test-approved-${Date.now()}`;
const SLUG_SUSPENDED  = `test-suspended-${Date.now()}`;

let pool: pg.Pool | null = null;
let pgAvailable = false;
let migrationApplied = false;
let merchantApprovedId: number | null = null;
let merchantSuspendedId: number | null = null;

beforeAll(async () => {
  try {
    pool = process.env.PG_CONNECTION_STRING
      ? new pg.Pool({ connectionString: process.env.PG_CONNECTION_STRING, connectionTimeoutMillis: 3000 })
      : new pg.Pool({
          host: process.env.PG_HOST ?? "127.0.0.1",
          port: Number(process.env.PG_PORT ?? 5432),
          database: process.env.PG_DATABASE ?? "zentto_prod",
          user: process.env.PG_USER ?? "zentto_app",
          password: process.env.PG_PASSWORD ?? "",
          // nosemgrep: javascript.lang.security.audit.sqli.node-bypass-tls-verification
          ssl: process.env.PG_SSL === "true" ? { rejectUnauthorized: false } : false,
          connectionTimeoutMillis: 3000,
        });
    await pool.query("SELECT 1");
    pgAvailable = true;

    const v = await pool.query<{ n: number }>(
      `SELECT COUNT(*)::int AS n
         FROM pg_views
        WHERE schemaname = 'store' AND viewname = 'UnifiedProduct'`
    );
    migrationApplied = (v.rows[0]?.n ?? 0) > 0;
  } catch {
    pgAvailable = false;
  }

  if (!pgAvailable || !migrationApplied || !pool) return;

  // Limpiar posibles leftovers
  await pool.query(
    `DELETE FROM store."MerchantProduct" WHERE "CompanyId" = $1`,
    [TEST_COMPANY_ID]
  );
  await pool.query(
    `DELETE FROM store."Merchant" WHERE "CompanyId" = $1`,
    [TEST_COMPANY_ID]
  );

  // Merchant APPROVED
  const m1 = await pool.query<{ Id: number }>(
    `INSERT INTO store."Merchant" (
       "CompanyId","CustomerId","LegalName","StoreSlug","Status","CommissionRate"
     ) VALUES ($1, NULL, 'Test Approved SRL', $2, 'approved', 10.00)
     RETURNING "Id"`,
    [TEST_COMPANY_ID, SLUG_APPROVED]
  );
  merchantApprovedId = m1.rows[0]?.Id ?? null;

  // Merchant SUSPENDED
  const m2 = await pool.query<{ Id: number }>(
    `INSERT INTO store."Merchant" (
       "CompanyId","CustomerId","LegalName","StoreSlug","Status","CommissionRate"
     ) VALUES ($1, NULL, 'Test Suspended SRL', $2, 'suspended', 10.00)
     RETURNING "Id"`,
    [TEST_COMPANY_ID, SLUG_SUSPENDED]
  );
  merchantSuspendedId = m2.rows[0]?.Id ?? null;

  // 3 productos:
  //   - APPROVED/approved → debe aparecer
  //   - APPROVED/pending_review → NO debe aparecer
  //   - SUSPENDED/approved → NO debe aparecer (merchant suspendido)
  await pool.query(
    `INSERT INTO store."MerchantProduct" (
       "MerchantId","CompanyId","ProductCode","Name","Price","Stock","Category","Status"
     ) VALUES
     ($1, $2, 'MP-APPR-001', 'Producto aprobado',   50.00, 10, 'Electrónica', 'approved'),
     ($1, $2, 'MP-PEND-001', 'Producto en revisión', 25.00,  5, 'Electrónica', 'pending_review'),
     ($3, $2, 'MP-SUSP-001', 'Producto de suspendido', 75.00, 8, 'Electrónica', 'approved')`,
    [merchantApprovedId, TEST_COMPANY_ID, merchantSuspendedId]
  );
});

afterAll(async () => {
  if (pool && pgAvailable && migrationApplied) {
    await pool
      .query(`DELETE FROM store."MerchantProduct" WHERE "CompanyId" = $1`, [TEST_COMPANY_ID])
      .catch(() => { /* noop */ });
    await pool
      .query(`DELETE FROM store."Merchant" WHERE "CompanyId" = $1`, [TEST_COMPANY_ID])
      .catch(() => { /* noop */ });
  }
  await pool?.end().catch(() => { /* noop */ });
});

describe("marketplace — 00158 UnifiedProduct + SPs", () => {
  it("skipea limpiamente si PG no está disponible o 00158 no aplicada", () => {
    if (!pgAvailable || !migrationApplied) {
      // eslint-disable-next-line no-console
      console.warn("[marketplace-unified-product.test] PG no disponible o migración 00158 no aplicada — skip");
    }
    expect(true).toBe(true);
  });

  it("vista store.UnifiedProduct expone columnas esperadas", async () => {
    if (!pgAvailable || !migrationApplied || !pool) return;
    const r = await pool.query<{ column_name: string }>(
      `SELECT column_name FROM information_schema.columns
        WHERE table_schema = 'store' AND table_name = 'UnifiedProduct'`
    );
    const cols = new Set(r.rows.map((x) => x.column_name));
    for (const expected of [
      "source", "Id", "Code", "Name", "Price", "Stock", "CompanyId",
      "MerchantId", "MerchantSlug", "MerchantName", "CategoryCode",
    ]) {
      expect(cols.has(expected)).toBe(true);
    }
  });

  it("producto merchant approved (merchant approved) aparece en UnifiedProduct", async () => {
    if (!pgAvailable || !migrationApplied || !pool) return;
    const r = await pool.query(
      `SELECT "Code", "source", "MerchantSlug" FROM store."UnifiedProduct"
        WHERE "CompanyId" = $1 AND "Code" = 'MP-APPR-001'`,
      [TEST_COMPANY_ID]
    );
    expect(r.rowCount).toBe(1);
    expect(r.rows[0].source).toBe("merchant");
    expect(r.rows[0].MerchantSlug).toBe(SLUG_APPROVED);
  });

  it("producto merchant pending_review NO aparece en UnifiedProduct", async () => {
    if (!pgAvailable || !migrationApplied || !pool) return;
    const r = await pool.query(
      `SELECT 1 FROM store."UnifiedProduct"
        WHERE "CompanyId" = $1 AND "Code" = 'MP-PEND-001'`,
      [TEST_COMPANY_ID]
    );
    expect(r.rowCount).toBe(0);
  });

  it("merchant suspended oculta sus productos aprobados en UnifiedProduct", async () => {
    if (!pgAvailable || !migrationApplied || !pool) return;
    const r = await pool.query(
      `SELECT 1 FROM store."UnifiedProduct"
        WHERE "CompanyId" = $1 AND "Code" = 'MP-SUSP-001'`,
      [TEST_COMPANY_ID]
    );
    expect(r.rowCount).toBe(0);
  });

  it("usp_store_product_list retorna el producto merchant approved con source='merchant'", async () => {
    if (!pgAvailable || !migrationApplied || !pool) return;
    const r = await pool.query(
      `SELECT "code", "source", "merchantSlug", "merchantName"
         FROM public.usp_store_product_list(
           $1::int, 1, NULL, NULL, NULL, NULL, NULL, NULL, false,
           'name', 1, 100, NULL, true
         )
        WHERE "code" = 'MP-APPR-001'`,
      [TEST_COMPANY_ID]
    );
    expect(r.rowCount).toBe(1);
    expect(r.rows[0].source).toBe("merchant");
    expect(r.rows[0].merchantSlug).toBe(SLUG_APPROVED);
  });

  it("usp_store_product_list filtra por p_merchant_slug", async () => {
    if (!pgAvailable || !migrationApplied || !pool) return;
    const r = await pool.query(
      `SELECT "code" FROM public.usp_store_product_list(
          $1::int, 1, NULL, NULL, NULL, NULL, NULL, NULL, false,
          'name', 1, 100, $2::varchar, true
        )`,
      [TEST_COMPANY_ID, SLUG_APPROVED]
    );
    const codes = r.rows.map((x: { code: string }) => x.code);
    expect(codes).toContain("MP-APPR-001");
    // No debe traer productos de otros merchants ni el del merchant suspendido
    expect(codes).not.toContain("MP-SUSP-001");
  });

  it("usp_store_product_list con p_include_merchant=false excluye merchants", async () => {
    if (!pgAvailable || !migrationApplied || !pool) return;
    const r = await pool.query(
      `SELECT "code" FROM public.usp_store_product_list(
          $1::int, 1, NULL, NULL, NULL, NULL, NULL, NULL, false,
          'name', 1, 100, NULL, false
        )`,
      [TEST_COMPANY_ID]
    );
    const codes = r.rows.map((x: { code: string }) => x.code);
    expect(codes).not.toContain("MP-APPR-001");
  });

  it("usp_store_product_getbycode retorna merchant* populado para producto merchant", async () => {
    if (!pgAvailable || !migrationApplied || !pool) return;
    const r = await pool.query(
      `SELECT "source", "merchantId", "merchantSlug", "merchantName"
         FROM public.usp_store_product_getbycode($1::int, 1, 'MP-APPR-001')`,
      [TEST_COMPANY_ID]
    );
    expect(r.rowCount).toBe(1);
    expect(r.rows[0].source).toBe("merchant");
    expect(Number(r.rows[0].merchantId)).toBe(merchantApprovedId);
    expect(r.rows[0].merchantSlug).toBe(SLUG_APPROVED);
    expect(r.rows[0].merchantName).toBe("Test Approved SRL");
  });

  it("usp_store_merchant_public_get retorna perfil del merchant approved", async () => {
    if (!pgAvailable || !migrationApplied || !pool) return;
    const r = await pool.query(
      `SELECT "merchantId", "storeSlug", "legalName", "productsApproved"
         FROM public.usp_store_merchant_public_get($1::int, $2::varchar)`,
      [TEST_COMPANY_ID, SLUG_APPROVED]
    );
    expect(r.rowCount).toBe(1);
    expect(Number(r.rows[0].merchantId)).toBe(merchantApprovedId);
    expect(r.rows[0].storeSlug).toBe(SLUG_APPROVED);
    expect(Number(r.rows[0].productsApproved)).toBeGreaterThanOrEqual(1);
  });

  it("usp_store_merchant_public_get NO retorna merchants suspended", async () => {
    if (!pgAvailable || !migrationApplied || !pool) return;
    const r = await pool.query(
      `SELECT "merchantId"
         FROM public.usp_store_merchant_public_get($1::int, $2::varchar)`,
      [TEST_COMPANY_ID, SLUG_SUSPENDED]
    );
    expect(r.rowCount).toBe(0);
  });
});
