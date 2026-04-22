-- +goose Up
-- Fix bugs en SPs admin del ecommerce (auditoria completa de endpoints):
--
-- Bug 1: usp_store_product_getbycode (500 "avgRating is ambiguous")
--        Las 2 subqueries LATERAL (rv y mr) exponian ambas un alias
--        "avgRating" que colisionaba con la columna "avgRating" del
--        RETURNS TABLE. Fix: renombrar a r_avg/r_count/m_avg.
--
-- Bug 2: usp_store_contactmessage_list (500 "Status is ambiguous")
--        La primera query (COUNT) no tenia alias de tabla. Fix: alias m.
--
-- Bug 3: usp_store_cmspage_upsert (500 "CmsPageId is ambiguous")
--        SELECT CmsPageId INTO v_id FROM store.CmsPage — sin alias de
--        tabla, colision con el "CmsPageId" del RETURNS TABLE. Fix: alias m.
--
-- Bug 4: usp_store_pressrelease_upsert (500 "PressReleaseId is ambiguous")
--        Mismo patron. Fix: alias pr.
--
-- Bug 5: usp_store_brand_upsert (400 "cannot insert non-DEFAULT value into BrandId")
--        El SP hacia MAX(BrandId)+1 e INSERT explicito, pero master.Brand
--        ahora es IDENTITY. Fix: omitir BrandId del INSERT.
--
-- Bug 6: usp_store_category_upsert (400 "cannot insert non-DEFAULT value into CategoryId")
--        Mismo patron con CategoryId. Fix: omitir CategoryId.

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
    COALESCE(rv.r_avg, 0)                             AS "avgRating",
    COALESCE(rv.r_count, 0)::int                      AS "reviewCount",
    u."source"::varchar                               AS "source",
    u."MerchantId"                                    AS "merchantId",
    u."MerchantSlug"                                  AS "merchantSlug",
    u."MerchantName"                                  AS "merchantName",
    u."MerchantLogoUrl"                               AS "merchantLogoUrl",
    COALESCE(mr.m_avg, 0)::double precision           AS "merchantRating"
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
      AVG(r."Rating"::double precision) AS r_avg,
      COUNT(*)::int                      AS r_count
    FROM store."ProductReview" r
    WHERE r."CompanyId"   = u."CompanyId"
      AND r."ProductCode" = u."Code"
      AND r."IsDeleted"   = false
      AND r."IsApproved"  = true
  ) rv ON TRUE
  LEFT JOIN LATERAL (
    SELECT mar."avgRating" AS m_avg
    FROM store.merchant_avg_rating(u."MerchantId") mar
  ) mr ON u."source" = 'merchant'
  WHERE u."CompanyId" = p_company_id
    AND u."Code"      = p_code
  LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_contactmessage_list(
  p_company_id integer DEFAULT 1,
  p_status     varchar DEFAULT NULL,
  p_page       integer DEFAULT 1,
  p_limit      integer DEFAULT 50
)
RETURNS TABLE (
  "ContactMessageId" bigint,
  "Name"             varchar,
  "Email"            varchar,
  "Phone"            varchar,
  "Subject"          varchar,
  "Message"          text,
  "Source"           varchar,
  "Status"           varchar,
  "CreatedAt"        timestamp,
  "TotalCount"       bigint
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_offset integer := (GREATEST(p_page,1) - 1) * GREATEST(p_limit,1);
  v_total  bigint;
BEGIN
  SELECT COUNT(*)::bigint INTO v_total
    FROM store."ContactMessage" m
   WHERE m."CompanyId" = p_company_id
     AND (p_status IS NULL OR m."Status" = p_status);

  RETURN QUERY
  SELECT
    m."ContactMessageId", m."Name", m."Email", m."Phone", m."Subject",
    m."Message", m."Source", m."Status", m."CreatedAt",
    v_total AS "TotalCount"
    FROM store."ContactMessage" m
   WHERE m."CompanyId" = p_company_id
     AND (p_status IS NULL OR m."Status" = p_status)
   ORDER BY m."CreatedAt" DESC
   OFFSET v_offset LIMIT GREATEST(p_limit,1);
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_cmspage_upsert(
  p_company_id   integer DEFAULT 1,
  p_cms_page_id  bigint  DEFAULT NULL,
  p_slug         varchar DEFAULT NULL,
  p_title        varchar DEFAULT NULL,
  p_subtitle     varchar DEFAULT NULL,
  p_template_key varchar DEFAULT NULL,
  p_config       jsonb   DEFAULT '{"sections":[]}'::jsonb,
  p_seo          jsonb   DEFAULT '{}'::jsonb,
  p_status       varchar DEFAULT 'draft'
)
RETURNS TABLE (
  "Resultado"  integer,
  "Mensaje"    varchar,
  "CmsPageId"  bigint
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id       bigint;
  v_now      timestamp := NOW() AT TIME ZONE 'UTC';
BEGIN
  IF p_slug IS NULL OR LENGTH(TRIM(p_slug)) = 0 THEN
    RETURN QUERY SELECT 0, 'slug requerido'::varchar, NULL::bigint;
    RETURN;
  END IF;
  IF p_title IS NULL OR LENGTH(TRIM(p_title)) = 0 THEN
    RETURN QUERY SELECT 0, 'title requerido'::varchar, NULL::bigint;
    RETURN;
  END IF;
  IF p_status NOT IN ('draft','published','archived') THEN
    RETURN QUERY SELECT 0, 'status invalido'::varchar, NULL::bigint;
    RETURN;
  END IF;

  IF p_cms_page_id IS NULL THEN
    SELECT m."CmsPageId" INTO v_id
      FROM store."CmsPage" m
     WHERE m."CompanyId" = p_company_id AND m."Slug" = p_slug;
  ELSE
    v_id := p_cms_page_id;
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO store."CmsPage"(
      "CompanyId","Slug","Title","Subtitle","TemplateKey",
      "Config","Seo","Status","PublishedAt","UpdatedAt","CreatedAt"
    ) VALUES (
      p_company_id, p_slug, p_title, p_subtitle, p_template_key,
      COALESCE(p_config,'{"sections":[]}'::jsonb),
      COALESCE(p_seo,'{}'::jsonb),
      p_status,
      CASE WHEN p_status = 'published' THEN v_now ELSE NULL END,
      v_now, v_now
    ) RETURNING store."CmsPage"."CmsPageId" INTO v_id;
    RETURN QUERY SELECT 1, 'creado'::varchar, v_id;
  ELSE
    UPDATE store."CmsPage" m SET
      "Slug"        = p_slug,
      "Title"       = p_title,
      "Subtitle"    = p_subtitle,
      "TemplateKey" = p_template_key,
      "Config"      = COALESCE(p_config, m."Config"),
      "Seo"         = COALESCE(p_seo, m."Seo"),
      "Status"      = p_status,
      "PublishedAt" = CASE
                        WHEN p_status = 'published' AND m."PublishedAt" IS NULL THEN v_now
                        WHEN p_status <> 'published' THEN NULL
                        ELSE m."PublishedAt"
                      END,
      "UpdatedAt"   = v_now
     WHERE m."CompanyId" = p_company_id AND m."CmsPageId" = v_id;
    RETURN QUERY SELECT 1, 'actualizado'::varchar, v_id;
  END IF;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_pressrelease_upsert(
  p_company_id       integer DEFAULT 1,
  p_press_release_id bigint  DEFAULT NULL,
  p_slug             varchar DEFAULT NULL,
  p_title            varchar DEFAULT NULL,
  p_excerpt          varchar DEFAULT NULL,
  p_body             text    DEFAULT NULL,
  p_cover_image_url  varchar DEFAULT NULL,
  p_tags             text[]  DEFAULT ARRAY[]::text[],
  p_status           varchar DEFAULT 'draft'
)
RETURNS TABLE (
  "Resultado"      integer,
  "Mensaje"        varchar,
  "PressReleaseId" bigint
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id  bigint;
  v_now timestamp := NOW() AT TIME ZONE 'UTC';
BEGIN
  IF p_slug IS NULL OR LENGTH(TRIM(p_slug)) = 0 THEN
    RETURN QUERY SELECT 0, 'slug requerido'::varchar, NULL::bigint;
    RETURN;
  END IF;
  IF p_title IS NULL OR LENGTH(TRIM(p_title)) = 0 THEN
    RETURN QUERY SELECT 0, 'title requerido'::varchar, NULL::bigint;
    RETURN;
  END IF;
  IF p_status NOT IN ('draft','published','archived') THEN
    RETURN QUERY SELECT 0, 'status invalido'::varchar, NULL::bigint;
    RETURN;
  END IF;

  IF p_press_release_id IS NULL THEN
    SELECT pr."PressReleaseId" INTO v_id
      FROM store."PressRelease" pr
     WHERE pr."CompanyId" = p_company_id AND pr."Slug" = p_slug;
  ELSE
    v_id := p_press_release_id;
  END IF;

  IF v_id IS NULL THEN
    INSERT INTO store."PressRelease"(
      "CompanyId","Slug","Title","Excerpt","Body","CoverImageUrl","Tags",
      "Status","PublishedAt","UpdatedAt","CreatedAt"
    ) VALUES (
      p_company_id, p_slug, p_title, p_excerpt, p_body, p_cover_image_url,
      COALESCE(p_tags, ARRAY[]::text[]),
      p_status,
      CASE WHEN p_status = 'published' THEN v_now ELSE NULL END,
      v_now, v_now
    ) RETURNING store."PressRelease"."PressReleaseId" INTO v_id;
    RETURN QUERY SELECT 1, 'creado'::varchar, v_id;
  ELSE
    UPDATE store."PressRelease" pr SET
      "Slug"          = p_slug,
      "Title"         = p_title,
      "Excerpt"       = p_excerpt,
      "Body"          = p_body,
      "CoverImageUrl" = p_cover_image_url,
      "Tags"          = COALESCE(p_tags, pr."Tags"),
      "Status"        = p_status,
      "PublishedAt"   = CASE
                          WHEN p_status = 'published' AND pr."PublishedAt" IS NULL THEN v_now
                          WHEN p_status <> 'published' THEN NULL
                          ELSE pr."PublishedAt"
                        END,
      "UpdatedAt"     = v_now
     WHERE pr."CompanyId" = p_company_id AND pr."PressReleaseId" = v_id;
    RETURN QUERY SELECT 1, 'actualizado'::varchar, v_id;
  END IF;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_brand_upsert(
  p_company_id integer DEFAULT 1,
  p_code       varchar DEFAULT NULL,
  p_name       varchar DEFAULT NULL,
  p_description varchar DEFAULT NULL,
  p_user_id    integer DEFAULT NULL
)
RETURNS TABLE (
  "Resultado" integer,
  "Mensaje"   varchar,
  "Code"      varchar
)
LANGUAGE plpgsql AS $$
DECLARE
  v_now    timestamp := (NOW() AT TIME ZONE 'UTC');
  v_exists boolean;
BEGIN
  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT 0, 'Código requerido'::varchar, NULL::varchar;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT 0, 'Nombre requerido'::varchar, NULL::varchar;
    RETURN;
  END IF;

  SELECT true INTO v_exists FROM master."Brand" b
   WHERE b."CompanyId" = p_company_id AND b."BrandCode" = p_code
   LIMIT 1;

  IF COALESCE(v_exists, false) THEN
    UPDATE master."Brand" b SET
      "BrandName"       = p_name,
      "Description"     = p_description,
      "IsActive"        = true,
      "IsDeleted"       = false,
      "UpdatedAt"       = v_now,
      "UpdatedByUserId" = p_user_id
     WHERE b."CompanyId" = p_company_id AND b."BrandCode" = p_code;
    RETURN QUERY SELECT 1, 'Marca actualizada'::varchar, p_code::varchar;
  ELSE
    INSERT INTO master."Brand" (
      "CompanyId", "BrandCode", "BrandName", "Description",
      "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
    ) VALUES (
      p_company_id, p_code, p_name, p_description,
      true, false, v_now, v_now, p_user_id, p_user_id
    );
    RETURN QUERY SELECT 1, 'Marca creada'::varchar, p_code::varchar;
  END IF;
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT -99, SQLERRM::varchar, NULL::varchar;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_category_upsert(
  p_company_id  integer DEFAULT 1,
  p_code        varchar DEFAULT NULL,
  p_name        varchar DEFAULT NULL,
  p_description varchar DEFAULT NULL,
  p_user_id     integer DEFAULT NULL
)
RETURNS TABLE (
  "Resultado" integer,
  "Mensaje"   varchar,
  "Code"      varchar
)
LANGUAGE plpgsql AS $$
DECLARE
  v_now    timestamp := (NOW() AT TIME ZONE 'UTC');
  v_exists boolean;
BEGIN
  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT 0, 'Código requerido'::varchar, NULL::varchar;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT 0, 'Nombre requerido'::varchar, NULL::varchar;
    RETURN;
  END IF;

  SELECT true INTO v_exists FROM master."Category" c
   WHERE c."CompanyId" = p_company_id AND c."CategoryCode" = p_code
   LIMIT 1;

  IF COALESCE(v_exists, false) THEN
    UPDATE master."Category" c SET
      "CategoryName"    = p_name,
      "Description"     = p_description,
      "IsActive"        = true,
      "IsDeleted"       = false,
      "UpdatedAt"       = v_now,
      "UpdatedByUserId" = p_user_id
     WHERE c."CompanyId" = p_company_id AND c."CategoryCode" = p_code;
    RETURN QUERY SELECT 1, 'Categoría actualizada'::varchar, p_code::varchar;
  ELSE
    INSERT INTO master."Category" (
      "CompanyId", "CategoryCode", "CategoryName", "Description",
      "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
    ) VALUES (
      p_company_id, p_code, p_name, p_description,
      true, false, v_now, v_now, p_user_id, p_user_id
    );
    RETURN QUERY SELECT 1, 'Categoría creada'::varchar, p_code::varchar;
  END IF;
EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT -99, SQLERRM::varchar, NULL::varchar;
END;
$$;
-- +goose StatementEnd

-- +goose Down
SELECT 1;
