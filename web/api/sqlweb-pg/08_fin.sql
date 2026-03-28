-- sp_conciliacion_get_detalle_sistema
DROP FUNCTION IF EXISTS public.sp_conciliacion_get_detalle_sistema(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_conciliacion_get_detalle_sistema(p_conciliacion_id integer)
 RETURNS TABLE("ID" integer, "Conciliacion_ID" integer, "Tipo_Origen" character varying, "MovCuentas_ID" integer, "Extracto_ID" integer, "Fecha" timestamp without time zone, "Descripcion" character varying, "Referencia" character varying, "Debito" numeric, "Credito" numeric, "Conciliado" boolean, "Nro_Ref" character varying, "MovFecha" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        d."ID", d."Conciliacion_ID", d."Tipo_Origen", d."MovCuentas_ID",

        d."Extracto_ID", d."Fecha", d."Descripcion", d."Referencia",

        d."Debito", d."Credito", d."Conciliado",

        m."Nro_Ref", m."Fecha" AS "MovFecha"

    FROM "ConciliacionDetalle" d

DROP FUNCTION IF EXISTS m ON m."id" = d."MovCuentas_ID"

    WHERE d."Conciliacion_ID" = p_conciliacion_id AND d."Tipo_Origen" = 'SISTEMA'

    ORDER BY d."Fecha";

END;

$function$
;

-- sp_conciliacion_get_extracto_pendiente
DROP FUNCTION IF EXISTS public.sp_conciliacion_get_extracto_pendiente(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_conciliacion_get_extracto_pendiente(p_conciliacion_id integer)
 RETURNS TABLE("ID" integer, "Nro_Cta" character varying, "Fecha" timestamp without time zone, "Descripcion" character varying, "Referencia" character varying, "Tipo" character varying, "Monto" numeric, "Saldo" numeric, "Conciliado" boolean)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_nro_cta     VARCHAR(20);

    v_fecha_desde TIMESTAMP;

    v_fecha_hasta TIMESTAMP;

BEGIN

    SELECT cb."Nro_Cta", cb."Fecha_Desde", cb."Fecha_Hasta"
DROP FUNCTION IF EXISTS
    INTO v_nro_cta, v_fecha_desde, v_fecha_hasta

    FROM "ConciliacionBancaria" cb

    WHERE cb."ID" = p_conciliacion_id;



    RETURN QUERY

    SELECT

        e."ID", e."Nro_Cta", e."Fecha", e."Descripcion", e."Referencia",

        e."Tipo", e."Monto", e."Saldo", e."Conciliado"

    FROM "ExtractoBancario" e

    WHERE e."Nro_Cta" = v_nro_cta

DROP FUNCTION IF EXISTS FALSE

      AND e."Fecha" BETWEEN v_fecha_desde AND v_fecha_hasta

    ORDER BY e."Fecha";

END;

$function$
;

-- sp_conciliacion_get_header
DROP FUNCTION IF EXISTS public.sp_conciliacion_get_header(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_conciliacion_get_header(p_conciliacion_id integer)
 RETURNS TABLE("ID" integer, "Nro_Cta" character varying, "Fecha_Desde" timestamp without time zone, "Fecha_Hasta" timestamp without time zone, "Saldo_Inicial_Sistema" numeric, "Saldo_Final_Sistema" numeric, "Saldo_Inicial_Banco" numeric, "Saldo_Final_Banco" numeric, "Diferencia" numeric, "Estado" character varying, "Observaciones" character varying, "Banco" character varying, "Descripcion" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        c."ID", c."Nro_Cta", c."Fecha_Desde", c."Fecha_Hasta",

        c."Saldo_Inicial_Sistema", c."Saldo_Final_Sistema",

        c."Saldo_Inicial_Banco", c."Saldo_Final_Banco",

        c."Diferencia", c."Estado", c."Observaciones",

        b."Banco", b."Descripcion"

    FROM "ConciliacionBancaria" c

DROP FUNCTION IF EXISTS" b ON b."Nro_Cta" = c."Nro_Cta"

    WHERE c."ID" = p_conciliacion_id;

END;

$function$
;

-- sp_conciliacion_list
DROP FUNCTION IF EXISTS public.sp_conciliacion_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.sp_conciliacion_list(p_nro_cta character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "ID" integer, "Nro_Cta" character varying, "Fecha_Desde" timestamp without time zone, "Fecha_Hasta" timestamp without time zone, "Saldo_Inicial_Sistema" numeric, "Saldo_Final_Sistema" numeric, "Saldo_Inicial_Banco" numeric, "Saldo_Final_Banco" numeric, "Diferencia" numeric, "Estado" character varying, "Observaciones" character varying, "Co_Usuario" character varying, "Fecha_Creacion" timestamp without time zone, "Fecha_Cierre" timestamp without time zone, "Banco" character varying, "Pendientes" bigint, "Conciliados" bigint)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_offset INT := (p_page - 1) * p_limit;

    v_total  BIGINT;

BEGIN

    SELECT COUNT(1) INTO v_total

    FROM "ConciliacionBancaria"

    WHERE (p_nro_cta IS NULL OR "Nro_Cta" = p_nro_cta)

      AND (p_estado IS NULL OR "Estado" = p_estado);



    RETURN QUERY

    SELECT

        v_total,

        c."ID", c."Nro_Cta", c."Fecha_Desde", c."Fecha_Hasta",

        c."Saldo_Inicial_Sistema", c."Saldo_Final_Sistema",

        c."Saldo_Inicial_Banco", c."Saldo_Final_Banco",

        c."Diferencia", c."Estado", c."Observaciones",

        c."Co_Usuario", c."Fecha_Creacion", c."Fecha_Cierre",

        b."Banco",

        (SELECT COUNT(1) FROM "ConciliacionDetalle" d WHERE d."Conciliacion_ID" = c."ID" AND d."Conciliado" = FALSE),

        (SELECT COUNT(1) FROM "ConciliacionDetalle" d WHERE d."Conciliacion_ID" = c."ID" AND d."Conciliado" = TRUE)

    FROM "ConciliacionBancaria" c

    LEFT JOIN "CuentasBank" b ON b."Nro_Cta" = c."Nro_Cta"

    WHERE (p_nro_cta IS NULL OR c."Nro_Cta" = p_nro_cta)

      AND (p_estado IS NULL OR c."Estado" = p_estado)

    ORDER BY c."Fecha_Creacion" DESC

    LIMIT p_limit OFFSET v_offset;

END;

$function$
;

-- usp_ap_application_apply
DROP FUNCTION IF EXISTS public.usp_ap_application_apply(bigint, numeric, character varying, date, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_application_apply(p_payable_document_id bigint, p_amount numeric, p_payment_reference character varying DEFAULT NULL::character varying, p_apply_date date DEFAULT NULL::date, p_updated_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE(ok integer, "ApplicationId" bigint, "NewPending" numeric, "Message" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE
DROP FUNCTION IF EXISTS
    v_apply_date       DATE := COALESCE(p_apply_date, (NOW() AT TIME ZONE 'UTC')::DATE);

    v_current_pending  DECIMAL(18,2);

    v_new_pending      DECIMAL(18,2);

    v_supplier_id      BIGINT;

    v_total_amount     DECIMAL(18,2);

    v_application_id   BIGINT;

    v_doc_status       VARCHAR(20);

BEGIN

    -- Validaciones basicas

    IF p_amount IS NULL OR p_amount <= 0 THEN

        RETURN QUERY SELECT 0, NULL::BIGINT, NULL::DECIMAL(18,2),

            'El monto debe ser mayor a cero.'::TEXT;

        RETURN;

    END IF;



    -- Obtener documento con bloqueo para evitar concurrencia

    SELECT d."PendingAmount", d."TotalAmount", d."SupplierId", d."Status"

    INTO v_current_pending, v_total_amount, v_supplier_id, v_doc_status

DROP FUNCTION IF EXISTSnt" d

    WHERE d."PayableDocumentId" = p_payable_document_id

    FOR UPDATE;



    -- Validar que el documento existe

    IF v_current_pending IS NULL THEN

        RETURN QUERY SELECT 0, NULL::BIGINT, NULL::DECIMAL(18,2),

            'Documento por pagar no encontrado.'::TEXT;

        RETURN;

    END IF;



    -- Validar que el documento no este anulado

    IF v_doc_status = 'VOIDED' THEN

        RETURN QUERY SELECT 0, NULL::BIGINT, NULL::DECIMAL(18,2),

            'No se puede aplicar pago a un documento anulado.'::TEXT;

        RETURN;

    END IF;



    -- Validar que el monto no exceda el saldo pendiente

    IF p_amount > v_current_pending THEN

        RETURN QUERY SELECT 0, NULL::BIGINT, v_current_pending,
DROP FUNCTION IF EXISTS
            ('El monto (' || p_amount::TEXT || ') excede el saldo pendiente (' || v_current_pending::TEXT || ').')::TEXT;

        RETURN;

    END IF;



    -- Insertar la aplicacion (pago)

    INSERT INTO ap."PayableApplication" ("PayableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference")

    VALUES (p_payable_document_id, v_apply_date, p_amount, p_payment_reference)

    RETURNING "PayableApplicationId" INTO v_application_id;



    -- Calcular nuevo saldo pendiente

    v_new_pending := v_current_pending - p_amount;



    -- Actualizar documento

    UPDATE ap."PayableDocument"

    SET "PendingAmount"   = v_new_pending,

        "PaidFlag"        = (v_new_pending <= 0),

        "Status"          = CASE

                              WHEN v_new_pending <= 0           THEN 'PAID'

                              WHEN v_new_pending < v_total_amount THEN 'PARTIAL'

                              ELSE 'PENDING'

                            END,

        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',

        "UpdatedByUserId" = p_updated_by_user_id

    WHERE "PayableDocumentId" = p_payable_document_id;



    -- Recalcular saldo total del proveedor
DROP FUNCTION IF EXISTS
    PERFORM usp_Master_Supplier_UpdateBalance(v_supplier_id, p_updated_by_user_id);



    -- Retornar resultado exitoso

    RETURN QUERY SELECT 1, v_application_id, v_new_pending,

        'Pago aplicado correctamente.'::TEXT;

END;

$function$
;

-- usp_ap_application_get
DROP FUNCTION IF EXISTS public.usp_ap_application_get(bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_application_get(p_application_id bigint)
 RETURNS TABLE("PayableApplicationId" bigint, "PayableDocumentId" bigint, "ApplyDate" date, "AppliedAmount" numeric, "PaymentReference" character varying, "CreatedAt" timestamp without time zone, "DocumentNumber" character varying, "DocumentType" character varying, "IssueDate" date, "DueDate" date, "CurrencyCode" character varying, "TotalAmount" numeric, "PendingAmount" numeric, "PaidFlag" boolean, "DocumentStatus" character varying, "DocumentNotes" character varying, "SupplierId" bigint, "SupplierCode" character varying, "SupplierName" character varying, "SupplierFiscalId" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        a."PayableApplicationId",

        a."PayableDocumentId",

        a."ApplyDate",

        a."AppliedAmount",

        a."PaymentReference",

        a."CreatedAt",

        d."DocumentNumber",

        d."DocumentType",

        d."IssueDate",

        d."DueDate",

        d."CurrencyCode",

        d."TotalAmount",

        d."PendingAmount",

        d."PaidFlag",

        d."Status",

        d."Notes",

        s."SupplierId",

        s."SupplierCode",

        s."SupplierName",

        s."FiscalId"

    FROM ap."PayableApplication" a

    INNER JOIN ap."PayableDocument" d ON d."PayableDocumentId" = a."PayableDocumentId"

    INNER JOIN master."Supplier" s    ON s."SupplierId"        = d."SupplierId"
DROP FUNCTION IF EXISTS
    WHERE a."PayableApplicationId" = p_application_id;

END;

$function$
;

-- usp_ap_application_getbycontext
DROP FUNCTION IF EXISTS public.usp_ap_application_getbycontext(bigint, integer, integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_application_getbycontext(p_application_id bigint, p_company_id integer, p_branch_id integer, p_currency_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Id" bigint, "ApplicationId" bigint, "DocumentoId" bigint, "CODIGO" character varying, "Codigo" character varying, "NOMBRE" character varying, "TIPO_DOC" character varying, "TipoDoc" character varying, "DOCUMENTO" character varying, "Num_fact" character varying, "FECHA" date, "Fecha" date, "MONTO" numeric, "Monto" numeric, "MONEDA" character varying, "REFERENCIA" character varying, "Concepto" character varying, "PENDIENTE" numeric, "TOTAL" numeric, "ESTADO_DOC" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        a."PayableApplicationId",

        a."PayableApplicationId",

        d."PayableDocumentId",

        s."SupplierCode",
DROP FUNCTION IF EXISTS
        s."SupplierCode",

        s."SupplierName",

        d."DocumentType",

        d."DocumentType",

        d."DocumentNumber",

        d."DocumentNumber",

        a."ApplyDate",

        a."ApplyDate",

        a."AppliedAmount",

        a."AppliedAmount",

        d."CurrencyCode",

        a."PaymentReference",

        a."PaymentReference",

        d."PendingAmount",

        d."TotalAmount",

        d."Status"

    FROM ap."PayableApplication" a

    INNER JOIN ap."PayableDocument" d ON d."PayableDocumentId" = a."PayableDocumentId"

    INNER JOIN master."Supplier" s    ON s."SupplierId"        = d."SupplierId"

    WHERE a."PayableApplicationId" = p_application_id

      AND d."CompanyId" = p_company_id

      AND d."BranchId"  = p_branch_id

      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code)

    LIMIT 1;

END;

$function$
;

-- usp_ap_application_list
DROP FUNCTION IF EXISTS public.usp_ap_application_list(bigint, character varying, date, date, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_application_list(p_supplier_id bigint DEFAULT NULL::bigint, p_document_type character varying DEFAULT NULL::character varying, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("PayableApplicationId" bigint, "PayableDocumentId" bigint, "ApplyDate" date, "AppliedAmount" numeric, "PaymentReference" character varying, "CreatedAt" timestamp without time zone, "DocumentNumber" character varying, "DocumentType" character varying, "TotalAmount" numeric, "PendingAmount" numeric, "DocumentStatus" character varying, "SupplierId" bigint, "SupplierCode" character varying, "SupplierName" character varying, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_page   INT := GREATEST(COALESCE(p_page, 1), 1);

    v_limit  INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 500);

    v_offset INT := (v_page - 1) * v_limit;

DROP FUNCTION IF EXISTS

BEGIN

    -- Contar registros totales que cumplen los filtros

    SELECT COUNT(*) INTO v_total

    FROM ap."PayableApplication" a

    INNER JOIN ap."PayableDocument" d ON d."PayableDocumentId" = a."PayableDocumentId"

    WHERE (p_supplier_id   IS NULL OR d."SupplierId"    = p_supplier_id)

      AND (p_document_type IS NULL OR d."DocumentType"  = p_document_type)

      AND (p_from_date     IS NULL OR a."ApplyDate"    >= p_from_date)

      AND (p_to_date       IS NULL OR a."ApplyDate"    <= p_to_date);



    -- Retornar pagina solicitada

    RETURN QUERY

    SELECT

        a."PayableApplicationId",

        a."PayableDocumentId",

        a."ApplyDate",

        a."AppliedAmount",

        a."PaymentReference",

        a."CreatedAt",

        d."DocumentNumber",

        d."DocumentType",

        d."TotalAmount",

        d."PendingAmount",

        d."Status",

        s."SupplierId",

        s."SupplierCode",

        s."SupplierName",

        v_total

    FROM ap."PayableApplication" a

    INNER JOIN ap."PayableDocument" d ON d."PayableDocumentId" = a."PayableDocumentId"

    INNER JOIN master."Supplier" s    ON s."SupplierId"        = d."SupplierId"

    WHERE (p_supplier_id   IS NULL OR d."SupplierId"    = p_supplier_id)

      AND (p_document_type IS NULL OR d."DocumentType"  = p_document_type)

      AND (p_from_date     IS NULL OR a."ApplyDate"    >= p_from_date)

      AND (p_to_date       IS NULL OR a."ApplyDate"    <= p_to_date)

    ORDER BY a."ApplyDate" DESC, a."PayableApplicationId" DESC

    LIMIT v_limit OFFSET v_offset;

END;

$function$
;

-- usp_ap_application_listbycontext
DROP FUNCTION IF EXISTS public.usp_ap_application_listbycontext(integer, integer, character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_application_listbycontext(p_company_id integer, p_branch_id integer, p_search character varying DEFAULT NULL::character varying, p_codigo character varying DEFAULT NULL::character varying, p_currency_code character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("Id" bigint, "ApplicationId" bigint, "DocumentoId" bigint, "CODIGO" character varying, "Codigo" character varying, "NOMBRE" character varying, "TIPO_DOC" character varying, "TipoDoc" character varying, "DOCUMENTO" character varying, "Num_fact" character varying, "FECHA" date, "Fecha" date, "MONTO" numeric, "Monto" numeric, "MONEDA" character varying, "REFERENCIA" character varying, "Concepto" character varying, "PENDIENTE" numeric, "TOTAL" numeric, "ESTADO_DOC" character varying, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_page           INT := GREATEST(COALESCE(p_page, 1), 1);

    v_limit          INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 500);

    v_offset         INT := (v_page - 1) * v_limit;
DROP FUNCTION IF EXISTS
    v_search_pattern VARCHAR(102);

    v_total          BIGINT;

BEGIN

    IF p_search IS NOT NULL AND LENGTH(TRIM(p_search)) > 0 THEN

        v_search_pattern := '%' || TRIM(p_search) || '%';

    END IF;



    -- Contar registros totales

    SELECT COUNT(*) INTO v_total

    FROM ap."PayableApplication" a

DROP FUNCTION IF EXISTSDocument" d ON d."PayableDocumentId" = a."PayableDocumentId"

    INNER JOIN master."Supplier" s    ON s."SupplierId"        = d."SupplierId"

    WHERE d."CompanyId" = p_company_id

      AND d."BranchId"  = p_branch_id

      AND (v_search_pattern IS NULL OR (

              d."DocumentNumber" ILIKE v_search_pattern

           OR s."SupplierName"   ILIKE v_search_pattern

           OR COALESCE(a."PaymentReference", '') ILIKE v_search_pattern

          ))

      AND (p_codigo       IS NULL OR s."SupplierCode" = p_codigo)

      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code);



    -- Retornar pagina solicitada

    RETURN QUERY

    SELECT

        a."PayableApplicationId",

        a."PayableApplicationId",

        d."PayableDocumentId",

        s."SupplierCode",

        s."SupplierCode",

        s."SupplierName",

        d."DocumentType",

        d."DocumentType",

        d."DocumentNumber",

        d."DocumentNumber",

        a."ApplyDate",

        a."ApplyDate",

        a."AppliedAmount",

        a."AppliedAmount",

        d."CurrencyCode",

        a."PaymentReference",

        a."PaymentReference",

        d."PendingAmount",

        d."TotalAmount",

        d."Status",

        v_total

    FROM ap."PayableApplication" a

    INNER JOIN ap."PayableDocument" d ON d."PayableDocumentId" = a."PayableDocumentId"

    INNER JOIN master."Supplier" s    ON s."SupplierId"        = d."SupplierId"

    WHERE d."CompanyId" = p_company_id

      AND d."BranchId"  = p_branch_id

      AND (v_search_pattern IS NULL OR (

              d."DocumentNumber" ILIKE v_search_pattern

           OR s."SupplierName"   ILIKE v_search_pattern

DROP FUNCTION IF EXISTSPaymentReference", '') ILIKE v_search_pattern

          ))

      AND (p_codigo       IS NULL OR s."SupplierCode" = p_codigo)

      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code)

    ORDER BY a."ApplyDate" DESC, a."PayableApplicationId" DESC

    LIMIT v_limit OFFSET v_offset;

END;

$function$
;

-- usp_ap_application_resolve
DROP FUNCTION IF EXISTS public.usp_ap_application_resolve(integer, integer, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_application_resolve(p_company_id integer, p_branch_id integer, p_document_number character varying, p_supplier_code character varying DEFAULT NULL::character varying, p_document_type character varying DEFAULT NULL::character varying)
 RETURNS TABLE("PayableDocumentId" bigint, "PendingAmount" numeric, "TotalAmount" numeric, "SupplierId" bigint, "CurrencyCode" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        d."PayableDocumentId",

        d."PendingAmount",

        d."TotalAmount",

        d."SupplierId",

        d."CurrencyCode"

    FROM ap."PayableDocument" d

    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"

    WHERE d."CompanyId"      = p_company_id

      AND d."BranchId"       = p_branch_id

      AND d."DocumentNumber" = p_document_number

      AND (p_supplier_code IS NULL OR s."SupplierCode" = p_supplier_code)

      AND (p_document_type IS NULL OR d."DocumentType" = p_document_type)

    ORDER BY d."PayableDocumentId" DESC

    LIMIT 1

    FOR UPDATE OF d;

END;

$function$
;

-- usp_ap_application_reverse
DROP FUNCTION IF EXISTS public.usp_ap_application_reverse(bigint, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_application_reverse(p_application_id bigint, p_updated_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE(ok integer, "NewPending" numeric, "Message" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_applied_amount       DECIMAL(18,2);

    v_payable_document_id  BIGINT;

    v_supplier_id          BIGINT;

    v_total_amount         DECIMAL(18,2);

    v_new_pending          DECIMAL(18,2);

BEGIN

    -- Obtener datos de la aplicacion con bloqueo

    SELECT a."AppliedAmount", a."PayableDocumentId"

    INTO v_applied_amount, v_payable_document_id

    FROM ap."PayableApplication" a

    WHERE a."PayableApplicationId" = p_application_id

    FOR UPDATE;



    -- Validar que la aplicacion existe

DROP FUNCTION IF EXISTS NULL THEN

        RETURN QUERY SELECT 0, NULL::DECIMAL(18,2),

            'Aplicacion de pago no encontrada.'::TEXT;

        RETURN;

    END IF;



    -- Obtener datos del documento asociado con bloqueo

    SELECT d."SupplierId", d."TotalAmount"

    INTO v_supplier_id, v_total_amount

    FROM ap."PayableDocument" d

    WHERE d."PayableDocumentId" = v_payable_document_id

    FOR UPDATE;



    -- Eliminar la aplicacion

    DELETE FROM ap."PayableApplication"

    WHERE "PayableApplicationId" = p_application_id;



    -- Calcular nuevo saldo pendiente

    SELECT d."TotalAmount" - COALESCE(SUM(a."AppliedAmount"), 0)

    INTO v_new_pending

    FROM ap."PayableDocument" d

    LEFT JOIN ap."PayableApplication" a ON a."PayableDocumentId" = d."PayableDocumentId"

    WHERE d."PayableDocumentId" = v_payable_document_id

    GROUP BY d."TotalAmount";



DROP FUNCTION IF EXISTSo

    UPDATE ap."PayableDocument"

    SET "PendingAmount"   = v_new_pending,

        "PaidFlag"        = (v_new_pending <= 0),

        "Status"          = CASE

                              WHEN v_new_pending <= 0           THEN 'PAID'

                              WHEN v_new_pending < v_total_amount THEN 'PARTIAL'

                              ELSE 'PENDING'

                            END,

        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',

DROP FUNCTION IF EXISTS= p_updated_by_user_id

    WHERE "PayableDocumentId" = v_payable_document_id;



    -- Recalcular saldo total del proveedor

    PERFORM usp_Master_Supplier_UpdateBalance(v_supplier_id, p_updated_by_user_id);



    -- Retornar resultado exitoso

    RETURN QUERY SELECT 1, v_new_pending,

        'Pago reversado correctamente.'::TEXT;

END;

$function$
;

-- usp_ap_application_update
DROP FUNCTION IF EXISTSblic.usp_ap_application_update(bigint, numeric, date, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_application_update(p_application_id bigint, p_amount numeric DEFAULT NULL::numeric, p_apply_date date DEFAULT NULL::date, p_payment_reference character varying DEFAULT NULL::character varying, p_currency_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE(ok integer, "Message" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_original_amount  DECIMAL(18,2);

    v_current_pending  DECIMAL(18,2);

    v_total_amount     DECIMAL(18,2);

    v_supplier_id      BIGINT;

    v_doc_currency     VARCHAR(10);

    v_doc_id           BIGINT;

    v_updated_amount   DECIMAL(18,2);

    v_delta            DECIMAL(18,2);

    v_new_pending      DECIMAL(18,2);

BEGIN

    -- Obtener aplicacion y documento con bloqueo

    SELECT a."AppliedAmount", a."PayableDocumentId",

           d."PendingAmount", d."TotalAmount", d."SupplierId", d."CurrencyCode"

    INTO v_original_amount, v_doc_id,

         v_current_pending, v_total_amount, v_supplier_id, v_doc_currency

    FROM ap."PayableApplication" a

    INNER JOIN ap."PayableDocument" d

DROP FUNCTION IF EXISTSentId" = a."PayableDocumentId"

    WHERE a."PayableApplicationId" = p_application_id

    FOR UPDATE;



    -- Validar que la aplicacion existe

    IF v_original_amount IS NULL THEN

        RETURN QUERY SELECT 0, 'Aplicacion de pago no encontrada.'::TEXT;

        RETURN;

    END IF;



    -- Validar moneda si se especifica

    IF p_currency_code IS NOT NULL

       AND UPPER(v_doc_currency)::character varying <> UPPER(p_currency_code)::character varying THEN

        RETURN QUERY SELECT 0, 'La moneda no coincide con el documento.'::TEXT;

        RETURN;

    END IF;



    -- Determinar nuevo monto (si no se pasa, mantener el original)

    v_updated_amount := COALESCE(p_amount, v_original_amount);

    v_delta := v_updated_amount - v_original_amount;



    -- Validar saldo si se incrementa

    IF v_delta > 0 AND v_current_pending < v_delta THEN

        RETURN QUERY SELECT 0,

            ('Saldo insuficiente en documento. Pendiente: '

             || v_current_pending::TEXT

             || ', Delta: ' || v_delta::TEXT)::TEXT;

        RETURN;

    END IF;
DROP FUNCTION IF EXISTS


    -- Calcular nuevo pendiente

    IF v_delta > 0 THEN

        v_new_pending := v_current_pending - v_delta;

    ELSIF v_delta < 0 THEN

        v_new_pending := CASE

            WHEN v_current_pending + ABS(v_delta) > v_total_amount THEN v_total_amount

            ELSE v_current_pending + ABS(v_delta)

        END;

    ELSE

        v_new_pending := v_current_pending;

    END IF;

DROP FUNCTION IF EXISTS

    -- Actualizar la aplicacion

    UPDATE ap."PayableApplication"

    SET "AppliedAmount"    = v_updated_amount,

        "ApplyDate"        = COALESCE(p_apply_date, "ApplyDate"),

        "PaymentReference" = COALESCE(p_payment_reference, "PaymentReference")

    WHERE "PayableApplicationId" = p_application_id;



    -- Actualizar documento si hubo cambio de monto

    IF v_delta <> 0 THEN
DROP FUNCTION IF EXISTS
        UPDATE ap."PayableDocument"

        SET "PendingAmount"   = v_new_pending,

            "PaidFlag"        = (v_new_pending <= 0),

            "Status"          = CASE

                                  WHEN v_new_pending <= 0           THEN 'PAID'

                                  WHEN v_new_pending < v_total_amount THEN 'PARTIAL'

                                  ELSE 'PENDING'

                                END,

            "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'

        WHERE "PayableDocumentId" = v_doc_id;



        -- Recalcular saldo del proveedor

        PERFORM usp_Master_Supplier_UpdateBalance(v_supplier_id);

    END IF;



    RETURN QUERY SELECT 1, 'Pago actualizado correctamente.'::TEXT;

END;

$function$
;

-- usp_ap_balance_getbysupplier
DROP FUNCTION IF EXISTS public.usp_ap_balance_getbysupplier(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_balance_getbysupplier(p_cod_proveedor character varying)
 RETURNS TABLE("saldoTotal" numeric, saldo30 numeric, saldo60 numeric, saldo90 numeric, saldo91 numeric)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        COALESCE(s."TotalBalance", 0)::NUMERIC(18,2),

        0::NUMERIC(18,2),

        0::NUMERIC(18,2),

        0::NUMERIC(18,2),

        0::NUMERIC(18,2)

    FROM master."Supplier" s

    WHERE s."SupplierCode" = p_cod_proveedor

      AND s."IsDeleted" = FALSE;

END;

$function$
;

-- usp_ap_payable_applypayment
DROP FUNCTION IF EXISTS public.usp_ap_payable_applypayment(character varying, date, character varying, character varying, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_payable_applypayment(p_cod_proveedor character varying, p_fecha date DEFAULT NULL::date, p_request_id character varying DEFAULT NULL::character varying, p_num_pago character varying DEFAULT NULL::character varying, p_documentos_json jsonb DEFAULT NULL::jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

DROP FUNCTION IF EXISTS

    v_apply_date  DATE := COALESCE(p_fecha, (NOW() AT TIME ZONE 'UTC')::DATE);

    v_applied     NUMERIC(18,2) := 0;

    v_doc         RECORD;

    v_doc_id      BIGINT;

    v_pending     NUMERIC(18,2);

    v_apply_amt   NUMERIC(18,2);

BEGIN

    SELECT s."SupplierId" INTO v_supplier_id

    FROM master."Supplier" s WHERE s."SupplierCode" = p_cod_proveedor AND s."IsDeleted" = FALSE

    LIMIT 1;



    IF v_supplier_id IS NULL OR v_supplier_id <= 0 THEN

        RETURN QUERY SELECT -1, 'Proveedor no encontrado en esquema canonico'::VARCHAR(500);

        RETURN;

    END IF;



    -- Iterar documentos JSONB

    FOR v_doc IN SELECT * FROM jsonb_array_elements(p_documentos_json) AS r
DROP FUNCTION IF EXISTS
    LOOP

        v_doc_id := NULL;

        v_pending := NULL;



        SELECT pd."PayableDocumentId", pd."PendingAmount"

        INTO v_doc_id, v_pending

        FROM ap."PayableDocument" pd

        WHERE pd."SupplierId" = v_supplier_id

          AND pd."DocumentType" = v_doc.r->>'tipoDoc'

          AND pd."DocumentNumber" = v_doc.r->>'numDoc'

          AND pd."Status" <> 'VOIDED'

        ORDER BY pd."PayableDocumentId" DESC

        LIMIT 1

        FOR UPDATE;



        v_apply_amt := CASE

            WHEN v_pending IS NULL THEN 0

            WHEN (v_doc.r->>'montoAplicar')::NUMERIC(18,2) < v_pending THEN (v_doc.r->>'montoAplicar')::NUMERIC(18,2)

            ELSE v_pending

        END;

DROP FUNCTION IF EXISTS

        IF v_apply_amt > 0 AND v_doc_id IS NOT NULL THEN

            INSERT INTO ap."PayableApplication" (

                "PayableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference"

            ) VALUES (v_doc_id, v_apply_date, v_apply_amt, CONCAT(p_request_id, ':', p_num_pago));



            UPDATE ap."PayableDocument"

            SET "PendingAmount" = CASE WHEN "PendingAmount" - v_apply_amt < 0 THEN 0

                                       ELSE "PendingAmount" - v_apply_amt END,

                "PaidFlag" = CASE WHEN "PendingAmount" - v_apply_amt <= 0 THEN TRUE ELSE FALSE END,

                "Status" = CASE

                             WHEN "PendingAmount" - v_apply_amt <= 0 THEN 'PAID'

                             WHEN "PendingAmount" - v_apply_amt < "TotalAmount" THEN 'PARTIAL'

                             ELSE 'PENDING'

                           END,

                "UpdatedAt" = NOW() AT TIME ZONE 'UTC'

            WHERE "PayableDocumentId" = v_doc_id;



            v_applied := v_applied + v_apply_amt;

        END IF;

    END LOOP;



    IF v_applied <= 0 THEN

        RAISE EXCEPTION 'No hay montos aplicables para pagar';

    END IF;



DROP FUNCTION IF EXISTSr"

    SET "TotalBalance" = (

            SELECT COALESCE(SUM("PendingAmount"), 0) FROM ap."PayableDocument"

            WHERE "SupplierId" = v_supplier_id AND "Status" <> 'VOIDED'

        ),

        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'

    WHERE "SupplierId" = v_supplier_id;



    RETURN QUERY SELECT 1, ('Pago aplicado exitosamente. Monto: ' || v_applied::TEXT)::VARCHAR(500);



EXCEPTION WHEN OTHERS THEN

    RETURN QUERY SELECT -99, ('Error en pago: ' || SQLERRM)::VARCHAR(500);

END;

$function$
;

-- usp_ap_payable_applypayment
DROP FUNCTION IF EXISTS public.usp_ap_payable_applypayment(character varying, date, character varying, character varying, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_payable_applypayment(p_cod_proveedor character varying, p_fecha date DEFAULT NULL::date, p_request_id character varying DEFAULT NULL::character varying, p_num_pago character varying DEFAULT NULL::character varying, p_documentos_json text DEFAULT NULL::text)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_supplier_id BIGINT;

    v_apply_date  DATE := COALESCE(p_fecha, (NOW() AT TIME ZONE 'UTC')::DATE);

    v_applied     NUMERIC(18,2) := 0;

    rec           RECORD;

    v_doc_id      BIGINT;

    v_pending     NUMERIC(18,2);

    v_apply_amount NUMERIC(18,2);

BEGIN

    -- Resolver proveedor

    SELECT "SupplierId" INTO v_supplier_id

    FROM master."Supplier"

    WHERE "SupplierCode" = p_cod_proveedor

      AND "IsDeleted" = FALSE

    LIMIT 1;



    IF v_supplier_id IS NULL OR v_supplier_id <= 0 THEN

        RETURN QUERY SELECT -1, 'Proveedor no encontrado en esquema canonico'::TEXT;

DROP FUNCTION IF EXISTS

    END IF;



    FOR rec IN

        SELECT

            elem->>'tipoDoc'      AS tipo_doc,

            elem->>'numDoc'       AS num_doc,

            (elem->>'montoAplicar')::NUMERIC(18,2) AS monto_aplicar

        FROM jsonb_array_elements(p_documentos_json::JSONB) AS elem

    LOOP

        v_doc_id := NULL;

        v_pending := NULL;



        SELECT pd."PayableDocumentId", pd."PendingAmount"

DROP FUNCTION IF EXISTSending

        FROM ap."PayableDocument" pd

        WHERE pd."SupplierId"     = v_supplier_id

          AND pd."DocumentType"   = rec.tipo_doc

          AND pd."DocumentNumber" = rec.num_doc

          AND pd."Status" <> 'VOIDED'

        ORDER BY pd."PayableDocumentId" DESC

        LIMIT 1

        FOR UPDATE;



        v_apply_amount := CASE

            WHEN v_pending IS NULL THEN 0

            WHEN rec.monto_aplicar < v_pending THEN rec.monto_aplicar

            ELSE v_pending

        END;



        IF v_apply_amount > 0 AND v_doc_id IS NOT NULL THEN

            INSERT INTO ap."PayableApplication" (

                "PayableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference"

            )

            VALUES (

                v_doc_id, v_apply_date, v_apply_amount,

                CONCAT(p_request_id, ':', p_num_pago)

            );



            UPDATE ap."PayableDocument"

            SET "PendingAmount" = CASE WHEN "PendingAmount" - v_apply_amount < 0 THEN 0

                                       ELSE "PendingAmount" - v_apply_amount END,

                "PaidFlag" = CASE WHEN "PendingAmount" - v_apply_amount <= 0 THEN TRUE ELSE FALSE END,

                "Status" = CASE

                             WHEN "PendingAmount" - v_apply_amount <= 0 THEN 'PAID'

                             WHEN "PendingAmount" - v_apply_amount < "TotalAmount" THEN 'PARTIAL'

                             ELSE 'PENDING'

                           END,

                "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
DROP FUNCTION IF EXISTS
            WHERE "PayableDocumentId" = v_doc_id;



            v_applied := v_applied + v_apply_amount;

        END IF;

    END LOOP;



    IF v_applied <= 0 THEN

        RETURN QUERY SELECT -2, 'No hay montos aplicables para pagar'::TEXT;

        RETURN;

    END IF;



    UPDATE master."Supplier"

    SET "TotalBalance" = (

            SELECT COALESCE(SUM("PendingAmount"), 0)

            FROM ap."PayableDocument"

            WHERE "SupplierId" = v_supplier_id

              AND "Status" <> 'VOIDED'

        ),

        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'

    WHERE "SupplierId" = v_supplier_id;



    RETURN QUERY SELECT 1, 'Pago aplicado en esquema canonico'::TEXT;



EXCEPTION WHEN OTHERS THEN

    RETURN QUERY SELECT -99, ('Error aplicando pago canonico: ' || SQLERRM)::TEXT;

END;

$function$
;

-- usp_ap_payable_create
DROP FUNCTION IF EXISTS public.usp_ap_payable_create(character varying, character varying, character varying, date, date, character varying, numeric, numeric, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_payable_create(p_codigo character varying, p_document_type character varying DEFAULT 'COMPRA'::character varying, p_document_number character varying DEFAULT NULL::character varying, p_issue_date date DEFAULT NULL::date, p_due_date date DEFAULT NULL::date, p_currency_code character varying DEFAULT 'USD'::character varying, p_total_amount numeric DEFAULT 0, p_pending_amount numeric DEFAULT NULL::numeric, p_notes character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_company_id INT;

    v_branch_id  INT;

    v_supplier_id BIGINT;

    v_pend       NUMERIC(18,2) := COALESCE(p_pending_amount, p_total_amount);

BEGIN

    SELECT "CompanyId" INTO v_company_id

    FROM cfg."Company" WHERE "IsDeleted" = FALSE

    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId" LIMIT 1;



    SELECT "BranchId" INTO v_branch_id

    FROM cfg."Branch" WHERE "CompanyId" = v_company_id AND "IsDeleted" = FALSE

    ORDER BY CASE WHEN "BranchCode" = 'MAIN' THEN 0 ELSE 1 END, "BranchId" LIMIT 1;



    SELECT "SupplierId" INTO v_supplier_id

    FROM master."Supplier"

    WHERE "CompanyId" = v_company_id AND "SupplierCode" = p_codigo AND "IsDeleted" = FALSE

    LIMIT 1;



    IF v_supplier_id IS NULL THEN

        RETURN QUERY SELECT -1, 'proveedor_no_encontrado'::TEXT;
DROP FUNCTION IF EXISTS
        RETURN;

    END IF;



    INSERT INTO ap."PayableDocument" (

        "CompanyId", "BranchId", "SupplierId", "DocumentType", "DocumentNumber",

        "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount",

        "PaidFlag", "Status", "Notes", "CreatedAt", "UpdatedAt"

    )

    VALUES (

        v_company_id, v_branch_id, v_supplier_id, p_document_type, p_document_number,

DROP FUNCTION IF EXISTSate, (NOW() AT TIME ZONE 'UTC')::DATE),

        COALESCE(p_due_date, p_issue_date, (NOW() AT TIME ZONE 'UTC')::DATE),

        p_currency_code, p_total_amount, v_pend,

        CASE WHEN v_pend <= 0 THEN TRUE ELSE FALSE END,

        CASE WHEN v_pend <= 0 THEN 'PAID' WHEN v_pend < p_total_amount THEN 'PARTIAL' ELSE 'PENDING' END,

        p_notes, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'

    );



    RETURN QUERY SELECT 1, 'ok'::TEXT;

END;

$function$
;

-- usp_ap_payable_getbyid
DROP FUNCTION IF EXISTS public.usp_ap_payable_getbyid(bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_payable_getbyid(p_id bigint)
 RETURNS TABLE(id bigint, codigo character varying, nombre character varying, tipo character varying, documento character varying, fecha date, "fechaVence" date, total numeric, pendiente numeric, estado character varying, moneda character varying, observacion character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        d."PayableDocumentId", s."SupplierCode", s."SupplierName",

        d."DocumentType", d."DocumentNumber", d."IssueDate", d."DueDate",

        d."TotalAmount", d."PendingAmount", d."Status",

        d."CurrencyCode", d."Notes"

    FROM ap."PayableDocument" d

    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"

    WHERE d."PayableDocumentId" = p_id;

END;

$function$
;

-- usp_ap_payable_getpending
DROP FUNCTION IF EXISTS public.usp_ap_payable_getpending(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_payable_getpending(p_cod_proveedor character varying)
 RETURNS TABLE("tipoDoc" character varying, "numDoc" character varying, fecha date, pendiente numeric, total numeric)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        d."DocumentType",

        d."DocumentNumber",

        d."IssueDate",

        d."PendingAmount",

        d."TotalAmount"

    FROM ap."PayableDocument" d

    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"

    WHERE s."SupplierCode" = p_cod_proveedor

      AND d."PendingAmount" > 0

      AND d."Status" IN ('PENDING', 'PARTIAL')

    ORDER BY d."IssueDate" ASC, d."PayableDocumentId" ASC;

END;

$function$
;

-- usp_ap_payable_list
DROP FUNCTION IF EXISTS public.usp_ap_payable_list(character varying, character varying, character varying, date, date, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_payable_list(p_cod_proveedor character varying DEFAULT NULL::character varying, p_tipo_doc character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "codProveedor" character varying, "tipoDoc" character varying, "numDoc" character varying, fecha date, total numeric, pendiente numeric, estado character varying, observacion character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_total BIGINT;

BEGIN
DROP FUNCTION IF EXISTS
    SELECT COUNT(1) INTO v_total

    FROM ap."PayableDocument" d

    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"

    WHERE (p_cod_proveedor IS NULL OR s."SupplierCode" = p_cod_proveedor)

      AND (p_tipo_doc IS NULL OR d."DocumentType" = p_tipo_doc)

      AND (p_estado IS NULL OR d."Status" = p_estado)

      AND (p_fecha_desde IS NULL OR d."IssueDate" >= p_fecha_desde)

      AND (p_fecha_hasta IS NULL OR d."IssueDate" <= p_fecha_hasta);



    RETURN QUERY

    SELECT

        v_total,

        s."SupplierCode",

        d."DocumentType",

        d."DocumentNumber",

        d."IssueDate",

        d."TotalAmount",

        d."PendingAmount",

        d."Status",

        d."Notes"

    FROM ap."PayableDocument" d

    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"

    WHERE (p_cod_proveedor IS NULL OR s."SupplierCode" = p_cod_proveedor)

      AND (p_tipo_doc IS NULL OR d."DocumentType" = p_tipo_doc)

      AND (p_estado IS NULL OR d."Status" = p_estado)

      AND (p_fecha_desde IS NULL OR d."IssueDate" >= p_fecha_desde)

      AND (p_fecha_hasta IS NULL OR d."IssueDate" <= p_fecha_hasta)

    ORDER BY d."IssueDate" DESC, d."PayableDocumentId" DESC

    LIMIT p_limit OFFSET p_offset;

END;

$function$
;

-- usp_ap_payable_listfull
DROP FUNCTION IF EXISTS public.usp_ap_payable_listfull(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_payable_listfull(p_search character varying DEFAULT NULL::character varying, p_codigo character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, id bigint, codigo character varying, nombre character varying, tipo character varying, documento character varying, fecha date, "fechaVence" date, total numeric, pendiente numeric, estado character varying, moneda character varying, observacion character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_company_id INT;

    v_branch_id  INT;

    v_total      BIGINT;

    v_search_pat VARCHAR(202) := CASE WHEN p_search IS NOT NULL THEN '%' || p_search || '%' ELSE NULL END;

BEGIN

    SELECT "CompanyId" INTO v_company_id

    FROM cfg."Company" WHERE "IsDeleted" = FALSE

    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
DROP FUNCTION IF EXISTS
    LIMIT 1;



    SELECT "BranchId" INTO v_branch_id

    FROM cfg."Branch" WHERE "CompanyId" = v_company_id AND "IsDeleted" = FALSE

    ORDER BY CASE WHEN "BranchCode" = 'MAIN' THEN 0 ELSE 1 END, "BranchId"

    LIMIT 1;



    SELECT COUNT(1) INTO v_total

    FROM ap."PayableDocument" d

    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"

    WHERE d."CompanyId" = v_company_id

      AND d."BranchId"  = v_branch_id

      AND (v_search_pat IS NULL OR (d."DocumentNumber" ILIKE v_search_pat OR d."Notes" ILIKE v_search_pat OR s."SupplierName" ILIKE v_search_pat))

      AND (p_codigo IS NULL OR s."SupplierCode" = p_codigo);



    RETURN QUERY

    SELECT

        v_total,

        d."PayableDocumentId",

        s."SupplierCode",

        s."SupplierName",

        d."DocumentType",

        d."DocumentNumber",

        d."IssueDate",

        d."DueDate",
DROP FUNCTION IF EXISTS
        d."TotalAmount",

        d."PendingAmount",

        d."Status",

        d."CurrencyCode",

        d."Notes"

    FROM ap."PayableDocument" d

    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"

    WHERE d."CompanyId" = v_company_id

      AND d."BranchId"  = v_branch_id

      AND (v_search_pat IS NULL OR (d."DocumentNumber" ILIKE v_search_pat OR d."Notes" ILIKE v_search_pat OR s."SupplierName" ILIKE v_search_pat))
DROP FUNCTION IF EXISTS
      AND (p_codigo IS NULL OR s."SupplierCode" = p_codigo)

    ORDER BY d."IssueDate" DESC, d."PayableDocumentId" DESC

    LIMIT p_limit OFFSET p_offset;

END;

$function$
;

-- usp_ap_payable_update
DROP FUNCTION IF EXISTS public.usp_ap_payable_update(bigint, character varying, character varying, date, date, numeric, numeric, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_payable_update(p_id bigint, p_document_type character varying DEFAULT NULL::character varying, p_document_number character varying DEFAULT NULL::character varying, p_issue_date date DEFAULT NULL::date, p_due_date date DEFAULT NULL::date, p_total_amount numeric DEFAULT NULL::numeric, p_pending_amount numeric DEFAULT NULL::numeric, p_status character varying DEFAULT NULL::character varying, p_currency_code character varying DEFAULT NULL::character varying, p_notes character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    UPDATE ap."PayableDocument"

    SET "DocumentType"   = COALESCE(p_document_type, "DocumentType"),
DROP FUNCTION IF EXISTS
        "DocumentNumber" = COALESCE(p_document_number, "DocumentNumber"),

        "IssueDate"      = COALESCE(p_issue_date, "IssueDate"),

        "DueDate"        = COALESCE(p_due_date, "DueDate"),

        "TotalAmount"    = COALESCE(p_total_amount, "TotalAmount"),

        "PendingAmount"  = COALESCE(p_pending_amount, "PendingAmount"),

        "Status"         = COALESCE(p_status, "Status"),

        "CurrencyCode"   = COALESCE(p_currency_code, "CurrencyCode"),

        "Notes"          = COALESCE(p_notes, "Notes"),

        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'

    WHERE "PayableDocumentId" = p_id;



    RETURN QUERY SELECT 1, 'ok'::TEXT;

END;

$function$
;

-- usp_ap_payable_void
DROP FUNCTION IF EXISTS public.usp_ap_payable_void(bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ap_payable_void(p_id bigint)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    UPDATE ap."PayableDocument"

    SET "PendingAmount" = 0,
DROP FUNCTION IF EXISTS
        "PaidFlag"      = TRUE,

        "Status"        = 'VOIDED',

        "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'

    WHERE "PayableDocumentId" = p_id;



    RETURN QUERY SELECT 1, 'ok'::TEXT;

END;

$function$
;

-- usp_ar_application_apply
DROP FUNCTION IF EXISTS public.usp_ar_application_apply(bigint, numeric, character varying, date, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_application_apply(p_receivable_document_id bigint, p_amount numeric, p_payment_reference character varying DEFAULT NULL::character varying, p_apply_date date DEFAULT NULL::date, p_updated_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE(ok integer, "ApplicationId" bigint, "NewPending" numeric, "Message" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_apply_date       DATE := COALESCE(p_apply_date, (NOW() AT TIME ZONE 'UTC')::DATE);

    v_current_pending  DECIMAL(18,2);

    v_new_pending      DECIMAL(18,2);

    v_customer_id      BIGINT;

    v_total_amount     DECIMAL(18,2);

    v_application_id   BIGINT;

    v_doc_status       VARCHAR(20);

BEGIN

    -- Validaciones basicas

    IF p_amount IS NULL OR p_amount <= 0 THEN

        RETURN QUERY SELECT 0, NULL::BIGINT, NULL::DECIMAL(18,2),

DROP FUNCTION IF EXISTS ser mayor a cero.'::TEXT;

        RETURN;

    END IF;



    -- Obtener documento con bloqueo para evitar concurrencia

    SELECT d."PendingAmount", d."TotalAmount", d."CustomerId", d."Status"

    INTO v_current_pending, v_total_amount, v_customer_id, v_doc_status

    FROM ar."ReceivableDocument" d

    WHERE d."ReceivableDocumentId" = p_receivable_document_id

    FOR UPDATE;



    -- Validar que el documento existe

    IF v_current_pending IS NULL THEN
DROP FUNCTION IF EXISTS
        RETURN QUERY SELECT 0, NULL::BIGINT, NULL::DECIMAL(18,2),

            'Documento por cobrar no encontrado.'::TEXT;

        RETURN;

    END IF;



    -- Validar que el documento no este anulado

    IF v_doc_status = 'VOIDED' THEN

        RETURN QUERY SELECT 0, NULL::BIGINT, NULL::DECIMAL(18,2),

            'No se puede aplicar abono a un documento anulado.'::TEXT;

DROP FUNCTION IF EXISTS

    END IF;



    -- Validar que el monto no exceda el saldo pendiente

    IF p_amount > v_current_pending THEN

        RETURN QUERY SELECT 0, NULL::BIGINT, v_current_pending,

            ('El monto (' || p_amount::TEXT || ') excede el saldo pendiente (' || v_current_pending::TEXT || ').')::TEXT;
DROP FUNCTION IF EXISTS
        RETURN;

    END IF;



    -- Insertar la aplicacion (abono)

    INSERT INTO ar."ReceivableApplication" ("ReceivableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference")

    VALUES (p_receivable_document_id, v_apply_date, p_amount, p_payment_reference)

    RETURNING "ReceivableApplicationId" INTO v_application_id;
DROP FUNCTION IF EXISTS


    -- Calcular nuevo saldo pendiente

    v_new_pending := v_current_pending - p_amount;



    -- Actualizar documento

    UPDATE ar."ReceivableDocument"

    SET "PendingAmount"   = v_new_pending,

        "PaidFlag"        = (v_new_pending <= 0),

        "Status"          = CASE

                              WHEN v_new_pending <= 0           THEN 'PAID'

                              WHEN v_new_pending < v_total_amount THEN 'PARTIAL'

                              ELSE 'PENDING'

                            END,

        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',

        "UpdatedByUserId" = p_updated_by_user_id

DROP FUNCTION IF EXISTSentId" = p_receivable_document_id;



    -- Recalcular saldo total del cliente

    PERFORM usp_Master_Customer_UpdateBalance(v_customer_id, p_updated_by_user_id);



    -- Retornar resultado exitoso

    RETURN QUERY SELECT 1, v_application_id, v_new_pending,

        'Abono aplicado correctamente.'::TEXT;

END;

$function$
;

-- usp_ar_application_get
DROP FUNCTION IF EXISTS public.usp_ar_application_get(bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_application_get(p_application_id bigint)
 RETURNS TABLE("ReceivableApplicationId" bigint, "ReceivableDocumentId" bigint, "ApplyDate" date, "AppliedAmount" numeric, "PaymentReference" character varying, "CreatedAt" timestamp without time zone, "DocumentNumber" character varying, "DocumentType" character varying, "IssueDate" date, "DueDate" date, "CurrencyCode" character varying, "TotalAmount" numeric, "PendingAmount" numeric, "PaidFlag" boolean, "DocumentStatus" character varying, "DocumentNotes" character varying, "CustomerId" bigint, "CustomerCode" character varying, "CustomerName" character varying, "CustomerFiscalId" character varying)
 LANGUAGE plpgsql
DROP FUNCTION IF EXISTS

BEGIN

    RETURN QUERY

    SELECT

        a."ReceivableApplicationId",

        a."ReceivableDocumentId",

        a."ApplyDate",

        a."AppliedAmount",

        a."PaymentReference",

        a."CreatedAt",

        d."DocumentNumber",

        d."DocumentType",

        d."IssueDate",

        d."DueDate",

        d."CurrencyCode",

        d."TotalAmount",

        d."PendingAmount",
DROP FUNCTION IF EXISTS
        d."PaidFlag",

        d."Status",

        d."Notes",

        c."CustomerId",

        c."CustomerCode",

        c."CustomerName",

        c."FiscalId"

    FROM ar."ReceivableApplication" a

DROP FUNCTION IF EXISTSbleDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"

    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"

    WHERE a."ReceivableApplicationId" = p_application_id;

END;

$function$
;

-- usp_ar_application_getbycontext
DROP FUNCTION IF EXISTSblic.usp_ar_application_getbycontext(bigint, integer, integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_application_getbycontext(p_application_id bigint, p_company_id integer, p_branch_id integer, p_currency_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Id" bigint, "ApplicationId" bigint, "DocumentoId" bigint, "CODIGO" character varying, "Codigo" character varying, "NOMBRE" character varying, "TIPO_DOC" character varying, "TipoDoc" character varying, "DOCUMENTO" character varying, "Num_fact" character varying, "FECHA" date, "Fecha" date, "MONTO" numeric, "Monto" numeric, "MONEDA" character varying, "REFERENCIA" character varying, "Concepto" character varying, "PENDIENTE" numeric, "TOTAL" numeric, "ESTADO_DOC" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        a."ReceivableApplicationId",

        a."ReceivableApplicationId",

        d."ReceivableDocumentId",
DROP FUNCTION IF EXISTS
        c."CustomerCode",

        c."CustomerCode",

        c."CustomerName",

        d."DocumentType",

        d."DocumentType",

DROP FUNCTION IF EXISTS,

        d."DocumentNumber",

        a."ApplyDate",

        a."ApplyDate",

        a."AppliedAmount",

        a."AppliedAmount",

DROP FUNCTION IF EXISTS

        a."PaymentReference",

        a."PaymentReference",

        d."PendingAmount",

        d."TotalAmount",

        d."Status"

    FROM ar."ReceivableApplication" a
DROP FUNCTION IF EXISTS
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"

    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"

    WHERE a."ReceivableApplicationId" = p_application_id

      AND d."CompanyId"  = p_company_id

      AND d."BranchId"   = p_branch_id

      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code)

    LIMIT 1;

DROP FUNCTION IF EXISTS

$function$
;

-- usp_ar_application_list
DROP FUNCTION IF EXISTS public.usp_ar_application_list(bigint, character varying, date, date, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_application_list(p_customer_id bigint DEFAULT NULL::bigint, p_document_type character varying DEFAULT NULL::character varying, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("ReceivableApplicationId" bigint, "ReceivableDocumentId" bigint, "ApplyDate" date, "AppliedAmount" numeric, "PaymentReference" character varying, "CreatedAt" timestamp without time zone, "DocumentNumber" character varying, "DocumentType" character varying, "TotalAmount" numeric, "PendingAmount" numeric, "DocumentStatus" character varying, "CustomerId" bigint, "CustomerCode" character varying, "CustomerName" character varying, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_page   INT := GREATEST(COALESCE(p_page, 1), 1);

    v_limit  INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 500);

    v_offset INT := (v_page - 1) * v_limit;

    v_total  BIGINT;

BEGIN

    -- Contar registros totales que cumplen los filtros

    SELECT COUNT(*) INTO v_total

    FROM ar."ReceivableApplication" a

    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"

DROP FUNCTION IF EXISTS IS NULL OR d."CustomerId"    = p_customer_id)

      AND (p_document_type IS NULL OR d."DocumentType"  = p_document_type)

      AND (p_from_date     IS NULL OR a."ApplyDate"    >= p_from_date)

      AND (p_to_date       IS NULL OR a."ApplyDate"    <= p_to_date);



    -- Retornar pagina solicitada

    RETURN QUERY

    SELECT

        a."ReceivableApplicationId",

        a."ReceivableDocumentId",

        a."ApplyDate",

        a."AppliedAmount",

        a."PaymentReference",

        a."CreatedAt",

        d."DocumentNumber",

        d."DocumentType",

        d."TotalAmount",

        d."PendingAmount",

        d."Status",

        c."CustomerId",

        c."CustomerCode",

        c."CustomerName",

        v_total

    FROM ar."ReceivableApplication" a

    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
DROP FUNCTION IF EXISTS
    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"

    WHERE (p_customer_id   IS NULL OR d."CustomerId"    = p_customer_id)

      AND (p_document_type IS NULL OR d."DocumentType"  = p_document_type)

      AND (p_from_date     IS NULL OR a."ApplyDate"    >= p_from_date)

      AND (p_to_date       IS NULL OR a."ApplyDate"    <= p_to_date)

    ORDER BY a."ApplyDate" DESC, a."ReceivableApplicationId" DESC

    LIMIT v_limit OFFSET v_offset;
DROP FUNCTION IF EXISTS
END;

$function$
;

-- usp_ar_application_listbycontext
DROP FUNCTION IF EXISTS public.usp_ar_application_listbycontext(integer, integer, character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_application_listbycontext(p_company_id integer, p_branch_id integer, p_search character varying DEFAULT NULL::character varying, p_codigo character varying DEFAULT NULL::character varying, p_currency_code character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("Id" bigint, "ApplicationId" bigint, "DocumentoId" bigint, "CODIGO" character varying, "Codigo" character varying, "NOMBRE" character varying, "TIPO_DOC" character varying, "TipoDoc" character varying, "DOCUMENTO" character varying, "Num_fact" character varying, "FECHA" date, "Fecha" date, "MONTO" numeric, "Monto" numeric, "MONEDA" character varying, "REFERENCIA" character varying, "Concepto" character varying, "PENDIENTE" numeric, "TOTAL" numeric, "ESTADO_DOC" character varying, "TotalCount" bigint)
 LANGUAGE plpgsql
DROP FUNCTION IF EXISTS

DECLARE

    v_page           INT := GREATEST(COALESCE(p_page, 1), 1);

    v_limit          INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 500);

    v_offset         INT := (v_page - 1) * v_limit;

    v_search_pattern VARCHAR(102);

    v_total          BIGINT;

BEGIN

    IF p_search IS NOT NULL AND LENGTH(TRIM(p_search)) > 0 THEN
DROP FUNCTION IF EXISTS
        v_search_pattern := '%' || TRIM(p_search) || '%';

    END IF;



    -- Contar registros totales

    SELECT COUNT(*) INTO v_total

    FROM ar."ReceivableApplication" a

    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"

    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"

    WHERE d."CompanyId" = p_company_id

      AND d."BranchId"  = p_branch_id

      AND (v_search_pattern IS NULL

           OR d."DocumentNumber"    ILIKE v_search_pattern

           OR c."CustomerName"      ILIKE v_search_pattern

           OR a."PaymentReference"  ILIKE v_search_pattern)

      AND (p_codigo       IS NULL OR c."CustomerCode" = p_codigo)

      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code);



    -- Retornar pagina solicitada

    RETURN QUERY

    SELECT

        a."ReceivableApplicationId",

        a."ReceivableApplicationId",

        d."ReceivableDocumentId",

        c."CustomerCode",

        c."CustomerCode",

        c."CustomerName",

        d."DocumentType",

        d."DocumentType",

        d."DocumentNumber",

        d."DocumentNumber",

        a."ApplyDate",

        a."ApplyDate",

        a."AppliedAmount",

        a."AppliedAmount",

        d."CurrencyCode",

        a."PaymentReference",

        a."PaymentReference",

        d."PendingAmount",

        d."TotalAmount",

        d."Status",

        v_total

    FROM ar."ReceivableApplication" a

    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"

    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"

    WHERE d."CompanyId" = p_company_id

      AND d."BranchId"  = p_branch_id

      AND (v_search_pattern IS NULL

           OR d."DocumentNumber"    ILIKE v_search_pattern

           OR c."CustomerName"      ILIKE v_search_pattern

           OR a."PaymentReference"  ILIKE v_search_pattern)

      AND (p_codigo       IS NULL OR c."CustomerCode" = p_codigo)

      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code)

    ORDER BY a."ApplyDate" DESC, a."ReceivableApplicationId" DESC

    LIMIT v_limit OFFSET v_offset;

END;

$function$
;

-- usp_ar_application_resolve
DROP FUNCTION IF EXISTS public.usp_ar_application_resolve(integer, integer, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_application_resolve(p_company_id integer, p_branch_id integer, p_document_number character varying, p_customer_code character varying DEFAULT NULL::character varying, p_document_type character varying DEFAULT NULL::character varying)
 RETURNS TABLE("ReceivableDocumentId" bigint, "PendingAmount" numeric, "TotalAmount" numeric, "CustomerId" bigint, "CurrencyCode" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        d."ReceivableDocumentId",

        d."PendingAmount",

        d."TotalAmount",

        d."CustomerId",

        d."CurrencyCode"

    FROM ar."ReceivableDocument" d

    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"

    WHERE d."CompanyId"       = p_company_id

      AND d."BranchId"        = p_branch_id

      AND d."DocumentNumber"  = p_document_number

      AND (p_customer_code IS NULL OR c."CustomerCode" = p_customer_code)

      AND (p_document_type IS NULL OR d."DocumentType" = p_document_type)

    ORDER BY d."ReceivableDocumentId" DESC

    LIMIT 1

    FOR UPDATE OF d;

END;

$function$
;

-- usp_ar_application_reverse
DROP FUNCTION IF EXISTS public.usp_ar_application_reverse(bigint, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_application_reverse(p_application_id bigint, p_updated_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE(ok integer, "NewPending" numeric, "Message" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_applied_amount          DECIMAL(18,2);

    v_receivable_document_id  BIGINT;

    v_customer_id             BIGINT;

    v_total_amount            DECIMAL(18,2);

    v_new_pending             DECIMAL(18,2);

BEGIN

    -- Obtener datos de la aplicacion con bloqueo

    SELECT a."AppliedAmount", a."ReceivableDocumentId"

    INTO v_applied_amount, v_receivable_document_id

    FROM ar."ReceivableApplication" a

    WHERE a."ReceivableApplicationId" = p_application_id

    FOR UPDATE;



    -- Validar que la aplicacion existe

    IF v_applied_amount IS NULL THEN

        RETURN QUERY SELECT 0, NULL::DECIMAL(18,2),

            'Aplicacion de cobro no encontrada.'::TEXT;

        RETURN;

    END IF;



    -- Obtener datos del documento asociado con bloqueo

DROP FUNCTION IF EXISTS d."TotalAmount"

    INTO v_customer_id, v_total_amount

    FROM ar."ReceivableDocument" d

    WHERE d."ReceivableDocumentId" = v_receivable_document_id

    FOR UPDATE;



    -- Eliminar la aplicacion

    DELETE FROM ar."ReceivableApplication"

    WHERE "ReceivableApplicationId" = p_application_id;



    -- Calcular nuevo saldo pendiente

    SELECT d."TotalAmount" - COALESCE(SUM(a."AppliedAmount"), 0)

    INTO v_new_pending

    FROM ar."ReceivableDocument" d

    LEFT JOIN ar."ReceivableApplication" a ON a."ReceivableDocumentId" = d."ReceivableDocumentId"

    WHERE d."ReceivableDocumentId" = v_receivable_document_id

    GROUP BY d."TotalAmount";



    -- Actualizar documento

    UPDATE ar."ReceivableDocument"

    SET "PendingAmount"   = v_new_pending,

        "PaidFlag"        = (v_new_pending <= 0),

        "Status"          = CASE

                              WHEN v_new_pending <= 0           THEN 'PAID'

                              WHEN v_new_pending < v_total_amount THEN 'PARTIAL'

                              ELSE 'PENDING'

                            END,

        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',

        "UpdatedByUserId" = p_updated_by_user_id

    WHERE "ReceivableDocumentId" = v_receivable_document_id;



    -- Recalcular saldo total del cliente

    PERFORM usp_Master_Customer_UpdateBalance(v_customer_id, p_updated_by_user_id);



    -- Retornar resultado exitoso

    RETURN QUERY SELECT 1, v_new_pending,

        'Abono reversado correctamente.'::TEXT;

END;

$function$
;

-- usp_ar_application_update
DROP FUNCTION IF EXISTS public.usp_ar_application_update(bigint, numeric, date, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_application_update(p_application_id bigint, p_amount numeric DEFAULT NULL::numeric, p_apply_date date DEFAULT NULL::date, p_payment_reference character varying DEFAULT NULL::character varying, p_currency_code character varying DEFAULT NULL::character varying)
 RETURNS TABLE(ok integer, "Message" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_current_amount   DECIMAL(18,2);

    v_doc_id           BIGINT;

    v_pending          DECIMAL(18,2);

    v_total_amount     DECIMAL(18,2);

    v_customer_id      BIGINT;

    v_doc_currency     VARCHAR(10);

    v_delta            DECIMAL(18,2);

    v_new_pending      DECIMAL(18,2);

    v_new_status       VARCHAR(20);

    v_new_paid_flag    BOOLEAN;

    v_amount           DECIMAL(18,2);

BEGIN

    -- Obtener aplicacion y documento con bloqueo

    SELECT a."AppliedAmount", a."ReceivableDocumentId",

           d."PendingAmount", d."TotalAmount", d."CustomerId", d."CurrencyCode"

    INTO v_current_amount, v_doc_id,

         v_pending, v_total_amount, v_customer_id, v_doc_currency

    FROM ar."ReceivableApplication" a

    INNER JOIN ar."ReceivableDocument" d

        ON d."ReceivableDocumentId" = a."ReceivableDocumentId"

    WHERE a."ReceivableApplicationId" = p_application_id

    FOR UPDATE;



    -- Validar que la aplicacion existe

    IF v_current_amount IS NULL THEN

        RETURN QUERY SELECT 0, 'Aplicacion de cobro no encontrada.'::TEXT;

        RETURN;

    END IF;



    -- Validar moneda si se especifica

    IF p_currency_code IS NOT NULL AND UPPER(v_doc_currency)::character varying <> UPPER(p_currency_code)::character varying THEN

        RETURN QUERY SELECT 0, 'La moneda del documento no coincide con la solicitada.'::TEXT;

        RETURN;

    END IF;



    -- Determinar el nuevo monto (si no se especifica, mantener el actual)

    v_amount := COALESCE(p_amount, v_current_amount);



    -- Validar monto positivo

    IF v_amount <= 0 THEN

        RETURN QUERY SELECT 0, 'El monto debe ser mayor a cero.'::TEXT;

        RETURN;

    END IF;



    -- Calcular delta y nuevo saldo pendiente

    v_delta := v_amount - v_current_amount;



    IF v_delta > 0 AND v_pending < v_delta THEN

        RETURN QUERY SELECT 0,

            ('Saldo insuficiente en el documento. Pendiente actual: ' || v_pending::TEXT)::TEXT;

        RETURN;

    END IF;



    IF v_delta > 0 THEN

        v_new_pending := v_pending - v_delta;

    ELSIF v_delta < 0 THEN

        v_new_pending := CASE

                           WHEN v_pending + ABS(v_delta) > v_total_amount THEN v_total_amount

                           ELSE v_pending + ABS(v_delta)

                         END;

    ELSE

        v_new_pending := v_pending;

    END IF;
DROP FUNCTION IF EXISTS


    -- Calcular nuevo estado del documento

    v_new_paid_flag := (v_new_pending <= 0);

    v_new_status    := CASE

                         WHEN v_new_pending <= 0           THEN 'PAID'

                         WHEN v_new_pending < v_total_amount THEN 'PARTIAL'

                         ELSE 'PENDING'

                       END;



    -- Actualizar la aplicacion

    UPDATE ar."ReceivableApplication"
DROP FUNCTION IF EXISTS
    SET "AppliedAmount"    = v_amount,

        "ApplyDate"        = COALESCE(p_apply_date, "ApplyDate"),

        "PaymentReference" = COALESCE(p_payment_reference, "PaymentReference")

    WHERE "ReceivableApplicationId" = p_application_id;



    -- Actualizar documento si hubo cambio de monto

    IF v_delta <> 0 THEN

        UPDATE ar."ReceivableDocument"
DROP FUNCTION IF EXISTS
        SET "PendingAmount"   = v_new_pending,

            "Status"          = v_new_status,

            "PaidFlag"        = v_new_paid_flag,

            "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'

        WHERE "ReceivableDocumentId" = v_doc_id;



        -- Recalcular saldo total del cliente

        PERFORM usp_Master_Customer_UpdateBalance(v_customer_id);

    END IF;


DROP FUNCTION IF EXISTS
    RETURN QUERY SELECT 1, 'Abono actualizado correctamente.'::TEXT;

END;

$function$
;

-- usp_ar_balance_getbycustomer
DROP FUNCTION IF EXISTS public.usp_ar_balance_getbycustomer(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_balance_getbycustomer(p_cod_cliente character varying)
 RETURNS TABLE("saldoTotal" numeric, saldo30 numeric, saldo60 numeric, saldo90 numeric, saldo91 numeric)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        COALESCE(c."TotalBalance", 0)::NUMERIC(18,2),

DROP FUNCTION IF EXISTS

        0::NUMERIC(18,2),

        0::NUMERIC(18,2),

        0::NUMERIC(18,2)

    FROM master."Customer" c

    WHERE c."CustomerCode" = p_cod_cliente

      AND c."IsDeleted" = FALSE;

END;

$function$
;

-- usp_ar_receivable_applypayment
DROP FUNCTION IF EXISTS public.usp_ar_receivable_applypayment(character varying, date, character varying, character varying, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_receivable_applypayment(p_cod_cliente character varying, p_fecha date DEFAULT NULL::date, p_request_id character varying DEFAULT NULL::character varying, p_num_recibo character varying DEFAULT NULL::character varying, p_documentos_json text DEFAULT NULL::text)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DROP FUNCTION IF EXISTS

    v_customer_id BIGINT;

    v_apply_date  DATE := COALESCE(p_fecha, (NOW() AT TIME ZONE 'UTC')::DATE);

    v_applied     NUMERIC(18,2) := 0;

    rec           RECORD;

    v_doc_id      BIGINT;

    v_pending     NUMERIC(18,2);

    v_apply_amount NUMERIC(18,2);

BEGIN

    -- Resolver cliente

    SELECT "CustomerId" INTO v_customer_id

    FROM master."Customer"

    WHERE "CustomerCode" = p_cod_cliente

      AND "IsDeleted" = FALSE

    LIMIT 1;



    IF v_customer_id IS NULL OR v_customer_id <= 0 THEN

        RETURN QUERY SELECT -1, 'Cliente no encontrado en esquema canonico'::TEXT;

        RETURN;

    END IF;
DROP FUNCTION IF EXISTS


    -- Iterar documentos desde JSON

    FOR rec IN

        SELECT

            elem->>'tipoDoc'      AS tipo_doc,

            elem->>'numDoc'       AS num_doc,

            (elem->>'montoAplicar')::NUMERIC(18,2) AS monto_aplicar

        FROM jsonb_array_elements(p_documentos_json::JSONB) AS elem

    LOOP

DROP FUNCTION IF EXISTS

        v_pending := NULL;



        -- Buscar documento con lock

        SELECT rd."ReceivableDocumentId", rd."PendingAmount"

        INTO v_doc_id, v_pending

        FROM ar."ReceivableDocument" rd

        WHERE rd."CustomerId"     = v_customer_id

          AND rd."DocumentType"   = rec.tipo_doc

          AND rd."DocumentNumber" = rec.num_doc

          AND rd."Status" <> 'VOIDED'

        ORDER BY rd."ReceivableDocumentId" DESC

        LIMIT 1

        FOR UPDATE;



        v_apply_amount := CASE

            WHEN v_pending IS NULL THEN 0

            WHEN rec.monto_aplicar < v_pending THEN rec.monto_aplicar

            ELSE v_pending

        END;



        IF v_apply_amount > 0 AND v_doc_id IS NOT NULL THEN

            -- Insertar aplicacion

            INSERT INTO ar."ReceivableApplication" (

                "ReceivableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference"

            )

            VALUES (

                v_doc_id, v_apply_date, v_apply_amount,

                CONCAT(p_request_id, ':', p_num_recibo)

            );



            -- Actualizar documento

            UPDATE ar."ReceivableDocument"

            SET "PendingAmount" = CASE WHEN "PendingAmount" - v_apply_amount < 0 THEN 0

DROP FUNCTION IF EXISTS             ELSE "PendingAmount" - v_apply_amount END,

                "PaidFlag" = CASE WHEN "PendingAmount" - v_apply_amount <= 0 THEN TRUE ELSE FALSE END,

                "Status" = CASE

                             WHEN "PendingAmount" - v_apply_amount <= 0 THEN 'PAID'

                             WHEN "PendingAmount" - v_apply_amount < "TotalAmount" THEN 'PARTIAL'

                             ELSE 'PENDING'

                           END,

                "UpdatedAt" = NOW() AT TIME ZONE 'UTC'

            WHERE "ReceivableDocumentId" = v_doc_id;



DROP FUNCTION IF EXISTS_applied + v_apply_amount;

        END IF;

    END LOOP;



    IF v_applied <= 0 THEN

        RETURN QUERY SELECT -2, 'No hay montos aplicables para cobrar'::TEXT;

        RETURN;

    END IF;



    -- Recalcular saldo del cliente

    UPDATE master."Customer"

    SET "TotalBalance" = (

            SELECT COALESCE(SUM("PendingAmount"), 0)

            FROM ar."ReceivableDocument"

            WHERE "CustomerId" = v_customer_id

              AND "Status" <> 'VOIDED'

        ),

        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'

    WHERE "CustomerId" = v_customer_id;



    RETURN QUERY SELECT 1, 'Cobro aplicado en esquema canonico'::TEXT;



EXCEPTION WHEN OTHERS THEN

    RETURN QUERY SELECT -99, ('Error aplicando cobro canonico: ' || SQLERRM)::TEXT;

END;
DROP FUNCTION IF EXISTS
$function$
;

-- usp_ar_receivable_applypayment
DROP FUNCTION IF EXISTS public.usp_ar_receivable_applypayment(character varying, date, character varying, character varying, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_receivable_applypayment(p_cod_cliente character varying, p_fecha date DEFAULT NULL::date, p_request_id character varying DEFAULT NULL::character varying, p_num_recibo character varying DEFAULT NULL::character varying, p_documentos_json jsonb DEFAULT NULL::jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_customer_id BIGINT;

    v_apply_date  DATE := COALESCE(p_fecha, (NOW() AT TIME ZONE 'UTC')::DATE);

    v_applied     NUMERIC(18,2) := 0;

    v_doc         RECORD;

DROP FUNCTION IF EXISTS

    v_pending     NUMERIC(18,2);

    v_apply_amt   NUMERIC(18,2);

BEGIN

    SELECT c."CustomerId" INTO v_customer_id

    FROM master."Customer" c WHERE c."CustomerCode" = p_cod_cliente AND c."IsDeleted" = FALSE

    LIMIT 1;



    IF v_customer_id IS NULL OR v_customer_id <= 0 THEN

        RETURN QUERY SELECT -1, 'Cliente no encontrado en esquema canonico'::VARCHAR(500);

        RETURN;

    END IF;



    -- Iterar documentos JSONB

    FOR v_doc IN SELECT * FROM jsonb_array_elements(p_documentos_json) AS r

    LOOP

        v_doc_id := NULL;

        v_pending := NULL;



        SELECT rd."ReceivableDocumentId", rd."PendingAmount"

        INTO v_doc_id, v_pending

        FROM ar."ReceivableDocument" rd

        WHERE rd."CustomerId" = v_customer_id

          AND rd."DocumentType" = v_doc.r->>'tipoDoc'

          AND rd."DocumentNumber" = v_doc.r->>'numDoc'

          AND rd."Status" <> 'VOIDED'

        ORDER BY rd."ReceivableDocumentId" DESC

        LIMIT 1
DROP FUNCTION IF EXISTS
        FOR UPDATE;



        v_apply_amt := CASE

            WHEN v_pending IS NULL THEN 0

            WHEN (v_doc.r->>'montoAplicar')::NUMERIC(18,2) < v_pending THEN (v_doc.r->>'montoAplicar')::NUMERIC(18,2)

            ELSE v_pending

        END;



        IF v_apply_amt > 0 AND v_doc_id IS NOT NULL THEN
DROP FUNCTION IF EXISTS
            INSERT INTO ar."ReceivableApplication" (

                "ReceivableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference"

            ) VALUES (v_doc_id, v_apply_date, v_apply_amt, CONCAT(p_request_id, ':', p_num_recibo));



            UPDATE ar."ReceivableDocument"

            SET "PendingAmount" = CASE WHEN "PendingAmount" - v_apply_amt < 0 THEN 0

                                       ELSE "PendingAmount" - v_apply_amt END,

                "PaidFlag" = CASE WHEN "PendingAmount" - v_apply_amt <= 0 THEN TRUE ELSE FALSE END,

                "Status" = CASE

                             WHEN "PendingAmount" - v_apply_amt <= 0 THEN 'PAID'

                             WHEN "PendingAmount" - v_apply_amt < "TotalAmount" THEN 'PARTIAL'
DROP FUNCTION IF EXISTS
                             ELSE 'PENDING'

                           END,

                "UpdatedAt" = NOW() AT TIME ZONE 'UTC'

            WHERE "ReceivableDocumentId" = v_doc_id;



            v_applied := v_applied + v_apply_amt;

        END IF;

    END LOOP;



    IF v_applied <= 0 THEN

        RAISE EXCEPTION 'No hay montos aplicables para cobrar';

    END IF;



    UPDATE master."Customer"

    SET "TotalBalance" = (

            SELECT COALESCE(SUM("PendingAmount"), 0) FROM ar."ReceivableDocument"

            WHERE "CustomerId" = v_customer_id AND "Status" <> 'VOIDED'

        ),

        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'

    WHERE "CustomerId" = v_customer_id;



    RETURN QUERY SELECT 1, ('Cobro aplicado exitosamente. Monto: ' || v_applied::TEXT)::VARCHAR(500);



EXCEPTION WHEN OTHERS THEN

    RETURN QUERY SELECT -99, ('Error en cobro: ' || SQLERRM)::VARCHAR(500);

END;

$function$
;

-- usp_ar_receivable_create
DROP FUNCTION IF EXISTS public.usp_ar_receivable_create(character varying, character varying, character varying, date, date, character varying, numeric, numeric, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_receivable_create(p_codigo character varying, p_document_type character varying DEFAULT 'FACT'::character varying, p_document_number character varying DEFAULT NULL::character varying, p_issue_date date DEFAULT NULL::date, p_due_date date DEFAULT NULL::date, p_currency_code character varying DEFAULT 'USD'::character varying, p_total_amount numeric DEFAULT 0, p_pending_amount numeric DEFAULT NULL::numeric, p_notes character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_company_id  INT;

    v_branch_id   INT;

    v_customer_id BIGINT;

    v_pend        NUMERIC(18,2) := COALESCE(p_pending_amount, p_total_amount);

BEGIN

    SELECT "CompanyId" INTO v_company_id

    FROM cfg."Company" WHERE "IsDeleted" = FALSE

    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId" LIMIT 1;



    SELECT "BranchId" INTO v_branch_id

    FROM cfg."Branch" WHERE "CompanyId" = v_company_id AND "IsDeleted" = FALSE

    ORDER BY CASE WHEN "BranchCode" = 'MAIN' THEN 0 ELSE 1 END, "BranchId" LIMIT 1;



    SELECT "CustomerId" INTO v_customer_id

    FROM master."Customer"

    WHERE "CompanyId" = v_company_id AND "CustomerCode" = p_codigo AND "IsDeleted" = FALSE

    LIMIT 1;



    IF v_customer_id IS NULL THEN

        RETURN QUERY SELECT -1, 'cliente_no_encontrado'::TEXT;

        RETURN;

    END IF;



    INSERT INTO ar."ReceivableDocument" (

        "CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber",

        "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount",

        "PaidFlag", "Status", "Notes", "CreatedAt", "UpdatedAt"

    )

    VALUES (

        v_company_id, v_branch_id, v_customer_id, p_document_type, p_document_number,

        COALESCE(p_issue_date, (NOW() AT TIME ZONE 'UTC')::DATE),

        COALESCE(p_due_date, p_issue_date, (NOW() AT TIME ZONE 'UTC')::DATE),

        p_currency_code, p_total_amount, v_pend,

        CASE WHEN v_pend <= 0 THEN TRUE ELSE FALSE END,

        CASE WHEN v_pend <= 0 THEN 'PAID' WHEN v_pend < p_total_amount THEN 'PARTIAL' ELSE 'PENDING' END,

        p_notes, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'

    );



    RETURN QUERY SELECT 1, 'ok'::TEXT;

END;

$function$
;

-- usp_ar_receivable_getbyid
DROP FUNCTION IF EXISTS public.usp_ar_receivable_getbyid(bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_receivable_getbyid(p_id bigint)
 RETURNS TABLE(id bigint, codigo character varying, nombre character varying, tipo character varying, documento character varying, fecha date, "fechaVence" date, total numeric, pendiente numeric, estado character varying, moneda character varying, observacion character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        d."ReceivableDocumentId", c."CustomerCode", c."CustomerName",

        d."DocumentType", d."DocumentNumber", d."IssueDate", d."DueDate",

        d."TotalAmount", d."PendingAmount", d."Status",

        d."CurrencyCode", d."Notes"

    FROM ar."ReceivableDocument" d

    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"

    WHERE d."ReceivableDocumentId" = p_id;

END;

$function$
;

-- usp_ar_receivable_getpending
DROP FUNCTION IF EXISTS public.usp_ar_receivable_getpending(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_receivable_getpending(p_cod_cliente character varying)
 RETURNS TABLE("tipoDoc" character varying, "numDoc" character varying, fecha date, pendiente numeric, total numeric)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        d."DocumentType",

        d."DocumentNumber",

        d."IssueDate",

        d."PendingAmount",

        d."TotalAmount"

    FROM ar."ReceivableDocument" d

    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"

    WHERE c."CustomerCode" = p_cod_cliente

      AND d."PendingAmount" > 0

      AND d."Status" IN ('PENDING', 'PARTIAL')

    ORDER BY d."IssueDate" ASC, d."ReceivableDocumentId" ASC;

END;

$function$
;

-- usp_ar_receivable_list
DROP FUNCTION IF EXISTS public.usp_ar_receivable_list(character varying, character varying, character varying, date, date, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_receivable_list(p_cod_cliente character varying DEFAULT NULL::character varying, p_tipo_doc character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "codCliente" character varying, "tipoDoc" character varying, "numDoc" character varying, fecha date, total numeric, pendiente numeric, estado character varying, observacion character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_total BIGINT;

BEGIN

    SELECT COUNT(1) INTO v_total

    FROM ar."ReceivableDocument" d

    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"

    WHERE (p_cod_cliente IS NULL OR c."CustomerCode" = p_cod_cliente)

      AND (p_tipo_doc IS NULL OR d."DocumentType" = p_tipo_doc)

      AND (p_estado IS NULL OR d."Status" = p_estado)

      AND (p_fecha_desde IS NULL OR d."IssueDate" >= p_fecha_desde)

      AND (p_fecha_hasta IS NULL OR d."IssueDate" <= p_fecha_hasta);



    RETURN QUERY

    SELECT

        v_total,

        c."CustomerCode",

        d."DocumentType",

        d."DocumentNumber",

        d."IssueDate",

        d."TotalAmount",

        d."PendingAmount",

        d."Status",

        d."Notes"

    FROM ar."ReceivableDocument" d

    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"

    WHERE (p_cod_cliente IS NULL OR c."CustomerCode" = p_cod_cliente)

      AND (p_tipo_doc IS NULL OR d."DocumentType" = p_tipo_doc)

      AND (p_estado IS NULL OR d."Status" = p_estado)

      AND (p_fecha_desde IS NULL OR d."IssueDate" >= p_fecha_desde)

      AND (p_fecha_hasta IS NULL OR d."IssueDate" <= p_fecha_hasta)

    ORDER BY d."IssueDate" DESC, d."ReceivableDocumentId" DESC

    LIMIT p_limit OFFSET p_offset;

END;

$function$
;

-- usp_ar_receivable_listfull
DROP FUNCTION IF EXISTS public.usp_ar_receivable_listfull(character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_receivable_listfull(p_search character varying DEFAULT NULL::character varying, p_codigo character varying DEFAULT NULL::character varying, p_currency_code character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, id bigint, codigo character varying, nombre character varying, tipo character varying, documento character varying, fecha date, "fechaVence" date, total numeric, pendiente numeric, estado character varying, moneda character varying, observacion character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_company_id INT;

    v_branch_id  INT;

    v_total      BIGINT;

    v_search_pat VARCHAR(202) := CASE WHEN p_search IS NOT NULL THEN '%' || p_search || '%' ELSE NULL END;

BEGIN

    SELECT "CompanyId" INTO v_company_id

    FROM cfg."Company" WHERE "IsDeleted" = FALSE

    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId" LIMIT 1;



    SELECT "BranchId" INTO v_branch_id

    FROM cfg."Branch" WHERE "CompanyId" = v_company_id AND "IsDeleted" = FALSE

    ORDER BY CASE WHEN "BranchCode" = 'MAIN' THEN 0 ELSE 1 END, "BranchId" LIMIT 1;



    SELECT COUNT(1) INTO v_total

    FROM ar."ReceivableDocument" d

    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"

    WHERE d."CompanyId" = v_company_id

      AND d."BranchId"  = v_branch_id

      AND (v_search_pat IS NULL OR (d."DocumentNumber" ILIKE v_search_pat OR d."Notes" ILIKE v_search_pat OR c."CustomerName" ILIKE v_search_pat))

      AND (p_codigo IS NULL OR c."CustomerCode" = p_codigo)

      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code);



    RETURN QUERY

    SELECT

        v_total,

        d."ReceivableDocumentId", c."CustomerCode", c."CustomerName",

        d."DocumentType", d."DocumentNumber", d."IssueDate", d."DueDate",

        d."TotalAmount", d."PendingAmount", d."Status",

        d."CurrencyCode", d."Notes"

    FROM ar."ReceivableDocument" d

    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"

    WHERE d."CompanyId" = v_company_id

      AND d."BranchId"  = v_branch_id

      AND (v_search_pat IS NULL OR (d."DocumentNumber" ILIKE v_search_pat OR d."Notes" ILIKE v_search_pat OR c."CustomerName" ILIKE v_search_pat))

      AND (p_codigo IS NULL OR c."CustomerCode" = p_codigo)

      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code)

    ORDER BY d."IssueDate" DESC, d."ReceivableDocumentId" DESC

    LIMIT p_limit OFFSET p_offset;

END;

$function$
;

-- usp_ar_receivable_update
DROP FUNCTION IF EXISTS public.usp_ar_receivable_update(bigint, character varying, character varying, date, date, numeric, numeric, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_receivable_update(p_id bigint, p_document_type character varying DEFAULT NULL::character varying, p_document_number character varying DEFAULT NULL::character varying, p_issue_date date DEFAULT NULL::date, p_due_date date DEFAULT NULL::date, p_total_amount numeric DEFAULT NULL::numeric, p_pending_amount numeric DEFAULT NULL::numeric, p_status character varying DEFAULT NULL::character varying, p_currency_code character varying DEFAULT NULL::character varying, p_notes character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    UPDATE ar."ReceivableDocument"

    SET "DocumentType"   = COALESCE(p_document_type, "DocumentType"),

        "DocumentNumber" = COALESCE(p_document_number, "DocumentNumber"),

        "IssueDate"      = COALESCE(p_issue_date, "IssueDate"),

        "DueDate"        = COALESCE(p_due_date, "DueDate"),

        "TotalAmount"    = COALESCE(p_total_amount, "TotalAmount"),

        "PendingAmount"  = COALESCE(p_pending_amount, "PendingAmount"),

        "Status"         = COALESCE(p_status, "Status"),

        "CurrencyCode"   = COALESCE(p_currency_code, "CurrencyCode"),

        "Notes"          = COALESCE(p_notes, "Notes"),

        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'

    WHERE "ReceivableDocumentId" = p_id;



    RETURN QUERY SELECT 1, 'ok'::TEXT;

END;

$function$
;

-- usp_ar_receivable_void
DROP FUNCTION IF EXISTS public.usp_ar_receivable_void(bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_ar_receivable_void(p_id bigint)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    UPDATE ar."ReceivableDocument"

    SET "PendingAmount" = 0,

        "PaidFlag"      = TRUE,

        "Status"        = 'VOIDED',

        "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'

    WHERE "ReceivableDocumentId" = p_id;



    RETURN QUERY SELECT 1, 'ok'::TEXT;

END;

$function$
;

-- usp_bank_account_getbynumber
DROP FUNCTION IF EXISTS public.usp_bank_account_getbynumber(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_account_getbynumber(p_company_id integer, p_nro_cta character varying)
 RETURNS TABLE("bankAccountId" bigint, "nroCta" character varying, "bankName" character varying, balance numeric, "availableBalance" numeric)
 LANGUAGE plpgsql
AS $function$ BEGIN

    RETURN QUERY SELECT ba."BankAccountId",ba."AccountNumber",b."BankName",ba."Balance",ba."AvailableBalance"

    FROM fin."BankAccount" ba INNER JOIN fin."Bank" b ON b."BankId"=ba."BankId"

    WHERE ba."CompanyId"=p_company_id AND ba."AccountNumber"=p_nro_cta AND ba."IsActive"=TRUE AND b."IsActive"=TRUE

    ORDER BY ba."BankAccountId" LIMIT 1;

END; $function$
;

-- usp_bank_account_list
DROP FUNCTION IF EXISTS public.usp_bank_account_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_account_list(p_company_id integer)
 RETURNS TABLE("Nro_Cta" character varying, "Banco" character varying, "Descripcion" character varying, "Moneda" character varying, "Saldo" numeric, "Saldo_Disponible" numeric, "BancoNombre" character varying)
 LANGUAGE plpgsql
AS $function$ BEGIN

    RETURN QUERY SELECT ba."AccountNumber",b."BankName",ba."AccountName",ba."CurrencyCode",

        ba."Balance",ba."AvailableBalance",b."BankName"

    FROM fin."BankAccount" ba INNER JOIN fin."Bank" b ON b."BankId"=ba."BankId"

    WHERE ba."CompanyId"=p_company_id AND ba."IsActive"=TRUE AND b."IsActive"=TRUE

    ORDER BY b."BankName",ba."AccountNumber";

END; $function$
;

-- usp_bank_movement_create
DROP FUNCTION IF EXISTS public.usp_bank_movement_create(bigint, character varying, smallint, numeric, numeric, character varying, character varying, character varying, character varying, character varying, character varying, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_movement_create(p_bank_account_id bigint, p_movement_type character varying, p_movement_sign smallint, p_amount numeric, p_net_amount numeric, p_reference_no character varying DEFAULT NULL::character varying, p_beneficiary character varying DEFAULT NULL::character varying, p_concept character varying DEFAULT NULL::character varying, p_category_code character varying DEFAULT NULL::character varying, p_related_document_no character varying DEFAULT NULL::character varying, p_related_document_type character varying DEFAULT NULL::character varying, p_created_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying, "movementId" integer, "newBalance" numeric)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_current_balance NUMERIC(18,2); v_current_available NUMERIC(18,2);

    v_new_balance NUMERIC(18,2); v_new_available NUMERIC(18,2); v_movement_id INT;

BEGIN

    SELECT "Balance","AvailableBalance" INTO v_current_balance,v_current_available

    FROM fin."BankAccount" WHERE "BankAccountId"=p_bank_account_id FOR UPDATE;



    v_new_balance := ROUND(v_current_balance+p_net_amount,2);

    v_new_available := ROUND(COALESCE(v_current_available,v_current_balance)+p_net_amount,2);



    UPDATE fin."BankAccount" SET "Balance"=v_new_balance,"AvailableBalance"=v_new_available,

        "UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "BankAccountId"=p_bank_account_id;



    INSERT INTO fin."BankMovement" ("BankAccountId","MovementDate","MovementType","MovementSign",

        "Amount","NetAmount","ReferenceNo","Beneficiary","Concept","CategoryCode",

        "RelatedDocumentNo","RelatedDocumentType","BalanceAfter","CreatedByUserId")

    VALUES (p_bank_account_id,NOW() AT TIME ZONE 'UTC',p_movement_type,p_movement_sign,

        p_amount,p_net_amount,p_reference_no,p_beneficiary,p_concept,p_category_code,

        p_related_document_no,p_related_document_type,v_new_balance,p_created_by_user_id)

    RETURNING "BankMovementId" INTO v_movement_id;



    RETURN QUERY SELECT v_movement_id, v_new_balance::TEXT::VARCHAR(500), v_movement_id, v_new_balance;

END; $function$
;

-- usp_bank_movement_listbyaccount
DROP FUNCTION IF EXISTS public.usp_bank_movement_listbyaccount(integer, character varying, date, date, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_movement_listbyaccount(p_company_id integer, p_nro_cta character varying, p_from_date date DEFAULT NULL::date, p_to_date date DEFAULT NULL::date, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE(id bigint, "Nro_Cta" character varying, "Fecha" timestamp with time zone, "Tipo" character varying, "Nro_Ref" character varying, "Beneficiario" character varying, "Monto" numeric, "MontoNeto" numeric, "Concepto" character varying, "Categoria" character varying, "Documento_Relacionado" character varying, "Tipo_Doc_Rel" character varying, "SaldoPosterior" numeric, "Conciliado" boolean, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$

DECLARE v_total BIGINT;

BEGIN

    SELECT COUNT(1) INTO v_total FROM fin."BankMovement" m

    INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=m."BankAccountId"

    WHERE ba."CompanyId"=p_company_id AND ba."AccountNumber"=p_nro_cta

      AND (p_from_date IS NULL OR m."MovementDate">=p_from_date)

      AND (p_to_date IS NULL OR m."MovementDate"<=p_to_date);



    RETURN QUERY SELECT m."BankMovementId",ba."AccountNumber",m."MovementDate",m."MovementType",

        m."ReferenceNo",m."Beneficiary",m."Amount",m."NetAmount",m."Concept",m."CategoryCode",

        m."RelatedDocumentNo",m."RelatedDocumentType",m."BalanceAfter",m."IsReconciled",v_total

    FROM fin."BankMovement" m INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=m."BankAccountId"

    WHERE ba."CompanyId"=p_company_id AND ba."AccountNumber"=p_nro_cta

      AND (p_from_date IS NULL OR m."MovementDate">=p_from_date)

      AND (p_to_date IS NULL OR m."MovementDate"<=p_to_date)

    ORDER BY m."MovementDate" DESC, m."BankMovementId" DESC

    LIMIT p_limit OFFSET p_offset;

END; $function$
;

-- usp_bank_reconciliation_close
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_close(integer, numeric, character varying, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_close(p_id integer, p_bank_closing numeric, p_notes character varying DEFAULT NULL::character varying, p_closed_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying, diferencia numeric, estado character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_bank_account_id BIGINT; v_system_closing NUMERIC(18,2);

    v_difference NUMERIC(18,2); v_status VARCHAR(30);

BEGIN

    SELECT br."BankAccountId" INTO v_bank_account_id FROM fin."BankReconciliation" br

    WHERE br."BankReconciliationId"=p_id LIMIT 1;



    IF v_bank_account_id IS NULL THEN

        RETURN QUERY SELECT 0,'Conciliacion no encontrada'::VARCHAR(500),0::NUMERIC,''::VARCHAR; RETURN;

    END IF;



    SELECT ba."Balance" INTO v_system_closing FROM fin."BankAccount" ba

    WHERE ba."BankAccountId"=v_bank_account_id LIMIT 1;



    v_difference := ROUND(p_bank_closing-v_system_closing,2);

    v_status := CASE WHEN ABS(v_difference)<=0.01 THEN 'CLOSED' ELSE 'CLOSED_WITH_DIFF' END;



    UPDATE fin."BankReconciliation" SET "ClosingSystemBalance"=v_system_closing,

        "ClosingBankBalance"=p_bank_closing,"DifferenceAmount"=v_difference,"Status"=v_status,

        "Notes"=COALESCE(p_notes,"Notes"),"ClosedAt"=NOW() AT TIME ZONE 'UTC',

        "ClosedByUserId"=p_closed_by_user_id,"UpdatedAt"=NOW() AT TIME ZONE 'UTC'

    WHERE "BankReconciliationId"=p_id;



    RETURN QUERY SELECT 1,'OK'::VARCHAR(500),v_difference,v_status;

END; $function$
;

-- usp_bank_reconciliation_create
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_create(integer, integer, bigint, date, date, numeric, numeric, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_create(p_company_id integer, p_branch_id integer, p_bank_account_id bigint, p_from_date date, p_to_date date, p_opening numeric, p_closing numeric, p_created_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE v_id INT;

BEGIN

    INSERT INTO fin."BankReconciliation" ("CompanyId","BranchId","BankAccountId","DateFrom","DateTo",

        "OpeningSystemBalance","ClosingSystemBalance","OpeningBankBalance","CreatedByUserId")

    VALUES (p_company_id,p_branch_id,p_bank_account_id,p_from_date,p_to_date,

        p_opening,p_closing,p_opening,p_created_by_user_id)

    RETURNING "BankReconciliationId" INTO v_id;

    RETURN QUERY SELECT v_id,'OK'::VARCHAR(500);

END; $function$
;

-- usp_bank_reconciliation_getaccountnobyid
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getaccountnobyid(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getaccountnobyid(p_id integer)
 RETURNS TABLE("accountNo" character varying)
 LANGUAGE plpgsql
AS $function$ BEGIN

    RETURN QUERY SELECT ba."AccountNumber" FROM fin."BankReconciliation" r

    INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=r."BankAccountId"

    WHERE r."BankReconciliationId"=p_id LIMIT 1;

END; $function$
;

-- usp_bank_reconciliation_getbyid
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getbyid(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getbyid(p_company_id integer, p_id integer)
 RETURNS TABLE("ID" integer, "Nro_Cta" character varying, "Fecha_Desde" character varying, "Fecha_Hasta" character varying, "Saldo_Inicial_Sistema" numeric, "Saldo_Final_Sistema" numeric, "Saldo_Inicial_Banco" numeric, "Saldo_Final_Banco" numeric, "Diferencia" numeric, "Estado" character varying, "Observaciones" character varying, "Banco" character varying)
 LANGUAGE plpgsql
AS $function$ BEGIN

    RETURN QUERY SELECT r."BankReconciliationId"::INT, ba."AccountNumber",

        TO_CHAR(r."DateFrom",'YYYY-MM-DD')::VARCHAR, TO_CHAR(r."DateTo",'YYYY-MM-DD')::VARCHAR,

        r."OpeningSystemBalance",r."ClosingSystemBalance",r."OpeningBankBalance",

        r."ClosingBankBalance",r."DifferenceAmount",r."Status",r."Notes",b."BankName"

    FROM fin."BankReconciliation" r

    INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=r."BankAccountId"

    INNER JOIN fin."Bank" b ON b."BankId"=ba."BankId"

    WHERE r."CompanyId"=p_company_id AND r."BankReconciliationId"=p_id LIMIT 1;

END; $function$
;

-- usp_bank_reconciliation_getnettotal
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getnettotal(bigint, date, date) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getnettotal(p_bank_account_id bigint, p_from_date date, p_to_date date)
 RETURNS TABLE("netTotal" numeric)
 LANGUAGE plpgsql
AS $function$ BEGIN

    RETURN QUERY SELECT COALESCE(SUM("NetAmount"),0) FROM fin."BankMovement"

    WHERE "BankAccountId"=p_bank_account_id AND ("MovementDate")::DATE BETWEEN p_from_date AND p_to_date;

END; $function$
;

-- usp_bank_reconciliation_getopenforaccount
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getopenforaccount(integer, bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getopenforaccount(p_company_id integer, p_bank_account_id bigint)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$ BEGIN

    RETURN QUERY SELECT br."BankReconciliationId" FROM fin."BankReconciliation" br

    WHERE br."CompanyId"=p_company_id AND br."BankAccountId"=p_bank_account_id AND br."Status"='OPEN'

    ORDER BY br."BankReconciliationId" DESC LIMIT 1;

END; $function$
;

-- usp_bank_reconciliation_getpendingstatements
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getpendingstatements(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getpendingstatements(p_id integer)
 RETURNS TABLE(id bigint, "Fecha" timestamp with time zone, "Descripcion" character varying, "Referencia" character varying, "Tipo" character varying, "Monto" numeric, "Saldo" numeric)
 LANGUAGE plpgsql
AS $function$ BEGIN

    RETURN QUERY SELECT sl."StatementLineId",sl."StatementDate",sl."DescriptionText",sl."ReferenceNo",

        sl."EntryType",sl."Amount",sl."Balance"

    FROM fin."BankStatementLine" sl WHERE sl."ReconciliationId"=p_id AND sl."IsMatched"=FALSE

    ORDER BY sl."StatementDate" DESC, sl."StatementLineId" DESC;

END; $function$
;

-- usp_bank_reconciliation_getsystemmovements
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getsystemmovements(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getsystemmovements(p_id integer)
 RETURNS TABLE(id bigint, "Fecha" timestamp with time zone, "Tipo" character varying, "Nro_Ref" character varying, "Beneficiario" character varying, "Concepto" character varying, "Monto" numeric, "MontoNeto" numeric, "SaldoPosterior" numeric, "Conciliado" boolean)
 LANGUAGE plpgsql
AS $function$ BEGIN

    RETURN QUERY SELECT m."BankMovementId",m."MovementDate",m."MovementType",m."ReferenceNo",

        m."Beneficiary",m."Concept",m."Amount",m."NetAmount",m."BalanceAfter",m."IsReconciled"

    FROM fin."BankMovement" m

    INNER JOIN fin."BankReconciliation" r ON r."BankAccountId"=m."BankAccountId"

    WHERE r."BankReconciliationId"=p_id AND (m."MovementDate")::DATE BETWEEN r."DateFrom" AND r."DateTo"

    ORDER BY m."MovementDate" DESC, m."BankMovementId" DESC;

END; $function$
;

-- usp_bank_reconciliation_list
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_list(integer, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_list(p_company_id integer, p_nro_cta character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("ID" integer, "Nro_Cta" character varying, "Fecha_Desde" character varying, "Fecha_Hasta" character varying, "Saldo_Inicial_Sistema" numeric, "Saldo_Final_Sistema" numeric, "Saldo_Inicial_Banco" numeric, "Saldo_Final_Banco" numeric, "Diferencia" numeric, "Estado" character varying, "Observaciones" character varying, "Banco" character varying, "Pendientes" bigint, "Conciliados" bigint, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$

DECLARE v_total BIGINT;

BEGIN

    SELECT COUNT(1) INTO v_total FROM fin."BankReconciliation" r

    INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=r."BankAccountId"

    WHERE r."CompanyId"=p_company_id

      AND (p_nro_cta IS NULL OR ba."AccountNumber"=p_nro_cta)

      AND (p_estado IS NULL OR r."Status"=p_estado);



    RETURN QUERY SELECT r."BankReconciliationId"::INT, ba."AccountNumber",

        TO_CHAR(r."DateFrom",'YYYY-MM-DD')::VARCHAR, TO_CHAR(r."DateTo",'YYYY-MM-DD')::VARCHAR,

        r."OpeningSystemBalance",r."ClosingSystemBalance",r."OpeningBankBalance",

        r."ClosingBankBalance",r."DifferenceAmount",r."Status",r."Notes",b."BankName",

        (SELECT COUNT(1) FROM fin."BankStatementLine" s WHERE s."ReconciliationId"=r."BankReconciliationId" AND s."IsMatched"=FALSE),

        (SELECT COUNT(1) FROM fin."BankStatementLine" s WHERE s."ReconciliationId"=r."BankReconciliationId" AND s."IsMatched"=TRUE),

        v_total

    FROM fin."BankReconciliation" r

    INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=r."BankAccountId"

    INNER JOIN fin."Bank" b ON b."BankId"=ba."BankId"

    WHERE r."CompanyId"=p_company_id

      AND (p_nro_cta IS NULL OR ba."AccountNumber"=p_nro_cta)

      AND (p_estado IS NULL OR r."Status"=p_estado)

    ORDER BY r."BankReconciliationId" DESC

    LIMIT p_limit OFFSET p_offset;

END; $function$
;

-- usp_bank_reconciliation_matchmovement
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_matchmovement(bigint, bigint, bigint, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_matchmovement(p_reconciliation_id bigint, p_movement_id bigint, p_statement_id bigint DEFAULT NULL::bigint, p_matched_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_account_id BIGINT; v_expected_type VARCHAR(12); v_move_amount NUMERIC(18,2);

BEGIN

    SELECT br."BankAccountId" INTO v_account_id FROM fin."BankReconciliation" br

    WHERE br."BankReconciliationId"=p_reconciliation_id LIMIT 1;



    IF v_account_id IS NULL THEN

        RETURN QUERY SELECT 0,'Conciliacion no encontrada'::VARCHAR(500); RETURN;

    END IF;



    IF NOT EXISTS (SELECT 1 FROM fin."BankMovement" WHERE "BankMovementId"=p_movement_id AND "BankAccountId"=v_account_id) THEN

        RETURN QUERY SELECT 0,'Movimiento no encontrado'::VARCHAR(500); RETURN;

    END IF;



    IF p_statement_id IS NULL OR p_statement_id=0 THEN

        SELECT CASE WHEN "MovementSign"<0 THEN 'DEBITO' ELSE 'CREDITO' END, "Amount"

        INTO v_expected_type, v_move_amount FROM fin."BankMovement" WHERE "BankMovementId"=p_movement_id LIMIT 1;



        SELECT sl."StatementLineId" INTO p_statement_id FROM fin."BankStatementLine" sl

        WHERE sl."ReconciliationId"=p_reconciliation_id AND sl."IsMatched"=FALSE

          AND sl."EntryType"=v_expected_type AND ABS(sl."Amount"-v_move_amount)<=0.01

        ORDER BY sl."StatementDate", sl."StatementLineId" LIMIT 1;

    END IF;



    IF NOT EXISTS (SELECT 1 FROM fin."BankReconciliationMatch"

        WHERE "ReconciliationId"=p_reconciliation_id AND "BankMovementId"=p_movement_id) THEN

        INSERT INTO fin."BankReconciliationMatch" ("ReconciliationId","BankMovementId","StatementLineId","MatchedByUserId")

        VALUES (p_reconciliation_id, p_movement_id,

                CASE WHEN p_statement_id>0 THEN p_statement_id ELSE NULL END, p_matched_by_user_id);

    END IF;



    UPDATE fin."BankMovement" SET "IsReconciled"=TRUE,"ReconciledAt"=NOW() AT TIME ZONE 'UTC',

        "ReconciliationId"=p_reconciliation_id WHERE "BankMovementId"=p_movement_id;



    IF p_statement_id IS NOT NULL AND p_statement_id>0 THEN

        UPDATE fin."BankStatementLine" SET "IsMatched"=TRUE,"MatchedAt"=NOW() AT TIME ZONE 'UTC'

        WHERE "StatementLineId"=p_statement_id;

    END IF;



    RETURN QUERY SELECT 1,'Movimiento conciliado'::VARCHAR(500);

END; $function$
;

-- usp_bank_resolvescope
DROP FUNCTION IF EXISTS public.usp_bank_resolvescope() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_resolvescope()
 RETURNS TABLE("companyId" integer, "branchId" integer, "systemUserId" integer)
 LANGUAGE plpgsql
AS $function$ BEGIN

    RETURN QUERY SELECT c."CompanyId",b."BranchId",su."UserId"

    FROM cfg."Company" c

    INNER JOIN cfg."Branch" b ON b."CompanyId"=c."CompanyId" AND b."BranchCode"='MAIN'

    LEFT JOIN sec."User" su ON su."UserCode"='SYSTEM'

    WHERE c."CompanyCode"='DEFAULT' ORDER BY c."CompanyId",b."BranchId" LIMIT 1;

END; $function$
;

-- usp_bank_resolveuserid
DROP FUNCTION IF EXISTS public.usp_bank_resolveuserid(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_resolveuserid(p_code character varying)
 RETURNS TABLE("userId" integer)
 LANGUAGE plpgsql
AS $function$ BEGIN

    RETURN QUERY SELECT u."UserId" FROM sec."User" u WHERE UPPER(u."UserCode")::character varying=UPPER(p_code)::character varying ORDER BY u."UserId" LIMIT 1;

END; $function$
;

-- usp_bank_statementline_insert
DROP FUNCTION IF EXISTS public.usp_bank_statementline_insert(bigint, timestamp with time zone, character varying, character varying, character varying, numeric, numeric, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_bank_statementline_insert(bigint, timestamp, character varying, character varying, character varying, numeric, numeric, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_statementline_insert(p_reconciliation_id bigint, p_statement_date timestamp, p_description_text character varying DEFAULT NULL::character varying, p_reference_no character varying DEFAULT NULL::character varying, p_entry_type character varying DEFAULT NULL::character varying, p_amount numeric DEFAULT NULL::numeric, p_balance numeric DEFAULT NULL::numeric, p_created_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE v_id INT;

BEGIN

    INSERT INTO fin."BankStatementLine" ("ReconciliationId","StatementDate","DescriptionText","ReferenceNo",

        "EntryType","Amount","Balance","CreatedByUserId")

    VALUES (p_reconciliation_id,p_statement_date,p_description_text,p_reference_no,

        p_entry_type,p_amount,p_balance,p_created_by_user_id)

    RETURNING "StatementLineId" INTO v_id;

    RETURN QUERY SELECT v_id,'OK'::VARCHAR(500);

END; $function$
;

-- usp_cxc_aplicar_cobro
DROP FUNCTION IF EXISTS public.usp_cxc_aplicar_cobro(character varying, character varying, character varying, numeric, character varying, character varying, jsonb, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_cxc_aplicar_cobro(p_request_id character varying, p_cod_cliente character varying, p_fecha character varying, p_monto_total numeric, p_cod_usuario character varying, p_observaciones character varying DEFAULT ''::character varying, p_documentos_json jsonb DEFAULT NULL::jsonb, p_formas_pago_json jsonb DEFAULT NULL::jsonb)
 RETURNS TABLE("NumRecibo" character varying, "Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_resultado     INT := 0;
    v_mensaje       VARCHAR(500) := '';
    v_num_recibo    VARCHAR(50) := '';
    v_fecha_date    DATE;
    v_customer_id   BIGINT;
    v_receivable_id BIGINT;
    v_pending       NUMERIC(18,2);
    v_total         NUMERIC(18,2);
    v_apply         NUMERIC(18,2);
    v_applied_total NUMERIC(18,2) := 0;
    v_doc           RECORD;
    v_dup_ref       VARCHAR(150);
BEGIN
    -- -------------------------------------------------------
    -- Validar fecha
    -- -------------------------------------------------------
    BEGIN
        v_fecha_date := p_fecha::DATE;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT
            ''::VARCHAR(50),
            -91,
            ('Fecha invalida: ' || COALESCE(p_fecha, 'NULL'))::VARCHAR(500);
        RETURN;
    END;

    -- -------------------------------------------------------
    -- Buscar cliente
    -- -------------------------------------------------------
    SELECT c."CustomerId"
      INTO v_customer_id
      FROM master."Customer" c
     WHERE c."CustomerCode" = p_cod_cliente
       AND c."IsDeleted" = FALSE
     LIMIT 1;

    IF v_customer_id IS NULL THEN
        RETURN QUERY SELECT
            ''::VARCHAR(50),
            -1,
            ('Cliente no encontrado: ' || p_cod_cliente)::VARCHAR(500);
        RETURN;
    END IF;

    -- -------------------------------------------------------
    -- Validar JSON de documentos
    -- -------------------------------------------------------
    IF p_documentos_json IS NULL THEN
        RETURN QUERY SELECT
            ''::VARCHAR(50),
            -2,
            'DocumentosJson invalido'::VARCHAR(500);
        RETURN;
    END IF;

    -- Verificar que haya al menos un documento valido
    IF NOT EXISTS (
        SELECT 1
          FROM jsonb_array_elements(p_documentos_json) AS elem
         WHERE COALESCE(NULLIF(elem->>'numDoc', ''::character varying), '')::character varying <> ''
    ) THEN
        RETURN QUERY SELECT
            ''::VARCHAR(50),
            -3,
            'No se recibieron documentos validos para aplicar'::VARCHAR(500);
        RETURN;
    END IF;

    -- -------------------------------------------------------
    -- Generar numero de recibo
    -- -------------------------------------------------------
    v_num_recibo := 'RCB-' || TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYYMMDDHH24MISS');

    -- -------------------------------------------------------
    -- Idempotencia: verificar si ya se proceso este RequestId
    -- -------------------------------------------------------
    SELECT SUBSTRING(ra."PaymentReference" FROM POSITION(':' IN ra."PaymentReference") + 1)
      INTO v_dup_ref
      FROM ar."ReceivableApplication" ra
     INNER JOIN ar."ReceivableDocument" rd
        ON rd."ReceivableDocumentId" = ra."ReceivableDocumentId"
     WHERE rd."CustomerId" = v_customer_id
       AND ra."PaymentReference" LIKE p_request_id || ':%'
     ORDER BY ra."ReceivableApplicationId" DESC
     LIMIT 1;

    IF v_dup_ref IS NOT NULL THEN
        RETURN QUERY SELECT
            v_dup_ref::VARCHAR(50),
            1,
            ('Duplicado idempotente. Recibo: ' || COALESCE(v_dup_ref, ''))::VARCHAR(500);
        RETURN;
    END IF;

    -- -------------------------------------------------------
    -- Iterar documentos y aplicar cobros
    -- -------------------------------------------------------
    FOR v_doc IN
        SELECT
            UPPER(COALESCE(NULLIF(elem->>'tipoDoc', ''::character varying), 'FACT')::character varying)::character varying AS tipo_doc,
            COALESCE(NULLIF(elem->>'numDoc', ''::character varying), '')::character varying             AS num_doc,
            COALESCE(NULLIF(elem->>'montoAplicar', ''::character varying), '0')::character varying::NUMERIC(18,2) AS monto_aplicar
          FROM jsonb_array_elements(p_documentos_json) AS elem
         WHERE COALESCE(NULLIF(elem->>'numDoc', ''::character varying), '')::character varying <> ''
    LOOP
        -- Buscar documento pendiente
        SELECT rd."ReceivableDocumentId",
               rd."PendingAmount",
               rd."TotalAmount"
          INTO v_receivable_id, v_pending, v_total
          FROM ar."ReceivableDocument" rd
         WHERE rd."CustomerId" = v_customer_id
           AND rd."DocumentType" = v_doc.tipo_doc
           AND rd."DocumentNumber" = v_doc.num_doc
           AND rd."Status" <> 'VOIDED'
         ORDER BY rd."ReceivableDocumentId" DESC
         LIMIT 1
           FOR UPDATE;

        IF v_receivable_id IS NOT NULL AND v_pending > 0 AND v_doc.monto_aplicar > 0 THEN
            v_apply := LEAST(v_doc.monto_aplicar, v_pending);

            INSERT INTO ar."ReceivableApplication" (
                "ReceivableDocumentId",
                "ApplyDate",
                "AppliedAmount",
                "PaymentReference"
            )
            VALUES (
                v_receivable_id,
                v_fecha_date,
                v_apply,
                p_request_id || ':' || v_num_recibo
            );

            UPDATE ar."ReceivableDocument"
               SET "PendingAmount" = CASE
                       WHEN "PendingAmount" - v_apply < 0 THEN 0
                       ELSE "PendingAmount" - v_apply
                   END,
                   "PaidFlag" = CASE
                       WHEN "PendingAmount" - v_apply <= 0 THEN TRUE
                       ELSE FALSE
                   END,
                   "Status" = CASE
                       WHEN "PendingAmount" - v_apply <= 0 THEN 'PAID'
                       WHEN "PendingAmount" - v_apply < "TotalAmount" THEN 'PARTIAL'
                       ELSE 'PENDING'
                   END,
                   "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
             WHERE "ReceivableDocumentId" = v_receivable_id;

            v_applied_total := v_applied_total + v_apply;
        END IF;

        -- Limpiar variables para siguiente iteracion
        v_receivable_id := NULL;
        v_pending := NULL;
        v_total := NULL;
        v_apply := NULL;
    END LOOP;

    -- -------------------------------------------------------
    -- Verificar que se haya aplicado algo
    -- -------------------------------------------------------
    IF v_applied_total <= 0 THEN
        RAISE EXCEPTION 'No se aplico ningun monto'
            USING ERRCODE = 'P0001';
    END IF;

    -- -------------------------------------------------------
    -- Actualizar saldo total del cliente
    -- -------------------------------------------------------
    UPDATE master."Customer"
       SET "TotalBalance" = (
               SELECT COALESCE(SUM("PendingAmount"), 0)
                 FROM ar."ReceivableDocument"
                WHERE "CustomerId" = v_customer_id
                  AND "Status" <> 'VOIDED'
           ),
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
     WHERE "CustomerId" = v_customer_id;

    -- -------------------------------------------------------
    -- Retornar resultado exitoso
    -- -------------------------------------------------------
    v_resultado := 1;
    v_mensaje := 'Cobro aplicado exitosamente. Recibo: ' || v_num_recibo;

    RETURN QUERY SELECT
        v_num_recibo::VARCHAR(50),
        v_resultado,
        v_mensaje::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    v_resultado := -99;
    v_mensaje := SQLERRM;

    RETURN QUERY SELECT
        ''::VARCHAR(50),
        v_resultado,
        v_mensaje::VARCHAR(500);
END;
$function$
;

-- usp_cxp_aplicar_pago
DROP FUNCTION IF EXISTS public.usp_cxp_aplicar_pago(character varying, character varying, character varying, numeric, character varying, character varying, jsonb, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_cxp_aplicar_pago(p_request_id character varying, p_cod_proveedor character varying, p_fecha character varying, p_monto_total numeric, p_cod_usuario character varying, p_observaciones character varying DEFAULT ''::character varying, p_documentos_json jsonb DEFAULT NULL::jsonb, p_formas_pago_json jsonb DEFAULT NULL::jsonb)
 RETURNS TABLE("NumPago" character varying, "Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_resultado     INT := 0;

    v_mensaje       VARCHAR(500) := '';

    v_num_pago      VARCHAR(50) := '';

    v_fecha_date    DATE;

    v_supplier_id   BIGINT;

    v_payable_id    BIGINT;

    v_pending       NUMERIC(18,2);

    v_total         NUMERIC(18,2);

    v_apply         NUMERIC(18,2);

    v_applied_total NUMERIC(18,2) := 0;

    v_doc           RECORD;

    v_dup_ref       VARCHAR(150);

BEGIN

    -- -------------------------------------------------------

    -- Validar fecha

    -- -------------------------------------------------------

    BEGIN

        v_fecha_date := p_fecha::DATE;

    EXCEPTION WHEN OTHERS THEN

        RETURN QUERY SELECT

            ''::VARCHAR(50),

            -91,

            ('Fecha invalida: ' || COALESCE(p_fecha, 'NULL'))::VARCHAR(500);

        RETURN;

    END;



    -- -------------------------------------------------------

    -- Buscar proveedor

    -- -------------------------------------------------------

    SELECT s."SupplierId"

      INTO v_supplier_id

      FROM master."Supplier" s

     WHERE s."SupplierCode" = p_cod_proveedor

       AND s."IsDeleted" = FALSE

     LIMIT 1;



    IF v_supplier_id IS NULL THEN

        RETURN QUERY SELECT

            ''::VARCHAR(50),

            -1,

            ('Proveedor no encontrado: ' || p_cod_proveedor)::VARCHAR(500);

        RETURN;

    END IF;



    -- -------------------------------------------------------

    -- Validar JSON de documentos

    -- -------------------------------------------------------

    IF p_documentos_json IS NULL THEN

        RETURN QUERY SELECT

            ''::VARCHAR(50),

            -2,

            'DocumentosJson invalido'::VARCHAR(500);

        RETURN;

    END IF;



    -- Verificar que haya al menos un documento valido

    IF NOT EXISTS (

        SELECT 1

          FROM jsonb_array_elements(p_documentos_json) AS elem

         WHERE COALESCE(NULLIF(elem->>'numDoc', ''::character varying), '')::character varying <> ''

    ) THEN

        RETURN QUERY SELECT

            ''::VARCHAR(50),

            -3,

            'No se recibieron documentos validos para aplicar'::VARCHAR(500);

        RETURN;

    END IF;



    -- -------------------------------------------------------

    -- Generar numero de pago

    -- -------------------------------------------------------

    v_num_pago := 'PAG-' || TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYYMMDDHH24MISS');



    -- -------------------------------------------------------

    -- Idempotencia: verificar si ya se proceso este RequestId

    -- -------------------------------------------------------

    SELECT SUBSTRING(pa."PaymentReference" FROM POSITION(':' IN pa."PaymentReference") + 1)

      INTO v_dup_ref

      FROM ap."PayableApplication" pa

     INNER JOIN ap."PayableDocument" pd

        ON pd."PayableDocumentId" = pa."PayableDocumentId"

     WHERE pd."SupplierId" = v_supplier_id

       AND pa."PaymentReference" LIKE p_request_id || ':%'

     ORDER BY pa."PayableApplicationId" DESC

     LIMIT 1;



    IF v_dup_ref IS NOT NULL THEN

        RETURN QUERY SELECT

            v_dup_ref::VARCHAR(50),

            1,

            ('Duplicado idempotente. Pago: ' || COALESCE(v_dup_ref, ''))::VARCHAR(500);

        RETURN;

    END IF;



    -- -------------------------------------------------------

    -- Iterar documentos y aplicar pagos

    -- -------------------------------------------------------

    FOR v_doc IN

        SELECT

            UPPER(COALESCE(NULLIF(elem->>'tipoDoc', ''::character varying), 'COMPRA')::character varying)::character varying AS tipo_doc,

            COALESCE(NULLIF(elem->>'numDoc', ''::character varying), '')::character varying               AS num_doc,

            COALESCE(NULLIF(elem->>'montoAplicar', ''::character varying), '0')::character varying::NUMERIC(18,2) AS monto_aplicar

          FROM jsonb_array_elements(p_documentos_json) AS elem

         WHERE COALESCE(NULLIF(elem->>'numDoc', ''::character varying), '')::character varying <> ''

    LOOP

        -- Buscar documento pendiente

        SELECT pd."PayableDocumentId",

               pd."PendingAmount",

               pd."TotalAmount"

          INTO v_payable_id, v_pending, v_total

          FROM ap."PayableDocument" pd

         WHERE pd."SupplierId" = v_supplier_id

           AND pd."DocumentType" = v_doc.tipo_doc

           AND pd."DocumentNumber" = v_doc.num_doc

           AND pd."Status" <> 'VOIDED'

         ORDER BY pd."PayableDocumentId" DESC

         LIMIT 1

           FOR UPDATE;



        IF v_payable_id IS NOT NULL AND v_pending > 0 AND v_doc.monto_aplicar > 0 THEN

            v_apply := LEAST(v_doc.monto_aplicar, v_pending);



            INSERT INTO ap."PayableApplication" (

                "PayableDocumentId",

                "ApplyDate",

                "AppliedAmount",

                "PaymentReference"

            )

            VALUES (

                v_payable_id,

                v_fecha_date,

                v_apply,

                p_request_id || ':' || v_num_pago

            );



            UPDATE ap."PayableDocument"

               SET "PendingAmount" = CASE

                       WHEN "PendingAmount" - v_apply < 0 THEN 0

                       ELSE "PendingAmount" - v_apply

                   END,

                   "PaidFlag" = CASE

                       WHEN "PendingAmount" - v_apply <= 0 THEN TRUE

                       ELSE FALSE

                   END,

                   "Status" = CASE

                       WHEN "PendingAmount" - v_apply <= 0 THEN 'PAID'

                       WHEN "PendingAmount" - v_apply < "TotalAmount" THEN 'PARTIAL'

                       ELSE 'PENDING'

                   END,

                   "UpdatedAt" = NOW() AT TIME ZONE 'UTC'

             WHERE "PayableDocumentId" = v_payable_id;



            v_applied_total := v_applied_total + v_apply;

        END IF;



        -- Limpiar variables para siguiente iteracion

        v_payable_id := NULL;

        v_pending := NULL;

        v_total := NULL;

        v_apply := NULL;

    END LOOP;



    -- -------------------------------------------------------

    -- Verificar que se haya aplicado algo

    -- -------------------------------------------------------

    IF v_applied_total <= 0 THEN

        RAISE EXCEPTION 'No se aplico ningun monto'

            USING ERRCODE = 'P0001';

    END IF;



    -- -------------------------------------------------------

    -- Actualizar saldo total del proveedor

    -- -------------------------------------------------------

    UPDATE master."Supplier"

       SET "TotalBalance" = (

               SELECT COALESCE(SUM("PendingAmount"), 0)

                 FROM ap."PayableDocument"

                WHERE "SupplierId" = v_supplier_id

                  AND "Status" <> 'VOIDED'

           ),

           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'

     WHERE "SupplierId" = v_supplier_id;



    -- -------------------------------------------------------

    -- Retornar resultado exitoso

    -- -------------------------------------------------------

    v_resultado := 1;

    v_mensaje := 'Pago aplicado exitosamente. Pago: ' || v_num_pago;



    RETURN QUERY SELECT

        v_num_pago::VARCHAR(50),

        v_resultado,

        v_mensaje::VARCHAR(500);



EXCEPTION WHEN OTHERS THEN

    v_resultado := -99;

    v_mensaje := SQLERRM;



    RETURN QUERY SELECT

        ''::VARCHAR(50),

        v_resultado,

        v_mensaje::VARCHAR(500);

END;

$function$
;

-- usp_fin_bank_delete
DROP FUNCTION IF EXISTS public.usp_fin_bank_delete(integer, character varying, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_bank_delete(p_company_id integer, p_bank_name character varying, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Success" boolean, "Message" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE v_affected INT;

BEGIN

    UPDATE fin."Bank"

    SET "IsActive" = FALSE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC', "UpdatedByUserId" = p_user_id

    WHERE "CompanyId" = p_company_id AND "BankName" = p_bank_name AND "IsActive" = TRUE;



    GET DIAGNOSTICS v_affected = ROW_COUNT;

    IF v_affected <= 0 THEN

        RETURN QUERY SELECT FALSE, 'Banco no encontrado'::TEXT;

    ELSE

        RETURN QUERY SELECT TRUE, 'Banco eliminado'::TEXT;

    END IF;

END;

$function$
;

-- usp_fin_bank_getbyname
DROP FUNCTION IF EXISTS public.usp_fin_bank_getbyname(integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_bank_getbyname(p_company_id integer, p_bank_name character varying)
 RETURNS TABLE("Nombre" character varying, "Contacto" character varying, "Direccion" character varying, "Telefonos" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT b."BankName", b."ContactName", b."AddressLine", b."Phones"

    FROM fin."Bank" b

    WHERE b."CompanyId" = p_company_id AND b."IsActive" = TRUE AND b."BankName" = p_bank_name

    ORDER BY b."BankId" DESC LIMIT 1;

END;

$function$
;

-- usp_fin_bank_insert
DROP FUNCTION IF EXISTS public.usp_fin_bank_insert(integer, character varying, character varying, character varying, character varying, character varying, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_bank_insert(p_company_id integer, p_bank_code character varying, p_bank_name character varying, p_contact_name character varying DEFAULT NULL::character varying, p_address_line character varying DEFAULT NULL::character varying, p_phones character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Success" boolean, "Message" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    IF EXISTS (SELECT 1 FROM fin."Bank" WHERE "CompanyId" = p_company_id AND "BankName" = p_bank_name) THEN

        RETURN QUERY SELECT FALSE, 'Banco ya existe'::TEXT;

        RETURN;

    END IF;



    INSERT INTO fin."Bank" ("CompanyId", "BankCode", "BankName", "ContactName", "AddressLine", "Phones", "IsActive", "CreatedByUserId", "UpdatedByUserId")

    VALUES (p_company_id, p_bank_code, p_bank_name, p_contact_name, p_address_line, p_phones, TRUE, p_user_id, p_user_id);



    RETURN QUERY SELECT TRUE, 'Banco creado'::TEXT;

END;

$function$
;

-- usp_fin_bank_list
DROP FUNCTION IF EXISTS public.usp_fin_bank_list(integer, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_bank_list(p_company_id integer, p_search character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "Nombre" character varying, "Contacto" character varying, "Direccion" character varying, "Telefonos" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE v_total BIGINT;

BEGIN

    SELECT COUNT(1) INTO v_total FROM fin."Bank"

    WHERE "CompanyId" = p_company_id AND "IsActive" = TRUE

      AND (p_search IS NULL OR "BankName" ILIKE p_search OR "ContactName" ILIKE p_search);



    RETURN QUERY

    SELECT v_total, b."BankName", b."ContactName", b."AddressLine", b."Phones"

    FROM fin."Bank" b

    WHERE b."CompanyId" = p_company_id AND b."IsActive" = TRUE

      AND (p_search IS NULL OR b."BankName" ILIKE p_search OR b."ContactName" ILIKE p_search)

    ORDER BY b."BankName"

    LIMIT p_limit OFFSET p_offset;

END;

$function$
;

-- usp_fin_bank_update
DROP FUNCTION IF EXISTS public.usp_fin_bank_update(integer, character varying, character varying, character varying, character varying, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_bank_update(p_company_id integer, p_bank_name character varying, p_contact_name character varying DEFAULT NULL::character varying, p_address_line character varying DEFAULT NULL::character varying, p_phones character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Success" boolean, "Message" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE v_affected INT;

BEGIN

    UPDATE fin."Bank"

    SET "ContactName" = COALESCE(p_contact_name, "ContactName"),

        "AddressLine" = COALESCE(p_address_line, "AddressLine"),

        "Phones"      = COALESCE(p_phones, "Phones"),

        "UpdatedAt"   = NOW() AT TIME ZONE 'UTC',

        "UpdatedByUserId" = p_user_id

    WHERE "CompanyId" = p_company_id AND "BankName" = p_bank_name AND "IsActive" = TRUE;



    GET DIAGNOSTICS v_affected = ROW_COUNT;

    IF v_affected <= 0 THEN

        RETURN QUERY SELECT FALSE, 'Banco no encontrado'::TEXT;

    ELSE

        RETURN QUERY SELECT TRUE, 'Banco actualizado'::TEXT;

    END IF;

END;

$function$
;

-- usp_fin_pettycash_box_create
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_box_create(integer, integer, character varying, character varying, numeric, character varying, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_box_create(p_company_id integer, p_branch_id integer, p_name character varying, p_account_code character varying DEFAULT NULL::character varying, p_max_amount numeric DEFAULT 0, p_responsible character varying DEFAULT NULL::character varying, p_created_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_new_id INT;

BEGIN

    IF EXISTS (

        SELECT 1 FROM fin."PettyCashBox"

        WHERE "CompanyId" = p_company_id

          AND "BranchId" = p_branch_id

          AND "Name" = p_name

          AND "Status" = 'ACTIVE'

    ) THEN

        RETURN QUERY SELECT -1, 'Ya existe una caja chica activa con ese nombre en esta sucursal.'::VARCHAR(500);

        RETURN;

    END IF;



    BEGIN

        INSERT INTO fin."PettyCashBox" (

            "CompanyId", "BranchId", "Name", "AccountCode", "MaxAmount",

            "CurrentBalance", "Responsible", "Status", "CreatedAt", "CreatedByUserId"

        )

        VALUES (

            p_company_id, p_branch_id, p_name, p_account_code, p_max_amount,

            0, p_responsible, 'ACTIVE', NOW() AT TIME ZONE 'UTC', p_created_by_user_id

        )

        RETURNING "Id" INTO v_new_id;



        RETURN QUERY SELECT v_new_id, 'Caja chica creada exitosamente.'::VARCHAR(500);

    EXCEPTION WHEN OTHERS THEN

        RETURN QUERY SELECT -1, SQLERRM::VARCHAR(500);

    END;

END;

$function$
;

-- usp_fin_pettycash_box_list
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_box_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_box_list(p_company_id integer)
 RETURNS TABLE("Id" integer, "CompanyId" integer, "BranchId" integer, "Name" character varying, "AccountCode" character varying, "MaxAmount" numeric, "CurrentBalance" numeric, "Responsible" character varying, "Status" character varying, "CreatedAt" timestamp with time zone, "CreatedByUserId" integer)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        b."Id", b."CompanyId", b."BranchId", b."Name",

        b."AccountCode", b."MaxAmount", b."CurrentBalance",

        b."Responsible", b."Status", b."CreatedAt", b."CreatedByUserId"

    FROM fin."PettyCashBox" b

    WHERE b."CompanyId" = p_company_id

    ORDER BY b."Name";

END;

$function$
;

-- usp_fin_pettycash_expense_add
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_expense_add(integer, integer, character varying, character varying, numeric, character varying, character varying, character varying, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_expense_add(p_session_id integer, p_box_id integer, p_category character varying, p_description character varying, p_amount numeric, p_beneficiary character varying DEFAULT NULL::character varying, p_receipt_number character varying DEFAULT NULL::character varying, p_account_code character varying DEFAULT NULL::character varying, p_created_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_opening_amount NUMERIC(18,2);

    v_total_expenses NUMERIC(18,2);

    v_new_id         INT;

BEGIN

    -- Validar que la sesion existe y esta abierta

    IF NOT EXISTS (

        SELECT 1 FROM fin."PettyCashSession"

        WHERE "Id" = p_session_id AND "BoxId" = p_box_id AND "Status" = 'OPEN'

    ) THEN

        RETURN QUERY SELECT -1, 'La sesion no existe, no pertenece a esta caja o ya esta cerrada.'::VARCHAR(500);

        RETURN;

    END IF;



    -- Validar monto positivo

    IF p_amount <= 0 THEN

        RETURN QUERY SELECT -2, 'El monto del gasto debe ser mayor a cero.'::VARCHAR(500);

        RETURN;

    END IF;



    -- Validar que haya saldo suficiente

    SELECT "OpeningAmount", "TotalExpenses"

    INTO v_opening_amount, v_total_expenses

    FROM fin."PettyCashSession"

    WHERE "Id" = p_session_id;



    IF (v_total_expenses + p_amount) > v_opening_amount THEN

        RETURN QUERY SELECT -3, ('El monto del gasto excede el saldo disponible en la sesion. Disponible: ' || (v_opening_amount - v_total_expenses)::TEXT)::VARCHAR(500);

        RETURN;

    END IF;



    BEGIN

        -- Insertar el gasto

        INSERT INTO fin."PettyCashExpense" (

            "SessionId", "BoxId", "Category", "Description", "Amount",

            "Beneficiary", "ReceiptNumber", "AccountCode", "CreatedAt", "CreatedByUserId"

        )

        VALUES (

            p_session_id, p_box_id, p_category, p_description, p_amount,

            p_beneficiary, p_receipt_number, p_account_code,

            NOW() AT TIME ZONE 'UTC', p_created_by_user_id

        )

        RETURNING "Id" INTO v_new_id;



        -- Actualizar total de gastos en la sesion

        UPDATE fin."PettyCashSession"

        SET "TotalExpenses" = "TotalExpenses" + p_amount

        WHERE "Id" = p_session_id;



        -- Actualizar saldo actual en la caja (restar gasto)

        UPDATE fin."PettyCashBox"

        SET "CurrentBalance" = "CurrentBalance" - p_amount

        WHERE "Id" = p_box_id;



        RETURN QUERY SELECT v_new_id, 'Gasto registrado exitosamente.'::VARCHAR(500);

    EXCEPTION WHEN OTHERS THEN

        RETURN QUERY SELECT -1, SQLERRM::VARCHAR(500);

    END;

END;

$function$
;

-- usp_fin_pettycash_expense_list
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_expense_list(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_expense_list(p_box_id integer, p_session_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Id" integer, "SessionId" integer, "BoxId" integer, "Category" character varying, "Description" character varying, "Amount" numeric, "Beneficiary" character varying, "ReceiptNumber" character varying, "AccountCode" character varying, "CreatedAt" timestamp with time zone, "CreatedByUserId" integer)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        e."Id", e."SessionId", e."BoxId", e."Category", e."Description",

        e."Amount", e."Beneficiary", e."ReceiptNumber", e."AccountCode",

        e."CreatedAt", e."CreatedByUserId"

    FROM fin."PettyCashExpense" e

    WHERE e."BoxId" = p_box_id

      AND (p_session_id IS NULL OR e."SessionId" = p_session_id)

    ORDER BY e."CreatedAt" DESC;

END;

$function$
;

-- usp_fin_pettycash_session_close
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_session_close(integer, integer, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_session_close(p_box_id integer, p_closed_by_user_id integer DEFAULT NULL::integer, p_notes character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_session_id     INT;

    v_opening_amount NUMERIC(18,2);

    v_total_expenses NUMERIC(18,2);

    v_closing_amount NUMERIC(18,2);

BEGIN

    -- Buscar la sesion abierta para esta caja

    SELECT "Id", "OpeningAmount", "TotalExpenses"

    INTO v_session_id, v_opening_amount, v_total_expenses

    FROM fin."PettyCashSession"

    WHERE "BoxId" = p_box_id AND "Status" = 'OPEN';



    IF v_session_id IS NULL THEN

        RETURN QUERY SELECT -1, 'No existe una sesion abierta para esta caja chica.'::VARCHAR(500);

        RETURN;

    END IF;



    -- Calcular monto de cierre

    v_closing_amount := v_opening_amount - v_total_expenses;



    BEGIN

        -- Cerrar la sesion

        UPDATE fin."PettyCashSession"

        SET "Status" = 'CLOSED',

            "ClosingAmount" = v_closing_amount,

            "ClosedAt" = NOW() AT TIME ZONE 'UTC',

            "ClosedByUserId" = p_closed_by_user_id,

            "Notes" = p_notes

        WHERE "Id" = v_session_id;



        -- Actualizar saldo en la caja

        UPDATE fin."PettyCashBox"

        SET "CurrentBalance" = v_closing_amount

        WHERE "Id" = p_box_id;



        RETURN QUERY SELECT v_session_id, ('Sesion cerrada exitosamente. Monto de cierre: ' || v_closing_amount::TEXT)::VARCHAR(500);

    EXCEPTION WHEN OTHERS THEN

        RETURN QUERY SELECT -1, SQLERRM::VARCHAR(500);

    END;

END;

$function$
;

-- usp_fin_pettycash_session_getactive
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_session_getactive(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_session_getactive(p_box_id integer)
 RETURNS TABLE("Id" integer, "BoxId" integer, "OpeningAmount" numeric, "ClosingAmount" numeric, "TotalExpenses" numeric, "Status" character varying, "OpenedAt" timestamp with time zone, "ClosedAt" timestamp with time zone, "OpenedByUserId" integer, "ClosedByUserId" integer, "Notes" character varying, "AvailableBalance" numeric, "ExpenseCount" bigint)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        s."Id", s."BoxId", s."OpeningAmount", s."ClosingAmount",

        s."TotalExpenses", s."Status", s."OpenedAt", s."ClosedAt",

        s."OpenedByUserId", s."ClosedByUserId", s."Notes",

        (s."OpeningAmount" - s."TotalExpenses"),

        (SELECT COUNT(1) FROM fin."PettyCashExpense" e WHERE e."SessionId" = s."Id")

    FROM fin."PettyCashSession" s

    WHERE s."BoxId" = p_box_id

      AND s."Status" = 'OPEN';

END;

$function$
;

-- usp_fin_pettycash_session_open
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_session_open(integer, numeric, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_session_open(p_box_id integer, p_opening_amount numeric, p_opened_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_max_amount NUMERIC(18,2);

    v_new_id     INT;

BEGIN

    -- Validar que la caja existe y esta activa

    IF NOT EXISTS (SELECT 1 FROM fin."PettyCashBox" WHERE "Id" = p_box_id AND "Status" = 'ACTIVE') THEN

        RETURN QUERY SELECT -1, 'La caja chica no existe o no esta activa.'::VARCHAR(500);

        RETURN;

    END IF;



    -- Validar que no haya otra sesion abierta para esta caja

    IF EXISTS (SELECT 1 FROM fin."PettyCashSession" WHERE "BoxId" = p_box_id AND "Status" = 'OPEN') THEN

        RETURN QUERY SELECT -2, 'Ya existe una sesion abierta para esta caja chica. Debe cerrarla primero.'::VARCHAR(500);

        RETURN;

    END IF;



    -- Validar que el monto de apertura no exceda el maximo permitido

    SELECT "MaxAmount" INTO v_max_amount FROM fin."PettyCashBox" WHERE "Id" = p_box_id;



    IF v_max_amount > 0 AND p_opening_amount > v_max_amount THEN

        RETURN QUERY SELECT -3, ('El monto de apertura excede el monto maximo permitido para esta caja chica (' || v_max_amount::TEXT || ').')::VARCHAR(500);

        RETURN;

    END IF;



    BEGIN

        -- Crear la sesion

        INSERT INTO fin."PettyCashSession" (

            "BoxId", "OpeningAmount", "ClosingAmount", "TotalExpenses",

            "Status", "OpenedAt", "OpenedByUserId"

        )

        VALUES (

            p_box_id, p_opening_amount, NULL, 0,

            'OPEN', NOW() AT TIME ZONE 'UTC', p_opened_by_user_id

        )

        RETURNING "Id" INTO v_new_id;



        -- Actualizar el saldo actual de la caja

        UPDATE fin."PettyCashBox"

        SET "CurrentBalance" = p_opening_amount

        WHERE "Id" = p_box_id;



        RETURN QUERY SELECT v_new_id, 'Sesion de caja chica abierta exitosamente.'::VARCHAR(500);

    EXCEPTION WHEN OTHERS THEN

        RETURN QUERY SELECT -1, SQLERRM::VARCHAR(500);

    END;

END;

$function$
;

-- usp_fin_pettycash_summary_box
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_summary_box(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_summary_box(p_box_id integer)
 RETURNS TABLE("Id" integer, "CompanyId" integer, "BranchId" integer, "Name" character varying, "AccountCode" character varying, "MaxAmount" numeric, "CurrentBalance" numeric, "Responsible" character varying, "Status" character varying, "CreatedAt" timestamp with time zone)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        b."Id", b."CompanyId", b."BranchId", b."Name",

        b."AccountCode", b."MaxAmount", b."CurrentBalance",

        b."Responsible", b."Status", b."CreatedAt"

    FROM fin."PettyCashBox" b

    WHERE b."Id" = p_box_id;

END;

$function$
;

-- usp_fin_pettycash_summary_categories
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_summary_categories(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_summary_categories(p_box_id integer)
 RETURNS TABLE("Category" character varying, "ExpenseCount" bigint, "TotalAmount" numeric)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        e."Category",

        COUNT(1),

        SUM(e."Amount")

    FROM fin."PettyCashExpense" e

    INNER JOIN fin."PettyCashSession" s ON s."Id" = e."SessionId"

    WHERE e."BoxId" = p_box_id

      AND s."Status" = 'OPEN'

    GROUP BY e."Category"

    ORDER BY SUM(e."Amount") DESC;

END;

$function$
;

-- usp_fin_pettycash_summary_session
DROP FUNCTION IF EXISTS public.usp_fin_pettycash_summary_session(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fin_pettycash_summary_session(p_box_id integer)
 RETURNS TABLE("SessionId" integer, "OpeningAmount" numeric, "TotalExpenses" numeric, "AvailableBalance" numeric, "OpenedAt" timestamp with time zone, "OpenedByUserId" integer, "ExpenseCount" bigint)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        s."Id",

        s."OpeningAmount",

        s."TotalExpenses",

        (s."OpeningAmount" - s."TotalExpenses"),

        s."OpenedAt",

        s."OpenedByUserId",

        (SELECT COUNT(1) FROM fin."PettyCashExpense" e WHERE e."SessionId" = s."Id")

    FROM fin."PettyCashSession" s

    WHERE s."BoxId" = p_box_id

      AND s."Status" = 'OPEN';

END;

$function$
;

