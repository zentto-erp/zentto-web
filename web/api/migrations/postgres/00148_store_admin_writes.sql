-- +goose Up
-- Backoffice ecommerce — writes para productos, imágenes, highlights, specs,
-- categorías, marcas y moderación de reviews.
--
-- Writes:
--   usp_store_product_upsert
--   usp_store_product_delete
--   usp_store_product_publish_toggle
--   usp_store_product_images_set
--   usp_store_product_highlights_set
--   usp_store_product_specs_set
--   usp_store_category_upsert
--   usp_store_category_delete
--   usp_store_brand_upsert
--   usp_store_brand_delete
--   usp_store_review_moderate
--   usp_store_review_list
--   usp_store_product_list_admin

-- ─── Columnas adicionales en master."Product" (SEO + publicación store) ───
-- +goose StatementBegin
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'master' AND table_name = 'Product' AND column_name = 'MetaTitle'
    ) THEN
        ALTER TABLE master."Product" ADD COLUMN "MetaTitle" varchar(200);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'master' AND table_name = 'Product' AND column_name = 'MetaDescription'
    ) THEN
        ALTER TABLE master."Product" ADD COLUMN "MetaDescription" varchar(320);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'master' AND table_name = 'Product' AND column_name = 'IsPublishedStore'
    ) THEN
        ALTER TABLE master."Product" ADD COLUMN "IsPublishedStore" boolean DEFAULT false NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'master' AND table_name = 'Product' AND column_name = 'PublishedAt'
    ) THEN
        ALTER TABLE master."Product" ADD COLUMN "PublishedAt" timestamp without time zone;
    END IF;
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE UNIQUE INDEX IF NOT EXISTS "IX_master_Product_Slug_Company"
    ON master."Product" ("CompanyId", "Slug")
    WHERE "Slug" IS NOT NULL AND "IsDeleted" = false;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_master_Product_PublishedStore"
    ON master."Product" ("CompanyId", "IsPublishedStore", "PublishedAt" DESC)
    WHERE "IsDeleted" = false;
-- +goose StatementEnd

-- ─── Columnas de moderación en store."ProductReview" ───
-- +goose StatementBegin
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'store' AND table_name = 'ProductReview' AND column_name = 'Status'
    ) THEN
        ALTER TABLE store."ProductReview" ADD COLUMN "Status" varchar(20) DEFAULT 'pending' NOT NULL;
        ALTER TABLE store."ProductReview"
            ADD CONSTRAINT "ProductReview_Status_check"
            CHECK ("Status" IN ('pending','approved','rejected'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'store' AND table_name = 'ProductReview' AND column_name = 'ModeratedAt'
    ) THEN
        ALTER TABLE store."ProductReview" ADD COLUMN "ModeratedAt" timestamp without time zone;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'store' AND table_name = 'ProductReview' AND column_name = 'ModeratorUser'
    ) THEN
        ALTER TABLE store."ProductReview" ADD COLUMN "ModeratorUser" varchar(60);
    END IF;

    -- Sincronizar Status con IsApproved para filas existentes
    UPDATE store."ProductReview"
       SET "Status" = CASE WHEN "IsApproved" THEN 'approved' ELSE 'pending' END
     WHERE "Status" = 'pending';
END $$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "IX_store_ProductReview_Status"
    ON store."ProductReview" ("CompanyId", "Status", "CreatedAt" DESC);
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════
-- FUNCIONES — PRODUCTOS
-- ═══════════════════════════════════════════════════════════════════════

-- ─── Upsert de producto (admin store) ─────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_upsert(
    p_company_id        integer DEFAULT 1,
    p_code              varchar DEFAULT NULL,
    p_name              varchar DEFAULT NULL,
    p_category          varchar DEFAULT NULL,
    p_brand             varchar DEFAULT NULL,
    p_price             numeric DEFAULT 0,
    p_compare_at_price  numeric DEFAULT NULL,
    p_cost_price        numeric DEFAULT 0,
    p_stock_qty         numeric DEFAULT 0,
    p_short_description varchar DEFAULT NULL,
    p_long_description  text    DEFAULT NULL,
    p_meta_title        varchar DEFAULT NULL,
    p_meta_description  varchar DEFAULT NULL,
    p_slug              varchar DEFAULT NULL,
    p_barcode           varchar DEFAULT NULL,
    p_unit_code         varchar DEFAULT 'UND',
    p_tax_rate          numeric DEFAULT 0,
    p_weight_kg         numeric DEFAULT NULL,
    p_is_service        boolean DEFAULT false,
    p_is_published      boolean DEFAULT false,
    p_user_id           integer DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar, "Code" varchar)
LANGUAGE plpgsql AS $$
DECLARE
    v_now       timestamp := (NOW() AT TIME ZONE 'UTC');
    v_published timestamp;
    v_exists    boolean;
BEGIN
    IF p_code IS NULL OR TRIM(p_code) = '' THEN
        RETURN QUERY SELECT 0, 'El código del producto es requerido'::varchar, NULL::varchar;
        RETURN;
    END IF;
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RETURN QUERY SELECT 0, 'El nombre del producto es requerido'::varchar, NULL::varchar;
        RETURN;
    END IF;

    -- Validar slug único por compañía si viene
    IF p_slug IS NOT NULL AND TRIM(p_slug) <> '' THEN
        IF EXISTS (
            SELECT 1 FROM master."Product"
             WHERE "CompanyId" = p_company_id
               AND "Slug" = p_slug
               AND "ProductCode" <> p_code
               AND "IsDeleted" = false
        ) THEN
            RETURN QUERY SELECT 0, 'El slug ya está en uso por otro producto'::varchar, NULL::varchar;
            RETURN;
        END IF;
    END IF;

    SELECT true INTO v_exists FROM master."Product"
     WHERE "CompanyId" = p_company_id AND "ProductCode" = p_code
     LIMIT 1;

    v_published := CASE WHEN p_is_published THEN v_now ELSE NULL END;

    IF COALESCE(v_exists, false) THEN
        UPDATE master."Product" SET
            "ProductName"      = p_name,
            "CategoryCode"     = p_category,
            "BrandCode"        = p_brand,
            "SalesPrice"       = COALESCE(p_price, 0),
            "CompareAtPrice"   = p_compare_at_price,
            "CostPrice"        = COALESCE(p_cost_price, 0),
            "StockQty"         = COALESCE(p_stock_qty, 0),
            "ShortDescription" = p_short_description,
            "LongDescription"  = p_long_description,
            "MetaTitle"        = p_meta_title,
            "MetaDescription"  = p_meta_description,
            "Slug"             = NULLIF(TRIM(COALESCE(p_slug, '')), ''),
            "BarCode"          = p_barcode,
            "UnitCode"         = COALESCE(p_unit_code, 'UND'),
            "DefaultTaxRate"   = COALESCE(p_tax_rate, 0),
            "WeightKg"         = p_weight_kg,
            "IsService"        = COALESCE(p_is_service, false),
            "IsPublishedStore" = COALESCE(p_is_published, false),
            "PublishedAt"      = CASE
                                     WHEN p_is_published AND "PublishedAt" IS NULL THEN v_now
                                     WHEN NOT p_is_published THEN NULL
                                     ELSE "PublishedAt"
                                 END,
            "IsActive"         = true,
            "IsDeleted"        = false,
            "UpdatedAt"        = v_now,
            "UpdatedByUserId"  = p_user_id
         WHERE "CompanyId" = p_company_id
           AND "ProductCode" = p_code;

        RETURN QUERY SELECT 1, 'Producto actualizado'::varchar, p_code::varchar;
    ELSE
        INSERT INTO master."Product" (
            "CompanyId", "ProductCode", "ProductName", "CategoryCode", "BrandCode",
            "SalesPrice", "CompareAtPrice", "CostPrice", "StockQty",
            "ShortDescription", "LongDescription", "MetaTitle", "MetaDescription",
            "Slug", "BarCode", "UnitCode", "DefaultTaxRate", "WeightKg",
            "IsService", "IsPublishedStore", "PublishedAt", "IsActive", "IsDeleted",
            "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
        ) VALUES (
            p_company_id, p_code, p_name, p_category, p_brand,
            COALESCE(p_price, 0), p_compare_at_price, COALESCE(p_cost_price, 0), COALESCE(p_stock_qty, 0),
            p_short_description, p_long_description, p_meta_title, p_meta_description,
            NULLIF(TRIM(COALESCE(p_slug, '')), ''), p_barcode, COALESCE(p_unit_code, 'UND'),
            COALESCE(p_tax_rate, 0), p_weight_kg,
            COALESCE(p_is_service, false), COALESCE(p_is_published, false), v_published, true, false,
            v_now, v_now, p_user_id, p_user_id
        );

        RETURN QUERY SELECT 1, 'Producto creado'::varchar, p_code::varchar;
    END IF;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::varchar, NULL::varchar;
END;
$$;
-- +goose StatementEnd

-- ─── Delete (soft) de producto ─────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_delete(
    p_company_id integer DEFAULT 1,
    p_code       varchar DEFAULT NULL,
    p_user_id    integer DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar)
LANGUAGE plpgsql AS $$
DECLARE
    v_now timestamp := (NOW() AT TIME ZONE 'UTC');
BEGIN
    IF p_code IS NULL THEN
        RETURN QUERY SELECT 0, 'Código requerido'::varchar;
        RETURN;
    END IF;

    UPDATE master."Product" SET
        "IsDeleted"        = true,
        "DeletedAt"        = v_now,
        "DeletedByUserId"  = p_user_id,
        "IsActive"         = false,
        "IsPublishedStore" = false,
        "UpdatedAt"        = v_now,
        "UpdatedByUserId"  = p_user_id
     WHERE "CompanyId" = p_company_id
       AND "ProductCode" = p_code
       AND "IsDeleted" = false;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Producto no encontrado o ya eliminado'::varchar;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'Producto eliminado'::varchar;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::varchar;
END;
$$;
-- +goose StatementEnd

-- ─── Publish toggle ────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_publish_toggle(
    p_company_id integer DEFAULT 1,
    p_code       varchar DEFAULT NULL,
    p_publish    boolean DEFAULT NULL,
    p_user_id    integer DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar, "IsPublished" boolean)
LANGUAGE plpgsql AS $$
DECLARE
    v_now    timestamp := (NOW() AT TIME ZONE 'UTC');
    v_target boolean;
    v_final  boolean;
BEGIN
    IF p_code IS NULL THEN
        RETURN QUERY SELECT 0, 'Código requerido'::varchar, NULL::boolean;
        RETURN;
    END IF;

    IF p_publish IS NULL THEN
        SELECT NOT COALESCE("IsPublishedStore", false) INTO v_target
          FROM master."Product"
         WHERE "CompanyId" = p_company_id AND "ProductCode" = p_code
           AND "IsDeleted" = false
         LIMIT 1;
    ELSE
        v_target := p_publish;
    END IF;

    IF v_target IS NULL THEN
        RETURN QUERY SELECT 0, 'Producto no encontrado'::varchar, NULL::boolean;
        RETURN;
    END IF;

    UPDATE master."Product" SET
        "IsPublishedStore" = v_target,
        "PublishedAt"      = CASE
                                 WHEN v_target AND "PublishedAt" IS NULL THEN v_now
                                 WHEN NOT v_target THEN NULL
                                 ELSE "PublishedAt"
                             END,
        "UpdatedAt"        = v_now,
        "UpdatedByUserId"  = p_user_id
     WHERE "CompanyId" = p_company_id
       AND "ProductCode" = p_code
       AND "IsDeleted" = false
    RETURNING "IsPublishedStore" INTO v_final;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Producto no encontrado'::varchar, NULL::boolean;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, CASE WHEN v_final THEN 'Producto publicado'::varchar ELSE 'Producto despublicado'::varchar END, v_final;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::varchar, NULL::boolean;
END;
$$;
-- +goose StatementEnd

-- ─── Images set — reemplaza todas las imágenes del producto ───
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_images_set(
    p_company_id integer DEFAULT 1,
    p_branch_id  integer DEFAULT 1,
    p_code       varchar DEFAULT NULL,
    p_images_json jsonb  DEFAULT NULL,
    p_user_id    integer DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar, "Count" integer)
LANGUAGE plpgsql AS $$
DECLARE
    v_product_id bigint;
    v_inserted   integer := 0;
    v_rec        jsonb;
    v_media_id   bigint;
    v_now        timestamp := (NOW() AT TIME ZONE 'UTC');
BEGIN
    SELECT "ProductId" INTO v_product_id
      FROM master."Product"
     WHERE "CompanyId" = p_company_id AND "ProductCode" = p_code AND "IsDeleted" = false
     LIMIT 1;

    IF v_product_id IS NULL THEN
        RETURN QUERY SELECT 0, 'Producto no encontrado'::varchar, 0;
        RETURN;
    END IF;

    -- Soft-delete de imágenes previas del producto
    UPDATE cfg."EntityImage" SET
        "IsDeleted" = true,
        "IsActive"  = false,
        "UpdatedAt" = v_now
     WHERE "CompanyId"  = p_company_id
       AND "EntityType" = 'MASTER_PRODUCT'
       AND "EntityId"   = v_product_id
       AND "IsDeleted"  = false;

    IF p_images_json IS NULL OR jsonb_array_length(p_images_json) = 0 THEN
        RETURN QUERY SELECT 1, 'Imágenes removidas'::varchar, 0;
        RETURN;
    END IF;

    FOR v_rec IN SELECT * FROM jsonb_array_elements(p_images_json) LOOP
        -- Crea MediaAsset si aún no existe para esa URL
        SELECT ma."MediaAssetId" INTO v_media_id
          FROM cfg."MediaAsset" ma
         WHERE ma."CompanyId" = p_company_id
           AND ma."PublicUrl" = v_rec->>'url'
           AND ma."IsDeleted" = false
         LIMIT 1;

        IF v_media_id IS NULL THEN
            INSERT INTO cfg."MediaAsset" (
                "CompanyId", "BranchId", "StorageProvider", "StorageKey", "PublicUrl",
                "OriginalFileName", "MimeType", "AltText",
                "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt"
            ) VALUES (
                p_company_id, p_branch_id,
                COALESCE(v_rec->>'storageProvider', 'external'),
                COALESCE(v_rec->>'storageKey', v_rec->>'url'),
                v_rec->>'url',
                v_rec->>'originalFileName',
                v_rec->>'mimeType',
                v_rec->>'altText',
                true, false, v_now, v_now
            ) RETURNING "MediaAssetId" INTO v_media_id;
        END IF;

        INSERT INTO cfg."EntityImage" (
            "CompanyId", "BranchId", "EntityType", "EntityId", "MediaAssetId",
            "RoleCode", "SortOrder", "IsPrimary", "IsActive", "IsDeleted",
            "CreatedAt", "UpdatedAt"
        ) VALUES (
            p_company_id, p_branch_id, 'MASTER_PRODUCT', v_product_id, v_media_id,
            COALESCE(v_rec->>'role', 'PRODUCT_IMAGE'),
            COALESCE((v_rec->>'sortOrder')::int, v_inserted),
            COALESCE((v_rec->>'isPrimary')::boolean, v_inserted = 0),
            true, false, v_now, v_now
        );

        v_inserted := v_inserted + 1;
    END LOOP;

    RETURN QUERY SELECT 1, 'Imágenes actualizadas'::varchar, v_inserted;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::varchar, 0;
END;
$$;
-- +goose StatementEnd

-- ─── Highlights set — reemplaza todos los highlights ───
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_highlights_set(
    p_company_id integer DEFAULT 1,
    p_code       varchar DEFAULT NULL,
    p_highlights_json jsonb DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar, "Count" integer)
LANGUAGE plpgsql AS $$
DECLARE
    v_now     timestamp := (NOW() AT TIME ZONE 'UTC');
    v_count   integer := 0;
    v_rec     jsonb;
BEGIN
    IF p_code IS NULL THEN
        RETURN QUERY SELECT 0, 'Código requerido'::varchar, 0;
        RETURN;
    END IF;

    DELETE FROM store."ProductHighlight"
     WHERE "CompanyId" = p_company_id
       AND "ProductCode" = p_code;

    IF p_highlights_json IS NULL OR jsonb_array_length(p_highlights_json) = 0 THEN
        RETURN QUERY SELECT 1, 'Highlights removidos'::varchar, 0;
        RETURN;
    END IF;

    FOR v_rec IN SELECT * FROM jsonb_array_elements(p_highlights_json) LOOP
        INSERT INTO store."ProductHighlight" (
            "CompanyId", "ProductCode", "HighlightText", "SortOrder", "IsActive", "CreatedAt"
        ) VALUES (
            p_company_id, p_code,
            COALESCE(v_rec->>'text', ''),
            COALESCE((v_rec->>'sortOrder')::int, v_count),
            true, v_now
        );
        v_count := v_count + 1;
    END LOOP;

    RETURN QUERY SELECT 1, 'Highlights actualizados'::varchar, v_count;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::varchar, 0;
END;
$$;
-- +goose StatementEnd

-- ─── Specs set ─────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_specs_set(
    p_company_id integer DEFAULT 1,
    p_code       varchar DEFAULT NULL,
    p_specs_json jsonb DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar, "Count" integer)
LANGUAGE plpgsql AS $$
DECLARE
    v_now   timestamp := (NOW() AT TIME ZONE 'UTC');
    v_count integer := 0;
    v_rec   jsonb;
BEGIN
    IF p_code IS NULL THEN
        RETURN QUERY SELECT 0, 'Código requerido'::varchar, 0;
        RETURN;
    END IF;

    DELETE FROM store."ProductSpec"
     WHERE "CompanyId" = p_company_id
       AND "ProductCode" = p_code;

    IF p_specs_json IS NULL OR jsonb_array_length(p_specs_json) = 0 THEN
        RETURN QUERY SELECT 1, 'Specs removidas'::varchar, 0;
        RETURN;
    END IF;

    FOR v_rec IN SELECT * FROM jsonb_array_elements(p_specs_json) LOOP
        INSERT INTO store."ProductSpec" (
            "CompanyId", "ProductCode", "SpecGroup", "SpecKey", "SpecValue",
            "SortOrder", "IsActive", "CreatedAt"
        ) VALUES (
            p_company_id, p_code,
            COALESCE(v_rec->>'group', 'General'),
            COALESCE(v_rec->>'key', ''),
            COALESCE(v_rec->>'value', ''),
            COALESCE((v_rec->>'sortOrder')::int, v_count),
            true, v_now
        );
        v_count := v_count + 1;
    END LOOP;

    RETURN QUERY SELECT 1, 'Specs actualizadas'::varchar, v_count;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::varchar, 0;
END;
$$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════
-- FUNCIONES — CATEGORÍAS
-- ═══════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_category_upsert(
    p_company_id  integer DEFAULT 1,
    p_code        varchar DEFAULT NULL,
    p_name        varchar DEFAULT NULL,
    p_description varchar DEFAULT NULL,
    p_user_id     integer DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar, "Code" varchar)
LANGUAGE plpgsql AS $$
DECLARE
    v_now    timestamp := (NOW() AT TIME ZONE 'UTC');
    v_exists boolean;
    v_next_id integer;
BEGIN
    IF p_code IS NULL OR TRIM(p_code) = '' THEN
        RETURN QUERY SELECT 0, 'Código requerido'::varchar, NULL::varchar;
        RETURN;
    END IF;
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RETURN QUERY SELECT 0, 'Nombre requerido'::varchar, NULL::varchar;
        RETURN;
    END IF;

    SELECT true INTO v_exists FROM master."Category"
     WHERE "CompanyId" = p_company_id AND "CategoryCode" = p_code
     LIMIT 1;

    IF COALESCE(v_exists, false) THEN
        UPDATE master."Category" SET
            "CategoryName"     = p_name,
            "Description"      = p_description,
            "IsActive"         = true,
            "IsDeleted"        = false,
            "UpdatedAt"        = v_now,
            "UpdatedByUserId"  = p_user_id
         WHERE "CompanyId" = p_company_id AND "CategoryCode" = p_code;

        RETURN QUERY SELECT 1, 'Categoría actualizada'::varchar, p_code::varchar;
    ELSE
        SELECT COALESCE(MAX("CategoryId"), 0) + 1 INTO v_next_id FROM master."Category";
        INSERT INTO master."Category" (
            "CategoryId", "CompanyId", "CategoryCode", "CategoryName", "Description",
            "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
        ) VALUES (
            v_next_id, p_company_id, p_code, p_name, p_description,
            true, false, v_now, v_now, p_user_id, p_user_id
        );

        RETURN QUERY SELECT 1, 'Categoría creada'::varchar, p_code::varchar;
    END IF;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::varchar, NULL::varchar;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_category_delete(
    p_company_id integer DEFAULT 1,
    p_code       varchar DEFAULT NULL,
    p_user_id    integer DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar)
LANGUAGE plpgsql AS $$
DECLARE
    v_now timestamp := (NOW() AT TIME ZONE 'UTC');
    v_in_use integer;
BEGIN
    IF p_code IS NULL THEN
        RETURN QUERY SELECT 0, 'Código requerido'::varchar;
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_in_use FROM master."Product"
     WHERE "CompanyId" = p_company_id AND "CategoryCode" = p_code AND "IsDeleted" = false;
    IF v_in_use > 0 THEN
        RETURN QUERY SELECT 0, ('No se puede eliminar: ' || v_in_use || ' productos usan esta categoría')::varchar;
        RETURN;
    END IF;

    UPDATE master."Category" SET
        "IsDeleted"       = true,
        "IsActive"        = false,
        "UpdatedAt"       = v_now,
        "UpdatedByUserId" = p_user_id
     WHERE "CompanyId" = p_company_id AND "CategoryCode" = p_code;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Categoría no encontrada'::varchar;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'Categoría eliminada'::varchar;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::varchar;
END;
$$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════
-- FUNCIONES — MARCAS
-- ═══════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_brand_upsert(
    p_company_id  integer DEFAULT 1,
    p_code        varchar DEFAULT NULL,
    p_name        varchar DEFAULT NULL,
    p_description varchar DEFAULT NULL,
    p_user_id     integer DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar, "Code" varchar)
LANGUAGE plpgsql AS $$
DECLARE
    v_now    timestamp := (NOW() AT TIME ZONE 'UTC');
    v_exists boolean;
    v_next_id integer;
BEGIN
    IF p_code IS NULL OR TRIM(p_code) = '' THEN
        RETURN QUERY SELECT 0, 'Código requerido'::varchar, NULL::varchar;
        RETURN;
    END IF;
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RETURN QUERY SELECT 0, 'Nombre requerido'::varchar, NULL::varchar;
        RETURN;
    END IF;

    SELECT true INTO v_exists FROM master."Brand"
     WHERE "CompanyId" = p_company_id AND "BrandCode" = p_code
     LIMIT 1;

    IF COALESCE(v_exists, false) THEN
        UPDATE master."Brand" SET
            "BrandName"        = p_name,
            "Description"      = p_description,
            "IsActive"         = true,
            "IsDeleted"        = false,
            "UpdatedAt"        = v_now,
            "UpdatedByUserId"  = p_user_id
         WHERE "CompanyId" = p_company_id AND "BrandCode" = p_code;

        RETURN QUERY SELECT 1, 'Marca actualizada'::varchar, p_code::varchar;
    ELSE
        SELECT COALESCE(MAX("BrandId"), 0) + 1 INTO v_next_id FROM master."Brand";
        INSERT INTO master."Brand" (
            "BrandId", "CompanyId", "BrandCode", "BrandName", "Description",
            "IsActive", "IsDeleted", "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId"
        ) VALUES (
            v_next_id, p_company_id, p_code, p_name, p_description,
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
CREATE OR REPLACE FUNCTION public.usp_store_brand_delete(
    p_company_id integer DEFAULT 1,
    p_code       varchar DEFAULT NULL,
    p_user_id    integer DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar)
LANGUAGE plpgsql AS $$
DECLARE
    v_now    timestamp := (NOW() AT TIME ZONE 'UTC');
    v_in_use integer;
BEGIN
    IF p_code IS NULL THEN
        RETURN QUERY SELECT 0, 'Código requerido'::varchar;
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_in_use FROM master."Product"
     WHERE "CompanyId" = p_company_id AND "BrandCode" = p_code AND "IsDeleted" = false;
    IF v_in_use > 0 THEN
        RETURN QUERY SELECT 0, ('No se puede eliminar: ' || v_in_use || ' productos usan esta marca')::varchar;
        RETURN;
    END IF;

    UPDATE master."Brand" SET
        "IsDeleted"       = true,
        "IsActive"        = false,
        "UpdatedAt"       = v_now,
        "UpdatedByUserId" = p_user_id
     WHERE "CompanyId" = p_company_id AND "BrandCode" = p_code;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Marca no encontrada'::varchar;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'Marca eliminada'::varchar;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::varchar;
END;
$$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════
-- FUNCIONES — REVIEWS (moderación)
-- ═══════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_review_moderate(
    p_company_id integer DEFAULT 1,
    p_review_id  integer DEFAULT NULL,
    p_status     varchar DEFAULT NULL,   -- approved | rejected | pending
    p_moderator  varchar DEFAULT NULL
) RETURNS TABLE ("Resultado" integer, "Mensaje" varchar)
LANGUAGE plpgsql AS $$
DECLARE
    v_now timestamp := (NOW() AT TIME ZONE 'UTC');
BEGIN
    IF p_review_id IS NULL THEN
        RETURN QUERY SELECT 0, 'ReviewId requerido'::varchar;
        RETURN;
    END IF;
    IF p_status NOT IN ('approved', 'rejected', 'pending') THEN
        RETURN QUERY SELECT 0, 'Status inválido (approved | rejected | pending)'::varchar;
        RETURN;
    END IF;

    UPDATE store."ProductReview" SET
        "Status"        = p_status,
        "IsApproved"    = (p_status = 'approved'),
        "ModeratedAt"   = v_now,
        "ModeratorUser" = p_moderator
     WHERE "CompanyId" = p_company_id
       AND "ReviewId"  = p_review_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT 0, 'Review no encontrada'::varchar;
        RETURN;
    END IF;

    RETURN QUERY SELECT 1, 'Review moderada'::varchar;
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::varchar;
END;
$$;
-- +goose StatementEnd

-- ─── Review list (admin, con filtro por status) ────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_review_list(
    p_company_id integer DEFAULT 1,
    p_status     varchar DEFAULT NULL,   -- pending | approved | rejected | NULL=todas
    p_search     varchar DEFAULT NULL,
    p_page       integer DEFAULT 1,
    p_limit      integer DEFAULT 25
)
RETURNS TABLE (
    "TotalCount"     bigint,
    "reviewId"       integer,
    "productCode"    varchar,
    "productName"    varchar,
    "rating"         integer,
    "title"          varchar,
    "comment"        varchar,
    "reviewerName"   varchar,
    "reviewerEmail"  varchar,
    "status"         varchar,
    "isVerified"     boolean,
    "createdAt"      timestamp,
    "moderatedAt"    timestamp,
    "moderatorUser"  varchar
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset int := (GREATEST(p_page, 1) - 1) * p_limit;
    v_pattern varchar := CASE
        WHEN p_search IS NOT NULL AND TRIM(p_search) <> '' THEN '%' || TRIM(p_search) || '%'
        ELSE NULL END;
    v_total bigint;
BEGIN
    SELECT COUNT(*) INTO v_total
      FROM store."ProductReview" r
     WHERE r."CompanyId" = p_company_id
       AND r."IsDeleted" = false
       AND (p_status IS NULL OR r."Status" = p_status)
       AND (v_pattern IS NULL OR r."ProductCode" LIKE v_pattern
            OR r."Title" LIKE v_pattern OR r."ReviewerName" LIKE v_pattern
            OR r."Comment" LIKE v_pattern);

    RETURN QUERY
    SELECT v_total,
           r."ReviewId",
           r."ProductCode"::varchar,
           p."ProductName"::varchar,
           r."Rating",
           r."Title"::varchar,
           r."Comment"::varchar,
           r."ReviewerName"::varchar,
           r."ReviewerEmail"::varchar,
           r."Status"::varchar,
           r."IsVerified",
           r."CreatedAt",
           r."ModeratedAt",
           r."ModeratorUser"::varchar
      FROM store."ProductReview" r
      LEFT JOIN master."Product" p
             ON p."CompanyId" = r."CompanyId" AND p."ProductCode" = r."ProductCode"
     WHERE r."CompanyId" = p_company_id
       AND r."IsDeleted" = false
       AND (p_status IS NULL OR r."Status" = p_status)
       AND (v_pattern IS NULL OR r."ProductCode" LIKE v_pattern
            OR r."Title" LIKE v_pattern OR r."ReviewerName" LIKE v_pattern
            OR r."Comment" LIKE v_pattern)
     ORDER BY r."CreatedAt" DESC
     LIMIT p_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ═══════════════════════════════════════════════════════════════════════
-- ADMIN — Listado completo de productos (incluye no publicados + stock bajo)
-- ═══════════════════════════════════════════════════════════════════════

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_product_list_admin(
    p_company_id      integer DEFAULT 1,
    p_branch_id       integer DEFAULT 1,
    p_search          varchar DEFAULT NULL,
    p_category        varchar DEFAULT NULL,
    p_brand           varchar DEFAULT NULL,
    p_published       varchar DEFAULT NULL,     -- 'published' | 'draft' | NULL(todos)
    p_low_stock_only  boolean DEFAULT false,
    p_low_stock_limit numeric DEFAULT 5,
    p_page            integer DEFAULT 1,
    p_limit           integer DEFAULT 25
)
RETURNS TABLE (
    "TotalCount"       bigint,
    "id"               bigint,
    "code"             varchar,
    "name"             varchar,
    "category"         varchar,
    "categoryName"     varchar,
    "brandCode"        varchar,
    "brandName"        varchar,
    "price"            numeric,
    "compareAtPrice"   numeric,
    "costPrice"        numeric,
    "stock"            numeric,
    "isService"        boolean,
    "isPublished"      boolean,
    "publishedAt"      timestamp,
    "imageUrl"         varchar,
    "slug"             varchar,
    "createdAt"        timestamp,
    "updatedAt"        timestamp
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset  int := (GREATEST(p_page, 1) - 1) * p_limit;
    v_pattern varchar := CASE
        WHEN p_search IS NOT NULL AND TRIM(p_search) <> '' THEN '%' || TRIM(p_search) || '%'
        ELSE NULL END;
    v_total bigint;
BEGIN
    SELECT COUNT(*) INTO v_total
      FROM master."Product" p
     WHERE p."CompanyId" = p_company_id
       AND p."IsDeleted" = false
       AND (v_pattern IS NULL OR p."ProductCode" LIKE v_pattern OR p."ProductName" LIKE v_pattern)
       AND (p_category IS NULL OR p."CategoryCode" = p_category)
       AND (p_brand IS NULL OR p."BrandCode" = p_brand)
       AND (p_published IS NULL
            OR (p_published = 'published' AND p."IsPublishedStore" = true)
            OR (p_published = 'draft'     AND p."IsPublishedStore" = false))
       AND (NOT p_low_stock_only OR p."StockQty" <= p_low_stock_limit);

    RETURN QUERY
    SELECT v_total,
           p."ProductId"::bigint,
           p."ProductCode"::varchar,
           p."ProductName"::varchar,
           p."CategoryCode"::varchar,
           c."CategoryName"::varchar,
           p."BrandCode"::varchar,
           b."BrandName"::varchar,
           p."SalesPrice",
           p."CompareAtPrice",
           p."CostPrice",
           p."StockQty",
           p."IsService",
           COALESCE(p."IsPublishedStore", false),
           p."PublishedAt",
           img."PublicUrl"::varchar,
           p."Slug"::varchar,
           p."CreatedAt",
           p."UpdatedAt"
      FROM master."Product" p
      LEFT JOIN master."Category" c
             ON c."CategoryCode" = p."CategoryCode" AND c."CompanyId" = p."CompanyId" AND c."IsDeleted" = false
      LEFT JOIN master."Brand" b
             ON b."BrandCode" = p."BrandCode" AND b."CompanyId" = p."CompanyId" AND b."IsDeleted" = false
      LEFT JOIN LATERAL (
          SELECT ma."PublicUrl"
            FROM cfg."EntityImage" ei
            INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
           WHERE ei."CompanyId"   = p."CompanyId"
             AND ei."BranchId"    = p_branch_id
             AND ei."EntityType"  = 'MASTER_PRODUCT'
             AND ei."EntityId"    = p."ProductId"
             AND ei."IsDeleted"   = false
             AND ei."IsActive"    = true
             AND ma."IsDeleted"   = false
           ORDER BY CASE WHEN ei."IsPrimary" THEN 0 ELSE 1 END, ei."SortOrder"
           LIMIT 1
      ) img ON true
     WHERE p."CompanyId" = p_company_id
       AND p."IsDeleted" = false
       AND (v_pattern IS NULL OR p."ProductCode" LIKE v_pattern OR p."ProductName" LIKE v_pattern)
       AND (p_category IS NULL OR p."CategoryCode" = p_category)
       AND (p_brand IS NULL OR p."BrandCode" = p_brand)
       AND (p_published IS NULL
            OR (p_published = 'published' AND p."IsPublishedStore" = true)
            OR (p_published = 'draft'     AND p."IsPublishedStore" = false))
       AND (NOT p_low_stock_only OR p."StockQty" <= p_low_stock_limit)
     ORDER BY p."UpdatedAt" DESC NULLS LAST, p."ProductId" DESC
     LIMIT p_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd


-- +goose Down
DROP FUNCTION IF EXISTS public.usp_store_product_list_admin(integer, integer, varchar, varchar, varchar, varchar, boolean, numeric, integer, integer);
DROP FUNCTION IF EXISTS public.usp_store_review_list(integer, varchar, varchar, integer, integer);
DROP FUNCTION IF EXISTS public.usp_store_review_moderate(integer, integer, varchar, varchar);
DROP FUNCTION IF EXISTS public.usp_store_brand_delete(integer, varchar, integer);
DROP FUNCTION IF EXISTS public.usp_store_brand_upsert(integer, varchar, varchar, varchar, integer);
DROP FUNCTION IF EXISTS public.usp_store_category_delete(integer, varchar, integer);
DROP FUNCTION IF EXISTS public.usp_store_category_upsert(integer, varchar, varchar, varchar, integer);
DROP FUNCTION IF EXISTS public.usp_store_product_specs_set(integer, varchar, jsonb);
DROP FUNCTION IF EXISTS public.usp_store_product_highlights_set(integer, varchar, jsonb);
DROP FUNCTION IF EXISTS public.usp_store_product_images_set(integer, integer, varchar, jsonb, integer);
DROP FUNCTION IF EXISTS public.usp_store_product_publish_toggle(integer, varchar, boolean, integer);
DROP FUNCTION IF EXISTS public.usp_store_product_delete(integer, varchar, integer);
DROP FUNCTION IF EXISTS public.usp_store_product_upsert(integer, varchar, varchar, varchar, varchar, numeric, numeric, numeric, numeric, varchar, text, varchar, varchar, varchar, varchar, varchar, numeric, numeric, boolean, boolean, integer);

DROP INDEX IF EXISTS store."IX_store_ProductReview_Status";
ALTER TABLE store."ProductReview" DROP CONSTRAINT IF EXISTS "ProductReview_Status_check";
ALTER TABLE store."ProductReview" DROP COLUMN IF EXISTS "ModeratorUser";
ALTER TABLE store."ProductReview" DROP COLUMN IF EXISTS "ModeratedAt";
ALTER TABLE store."ProductReview" DROP COLUMN IF EXISTS "Status";

DROP INDEX IF EXISTS master."IX_master_Product_PublishedStore";
DROP INDEX IF EXISTS master."IX_master_Product_Slug_Company";
ALTER TABLE master."Product" DROP COLUMN IF EXISTS "PublishedAt";
ALTER TABLE master."Product" DROP COLUMN IF EXISTS "IsPublishedStore";
ALTER TABLE master."Product" DROP COLUMN IF EXISTS "MetaDescription";
ALTER TABLE master."Product" DROP COLUMN IF EXISTS "MetaTitle";
