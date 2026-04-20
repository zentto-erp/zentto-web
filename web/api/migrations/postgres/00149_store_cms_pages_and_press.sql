-- +goose Up
-- CMS pages + Press releases para ecommerce (reemplazo de mocks).
--
-- Tablas:
--   store.CmsPage          — páginas de contenido editorial (acerca, contacto, etc.)
--   store.PressRelease     — comunicados de prensa (blog de prensa)
--   store.ContactMessage   — mensajes del formulario público de contacto
--
-- Funciones:
--   usp_Store_CmsPage_List               → lista admin con filtro status + paginado
--   usp_Store_CmsPage_GetBySlug          → público (solo published)
--   usp_Store_CmsPage_GetByIdAdmin       → admin (cualquier status)
--   usp_Store_CmsPage_Upsert             → upsert por slug
--   usp_Store_CmsPage_Delete
--   usp_Store_CmsPage_Publish            → status=published + published_at=NOW
--   usp_Store_PressRelease_List          → admin/público
--   usp_Store_PressRelease_GetBySlug     → público (solo published)
--   usp_Store_PressRelease_GetByIdAdmin
--   usp_Store_PressRelease_Upsert
--   usp_Store_PressRelease_Delete
--   usp_Store_PressRelease_Publish
--   usp_Store_ContactMessage_Create      → público guarda form
--   usp_Store_ContactMessage_List        → admin
--
-- Status: draft | published | archived

-- ─── Tablas ────────────────────────────────────────────
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."CmsPage" (
  "CmsPageId"    bigserial PRIMARY KEY,
  "CompanyId"    integer NOT NULL DEFAULT 1,
  "Slug"         varchar(120) NOT NULL,
  "Title"        varchar(200) NOT NULL,
  "Subtitle"     varchar(300),
  "TemplateKey"  varchar(80),
  "Config"       jsonb NOT NULL DEFAULT '{"sections":[]}'::jsonb,
  "Seo"          jsonb NOT NULL DEFAULT '{}'::jsonb,
  "Status"       varchar(20) NOT NULL DEFAULT 'draft',
  "PublishedAt"  timestamp,
  "CreatedAt"    timestamp NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"    timestamp NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UK_store_CmsPage_CompanySlug" UNIQUE ("CompanyId", "Slug"),
  CONSTRAINT "CK_store_CmsPage_Status"
    CHECK ("Status" IN ('draft','published','archived'))
);
CREATE INDEX IF NOT EXISTS "IX_store_CmsPage_CompanyStatus"
  ON store."CmsPage" ("CompanyId", "Status", "Slug");
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."PressRelease" (
  "PressReleaseId" bigserial PRIMARY KEY,
  "CompanyId"      integer NOT NULL DEFAULT 1,
  "Slug"           varchar(160) NOT NULL,
  "Title"          varchar(240) NOT NULL,
  "Excerpt"        varchar(600),
  "Body"           text,
  "CoverImageUrl"  varchar(500),
  "Tags"           text[] DEFAULT ARRAY[]::text[],
  "Status"         varchar(20) NOT NULL DEFAULT 'draft',
  "PublishedAt"    timestamp,
  "CreatedAt"      timestamp NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"      timestamp NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UK_store_PressRelease_CompanySlug" UNIQUE ("CompanyId", "Slug"),
  CONSTRAINT "CK_store_PressRelease_Status"
    CHECK ("Status" IN ('draft','published','archived'))
);
CREATE INDEX IF NOT EXISTS "IX_store_PressRelease_Status"
  ON store."PressRelease" ("CompanyId", "Status", "PublishedAt" DESC);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS store."ContactMessage" (
  "ContactMessageId" bigserial PRIMARY KEY,
  "CompanyId"        integer NOT NULL DEFAULT 1,
  "Name"             varchar(160) NOT NULL,
  "Email"            varchar(240) NOT NULL,
  "Phone"            varchar(40),
  "Subject"          varchar(240),
  "Message"          text NOT NULL,
  "Source"           varchar(60) DEFAULT 'contact',
  "Status"           varchar(20) NOT NULL DEFAULT 'new',
  "CreatedAt"        timestamp NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "CK_store_ContactMessage_Status"
    CHECK ("Status" IN ('new','read','replied','archived'))
);
CREATE INDEX IF NOT EXISTS "IX_store_ContactMessage_CompanyStatus"
  ON store."ContactMessage" ("CompanyId", "Status", "CreatedAt" DESC);
-- +goose StatementEnd

-- ─── CmsPage: List ─────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_cmspage_list(
  p_company_id integer DEFAULT 1,
  p_status     varchar DEFAULT NULL,
  p_page       integer DEFAULT 1,
  p_limit      integer DEFAULT 50
)
RETURNS TABLE (
  "CmsPageId"   bigint,
  "Slug"        varchar,
  "Title"       varchar,
  "Subtitle"    varchar,
  "TemplateKey" varchar,
  "Status"      varchar,
  "PublishedAt" timestamp,
  "UpdatedAt"   timestamp,
  "CreatedAt"   timestamp,
  "TotalCount"  bigint
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_offset integer := (GREATEST(p_page,1) - 1) * GREATEST(p_limit,1);
  v_total  bigint;
BEGIN
  SELECT COUNT(*)::bigint INTO v_total
    FROM store."CmsPage"
   WHERE "CompanyId" = p_company_id
     AND (p_status IS NULL OR "Status" = p_status);

  RETURN QUERY
  SELECT
    p."CmsPageId", p."Slug", p."Title", p."Subtitle", p."TemplateKey",
    p."Status", p."PublishedAt", p."UpdatedAt", p."CreatedAt",
    v_total AS "TotalCount"
    FROM store."CmsPage" p
   WHERE p."CompanyId" = p_company_id
     AND (p_status IS NULL OR p."Status" = p_status)
   ORDER BY p."UpdatedAt" DESC
   OFFSET v_offset LIMIT GREATEST(p_limit,1);
END;
$$;
-- +goose StatementEnd

-- ─── CmsPage: GetBySlug (público) ──────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_cmspage_getbyslug(
  p_company_id integer DEFAULT 1,
  p_slug       varchar DEFAULT NULL
)
RETURNS TABLE (
  "CmsPageId"   bigint,
  "Slug"        varchar,
  "Title"       varchar,
  "Subtitle"    varchar,
  "TemplateKey" varchar,
  "Config"      jsonb,
  "Seo"         jsonb,
  "Status"      varchar,
  "PublishedAt" timestamp,
  "UpdatedAt"   timestamp
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT p."CmsPageId", p."Slug", p."Title", p."Subtitle", p."TemplateKey",
         p."Config", p."Seo", p."Status", p."PublishedAt", p."UpdatedAt"
    FROM store."CmsPage" p
   WHERE p."CompanyId" = p_company_id
     AND p."Slug" = p_slug
     AND p."Status" = 'published';
END;
$$;
-- +goose StatementEnd

-- ─── CmsPage: GetByIdAdmin ─────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_cmspage_getbyidadmin(
  p_company_id  integer DEFAULT 1,
  p_cms_page_id bigint DEFAULT NULL
)
RETURNS TABLE (
  "CmsPageId"   bigint,
  "Slug"        varchar,
  "Title"       varchar,
  "Subtitle"    varchar,
  "TemplateKey" varchar,
  "Config"      jsonb,
  "Seo"         jsonb,
  "Status"      varchar,
  "PublishedAt" timestamp,
  "UpdatedAt"   timestamp,
  "CreatedAt"   timestamp
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT p."CmsPageId", p."Slug", p."Title", p."Subtitle", p."TemplateKey",
         p."Config", p."Seo", p."Status", p."PublishedAt", p."UpdatedAt", p."CreatedAt"
    FROM store."CmsPage" p
   WHERE p."CompanyId" = p_company_id
     AND p."CmsPageId" = p_cms_page_id;
END;
$$;
-- +goose StatementEnd

-- ─── CmsPage: Upsert ───────────────────────────────────
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
    -- intentar upsert por slug
    SELECT "CmsPageId" INTO v_id
      FROM store."CmsPage"
     WHERE "CompanyId" = p_company_id AND "Slug" = p_slug;
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
    ) RETURNING "CmsPageId" INTO v_id;
    RETURN QUERY SELECT 1, 'creado'::varchar, v_id;
  ELSE
    UPDATE store."CmsPage" SET
      "Slug"        = p_slug,
      "Title"       = p_title,
      "Subtitle"    = p_subtitle,
      "TemplateKey" = p_template_key,
      "Config"      = COALESCE(p_config, "Config"),
      "Seo"         = COALESCE(p_seo, "Seo"),
      "Status"      = p_status,
      "PublishedAt" = CASE
                        WHEN p_status = 'published' AND "PublishedAt" IS NULL THEN v_now
                        WHEN p_status <> 'published' THEN NULL
                        ELSE "PublishedAt"
                      END,
      "UpdatedAt"   = v_now
     WHERE "CompanyId" = p_company_id AND "CmsPageId" = v_id;
    RETURN QUERY SELECT 1, 'actualizado'::varchar, v_id;
  END IF;
END;
$$;
-- +goose StatementEnd

-- ─── CmsPage: Delete ───────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_cmspage_delete(
  p_company_id  integer DEFAULT 1,
  p_cms_page_id bigint  DEFAULT NULL
)
RETURNS TABLE (
  "Resultado" integer,
  "Mensaje"   varchar
)
LANGUAGE plpgsql AS $$
DECLARE
  v_deleted integer;
BEGIN
  DELETE FROM store."CmsPage"
   WHERE "CompanyId" = p_company_id AND "CmsPageId" = p_cms_page_id;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  IF v_deleted = 0 THEN
    RETURN QUERY SELECT 0, 'no encontrado'::varchar;
  ELSE
    RETURN QUERY SELECT 1, 'eliminado'::varchar;
  END IF;
END;
$$;
-- +goose StatementEnd

-- ─── CmsPage: Publish ──────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_cmspage_publish(
  p_company_id  integer DEFAULT 1,
  p_cms_page_id bigint  DEFAULT NULL
)
RETURNS TABLE (
  "Resultado" integer,
  "Mensaje"   varchar
)
LANGUAGE plpgsql AS $$
DECLARE
  v_updated integer;
  v_now     timestamp := NOW() AT TIME ZONE 'UTC';
BEGIN
  UPDATE store."CmsPage"
     SET "Status"      = 'published',
         "PublishedAt" = COALESCE("PublishedAt", v_now),
         "UpdatedAt"   = v_now
   WHERE "CompanyId" = p_company_id AND "CmsPageId" = p_cms_page_id;
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    RETURN QUERY SELECT 0, 'no encontrado'::varchar;
  ELSE
    RETURN QUERY SELECT 1, 'publicado'::varchar;
  END IF;
END;
$$;
-- +goose StatementEnd

-- ─── PressRelease: List ────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_pressrelease_list(
  p_company_id integer DEFAULT 1,
  p_status     varchar DEFAULT NULL,
  p_page       integer DEFAULT 1,
  p_limit      integer DEFAULT 20
)
RETURNS TABLE (
  "PressReleaseId" bigint,
  "Slug"           varchar,
  "Title"          varchar,
  "Excerpt"        varchar,
  "CoverImageUrl"  varchar,
  "Tags"           text[],
  "Status"         varchar,
  "PublishedAt"    timestamp,
  "UpdatedAt"      timestamp,
  "CreatedAt"      timestamp,
  "TotalCount"     bigint
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_offset integer := (GREATEST(p_page,1) - 1) * GREATEST(p_limit,1);
  v_total  bigint;
BEGIN
  SELECT COUNT(*)::bigint INTO v_total
    FROM store."PressRelease"
   WHERE "CompanyId" = p_company_id
     AND (p_status IS NULL OR "Status" = p_status);

  RETURN QUERY
  SELECT
    r."PressReleaseId", r."Slug", r."Title", r."Excerpt", r."CoverImageUrl",
    r."Tags", r."Status", r."PublishedAt", r."UpdatedAt", r."CreatedAt",
    v_total AS "TotalCount"
    FROM store."PressRelease" r
   WHERE r."CompanyId" = p_company_id
     AND (p_status IS NULL OR r."Status" = p_status)
   ORDER BY COALESCE(r."PublishedAt", r."CreatedAt") DESC
   OFFSET v_offset LIMIT GREATEST(p_limit,1);
END;
$$;
-- +goose StatementEnd

-- ─── PressRelease: GetBySlug (público) ─────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_pressrelease_getbyslug(
  p_company_id integer DEFAULT 1,
  p_slug       varchar DEFAULT NULL
)
RETURNS TABLE (
  "PressReleaseId" bigint,
  "Slug"           varchar,
  "Title"          varchar,
  "Excerpt"        varchar,
  "Body"           text,
  "CoverImageUrl"  varchar,
  "Tags"           text[],
  "Status"         varchar,
  "PublishedAt"    timestamp,
  "UpdatedAt"      timestamp
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT r."PressReleaseId", r."Slug", r."Title", r."Excerpt", r."Body",
         r."CoverImageUrl", r."Tags", r."Status", r."PublishedAt", r."UpdatedAt"
    FROM store."PressRelease" r
   WHERE r."CompanyId" = p_company_id
     AND r."Slug" = p_slug
     AND r."Status" = 'published';
END;
$$;
-- +goose StatementEnd

-- ─── PressRelease: GetByIdAdmin ────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_pressrelease_getbyidadmin(
  p_company_id       integer DEFAULT 1,
  p_press_release_id bigint  DEFAULT NULL
)
RETURNS TABLE (
  "PressReleaseId" bigint,
  "Slug"           varchar,
  "Title"          varchar,
  "Excerpt"        varchar,
  "Body"           text,
  "CoverImageUrl"  varchar,
  "Tags"           text[],
  "Status"         varchar,
  "PublishedAt"    timestamp,
  "UpdatedAt"      timestamp,
  "CreatedAt"      timestamp
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT r."PressReleaseId", r."Slug", r."Title", r."Excerpt", r."Body",
         r."CoverImageUrl", r."Tags", r."Status", r."PublishedAt", r."UpdatedAt", r."CreatedAt"
    FROM store."PressRelease" r
   WHERE r."CompanyId" = p_company_id
     AND r."PressReleaseId" = p_press_release_id;
END;
$$;
-- +goose StatementEnd

-- ─── PressRelease: Upsert ──────────────────────────────
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
    SELECT "PressReleaseId" INTO v_id
      FROM store."PressRelease"
     WHERE "CompanyId" = p_company_id AND "Slug" = p_slug;
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
    ) RETURNING "PressReleaseId" INTO v_id;
    RETURN QUERY SELECT 1, 'creado'::varchar, v_id;
  ELSE
    UPDATE store."PressRelease" SET
      "Slug"          = p_slug,
      "Title"         = p_title,
      "Excerpt"       = p_excerpt,
      "Body"          = p_body,
      "CoverImageUrl" = p_cover_image_url,
      "Tags"          = COALESCE(p_tags, "Tags"),
      "Status"        = p_status,
      "PublishedAt"   = CASE
                          WHEN p_status = 'published' AND "PublishedAt" IS NULL THEN v_now
                          WHEN p_status <> 'published' THEN NULL
                          ELSE "PublishedAt"
                        END,
      "UpdatedAt"     = v_now
     WHERE "CompanyId" = p_company_id AND "PressReleaseId" = v_id;
    RETURN QUERY SELECT 1, 'actualizado'::varchar, v_id;
  END IF;
END;
$$;
-- +goose StatementEnd

-- ─── PressRelease: Delete ──────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_pressrelease_delete(
  p_company_id       integer DEFAULT 1,
  p_press_release_id bigint  DEFAULT NULL
)
RETURNS TABLE (
  "Resultado" integer,
  "Mensaje"   varchar
)
LANGUAGE plpgsql AS $$
DECLARE
  v_deleted integer;
BEGIN
  DELETE FROM store."PressRelease"
   WHERE "CompanyId" = p_company_id AND "PressReleaseId" = p_press_release_id;
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  IF v_deleted = 0 THEN
    RETURN QUERY SELECT 0, 'no encontrado'::varchar;
  ELSE
    RETURN QUERY SELECT 1, 'eliminado'::varchar;
  END IF;
END;
$$;
-- +goose StatementEnd

-- ─── PressRelease: Publish ─────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_pressrelease_publish(
  p_company_id       integer DEFAULT 1,
  p_press_release_id bigint  DEFAULT NULL
)
RETURNS TABLE (
  "Resultado" integer,
  "Mensaje"   varchar
)
LANGUAGE plpgsql AS $$
DECLARE
  v_updated integer;
  v_now     timestamp := NOW() AT TIME ZONE 'UTC';
BEGIN
  UPDATE store."PressRelease"
     SET "Status"      = 'published',
         "PublishedAt" = COALESCE("PublishedAt", v_now),
         "UpdatedAt"   = v_now
   WHERE "CompanyId" = p_company_id AND "PressReleaseId" = p_press_release_id;
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    RETURN QUERY SELECT 0, 'no encontrado'::varchar;
  ELSE
    RETURN QUERY SELECT 1, 'publicado'::varchar;
  END IF;
END;
$$;
-- +goose StatementEnd

-- ─── ContactMessage: Create ────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_store_contactmessage_create(
  p_company_id integer DEFAULT 1,
  p_name       varchar DEFAULT NULL,
  p_email      varchar DEFAULT NULL,
  p_phone      varchar DEFAULT NULL,
  p_subject    varchar DEFAULT NULL,
  p_message    text    DEFAULT NULL,
  p_source     varchar DEFAULT 'contact'
)
RETURNS TABLE (
  "Resultado"        integer,
  "Mensaje"          varchar,
  "ContactMessageId" bigint
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id bigint;
BEGIN
  IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
    RETURN QUERY SELECT 0, 'name requerido'::varchar, NULL::bigint; RETURN;
  END IF;
  IF p_email IS NULL OR LENGTH(TRIM(p_email)) = 0 THEN
    RETURN QUERY SELECT 0, 'email requerido'::varchar, NULL::bigint; RETURN;
  END IF;
  IF p_message IS NULL OR LENGTH(TRIM(p_message)) = 0 THEN
    RETURN QUERY SELECT 0, 'message requerido'::varchar, NULL::bigint; RETURN;
  END IF;

  INSERT INTO store."ContactMessage"(
    "CompanyId","Name","Email","Phone","Subject","Message","Source"
  ) VALUES (
    p_company_id, p_name, p_email, p_phone, p_subject, p_message,
    COALESCE(p_source,'contact')
  ) RETURNING "ContactMessageId" INTO v_id;

  RETURN QUERY SELECT 1, 'creado'::varchar, v_id;
END;
$$;
-- +goose StatementEnd

-- ─── ContactMessage: List ──────────────────────────────
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
    FROM store."ContactMessage"
   WHERE "CompanyId" = p_company_id
     AND (p_status IS NULL OR "Status" = p_status);

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

-- ─── Seeds iniciales (contenido real) ──────────────────
-- +goose StatementBegin
INSERT INTO store."CmsPage" ("CompanyId","Slug","Title","Subtitle","TemplateKey","Config","Seo","Status","PublishedAt")
VALUES
  (1, 'acerca', 'Acerca de Zentto',
   'La plataforma ERP todo-en-uno para PYMEs de Latinoamérica',
   'content',
   '{"sections":[
      {"type":"hero","title":"Construido en Latinoamérica, para Latinoamérica","subtitle":"Zentto nace de dos décadas de experiencia acompañando a PYMEs latinoamericanas. Lo que empezó como un ERP local para VB6 es hoy una plataforma cloud-first con 20+ módulos integrados.","ctaLabel":"Explorar productos","ctaHref":"/productos"},
      {"type":"stats","items":[
        {"value":"1,000+","label":"Empresas activas"},
        {"value":"14","label":"Países"},
        {"value":"20+","label":"Módulos integrados"},
        {"value":"20+","label":"Años de experiencia"}
      ]},
      {"type":"content","markdown":"## Nuestra misión\n\nDemocratizar el acceso a software empresarial de calidad para las pequeñas y medianas empresas del mundo hispanohablante. Creemos que una PYME en Caracas, CDMX o Madrid merece las mismas herramientas que una multinacional — sin el precio ni la complejidad.\n\n## Qué hacemos\n\nZentto es una suite ERP completa: contabilidad, inventario, CRM, punto de venta, ecommerce, facturación electrónica, nómina, logística, manufactura y más — todo integrado en una sola plataforma. Compatible con SQL Server y PostgreSQL, desplegable en cloud o on-premise.\n\n## Por qué nos eligen\n\n- **Soporte bilingüe en español** con equipo que entiende la realidad regulatoria de tu país.\n- **Facturación electrónica certificada** en Venezuela, México, Colombia, España y más.\n- **Sin costos ocultos** — un único precio mensual por empresa, sin límites de usuarios."},
      {"type":"timeline","title":"Nuestra historia","events":[
        {"year":"2003","title":"Nace DatqBox ERP (VB6)","description":"Primer ERP local desarrollado en Venezuela para PYMEs con contabilidad, inventario y facturación."},
        {"year":"2014","title":"Expansión a 5 países","description":"Presencia en México, Colombia, Perú y Ecuador con partners locales."},
        {"year":"2023","title":"Migración a la nube","description":"Comienza el rediseño completo como plataforma cloud-first multi-tenant."},
        {"year":"2024","title":"Nace Zentto","description":"Relanzamiento oficial bajo nueva marca con arquitectura moderna, multi-motor SQL Server + PostgreSQL y 20+ módulos integrados."},
        {"year":"2026","title":"1,000+ empresas, 14 países","description":"Hito de mil empresas activas. Lanzamiento de Zentto Store, Zentto POS y Fiscal Agent."}
      ]},
      {"type":"cta","title":"¿Listo para modernizar tu PYME?","subtitle":"Hablemos de cómo Zentto puede ayudarte.","ctaLabel":"Contáctanos","ctaHref":"/contacto"}
    ]}',
   '{"title":"Acerca de Zentto — ERP latinoamericano para PYMEs","description":"Conoce la historia, misión y equipo detrás de Zentto, el ERP integrado que ya usan más de 1,000 empresas en 14 países."}',
   'published', NOW() AT TIME ZONE 'UTC'),

  (1, 'trabaja-con-nosotros', 'Trabaja con nosotros',
   'Construye el futuro del software empresarial latinoamericano',
   'content',
   '{"sections":[
      {"type":"hero","title":"Únete a Zentto","subtitle":"Buscamos personas que quieran impactar a miles de PYMEs en toda Latinoamérica.","ctaLabel":"Enviar mi CV","ctaHref":"mailto:talento@zentto.net"},
      {"type":"content","markdown":"## Por qué Zentto\n\n- **Remoto primero**: trabajamos distribuidos desde Venezuela, México, Colombia, España y Argentina.\n- **Impacto real**: tu código corre todos los días en 1,000+ empresas.\n- **Stack moderno**: TypeScript, Next.js, PostgreSQL, Docker, GitHub Actions.\n- **Equipo senior**: aprendes de gente con 15+ años en ERPs y fiscalización LatAm."},
      {"type":"jobs","title":"Posiciones abiertas","jobs":[
        {"title":"Senior Full-stack Developer (Node + React)","location":"Remoto LatAm/ES","type":"Full-time","href":"mailto:talento@zentto.net?subject=Fullstack%20Senior"},
        {"title":"SRE / DevOps Engineer","location":"Remoto LatAm/ES","type":"Full-time","href":"mailto:talento@zentto.net?subject=SRE%20DevOps"},
        {"title":"Especialista Facturación Electrónica (SAT / DIAN / SII)","location":"Remoto LatAm","type":"Full-time","href":"mailto:talento@zentto.net?subject=Fiscal%20Especialista"},
        {"title":"Customer Success Manager (español nativo)","location":"Remoto LatAm","type":"Full-time","href":"mailto:talento@zentto.net?subject=CSM"}
      ],"emptyLabel":"No ves tu rol aquí pero crees que encajas — escríbenos a talento@zentto.net."},
      {"type":"contact","title":"Postúlate ahora","email":"talento@zentto.net"}
    ]}',
   '{"title":"Trabaja en Zentto — ERP remoto LatAm","description":"Posiciones abiertas: fullstack, DevOps, facturación electrónica. 100% remoto."}',
   'published', NOW() AT TIME ZONE 'UTC'),

  (1, 'contacto', 'Contáctanos',
   'Respondemos en menos de 24 horas hábiles',
   'contact',
   '{"sections":[
      {"type":"hero","title":"¿Hablamos?","subtitle":"Ventas, soporte, partnerships — estamos a un mensaje de distancia."},
      {"type":"contact","title":"Envíanos un mensaje","email":"contacto@zentto.net","showForm":true},
      {"type":"features","items":[
        {"title":"Ventas","description":"ventas@zentto.net","icon":"store"},
        {"title":"Soporte técnico","description":"soporte@zentto.net","icon":"support"},
        {"title":"Prensa y medios","description":"prensa@zentto.net","icon":"press"},
        {"title":"Partners","description":"partners@zentto.net","icon":"partners"}
      ]}
    ]}',
   '{"title":"Contacto Zentto","description":"Contáctanos por ventas, soporte o partnerships. Respondemos en menos de 24h hábiles."}',
   'published', NOW() AT TIME ZONE 'UTC'),

  (1, 'devoluciones', 'Política de devoluciones',
   'Cómo funciona el proceso de devolución en Zentto Store',
   'content',
   '{"sections":[
      {"type":"hero","title":"Política de devoluciones","subtitle":"Plazo de 30 días, condiciones y cómo iniciar tu devolución."},
      {"type":"content","markdown":"## Plazo de devolución\n\nDispones de **30 días naturales** desde la entrega del producto para solicitar una devolución, siempre que el artículo esté en estado original, sin uso y con su embalaje completo.\n\n## Productos no elegibles\n\n- Productos digitales o licencias de software ya activadas.\n- Productos personalizados o fabricados a medida.\n- Productos perecederos o consumibles abiertos."},
      {"type":"return-steps","title":"Cómo iniciar una devolución","steps":[
        {"step":1,"title":"Accede a Mis pedidos","description":"Desde tu cuenta, abre Mis pedidos y localiza el pedido a devolver."},
        {"step":2,"title":"Pulsa Solicitar devolución","description":"Selecciona los productos, indica el motivo y adjunta fotos si aplica."},
        {"step":3,"title":"Recibe la etiqueta prepagada","description":"Te llegará por email la etiqueta de envío + instrucciones del courier."},
        {"step":4,"title":"Empaca y entrega al courier","description":"Usa el embalaje original cuando sea posible y entrega al courier asignado."},
        {"step":5,"title":"Reembolso en 3-5 días hábiles","description":"Tras recibir el producto en almacén, procesamos el reembolso al método de pago original."}
      ]},
      {"type":"faq","items":[
        {"question":"¿Quién paga el envío de devolución?","answer":"Zentto asume el costo cuando la devolución es por defecto de fábrica o error de envío. En otros casos el cliente cubre el envío."},
        {"question":"¿Puedo cambiar por otro producto en vez de reembolso?","answer":"Sí. Al solicitar la devolución puedes elegir entre reembolso o crédito en Zentto Store por el mismo valor."},
        {"question":"¿Qué pasa si el producto llega dañado?","answer":"Contacta a soporte en las primeras 48h con fotos del daño y del embalaje. Haremos la reposición sin costo."}
      ]}
    ]}',
   '{"title":"Política de devoluciones — Zentto Store","description":"30 días para devolver. Plazo, condiciones y cómo iniciar una devolución en Zentto Store."}',
   'published', NOW() AT TIME ZONE 'UTC'),

  (1, 'centro-de-ayuda', 'Centro de ayuda',
   'Respuestas a las preguntas más frecuentes',
   'content',
   '{"sections":[
      {"type":"hero","title":"Centro de ayuda","subtitle":"Busca por tema o consulta las preguntas más frecuentes."},
      {"type":"faq","items":[
        {"question":"¿Cómo creo mi cuenta?","answer":"Pulsa el botón Registrarme en la esquina superior derecha, completa tus datos y verifica tu email con el enlace que recibirás."},
        {"question":"¿Qué métodos de pago aceptan?","answer":"Tarjetas de crédito y débito (Visa, Mastercard, Amex), PayPal, transferencia bancaria, Paddle y Pago Móvil (Venezuela)."},
        {"question":"¿Cuánto tarda el envío?","answer":"Depende del país: 24-48h en capitales de LatAm y España, 3-5 días hábiles en regiones. Verás el estimado exacto al hacer checkout."},
        {"question":"¿Puedo facturar a nombre de mi empresa?","answer":"Sí. Al hacer checkout ingresa tu RIF/RFC/NIT y razón social en los datos fiscales — emitimos factura electrónica automáticamente."},
        {"question":"¿Cómo rastreo mi pedido?","answer":"Desde Mis pedidos, selecciona el pedido y verás el estado en tiempo real. También recibirás emails en cada cambio de estado."},
        {"question":"¿Tienen garantía los productos?","answer":"Sí. Todos los productos físicos cuentan con la garantía del fabricante más 6 meses adicionales de Zentto Store."},
        {"question":"¿Cómo cancelo un pedido?","answer":"Si aún no ha sido despachado, desde Mis pedidos pulsa Cancelar. Si ya salió, hay que esperar a recibirlo y tramitar una devolución."}
      ]},
      {"type":"cta","title":"¿No encuentras tu respuesta?","subtitle":"Escríbenos y te ayudamos.","ctaLabel":"Ir al contacto","ctaHref":"/contacto"}
    ]}',
   '{"title":"Centro de ayuda — Zentto Store","description":"Preguntas frecuentes sobre cuenta, pagos, envíos, garantía y devoluciones en Zentto Store."}',
   'published', NOW() AT TIME ZONE 'UTC'),

  (1, 'prensa', 'Prensa',
   'Zentto en los medios',
   'content',
   '{"sections":[
      {"type":"hero","title":"Prensa","subtitle":"Comunicados, noticias y recursos para medios."}
    ]}',
   '{"title":"Prensa — Zentto","description":"Comunicados oficiales, noticias y contacto de prensa de Zentto."}',
   'published', NOW() AT TIME ZONE 'UTC')
ON CONFLICT ("CompanyId", "Slug") DO NOTHING;
-- +goose StatementEnd

-- +goose StatementBegin
INSERT INTO store."PressRelease" ("CompanyId","Slug","Title","Excerpt","Body","Tags","Status","PublishedAt")
VALUES
  (1, 'zentto-lanza-plataforma-ecommerce-erp-integrada',
   'Zentto lanza su plataforma de comercio electrónico integrada con ERP',
   'La nueva solución permite a las PYMEs latinoamericanas gestionar tienda en línea, inventarios y contabilidad desde una única plataforma.',
   $md$
# Zentto lanza su plataforma de comercio electrónico integrada con ERP

**Caracas / Ciudad de México — 15 de marzo de 2026.** Zentto, la suite ERP latinoamericana, anuncia hoy el lanzamiento general de Zentto Store, su módulo de comercio electrónico completamente integrado con el resto del ERP.

## Una sola plataforma, todo el negocio

Con Zentto Store, las PYMEs pueden ahora gestionar desde una única plataforma:

- **Catálogo y tienda online** con dominio propio y pagos locales.
- **Inventario sincronizado en tiempo real** entre tienda física, POS y ecommerce.
- **Facturación electrónica automática** certificada para Venezuela, México, Colombia y España.
- **Envíos y logística** con integración directa a couriers locales.

"El comercio electrónico ya no es un lujo para la PYME latinoamericana — es una necesidad de supervivencia. Pero hasta hoy, montarlo implicaba integrar 4 o 5 herramientas distintas que nunca terminaban de hablar entre sí", comenta Raúl González, CTO de Zentto. "Zentto Store elimina esa complejidad: vendes, cobras, facturas y despachas desde la misma plataforma donde llevas tu contabilidad."

## Disponibilidad

Zentto Store está disponible desde hoy para todos los clientes del plan Pro y Enterprise sin costo adicional. Los clientes del plan Básico pueden activarlo por un complemento mensual.

## Sobre Zentto

Zentto es una suite ERP cloud-first construida en Latinoamérica, con presencia en 14 países y más de 1,000 empresas activas. Incluye módulos de contabilidad, inventario, CRM, POS, ecommerce, nómina, logística y manufactura.

---
**Contacto de prensa:** prensa@zentto.net
$md$,
   ARRAY['producto','lanzamiento','ecommerce'],
   'published', (NOW() AT TIME ZONE 'UTC') - INTERVAL '35 days'),

  (1, 'zentto-supera-1000-empresas-14-paises',
   'Zentto supera las 1,000 empresas activas en 14 países',
   'El ERP latinoamericano alcanza un hito significativo con presencia en Venezuela, Colombia, México, España, Chile, Perú, Argentina, Ecuador, Panamá, Rep. Dominicana, Costa Rica, Uruguay, Bolivia y Paraguay.',
   $md$
# Zentto supera las 1,000 empresas activas en 14 países

**Ciudad de México — 28 de febrero de 2026.** Zentto cierra febrero con más de 1,000 empresas activas usando su plataforma ERP en 14 países de Latinoamérica y España, un 140 % de crecimiento interanual.

## Distribución geográfica

Los principales mercados por número de empresas son:

1. **México** — 28 %
2. **Venezuela** — 22 %
3. **Colombia** — 16 %
4. **España** — 11 %
5. **Argentina, Chile, Perú** — 14 % combinado
6. Resto de LatAm — 9 %

## Qué explica el crecimiento

"Tres factores", explica el equipo. "Primero, la incorporación de facturación electrónica certificada en SAT México y DIAN Colombia. Segundo, el lanzamiento de Zentto POS con impresoras fiscales integradas. Tercero, un modelo de precio único sin límite de usuarios que es especialmente atractivo para PYMEs con equipos grandes."

## Próximos pasos

Zentto planea abrir oficinas comerciales en CDMX y Madrid durante el primer semestre de 2026, y duplicar el equipo de customer success antes de cerrar el año.

---
**Contacto de prensa:** prensa@zentto.net
$md$,
   ARRAY['hito','crecimiento','latam'],
   'published', (NOW() AT TIME ZONE 'UTC') - INTERVAL '50 days')
ON CONFLICT ("CompanyId", "Slug") DO NOTHING;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_store_contactmessage_list(integer, varchar, integer, integer);
DROP FUNCTION IF EXISTS public.usp_store_contactmessage_create(integer, varchar, varchar, varchar, varchar, text, varchar);
DROP FUNCTION IF EXISTS public.usp_store_pressrelease_publish(integer, bigint);
DROP FUNCTION IF EXISTS public.usp_store_pressrelease_delete(integer, bigint);
DROP FUNCTION IF EXISTS public.usp_store_pressrelease_upsert(integer, bigint, varchar, varchar, varchar, text, varchar, text[], varchar);
DROP FUNCTION IF EXISTS public.usp_store_pressrelease_getbyidadmin(integer, bigint);
DROP FUNCTION IF EXISTS public.usp_store_pressrelease_getbyslug(integer, varchar);
DROP FUNCTION IF EXISTS public.usp_store_pressrelease_list(integer, varchar, integer, integer);
DROP FUNCTION IF EXISTS public.usp_store_cmspage_publish(integer, bigint);
DROP FUNCTION IF EXISTS public.usp_store_cmspage_delete(integer, bigint);
DROP FUNCTION IF EXISTS public.usp_store_cmspage_upsert(integer, bigint, varchar, varchar, varchar, varchar, jsonb, jsonb, varchar);
DROP FUNCTION IF EXISTS public.usp_store_cmspage_getbyidadmin(integer, bigint);
DROP FUNCTION IF EXISTS public.usp_store_cmspage_getbyslug(integer, varchar);
DROP FUNCTION IF EXISTS public.usp_store_cmspage_list(integer, varchar, integer, integer);
DROP TABLE IF EXISTS store."ContactMessage";
DROP TABLE IF EXISTS store."PressRelease";
DROP TABLE IF EXISTS store."CmsPage";
-- +goose StatementEnd
