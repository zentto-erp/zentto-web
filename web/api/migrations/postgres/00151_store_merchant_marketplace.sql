-- +goose Up
-- Marketplace de comerciantes externos (merchants) — onboarding + productos + payouts.
--
-- NOTA: se usa "Merchant" en lugar de "Seller" para evitar colisión con
-- master.Seller, que ya existe en el baseline del ERP como vendedor comercial
-- (ver web/api/sqlweb-pg/baseline/005_functions.sql:19078+). En la UI pública
-- se mantiene el término "vendedor" / ruta `/vender` por UX en español.
--
-- Tablas:
--   store.Merchant          — cuenta de comerciante externo (marketplace)
--   store.MerchantProduct   — propuesta de producto del comerciante
--   store.MerchantPayout    — lotes de pago al comerciante
--
-- Extiende ar.SalesDocumentLine con "MerchantId" para attribution de ventas por comerciante.
--
-- Funciones:
--   usp_store_merchant_apply
--   usp_store_merchant_admin_list
--   usp_store_merchant_admin_get_detail
--   usp_store_merchant_admin_set_status
--   usp_store_merchant_dashboard
--   usp_store_merchant_product_submit
--   usp_store_merchant_products_list
--   usp_store_merchant_admin_products_list
--   usp_store_merchant_admin_product_review

-- ─── Tablas ──────────────────────────────────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."Merchant" (
  "Id"              bigserial PRIMARY KEY,
  "CompanyId"       integer NOT NULL DEFAULT 1,
  "CustomerId"      integer,
  "LegalName"       varchar(200) NOT NULL,
  "TaxId"           varchar(40),
  "StoreSlug"       varchar(80) NOT NULL UNIQUE,
  "Description"     text,
  "LogoUrl"         varchar(500),
  "BannerUrl"       varchar(500),
  "ContactEmail"    varchar(200),
  "ContactPhone"    varchar(40),
  "Status"          varchar(20) NOT NULL DEFAULT 'pending'
                    CHECK ("Status" IN ('pending','approved','suspended','rejected')),
  "CommissionRate"  numeric(5,2) NOT NULL DEFAULT 15.00,
  "PayoutMethod"    varchar(30),
  "PayoutDetails"   jsonb,
  "RejectionReason" varchar(500),
  "CreatedAt"       timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  "ApprovedAt"      timestamp,
  "ApprovedBy"      varchar(60)
);
CREATE INDEX IF NOT EXISTS "IX_store_Merchant_Status"   ON store."Merchant" ("CompanyId","Status");
CREATE INDEX IF NOT EXISTS "IX_store_Merchant_Customer" ON store."Merchant" ("CompanyId","CustomerId");
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."MerchantProduct" (
  "Id"             bigserial PRIMARY KEY,
  "MerchantId"     bigint NOT NULL REFERENCES store."Merchant"("Id") ON DELETE CASCADE,
  "CompanyId"      integer NOT NULL DEFAULT 1,
  "ProductCode"    varchar(64) NOT NULL,
  "Name"           varchar(250) NOT NULL,
  "Description"    text,
  "Price"          numeric(18,4) NOT NULL DEFAULT 0,
  "Stock"          numeric(18,4) NOT NULL DEFAULT 0,
  "Category"       varchar(80),
  "ImageUrl"       varchar(500),
  "Status"         varchar(20) NOT NULL DEFAULT 'draft'
                   CHECK ("Status" IN ('draft','pending_review','approved','rejected')),
  "ReviewNotes"    text,
  "CreatedAt"      timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  "UpdatedAt"      timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL,
  "ReviewedAt"     timestamp,
  "ReviewedBy"     varchar(60)
);
CREATE INDEX IF NOT EXISTS "IX_store_MerchantProduct_Merchant" ON store."MerchantProduct" ("MerchantId","Status");
CREATE INDEX IF NOT EXISTS "IX_store_MerchantProduct_Status"   ON store."MerchantProduct" ("CompanyId","Status","CreatedAt" DESC);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."MerchantPayout" (
  "Id"              bigserial PRIMARY KEY,
  "MerchantId"      bigint NOT NULL REFERENCES store."Merchant"("Id"),
  "CompanyId"       integer NOT NULL DEFAULT 1,
  "PeriodStart"     date NOT NULL,
  "PeriodEnd"       date NOT NULL,
  "GrossAmount"     numeric(14,2) NOT NULL DEFAULT 0,
  "CommissionAmount" numeric(14,2) NOT NULL DEFAULT 0,
  "NetAmount"       numeric(14,2) NOT NULL DEFAULT 0,
  "CurrencyCode"    char(3) NOT NULL DEFAULT 'USD',
  "Status"          varchar(20) NOT NULL DEFAULT 'pending'
                    CHECK ("Status" IN ('pending','processing','paid','failed')),
  "PaidAt"          timestamp,
  "TransactionRef"  varchar(100),
  "CreatedAt"       timestamp DEFAULT (now() AT TIME ZONE 'UTC') NOT NULL
);
CREATE INDEX IF NOT EXISTS "IX_store_MerchantPayout_Merchant" ON store."MerchantPayout" ("MerchantId","Status","PeriodEnd" DESC);
-- +goose StatementEnd

-- ─── Extender ar.SalesDocumentLine con MerchantId ────────
-- +goose StatementBegin
ALTER TABLE ar."SalesDocumentLine"
  ADD COLUMN IF NOT EXISTS "MerchantId" bigint;
CREATE INDEX IF NOT EXISTS "IX_ar_SalesDocumentLine_Merchant"
  ON ar."SalesDocumentLine" ("MerchantId") WHERE "MerchantId" IS NOT NULL;
-- +goose StatementEnd

-- ─── usp_store_merchant_apply ────────────────────────────
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

  -- Generar slug único a partir del legal_name
  v_slug := LOWER(REGEXP_REPLACE(COALESCE(p_store_slug, p_legal_name), '[^a-zA-Z0-9]+', '-', 'g'));
  v_slug := TRIM(BOTH '-' FROM v_slug);
  IF length(v_slug) < 3 THEN v_slug := 'merchant-' || p_customer_id::text; END IF;

  -- Garantizar unicidad
  LOOP
    SELECT COUNT(*) INTO v_existing FROM store."Merchant" WHERE "StoreSlug" = v_slug;
    EXIT WHEN v_existing = 0;
    v_slug := v_slug || '-' || FLOOR(random()*10000)::int::text;
  END LOOP;

  INSERT INTO store."Merchant" (
    "CompanyId","CustomerId","LegalName","TaxId","StoreSlug",
    "Description","LogoUrl","ContactEmail","ContactPhone",
    "PayoutMethod","PayoutDetails"
  )
  VALUES (
    p_company_id, p_customer_id, p_legal_name, p_tax_id, v_slug,
    p_description, p_logo_url, p_contact_email, p_contact_phone,
    p_payout_method, p_payout_details
  )
  RETURNING "Id" INTO v_id;

  RETURN QUERY SELECT true, 'Solicitud recibida. Revisaremos tu tienda en 24-48h.'::text, v_id, v_slug;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_merchant_admin_list ───────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_admin_list(
  p_company_id integer,
  p_status     varchar,
  p_page       integer,
  p_limit      integer
)
RETURNS TABLE(
  "id"           bigint,
  "legalName"    varchar,
  "storeSlug"    varchar,
  "contactEmail" varchar,
  "taxId"        varchar,
  "status"       varchar,
  "commissionRate" numeric,
  "productCount" bigint,
  "approvedCount" bigint,
  "createdAt"    timestamp,
  "approvedAt"   timestamp,
  "TotalCount"   bigint
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_page   integer := GREATEST(COALESCE(p_page,1), 1);
  v_limit  integer := LEAST(GREATEST(COALESCE(p_limit,20),1), 100);
  v_offset integer := (v_page - 1) * v_limit;
BEGIN
  RETURN QUERY
  SELECT
    s."Id", s."LegalName", s."StoreSlug", s."ContactEmail", s."TaxId",
    s."Status", s."CommissionRate",
    COALESCE((SELECT COUNT(*) FROM store."MerchantProduct" sp WHERE sp."MerchantId" = s."Id"), 0),
    COALESCE((SELECT COUNT(*) FROM store."MerchantProduct" sp WHERE sp."MerchantId" = s."Id" AND sp."Status" = 'approved'), 0),
    s."CreatedAt", s."ApprovedAt",
    COUNT(*) OVER()::bigint
  FROM store."Merchant" s
  WHERE s."CompanyId" = p_company_id
    AND (p_status IS NULL OR s."Status" = p_status)
  ORDER BY s."CreatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_merchant_admin_get_detail ─────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_admin_get_detail(
  p_company_id integer,
  p_merchant_id bigint
)
RETURNS TABLE(
  "id"            bigint,
  "legalName"     varchar,
  "storeSlug"     varchar,
  "description"   text,
  "taxId"         varchar,
  "contactEmail"  varchar,
  "contactPhone"  varchar,
  "logoUrl"       varchar,
  "bannerUrl"     varchar,
  "status"        varchar,
  "commissionRate" numeric,
  "payoutMethod"  varchar,
  "rejectionReason" varchar,
  "createdAt"     timestamp,
  "approvedAt"    timestamp,
  "approvedBy"    varchar
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT
    s."Id", s."LegalName", s."StoreSlug", s."Description", s."TaxId",
    s."ContactEmail", s."ContactPhone", s."LogoUrl", s."BannerUrl",
    s."Status", s."CommissionRate", s."PayoutMethod", s."RejectionReason",
    s."CreatedAt", s."ApprovedAt", s."ApprovedBy"
  FROM store."Merchant" s
  WHERE s."CompanyId" = p_company_id AND s."Id" = p_merchant_id
  LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_merchant_admin_set_status ─────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_admin_set_status(
  p_company_id integer,
  p_merchant_id bigint,
  p_status     varchar,
  p_actor      varchar,
  p_reason     varchar
)
RETURNS TABLE("ok" boolean, "mensaje" text)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_status NOT IN ('approved','rejected','suspended','pending') THEN
    RETURN QUERY SELECT false, 'Status inválido'::text;
    RETURN;
  END IF;

  UPDATE store."Merchant"
     SET "Status"         = p_status,
         "ApprovedAt"     = CASE WHEN p_status = 'approved' THEN (now() AT TIME ZONE 'UTC') ELSE "ApprovedAt" END,
         "ApprovedBy"     = CASE WHEN p_status = 'approved' THEN p_actor ELSE "ApprovedBy" END,
         "RejectionReason" = CASE WHEN p_status IN ('rejected','suspended') THEN p_reason ELSE "RejectionReason" END
   WHERE "Id" = p_merchant_id AND "CompanyId" = p_company_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Vendedor no encontrado'::text;
    RETURN;
  END IF;
  RETURN QUERY SELECT true, 'Estado actualizado'::text;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_merchant_dashboard ────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_dashboard(
  p_company_id  integer,
  p_customer_id integer
)
RETURNS TABLE(
  "merchantId"      bigint,
  "legalName"       varchar,
  "storeSlug"       varchar,
  "status"          varchar,
  "commissionRate"  numeric,
  "productsTotal"   bigint,
  "productsApproved" bigint,
  "productsPending" bigint,
  "ordersTotal"     bigint,
  "grossSalesUsd"   numeric,
  "payoutsPaidUsd"  numeric
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_id bigint;
BEGIN
  SELECT "Id" INTO v_id
    FROM store."Merchant"
   WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id
   LIMIT 1;
  IF v_id IS NULL THEN RETURN; END IF;

  RETURN QUERY
  SELECT
    v_id,
    (SELECT "LegalName"      FROM store."Merchant" WHERE "Id" = v_id)::varchar,
    (SELECT "StoreSlug"      FROM store."Merchant" WHERE "Id" = v_id)::varchar,
    (SELECT "Status"         FROM store."Merchant" WHERE "Id" = v_id)::varchar,
    (SELECT "CommissionRate" FROM store."Merchant" WHERE "Id" = v_id),
    (SELECT COUNT(*) FROM store."MerchantProduct" WHERE "MerchantId" = v_id)::bigint,
    (SELECT COUNT(*) FROM store."MerchantProduct" WHERE "MerchantId" = v_id AND "Status" = 'approved')::bigint,
    (SELECT COUNT(*) FROM store."MerchantProduct" WHERE "MerchantId" = v_id AND "Status" = 'pending_review')::bigint,
    (SELECT COUNT(DISTINCT l."DocumentNumber")
       FROM ar."SalesDocumentLine" l
      WHERE l."MerchantId" = v_id)::bigint,
    COALESCE((SELECT SUM(l."TotalAmount") FROM ar."SalesDocumentLine" l WHERE l."MerchantId" = v_id), 0)::numeric,
    COALESCE((SELECT SUM("NetAmount") FROM store."MerchantPayout" WHERE "MerchantId" = v_id AND "Status" = 'paid'), 0)::numeric;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_merchant_product_submit ───────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_product_submit(
  p_company_id  integer,
  p_customer_id integer,
  p_product_id  bigint,
  p_code        varchar,
  p_name        varchar,
  p_description text,
  p_price       numeric,
  p_stock       numeric,
  p_category    varchar,
  p_image_url   varchar,
  p_submit      boolean
)
RETURNS TABLE("ok" boolean, "mensaje" text, "productId" bigint, "status" varchar)
LANGUAGE plpgsql AS $$
DECLARE
  v_merchant_id bigint;
  v_pid       bigint;
  v_status    varchar(20);
BEGIN
  SELECT "Id" INTO v_merchant_id
    FROM store."Merchant"
   WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id
     AND "Status" = 'approved';
  IF v_merchant_id IS NULL THEN
    RETURN QUERY SELECT false, 'Vendedor no aprobado'::text, NULL::bigint, NULL::varchar;
    RETURN;
  END IF;

  v_status := CASE WHEN p_submit THEN 'pending_review' ELSE 'draft' END;

  IF p_product_id IS NOT NULL THEN
    UPDATE store."MerchantProduct"
       SET "Name"       = p_name,
           "Description" = p_description,
           "Price"      = p_price,
           "Stock"      = p_stock,
           "Category"   = p_category,
           "ImageUrl"   = p_image_url,
           "Status"     = v_status,
           "UpdatedAt"  = (now() AT TIME ZONE 'UTC')
     WHERE "Id" = p_product_id AND "MerchantId" = v_merchant_id
    RETURNING "Id" INTO v_pid;
    IF v_pid IS NULL THEN
      RETURN QUERY SELECT false, 'Producto no encontrado'::text, NULL::bigint, NULL::varchar;
      RETURN;
    END IF;
  ELSE
    INSERT INTO store."MerchantProduct" (
      "MerchantId","CompanyId","ProductCode","Name","Description",
      "Price","Stock","Category","ImageUrl","Status"
    )
    VALUES (
      v_merchant_id, p_company_id,
      COALESCE(p_code, 'MP-' || FLOOR(random()*1000000)::int),
      p_name, p_description, p_price, p_stock, p_category, p_image_url, v_status
    )
    RETURNING "Id" INTO v_pid;
  END IF;

  RETURN QUERY SELECT true,
    CASE WHEN p_submit THEN 'Producto enviado a revisión' ELSE 'Borrador guardado' END::text,
    v_pid, v_status;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_merchant_products_list ────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_products_list(
  p_company_id  integer,
  p_customer_id integer,
  p_status      varchar,
  p_page        integer,
  p_limit       integer
)
RETURNS TABLE(
  "id"           bigint,
  "productCode"  varchar,
  "name"         varchar,
  "price"        numeric,
  "stock"        numeric,
  "category"     varchar,
  "imageUrl"     varchar,
  "status"       varchar,
  "reviewNotes"  text,
  "createdAt"    timestamp,
  "updatedAt"    timestamp,
  "TotalCount"   bigint
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_merchant_id bigint;
  v_page   integer := GREATEST(COALESCE(p_page,1), 1);
  v_limit  integer := LEAST(GREATEST(COALESCE(p_limit,20),1), 100);
  v_offset integer := (v_page - 1) * v_limit;
BEGIN
  SELECT "Id" INTO v_merchant_id
    FROM store."Merchant"
   WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id;
  IF v_merchant_id IS NULL THEN RETURN; END IF;

  RETURN QUERY
  SELECT
    sp."Id", sp."ProductCode", sp."Name", sp."Price", sp."Stock", sp."Category",
    sp."ImageUrl", sp."Status", sp."ReviewNotes",
    sp."CreatedAt", sp."UpdatedAt",
    COUNT(*) OVER()::bigint
  FROM store."MerchantProduct" sp
  WHERE sp."MerchantId" = v_merchant_id
    AND (p_status IS NULL OR sp."Status" = p_status)
  ORDER BY sp."UpdatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_merchant_admin_products_list ──────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_admin_products_list(
  p_company_id integer,
  p_status     varchar,
  p_page       integer,
  p_limit      integer
)
RETURNS TABLE(
  "id"           bigint,
  "merchantId"   bigint,
  "merchantName" varchar,
  "productCode"  varchar,
  "name"         varchar,
  "price"        numeric,
  "stock"        numeric,
  "category"     varchar,
  "imageUrl"     varchar,
  "status"       varchar,
  "reviewNotes"  text,
  "createdAt"    timestamp,
  "TotalCount"   bigint
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_page   integer := GREATEST(COALESCE(p_page,1), 1);
  v_limit  integer := LEAST(GREATEST(COALESCE(p_limit,20),1), 100);
  v_offset integer := (v_page - 1) * v_limit;
BEGIN
  RETURN QUERY
  SELECT
    sp."Id", sp."MerchantId", s."LegalName",
    sp."ProductCode", sp."Name", sp."Price", sp."Stock", sp."Category",
    sp."ImageUrl", sp."Status", sp."ReviewNotes", sp."CreatedAt",
    COUNT(*) OVER()::bigint
  FROM store."MerchantProduct" sp
  JOIN store."Merchant" s ON s."Id" = sp."MerchantId"
  WHERE sp."CompanyId" = p_company_id
    AND (p_status IS NULL OR sp."Status" = p_status)
  ORDER BY sp."CreatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_merchant_admin_product_review ─────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_admin_product_review(
  p_company_id integer,
  p_product_id bigint,
  p_status     varchar,
  p_notes      text,
  p_actor      varchar
)
RETURNS TABLE("ok" boolean, "mensaje" text)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_status NOT IN ('approved','rejected') THEN
    RETURN QUERY SELECT false, 'Status inválido'::text;
    RETURN;
  END IF;

  UPDATE store."MerchantProduct"
     SET "Status"      = p_status,
         "ReviewNotes" = p_notes,
         "ReviewedAt"  = (now() AT TIME ZONE 'UTC'),
         "ReviewedBy"  = p_actor,
         "UpdatedAt"   = (now() AT TIME ZONE 'UTC')
   WHERE "Id" = p_product_id AND "CompanyId" = p_company_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Producto no encontrado'::text;
    RETURN;
  END IF;
  RETURN QUERY SELECT true, 'Revisión guardada'::text;
END;
$$;
-- +goose StatementEnd

-- ─── Seeds: 2 merchants ejemplo para QA / demo ───────────
-- +goose StatementBegin
INSERT INTO store."Merchant" (
  "CompanyId","CustomerId","LegalName","TaxId","StoreSlug",
  "Description","ContactEmail","ContactPhone","Status","CommissionRate",
  "PayoutMethod","ApprovedAt","ApprovedBy"
)
VALUES
  (1, NULL, 'TechHub SRL', 'J-12345678-9', 'techhub',
   'Distribuidor de accesorios tech premium', 'hola@techhub.example', '+58-212-5550101',
   'approved', 12.00, 'transferencia', (now() AT TIME ZONE 'UTC'), 'system'),
  (1, NULL, 'Moda Andina CA', 'J-87654321-0', 'moda-andina',
   'Ropa artesanal latinoamericana', 'ventas@modaandina.example', '+58-212-5550202',
   'pending', 15.00, 'paypal', NULL, NULL)
ON CONFLICT ("StoreSlug") DO NOTHING;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_merchant_admin_product_review(integer,bigint,varchar,text,varchar);
DROP FUNCTION IF EXISTS public.usp_store_merchant_admin_products_list(integer,varchar,integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_merchant_products_list(integer,integer,varchar,integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_merchant_product_submit(integer,integer,bigint,varchar,varchar,text,numeric,numeric,varchar,varchar,boolean);
DROP FUNCTION IF EXISTS public.usp_store_merchant_dashboard(integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_merchant_admin_set_status(integer,bigint,varchar,varchar,varchar);
DROP FUNCTION IF EXISTS public.usp_store_merchant_admin_get_detail(integer,bigint);
DROP FUNCTION IF EXISTS public.usp_store_merchant_admin_list(integer,varchar,integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_merchant_apply(integer,integer,varchar,varchar,varchar,text,varchar,varchar,varchar,varchar,jsonb);
ALTER TABLE ar."SalesDocumentLine" DROP COLUMN IF EXISTS "MerchantId";
DROP TABLE IF EXISTS store."MerchantPayout";
DROP TABLE IF EXISTS store."MerchantProduct";
DROP TABLE IF EXISTS store."Merchant";
-- +goose StatementEnd
