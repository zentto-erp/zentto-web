-- ============================================================
-- fix_inv_movement_types.sql
-- Corrige tipos en usp_inv_movement_*
-- MovementId -> bigint (no integer)
-- MovementDate -> date (no timestamp)
-- SummaryDate -> date (no timestamp)
-- SummaryId -> bigint (no integer)
-- Period -> VARCHAR (es CHAR en tabla, necesita cast)
-- ============================================================

-- 1. usp_inv_movement_getbyid
DROP FUNCTION IF EXISTS public.usp_inv_movement_getbyid(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_getbyid(p_id integer)
  RETURNS TABLE(
    "MovementId"  bigint,
    "Codigo"      character varying,
    "Product"     character varying,
    "Documento"   character varying,
    "Tipo"        character varying,
    "Fecha"       date,
    "Quantity"    numeric,
    "UnitCost"    numeric,
    "TotalCost"   numeric,
    "Notes"       character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."MovementId", m."ProductCode"::VARCHAR, m."ProductName"::VARCHAR, m."DocumentRef"::VARCHAR,
           m."MovementType"::VARCHAR, m."MovementDate", m."Quantity", m."UnitCost", m."TotalCost", m."Notes"::VARCHAR
    FROM master."InventoryMovement" m
    WHERE m."MovementId" = p_id AND m."IsDeleted" = FALSE;
END;
$function$;

-- 2. usp_inv_movement_list
DROP FUNCTION IF EXISTS public.usp_inv_movement_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_list(
    p_search character varying DEFAULT NULL,
    p_tipo   character varying DEFAULT NULL,
    p_offset integer DEFAULT 0,
    p_limit  integer DEFAULT 50
)
  RETURNS TABLE(
    "MovementId"  bigint,
    "Codigo"      character varying,
    "Product"     character varying,
    "Documento"   character varying,
    "Tipo"        character varying,
    "Fecha"       date,
    "Quantity"    numeric,
    "UnitCost"    numeric,
    "TotalCost"   numeric,
    "Notes"       character varying,
    "TotalCount"  bigint
  )
  LANGUAGE plpgsql
AS $function$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryMovement"
    WHERE "IsDeleted" = FALSE
      AND (p_search IS NULL OR "ProductCode" LIKE p_search OR "ProductName" LIKE p_search OR "DocumentRef" LIKE p_search)
      AND (p_tipo IS NULL OR "MovementType" = p_tipo);

    RETURN QUERY
    SELECT m."MovementId", m."ProductCode"::VARCHAR, m."ProductName"::VARCHAR, m."DocumentRef"::VARCHAR,
           m."MovementType"::VARCHAR, m."MovementDate", m."Quantity", m."UnitCost", m."TotalCost",
           m."Notes"::VARCHAR, v_total
    FROM master."InventoryMovement" m
    WHERE m."IsDeleted" = FALSE
      AND (p_search IS NULL OR m."ProductCode" LIKE p_search OR m."ProductName" LIKE p_search OR m."DocumentRef" LIKE p_search)
      AND (p_tipo IS NULL OR m."MovementType" = p_tipo)
    ORDER BY m."MovementDate" DESC, m."MovementId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$;

-- 3. usp_inv_movement_listperiodsummary
DROP FUNCTION IF EXISTS public.usp_inv_movement_listperiodsummary(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_listperiodsummary(
    p_periodo character varying DEFAULT NULL,
    p_codigo  character varying DEFAULT NULL,
    p_offset  integer DEFAULT 0,
    p_limit   integer DEFAULT 50
)
  RETURNS TABLE(
    "SummaryId"   bigint,
    "Periodo"     character varying,
    "Codigo"      character varying,
    "OpeningQty"  numeric,
    "InboundQty"  numeric,
    "OutboundQty" numeric,
    "ClosingQty"  numeric,
    fecha         date,
    "IsClosed"    boolean,
    "TotalCount"  bigint
  )
  LANGUAGE plpgsql
AS $function$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryPeriodSummary"
    WHERE (p_periodo IS NULL OR "Period"::VARCHAR = p_periodo)
      AND (p_codigo IS NULL OR "ProductCode" = p_codigo);

    RETURN QUERY
    SELECT s."SummaryId", s."Period"::VARCHAR, s."ProductCode"::VARCHAR, s."OpeningQty",
           s."InboundQty", s."OutboundQty", s."ClosingQty", s."SummaryDate", s."IsClosed", v_total
    FROM master."InventoryPeriodSummary" s
    WHERE (p_periodo IS NULL OR s."Period"::VARCHAR = p_periodo)
      AND (p_codigo IS NULL OR s."ProductCode" = p_codigo)
    ORDER BY s."Period" DESC, s."ProductCode"
    LIMIT p_limit OFFSET p_offset;
END;
$function$;
