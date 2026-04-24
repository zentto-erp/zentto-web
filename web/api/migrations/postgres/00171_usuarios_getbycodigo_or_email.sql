-- +goose Up
-- +goose StatementBegin

-- usp_usuarios_getbycodigo: acepta tanto UserCode como Email como identificador.
-- Motivo: zentto-auth emite JWT con `sub = email` (identidad global del ecosistema),
-- mientras que /v1/auth/login del ERP emite `sub = UserCode`. Cualquier endpoint
-- que llame a getUsuarioByCodigoSP(req.user.sub) debe funcionar con ambos formatos.
-- Prioridad: match exacto por UserCode primero, luego por Email.

CREATE OR REPLACE FUNCTION public.usp_usuarios_getbycodigo(
    p_cod_usuario character varying
)
RETURNS TABLE(
    "Cod_Usuario" character varying,
    "Password" character varying,
    "Nombre" character varying,
    "Tipo" character varying,
    "Updates" boolean,
    "Addnews" boolean,
    "Deletes" boolean,
    "Creador" boolean,
    "Cambiar" boolean,
    "PrecioMinimo" boolean,
    "Credito" boolean,
    "IsAdmin" boolean,
    "Avatar" text
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u."UserCode"::varchar       AS "Cod_Usuario",
        u."PasswordHash"::varchar   AS "Password",
        u."UserName"::varchar       AS "Nombre",
        u."UserType"::varchar       AS "Tipo",
        u."CanUpdate"      AS "Updates",
        u."CanCreate"      AS "Addnews",
        u."CanDelete"      AS "Deletes",
        u."IsCreator"      AS "Creador",
        u."CanChangePwd"   AS "Cambiar",
        u."CanChangePrice" AS "PrecioMinimo",
        u."CanGiveCredit"  AS "Credito",
        u."IsAdmin",
        u."Avatar"
    FROM sec."User" u
    WHERE u."IsDeleted" = FALSE
      AND (u."UserCode" = p_cod_usuario OR u."Email" = p_cod_usuario)
    ORDER BY
        CASE WHEN u."UserCode" = p_cod_usuario THEN 0 ELSE 1 END,
        u."UserId"
    LIMIT 1;
END;
$$;

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
-- Down: volver a la version solo-UserCode (pero es menos funcional, solo para rollback)
CREATE OR REPLACE FUNCTION public.usp_usuarios_getbycodigo(
    p_cod_usuario character varying
)
RETURNS TABLE(
    "Cod_Usuario" character varying,
    "Password" character varying,
    "Nombre" character varying,
    "Tipo" character varying,
    "Updates" boolean,
    "Addnews" boolean,
    "Deletes" boolean,
    "Creador" boolean,
    "Cambiar" boolean,
    "PrecioMinimo" boolean,
    "Credito" boolean,
    "IsAdmin" boolean,
    "Avatar" text
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        u."UserCode"::varchar       AS "Cod_Usuario",
        u."PasswordHash"::varchar   AS "Password",
        u."UserName"::varchar       AS "Nombre",
        u."UserType"::varchar       AS "Tipo",
        u."CanUpdate"      AS "Updates",
        u."CanCreate"      AS "Addnews",
        u."CanDelete"      AS "Deletes",
        u."IsCreator"      AS "Creador",
        u."CanChangePwd"   AS "Cambiar",
        u."CanChangePrice" AS "PrecioMinimo",
        u."CanGiveCredit"  AS "Credito",
        u."IsAdmin",
        u."Avatar"
    FROM sec."User" u
    WHERE u."UserCode" = p_cod_usuario AND u."IsDeleted" = FALSE;
END;
$$;
-- +goose StatementEnd
