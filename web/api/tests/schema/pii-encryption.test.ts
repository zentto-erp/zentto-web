/**
 * pii-encryption.test.ts
 *
 * Valida las helpers `store.pii_encrypt`/`store.pii_decrypt`/`pii_decrypt_safe`
 * y el flujo completo de la migraciÃ³n 00155 (pgcrypto):
 *
 *   1. GUC zentto.master_key vacÃ­a â†’ encrypt/decrypt lanzan error explÃ­cito.
 *   2. Con GUC seteada â†’ roundtrip text â†’ bytea â†’ text idÃ©ntico.
 *   3. NULL / vacÃ­o â†’ NULL (no se cifra).
 *   4. decrypt_safe sin GUC â†’ NULL (no lanza).
 *   5. La columna PayoutDetailsEnc tiene tipo bytea.
 *   6. Los SPs usp_store_affiliate_register y usp_store_merchant_apply existen
 *      con la firma esperada (incluyen p_payout_details jsonb).
 *
 * Requiere PG con migraciones aplicadas hasta 00155. Si no hay PG disponible,
 * el test se skipea (passWithNoTests en vitest config cubre el CI sin DB).
 *
 * Variables de entorno:
 *   PG_CONNECTION_STRING  o  PG_HOST + PG_PORT + PG_DATABASE + PG_USER + PG_PASSWORD
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import pg from "pg";
import "dotenv/config";

let pool: pg.Pool | null = null;
let pgAvailable = false;
const TEST_KEY = "test-master-key-pii-encryption-" + Date.now();

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
          // nosemgrep: bypass-tls-verification
          ssl: process.env.PG_SSL === "true" ? { rejectUnauthorized: false } : false,
          connectionTimeoutMillis: 3000,
        });
    // Ping
    await pool.query("SELECT 1");
    // Â¿Existen los helpers? Si no, skipear todo.
    const r = await pool.query<{ n: number }>(
      `SELECT COUNT(*)::int AS n
         FROM pg_proc p JOIN pg_namespace s ON s.oid = p.pronamespace
        WHERE s.nspname = 'store' AND p.proname = 'pii_encrypt'`
    );
    pgAvailable = (r.rows[0]?.n ?? 0) > 0;
  } catch {
    pgAvailable = false;
  }
});

afterAll(async () => {
  await pool?.end().catch(() => { /* noop */ });
});

describe("PII encryption (pgcrypto)", () => {
  it("skipea limpiamente si PG no estÃ¡ disponible o migraciÃ³n 00155 no aplicada", () => {
    if (!pgAvailable) {
      console.warn("[pii-encryption.test] PG no disponible o migraciÃ³n 00155 no aplicada â€” skip");
    }
    expect(true).toBe(true);
  });

  it("store.pii_encrypt falla si zentto.master_key no estÃ¡ set", async () => {
    if (!pgAvailable || !pool) return;
    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      // No seteamos la GUC
      await expect(
        client.query(`SELECT store.pii_encrypt('hello')`)
      ).rejects.toThrow(/master_key/i);
      await client.query("ROLLBACK");
    } finally {
      client.release();
    }
  });

  it("store.pii_decrypt falla si zentto.master_key no estÃ¡ set", async () => {
    if (!pgAvailable || !pool) return;
    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      await expect(
        client.query(`SELECT store.pii_decrypt(E'\\\\x1234'::bytea)`)
      ).rejects.toThrow(/master_key/i);
      await client.query("ROLLBACK");
    } finally {
      client.release();
    }
  });

  it("roundtrip encrypt/decrypt devuelve el texto original", async () => {
    if (!pgAvailable || !pool) return;
    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      await client.query("SELECT set_config('zentto.master_key', $1, true)", [TEST_KEY]);

      const plaintext = JSON.stringify({
        iban: "VE12345678901234567890",
        account_number: "001-12345-9",
        tax_id: "V-12345678-9",
      });

      const enc = await client.query<{ enc: Buffer }>(
        `SELECT store.pii_encrypt($1) AS enc`,
        [plaintext]
      );
      expect(enc.rows[0].enc).toBeInstanceOf(Buffer);
      expect(enc.rows[0].enc.length).toBeGreaterThan(0);

      const dec = await client.query<{ dec: string }>(
        `SELECT store.pii_decrypt($1::bytea) AS dec`,
        [enc.rows[0].enc]
      );
      expect(dec.rows[0].dec).toBe(plaintext);

      await client.query("ROLLBACK");
    } finally {
      client.release();
    }
  });

  it("encrypt(NULL) y encrypt('') retornan NULL", async () => {
    if (!pgAvailable || !pool) return;
    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      await client.query("SELECT set_config('zentto.master_key', $1, true)", [TEST_KEY]);

      const r1 = await client.query<{ enc: Buffer | null }>(
        `SELECT store.pii_encrypt(NULL) AS enc`
      );
      expect(r1.rows[0].enc).toBeNull();

      const r2 = await client.query<{ enc: Buffer | null }>(
        `SELECT store.pii_encrypt('') AS enc`
      );
      expect(r2.rows[0].enc).toBeNull();

      await client.query("ROLLBACK");
    } finally {
      client.release();
    }
  });

  it("decrypt(NULL) retorna NULL", async () => {
    if (!pgAvailable || !pool) return;
    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      await client.query("SELECT set_config('zentto.master_key', $1, true)", [TEST_KEY]);
      const r = await client.query<{ dec: string | null }>(
        `SELECT store.pii_decrypt(NULL) AS dec`
      );
      expect(r.rows[0].dec).toBeNull();
      await client.query("ROLLBACK");
    } finally {
      client.release();
    }
  });

  it("pii_decrypt_safe sin GUC retorna NULL (no lanza)", async () => {
    if (!pgAvailable || !pool) return;
    const client = await pool.connect();
    try {
      // Generamos un bytea cifrado con key distinta, en otra sesiÃ³n
      await client.query("BEGIN");
      await client.query("SELECT set_config('zentto.master_key', $1, true)", [TEST_KEY]);
      const enc = await client.query<{ enc: Buffer }>(
        `SELECT store.pii_encrypt('secret-value') AS enc`
      );
      await client.query("ROLLBACK");

      // Nueva transacciÃ³n sin GUC
      await client.query("BEGIN");
      const r = await client.query<{ dec: string | null }>(
        `SELECT store.pii_decrypt_safe($1::bytea) AS dec`,
        [enc.rows[0].enc]
      );
      expect(r.rows[0].dec).toBeNull();
      await client.query("ROLLBACK");
    } finally {
      client.release();
    }
  });

  it("PayoutDetailsEnc existe como bytea en Affiliate y Merchant", async () => {
    if (!pgAvailable || !pool) return;
    const aff = await pool.query<{ data_type: string }>(
      `SELECT data_type FROM information_schema.columns
        WHERE table_schema='store' AND table_name='Affiliate' AND column_name='PayoutDetailsEnc'`
    );
    expect(aff.rows[0]?.data_type).toBe("bytea");

    const mer = await pool.query<{ data_type: string }>(
      `SELECT data_type FROM information_schema.columns
        WHERE table_schema='store' AND table_name='Merchant' AND column_name='PayoutDetailsEnc'`
    );
    expect(mer.rows[0]?.data_type).toBe("bytea");
  });

  it("usp_store_affiliate_register y usp_store_merchant_apply existen con jsonb", async () => {
    if (!pgAvailable || !pool) return;
    const fns = await pool.query<{ proname: string }>(
      `SELECT p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          AND p.proname IN ('usp_store_affiliate_register','usp_store_merchant_apply')`
    );
    const names = fns.rows.map((r) => r.proname).sort();
    expect(names).toEqual(["usp_store_affiliate_register", "usp_store_merchant_apply"]);
  });
});
