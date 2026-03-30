-- =============================================================================
--  MigraciÃ³n 020: Crear usp_Cfg_Scope_GetDefault en PostgreSQL
--  Motivo: restaurante/admin y media usan esta funciÃ³n que no existÃ­a en PG.
--  Retorna: companyId, branchId, systemUserId (usuario sistema para auditorÃ­a)
-- =============================================================================

\echo '  [020] Creando usp_Cfg_Scope_GetDefault...'

DROP FUNCTION IF EXISTS usp_cfg_scope_getdefault() CASCADE;
CREATE OR REPLACE FUNCTION usp_cfg_scope_getdefault()
RETURNS TABLE(
    "companyId"    INT,
    "branchId"     INT,
    "systemUserId" INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CompanyId",
        b."BranchId",
        (
            SELECT u."UserId"
            FROM   sec."User" u
            WHERE  u."CompanyId" = c."CompanyId"
              AND  (u."UserCode" = 'SYSTEM' OR u."UserCode" = 'ADMIN')
              AND  u."IsDeleted" = FALSE
            ORDER BY CASE WHEN u."UserCode" = 'SYSTEM' THEN 0 ELSE 1 END
            LIMIT 1
        )
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId"
    WHERE c."IsDeleted" = FALSE
      AND b."IsDeleted" = FALSE
    ORDER BY
        CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END,
        c."CompanyId",
        CASE WHEN b."BranchCode"  = 'MAIN'    THEN 0 ELSE 1 END,
        b."BranchId"
    LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_cfg_scope_getdefault() TO zentto_app;

\echo '  [020] Registrando migraciÃ³n...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('020_add_cfg_scope_getdefault', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [020] COMPLETO â€” usp_Cfg_Scope_GetDefault creada'
