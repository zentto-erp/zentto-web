-- ============================================================
-- fix_timestamp_type_mismatches.sql
-- Barrido completo: corrige TIMESTAMPTZ vs TIMESTAMP en funciones PG
-- Las tablas subyacentes usan TIMESTAMP WITHOUT TIME ZONE, pero las
-- funciones declaraban TIMESTAMP WITH TIME ZONE -> "structure of query
-- does not match function result type".
-- Fix: cambiar RETURNS TABLE a TIMESTAMP (sin tz) en todas las
-- funciones afectadas.
-- Run as: psql -U postgres -d zentto_prod -f fix_timestamp_type_mismatches.sql
-- Fecha: 2026-03-17
-- ============================================================

-- --------------------------------------------------------
-- 1. usp_bank_reconciliation_getpendingstatements
-- Tabla: fin.BankStatementLine.StatementDate -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getpendingstatements(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getpendingstatements(p_id integer)
  RETURNS TABLE(
    id            bigint,
    "Fecha"       timestamp without time zone,
    "Descripcion" character varying,
    "Referencia"  character varying,
    "Tipo"        character varying,
    "Monto"       numeric,
    "Saldo"       numeric
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT sl."StatementLineId", sl."StatementDate", sl."DescriptionText", sl."ReferenceNo",
           sl."EntryType", sl."Amount", sl."Balance"
    FROM fin."BankStatementLine" sl
    WHERE sl."ReconciliationId" = p_id AND sl."IsMatched" = FALSE
    ORDER BY sl."StatementDate" DESC, sl."StatementLineId" DESC;
END;
$function$;

-- --------------------------------------------------------
-- 2. usp_bank_reconciliation_getsystemmovements
-- Tabla: fin.BankMovement.MovementDate -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_bank_reconciliation_getsystemmovements(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_bank_reconciliation_getsystemmovements(p_id integer)
  RETURNS TABLE(
    id              bigint,
    "Fecha"         timestamp without time zone,
    "Tipo"          character varying,
    "Nro_Ref"       character varying,
    "Beneficiario"  character varying,
    "Concepto"      character varying,
    "Monto"         numeric,
    "MontoNeto"     numeric,
    "SaldoPosterior" numeric,
    "Conciliado"    boolean
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."BankMovementId", m."MovementDate", m."MovementType", m."ReferenceNo",
           m."Beneficiary", m."Concept", m."Amount", m."NetAmount", m."BalanceAfter", m."IsReconciled"
    FROM fin."BankMovement" m
    INNER JOIN fin."BankReconciliation" r ON r."BankAccountId" = m."BankAccountId"
    WHERE r."BankReconciliationId" = p_id
      AND (m."MovementDate")::DATE BETWEEN r."DateFrom" AND r."DateTo"
    ORDER BY m."MovementDate" DESC, m."BankMovementId" DESC;
END;
$function$;

-- --------------------------------------------------------
-- 3. usp_inv_movement_getbyid
-- Tabla: master.InventoryMovement.CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_inv_movement_getbyid(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_getbyid(p_id integer)
  RETURNS TABLE(
    "MovementId"  integer,
    "Codigo"      character varying,
    "Product"     character varying,
    "Documento"   character varying,
    "Tipo"        character varying,
    "Fecha"       timestamp without time zone,
    "Quantity"    numeric,
    "UnitCost"    numeric,
    "TotalCost"   numeric,
    "Notes"       character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT m."MovementId", m."ProductCode", m."ProductName", m."DocumentRef",
           m."MovementType", m."MovementDate", m."Quantity", m."UnitCost", m."TotalCost", m."Notes"
    FROM master."InventoryMovement" m
    WHERE m."MovementId" = p_id AND m."IsDeleted" = FALSE;
END;
$function$;

-- --------------------------------------------------------
-- 4. usp_inv_movement_list
-- Tabla: master.InventoryMovement.MovementDate -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_inv_movement_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_list(
    p_search character varying DEFAULT NULL,
    p_tipo   character varying DEFAULT NULL,
    p_offset integer DEFAULT 0,
    p_limit  integer DEFAULT 50
)
  RETURNS TABLE(
    "MovementId"  integer,
    "Codigo"      character varying,
    "Product"     character varying,
    "Documento"   character varying,
    "Tipo"        character varying,
    "Fecha"       timestamp without time zone,
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
    SELECT m."MovementId", m."ProductCode", m."ProductName", m."DocumentRef",
           m."MovementType", m."MovementDate", m."Quantity", m."UnitCost", m."TotalCost", m."Notes", v_total
    FROM master."InventoryMovement" m
    WHERE m."IsDeleted" = FALSE
      AND (p_search IS NULL OR m."ProductCode" LIKE p_search OR m."ProductName" LIKE p_search OR m."DocumentRef" LIKE p_search)
      AND (p_tipo IS NULL OR m."MovementType" = p_tipo)
    ORDER BY m."MovementDate" DESC, m."MovementId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$;

-- --------------------------------------------------------
-- 5. usp_inv_movement_listperiodsummary
-- Tabla: master.InventoryPeriodSummary.SummaryDate -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_inv_movement_listperiodsummary(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_inv_movement_listperiodsummary(
    p_periodo character varying DEFAULT NULL,
    p_codigo  character varying DEFAULT NULL,
    p_offset  integer DEFAULT 0,
    p_limit   integer DEFAULT 50
)
  RETURNS TABLE(
    "SummaryId"   integer,
    "Periodo"     character varying,
    "Codigo"      character varying,
    "OpeningQty"  numeric,
    "InboundQty"  numeric,
    "OutboundQty" numeric,
    "ClosingQty"  numeric,
    fecha         timestamp without time zone,
    "IsClosed"    boolean,
    "TotalCount"  bigint
  )
  LANGUAGE plpgsql
AS $function$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryPeriodSummary"
    WHERE (p_periodo IS NULL OR "Period" = p_periodo)
      AND (p_codigo IS NULL OR "ProductCode" = p_codigo);

    RETURN QUERY
    SELECT s."SummaryId", s."Period", s."ProductCode", s."OpeningQty",
           s."InboundQty", s."OutboundQty", s."ClosingQty", s."SummaryDate", s."IsClosed", v_total
    FROM master."InventoryPeriodSummary" s
    WHERE (p_periodo IS NULL OR s."Period" = p_periodo)
      AND (p_codigo IS NULL OR s."ProductCode" = p_codigo)
    ORDER BY s."Period" DESC, s."ProductCode"
    LIMIT p_limit OFFSET p_offset;
END;
$function$;

-- --------------------------------------------------------
-- 6. usp_pay_cardreader_list
-- Tabla: pay.CardReaderDevices.LastSeenAt, CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_cardreader_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_cardreader_list(p_company_id integer DEFAULT NULL)
  RETURNS TABLE(
    "Id"               integer,
    "EmpresaId"        integer,
    "SucursalId"       integer,
    "StationId"        character varying,
    "DeviceName"       character varying,
    "DeviceType"       character varying,
    "ConnectionType"   character varying,
    "ConnectionConfig" character varying,
    "ProviderId"       integer,
    "IsActive"         boolean,
    "LastSeenAt"       timestamp without time zone,
    "CreatedAt"        timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cr."Id", cr."EmpresaId", cr."SucursalId", cr."StationId",
           cr."DeviceName", cr."DeviceType", cr."ConnectionType",
           cr."ConnectionConfig", cr."ProviderId", cr."IsActive",
           cr."LastSeenAt", cr."CreatedAt"
    FROM pay."CardReaderDevices" cr
    WHERE (p_company_id IS NULL OR cr."EmpresaId" = p_company_id)
    ORDER BY cr."EmpresaId", cr."StationId", cr."DeviceName";
END;
$function$;

-- --------------------------------------------------------
-- 7. usp_pay_cardreader_listbycompany
-- Tabla: pay.CardReaderDevices.LastSeenAt, CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_cardreader_listbycompany(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_cardreader_listbycompany(
    p_company_id integer,
    p_branch_id  integer DEFAULT NULL
)
  RETURNS TABLE(
    "Id"               integer,
    "EmpresaId"        integer,
    "SucursalId"       integer,
    "StationId"        character varying,
    "DeviceName"       character varying,
    "DeviceType"       character varying,
    "ConnectionType"   character varying,
    "ConnectionConfig" character varying,
    "ProviderId"       integer,
    "IsActive"         boolean,
    "LastSeenAt"       timestamp without time zone,
    "CreatedAt"        timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cr."Id", cr."EmpresaId", cr."SucursalId", cr."StationId",
           cr."DeviceName", cr."DeviceType", cr."ConnectionType",
           cr."ConnectionConfig", cr."ProviderId", cr."IsActive",
           cr."LastSeenAt", cr."CreatedAt"
    FROM pay."CardReaderDevices" cr
    WHERE cr."EmpresaId" = p_company_id
      AND cr."IsActive" = TRUE
      AND (p_branch_id IS NULL OR cr."SucursalId" = p_branch_id)
    ORDER BY cr."StationId", cr."DeviceName";
END;
$function$;

-- --------------------------------------------------------
-- 8. usp_pay_companyconfig_list
-- Tabla: pay.CompanyPaymentConfig.CreatedAt, UpdatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_companyconfig_list(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_list(p_company_id integer DEFAULT NULL)
  RETURNS TABLE(
    "Id"            integer,
    "EmpresaId"     integer,
    "SucursalId"    integer,
    "CountryCode"   character varying,
    "ProviderId"    integer,
    "ProviderCode"  character varying,
    "ProviderName"  character varying,
    "ProviderType"  character varying,
    "Environment"   character varying,
    "AutoCapture"   boolean,
    "AllowRefunds"  boolean,
    "MaxRefundDays" integer,
    "IsActive"      boolean,
    "CreatedAt"     timestamp without time zone,
    "UpdatedAt"     timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode",
           cc."ProviderId", p."Code", p."Name", p."ProviderType",
           cc."Environment", cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE (p_company_id IS NULL OR cc."EmpresaId" = p_company_id)
    ORDER BY cc."EmpresaId", p."Code";
END;
$function$;

-- --------------------------------------------------------
-- 9. usp_pay_companyconfig_listbycompany
-- Tabla: pay.CompanyPaymentConfig.CreatedAt, UpdatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_companyconfig_listbycompany(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_listbycompany(
    p_company_id integer,
    p_branch_id  integer DEFAULT NULL
)
  RETURNS TABLE(
    "Id"               integer,
    "EmpresaId"        integer,
    "SucursalId"       integer,
    "CountryCode"      character varying,
    "ProviderId"       integer,
    "ProviderCode"     character varying,
    "ProviderName"     character varying,
    "ProviderType"     character varying,
    "Environment"      character varying,
    "ClientId"         character varying,
    "ClientSecret"     character varying,
    "MerchantId"       character varying,
    "TerminalId"       character varying,
    "IntegratorId"     character varying,
    "CertificatePath"  character varying,
    "ExtraConfig"      character varying,
    "AutoCapture"      boolean,
    "AllowRefunds"     boolean,
    "MaxRefundDays"    integer,
    "IsActive"         boolean,
    "CreatedAt"        timestamp without time zone,
    "UpdatedAt"        timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode",
           cc."ProviderId", p."Code", p."Name", p."ProviderType",
           cc."Environment", cc."ClientId", cc."ClientSecret",
           cc."MerchantId", cc."TerminalId", cc."IntegratorId",
           cc."CertificatePath", cc."ExtraConfig",
           cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE cc."EmpresaId" = p_company_id
      AND (p_branch_id IS NULL OR cc."SucursalId" = p_branch_id)
    ORDER BY p."Name";
END;
$function$;

-- --------------------------------------------------------
-- 10. usp_pay_provider_get
-- Tabla: pay.PaymentProviders.CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_provider_get(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pay_provider_get(p_provider_code character varying)
  RETURNS TABLE(
    "Id"             integer,
    "Code"           character varying,
    "Name"           character varying,
    "CountryCode"    character varying,
    "ProviderType"   character varying,
    "BaseUrlSandbox" character varying,
    "BaseUrlProd"    character varying,
    "AuthType"       character varying,
    "DocsUrl"        character varying,
    "LogoUrl"        character varying,
    "IsActive"       boolean,
    "CreatedAt"      timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT pp."Id", pp."Code", pp."Name", pp."CountryCode",
           pp."ProviderType", pp."BaseUrlSandbox", pp."BaseUrlProd",
           pp."AuthType", pp."DocsUrl", pp."LogoUrl",
           pp."IsActive", pp."CreatedAt"
    FROM pay."PaymentProviders" pp
    WHERE pp."Code" = p_provider_code
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 11. usp_pos_report_ventas
-- Tabla: pos.SaleTicket.SoldAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pos_report_ventas(integer, integer, date, date, character varying, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pos_report_ventas(
    p_company_id integer,
    p_branch_id  integer,
    p_from_date  date,
    p_to_date    date,
    p_caja_id    character varying DEFAULT NULL,
    p_limit      integer DEFAULT 200
)
  RETURNS TABLE(
    id                   integer,
    "numFactura"         character varying,
    fecha                timestamp without time zone,
    cliente              character varying,
    "cajaId"             character varying,
    total                numeric,
    estado               character varying,
    "metodoPago"         character varying,
    "tramaFiscal"        character varying,
    "serialFiscal"       character varying,
    "correlativoFiscal"  integer
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        v."SaleTicketId",
        v."InvoiceNumber",
        v."SoldAt",
        COALESCE(NULLIF(TRIM(v."CustomerName"), ''), 'Consumidor Final')::character varying::VARCHAR,
        v."CashRegisterCode",
        v."TotalAmount",
        'Completada'::VARCHAR,
        v."PaymentMethod",
        v."FiscalPayload",
        corr."SerialFiscal",
        corr."CurrentNumber"
    FROM pos."SaleTicket" v
    LEFT JOIN LATERAL (
        SELECT fc."SerialFiscal", fc."CurrentNumber"
        FROM pos."FiscalCorrelative" fc
        WHERE fc."CompanyId" = v."CompanyId" AND fc."BranchId" = v."BranchId"
          AND fc."CorrelativeType" = 'FACTURA' AND fc."IsActive" = TRUE
          AND fc."CashRegisterCode" IN (UPPER(v."CashRegisterCode")::character varying, 'GLOBAL')
        ORDER BY CASE WHEN fc."CashRegisterCode" = UPPER(v."CashRegisterCode")::character varying THEN 0 ELSE 1 END,
                 fc."FiscalCorrelativeId" DESC
        LIMIT 1
    ) corr ON TRUE
    WHERE v."CompanyId" = p_company_id AND v."BranchId" = p_branch_id
      AND (v."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
      AND (p_caja_id IS NULL OR UPPER(v."CashRegisterCode")::character varying = p_caja_id)
    ORDER BY v."SoldAt" DESC, v."SaleTicketId" DESC
    LIMIT p_limit;
END;
$function$;

-- --------------------------------------------------------
-- 12. usp_pos_waitticket_getheader
-- Tabla: pos.WaitTicket.CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pos_waitticket_getheader(integer, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_getheader(
    p_company_id     integer,
    p_branch_id      integer,
    p_wait_ticket_id integer
)
  RETURNS TABLE(
    id               integer,
    "cajaId"         character varying,
    "estacionNombre" character varying,
    "clienteId"      character varying,
    "clienteNombre"  character varying,
    "clienteRif"     character varying,
    "tipoPrecio"     character varying,
    motivo           character varying,
    subtotal         numeric,
    impuestos        numeric,
    total            numeric,
    estado           character varying,
    "fechaCreacion"  timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT wt."WaitTicketId", wt."CashRegisterCode", wt."StationName", wt."CustomerCode",
           wt."CustomerName", wt."CustomerFiscalId", wt."PriceTier", wt."Reason",
           wt."NetAmount", wt."TaxAmount", wt."TotalAmount", wt."Status", wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id
      AND wt."BranchId" = p_branch_id
      AND wt."WaitTicketId" = p_wait_ticket_id
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 13. usp_pos_waitticket_list
-- Tabla: pos.WaitTicket.CreatedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pos_waitticket_list(integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_list(p_company_id integer, p_branch_id integer)
  RETURNS TABLE(
    id               integer,
    "cajaId"         character varying,
    "estacionNombre" character varying,
    "clienteNombre"  character varying,
    motivo           character varying,
    total            numeric,
    "fechaCreacion"  timestamp without time zone
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT wt."WaitTicketId", wt."CashRegisterCode", wt."StationName",
           wt."CustomerName", wt."Reason", wt."TotalAmount", wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id
      AND wt."BranchId" = p_branch_id
      AND wt."Status" = 'WAITING'
    ORDER BY wt."CreatedAt";
END;
$function$;

-- --------------------------------------------------------
-- 14. usp_rest_admin_compra_getdetalle_header
-- Tabla: rest.Purchase.PurchaseDate -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_getdetalle_header(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_getdetalle_header(p_compra_id integer)
  RETURNS TABLE(
    id                integer,
    "numCompra"       character varying,
    "proveedorId"     character varying,
    "proveedorNombre" character varying,
    "fechaCompra"     timestamp without time zone,
    estado            character varying,
    subtotal          numeric,
    iva               numeric,
    total             numeric,
    observaciones     character varying,
    "codUsuario"      character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."PurchaseId",
        p."PurchaseNumber",
        s."SupplierCode",
        s."SupplierName",
        p."PurchaseDate",
        p."Status",
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes",
        u."UserCode"
    FROM rest."Purchase" p
    LEFT JOIN master."Supplier" s ON s."SupplierId" = p."SupplierId"
    LEFT JOIN sec."User" u ON u."UserId" = p."CreatedByUserId"
    WHERE p."PurchaseId" = p_compra_id
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 15. usp_rest_admin_compra_list
-- Tabla: rest.Purchase.PurchaseDate -> timestamp without time zone
-- Parametros: cambiados de TIMESTAMPTZ a TIMESTAMP para consistencia
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_list(integer, integer, character varying, timestamp with time zone, timestamp with time zone) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_list(
    p_company_id integer,
    p_branch_id  integer,
    p_status     character varying DEFAULT NULL,
    p_from_date  timestamp without time zone DEFAULT NULL,
    p_to_date    timestamp without time zone DEFAULT NULL
)
  RETURNS TABLE(
    id                integer,
    "numCompra"       character varying,
    "proveedorId"     character varying,
    "proveedorNombre" character varying,
    "fechaCompra"     timestamp without time zone,
    estado            character varying,
    subtotal          numeric,
    iva               numeric,
    total             numeric,
    observaciones     character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."PurchaseId",
        p."PurchaseNumber",
        s."SupplierCode",
        s."SupplierName",
        p."PurchaseDate",
        p."Status",
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes"
    FROM rest."Purchase" p
    LEFT JOIN master."Supplier" s ON s."SupplierId" = p."SupplierId"
    WHERE p."CompanyId" = p_company_id
      AND p."BranchId"  = p_branch_id
      AND (p_status IS NULL OR p."Status" = p_status)
      AND (p_from_date IS NULL OR p."PurchaseDate" >= p_from_date)
      AND (p_to_date IS NULL OR p."PurchaseDate" <= p_to_date)
    ORDER BY p."PurchaseDate" DESC, p."PurchaseId" DESC;
END;
$function$;

-- --------------------------------------------------------
-- 16. usp_rest_orderticket_getheaderforclose
-- Tabla: rest.OrderTicket.ClosedAt -> timestamp without time zone
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_orderticket_getheaderforclose(integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_getheaderforclose(p_pedido_id integer)
  RETURNS TABLE(
    id               integer,
    "empresaId"      integer,
    "sucursalId"     integer,
    "countryCode"    character varying,
    "mesaId"         integer,
    "clienteNombre"  character varying,
    "clienteRif"     character varying,
    estado           character varying,
    total            numeric,
    "fechaCierre"    timestamp without time zone,
    "codUsuario"     character varying
  )
  LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT o."OrderTicketId", o."CompanyId", o."BranchId", o."CountryCode", dt."DiningTableId",
           o."CustomerName", o."CustomerFiscalId", o."Status", o."TotalAmount", o."ClosedAt",
           COALESCE(uc."UserCode", uo."UserCode")::VARCHAR
    FROM rest."OrderTicket" o
    LEFT JOIN rest."DiningTable" dt ON dt."CompanyId" = o."CompanyId"
      AND dt."BranchId" = o."BranchId" AND dt."TableNumber" = o."TableNumber"
    LEFT JOIN sec."User" uo ON uo."UserId" = o."OpenedByUserId"
    LEFT JOIN sec."User" uc ON uc."UserId" = o."ClosedByUserId"
    WHERE o."OrderTicketId" = p_pedido_id
    LIMIT 1;
END;
$function$;

-- ============================================================
-- FIN del barrido de type mismatches TIMESTAMP
-- Funciones corregidas: 16
-- Fecha: 2026-03-17
-- ============================================================
