-- +goose Up
-- +goose StatementBegin
-- Fix: columna "Status" ambigua en SPs list (conflicto con RETURNS TABLE).
-- Error prod: `column reference "Status" is ambiguous` en /store/press/releases.
-- Causa: el SELECT COUNT interno usa "Status" sin alias de tabla, y el
-- RETURNS TABLE declara columna con el mismo nombre.
-- Fix: calificar todas las referencias con el alias de la tabla.

-- ─── usp_store_cmspage_list — fix COUNT ambigüo ─────────
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
    FROM store."CmsPage" c
   WHERE c."CompanyId" = p_company_id
     AND (p_status IS NULL OR c."Status" = p_status);

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

-- ─── usp_store_pressrelease_list — fix COUNT ambigüo ────
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
    FROM store."PressRelease" pr
   WHERE pr."CompanyId" = p_company_id
     AND (p_status IS NULL OR pr."Status" = p_status);

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

-- +goose Down
-- No down — los SPs corregidos sobrescriben via CREATE OR REPLACE.
-- Revertir requiere re-aplicar las versiones originales de la migración 00149.
SELECT 1;
