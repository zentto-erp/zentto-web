-- +goose Up
-- usp_Sys_Notificacion_Insert ahora acepta p_company_id y p_app_code
-- para que cada notificacion se cree con su alcance correcto (empresa + app).
-- Backward compat: params opcionales, NULL = broadcast.

-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_sys_notificacion_insert(varchar, varchar, varchar, varchar, varchar);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_sys_notificacion_insert(
  p_tipo            varchar,
  p_titulo          varchar,
  p_mensaje         varchar,
  p_usuario_id      varchar DEFAULT NULL,
  p_ruta_navegacion varchar DEFAULT NULL,
  p_company_id      integer DEFAULT NULL,
  p_app_code        varchar DEFAULT NULL
)
RETURNS TABLE (
  "Id"      integer,
  "Mensaje" varchar
)
LANGUAGE plpgsql AS $$
BEGIN
  -- Evitar duplicados recientes: mismo titulo + scope (user/company/app)
  -- en las ultimas 4 horas si aun no leida.
  IF EXISTS (
    SELECT 1 FROM public."Sys_Notificaciones" n
     WHERE n."Titulo" = p_titulo
       AND (n."UsuarioId" = p_usuario_id OR (n."UsuarioId" IS NULL AND p_usuario_id IS NULL))
       AND (n."CompanyId" = p_company_id OR (n."CompanyId" IS NULL AND p_company_id IS NULL))
       AND (n."AppCode"   = p_app_code   OR (n."AppCode"   IS NULL AND p_app_code   IS NULL))
       AND n."Leido" = FALSE
       AND n."FechaCreacion" > NOW() - INTERVAL '4 hours'
  ) THEN
    RETURN QUERY SELECT 0, 'duplicado_reciente'::varchar;
    RETURN;
  END IF;

  RETURN QUERY
  INSERT INTO public."Sys_Notificaciones" (
    "Tipo", "Titulo", "Mensaje", "UsuarioId", "RutaNavegacion", "CompanyId", "AppCode"
  ) VALUES (
    p_tipo, p_titulo, p_mensaje, p_usuario_id, p_ruta_navegacion, p_company_id, p_app_code
  )
  RETURNING public."Sys_Notificaciones"."Id", 'ok'::varchar;
END;
$$;
-- +goose StatementEnd

-- +goose Down
SELECT 1;
