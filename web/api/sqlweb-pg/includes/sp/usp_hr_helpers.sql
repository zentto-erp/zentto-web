-- =============================================================================
-- usp_hr_helpers.sql  (PostgreSQL / PL/pgSQL)
-- Funciones helper compartidas por modulos de RRHH y Nomina
-- Fecha: 2026-03-28
-- =============================================================================

-- =============================================================================
-- usp_HR_Payroll_ResolveScope
-- Resuelve CompanyId, BranchId y UserId del sistema
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ResolveScope() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_ResolveScope()
RETURNS TABLE(
    "companyId"     INTEGER,
    "branchId"      INTEGER,
    "systemUserId"  INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CompanyId"   AS "companyId",
        b."BranchId"    AS "branchId",
        su."UserId"     AS "systemUserId"
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b
        ON b."CompanyId" = c."CompanyId"
       AND b."BranchCode" = 'MAIN'
    LEFT JOIN sec."User" su
        ON su."UserCode" = 'SYSTEM'
    WHERE c."CompanyCode" = 'DEFAULT'
    ORDER BY c."CompanyId", b."BranchId"
    LIMIT 1;
END;
$$;

-- =============================================================================
-- usp_HR_Payroll_ResolveUser
-- Resuelve UserId a partir de UserCode
-- =============================================================================
DROP FUNCTION IF EXISTS public.usp_HR_Payroll_ResolveUser(VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_HR_Payroll_ResolveUser(
    p_user_code  VARCHAR DEFAULT NULL
)
RETURNS TABLE("userId" INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_user_code IS NOT NULL AND TRIM(p_user_code) <> '' THEN
        RETURN QUERY
        SELECT u."UserId" AS "userId"
        FROM sec."User" u
        WHERE u."UserCode" = TRIM(p_user_code)
           OR u."Username" = TRIM(p_user_code)
        LIMIT 1;
    ELSE
        RETURN QUERY
        SELECT u."UserId" AS "userId"
        FROM sec."User" u
        WHERE u."UserCode" = 'SYSTEM'
        LIMIT 1;
    END IF;
END;
$$;
