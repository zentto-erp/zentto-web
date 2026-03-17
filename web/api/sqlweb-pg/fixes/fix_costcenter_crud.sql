-- Fix: usp_acct_costcenter_insert - rename params to match TypeScript service
-- Service calls with: CompanyId -> p_company_id, CostCenterCode -> p_cost_center_code, CostCenterName -> p_cost_center_name, ParentCode -> p_parent_code
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_insert(integer, character varying, character varying, character varying, integer, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_costcenter_insert(
    p_company_id        integer,
    p_cost_center_code  character varying,
    p_cost_center_name  character varying,
    p_parent_code       character varying DEFAULT NULL::character varying,
    OUT p_resultado     integer,
    OUT p_mensaje       text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
DECLARE
    v_parent_id INTEGER;
    v_lvl       SMALLINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_cost_center_code AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Ya existe un centro de costo con el codigo ' || p_cost_center_code || '.';
        RETURN;
    END IF;

    v_parent_id := NULL;
    v_lvl       := 1;

    IF p_parent_code IS NOT NULL THEN
        SELECT "CostCenterId", "Level" + 1
        INTO v_parent_id, v_lvl
        FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_parent_code AND "IsDeleted" = FALSE;

        IF v_parent_id IS NULL THEN
            p_mensaje := 'Centro de costo padre ' || p_parent_code || ' no encontrado.';
            RETURN;
        END IF;
    END IF;

    BEGIN
        INSERT INTO acct."CostCenter" ("CompanyId", "CostCenterCode", "CostCenterName", "ParentCostCenterId", "Level")
        VALUES (p_company_id, p_cost_center_code, p_cost_center_name, v_parent_id, v_lvl);

        p_resultado := 1;
        p_mensaje   := 'Centro de costo ' || p_cost_center_code || ' creado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al crear centro de costo: ' || SQLERRM;
    END;
END;
$function$;

-- Fix: usp_acct_costcenter_update - rename params to match TypeScript service
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_update(integer, character varying, character varying, character varying, integer, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_costcenter_update(
    p_company_id        integer,
    p_cost_center_code  character varying,
    p_cost_center_name  character varying DEFAULT NULL::character varying,
    p_parent_code       character varying DEFAULT NULL::character varying,
    OUT p_resultado     integer,
    OUT p_mensaje       text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
DECLARE
    v_parent_id INTEGER;
    v_lvl       SMALLINT;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF NOT EXISTS (
        SELECT 1 FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_cost_center_code AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'Centro de costo ' || p_cost_center_code || ' no encontrado.';
        RETURN;
    END IF;

    v_parent_id := NULL;
    v_lvl       := 1;

    IF p_parent_code IS NOT NULL THEN
        SELECT "CostCenterId", "Level" + 1
        INTO v_parent_id, v_lvl
        FROM acct."CostCenter"
        WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_parent_code AND "IsDeleted" = FALSE;

        IF v_parent_id IS NULL THEN
            p_mensaje := 'Centro de costo padre ' || p_parent_code || ' no encontrado.';
            RETURN;
        END IF;
    END IF;

    BEGIN
        UPDATE acct."CostCenter"
        SET "CostCenterName"     = COALESCE(p_cost_center_name, "CostCenterName"),
            "ParentCostCenterId" = v_parent_id,
            "Level"              = v_lvl,
            "UpdatedAt"          = (NOW() AT TIME ZONE 'UTC')
        WHERE "CompanyId"      = p_company_id
          AND "CostCenterCode" = p_cost_center_code
          AND "IsDeleted"      = FALSE;

        p_resultado := 1;
        p_mensaje   := 'Centro de costo ' || p_cost_center_code || ' actualizado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al actualizar centro de costo: ' || SQLERRM;
    END;
END;
$function$;

-- Fix: usp_acct_costcenter_delete - rename params to match TypeScript service
DROP FUNCTION IF EXISTS public.usp_acct_costcenter_delete(integer, character varying, integer, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_acct_costcenter_delete(
    p_company_id        integer,
    p_cost_center_code  character varying,
    OUT p_resultado     integer,
    OUT p_mensaje       text
)
RETURNS record
LANGUAGE plpgsql
AS $function$
DECLARE
    v_cc_id INTEGER;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    SELECT "CostCenterId"
    INTO v_cc_id
    FROM acct."CostCenter"
    WHERE "CompanyId" = p_company_id AND "CostCenterCode" = p_cost_center_code AND "IsDeleted" = FALSE;

    IF v_cc_id IS NULL THEN
        p_mensaje := 'No se encontro el centro de costo ' || p_cost_center_code || '.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM acct."CostCenter"
        WHERE "ParentCostCenterId" = v_cc_id AND "IsDeleted" = FALSE
    ) THEN
        p_mensaje := 'No se puede eliminar: el centro de costo tiene hijos activos.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."CostCenter"
        SET "IsDeleted" = TRUE,
            "IsActive"  = FALSE,
            "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
        WHERE "CostCenterId" = v_cc_id;

        p_resultado := 1;
        p_mensaje   := 'Centro de costo ' || p_cost_center_code || ' eliminado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error al eliminar centro de costo: ' || SQLERRM;
    END;
END;
$function$;
