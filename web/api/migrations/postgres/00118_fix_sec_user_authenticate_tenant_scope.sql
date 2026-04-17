-- +goose Up
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_Sec_User_Authenticate(
    p_cod_usuario  VARCHAR,
    p_company_id   INTEGER DEFAULT NULL
)
RETURNS TABLE(
    "Cod_Usuario"   VARCHAR,
    "Password"      VARCHAR,
    "Nombre"        VARCHAR,
    "Tipo"          VARCHAR,
    "Updates"       BOOLEAN,
    "Addnews"       BOOLEAN,
    "Deletes"       BOOLEAN,
    "Creador"       VARCHAR,
    "Cambiar"       BOOLEAN,
    "PrecioMinimo"  BOOLEAN,
    "Credito"       BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."UserCode",
           u."PasswordHash",
           u."UserName",
           u."UserType",
           COALESCE(u."CanUpdate", TRUE),
           COALESCE(u."CanCreate", TRUE),
           COALESCE(u."CanDelete", TRUE),
           u."CreatedByUserId"::VARCHAR,
           COALESCE(u."CanChangePwd", TRUE),
           COALESCE(u."CanChangePrice", TRUE),
           COALESCE(u."CanGiveCredit", TRUE)
    FROM   sec."User" u
    WHERE  u."UserCode"  = p_cod_usuario
      AND  u."IsDeleted" = FALSE
      AND  (p_company_id IS NULL OR u."CompanyId" = p_company_id)
    ORDER BY u."CompanyId"
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_Sec_User_Authenticate(
    p_cod_usuario  VARCHAR
)
RETURNS TABLE(
    "Cod_Usuario"   VARCHAR,
    "Password"      VARCHAR,
    "Nombre"        VARCHAR,
    "Tipo"          VARCHAR,
    "Updates"       BOOLEAN,
    "Addnews"       BOOLEAN,
    "Deletes"       BOOLEAN,
    "Creador"       VARCHAR,
    "Cambiar"       BOOLEAN,
    "PrecioMinimo"  BOOLEAN,
    "Credito"       BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT u."UserCode",
           u."PasswordHash",
           u."UserName",
           u."UserType",
           COALESCE(u."CanUpdate", TRUE),
           COALESCE(u."CanCreate", TRUE),
           COALESCE(u."CanDelete", TRUE),
           u."CreatedByUserId"::VARCHAR,
           COALESCE(u."CanChangePwd", TRUE),
           COALESCE(u."CanChangePrice", TRUE),
           COALESCE(u."CanGiveCredit", TRUE)
    FROM   sec."User" u
    WHERE  u."UserCode"  = p_cod_usuario
      AND  u."IsDeleted" = FALSE
    LIMIT 1;
END;
$$;
-- +goose StatementEnd
