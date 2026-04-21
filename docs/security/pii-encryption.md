# Cifrado PII — `pgcrypto` + paridad T-SQL

> Estado: **activo** desde PR `feat/pii-pgcrypto-payout-details` (migración goose `00155`).
> Bloqueador pre-`STORE_AFFILIATE_PAYOUT_ENABLED=true`.

## 1. Alcance

Columnas `PayoutDetails` (JSON con IBAN, account_number, tax_id del afiliado/merchant) en:

- `store."Affiliate"."PayoutDetailsEnc"` (`bytea`, antes `PayoutDetails jsonb`)
- `store."Merchant"."PayoutDetailsEnc"`  (`bytea`, antes `PayoutDetails jsonb`)

El JSON original se conserva temporalmente en `PayoutDetailsPlain` para permitir
un script one-shot de migración de data existente (ver sección 5).

## 2. Arquitectura

### PostgreSQL (producción)

- Extensión `pgcrypto` (simétrica, `pgp_sym_encrypt`/`pgp_sym_decrypt`).
- Passphrase: env `MASTER_KEY` en el servidor, expuesta a cada transacción via
  `SET LOCAL zentto.master_key = '...'`.
- Helpers SQL reutilizables en el schema `store`:
  - `store.pii_encrypt(text) RETURNS bytea` — falla si la GUC no está set.
  - `store.pii_decrypt(bytea) RETURNS text` — idem.
  - `store.pii_decrypt_safe(bytea) RETURNS text` — retorna `NULL` si no hay key
    (p. ej. listados admin sin contexto de decrypt).

### SQL Server (paridad)

- `ENCRYPTBYPASSPHRASE` / `DECRYPTBYPASSPHRASE` con la misma `MASTER_KEY` como
  passphrase. Paridad funcional mínima — la llave se pasa como parámetro
  `@MasterKey` a los SPs afectados.
- Columnas equivalentes: `PayoutDetailsEnc VARBINARY(MAX)`.
- Nota: no hay GUC en SQL Server, por eso la key va como parámetro.
- Patch: `web/api/sqlweb-mssql/08_patch_pii_pgcrypto_payout_details.sql`.

## 3. API — contrato app → BD

El backend expone dos helpers nuevos en `web/api/src/db/query.ts`:

```ts
// Ejecuta un SP con la GUC zentto.master_key ya seteada.
callSpWithPii<T>(spName, inputs)
callSpOutWithPii<T>(spName, inputs, outputs)
```

Internamente:

1. Toman un `client` del pool PG.
2. `BEGIN`.
3. `SELECT set_config('zentto.master_key', $1, true)` — la GUC vive sólo en
   esta transacción y este `client`.
4. Ejecutan el SP en la misma conexión.
5. `COMMIT` (o `ROLLBACK`).

La key nunca se interpola en el SQL — siempre va como parámetro `$1` a
`set_config()`.

**Requisito:** `env.masterKey` (`process.env.MASTER_KEY`) debe estar configurada.
Si no lo está, `callSpWithPii`/`callSpOutWithPii` lanzan error explícito. No
fallamos silenciosamente (eso guardaría data con passphrase vacía).

## 4. SPs afectados

| SP | Tipo | Cambio |
|----|------|--------|
| `usp_store_affiliate_register` | write | cifra `PayoutDetails` con `store.pii_encrypt` |
| `usp_store_affiliate_admin_list` | read | expone `payoutDetails` descifrado con `pii_decrypt_safe` |
| `usp_store_merchant_apply` | write | idem |
| `usp_store_merchant_admin_get_detail` | read | idem |

Los listados no-admin (`get_dashboard`, `dashboard`, `products_list` etc.) NO
exponen PayoutDetails — no requieren la GUC.

## 5. Rollout de data existente (diferido)

La migración `00155` **no cifra** los registros existentes — conserva la data
en `PayoutDetailsPlain`. Esto es intencional para:

1. No requerir que `MASTER_KEY` esté disponible via `PGOPTIONS` durante `goose up`.
2. Permitir rollback si la key inicial resulta incorrecta.

Cuando el PO decida el rollout final, ejecutar el siguiente script one-shot
dentro de una sesión con la GUC seteada:

```sql
BEGIN;
SELECT set_config('zentto.master_key', '<MASTER_KEY>', false);

UPDATE store."Affiliate"
   SET "PayoutDetailsEnc" = store.pii_encrypt("PayoutDetailsPlain"::text)
 WHERE "PayoutDetailsPlain" IS NOT NULL
   AND "PayoutDetailsEnc" IS NULL;

UPDATE store."Merchant"
   SET "PayoutDetailsEnc" = store.pii_encrypt("PayoutDetailsPlain"::text)
 WHERE "PayoutDetailsPlain" IS NOT NULL
   AND "PayoutDetailsEnc" IS NULL;

-- Una vez validado en prod:
-- ALTER TABLE store."Affiliate" DROP COLUMN "PayoutDetailsPlain";
-- ALTER TABLE store."Merchant"  DROP COLUMN "PayoutDetailsPlain";

COMMIT;
```

El `DROP COLUMN "PayoutDetailsPlain"` final va en una migración posterior
(`00156_drop_payout_details_plain.sql`, TBD) una vez validado.

## 6. Pruebas

- `web/api/tests/pii-encryption.test.ts` — roundtrip encrypt/decrypt sin DB
  (usa `pgp_sym_encrypt`/`pgp_sym_decrypt` via openssl compat, o pg en local si
  está disponible).
- Gate: el test NO bloquea CI si `PG_HOST` no está disponible.

## 7. Rotación de `MASTER_KEY` (futuro)

Rotación completa requiere:

1. Leer cada fila cifrada con la key vieja.
2. Re-cifrar con la key nueva.
3. Swap atómico de la env var.

No está implementada todavía — cuando el PO lo requiera, abrir issue dedicado.
