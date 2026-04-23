-- +goose Up
-- Fix: usp_store_product_getbycode solo retornaba productos publicados
-- porque consultaba la vista store.UnifiedProduct que filtra por
-- "IsPublishedStore = true". En admin necesitamos ver tambien borradores.
--
-- Cambio: consultar master.Product directamente (incluye drafts) con
-- left join opcional a merchant para productos marketplace.

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
    p."ProductId"                                     AS "id",
    p."ProductCode"                                   AS "code",
    p."ProductName"                                   AS "name",
    COALESCE(p."ShortDescription", p."ProductName")::text AS "fullDescription",
    p."ShortDescription"                              AS "shortDescription",
    p."LongDescription"                               AS "longDescription",
    p."CategoryCode"                                  AS "category",
    c."CategoryName"::varchar                         AS "categoryName",
    p."BrandCode"                                     AS "brandCode",
    b."BrandName"::varchar                            AS "brandName",
    p."SalesPrice"                                    AS "price",
    p."CompareAtPrice"                                AS "compareAtPrice",
    p."CostPrice"                                     AS "costPrice",
    p."StockQty"                                      AS "stock",
    p."IsService"                                     AS "isService",
    p."UnitCode"::varchar                             AS "unitCode",
    (CASE WHEN p."DefaultTaxRate" > 1 THEN p."DefaultTaxRate" / 100.0
          ELSE COALESCE(p."DefaultTaxRate", 0) END)   AS "taxRate",
    p."WeightKg"                                      AS "weightKg",
    p."WidthCm"                                       AS "widthCm",
    p."HeightCm"                                      AS "heightCm",
    p."DepthCm"                                       AS "depthCm",
    p."WarrantyMonths"                                AS "warrantyMonths",
    p."BarCode"::varchar                              AS "barCode",
    p."Slug"                                          AS "slug",
    COALESCE(rv.r_avg, 0)                             AS "avgRating",
    COALESCE(rv.r_count, 0)::int                      AS "reviewCount",
    'zentto'::varchar                                 AS "source",
    NULL::bigint                                      AS "merchantId",
    NULL::varchar                                     AS "merchantSlug",
    NULL::varchar                                     AS "merchantName",
    NULL::varchar                                     AS "merchantLogoUrl",
    0::double precision                               AS "merchantRating"
  FROM master."Product" p
  LEFT JOIN master."Category" c
    ON c."CategoryCode" = p."CategoryCode"
   AND c."CompanyId"    = p."CompanyId"
   AND c."IsDeleted"    = false
  LEFT JOIN master."Brand" b
    ON b."BrandCode" = p."BrandCode"
   AND b."CompanyId" = p."CompanyId"
   AND b."IsDeleted" = false
  LEFT JOIN LATERAL (
    SELECT
      AVG(r."Rating"::double precision) AS r_avg,
      COUNT(*)::int                      AS r_count
    FROM store."ProductReview" r
    WHERE r."CompanyId"   = p."CompanyId"
      AND r."ProductCode" = p."ProductCode"
      AND r."IsDeleted"   = false
      AND r."IsApproved"  = true
  ) rv ON TRUE
  WHERE p."CompanyId"   = p_company_id
    AND p."ProductCode" = p_code
    AND p."IsDeleted"   = false
  LIMIT 1;

  -- Si no hay match en master.Product, probar marketplace (merchant products)
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT
      mp."Id"                                           AS "id",
      mp."Code"                                         AS "code",
      mp."Name"                                         AS "name",
      COALESCE(mp."ShortDescription", mp."Name")::text  AS "fullDescription",
      mp."ShortDescription"                             AS "shortDescription",
      mp."LongDescription"                              AS "longDescription",
      mp."CategoryCode"::varchar                        AS "category",
      NULL::varchar                                     AS "categoryName",
      NULL::varchar                                     AS "brandCode",
      NULL::varchar                                     AS "brandName",
      mp."Price"                                        AS "price",
      mp."CompareAtPrice"                               AS "compareAtPrice",
      NULL::numeric                                     AS "costPrice",
      mp."Stock"                                        AS "stock",
      false                                             AS "isService",
      'UND'::varchar                                    AS "unitCode",
      0::numeric                                        AS "taxRate",
      NULL::numeric                                     AS "weightKg",
      NULL::numeric                                     AS "widthCm",
      NULL::numeric                                     AS "heightCm",
      NULL::numeric                                     AS "depthCm",
      NULL::integer                                     AS "warrantyMonths",
      NULL::varchar                                     AS "barCode",
      mp."Slug"                                         AS "slug",
      0::double precision                               AS "avgRating",
      0                                                 AS "reviewCount",
      'merchant'::varchar                               AS "source",
      mp."MerchantId"                                   AS "merchantId",
      NULL::varchar                                     AS "merchantSlug",
      NULL::varchar                                     AS "merchantName",
      NULL::varchar                                     AS "merchantLogoUrl",
      0::double precision                               AS "merchantRating"
    FROM store."MerchantProduct" mp
    WHERE mp."CompanyId" = p_company_id
      AND mp."Code"      = p_code
      AND mp."IsDeleted" = false
    LIMIT 1;
  END IF;
END;
$$;
-- +goose StatementEnd

-- +goose Down
SELECT 1;
