-- ============================================================
-- 006_fix_waitticketline_getitems_bigint.sql
-- Corrige tipo de retorno de supervisorApprovalId:
--   integer -> bigint (coincide con pos."WaitTicketLine"."SupervisorApprovalId")
-- Error: "Returned type bigint does not match expected type integer in column 11"
-- ============================================================

DROP FUNCTION IF EXISTS public.usp_pos_waitticketline_getitems(bigint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_pos_waitticketline_getitems(integer) CASCADE;

DROP FUNCTION IF EXISTS public.usp_pos_waitticketline_getitems(p_wait_ticket_id bigint)
 RETURNS TABLE(
   id                  bigint,
   "productoId"        character varying,
   codigo              character varying,
   nombre              character varying,
   cantidad            numeric,
   "precioUnitario"    numeric,
   descuento           numeric,
   iva                 numeric,
   subtotal            numeric,
   total               numeric,
   "supervisorApprovalId" bigint,
   "lineMetaJson"      text
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        wl."WaitTicketLineId",
        COALESCE(wl."ProductId"::TEXT, wl."ProductCode")::VARCHAR,
        wl."ProductCode",
        wl."ProductName",
        wl."Quantity",
        wl."UnitPrice",
        wl."DiscountAmount",
        CASE WHEN wl."TaxRate" > 1 THEN wl."TaxRate" ELSE wl."TaxRate" * 100 END,
        wl."NetAmount",
        wl."TotalAmount",
        wl."SupervisorApprovalId"::BIGINT,
        wl."LineMetaJson"::TEXT
    FROM pos."WaitTicketLine" wl
    WHERE wl."WaitTicketId" = p_wait_ticket_id
    ORDER BY wl."LineNumber";
END;
$function$;
