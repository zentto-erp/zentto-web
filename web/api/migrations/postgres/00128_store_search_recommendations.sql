-- +goose Up
-- FASE 4 — Search full-text PostgreSQL + Recomendaciones + Comparar productos.
--
-- 1. master.Product.search_vector tsvector con weights (A=name, B=descr, C=brand+category)
-- 2. GIN index sobre search_vector
-- 3. SP usp_store_product_search       — full-text con ts_rank + headline (highlight)
-- 4. SP usp_store_product_recommendations — "tambien te puede interesar" por categoria/brand
-- 5. SP usp_store_product_compare      — comparativa side-by-side de hasta 4 productos

-- ─── 1. Columna generada search_vector ─────────────────
-- +goose StatementBegin
ALTER TABLE master."Product"
  ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('simple', COALESCE("ProductName", '')),       'A') ||
    setweight(to_tsvector('simple', COALESCE("ShortDescription", '')),  'B') ||
    setweight(to_tsvector('simple', COALESCE("LongDescription"::text, '')), 'B') ||
    setweight(to_tsvector('simple', COALESCE("BrandCode", '')),         'C') ||
    setweight(to_tsvector('simple', COALESCE("CategoryCode", '')),      'C') ||
    setweight(to_tsvector('simple', COALESCE("ProductCode", '')),       'D')
  ) STORED;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_master_Product_SearchVector"
  ON master."Product" USING GIN (search_vector);
-- +goose StatementEnd

-- Trigram extension (para fallback similar y suggestions)
-- +goose StatementBegin
CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_master_Product_NameTrgm"
  ON master."Product" USING GIN ("ProductName" gin_trgm_ops);
-- +goose StatementEnd

-- ─── 3. SP search full-text con ranking + highlight ────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_search(
  p_company_id integer DEFAULT 1,
  p_branch_id  integer DEFAULT 1,
  p_query      varchar DEFAULT NULL,
  p_category   varchar DEFAULT NULL,
  p_brand      varchar DEFAULT NULL,
  p_page       integer DEFAULT 1,
  p_limit      integer DEFAULT 24
) RETURNS TABLE (
  "TotalCount"   bigint,
  "code"         varchar,
  "name"         varchar,
  "highlight"    varchar,
  "category"     varchar,
  "brand"        varchar,
  "price"        numeric,
  "compareAt"    numeric,
  "stock"        numeric,
  "imageUrl"     varchar,
  "rank"         double precision
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_offset int := GREATEST((COALESCE(p_page, 1) - 1) * COALESCE(p_limit, 24), 0);
  v_query  tsquery;
  v_total  bigint;
BEGIN
  -- Convertir consulta libre a tsquery con prefix matching y AND entre términos
  IF p_query IS NULL OR TRIM(p_query) = '' THEN
    v_query := NULL;
  ELSE
    v_query := websearch_to_tsquery('simple', p_query);
    IF v_query::text = '' THEN
      v_query := plainto_tsquery('simple', p_query);
    END IF;
  END IF;

  SELECT COUNT(*) INTO v_total
    FROM master."Product" p
   WHERE p."CompanyId" = p_company_id
     AND p."IsDeleted" = FALSE
     AND p."IsActive"  = TRUE
     AND (p_category IS NULL OR p."CategoryCode" = p_category)
     AND (p_brand    IS NULL OR p."BrandCode"    = p_brand)
     AND (v_query IS NULL OR p.search_vector @@ v_query);

  RETURN QUERY
  SELECT
    v_total,
    p."ProductCode"::varchar,
    p."ProductName"::varchar,
    CASE
      WHEN v_query IS NULL THEN COALESCE(p."ShortDescription", '')::varchar
      ELSE ts_headline('simple',
                       COALESCE(p."ShortDescription", p."ProductName"),
                       v_query,
                       'StartSel=<mark>,StopSel=</mark>,MaxWords=20,MinWords=5,ShortWord=2'
                      )::varchar
    END,
    p."CategoryCode"::varchar,
    p."BrandCode"::varchar,
    p."SalesPrice",
    p."CompareAtPrice",
    p."StockQty",
    img."PublicUrl"::varchar,
    CASE WHEN v_query IS NULL THEN 0::float8 ELSE ts_rank(p.search_vector, v_query)::float8 END
  FROM master."Product" p
  LEFT JOIN LATERAL (
    SELECT ma."PublicUrl"
      FROM cfg."EntityImage" ei
      INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
     WHERE ei."CompanyId"  = p."CompanyId"
       AND ei."BranchId"   = p_branch_id
       AND ei."EntityType" = 'MASTER_PRODUCT'
       AND ei."EntityId"   = p."ProductId"
       AND ei."IsDeleted"  = FALSE
       AND ei."IsActive"   = TRUE
       AND ma."IsActive"   = TRUE
     ORDER BY ei."IsPrimary" DESC, ei."SortOrder"
     LIMIT 1
  ) img ON TRUE
  WHERE p."CompanyId" = p_company_id
    AND p."IsDeleted" = FALSE
    AND p."IsActive"  = TRUE
    AND (p_category IS NULL OR p."CategoryCode" = p_category)
    AND (p_brand    IS NULL OR p."BrandCode"    = p_brand)
    AND (v_query IS NULL OR p.search_vector @@ v_query)
  ORDER BY
    CASE WHEN v_query IS NULL THEN 0 ELSE ts_rank(p.search_vector, v_query) END DESC,
    p."ProductName"
  LIMIT COALESCE(p_limit, 24)
  OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ─── 4. Recomendaciones "También te puede interesar" ───
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_recommendations(
  p_company_id    integer DEFAULT 1,
  p_branch_id     integer DEFAULT 1,
  p_product_code  varchar DEFAULT NULL,
  p_limit         integer DEFAULT 8
) RETURNS TABLE (
  "code"        varchar,
  "name"        varchar,
  "category"    varchar,
  "brand"       varchar,
  "price"       numeric,
  "stock"       numeric,
  "imageUrl"    varchar,
  "avgRating"   double precision,
  "reviewCount" integer,
  "matchScore"  integer
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_category varchar(100);
  v_brand    varchar(20);
BEGIN
  SELECT "CategoryCode", "BrandCode"
    INTO v_category, v_brand
    FROM master."Product"
   WHERE "CompanyId" = p_company_id
     AND "ProductCode" = p_product_code
   LIMIT 1;

  IF v_category IS NULL AND v_brand IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH ratings AS (
    SELECT r."ProductCode",
           AVG(r."Rating"::float8)  AS "avgRating",
           COUNT(*)::int            AS "reviewCount"
      FROM store."ProductReview" r
     WHERE r."CompanyId"  = p_company_id
       AND r."IsDeleted"  = FALSE
       AND r."IsApproved" = TRUE
     GROUP BY r."ProductCode"
  )
  SELECT
    p."ProductCode"::varchar,
    p."ProductName"::varchar,
    p."CategoryCode"::varchar,
    p."BrandCode"::varchar,
    p."SalesPrice",
    p."StockQty",
    img."PublicUrl"::varchar,
    COALESCE(rt."avgRating", 0)::float8,
    COALESCE(rt."reviewCount", 0)::int,
    -- Match score: brand+category=3, solo brand=2, solo category=1
    CASE
      WHEN p."BrandCode"    = v_brand AND p."CategoryCode" = v_category THEN 3
      WHEN p."BrandCode"    = v_brand                                     THEN 2
      WHEN p."CategoryCode" = v_category                                  THEN 1
      ELSE 0
    END
  FROM master."Product" p
  LEFT JOIN ratings rt ON rt."ProductCode" = p."ProductCode"
  LEFT JOIN LATERAL (
    SELECT ma."PublicUrl"
      FROM cfg."EntityImage" ei
      INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
     WHERE ei."CompanyId"  = p."CompanyId"
       AND ei."BranchId"   = p_branch_id
       AND ei."EntityType" = 'MASTER_PRODUCT'
       AND ei."EntityId"   = p."ProductId"
       AND ei."IsDeleted"  = FALSE
       AND ei."IsActive"   = TRUE
       AND ma."IsActive"   = TRUE
     ORDER BY ei."IsPrimary" DESC, ei."SortOrder"
     LIMIT 1
  ) img ON TRUE
  WHERE p."CompanyId"   = p_company_id
    AND p."IsDeleted"   = FALSE
    AND p."IsActive"    = TRUE
    AND p."ProductCode" <> p_product_code
    AND (p."BrandCode" = v_brand OR p."CategoryCode" = v_category)
  ORDER BY
    CASE
      WHEN p."BrandCode"    = v_brand AND p."CategoryCode" = v_category THEN 3
      WHEN p."BrandCode"    = v_brand                                     THEN 2
      WHEN p."CategoryCode" = v_category                                  THEN 1
      ELSE 0
    END DESC,
    COALESCE(rt."avgRating", 0) DESC,
    COALESCE(rt."reviewCount", 0) DESC
  LIMIT GREATEST(p_limit, 1);
END;
$$;
-- +goose StatementEnd

-- ─── 5. Comparar productos (hasta 4) ───────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_compare(
  p_company_id integer DEFAULT 1,
  p_branch_id  integer DEFAULT 1,
  p_codes      text[]  DEFAULT NULL
) RETURNS TABLE (
  "code"        varchar,
  "name"        varchar,
  "brand"       varchar,
  "category"    varchar,
  "price"       numeric,
  "compareAt"   numeric,
  "stock"       numeric,
  "isService"   boolean,
  "warranty"    integer,
  "weightKg"    numeric,
  "widthCm"     numeric,
  "heightCm"    numeric,
  "depthCm"     numeric,
  "imageUrl"    varchar,
  "avgRating"   double precision,
  "reviewCount" integer,
  "specsJson"   jsonb
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  IF p_codes IS NULL OR array_length(p_codes, 1) IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH ratings AS (
    SELECT r."ProductCode",
           AVG(r."Rating"::float8) AS "avgRating",
           COUNT(*)::int           AS "reviewCount"
      FROM store."ProductReview" r
     WHERE r."CompanyId"  = p_company_id
       AND r."IsDeleted"  = FALSE
       AND r."IsApproved" = TRUE
     GROUP BY r."ProductCode"
  ),
  specs AS (
    SELECT s."ProductCode",
           jsonb_object_agg(s."SpecKey", s."SpecValue") AS specs_json
      FROM store."ProductSpec" s
     WHERE s."CompanyId" = p_company_id
       AND s."IsActive"  = TRUE
     GROUP BY s."ProductCode"
  )
  SELECT
    p."ProductCode"::varchar,
    p."ProductName"::varchar,
    p."BrandCode"::varchar,
    p."CategoryCode"::varchar,
    p."SalesPrice",
    p."CompareAtPrice",
    p."StockQty",
    p."IsService",
    p."WarrantyMonths",
    p."WeightKg",
    p."WidthCm",
    p."HeightCm",
    p."DepthCm",
    img."PublicUrl"::varchar,
    COALESCE(rt."avgRating", 0)::float8,
    COALESCE(rt."reviewCount", 0)::int,
    COALESCE(sp.specs_json, '{}'::jsonb)
  FROM master."Product" p
  LEFT JOIN ratings rt ON rt."ProductCode" = p."ProductCode"
  LEFT JOIN specs   sp ON sp."ProductCode" = p."ProductCode"
  LEFT JOIN LATERAL (
    SELECT ma."PublicUrl"
      FROM cfg."EntityImage" ei
      INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
     WHERE ei."CompanyId"  = p."CompanyId"
       AND ei."BranchId"   = p_branch_id
       AND ei."EntityType" = 'MASTER_PRODUCT'
       AND ei."EntityId"   = p."ProductId"
       AND ei."IsDeleted"  = FALSE
       AND ei."IsActive"   = TRUE
       AND ma."IsActive"   = TRUE
     ORDER BY ei."IsPrimary" DESC, ei."SortOrder"
     LIMIT 1
  ) img ON TRUE
  WHERE p."CompanyId"   = p_company_id
    AND p."IsDeleted"   = FALSE
    AND p."IsActive"    = TRUE
    AND p."ProductCode" = ANY(p_codes)
  ORDER BY array_position(p_codes, p."ProductCode")
  LIMIT 4;
END;
$$;
-- +goose StatementEnd


-- +goose Down
DROP FUNCTION IF EXISTS public.usp_store_product_compare(integer, integer, text[]);
DROP FUNCTION IF EXISTS public.usp_store_product_recommendations(integer, integer, varchar, integer);
DROP FUNCTION IF EXISTS public.usp_store_product_search(integer, integer, varchar, varchar, varchar, integer, integer);
DROP INDEX IF EXISTS "IX_master_Product_NameTrgm";
DROP INDEX IF EXISTS "IX_master_Product_SearchVector";
ALTER TABLE master."Product" DROP COLUMN IF EXISTS search_vector;
