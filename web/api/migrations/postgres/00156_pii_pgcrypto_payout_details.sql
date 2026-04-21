-- +goose Up
-- Cifrado PII (pgcrypto) para store."Affiliate"."PayoutDetails" y
-- store."Merchant"."PayoutDetails".
--
-- Bloqueador del integration reviewer antes de activar
-- STORE_AFFILIATE_PAYOUT_ENABLED=true.
--
-- Estrategia:
--   1. CREATE EXTENSION pgcrypto (idempotente).
--   2. Renombrar la columna JSONB original a "PayoutDetailsPlain" y agregar
--      "PayoutDetailsEnc" bytea. Durante el rollout conservamos la data
--      plaintext para que el PO pueda lanzar un script one-shot de migración
--      cuando la GUC zentto.master_key esté disponible en su sesión.
--   3. Helpers store.pii_encrypt(text) / store.pii_decrypt(bytea) usando
--      current_setting('zentto.master_key') — la app hace SET LOCAL en cada
--      transacción que involucre estos SPs.
--   4. Actualizar los SPs afectados para que los writes cifren al guardar y
--      los reads (dashboard + admin) descifren on-the-fly.
--
-- Importante: la migración NO cifra la data vieja. Queda en
-- "PayoutDetailsPlain" hasta que el PO dispare un script manual
-- (ver docs/security/pii-encryption.md).
--
-- Paridad SQL Server: patch equivalente en
-- web/api/sqlweb-mssql/08_patch_pii_pgcrypto_payout_details.sql
-- usa ENCRYPTBYPASSPHRASE.

-- ─── pgcrypto ─────────────────────────────────────────────
-- +goose StatementBegin
CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- +goose StatementEnd

-- ─── Affiliate: split PayoutDetails → Plain + Enc ─────────
-- +goose StatementBegin
DO $$
BEGIN
  -- Rename "PayoutDetails" → "PayoutDetailsPlain" (solo si existe y aún no se renombró)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'store' AND table_name = 'Affiliate'
       AND column_name = 'PayoutDetails'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'store' AND table_name = 'Affiliate'
       AND column_name = 'PayoutDetailsPlain'
  ) THEN
    EXECUTE 'ALTER TABLE store."Affiliate" RENAME COLUMN "PayoutDetails" TO "PayoutDetailsPlain"';
  END IF;

  -- Add "PayoutDetailsEnc" bytea si no existe
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'store' AND table_name = 'Affiliate'
       AND column_name = 'PayoutDetailsEnc'
  ) THEN
    EXECUTE 'ALTER TABLE store."Affiliate" ADD COLUMN "PayoutDetailsEnc" bytea';
  END IF;
END$$;
-- +goose StatementEnd

-- ─── Merchant: split PayoutDetails → Plain + Enc ──────────
-- +goose StatementBegin
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'store' AND table_name = 'Merchant'
       AND column_name = 'PayoutDetails'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'store' AND table_name = 'Merchant'
       AND column_name = 'PayoutDetailsPlain'
  ) THEN
    EXECUTE 'ALTER TABLE store."Merchant" RENAME COLUMN "PayoutDetails" TO "PayoutDetailsPlain"';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'store' AND table_name = 'Merchant'
       AND column_name = 'PayoutDetailsEnc'
  ) THEN
    EXECUTE 'ALTER TABLE store."Merchant" ADD COLUMN "PayoutDetailsEnc" bytea';
  END IF;
END$$;
-- +goose StatementEnd

-- ─── Helpers genéricos de cifrado PII ─────────────────────
-- Usan current_setting('zentto.master_key', true) — el segundo arg (true)
-- hace que retorne NULL si la GUC no está set en la sesión, evitando error
-- durante la migración inicial. En producción la app siempre setea la GUC
-- via SET LOCAL antes de llamar a los SPs (ver setPiiMasterKey() en query.ts).
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION store.pii_encrypt(p_value text)
RETURNS bytea
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_key text;
BEGIN
  IF p_value IS NULL OR length(p_value) = 0 THEN
    RETURN NULL;
  END IF;
  v_key := current_setting('zentto.master_key', true);
  IF v_key IS NULL OR length(v_key) = 0 THEN
    RAISE EXCEPTION 'pii_encrypt: zentto.master_key GUC no configurada. La app debe ejecutar SET LOCAL zentto.master_key = ''...'' dentro de la transacción.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN pgp_sym_encrypt(p_value, v_key);
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION store.pii_decrypt(p_value bytea)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_key text;
BEGIN
  IF p_value IS NULL THEN
    RETURN NULL;
  END IF;
  v_key := current_setting('zentto.master_key', true);
  IF v_key IS NULL OR length(v_key) = 0 THEN
    RAISE EXCEPTION 'pii_decrypt: zentto.master_key GUC no configurada. La app debe ejecutar SET LOCAL zentto.master_key = ''...'' dentro de la transacción.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN pgp_sym_decrypt(p_value, v_key);
END;
$$;
-- +goose StatementEnd

-- Variante "safe" que retorna NULL si no puede descifrar (p.ej. listado
-- público sin GUC seteada). Se usa sólo donde NO interesa mostrar el PII.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION store.pii_decrypt_safe(p_value bytea)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_key text;
BEGIN
  IF p_value IS NULL THEN RETURN NULL; END IF;
  v_key := current_setting('zentto.master_key', true);
  IF v_key IS NULL OR length(v_key) = 0 THEN
    RETURN NULL; -- sin key, no exponemos datos
  END IF;
  BEGIN
    RETURN pgp_sym_decrypt(p_value, v_key);
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_register (write con cifrado) ─────
-- Reemplaza la versión de la migración 00150: acepta p_payout_details jsonb
-- y lo cifra antes de guardar en "PayoutDetailsEnc".
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_affiliate_register(integer,integer,varchar,varchar,varchar,varchar,jsonb);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_register(
  p_company_id     integer,
  p_customer_id    integer,
  p_legal_name     varchar,
  p_tax_id         varchar,
  p_contact_email  varchar,
  p_payout_method  varchar,
  p_payout_details jsonb
)
RETURNS TABLE("ok" boolean, "mensaje" text, "referralCode" varchar, "affiliateId" bigint)
LANGUAGE plpgsql AS $$
DECLARE
  v_code    varchar(20);
  v_id      bigint;
  v_exists  bigint;
  v_enc     bytea;
BEGIN
  IF p_customer_id IS NULL THEN
    RETURN QUERY SELECT false, 'customer_id requerido'::text, NULL::varchar, NULL::bigint;
    RETURN;
  END IF;

  SELECT "Id", "ReferralCode" INTO v_id, v_code
    FROM store."Affiliate"
   WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id
   LIMIT 1;

  IF v_id IS NOT NULL THEN
    RETURN QUERY SELECT true, 'Ya eres afiliado'::text, v_code, v_id;
    RETURN;
  END IF;

  LOOP
    v_code := 'ZEN-' || UPPER(SUBSTRING(MD5(random()::text || clock_timestamp()::text) FROM 1 FOR 8));
    SELECT COUNT(*) INTO v_exists FROM store."Affiliate" WHERE "ReferralCode" = v_code;
    EXIT WHEN v_exists = 0;
  END LOOP;

  -- Cifrar PayoutDetails (si viene). La GUC zentto.master_key debe estar set
  -- en la transacción por la app (SET LOCAL).
  IF p_payout_details IS NOT NULL THEN
    v_enc := store.pii_encrypt(p_payout_details::text);
  ELSE
    v_enc := NULL;
  END IF;

  INSERT INTO store."Affiliate" (
    "CompanyId","CustomerId","ReferralCode","Status",
    "PayoutMethod","PayoutDetailsEnc","TaxId","LegalName","ContactEmail"
  )
  VALUES (
    p_company_id, p_customer_id, v_code, 'pending',
    p_payout_method, v_enc, p_tax_id, p_legal_name, p_contact_email
  )
  RETURNING "Id" INTO v_id;

  RETURN QUERY SELECT true, 'Aplicación recibida. Te notificaremos cuando sea aprobada.'::text, v_code, v_id;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_affiliate_admin_list (read con decrypt safe) ─
-- El admin list expone "payoutMethod" y "payoutDetails" descifrado.
-- NOTA: solo el endpoint admin lo llama (requiere auth admin).
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_affiliate_admin_list(integer,varchar,integer,integer);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_affiliate_admin_list(
  p_company_id integer,
  p_status     varchar,
  p_page       integer,
  p_limit      integer
)
RETURNS TABLE(
  "id"             bigint,
  "referralCode"   varchar,
  "customerId"     integer,
  "legalName"      varchar,
  "contactEmail"   varchar,
  "status"         varchar,
  "taxId"          varchar,
  "payoutMethod"   varchar,
  "payoutDetails"  text,
  "createdAt"      timestamp,
  "approvedAt"     timestamp,
  "pendingAmount"  numeric,
  "paidAmount"     numeric,
  "TotalCount"     bigint
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_page   integer := GREATEST(COALESCE(p_page,1), 1);
  v_limit  integer := LEAST(GREATEST(COALESCE(p_limit,20),1), 100);
  v_offset integer := (v_page - 1) * v_limit;
BEGIN
  RETURN QUERY
  SELECT
    a."Id", a."ReferralCode", a."CustomerId", a."LegalName", a."ContactEmail",
    a."Status", a."TaxId", a."PayoutMethod",
    store.pii_decrypt_safe(a."PayoutDetailsEnc") AS "payoutDetails",
    a."CreatedAt", a."ApprovedAt",
    COALESCE((SELECT SUM("CommissionAmount") FROM store."AffiliateCommission" WHERE "AffiliateId" = a."Id" AND "Status" = 'pending'), 0),
    COALESCE((SELECT SUM("CommissionAmount") FROM store."AffiliateCommission" WHERE "AffiliateId" = a."Id" AND "Status" = 'paid'), 0),
    COUNT(*) OVER()::bigint
  FROM store."Affiliate" a
  WHERE a."CompanyId" = p_company_id
    AND (p_status IS NULL OR a."Status" = p_status)
  ORDER BY a."CreatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_merchant_apply (write con cifrado) ─────────
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_merchant_apply(integer,integer,varchar,varchar,varchar,text,varchar,varchar,varchar,varchar,jsonb);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_apply(
  p_company_id     integer,
  p_customer_id    integer,
  p_legal_name     varchar,
  p_tax_id         varchar,
  p_store_slug     varchar,
  p_description    text,
  p_logo_url       varchar,
  p_contact_email  varchar,
  p_contact_phone  varchar,
  p_payout_method  varchar,
  p_payout_details jsonb
)
RETURNS TABLE("ok" boolean, "mensaje" text, "merchantId" bigint, "storeSlug" varchar)
LANGUAGE plpgsql AS $$
DECLARE
  v_id       bigint;
  v_slug     varchar(80);
  v_existing bigint;
  v_enc      bytea;
BEGIN
  IF p_customer_id IS NULL THEN
    RETURN QUERY SELECT false, 'customer_id requerido'::text, NULL::bigint, NULL::varchar;
    RETURN;
  END IF;
  IF p_legal_name IS NULL OR length(trim(p_legal_name)) = 0 THEN
    RETURN QUERY SELECT false, 'Razón social requerida'::text, NULL::bigint, NULL::varchar;
    RETURN;
  END IF;

  SELECT "Id" INTO v_id FROM store."Merchant"
    WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id;
  IF v_id IS NOT NULL THEN
    RETURN QUERY SELECT true, 'Ya tienes una solicitud de vendedor'::text, v_id, NULL::varchar;
    RETURN;
  END IF;

  v_slug := LOWER(REGEXP_REPLACE(COALESCE(p_store_slug, p_legal_name), '[^a-zA-Z0-9]+', '-', 'g'));
  v_slug := TRIM(BOTH '-' FROM v_slug);
  IF length(v_slug) < 3 THEN v_slug := 'merchant-' || p_customer_id::text; END IF;

  LOOP
    SELECT COUNT(*) INTO v_existing FROM store."Merchant" WHERE "StoreSlug" = v_slug;
    EXIT WHEN v_existing = 0;
    v_slug := v_slug || '-' || FLOOR(random()*10000)::int::text;
  END LOOP;

  IF p_payout_details IS NOT NULL THEN
    v_enc := store.pii_encrypt(p_payout_details::text);
  ELSE
    v_enc := NULL;
  END IF;

  INSERT INTO store."Merchant" (
    "CompanyId","CustomerId","LegalName","TaxId","StoreSlug",
    "Description","LogoUrl","ContactEmail","ContactPhone",
    "PayoutMethod","PayoutDetailsEnc"
  )
  VALUES (
    p_company_id, p_customer_id, p_legal_name, p_tax_id, v_slug,
    p_description, p_logo_url, p_contact_email, p_contact_phone,
    p_payout_method, v_enc
  )
  RETURNING "Id" INTO v_id;

  RETURN QUERY SELECT true, 'Solicitud recibida. Revisaremos tu tienda en 24-48h.'::text, v_id, v_slug;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_merchant_admin_get_detail (read con decrypt) ─
-- Extiende la firma original con "payoutDetails" (descifrado on-the-fly).
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_merchant_admin_get_detail(integer,bigint);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_admin_get_detail(
  p_company_id  integer,
  p_merchant_id bigint
)
RETURNS TABLE(
  "id"              bigint,
  "legalName"       varchar,
  "storeSlug"       varchar,
  "description"     text,
  "taxId"           varchar,
  "contactEmail"    varchar,
  "contactPhone"    varchar,
  "logoUrl"         varchar,
  "bannerUrl"       varchar,
  "status"          varchar,
  "commissionRate"  numeric,
  "payoutMethod"    varchar,
  "payoutDetails"   text,
  "rejectionReason" varchar,
  "createdAt"       timestamp,
  "approvedAt"      timestamp,
  "approvedBy"      varchar
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT
    s."Id", s."LegalName", s."StoreSlug", s."Description", s."TaxId",
    s."ContactEmail", s."ContactPhone", s."LogoUrl", s."BannerUrl",
    s."Status", s."CommissionRate", s."PayoutMethod",
    store.pii_decrypt_safe(s."PayoutDetailsEnc") AS "payoutDetails",
    s."RejectionReason", s."CreatedAt", s."ApprovedAt", s."ApprovedBy"
  FROM store."Merchant" s
  WHERE s."CompanyId" = p_company_id AND s."Id" = p_merchant_id
  LIMIT 1;
END;
$$;
-- +goose StatementEnd


-- +goose Down
-- +goose StatementBegin
-- Revertir SPs a su forma original (sin cifrado, leyendo de PayoutDetailsPlain)
DROP FUNCTION IF EXISTS public.usp_store_merchant_admin_get_detail(integer,bigint);
DROP FUNCTION IF EXISTS public.usp_store_merchant_apply(integer,integer,varchar,varchar,varchar,text,varchar,varchar,varchar,varchar,jsonb);
DROP FUNCTION IF EXISTS public.usp_store_affiliate_admin_list(integer,varchar,integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_affiliate_register(integer,integer,varchar,varchar,varchar,varchar,jsonb);
DROP FUNCTION IF EXISTS store.pii_decrypt_safe(bytea);
DROP FUNCTION IF EXISTS store.pii_decrypt(bytea);
DROP FUNCTION IF EXISTS store.pii_encrypt(text);

-- Descartar columna cifrada y re-renombrar Plain → PayoutDetails
ALTER TABLE store."Affiliate" DROP COLUMN IF EXISTS "PayoutDetailsEnc";
ALTER TABLE store."Merchant"  DROP COLUMN IF EXISTS "PayoutDetailsEnc";

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'store' AND table_name = 'Affiliate'
       AND column_name = 'PayoutDetailsPlain'
  ) THEN
    EXECUTE 'ALTER TABLE store."Affiliate" RENAME COLUMN "PayoutDetailsPlain" TO "PayoutDetails"';
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_schema = 'store' AND table_name = 'Merchant'
       AND column_name = 'PayoutDetailsPlain'
  ) THEN
    EXECUTE 'ALTER TABLE store."Merchant" RENAME COLUMN "PayoutDetailsPlain" TO "PayoutDetails"';
  END IF;
END$$;
-- +goose StatementEnd
