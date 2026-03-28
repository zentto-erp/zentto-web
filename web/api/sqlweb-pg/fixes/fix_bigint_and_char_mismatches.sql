-- ============================================================
-- fix_bigint_and_char_mismatches.sql
-- Segunda ronda de fixes post-barrido TIMESTAMP:
-- - INTEGER -> BIGINT en PK/FK de tipo bigint
-- - CHARACTER(n) -> VARCHAR con cast ::VARCHAR en RETURNS TABLE + SELECT
-- - TIMESTAMP WITH TIME ZONE -> TIMESTAMP WITHOUT TIME ZONE para pay.* restantes
-- ============================================================

-- --------------------------------------------------------
-- 1. usp_pay_cardreader_list
-- pay.CardReaderDevices: Id=int4, LastSeenAt=timestamp(notz), CreatedAt=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_cardreader_list(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_pay_cardreader_list(p_company_id integer DEFAULT NULL)
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
    SELECT cr."Id", cr."EmpresaId", cr."SucursalId", cr."StationId"::VARCHAR,
           cr."DeviceName"::VARCHAR, cr."DeviceType"::VARCHAR, cr."ConnectionType"::VARCHAR,
           cr."ConnectionConfig"::VARCHAR, cr."ProviderId", cr."IsActive",
           cr."LastSeenAt", cr."CreatedAt"
    FROM pay."CardReaderDevices" cr
    WHERE (p_company_id IS NULL OR cr."EmpresaId" = p_company_id)
    ORDER BY cr."EmpresaId", cr."StationId", cr."DeviceName";
END;
$function$;

-- --------------------------------------------------------
-- 2. usp_pay_cardreader_listbycompany
-- pay.CardReaderDevices: LastSeenAt=timestamp(notz), CreatedAt=timestamp(notz)
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
    SELECT cr."Id", cr."EmpresaId", cr."SucursalId", cr."StationId"::VARCHAR,
           cr."DeviceName"::VARCHAR, cr."DeviceType"::VARCHAR, cr."ConnectionType"::VARCHAR,
           cr."ConnectionConfig"::VARCHAR, cr."ProviderId", cr."IsActive",
           cr."LastSeenAt", cr."CreatedAt"
    FROM pay."CardReaderDevices" cr
    WHERE cr."EmpresaId" = p_company_id
      AND cr."IsActive" = TRUE
      AND (p_branch_id IS NULL OR cr."SucursalId" = p_branch_id)
    ORDER BY cr."StationId", cr."DeviceName";
END;
$function$;

-- --------------------------------------------------------
-- 3. usp_pay_companyconfig_list
-- pay.CompanyPaymentConfig: CountryCode=CHAR(2) -> ::VARCHAR
-- pay.CompanyPaymentConfig: CreatedAt/UpdatedAt = timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_companyconfig_list(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_pay_companyconfig_list(p_company_id integer DEFAULT NULL)
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
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode"::VARCHAR,
           cc."ProviderId", p."Code"::VARCHAR, p."Name"::VARCHAR, p."ProviderType"::VARCHAR,
           cc."Environment"::VARCHAR, cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE (p_company_id IS NULL OR cc."EmpresaId" = p_company_id)
    ORDER BY cc."EmpresaId", p."Code";
END;
$function$;

-- --------------------------------------------------------
-- 4. usp_pay_companyconfig_listbycompany
-- pay.CompanyPaymentConfig: CountryCode=CHAR(2) -> ::VARCHAR
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
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode"::VARCHAR,
           cc."ProviderId", p."Code"::VARCHAR, p."Name"::VARCHAR, p."ProviderType"::VARCHAR,
           cc."Environment"::VARCHAR, cc."ClientId"::VARCHAR, cc."ClientSecret"::VARCHAR,
           cc."MerchantId"::VARCHAR, cc."TerminalId"::VARCHAR, cc."IntegratorId"::VARCHAR,
           cc."CertificatePath"::VARCHAR, cc."ExtraConfig"::VARCHAR,
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
-- 5. usp_pay_provider_get
-- pay.PaymentProviders: CountryCode=CHAR(2) -> ::VARCHAR
-- pay.PaymentProviders: CreatedAt=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pay_provider_get(character varying) CASCADE;
DROP FUNCTION IF EXISTS public.usp_pay_provider_get(p_provider_code character varying)
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
    SELECT pp."Id", pp."Code"::VARCHAR, pp."Name"::VARCHAR, pp."CountryCode"::VARCHAR,
           pp."ProviderType"::VARCHAR, pp."BaseUrlSandbox"::VARCHAR, pp."BaseUrlProd"::VARCHAR,
           pp."AuthType"::VARCHAR, pp."DocsUrl"::VARCHAR, pp."LogoUrl"::VARCHAR,
           pp."IsActive", pp."CreatedAt"
    FROM pay."PaymentProviders" pp
    WHERE pp."Code" = p_provider_code
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 6. usp_pos_report_ventas
-- pos.SaleTicket: SaleTicketId=bigint, SoldAt=timestamp(notz)
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
    id                   bigint,
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
        v."InvoiceNumber"::VARCHAR,
        v."SoldAt",
        COALESCE(NULLIF(TRIM(v."CustomerName"), ''), 'Consumidor Final')::VARCHAR,
        v."CashRegisterCode"::VARCHAR,
        v."TotalAmount",
        'Completada'::VARCHAR,
        v."PaymentMethod"::VARCHAR,
        v."FiscalPayload"::VARCHAR,
        corr."SerialFiscal"::VARCHAR,
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
-- 7. usp_pos_waitticket_getheader
-- pos.WaitTicket: WaitTicketId=bigint, CreatedAt=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pos_waitticket_getheader(integer, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_getheader(
    p_company_id     integer,
    p_branch_id      integer,
    p_wait_ticket_id integer
)
  RETURNS TABLE(
    id               bigint,
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
    SELECT wt."WaitTicketId", wt."CashRegisterCode"::VARCHAR, wt."StationName"::VARCHAR,
           wt."CustomerCode"::VARCHAR, wt."CustomerName"::VARCHAR, wt."CustomerFiscalId"::VARCHAR,
           wt."PriceTier"::VARCHAR, wt."Reason"::VARCHAR,
           wt."NetAmount", wt."TaxAmount", wt."TotalAmount", wt."Status"::VARCHAR, wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id
      AND wt."BranchId" = p_branch_id
      AND wt."WaitTicketId" = p_wait_ticket_id
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 8. usp_pos_waitticket_list
-- pos.WaitTicket: WaitTicketId=bigint, CreatedAt=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_pos_waitticket_list(integer, integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_pos_waitticket_list(p_company_id integer, p_branch_id integer)
  RETURNS TABLE(
    id               bigint,
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
    SELECT wt."WaitTicketId", wt."CashRegisterCode"::VARCHAR, wt."StationName"::VARCHAR,
           wt."CustomerName"::VARCHAR, wt."Reason"::VARCHAR, wt."TotalAmount", wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id
      AND wt."BranchId" = p_branch_id
      AND wt."Status" = 'WAITING'
    ORDER BY wt."CreatedAt";
END;
$function$;

-- --------------------------------------------------------
-- 9. usp_rest_admin_compra_getdetalle_header
-- rest.Purchase: PurchaseId=bigint, PurchaseDate=timestamp(notz)
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_getdetalle_header(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_getdetalle_header(p_compra_id integer)
  RETURNS TABLE(
    id                bigint,
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
        p."PurchaseNumber"::VARCHAR,
        s."SupplierCode"::VARCHAR,
        s."SupplierName"::VARCHAR,
        p."PurchaseDate",
        p."Status"::VARCHAR,
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes"::VARCHAR,
        u."UserCode"::VARCHAR
    FROM rest."Purchase" p
    LEFT JOIN master."Supplier" s ON s."SupplierId" = p."SupplierId"
    LEFT JOIN sec."User" u ON u."UserId" = p."CreatedByUserId"
    WHERE p."PurchaseId" = p_compra_id
    LIMIT 1;
END;
$function$;

-- --------------------------------------------------------
-- 10. usp_rest_admin_compra_list
-- rest.Purchase: PurchaseId=bigint, PurchaseDate=timestamp(notz)
-- Nota: la vieja version tenia parametros TIMESTAMPTZ, la nueva los tiene TIMESTAMP
-- Hay que eliminar AMBAS versiones si existen
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_list(integer, integer, character varying, timestamp with time zone, timestamp with time zone) CASCADE;
DROP FUNCTION IF EXISTS public.usp_rest_admin_compra_list(integer, integer, character varying, timestamp without time zone, timestamp without time zone) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_list(
    p_company_id integer,
    p_branch_id  integer,
    p_status     character varying DEFAULT NULL,
    p_from_date  timestamp without time zone DEFAULT NULL,
    p_to_date    timestamp without time zone DEFAULT NULL
)
  RETURNS TABLE(
    id                bigint,
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
        p."PurchaseNumber"::VARCHAR,
        s."SupplierCode"::VARCHAR,
        s."SupplierName"::VARCHAR,
        p."PurchaseDate",
        p."Status"::VARCHAR,
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes"::VARCHAR
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
-- 11. usp_rest_orderticket_getheaderforclose
-- rest.OrderTicket: OrderTicketId=bigint, ClosedAt=timestamp(notz)
-- rest.DiningTable: DiningTableId=bigint
-- rest.OrderTicket: CountryCode=CHAR(2) -> ::VARCHAR
-- --------------------------------------------------------
DROP FUNCTION IF EXISTS public.usp_rest_orderticket_getheaderforclose(integer) CASCADE;
DROP FUNCTION IF EXISTS public.usp_rest_orderticket_getheaderforclose(p_pedido_id integer)
  RETURNS TABLE(
    id               bigint,
    "empresaId"      integer,
    "sucursalId"     integer,
    "countryCode"    character varying,
    "mesaId"         bigint,
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
    SELECT o."OrderTicketId", o."CompanyId", o."BranchId", o."CountryCode"::VARCHAR, dt."DiningTableId",
           o."CustomerName"::VARCHAR, o."CustomerFiscalId"::VARCHAR, o."Status"::VARCHAR,
           o."TotalAmount", o."ClosedAt",
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
