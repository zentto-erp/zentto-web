-- +goose Up
-- Ola 4 — Marketplace: productos merchant visibles en storefront público.
--
-- Auditoría: docs/architecture/marketplace-flow-audit.md (P0 #1).
-- Hueco detectado: usp_store_product_list lee solo master."Product"; los
-- productos aprobados en store."MerchantProduct" nunca aparecen en la tienda.
--
-- Estrategia:
--   1. Vista store."UnifiedProduct" — unión entre master."Product" publicados
--      (IsPublishedStore=true) y store."MerchantProduct" Status='approved'
--      cuyo Merchant también está approved. Expone el "source" ('zentto' |
--      'merchant') y datos del vendedor cuando aplica.
--   2. Re-declarar usp_store_product_list para leer de la vista. Mantiene
--      firma pública + agrega p_merchant_slug y p_include_merchant.
--   3. Re-declarar usp_store_product_getbycode para retornar info del
--      merchant (id/slug/name/rating) si el producto viene del marketplace.
--   4. Nueva función usp_store_merchant_public_get — perfil público del
--      merchant por slug (GET /store/merchants/:slug).
--
-- Retrocompat:
--   - Firma de usp_store_product_list conserva params originales y agrega
--     p_merchant_slug + p_include_merchant (ambos con DEFAULT).
--   - usp_store_product_getbycode suma columnas merchant* al final; clientes
--     previos que desestructuran por nombre siguen funcionando.
--
-- Paridad SQL Server: patch 09_patch_marketplace_products_visibility.sql.

-- ─── Helper: rating de merchant (avg de sus productos) ───
-- No existe tabla de reseñas de merchants (futuro) — usamos rating promedio
-- de store."ProductReview" filtrando productos cuyo ProductCode pertenece al
-- merchant. Si no hay reviews, devuelve NULL.
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION store.merchant_avg_rating(p_merchant_id bigint)
RETURNS TABLE("avgRating" numeric, "reviewCount" bigint)
LANGUAGE sql STABLE AS $$
  SELECT
    COALESCE(AVG(r."Rating")::numeric(4,2), NULL)   AS "avgRating",
    COUNT(*)::bigint                                 AS "reviewCount"
    FROM store."ProductReview" r
   WHERE r."IsDeleted"  = false
     AND r."IsApproved" = true
     AND r."ProductCode" IN (
       SELECT mp."ProductCode" FROM store."MerchantProduct" mp
        WHERE mp."MerchantId" = p_merchant_id
          AND mp."Status" = 'approved'
     );
$$;
-- +goose StatementEnd

-- ─── Vista store."UnifiedProduct" ─────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE VIEW store."UnifiedProduct" AS
SELECT
  'zentto'::text                                    AS "source",
  p."ProductId"::bigint                             AS "Id",
  p."ProductCode"::varchar(80)                      AS "Code",
  p."ProductName"::varchar(250)                     AS "Name",
  p."ShortDescription"::varchar(500)                AS "ShortDescription",
  p."LongDescription"::text                         AS "LongDescription",
  p."CategoryCode"::varchar(100)                    AS "CategoryCode",
  p."BrandCode"::varchar(50)                        AS "BrandCode",
  p."SalesPrice"::numeric(18,4)                     AS "Price",
  p."CompareAtPrice"::numeric(18,4)                 AS "CompareAtPrice",
  p."StockQty"::numeric(18,4)                       AS "Stock",
  p."IsService"::boolean                            AS "IsService",
  p."DefaultTaxRate"::numeric(9,4)                  AS "TaxRate",
  p."Slug"::varchar(200)                            AS "Slug",
  NULL::varchar(500)                                AS "ImageUrl",
  NULL::bigint                                      AS "MerchantId",
  NULL::varchar(80)                                 AS "MerchantSlug",
  NULL::varchar(200)                                AS "MerchantName",
  NULL::varchar(500)                                AS "MerchantLogoUrl",
  TRUE                                              AS "Published",
  p."CompanyId"::integer                            AS "CompanyId",
  p."CreatedAt"                                     AS "CreatedAt",
  p."UpdatedAt"                                     AS "UpdatedAt"
  FROM master."Product" p
 WHERE p."IsDeleted"         = false
   AND p."IsActive"          = true
   AND COALESCE(p."IsPublishedStore", false) = true
UNION ALL
SELECT
  'merchant'::text                                  AS "source",
  mp."Id"::bigint                                   AS "Id",
  mp."ProductCode"::varchar(80)                     AS "Code",
  mp."Name"::varchar(250)                           AS "Name",
  COALESCE(LEFT(mp."Description", 500),'')::varchar(500) AS "ShortDescription",
  mp."Description"::text                            AS "LongDescription",
  mp."Category"::varchar(100)                       AS "CategoryCode",
  NULL::varchar(50)                                 AS "BrandCode",
  mp."Price"::numeric(18,4)                         AS "Price",
  NULL::numeric(18,4)                               AS "CompareAtPrice",
  mp."Stock"::numeric(18,4)                         AS "Stock",
  FALSE                                             AS "IsService",
  0::numeric(9,4)                                   AS "TaxRate",
  NULL::varchar(200)                                AS "Slug",
  mp."ImageUrl"::varchar(500)                       AS "ImageUrl",
  m."Id"::bigint                                    AS "MerchantId",
  m."StoreSlug"::varchar(80)                        AS "MerchantSlug",
  m."LegalName"::varchar(200)                       AS "MerchantName",
  m."LogoUrl"::varchar(500)                         AS "MerchantLogoUrl",
  TRUE                                              AS "Published",
  mp."CompanyId"::integer                           AS "CompanyId",
  mp."CreatedAt"                                    AS "CreatedAt",
  mp."UpdatedAt"                                    AS "UpdatedAt"
  FROM store."MerchantProduct" mp
  JOIN store."Merchant" m ON m."Id" = mp."MerchantId"
 WHERE mp."Status" = 'approved'
   AND m."Status"  = 'approved';
-- +goose StatementEnd

COMMENT ON VIEW store."UnifiedProduct" IS
  'Unión de catálogo: master.Product publicados + store.MerchantProduct approved (con Merchant approved). Auditoría marketplace-flow P0 #1.';

-- ─── Re-declarar usp_store_product_list (desde la vista) ──
-- Firma extendida — agrega p_merchant_slug + p_include_merchant (DEFAULTs).
-- Nota: las funciones PG no soportan overload cambiando tipos de retorno sin
-- DROP. La anterior (baseline/005_functions.sql:36906) existe como
-- FUNCTION sin OR REPLACE; la rehacemos aquí con retrocompat.
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_product_list(
  integer, integer, varchar, varchar, varchar, numeric, numeric,
  integer, boolean, varchar, integer, integer
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_list(
  p_company_id       integer DEFAULT 1,
  p_branch_id        integer DEFAULT 1,
  p_search           varchar DEFAULT NULL,
  p_category         varchar DEFAULT NULL,
  p_brand            varchar DEFAULT NULL,
  p_price_min        numeric DEFAULT NULL,
  p_price_max        numeric DEFAULT NULL,
  p_min_rating       integer DEFAULT NULL,
  p_in_stock_only    boolean DEFAULT true,
  p_sort_by          varchar DEFAULT 'name',
  p_page             integer DEFAULT 1,
  p_limit            integer DEFAULT 24,
  p_merchant_slug    varchar DEFAULT NULL,
  p_include_merchant boolean DEFAULT true
)
RETURNS TABLE (
  "TotalCount"       bigint,
  "id"               bigint,
  "code"             varchar,
  "name"             varchar,
  "fullDescription"  varchar,
  "shortDescription" varchar,
  "category"         varchar,
  "categoryName"     varchar,
  "brandCode"        varchar,
  "brandName"        varchar,
  "price"            numeric,
  "compareAtPrice"   numeric,
  "stock"            numeric,
  "isService"        boolean,
  "taxRate"          numeric,
  "imageUrl"         varchar,
  "avgRating"        double precision,
  "reviewCount"      integer,
  "source"           varchar,
  "merchantId"       bigint,
  "merchantSlug"     varchar,
  "merchantName"     varchar
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_offset int := (GREATEST(COALESCE(p_page, 1), 1) - 1) * COALESCE(p_limit, 24);
  v_pattern varchar := CASE
    WHEN p_search IS NOT NULL AND TRIM(p_search) <> '' THEN '%' || TRIM(p_search) || '%'
    ELSE NULL END;
  v_total bigint;
BEGIN
  -- Total con mismos filtros
  SELECT COUNT(*) INTO v_total
    FROM store."UnifiedProduct" u
    LEFT JOIN LATERAL (
      SELECT AVG(r."Rating"::double precision) AS "avgRating"
        FROM store."ProductReview" r
       WHERE r."CompanyId" = u."CompanyId"
         AND r."ProductCode" = u."Code"
         AND r."IsDeleted" = false
         AND r."IsApproved" = true
    ) rv ON TRUE
   WHERE u."CompanyId" = p_company_id
     AND (p_include_merchant OR u."source" = 'zentto')
     AND (NOT p_in_stock_only OR u."Stock" > 0 OR u."IsService" = TRUE)
     AND (v_pattern IS NULL
          OR u."Code" LIKE v_pattern
          OR u."Name" LIKE v_pattern
          OR COALESCE(u."CategoryCode",'') LIKE v_pattern)
     AND (p_category IS NULL OR u."CategoryCode" = p_category)
     AND (p_brand IS NULL OR u."BrandCode" = p_brand)
     AND (p_price_min IS NULL OR u."Price" >= p_price_min)
     AND (p_price_max IS NULL OR u."Price" <= p_price_max)
     AND (p_min_rating IS NULL OR COALESCE(rv."avgRating", 0) >= p_min_rating)
     AND (p_merchant_slug IS NULL OR u."MerchantSlug" = p_merchant_slug);

  RETURN QUERY
  SELECT
    v_total                                   AS "TotalCount",
    u."Id"                                    AS "id",
    u."Code"                                  AS "code",
    u."Name"                                  AS "name",
    COALESCE(u."ShortDescription", u."Name")::varchar AS "fullDescription",
    u."ShortDescription"                      AS "shortDescription",
    u."CategoryCode"                          AS "category",
    c."CategoryName"::varchar                 AS "categoryName",
    u."BrandCode"                             AS "brandCode",
    b."BrandName"::varchar                    AS "brandName",
    u."Price"                                 AS "price",
    u."CompareAtPrice"                        AS "compareAtPrice",
    u."Stock"                                 AS "stock",
    u."IsService"                             AS "isService",
    (CASE WHEN u."TaxRate" > 1 THEN u."TaxRate" / 100.0
          ELSE COALESCE(u."TaxRate", 0) END)  AS "taxRate",
    COALESCE(u."ImageUrl", img."PublicUrl")::varchar AS "imageUrl",
    COALESCE(rv."avgRating", 0)               AS "avgRating",
    COALESCE(rv."reviewCount", 0)::int        AS "reviewCount",
    u."source"::varchar                       AS "source",
    u."MerchantId"                            AS "merchantId",
    u."MerchantSlug"                          AS "merchantSlug",
    u."MerchantName"                          AS "merchantName"
  FROM store."UnifiedProduct" u
  LEFT JOIN master."Category" c
    ON c."CategoryCode" = u."CategoryCode"
   AND c."CompanyId"    = u."CompanyId"
   AND c."IsDeleted"    = false
  LEFT JOIN master."Brand" b
    ON b."BrandCode" = u."BrandCode"
   AND b."CompanyId" = u."CompanyId"
   AND b."IsDeleted" = false
  LEFT JOIN LATERAL (
    SELECT ma."PublicUrl"
      FROM cfg."EntityImage" ei
      INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
     WHERE ei."CompanyId"   = u."CompanyId"
       AND ei."BranchId"    = p_branch_id
       AND ei."EntityType"  = 'MASTER_PRODUCT'
       AND ei."EntityId"    = u."Id"
       AND ei."IsDeleted"   = false
       AND ei."IsActive"    = true
       AND ma."IsDeleted"   = false
       AND ma."IsActive"    = true
     ORDER BY CASE WHEN ei."IsPrimary" = true THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
     LIMIT 1
  ) img ON u."source" = 'zentto'
  LEFT JOIN LATERAL (
    SELECT
      AVG(r."Rating"::double precision) AS "avgRating",
      COUNT(*)::int                      AS "reviewCount"
    FROM store."ProductReview" r
    WHERE r."CompanyId"   = u."CompanyId"
      AND r."ProductCode" = u."Code"
      AND r."IsDeleted"   = false
      AND r."IsApproved"  = true
  ) rv ON TRUE
  WHERE u."CompanyId" = p_company_id
    AND (p_include_merchant OR u."source" = 'zentto')
    AND (NOT p_in_stock_only OR u."Stock" > 0 OR u."IsService" = TRUE)
    AND (v_pattern IS NULL
         OR u."Code" LIKE v_pattern
         OR u."Name" LIKE v_pattern
         OR COALESCE(u."CategoryCode",'') LIKE v_pattern)
    AND (p_category IS NULL OR u."CategoryCode" = p_category)
    AND (p_brand IS NULL OR u."BrandCode" = p_brand)
    AND (p_price_min IS NULL OR u."Price" >= p_price_min)
    AND (p_price_max IS NULL OR u."Price" <= p_price_max)
    AND (p_min_rating IS NULL OR COALESCE(rv."avgRating", 0) >= p_min_rating)
    AND (p_merchant_slug IS NULL OR u."MerchantSlug" = p_merchant_slug)
  ORDER BY
    CASE WHEN p_sort_by = 'name'       THEN u."Name"  END ASC,
    CASE WHEN p_sort_by = 'price_asc'  THEN u."Price" END ASC,
    CASE WHEN p_sort_by = 'price_desc' THEN u."Price" END DESC,
    CASE WHEN p_sort_by = 'rating'     THEN rv."avgRating" END DESC,
    CASE WHEN p_sort_by = 'newest'     THEN u."CreatedAt" END DESC,
    u."Name" ASC
  LIMIT COALESCE(p_limit, 24) OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ─── Re-declarar usp_store_product_getbycode con merchant ──
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_product_getbycode(
  integer, integer, varchar
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_getbycode(
  p_company_id integer DEFAULT 1,
  p_branch_id  integer DEFAULT 1,
  p_code       varchar DEFAULT NULL
)
RETURNS TABLE (
  "id"               bigint,
  "code"             varchar,
  "name"             varchar,
  "fullDescription"  text,
  "shortDescription" varchar,
  "longDescription"  text,
  "category"         varchar,
  "categoryName"     varchar,
  "brandCode"        varchar,
  "brandName"        varchar,
  "price"            numeric,
  "compareAtPrice"   numeric,
  "costPrice"        numeric,
  "stock"            numeric,
  "isService"        boolean,
  "unitCode"         varchar,
  "taxRate"          numeric,
  "weightKg"         numeric,
  "widthCm"          numeric,
  "heightCm"         numeric,
  "depthCm"          numeric,
  "warrantyMonths"   integer,
  "barCode"          varchar,
  "slug"             varchar,
  "avgRating"        double precision,
  "reviewCount"      integer,
  "source"           varchar,
  "merchantId"       bigint,
  "merchantSlug"     varchar,
  "merchantName"     varchar,
  "merchantLogoUrl"  varchar,
  "merchantRating"   double precision
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT
    u."Id"                                            AS "id",
    u."Code"                                          AS "code",
    u."Name"                                          AS "name",
    COALESCE(u."ShortDescription", u."Name")::text    AS "fullDescription",
    u."ShortDescription"                              AS "shortDescription",
    u."LongDescription"                               AS "longDescription",
    u."CategoryCode"                                  AS "category",
    c."CategoryName"::varchar                         AS "categoryName",
    u."BrandCode"                                     AS "brandCode",
    b."BrandName"::varchar                            AS "brandName",
    u."Price"                                         AS "price",
    u."CompareAtPrice"                                AS "compareAtPrice",
    p."CostPrice"                                     AS "costPrice",
    u."Stock"                                         AS "stock",
    u."IsService"                                     AS "isService",
    p."UnitCode"::varchar                             AS "unitCode",
    (CASE WHEN u."TaxRate" > 1 THEN u."TaxRate" / 100.0
          ELSE COALESCE(u."TaxRate", 0) END)          AS "taxRate",
    p."WeightKg"                                      AS "weightKg",
    p."WidthCm"                                       AS "widthCm",
    p."HeightCm"                                      AS "heightCm",
    p."DepthCm"                                       AS "depthCm",
    p."WarrantyMonths"                                AS "warrantyMonths",
    p."BarCode"::varchar                              AS "barCode",
    u."Slug"                                          AS "slug",
    COALESCE(rv."avgRating", 0)                       AS "avgRating",
    COALESCE(rv."reviewCount", 0)::int                AS "reviewCount",
    u."source"::varchar                               AS "source",
    u."MerchantId"                                    AS "merchantId",
    u."MerchantSlug"                                  AS "merchantSlug",
    u."MerchantName"                                  AS "merchantName",
    u."MerchantLogoUrl"                               AS "merchantLogoUrl",
    COALESCE(mr."avgRating", 0)::double precision     AS "merchantRating"
  FROM store."UnifiedProduct" u
  LEFT JOIN master."Product" p
    ON u."source" = 'zentto'
   AND p."ProductId" = u."Id"
   AND p."CompanyId" = u."CompanyId"
  LEFT JOIN master."Category" c
    ON c."CategoryCode" = u."CategoryCode"
   AND c."CompanyId"    = u."CompanyId"
   AND c."IsDeleted"    = false
  LEFT JOIN master."Brand" b
    ON b."BrandCode" = u."BrandCode"
   AND b."CompanyId" = u."CompanyId"
   AND b."IsDeleted" = false
  LEFT JOIN LATERAL (
    SELECT
      AVG(r."Rating"::double precision) AS "avgRating",
      COUNT(*)::int                      AS "reviewCount"
    FROM store."ProductReview" r
    WHERE r."CompanyId"   = u."CompanyId"
      AND r."ProductCode" = u."Code"
      AND r."IsDeleted"   = false
      AND r."IsApproved"  = true
  ) rv ON TRUE
  LEFT JOIN LATERAL (
    SELECT "avgRating" FROM store.merchant_avg_rating(u."MerchantId")
  ) mr ON u."source" = 'merchant'
  WHERE u."CompanyId" = p_company_id
    AND u."Code"      = p_code
  LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ─── usp_store_merchant_public_get (perfil público) ──────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_merchant_public_get(
  p_company_id integer,
  p_slug       varchar
)
RETURNS TABLE (
  "merchantId"      bigint,
  "storeSlug"       varchar,
  "legalName"       varchar,
  "description"     text,
  "logoUrl"         varchar,
  "bannerUrl"       varchar,
  "contactEmail"    varchar,
  "productsApproved" bigint,
  "avgRating"       double precision,
  "reviewCount"     bigint,
  "createdAt"       timestamp
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT
    m."Id"::bigint,
    m."StoreSlug"::varchar,
    m."LegalName"::varchar,
    m."Description"::text,
    m."LogoUrl"::varchar,
    m."BannerUrl"::varchar,
    m."ContactEmail"::varchar,
    COALESCE((SELECT COUNT(*) FROM store."MerchantProduct" sp
               WHERE sp."MerchantId" = m."Id"
                 AND sp."Status" = 'approved'), 0)::bigint,
    COALESCE(mr."avgRating", 0)::double precision,
    COALESCE(mr."reviewCount", 0),
    m."CreatedAt"
    FROM store."Merchant" m
    LEFT JOIN LATERAL store.merchant_avg_rating(m."Id") mr ON TRUE
   WHERE m."CompanyId" = p_company_id
     AND m."StoreSlug" = p_slug
     AND m."Status"    = 'approved'
   LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_merchant_public_get(integer, varchar);
DROP FUNCTION IF EXISTS public.usp_store_product_getbycode(integer, integer, varchar);
DROP FUNCTION IF EXISTS public.usp_store_product_list(
  integer, integer, varchar, varchar, varchar, numeric, numeric,
  integer, boolean, varchar, integer, integer, varchar, boolean
);
DROP VIEW IF EXISTS store."UnifiedProduct";
DROP FUNCTION IF EXISTS store.merchant_avg_rating(bigint);
-- +goose StatementEnd
