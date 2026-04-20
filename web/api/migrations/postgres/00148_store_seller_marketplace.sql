-- +goose Up
-- Marketplace de vendedores (onboarding + productos + payouts).
--
-- Tablas:
--   store.Seller          — cuenta de vendedor
--   store.SellerProduct   — propuesta de producto del vendedor
--   store.SellerPayout    — lotes de pago al vendedor
--
-- Extiende ar.SalesDocumentLine con "SellerId" para tracking de ventas por seller.
--
-- Funciones:
--   usp_store_seller_apply
--   usp_store_seller_admin_list
--   usp_store_seller_admin_get_detail
--   usp_store_seller_admin_set_status
--   usp_store_seller_dashboard
--   usp_store_seller_product_submit
--   usp_store_seller_products_list
--   usp_store_seller_admin_products_list
--   usp_store_seller_admin_product_review

-- ─── Tablas ──────────────────────────────────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."Seller" (
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
CREATE INDEX IF NOT EXISTS "IX_store_Seller_Status"   ON store."Seller" ("CompanyId","Status");
CREATE INDEX IF NOT EXISTS "IX_store_Seller_Customer" ON store."Seller" ("CompanyId","CustomerId");
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."SellerProduct" (
  "Id"             bigserial PRIMARY KEY,
  "SellerId"       bigint NOT NULL REFERENCES store."Seller"("Id") ON DELETE CASCADE,
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
CREATE INDEX IF NOT EXISTS "IX_store_SellerProduct_Seller" ON store."SellerProduct" ("SellerId","Status");
CREATE INDEX IF NOT EXISTS "IX_store_SellerProduct_Status" ON store."SellerProduct" ("CompanyId","Status","CreatedAt" DESC);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."SellerPayout" (
  "Id"              bigserial PRIMARY KEY,
  "SellerId"        bigint NOT NULL REFERENCES store."Seller"("Id"),
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
CREATE INDEX IF NOT EXISTS "IX_store_SellerPayout_Seller" ON store."SellerPayout" ("SellerId","Status","PeriodEnd" DESC);
-- +goose StatementEnd

-- ─── Extender ar.SalesDocumentLine con SellerId ──────────
-- +goose StatementBegin
ALTER TABLE ar."SalesDocumentLine"
  ADD COLUMN IF NOT EXISTS "SellerId" bigint;
CREATE INDEX IF NOT EXISTS "IX_ar_SalesDocumentLine_Seller"
  ON ar."SalesDocumentLine" ("SellerId") WHERE "SellerId" IS NOT NULL;
-- +goose StatementEnd

-- ─── usp_store_seller_apply ──────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_seller_apply(
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
RETURNS TABLE("ok" boolean, "mensaje" text, "sellerId" bigint, "storeSlug" varchar)
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

  SELECT "Id" INTO v_id FROM store."Seller"
    WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id;
  IF v_id IS NOT NULL THEN
    RETURN QUERY SELECT true, 'Ya tienes una solicitud de vendedor'::text, v_id, NULL::varchar;
    RETURN;
  END IF;

  -- Generar slug único a partir del legal_name
  v_slug := LOWER(REGEXP_REPLACE(COALESCE(p_store_slug, p_legal_name), '[^a-zA-Z0-9]+', '-', 'g'));
  v_slug := TRIM(BOTH '-' FROM v_slug);
  IF length(v_slug) < 3 THEN v_slug := 'seller-' || p_customer_id::text; END IF;

  -- Garantizar unicidad
  LOOP
    SELECT COUNT(*) INTO v_existing FROM store."Seller" WHERE "StoreSlug" = v_slug;
    EXIT WHEN v_existing = 0;
    v_slug := v_slug || '-' || FLOOR(random()*10000)::int::text;
  END LOOP;

  INSERT INTO store."Seller" (
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

-- ─── usp_store_seller_admin_list ─────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_seller_admin_list(
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
    COALESCE((SELECT COUNT(*) FROM store."SellerProduct" sp WHERE sp."SellerId" = s."Id"), 0),
    COALESCE((SELECT COUNT(*) FROM store."SellerProduct" sp WHERE sp."SellerId" = s."Id" AND sp."Status" = 'approved'), 0),
    s."CreatedAt", s."ApprovedAt",
    COUNT(*) OVER()::bigint
  FROM store."Seller" s
  WHERE s."CompanyId" = p_company_id
    AND (p_status IS NULL OR s."Status" = p_status)
  ORDER BY s."CreatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_seller_admin_get_detail ───────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_seller_admin_get_detail(
  p_company_id integer,
  p_seller_id  bigint
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
  FROM store."Seller" s
  WHERE s."CompanyId" = p_company_id AND s."Id" = p_seller_id
  LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_seller_admin_set_status ───────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_seller_admin_set_status(
  p_company_id integer,
  p_seller_id  bigint,
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

  UPDATE store."Seller"
     SET "Status"         = p_status,
         "ApprovedAt"     = CASE WHEN p_status = 'approved' THEN (now() AT TIME ZONE 'UTC') ELSE "ApprovedAt" END,
         "ApprovedBy"     = CASE WHEN p_status = 'approved' THEN p_actor ELSE "ApprovedBy" END,
         "RejectionReason" = CASE WHEN p_status IN ('rejected','suspended') THEN p_reason ELSE "RejectionReason" END
   WHERE "Id" = p_seller_id AND "CompanyId" = p_company_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Vendedor no encontrado'::text;
    RETURN;
  END IF;
  RETURN QUERY SELECT true, 'Estado actualizado'::text;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_seller_dashboard ──────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_seller_dashboard(
  p_company_id  integer,
  p_customer_id integer
)
RETURNS TABLE(
  "sellerId"        bigint,
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
    FROM store."Seller"
   WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id
   LIMIT 1;
  IF v_id IS NULL THEN RETURN; END IF;

  RETURN QUERY
  SELECT
    v_id,
    (SELECT "LegalName"      FROM store."Seller" WHERE "Id" = v_id)::varchar,
    (SELECT "StoreSlug"      FROM store."Seller" WHERE "Id" = v_id)::varchar,
    (SELECT "Status"         FROM store."Seller" WHERE "Id" = v_id)::varchar,
    (SELECT "CommissionRate" FROM store."Seller" WHERE "Id" = v_id),
    (SELECT COUNT(*) FROM store."SellerProduct" WHERE "SellerId" = v_id)::bigint,
    (SELECT COUNT(*) FROM store."SellerProduct" WHERE "SellerId" = v_id AND "Status" = 'approved')::bigint,
    (SELECT COUNT(*) FROM store."SellerProduct" WHERE "SellerId" = v_id AND "Status" = 'pending_review')::bigint,
    (SELECT COUNT(DISTINCT l."DocumentNumber")
       FROM ar."SalesDocumentLine" l
      WHERE l."SellerId" = v_id)::bigint,
    COALESCE((SELECT SUM(l."TotalAmount") FROM ar."SalesDocumentLine" l WHERE l."SellerId" = v_id), 0)::numeric,
    COALESCE((SELECT SUM("NetAmount") FROM store."SellerPayout" WHERE "SellerId" = v_id AND "Status" = 'paid'), 0)::numeric;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_seller_product_submit ─────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_seller_product_submit(
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
  v_seller_id bigint;
  v_pid       bigint;
  v_status    varchar(20);
BEGIN
  SELECT "Id" INTO v_seller_id
    FROM store."Seller"
   WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id
     AND "Status" = 'approved';
  IF v_seller_id IS NULL THEN
    RETURN QUERY SELECT false, 'Vendedor no aprobado'::text, NULL::bigint, NULL::varchar;
    RETURN;
  END IF;

  v_status := CASE WHEN p_submit THEN 'pending_review' ELSE 'draft' END;

  IF p_product_id IS NOT NULL THEN
    UPDATE store."SellerProduct"
       SET "Name"       = p_name,
           "Description" = p_description,
           "Price"      = p_price,
           "Stock"      = p_stock,
           "Category"   = p_category,
           "ImageUrl"   = p_image_url,
           "Status"     = v_status,
           "UpdatedAt"  = (now() AT TIME ZONE 'UTC')
     WHERE "Id" = p_product_id AND "SellerId" = v_seller_id
    RETURNING "Id" INTO v_pid;
    IF v_pid IS NULL THEN
      RETURN QUERY SELECT false, 'Producto no encontrado'::text, NULL::bigint, NULL::varchar;
      RETURN;
    END IF;
  ELSE
    INSERT INTO store."SellerProduct" (
      "SellerId","CompanyId","ProductCode","Name","Description",
      "Price","Stock","Category","ImageUrl","Status"
    )
    VALUES (
      v_seller_id, p_company_id,
      COALESCE(p_code, 'SP-' || FLOOR(random()*1000000)::int),
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

-- ─── usp_store_seller_products_list ──────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_seller_products_list(
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
  v_seller_id bigint;
  v_page   integer := GREATEST(COALESCE(p_page,1), 1);
  v_limit  integer := LEAST(GREATEST(COALESCE(p_limit,20),1), 100);
  v_offset integer := (v_page - 1) * v_limit;
BEGIN
  SELECT "Id" INTO v_seller_id
    FROM store."Seller"
   WHERE "CompanyId" = p_company_id AND "CustomerId" = p_customer_id;
  IF v_seller_id IS NULL THEN RETURN; END IF;

  RETURN QUERY
  SELECT
    sp."Id", sp."ProductCode", sp."Name", sp."Price", sp."Stock", sp."Category",
    sp."ImageUrl", sp."Status", sp."ReviewNotes",
    sp."CreatedAt", sp."UpdatedAt",
    COUNT(*) OVER()::bigint
  FROM store."SellerProduct" sp
  WHERE sp."SellerId" = v_seller_id
    AND (p_status IS NULL OR sp."Status" = p_status)
  ORDER BY sp."UpdatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_seller_admin_products_list ────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_seller_admin_products_list(
  p_company_id integer,
  p_status     varchar,
  p_page       integer,
  p_limit      integer
)
RETURNS TABLE(
  "id"           bigint,
  "sellerId"     bigint,
  "sellerName"   varchar,
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
    sp."Id", sp."SellerId", s."LegalName",
    sp."ProductCode", sp."Name", sp."Price", sp."Stock", sp."Category",
    sp."ImageUrl", sp."Status", sp."ReviewNotes", sp."CreatedAt",
    COUNT(*) OVER()::bigint
  FROM store."SellerProduct" sp
  JOIN store."Seller" s ON s."Id" = sp."SellerId"
  WHERE sp."CompanyId" = p_company_id
    AND (p_status IS NULL OR sp."Status" = p_status)
  ORDER BY sp."CreatedAt" DESC
  OFFSET v_offset LIMIT v_limit;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_seller_admin_product_review ───────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_seller_admin_product_review(
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

  UPDATE store."SellerProduct"
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

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_seller_admin_product_review(integer,bigint,varchar,text,varchar);
DROP FUNCTION IF EXISTS public.usp_store_seller_admin_products_list(integer,varchar,integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_seller_products_list(integer,integer,varchar,integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_seller_product_submit(integer,integer,bigint,varchar,varchar,text,numeric,numeric,varchar,varchar,boolean);
DROP FUNCTION IF EXISTS public.usp_store_seller_dashboard(integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_seller_admin_set_status(integer,bigint,varchar,varchar,varchar);
DROP FUNCTION IF EXISTS public.usp_store_seller_admin_get_detail(integer,bigint);
DROP FUNCTION IF EXISTS public.usp_store_seller_admin_list(integer,varchar,integer,integer);
DROP FUNCTION IF EXISTS public.usp_store_seller_apply(integer,integer,varchar,varchar,varchar,text,varchar,varchar,varchar,varchar,jsonb);
ALTER TABLE ar."SalesDocumentLine" DROP COLUMN IF EXISTS "SellerId";
DROP TABLE IF EXISTS store."SellerPayout";
DROP TABLE IF EXISTS store."SellerProduct";
DROP TABLE IF EXISTS store."Seller";
-- +goose StatementEnd
