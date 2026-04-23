-- +goose Up
-- Extiende el sistema de notificaciones para filtrado por empresa y app.
--
-- Hasta ahora: Sys_Notificaciones tenia solo UsuarioId (NULL = broadcast).
-- Resultado: todas las apps (crm, ventas, ecommerce, etc.) veian las mismas
-- notificaciones sin forma de segmentar.
--
-- Cambio: agregar columnas CompanyId y AppCode (nullable = broadcast).
-- El SP filtra con logica inclusiva:
--   UsuarioId NULL o = usuario  (igual que antes)
--   CompanyId NULL o = empresa activa del request
--   AppCode   NULL o = app desde la que se consulta
--
-- Esto permite:
--   - NULL en las 3 columnas -> notificacion global (banner del sistema)
--   - CompanyId=1 + AppCode=NULL -> para toda empresa 1, cualquier app
--   - CompanyId=1 + AppCode='crm' -> solo crm de empresa 1
--   - UsuarioId='abc' -> solo usuario abc (puede combinarse con los otros)

-- +goose StatementBegin
ALTER TABLE public."Sys_Notificaciones"
  ADD COLUMN IF NOT EXISTS "CompanyId" integer NULL,
  ADD COLUMN IF NOT EXISTS "AppCode"   varchar(50) NULL;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS idx_sys_notif_scope
  ON public."Sys_Notificaciones" ("CompanyId", "AppCode", "UsuarioId", "FechaCreacion" DESC);
-- +goose StatementEnd

-- +goose StatementBegin
-- Drop old single-param SP para evitar ambiguedad con la nueva firma.
DROP FUNCTION IF EXISTS public.usp_sys_notificacion_list(varchar);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sys_notificacion_list(
  p_usuario_id  varchar DEFAULT NULL,
  p_company_id  integer DEFAULT NULL,
  p_app_code    varchar DEFAULT NULL
)
RETURNS TABLE (
  "Id"             integer,
  "Tipo"           varchar,
  "Titulo"         varchar,
  "Mensaje"        text,
  "Leido"          boolean,
  "FechaCreacion"  timestamp,
  "RutaNavegacion" varchar
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT n."Id", n."Tipo", n."Titulo", n."Mensaje",
         n."Leido", n."FechaCreacion", n."RutaNavegacion"
    FROM public."Sys_Notificaciones" n
   WHERE (n."UsuarioId" IS NULL OR n."UsuarioId" = p_usuario_id)
     -- CompanyId: si el request no envia companyId, solo muestra broadcasts.
     -- Si envia companyId, muestra notifs de esa empresa + broadcasts (NULL).
     AND (p_company_id IS NULL OR n."CompanyId" IS NULL OR n."CompanyId" = p_company_id)
     -- AppCode: si el request no envia appCode, muestra todas.
     -- Si envia appCode, muestra notifs de esa app + cross-app (NULL).
     AND (p_app_code IS NULL OR n."AppCode" IS NULL OR n."AppCode" = p_app_code)
   ORDER BY n."FechaCreacion" DESC
   LIMIT 50;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP INDEX IF EXISTS idx_sys_notif_scope;
-- +goose StatementEnd

-- +goose StatementBegin
ALTER TABLE public."Sys_Notificaciones"
  DROP COLUMN IF EXISTS "AppCode",
  DROP COLUMN IF EXISTS "CompanyId";
-- +goose StatementEnd
