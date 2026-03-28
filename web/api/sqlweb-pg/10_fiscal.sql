-- sp_CxC_Documentos_List
DROP FUNCTION IF EXISTS public."sp_CxC_Documentos_List"(character varying, character varying, character varying, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public."sp_CxC_Documentos_List"(p_codcliente character varying DEFAULT NULL::character varying, p_tipodoc character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_fechadesde date DEFAULT NULL::date, p_fechahasta date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("codCliente" character varying, "tipoDoc" character varying, "numDoc" character varying, fecha date, total numeric, pendiente numeric, estado character varying, observacion character varying, "codUsuario" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

  v_Page  INT := GREATEST(COALESCE(p_Page, 1), 1);

  v_Limit INT := LEAST(GREATEST(COALESCE(p_Limit, 50), 1), 500);

  v_Offset INT := (v_Page - 1) * v_Limit;

BEGIN

  RETURN QUERY

  SELECT

    c."CustomerCode"::VARCHAR      AS "codCliente",

    d."DocumentType"::VARCHAR      AS "tipoDoc",

    d."DocumentNumber"::VARCHAR    AS "numDoc",

    d."IssueDate"                  AS "fecha",

    d."TotalAmount"                AS "total",

    d."PendingAmount"              AS "pendiente",

    d."Status"::VARCHAR            AS "estado",

    d."Notes"::VARCHAR             AS "observacion",

    u."UserCode"::VARCHAR          AS "codUsuario"
DROP FUNCTION IF EXISTS
  FROM ar."ReceivableDocument" d

  INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"

  LEFT JOIN sec."User" u ON u."UserId" = d."CreatedByUserId"

  WHERE (p_CodCliente IS NULL OR c."CustomerCode" = p_CodCliente)

    AND (p_TipoDoc IS NULL OR d."DocumentType" = p_TipoDoc)

    AND (p_FechaDesde IS NULL OR d."IssueDate" >= p_FechaDesde)

    AND (p_FechaHasta IS NULL OR d."IssueDate" <= p_FechaHasta)

    AND (p_Estado IS NULL OR p_Estado = '' OR d."Status" = p_Estado)

  ORDER BY d."IssueDate" DESC, d."DocumentNumber" DESC, d."ReceivableDocumentId" DESC

  LIMIT v_Limit OFFSET v_Offset;

END;

$function$
;

-- sp_CxP_Documentos_List
DROP FUNCTION IF EXISTS public."sp_CxP_Documentos_List"(character varying, character varying, character varying, date, date, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public."sp_CxP_Documentos_List"(p_codproveedor character varying DEFAULT NULL::character varying, p_tipodoc character varying DEFAULT NULL::character varying, p_estado character varying DEFAULT NULL::character varying, p_fechadesde date DEFAULT NULL::date, p_fechahasta date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("codProveedor" character varying, "tipoDoc" character varying, "numDoc" character varying, fecha date, total numeric, pendiente numeric, estado character varying, observacion character varying, "codUsuario" character varying)
 LANGUAGE plpgsql
AS $function$

DECLARE

  v_Page  INT := GREATEST(COALESCE(p_Page, 1), 1);
DROP FUNCTION IF EXISTS
  v_Limit INT := LEAST(GREATEST(COALESCE(p_Limit, 50), 1), 500);

  v_Offset INT := (v_Page - 1) * v_Limit;

BEGIN

  RETURN QUERY

  SELECT

    s."SupplierCode"::VARCHAR      AS "codProveedor",

    d."DocumentType"::VARCHAR      AS "tipoDoc",

    d."DocumentNumber"::VARCHAR    AS "numDoc",

    d."IssueDate"                  AS "fecha",

    d."TotalAmount"                AS "total",

    d."PendingAmount"              AS "pendiente",
DROP FUNCTION IF EXISTS
    d."Status"::VARCHAR            AS "estado",

    d."Notes"::VARCHAR             AS "observacion",

    u."UserCode"::VARCHAR          AS "codUsuario"

  FROM ap."PayableDocument" d

  INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"

  LEFT JOIN sec."User" u ON u."UserId" = d."CreatedByUserId"

  WHERE (p_CodProveedor IS NULL OR s."SupplierCode" = p_CodProveedor)

    AND (p_TipoDoc IS NULL OR d."DocumentType" = p_TipoDoc)

    AND (p_FechaDesde IS NULL OR d."IssueDate" >= p_FechaDesde)

    AND (p_FechaHasta IS NULL OR d."IssueDate" <= p_FechaHasta)

    AND (p_Estado IS NULL OR p_Estado = '' OR d."Status" = p_Estado)

  ORDER BY d."IssueDate" DESC, d."DocumentNumber" DESC, d."PayableDocumentId" DESC

  LIMIT v_Limit OFFSET v_Offset;
DROP FUNCTION IF EXISTS
END;

$function$
;

-- usp_audit_dashboard_topmodulos
DROP FUNCTION IF EXISTS public.usp_audit_dashboard_topmodulos(integer, integer, date, date) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_audit_dashboard_topmodulos(p_company_id integer, p_branch_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("ModuleName" character varying, "Total" bigint)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT a."ModuleName",

           COUNT(*) AS "Total"

    FROM   audit."AuditLog" a

    WHERE  a."CompanyId" = p_company_id

      AND  a."BranchId"  = p_branch_id
DROP FUNCTION IF EXISTS
      AND  a."CreatedAt"::DATE >= p_fecha_desde

      AND  a."CreatedAt"::DATE <= p_fecha_hasta

    GROUP BY a."ModuleName"

    ORDER BY "Total" DESC

    LIMIT 10;

END;

$function$
;

-- usp_audit_dashboard_totales
DROP FUNCTION IF EXISTS public.usp_audit_dashboard_totales(integer, integer, date, date) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_audit_dashboard_totales(p_company_id integer, p_branch_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("totalLogs" bigint, "totalCreates" bigint, "totalUpdates" bigint, "totalDeletes" bigint, "totalVoids" bigint, "totalLogins" bigint, "logsUltimas24h" bigint)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        COUNT(*)                                                           AS "totalLogs",

        SUM(CASE WHEN a."ActionType" = 'CREATE' THEN 1 ELSE 0 END)::BIGINT AS "totalCreates",

        SUM(CASE WHEN a."ActionType" = 'UPDATE' THEN 1 ELSE 0 END)::BIGINT AS "totalUpdates",

        SUM(CASE WHEN a."ActionType" = 'DELETE' THEN 1 ELSE 0 END)::BIGINT AS "totalDeletes",

        SUM(CASE WHEN a."ActionType" = 'VOID'   THEN 1 ELSE 0 END)::BIGINT AS "totalVoids",

        SUM(CASE WHEN a."ActionType" = 'LOGIN'  THEN 1 ELSE 0 END)::BIGINT AS "totalLogins",

        SUM(CASE WHEN a."CreatedAt" >= (NOW() AT TIME ZONE 'UTC') - INTERVAL '24 hours'

                 THEN 1 ELSE 0 END)::BIGINT                                AS "logsUltimas24h"

    FROM   audit."AuditLog" a

    WHERE  a."CompanyId" = p_company_id

      AND  a."BranchId"  = p_branch_id

      AND  a."CreatedAt"::DATE >= p_fecha_desde
DROP FUNCTION IF EXISTS
      AND  a."CreatedAt"::DATE <= p_fecha_hasta;

END;

$function$
;

-- usp_audit_dashboard_ultimoslogs
DROP FUNCTION IF EXISTS public.usp_audit_dashboard_ultimoslogs(integer, integer, date, date) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_audit_dashboard_ultimoslogs(p_company_id integer, p_branch_id integer, p_fecha_desde date, p_fecha_hasta date)
 RETURNS TABLE("AuditLogId" bigint, "CreatedAt" timestamp without time zone, "UserName" character varying, "ModuleName" character varying, "ActionType" character varying, "EntityName" character varying, "Summary" character varying)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT a."AuditLogId",

           a."CreatedAt",

           a."UserName",

           a."ModuleName",

           a."ActionType",
DROP FUNCTION IF EXISTS
           a."EntityName",

           a."Summary"

    FROM   audit."AuditLog" a

    WHERE  a."CompanyId" = p_company_id

      AND  a."BranchId"  = p_branch_id

      AND  a."CreatedAt"::DATE >= p_fecha_desde

      AND  a."CreatedAt"::DATE <= p_fecha_hasta

    ORDER BY a."CreatedAt" DESC

    LIMIT 10;

END;

$function$
;

-- usp_audit_fiscalrecord_list
DROP FUNCTION IF EXISTS public.usp_audit_fiscalrecord_list(integer, integer, date, date, integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_audit_fiscalrecord_list(p_company_id integer, p_branch_id integer, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "FiscalRecordId" integer, "InvoiceId" integer, "InvoiceNumber" character varying, "InvoiceDate" date, "InvoiceType" character varying, "RecordHash" character varying, "SentToAuthority" boolean, "AuthorityStatus" character varying, "CountryCode" character varying, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_page   INT := GREATEST(p_page, 1);

    v_limit  INT := GREATEST(LEAST(p_limit, 500), 1);

    v_offset INT := (v_page - 1) * v_limit;

    v_total  BIGINT;

    v_table_exists BOOLEAN;

BEGIN

    -- Verificar si existe la tabla fiscal."Record"

    SELECT EXISTS (

        SELECT 1 FROM information_schema.tables

        WHERE table_schema = 'fiscal' AND table_name = 'Record'

    ) INTO v_table_exists;



    IF NOT v_table_exists THEN

        -- Retornar conjunto vacio

        RETURN;

    END IF;



    -- Calcular total

    EXECUTE format(

        'SELECT COUNT(*) FROM fiscal."Record" WHERE "CompanyId" = $1 AND "BranchId" = $2'

        || CASE WHEN p_fecha_desde IS NOT NULL THEN ' AND "CreatedAt"::DATE >= $3' ELSE '' END

        || CASE WHEN p_fecha_hasta IS NOT NULL THEN ' AND "CreatedAt"::DATE <= $4' ELSE '' END

    )

    INTO v_total

    USING p_company_id, p_branch_id, p_fecha_desde, p_fecha_hasta;
DROP FUNCTION IF EXISTS


    -- Retornar registros paginados

    RETURN QUERY EXECUTE format(

        'SELECT $5::BIGINT AS "TotalCount",'

        || ' "FiscalRecordId", "InvoiceId", "InvoiceNumber"::VARCHAR(50),'

        || ' "InvoiceDate"::DATE, "InvoiceType"::VARCHAR(20),'

        || ' "RecordHash"::VARCHAR(64), "SentToAuthority"::BOOLEAN,'

        || ' "AuthorityStatus"::VARCHAR(50), "CountryCode"::VARCHAR(3), "CreatedAt"'

        || ' FROM fiscal."Record"'

        || ' WHERE "CompanyId" = $1 AND "BranchId" = $2'

        || CASE WHEN p_fecha_desde IS NOT NULL THEN ' AND "CreatedAt"::DATE >= $3' ELSE '' END

        || CASE WHEN p_fecha_hasta IS NOT NULL THEN ' AND "CreatedAt"::DATE <= $4' ELSE '' END

        || ' ORDER BY "CreatedAt" DESC'

        || ' LIMIT $6 OFFSET $7'

    )

    USING p_company_id, p_branch_id, p_fecha_desde, p_fecha_hasta, v_total, v_limit, v_offset;

END;

$function$
;

-- usp_audit_log_getbyid
DROP FUNCTION IF EXISTS public.usp_audit_log_getbyid(bigint) CASCADE;
DROP FUNCTION IF EXISTS public.usp_audit_log_getbyid(p_audit_log_id bigint)
 RETURNS TABLE("AuditLogId" bigint, "CompanyId" integer, "BranchId" integer, "UserId" integer, "UserName" character varying, "ModuleName" character varying, "EntityName" character varying, "EntityId" character varying, "ActionType" character varying, "Summary" character varying, "OldValues" character varying, "NewValues" character varying, "IpAddress" character varying, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT a."AuditLogId",

           a."CompanyId",

           a."BranchId",

           a."UserId",

           a."UserName",

           a."ModuleName",

           a."EntityName",

           a."EntityId",

           a."ActionType",

           a."Summary",

           a."OldValues",

           a."NewValues",

           a."IpAddress",

           a."CreatedAt"

    FROM   audit."AuditLog" a

    WHERE  a."AuditLogId" = p_audit_log_id;

END;

$function$
;

-- usp_audit_log_insert
DROP FUNCTION IF EXISTS public.usp_audit_log_insert(integer, integer, integer, character varying, character varying, character varying, character varying, character varying, character varying, text, text, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_audit_log_insert(p_company_id integer, p_branch_id integer, p_user_id integer DEFAULT NULL::integer, p_user_name character varying DEFAULT NULL::character varying, p_module_name character varying DEFAULT NULL::character varying, p_entity_name character varying DEFAULT NULL::character varying, p_entity_id character varying DEFAULT NULL::character varying, p_action_type character varying DEFAULT NULL::character varying, p_summary character varying DEFAULT NULL::character varying, p_old_values text DEFAULT NULL::text, p_new_values text DEFAULT NULL::text, p_ip_address character varying DEFAULT NULL::character varying)
 RETURNS TABLE("AuditLogId" bigint)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_id BIGINT;

BEGIN

    INSERT INTO audit."AuditLog" (

        "CompanyId", "BranchId", "UserId", "UserName",

        "ModuleName", "EntityName", "EntityId", "ActionType",

        "Summary", "OldValues", "NewValues", "IpAddress"

    )

    VALUES (

        p_company_id, p_branch_id, p_user_id, p_user_name,

        p_module_name, p_entity_name, p_entity_id, p_action_type,

        p_summary, p_old_values, p_new_values, p_ip_address

    )

    RETURNING audit."AuditLog"."AuditLogId" INTO v_id;



    RETURN QUERY SELECT v_id;

END;

$function$
;

-- usp_audit_log_list
DROP FUNCTION IF EXISTS public.usp_audit_log_list(integer, integer, date, date, character varying, character varying, character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_audit_log_list(p_company_id integer, p_branch_id integer, p_fecha_desde date DEFAULT NULL::date, p_fecha_hasta date DEFAULT NULL::date, p_module_name character varying DEFAULT NULL::character varying, p_user_name character varying DEFAULT NULL::character varying, p_action_type character varying DEFAULT NULL::character varying, p_entity_name character varying DEFAULT NULL::character varying, p_search character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "AuditLogId" bigint, "CompanyId" integer, "BranchId" integer, "UserId" integer, "UserName" character varying, "ModuleName" character varying, "EntityName" character varying, "EntityId" character varying, "ActionType" character varying, "Summary" character varying, "IpAddress" character varying, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_page   INT := GREATEST(p_page, 1);

    v_limit  INT := GREATEST(LEAST(p_limit, 500), 1);

    v_offset INT := (v_page - 1) * v_limit;

    v_total  BIGINT;

BEGIN

    -- Calcular total

    SELECT COUNT(*)

    INTO   v_total

    FROM   audit."AuditLog" a

    WHERE  a."CompanyId" = p_company_id

      AND  a."BranchId"  = p_branch_id

      AND  (p_fecha_desde IS NULL OR a."CreatedAt"::DATE >= p_fecha_desde)

      AND  (p_fecha_hasta IS NULL OR a."CreatedAt"::DATE <= p_fecha_hasta)

      AND  (p_module_name IS NULL OR a."ModuleName" = p_module_name)

DROP FUNCTION IF EXISTSIS NULL OR a."UserName"   = p_user_name)

      AND  (p_action_type IS NULL OR a."ActionType" = p_action_type)

      AND  (p_entity_name IS NULL OR a."EntityName" = p_entity_name)

      AND  (p_search      IS NULL OR a."Summary" LIKE '%' || p_search || '%');



    RETURN QUERY

    SELECT v_total,

           a."AuditLogId",

           a."CompanyId",

           a."BranchId",

           a."UserId",

           a."UserName",

DROP FUNCTION IF EXISTS

           a."EntityName",

           a."EntityId",

           a."ActionType",

           a."Summary",

           a."IpAddress",

           a."CreatedAt"

    FROM   audit."AuditLog" a

    WHERE  a."CompanyId" = p_company_id

      AND  a."BranchId"  = p_branch_id

      AND  (p_fecha_desde IS NULL OR a."CreatedAt"::DATE >= p_fecha_desde)

      AND  (p_fecha_hasta IS NULL OR a."CreatedAt"::DATE <= p_fecha_hasta)

      AND  (p_module_name IS NULL OR a."ModuleName" = p_module_name)

      AND  (p_user_name   IS NULL OR a."UserName"   = p_user_name)

      AND  (p_action_type IS NULL OR a."ActionType" = p_action_type)

      AND  (p_entity_name IS NULL OR a."EntityName" = p_entity_name)

DROP FUNCTION IF EXISTSIS NULL OR a."Summary" LIKE '%' || p_search || '%')

    ORDER BY a."CreatedAt" DESC

    LIMIT v_limit OFFSET v_offset;

END;

$function$
;

-- usp_fiscal_declaration_amend
DROP FUNCTION IF EXISTS public.usp_fiscal_declaration_amend(integer, bigint, character varying, integer, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_declaration_amend(p_company_id integer, p_declaration_id bigint, p_cod_usuario character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_current_status VARCHAR(20);

BEGIN

    p_resultado := 0;

    p_mensaje   := '';



    SELECT "Status" INTO v_current_status

    FROM fiscal."TaxDeclaration"

    WHERE "CompanyId"     = p_company_id

      AND "DeclarationId" = p_declaration_id;



    IF v_current_status IS NULL THEN

DROP FUNCTION IF EXISTSaracion no encontrada';

        RETURN;

    END IF;



    IF v_current_status <> 'SUBMITTED' THEN

        p_mensaje := 'Solo se puede enmendar una declaracion en estado SUBMITTED. Estado actual: ' || v_current_status;

        RETURN;

    END IF;



    UPDATE fiscal."TaxDeclaration"

    SET "Status"    = 'AMENDED',

        "UpdatedBy" = p_cod_usuario,
DROP FUNCTION IF EXISTS
        "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')

    WHERE "CompanyId"     = p_company_id

      AND "DeclarationId" = p_declaration_id;



    p_resultado := 1;

    p_mensaje   := 'Declaracion marcada como enmendada';

END;

$function$
;

-- usp_fiscal_declaration_calculate
DROP FUNCTION IF EXISTS public.usp_fiscal_declaration_calculate(integer, character varying, character varying, character varying, character varying, bigint, integer, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_declaration_calculate(p_company_id integer, p_declaration_type character varying, p_period_code character varying, p_country_code character varying, p_cod_usuario character varying, OUT p_declaration_id bigint, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$

DROP FUNCTION IF EXISTS

    v_period_start       DATE;

    v_period_end         DATE;

    v_sales_base         NUMERIC(18,2) := 0;

    v_sales_tax          NUMERIC(18,2) := 0;

    v_purchases_base     NUMERIC(18,2) := 0;

    v_purchases_tax      NUMERIC(18,2) := 0;

    v_withholdings_credit NUMERIC(18,2) := 0;

    v_taxable_base       NUMERIC(18,2) := 0;

    v_tax_amount         NUMERIC(18,2) := 0;

    v_net_payable        NUMERIC(18,2) := 0;

BEGIN

    p_declaration_id := 0;

    p_resultado      := 0;

    p_mensaje        := '';


DROP FUNCTION IF EXISTS
    v_period_start := CAST(p_period_code || '-01' AS DATE);

    v_period_end   := (DATE_TRUNC('month', v_period_start) + INTERVAL '1 month - 1 day')::DATE;



    BEGIN

        IF p_declaration_type IN ('IVA', 'MODELO_303') THEN

            SELECT COALESCE(SUM("TaxableBase"), 0), COALESCE(SUM("TaxAmount"), 0)

            INTO v_sales_base, v_sales_tax

            FROM fiscal."TaxBookEntry"

            WHERE "CompanyId"   = p_company_id

              AND "BookType"    = 'SALES'

              AND "PeriodCode"  = p_period_code

              AND "CountryCode" = p_country_code;



            SELECT COALESCE(SUM("TaxableBase"), 0), COALESCE(SUM("TaxAmount"), 0)

            INTO v_purchases_base, v_purchases_tax

            FROM fiscal."TaxBookEntry"

            WHERE "CompanyId"   = p_company_id

              AND "BookType"    = 'PURCHASE'

              AND "PeriodCode"  = p_period_code

              AND "CountryCode" = p_country_code;



            SELECT COALESCE(SUM("WithholdingAmount"), 0)

            INTO v_withholdings_credit

            FROM fiscal."WithholdingVoucher"

            WHERE "CompanyId"      = p_company_id

              AND "PeriodCode"     = p_period_code

              AND "WithholdingType" = 'IVA'

              AND "CountryCode"    = p_country_code;



            v_taxable_base := v_sales_base - v_purchases_base;

            v_tax_amount   := v_sales_tax  - v_purchases_tax;

            v_net_payable  := v_tax_amount - v_withholdings_credit;



        ELSIF p_declaration_type IN ('ISLR', 'IRPF') THEN

            SELECT COALESCE(SUM("TaxableBase"), 0), COALESCE(SUM("TaxAmount"), 0)

            INTO v_sales_base, v_sales_tax

            FROM fiscal."TaxBookEntry"

            WHERE "CompanyId"   = p_company_id

              AND "BookType"    = 'SALES'

              AND "PeriodCode"  = p_period_code

              AND "CountryCode" = p_country_code;



            SELECT COALESCE(SUM("TaxableBase"), 0), COALESCE(SUM("TaxAmount"), 0)

            INTO v_purchases_base, v_purchases_tax

            FROM fiscal."TaxBookEntry"

            WHERE "CompanyId"   = p_company_id

              AND "BookType"    = 'PURCHASE'

              AND "PeriodCode"  = p_period_code

              AND "CountryCode" = p_country_code;



            SELECT COALESCE(SUM("WithholdingAmount"), 0)

            INTO v_withholdings_credit

            FROM fiscal."WithholdingVoucher"

            WHERE "CompanyId"      = p_company_id

              AND "PeriodCode"     = p_period_code

              AND "WithholdingType" = p_declaration_type

              AND "CountryCode"    = p_country_code;



            v_taxable_base := v_sales_base - v_purchases_base;

            v_tax_amount   := v_sales_tax  - v_purchases_tax;

            v_net_payable  := v_tax_amount - v_withholdings_credit;

        ELSE

            p_resultado      := 0;
DROP FUNCTION IF EXISTS
            p_declaration_id := 0;

            p_mensaje        := 'Tipo de declaracion no soportado: ' || p_declaration_type;

            RETURN;

        END IF;



        -- Eliminar borrador previo

        DELETE FROM fiscal."TaxDeclaration"

        WHERE "CompanyId"       = p_company_id

          AND "DeclarationType" = p_declaration_type

          AND "PeriodCode"      = p_period_code

          AND "CountryCode"     = p_country_code

          AND "Status"          = 'DRAFT';


DROP FUNCTION IF EXISTS
        INSERT INTO fiscal."TaxDeclaration" (

            "CompanyId", "CountryCode", "DeclarationType",

            "PeriodCode", "PeriodStart", "PeriodEnd",

            "SalesBase", "SalesTax", "PurchasesBase", "PurchasesTax",

            "TaxableBase", "TaxAmount", "WithholdingsCredit",

            "PreviousBalance", "NetPayable", "Status", "CreatedBy", "CreatedAt"

        )

        VALUES (

            p_company_id, p_country_code, p_declaration_type,

            p_period_code, v_period_start, v_period_end,

            v_sales_base, v_sales_tax, v_purchases_base, v_purchases_tax,

            v_taxable_base, v_tax_amount, v_withholdings_credit,

            0, v_net_payable, 'CALCULATED', p_cod_usuario, (NOW() AT TIME ZONE 'UTC')

        )

        RETURNING "DeclarationId" INTO p_declaration_id;



        p_resultado := 1;

        p_mensaje   := 'Declaracion calculada. Base: ' || v_taxable_base::TEXT

                     || ', Impuesto: ' || v_tax_amount::TEXT

                     || ', Neto a pagar: ' || v_net_payable::TEXT;

    EXCEPTION WHEN OTHERS THEN

        p_resultado      := 0;

        p_declaration_id := 0;

        p_mensaje        := 'Error: ' || SQLERRM;

    END;

END;

$function$
;

-- usp_fiscal_declaration_get
DROP FUNCTION IF EXISTS public.usp_fiscal_declaration_get(integer, bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_declaration_get(p_company_id integer, p_declaration_id bigint)
 RETURNS TABLE("DeclarationId" bigint, "CompanyId" integer, "BranchId" integer, "CountryCode" character varying, "DeclarationType" character varying, "PeriodCode" character varying, "PeriodStart" date, "PeriodEnd" date, "SalesBase" numeric, "SalesTax" numeric, "PurchasesBase" numeric, "PurchasesTax" numeric, "TaxableBase" numeric, "TaxAmount" numeric, "WithholdingsCredit" numeric, "PreviousBalance" numeric, "NetPayable" numeric, "Status" character varying, "SubmittedAt" timestamp without time zone, "SubmittedFile" character varying, "AuthorityResponse" character varying, "PaidAt" timestamp without time zone, "PaymentReference" character varying, "JournalEntryId" bigint, "Notes" character varying, "CreatedBy" character varying, "UpdatedBy" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT "DeclarationId", "CompanyId", "BranchId", "CountryCode",

           "DeclarationType", "PeriodCode", "PeriodStart", "PeriodEnd",

           "SalesBase", "SalesTax", "PurchasesBase", "PurchasesTax",

           "TaxableBase", "TaxAmount", "WithholdingsCredit",

           "PreviousBalance", "NetPayable", "Status",

           "SubmittedAt", "SubmittedFile", "AuthorityResponse",

           "PaidAt", "PaymentReference", "JournalEntryId", "Notes",

           "CreatedBy", "UpdatedBy", "CreatedAt", "UpdatedAt"

    FROM fiscal."TaxDeclaration"

    WHERE "CompanyId"     = p_company_id

      AND "DeclarationId" = p_declaration_id

    LIMIT 1;

DROP FUNCTION IF EXISTS

$function$
;

-- usp_fiscal_declaration_list
DROP FUNCTION IF EXISTS public.usp_fiscal_declaration_list(integer, character varying, integer, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_declaration_list(p_company_id integer, p_declaration_type character varying DEFAULT NULL::character varying, p_year integer DEFAULT NULL::integer, p_status character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "DeclarationId" bigint, "CompanyId" integer, "BranchId" integer, "CountryCode" character varying, "DeclarationType" character varying, "PeriodCode" character varying, "PeriodStart" date, "PeriodEnd" date, "SalesBase" numeric, "SalesTax" numeric, "PurchasesBase" numeric, "PurchasesTax" numeric, "TaxableBase" numeric, "TaxAmount" numeric, "WithholdingsCredit" numeric, "PreviousBalance" numeric, "NetPayable" numeric, "Status" character varying, "SubmittedAt" timestamp without time zone, "SubmittedFile" character varying, "AuthorityResponse" character varying, "PaidAt" timestamp without time zone, "PaymentReference" character varying, "JournalEntryId" bigint, "Notes" character varying, "CreatedBy" character varying, "UpdatedBy" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$

BEGIN

    IF p_page  < 1   THEN p_page  := 1;  END IF;

    IF p_limit < 1   THEN p_limit := 50; END IF;

    IF p_limit > 500 THEN p_limit := 500; END IF;



DROP FUNCTION IF EXISTS

    SELECT COUNT(*) OVER()  AS p_total_count,

           "DeclarationId", "CompanyId", "BranchId", "CountryCode",

           "DeclarationType", "PeriodCode", "PeriodStart", "PeriodEnd",

           "SalesBase", "SalesTax", "PurchasesBase", "PurchasesTax",

           "TaxableBase", "TaxAmount", "WithholdingsCredit",

           "PreviousBalance", "NetPayable", "Status",

           "SubmittedAt", "SubmittedFile", "AuthorityResponse",

           "PaidAt", "PaymentReference", "JournalEntryId", "Notes",

           "CreatedBy", "UpdatedBy", "CreatedAt", "UpdatedAt"

    FROM fiscal."TaxDeclaration"

    WHERE "CompanyId" = p_company_id

      AND (p_declaration_type IS NULL OR "DeclarationType" = p_declaration_type)

      AND (p_year IS NULL OR LEFT("PeriodCode", 4) = CAST(p_year AS VARCHAR(4)))

      AND (p_status IS NULL OR "Status" = p_status)

DROP FUNCTION IF EXISTSDESC

    LIMIT p_limit OFFSET (p_page - 1) * p_limit;

END;

$function$
;

-- usp_fiscal_declaration_submit
DROP FUNCTION IF EXISTS public.usp_fiscal_declaration_submit(integer, bigint, character varying, text, integer, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_declaration_submit(p_company_id integer, p_declaration_id bigint, p_cod_usuario character varying, p_file_path text DEFAULT NULL::text, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$

DECLARE
DROP FUNCTION IF EXISTS
    v_current_status VARCHAR(20);

BEGIN

    p_resultado := 0;

    p_mensaje   := '';



    SELECT "Status" INTO v_current_status

    FROM fiscal."TaxDeclaration"

    WHERE "CompanyId"     = p_company_id

DROP FUNCTION IF EXISTS= p_declaration_id;



    IF v_current_status IS NULL THEN

        p_mensaje := 'Declaracion no encontrada';

        RETURN;

    END IF;



    IF v_current_status <> 'CALCULATED' THEN

        p_mensaje := 'Solo se puede presentar una declaracion en estado CALCULATED. Estado actual: ' || v_current_status;

        RETURN;

    END IF;



    UPDATE fiscal."TaxDeclaration"

    SET "Status"        = 'SUBMITTED',

        "SubmittedAt"   = (NOW() AT TIME ZONE 'UTC'),

        "SubmittedFile" = p_file_path,

        "UpdatedBy"     = p_cod_usuario,

        "UpdatedAt"     = (NOW() AT TIME ZONE 'UTC')

    WHERE "CompanyId"     = p_company_id

      AND "DeclarationId" = p_declaration_id;



    p_resultado := 1;

    p_mensaje   := 'Declaracion presentada exitosamente';

END;

$function$
;

-- usp_fiscal_export_declaration
DROP FUNCTION IF EXISTS public.usp_fiscal_export_declaration(integer, bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_export_declaration(p_company_id integer, p_declaration_id bigint)
 RETURNS TABLE("DeclarationId" bigint, "CompanyId" integer, "BranchId" integer, "CountryCode" character varying, "DeclarationType" character varying, "PeriodCode" character varying, "PeriodStart" date, "PeriodEnd" date, "SalesBase" numeric, "SalesTax" numeric, "PurchasesBase" numeric, "PurchasesTax" numeric, "TaxableBase" numeric, "TaxAmount" numeric, "WithholdingsCredit" numeric, "PreviousBalance" numeric, "NetPayable" numeric, "Status" character varying, "SubmittedAt" timestamp without time zone, "SubmittedFile" character varying, "AuthorityResponse" character varying, "PaidAt" timestamp without time zone, "PaymentReference" character varying, "JournalEntryId" bigint, "Notes" character varying, "CreatedBy" character varying, "UpdatedBy" character varying, "CreatedAt" timestamp without time zone, "UpdatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT "DeclarationId", "CompanyId", "BranchId", "CountryCode",

           "DeclarationType", "PeriodCode", "PeriodStart", "PeriodEnd",

           "SalesBase", "SalesTax", "PurchasesBase", "PurchasesTax",

           "TaxableBase", "TaxAmount", "WithholdingsCredit",

           "PreviousBalance", "NetPayable", "Status",

           "SubmittedAt", "SubmittedFile", "AuthorityResponse",

           "PaidAt", "PaymentReference", "JournalEntryId", "Notes",

           "CreatedBy", "UpdatedBy", "CreatedAt", "UpdatedAt"

    FROM fiscal."TaxDeclaration"

    WHERE "CompanyId"     = p_company_id

      AND "DeclarationId" = p_declaration_id;

END;

$function$
;

-- usp_fiscal_export_taxbook
DROP FUNCTION IF EXISTS public.usp_fiscal_export_taxbook(integer, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_export_taxbook(p_company_id integer, p_book_type character varying, p_period_code character varying, p_country_code character varying)
 RETURNS TABLE("EntryId" bigint, "CompanyId" integer, "BookType" character varying, "PeriodCode" character varying, "EntryDate" date, "DocumentNumber" character varying, "DocumentType" character varying, "ControlNumber" character varying, "ThirdPartyId" character varying, "ThirdPartyName" character varying, "TaxableBase" numeric, "ExemptAmount" numeric, "TaxRate" numeric, "TaxAmount" numeric, "WithholdingRate" numeric, "WithholdingAmount" numeric, "TotalAmount" numeric, "SourceDocumentId" bigint, "SourceModule" character varying, "CountryCode" character varying, "DeclarationId" bigint, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT "EntryId", "CompanyId", "BookType", "PeriodCode", "EntryDate",

           "DocumentNumber", "DocumentType", "ControlNumber",

           "ThirdPartyId", "ThirdPartyName",

           "TaxableBase", "ExemptAmount", "TaxRate", "TaxAmount",

           "WithholdingRate", "WithholdingAmount", "TotalAmount",

           "SourceDocumentId", "SourceModule", "CountryCode",

           "DeclarationId", "CreatedAt"

    FROM fiscal."TaxBookEntry"

    WHERE "CompanyId"   = p_company_id

      AND "BookType"    = p_book_type

      AND "PeriodCode"  = p_period_code

      AND "CountryCode" = p_country_code

    ORDER BY "EntryDate", "DocumentNumber";

END;

$function$
;

-- usp_fiscal_taxbook_list
DROP FUNCTION IF EXISTS public.usp_fiscal_taxbook_list(integer, character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_taxbook_list(p_company_id integer, p_book_type character varying, p_period_code character varying, p_country_code character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 100)
 RETURNS TABLE(p_total_count bigint, "EntryId" bigint, "CompanyId" integer, "BookType" character varying, "PeriodCode" character varying, "EntryDate" date, "DocumentNumber" character varying, "DocumentType" character varying, "ControlNumber" character varying, "ThirdPartyId" character varying, "ThirdPartyName" character varying, "TaxableBase" numeric, "ExemptAmount" numeric, "TaxRate" numeric, "TaxAmount" numeric, "WithholdingRate" numeric, "WithholdingAmount" numeric, "TotalAmount" numeric, "SourceDocumentId" bigint, "SourceModule" character varying, "CountryCode" character varying, "DeclarationId" bigint, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$

BEGIN

    IF p_page  < 1   THEN p_page  := 1;   END IF;

    IF p_limit < 1   THEN p_limit := 100;  END IF;

    IF p_limit > 500 THEN p_limit := 500;  END IF;



    RETURN QUERY

    SELECT COUNT(*) OVER()  AS p_total_count,

           "EntryId", "CompanyId", "BookType", "PeriodCode", "EntryDate",

           "DocumentNumber", "DocumentType", "ControlNumber",

           "ThirdPartyId", "ThirdPartyName",

           "TaxableBase", "ExemptAmount", "TaxRate", "TaxAmount",

           "WithholdingRate", "WithholdingAmount", "TotalAmount",

           "SourceDocumentId", "SourceModule", "CountryCode",

           "DeclarationId", "CreatedAt"

    FROM fiscal."TaxBookEntry"

    WHERE "CompanyId"   = p_company_id

      AND "BookType"    = p_book_type

      AND "PeriodCode"  = p_period_code

      AND "CountryCode" = p_country_code

    ORDER BY "EntryDate", "DocumentNumber"

    LIMIT p_limit OFFSET (p_page - 1) * p_limit;

END;

$function$
;

-- usp_fiscal_taxbook_populate
DROP FUNCTION IF EXISTS public.usp_fiscal_taxbook_populate(integer, character varying, character varying, character varying, character varying, integer, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_taxbook_populate(p_company_id integer, p_book_type character varying, p_period_code character varying, p_country_code character varying, p_cod_usuario character varying, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_period_start  DATE;

    v_period_end    DATE;

    v_rows_inserted INTEGER := 0;

BEGIN

    p_resultado := 0;

    p_mensaje   := '';



    v_period_start := CAST(p_period_code || '-01' AS DATE);

    v_period_end   := (DATE_TRUNC('month', v_period_start) + INTERVAL '1 month - 1 day')::DATE;



    IF p_book_type NOT IN ('SALES', 'PURCHASE') THEN

        p_resultado := 0;

        p_mensaje   := 'BookType debe ser SALES o PURCHASE';

        RETURN;

    END IF;



    BEGIN

        -- Eliminar entradas existentes para regenerar

        DELETE FROM fiscal."TaxBookEntry"

        WHERE "CompanyId"   = p_company_id

          AND "BookType"    = p_book_type

          AND "PeriodCode"  = p_period_code

          AND "CountryCode" = p_country_code;



        IF p_book_type = 'SALES' THEN

            -- Fuente: dbo.DocumentosVenta

            INSERT INTO fiscal."TaxBookEntry" (

                "CompanyId", "BookType", "PeriodCode", "EntryDate",

                "DocumentNumber", "DocumentType", "ControlNumber",

                "ThirdPartyId", "ThirdPartyName",

                "TaxableBase", "ExemptAmount", "TaxRate", "TaxAmount",

                "WithholdingRate", "WithholdingAmount", "TotalAmount",

                "SourceDocumentId", "SourceModule", "CountryCode", "CreatedAt"

            )

            SELECT

                p_company_id,

                'SALES',

                p_period_code,

                v."FECHA",

                v."NUM_DOC",

                CASE v."SERIALTIPO"

                    WHEN 'FAC' THEN 'FACTURA'

                    WHEN 'NC'  THEN 'NOTA_CREDITO'

                    WHEN 'ND'  THEN 'NOTA_DEBITO'

                    ELSE v."SERIALTIPO"

                END,

                v."NUM_CONTROL",

                v."RIF",

                v."NOMBRE",

                COALESCE(v."MONTO_GRA", 0),

                COALESCE(v."MONTO_EXE", 0),

                COALESCE(v."ALICUOTA", 0),

                COALESCE(v."IVA", 0),

                0,

                0,

                COALESCE(v."TOTAL", 0),

                v."ID",

                'AR',

                p_country_code,

                (NOW() AT TIME ZONE 'UTC')

            FROM dbo."DocumentosVenta" v

            WHERE v."FECHA" BETWEEN v_period_start AND v_period_end

              AND v."ANULADA" = 0;



            GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;



        ELSIF p_book_type = 'PURCHASE' THEN

            -- Fuente: dbo.DocumentosCompra

            INSERT INTO fiscal."TaxBookEntry" (

                "CompanyId", "BookType", "PeriodCode", "EntryDate",

                "DocumentNumber", "DocumentType", "ControlNumber",

                "ThirdPartyId", "ThirdPartyName",

                "TaxableBase", "ExemptAmount", "TaxRate", "TaxAmount",

                "WithholdingRate", "WithholdingAmount", "TotalAmount",

                "SourceDocumentId", "SourceModule", "CountryCode", "CreatedAt"

            )

            SELECT

                p_company_id,

                'PURCHASE',

                p_period_code,

                c."FECHA",

                c."NUM_DOC",

                CASE c."SERIALTIPO"

                    WHEN 'FAC' THEN 'FACTURA'

                    WHEN 'NC'  THEN 'NOTA_CREDITO'

                    WHEN 'ND'  THEN 'NOTA_DEBITO'

                    ELSE c."SERIALTIPO"

                END,

                c."NUM_CONTROL",

                c."RIF",

                c."NOMBRE",

                COALESCE(c."MONTO_GRA", 0),

                COALESCE(c."MONTO_EXE", 0),

                COALESCE(c."ALICUOTA", 0),

                COALESCE(c."IVA", 0),

                0,

                0,

                COALESCE(c."TOTAL", 0),

                c."ID",

                'AP',

                p_country_code,

                (NOW() AT TIME ZONE 'UTC')

            FROM dbo."DocumentosCompra" c

            WHERE c."FECHA" BETWEEN v_period_start AND v_period_end

              AND c."ANULADA" = 0;



            GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;

        END IF;



        p_resultado := 1;

        p_mensaje   := 'Libro fiscal generado: ' || v_rows_inserted::TEXT || ' registros';

    EXCEPTION WHEN OTHERS THEN

        p_resultado := 0;

        p_mensaje   := 'Error: ' || SQLERRM;

    END;

END;

$function$
;

-- usp_fiscal_taxbook_summary
DROP FUNCTION IF EXISTS public.usp_fiscal_taxbook_summary(integer, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_taxbook_summary(p_company_id integer, p_book_type character varying, p_period_code character varying, p_country_code character varying)
 RETURNS TABLE("TaxRate" numeric, "TaxableBase" numeric, "ExemptAmount" numeric, "TaxAmount" numeric, "WithholdingAmount" numeric, "TotalAmount" numeric, "EntryCount" bigint)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT "TaxRate",

           SUM("TaxableBase")        AS "TaxableBase",

           SUM("ExemptAmount")       AS "ExemptAmount",

           SUM("TaxAmount")          AS "TaxAmount",

           SUM("WithholdingAmount")  AS "WithholdingAmount",

           SUM("TotalAmount")        AS "TotalAmount",

           COUNT(*)                  AS "EntryCount"

    FROM fiscal."TaxBookEntry"

    WHERE "CompanyId"   = p_company_id

      AND "BookType"    = p_book_type

      AND "PeriodCode"  = p_period_code

      AND "CountryCode" = p_country_code

    GROUP BY "TaxRate"

    ORDER BY "TaxRate";

END;

$function$
;

-- usp_fiscal_withholding_generate
DROP FUNCTION IF EXISTS public.usp_fiscal_withholding_generate(integer, bigint, character varying, character varying, character varying, bigint, integer, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_withholding_generate(p_company_id integer, p_document_id bigint, p_withholding_type character varying, p_country_code character varying, p_cod_usuario character varying, OUT p_voucher_id bigint, OUT p_resultado integer, OUT p_mensaje text)
 RETURNS record
 LANGUAGE plpgsql
AS $function$

DECLARE

    v_taxable_base       NUMERIC(18,2);

    v_rate               NUMERIC(8,4);

    v_withholding_amount NUMERIC(18,2);

    v_period_code        VARCHAR(7);

    v_voucher_number     VARCHAR(50);

    v_next_seq           INTEGER;

    v_doc_fecha          DATE;

    v_doc_num_doc        VARCHAR(50);

    v_third_party_id     VARCHAR(50);

    v_third_party_name   VARCHAR(200);

BEGIN

    p_voucher_id := 0;

    p_resultado  := 0;

    p_mensaje    := '';



    SELECT COALESCE(c."MONTO_GRA", 0), c."FECHA", c."NUM_DOC", c."RIF", c."NOMBRE"

    INTO v_taxable_base, v_doc_fecha, v_doc_num_doc, v_third_party_id, v_third_party_name

    FROM dbo."DocumentosCompra" c

    WHERE c."ID" = p_document_id;



    IF v_taxable_base IS NULL THEN

        p_voucher_id := 0;

        p_mensaje    := 'Documento de compra no encontrado';

        RETURN;

    END IF;



    SELECT "RetentionRate" INTO v_rate

    FROM master."TaxRetention"

    WHERE "RetentionType" = p_withholding_type

      AND "CountryCode"   = p_country_code

    LIMIT 1;



    IF v_rate IS NULL THEN

        p_voucher_id := 0;

        p_mensaje    := 'Tasa de retencion no configurada para tipo: ' || p_withholding_type || ', pais: ' || p_country_code;

        RETURN;

    END IF;



    v_withholding_amount := ROUND(v_taxable_base * v_rate / 100.0, 2);

    v_period_code        := TO_CHAR(v_doc_fecha, 'YYYY-MM');



    BEGIN

        SELECT COALESCE(MAX(

            CAST(RIGHT("VoucherNumber", 4) AS INTEGER)

        ), 0) + 1

        INTO v_next_seq

        FROM fiscal."WithholdingVoucher"

        WHERE "CompanyId"      = p_company_id

          AND "WithholdingType" = p_withholding_type

          AND "PeriodCode"     = v_period_code

          AND "CountryCode"    = p_country_code;



        v_voucher_number := p_withholding_type || '-'

                          || REPLACE(v_period_code, '-', '') || '-'

                          || LPAD(v_next_seq::TEXT, 4, '0');



        INSERT INTO fiscal."WithholdingVoucher" (

            "CompanyId", "VoucherNumber", "VoucherDate",

            "WithholdingType", "ThirdPartyId", "ThirdPartyName",

            "DocumentNumber", "DocumentDate", "TaxableBase",

            "WithholdingRate", "WithholdingAmount", "PeriodCode",

            "Status", "CountryCode", "CreatedBy", "CreatedAt"

        )

        VALUES (

            p_company_id, v_voucher_number, (NOW() AT TIME ZONE 'UTC'),

            p_withholding_type, v_third_party_id, v_third_party_name,

            v_doc_num_doc, v_doc_fecha, v_taxable_base,

            v_rate, v_withholding_amount, v_period_code,

            'GENERATED', p_country_code, p_cod_usuario, (NOW() AT TIME ZONE 'UTC')

        )

        RETURNING "VoucherId" INTO p_voucher_id;



        p_resultado := 1;

        p_mensaje   := 'Comprobante generado: ' || v_voucher_number

                     || ', Monto retenido: ' || v_withholding_amount::TEXT;

    EXCEPTION WHEN OTHERS THEN

        p_voucher_id := 0;

        p_resultado  := 0;

        p_mensaje    := 'Error: ' || SQLERRM;

    END;

END;

$function$
;

-- usp_fiscal_withholding_get
DROP FUNCTION IF EXISTS public.usp_fiscal_withholding_get(integer, bigint) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_withholding_get(p_company_id integer, p_voucher_id bigint)
 RETURNS TABLE("VoucherId" bigint, "CompanyId" integer, "VoucherNumber" character varying, "VoucherDate" timestamp without time zone, "WithholdingType" character varying, "ThirdPartyId" character varying, "ThirdPartyName" character varying, "DocumentNumber" character varying, "DocumentDate" date, "TaxableBase" numeric, "WithholdingRate" numeric, "WithholdingAmount" numeric, "PeriodCode" character varying, "Status" character varying, "CountryCode" character varying, "JournalEntryId" bigint, "CreatedBy" character varying, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT "VoucherId", "CompanyId", "VoucherNumber", "VoucherDate",

           "WithholdingType", "ThirdPartyId", "ThirdPartyName",

           "DocumentNumber", "DocumentDate", "TaxableBase",

           "WithholdingRate", "WithholdingAmount", "PeriodCode",

           "Status", "CountryCode", "JournalEntryId",

           "CreatedBy", "CreatedAt"

    FROM fiscal."WithholdingVoucher"

    WHERE "CompanyId" = p_company_id

      AND "VoucherId" = p_voucher_id

    LIMIT 1;

END;

$function$
;

-- usp_fiscal_withholding_list
DROP FUNCTION IF EXISTS public.usp_fiscal_withholding_list(integer, character varying, character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_fiscal_withholding_list(p_company_id integer, p_withholding_type character varying DEFAULT NULL::character varying, p_period_code character varying DEFAULT NULL::character varying, p_country_code character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE(p_total_count bigint, "VoucherId" bigint, "CompanyId" integer, "VoucherNumber" character varying, "VoucherDate" timestamp without time zone, "WithholdingType" character varying, "ThirdPartyId" character varying, "ThirdPartyName" character varying, "DocumentNumber" character varying, "DocumentDate" date, "TaxableBase" numeric, "WithholdingRate" numeric, "WithholdingAmount" numeric, "PeriodCode" character varying, "Status" character varying, "CountryCode" character varying, "JournalEntryId" bigint, "CreatedBy" character varying, "CreatedAt" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$

BEGIN

    IF p_page  < 1   THEN p_page  := 1;  END IF;

    IF p_limit < 1   THEN p_limit := 50; END IF;

    IF p_limit > 500 THEN p_limit := 500; END IF;



    RETURN QUERY

    SELECT COUNT(*) OVER()  AS p_total_count,

           "VoucherId", "CompanyId", "VoucherNumber", "VoucherDate",

           "WithholdingType", "ThirdPartyId", "ThirdPartyName",

           "DocumentNumber", "DocumentDate", "TaxableBase",

           "WithholdingRate", "WithholdingAmount", "PeriodCode",

           "Status", "CountryCode", "JournalEntryId",

           "CreatedBy", "CreatedAt"

    FROM fiscal."WithholdingVoucher"

    WHERE "CompanyId" = p_company_id

      AND (p_withholding_type IS NULL OR "WithholdingType" = p_withholding_type)

      AND (p_period_code      IS NULL OR "PeriodCode"      = p_period_code)

      AND (p_country_code     IS NULL OR "CountryCode"     = p_country_code)

    ORDER BY "VoucherDate" DESC

    LIMIT p_limit OFFSET (p_page - 1) * p_limit;

END;

$function$
;

-- usp_tax_retention_count
DROP FUNCTION IF EXISTS public.usp_tax_retention_count(character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_tax_retention_count(p_search character varying DEFAULT NULL::character varying, p_tipo character varying DEFAULT NULL::character varying)
 RETURNS TABLE(total bigint)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT COUNT(1)

    FROM master."TaxRetention"

    WHERE "IsDeleted" = FALSE

      AND (p_search IS NULL OR ("RetentionCode" ILIKE '%' || p_search || '%' OR "Description" ILIKE '%' || p_search || '%'))

      AND (p_tipo IS NULL OR "RetentionType" = p_tipo);

END;

$function$
;

-- usp_tax_retention_getbycode
DROP FUNCTION IF EXISTS public.usp_tax_retention_getbycode(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_tax_retention_getbycode(p_codigo character varying)
 RETURNS TABLE("RetentionId" integer, "Codigo" character varying, "Descripcion" character varying, "Tipo" character varying, "Porcentaje" numeric, "Pais" character varying, "IsActive" boolean)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT tr."RetentionId", tr."RetentionCode", tr."Description",

           tr."RetentionType", tr."RetentionRate", tr."CountryCode", tr."IsActive"

    FROM master."TaxRetention" tr

    WHERE tr."RetentionCode" = p_codigo AND tr."IsDeleted" = FALSE

    LIMIT 1;

END;

$function$
;

-- usp_tax_retention_list
DROP FUNCTION IF EXISTS public.usp_tax_retention_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_tax_retention_list(p_search character varying DEFAULT NULL::character varying, p_tipo character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE("RetentionId" integer, "Codigo" character varying, "Descripcion" character varying, "Tipo" character varying, "Porcentaje" numeric, "Pais" character varying, "IsActive" boolean)
 LANGUAGE plpgsql
AS $function$

BEGIN

    RETURN QUERY

    SELECT

        tr."RetentionId", tr."RetentionCode", tr."Description",

        tr."RetentionType", tr."RetentionRate", tr."CountryCode", tr."IsActive"

    FROM master."TaxRetention" tr

    WHERE tr."IsDeleted" = FALSE

      AND (p_search IS NULL OR (tr."RetentionCode" ILIKE '%' || p_search || '%' OR tr."Description" ILIKE '%' || p_search || '%'))

      AND (p_tipo IS NULL OR tr."RetentionType" = p_tipo)

    ORDER BY tr."RetentionCode"

    LIMIT p_limit OFFSET p_offset;

END;

$function$
;

