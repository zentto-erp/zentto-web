-- =============================================================================
--  Archivo : usp_fiscal_tributaria.sql  (PostgreSQL)
--  Auto-convertido desde T-SQL (SQL Server) a PL/pgSQL
--  Fecha de conversion: 2026-03-16
--  Fuente original: web/api/sqlweb/includes/sp/usp_fiscal_tributaria.sql
--
--  Procedimientos de Gestion Fiscal y Tributaria
--  Operaciones sobre fiscal.TaxBookEntry, fiscal.TaxDeclaration,
--  fiscal.WithholdingVoucher y fiscal.DeclarationTemplate.
--
--  Funciones (13):
--    1.  usp_Fiscal_TaxBook_Populate       - Genera libro fiscal desde documentos
--    2.  usp_Fiscal_TaxBook_List           - Listado paginado de entradas de libro
--    3.  usp_Fiscal_TaxBook_Summary        - Resumen agrupado por tasa impositiva
--    4.  usp_Fiscal_Declaration_Calculate  - Calcula declaracion de impuestos
--    5.  usp_Fiscal_Declaration_List       - Listado paginado de declaraciones
--    6.  usp_Fiscal_Declaration_Get        - Detalle de una declaracion
--    7.  usp_Fiscal_Declaration_Submit     - Marca declaracion como presentada
--    8.  usp_Fiscal_Declaration_Amend      - Marca declaracion como enmendada
--    9.  usp_Fiscal_Withholding_Generate   - Genera comprobante de retencion
--   10.  usp_Fiscal_Withholding_List       - Listado paginado de retenciones
--   11.  usp_Fiscal_Withholding_Get        - Detalle de un comprobante de retencion
--   12.  usp_Fiscal_Export_TaxBook         - Exporta libro fiscal completo
--   13.  usp_Fiscal_Export_Declaration     - Exporta declaracion para presentacion
-- =============================================================================

-- =============================================================================
-- 1. usp_Fiscal_TaxBook_Populate
--    Genera (o regenera) las entradas del libro fiscal para un periodo dado,
--    a partir de los documentos de venta o compra segun p_book_type.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_TaxBook_Populate(INTEGER, VARCHAR(10), VARCHAR(7), VARCHAR(2), VARCHAR(40), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_TaxBook_Populate(
    p_company_id   INTEGER,
    p_book_type    VARCHAR(10),
    p_period_code  VARCHAR(7),
    p_country_code VARCHAR(2),
    p_cod_usuario  VARCHAR(40),
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
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
            -- Fuente canonical: ar."SalesDocument"
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
                v."DocumentDate"::DATE,
                v."DocumentNumber",
                CASE v."SerialType"
                    WHEN 'FAC'   THEN 'FACTURA'
                    WHEN 'NC'    THEN 'NOTA_CREDITO'
                    WHEN 'ND'    THEN 'NOTA_DEBITO'
                    WHEN 'FACT'  THEN 'FACTURA'
                    ELSE COALESCE(v."SerialType", 'FACTURA')
                END,
                v."ControlNumber",
                v."FiscalId",
                v."CustomerName",
                COALESCE(v."TaxableAmount", 0),
                COALESCE(v."ExemptAmount",  0),
                COALESCE(v."TaxRate",       0),
                COALESCE(v."TaxAmount",     0),
                0,
                0,
                COALESCE(v."TotalAmount",   0),
                v."DocumentId",
                'AR',
                p_country_code,
                (NOW() AT TIME ZONE 'UTC')
            FROM ar."SalesDocument" v
            WHERE v."DocumentDate"::DATE BETWEEN v_period_start AND v_period_end
              AND v."IsVoided"  = FALSE
              AND v."IsDeleted" = FALSE;

            GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;

        ELSIF p_book_type = 'PURCHASE' THEN
            -- Fuente canonical: ap."PurchaseDocument"
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
                c."DocumentDate"::DATE,
                c."DocumentNumber",
                CASE c."SerialType"
                    WHEN 'FAC'    THEN 'FACTURA'
                    WHEN 'NC'     THEN 'NOTA_CREDITO'
                    WHEN 'ND'     THEN 'NOTA_DEBITO'
                    WHEN 'COMPRA' THEN 'FACTURA'
                    ELSE COALESCE(c."SerialType", 'FACTURA')
                END,
                c."ControlNumber",
                c."FiscalId",
                c."SupplierName",
                COALESCE(c."TaxableAmount",  0),
                COALESCE(c."ExemptAmount",   0),
                COALESCE(c."TaxRate",        0),
                COALESCE(c."TaxAmount",      0),
                COALESCE(c."RetentionRate",  0),
                COALESCE(c."RetainedTax",    0),
                COALESCE(c."TotalAmount",    0),
                c."DocumentId",
                'AP',
                p_country_code,
                (NOW() AT TIME ZONE 'UTC')
            FROM ap."PurchaseDocument" c
            WHERE c."DocumentDate"::DATE BETWEEN v_period_start AND v_period_end
              AND c."IsVoided"  = FALSE
              AND c."IsDeleted" = FALSE;

            GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;
        END IF;

        p_resultado := 1;
        p_mensaje   := 'Libro fiscal generado: ' || v_rows_inserted::TEXT || ' registros';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
-- 2. usp_Fiscal_TaxBook_List
--    Listado paginado de entradas del libro fiscal.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_TaxBook_List(INTEGER, VARCHAR(10), VARCHAR(7), VARCHAR(2), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_TaxBook_List(
    p_company_id   INTEGER,
    p_book_type    VARCHAR(10),
    p_period_code  VARCHAR(7),
    p_country_code VARCHAR(2),
    p_page         INTEGER DEFAULT 1,
    p_limit        INTEGER DEFAULT 100
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "EntryId"           BIGINT,
    "CompanyId"         INTEGER,
    "BookType"          VARCHAR(10),
    "PeriodCode"        VARCHAR(7),
    "EntryDate"         DATE,
    "DocumentNumber"    VARCHAR(50),
    "DocumentType"      VARCHAR(30),
    "ControlNumber"     VARCHAR(30),
    "ThirdPartyId"      VARCHAR(50),
    "ThirdPartyName"    VARCHAR(200),
    "TaxableBase"       NUMERIC(18,2),
    "ExemptAmount"      NUMERIC(18,2),
    "TaxRate"           NUMERIC(8,4),
    "TaxAmount"         NUMERIC(18,2),
    "WithholdingRate"   NUMERIC(8,4),
    "WithholdingAmount" NUMERIC(18,2),
    "TotalAmount"       NUMERIC(18,2),
    "SourceDocumentId"  BIGINT,
    "SourceModule"      VARCHAR(20),
    "CountryCode"       VARCHAR(2),
    "DeclarationId"     BIGINT,
    "CreatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================================================
-- 3. usp_Fiscal_TaxBook_Summary
--    Resumen del libro fiscal agrupado por tasa impositiva.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_TaxBook_Summary(INTEGER, VARCHAR(10), VARCHAR(7), VARCHAR(2)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_TaxBook_Summary(
    p_company_id   INTEGER,
    p_book_type    VARCHAR(10),
    p_period_code  VARCHAR(7),
    p_country_code VARCHAR(2)
)
RETURNS TABLE(
    "TaxRate"           NUMERIC(8,4),
    "TaxableBase"       NUMERIC(18,2),
    "ExemptAmount"      NUMERIC(18,2),
    "TaxAmount"         NUMERIC(18,2),
    "WithholdingAmount" NUMERIC(18,2),
    "TotalAmount"       NUMERIC(18,2),
    "EntryCount"        BIGINT
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================================================
-- 4. usp_Fiscal_Declaration_Calculate
--    Calcula una declaracion de impuestos (IVA/MODELO_303 o ISLR/IRPF).
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_Declaration_Calculate(INTEGER, VARCHAR(30), VARCHAR(7), VARCHAR(2), VARCHAR(40), BIGINT, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_Declaration_Calculate(
    p_company_id       INTEGER,
    p_declaration_type VARCHAR(30),
    p_period_code      VARCHAR(7),
    p_country_code     VARCHAR(2),
    p_cod_usuario      VARCHAR(40),
    OUT p_declaration_id BIGINT,
    OUT p_resultado      INTEGER,
    OUT p_mensaje        TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
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
$$;

-- =============================================================================
-- 5. usp_Fiscal_Declaration_List
--    Listado paginado de declaraciones fiscales.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_Declaration_List(INTEGER, VARCHAR(30), INTEGER, VARCHAR(20), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_Declaration_List(
    p_company_id       INTEGER,
    p_declaration_type VARCHAR(30) DEFAULT NULL,
    p_year             INTEGER     DEFAULT NULL,
    p_status           VARCHAR(20) DEFAULT NULL,
    p_page             INTEGER     DEFAULT 1,
    p_limit            INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count        BIGINT,
    "DeclarationId"      BIGINT,
    "CompanyId"          INTEGER,
    "BranchId"           INTEGER,
    "CountryCode"        VARCHAR(2),
    "DeclarationType"    VARCHAR(30),
    "PeriodCode"         VARCHAR(7),
    "PeriodStart"        DATE,
    "PeriodEnd"          DATE,
    "SalesBase"          NUMERIC(18,2),
    "SalesTax"           NUMERIC(18,2),
    "PurchasesBase"      NUMERIC(18,2),
    "PurchasesTax"       NUMERIC(18,2),
    "TaxableBase"        NUMERIC(18,2),
    "TaxAmount"          NUMERIC(18,2),
    "WithholdingsCredit" NUMERIC(18,2),
    "PreviousBalance"    NUMERIC(18,2),
    "NetPayable"         NUMERIC(18,2),
    "Status"             VARCHAR(20),
    "SubmittedAt"        TIMESTAMP,
    "SubmittedFile"      VARCHAR(500),
    "AuthorityResponse"  TEXT,
    "PaidAt"             TIMESTAMP,
    "PaymentReference"   VARCHAR(100),
    "JournalEntryId"     BIGINT,
    "Notes"              VARCHAR(1000),
    "CreatedBy"          VARCHAR(40),
    "UpdatedBy"          VARCHAR(40),
    "CreatedAt"          TIMESTAMP,
    "UpdatedAt"          TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;  END IF;
    IF p_limit < 1   THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT COUNT(*) OVER()  AS p_total_count,
           d."DeclarationId", d."CompanyId", d."BranchId", d."CountryCode",
           d."DeclarationType", d."PeriodCode", d."PeriodStart", d."PeriodEnd",
           d."SalesBase", d."SalesTax", d."PurchasesBase", d."PurchasesTax",
           d."TaxableBase", d."TaxAmount", d."WithholdingsCredit",
           d."PreviousBalance", d."NetPayable", d."Status",
           d."SubmittedAt", d."SubmittedFile", d."AuthorityResponse",
           d."PaidAt", d."PaymentReference", d."JournalEntryId", d."Notes",
           d."CreatedBy", d."UpdatedBy", d."CreatedAt", d."UpdatedAt"
    FROM fiscal."TaxDeclaration" d
    WHERE d."CompanyId" = p_company_id
      AND (p_declaration_type IS NULL OR d."DeclarationType" = p_declaration_type)
      AND (p_year IS NULL OR LEFT(d."PeriodCode", 4) = CAST(p_year AS VARCHAR(4)))
      AND (p_status IS NULL OR d."Status" = p_status)
    ORDER BY d."PeriodCode" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 6. usp_Fiscal_Declaration_Get
--    Obtiene el detalle completo de una declaracion fiscal por su ID.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_Declaration_Get(INTEGER, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_Declaration_Get(
    p_company_id     INTEGER,
    p_declaration_id BIGINT
)
RETURNS TABLE(
    "DeclarationId"      BIGINT,
    "CompanyId"          INTEGER,
    "BranchId"           INTEGER,
    "CountryCode"        VARCHAR(2),
    "DeclarationType"    VARCHAR(30),
    "PeriodCode"         VARCHAR(7),
    "PeriodStart"        DATE,
    "PeriodEnd"          DATE,
    "SalesBase"          NUMERIC(18,2),
    "SalesTax"           NUMERIC(18,2),
    "PurchasesBase"      NUMERIC(18,2),
    "PurchasesTax"       NUMERIC(18,2),
    "TaxableBase"        NUMERIC(18,2),
    "TaxAmount"          NUMERIC(18,2),
    "WithholdingsCredit" NUMERIC(18,2),
    "PreviousBalance"    NUMERIC(18,2),
    "NetPayable"         NUMERIC(18,2),
    "Status"             VARCHAR(20),
    "SubmittedAt"        TIMESTAMP,
    "SubmittedFile"      VARCHAR(500),
    "AuthorityResponse"  TEXT,
    "PaidAt"             TIMESTAMP,
    "PaymentReference"   VARCHAR(100),
    "JournalEntryId"     BIGINT,
    "Notes"              VARCHAR(1000),
    "CreatedBy"          VARCHAR(40),
    "UpdatedBy"          VARCHAR(40),
    "CreatedAt"          TIMESTAMP,
    "UpdatedAt"          TIMESTAMP
)
LANGUAGE plpgsql
AS $$
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
END;
$$;

-- =============================================================================
-- 7. usp_Fiscal_Declaration_Submit
--    Marca una declaracion como presentada (SUBMITTED).
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_Declaration_Submit(INTEGER, BIGINT, VARCHAR(40), TEXT, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_Declaration_Submit(
    p_company_id     INTEGER,
    p_declaration_id BIGINT,
    p_cod_usuario    VARCHAR(40),
    p_file_path      TEXT       DEFAULT NULL,
    OUT p_resultado   INTEGER,
    OUT p_mensaje     TEXT
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================================================
-- 8. usp_Fiscal_Declaration_Amend
--    Marca una declaracion como enmendada (AMENDED).
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_Declaration_Amend(INTEGER, BIGINT, VARCHAR(40), INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_Declaration_Amend(
    p_company_id     INTEGER,
    p_declaration_id BIGINT,
    p_cod_usuario    VARCHAR(40),
    OUT p_resultado   INTEGER,
    OUT p_mensaje     TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
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
        p_mensaje := 'Declaracion no encontrada';
        RETURN;
    END IF;

    IF v_current_status <> 'SUBMITTED' THEN
        p_mensaje := 'Solo se puede enmendar una declaracion en estado SUBMITTED. Estado actual: ' || v_current_status;
        RETURN;
    END IF;

    UPDATE fiscal."TaxDeclaration"
    SET "Status"    = 'AMENDED',
        "UpdatedBy" = p_cod_usuario,
        "UpdatedAt" = (NOW() AT TIME ZONE 'UTC')
    WHERE "CompanyId"     = p_company_id
      AND "DeclarationId" = p_declaration_id;

    p_resultado := 1;
    p_mensaje   := 'Declaracion marcada como enmendada';
END;
$$;

-- =============================================================================
-- 9. usp_Fiscal_Withholding_Generate
--    Genera un comprobante de retencion a partir de un documento de compra.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_Withholding_Generate(INTEGER, BIGINT, VARCHAR(20), VARCHAR(2), VARCHAR(40), BIGINT, INTEGER, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_Withholding_Generate(
    p_company_id       INTEGER,
    p_document_id      BIGINT,
    p_withholding_type VARCHAR(20),
    p_country_code     VARCHAR(2),
    p_cod_usuario      VARCHAR(40),
    OUT p_voucher_id    BIGINT,
    OUT p_resultado     INTEGER,
    OUT p_mensaje       TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
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
                          || REPLACE(v_period_code, '-',''::VARCHAR) || '-'
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
$$;

-- =============================================================================
-- 10. usp_Fiscal_Withholding_List
--     Listado paginado de comprobantes de retencion.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_Withholding_List(INTEGER, VARCHAR(20), VARCHAR(7), VARCHAR(2), INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_Withholding_List(
    p_company_id       INTEGER,
    p_withholding_type VARCHAR(20) DEFAULT NULL,
    p_period_code      VARCHAR(7)  DEFAULT NULL,
    p_country_code     VARCHAR(2)  DEFAULT NULL,
    p_page             INTEGER     DEFAULT 1,
    p_limit            INTEGER     DEFAULT 50
)
RETURNS TABLE(
    p_total_count       BIGINT,
    "VoucherId"         BIGINT,
    "CompanyId"         INTEGER,
    "VoucherNumber"     VARCHAR(40),
    "VoucherDate"       DATE,
    "WithholdingType"   VARCHAR(20),
    "ThirdPartyId"      VARCHAR(40),
    "ThirdPartyName"    VARCHAR(200),
    "DocumentNumber"    VARCHAR(60),
    "DocumentDate"      DATE,
    "TaxableBase"       NUMERIC(18,2),
    "WithholdingRate"   NUMERIC(5,2),
    "WithholdingAmount" NUMERIC(18,2),
    "PeriodCode"        VARCHAR(7),
    "Status"            VARCHAR(20),
    "CountryCode"       VARCHAR(2),
    "JournalEntryId"    BIGINT,
    "CreatedBy"         VARCHAR(40),
    "CreatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;  END IF;
    IF p_limit < 1   THEN p_limit := 50; END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    RETURN QUERY
    SELECT COUNT(*) OVER()  AS p_total_count,
           v."VoucherId", v."CompanyId", v."VoucherNumber", v."VoucherDate",
           v."WithholdingType", v."ThirdPartyId", v."ThirdPartyName",
           v."DocumentNumber", v."DocumentDate", v."TaxableBase",
           v."WithholdingRate", v."WithholdingAmount", v."PeriodCode",
           v."Status", v."CountryCode", v."JournalEntryId",
           v."CreatedBy", v."CreatedAt"
    FROM fiscal."WithholdingVoucher" v
    WHERE v."CompanyId" = p_company_id
      AND (p_withholding_type IS NULL OR v."WithholdingType" = p_withholding_type)
      AND (p_period_code      IS NULL OR v."PeriodCode"      = p_period_code)
      AND (p_country_code     IS NULL OR v."CountryCode"     = p_country_code)
    ORDER BY v."VoucherDate" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$$;

-- =============================================================================
-- 11. usp_Fiscal_Withholding_Get
--     Obtiene el detalle completo de un comprobante de retencion por su ID.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_Withholding_Get(INTEGER, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_Withholding_Get(
    p_company_id INTEGER,
    p_voucher_id BIGINT
)
RETURNS TABLE(
    "VoucherId"          BIGINT,
    "CompanyId"          INTEGER,
    "VoucherNumber"      VARCHAR(40),
    "VoucherDate"        DATE,
    "WithholdingType"    VARCHAR(20),
    "ThirdPartyId"       VARCHAR(40),
    "ThirdPartyName"     VARCHAR(200),
    "DocumentNumber"     VARCHAR(60),
    "DocumentDate"       DATE,
    "TaxableBase"        NUMERIC(18,2),
    "WithholdingRate"    NUMERIC(5,2),
    "WithholdingAmount"  NUMERIC(18,2),
    "PeriodCode"         VARCHAR(7),
    "Status"             VARCHAR(20),
    "CountryCode"        VARCHAR(2),
    "JournalEntryId"     BIGINT,
    "CreatedBy"          VARCHAR(40),
    "CreatedAt"          TIMESTAMP
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================================================
-- 12. usp_Fiscal_Export_TaxBook
--     Exporta todas las entradas del libro fiscal para un periodo dado.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_Export_TaxBook(INTEGER, VARCHAR(10), VARCHAR(7), VARCHAR(2)) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_Export_TaxBook(
    p_company_id   INTEGER,
    p_book_type    VARCHAR(10),
    p_period_code  VARCHAR(7),
    p_country_code VARCHAR(2)
)
RETURNS TABLE(
    "EntryId"           BIGINT,
    "CompanyId"         INTEGER,
    "BookType"          VARCHAR(10),
    "PeriodCode"        VARCHAR(7),
    "EntryDate"         DATE,
    "DocumentNumber"    VARCHAR(50),
    "DocumentType"      VARCHAR(30),
    "ControlNumber"     VARCHAR(30),
    "ThirdPartyId"      VARCHAR(50),
    "ThirdPartyName"    VARCHAR(200),
    "TaxableBase"       NUMERIC(18,2),
    "ExemptAmount"      NUMERIC(18,2),
    "TaxRate"           NUMERIC(8,4),
    "TaxAmount"         NUMERIC(18,2),
    "WithholdingRate"   NUMERIC(8,4),
    "WithholdingAmount" NUMERIC(18,2),
    "TotalAmount"       NUMERIC(18,2),
    "SourceDocumentId"  BIGINT,
    "SourceModule"      VARCHAR(20),
    "CountryCode"       VARCHAR(2),
    "DeclarationId"     BIGINT,
    "CreatedAt"         TIMESTAMP
)
LANGUAGE plpgsql
AS $$
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
$$;

-- =============================================================================
-- 13. usp_Fiscal_Export_Declaration
--     Exporta el detalle completo de una declaracion para presentacion o archivo.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_Fiscal_Export_Declaration(INTEGER, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_Fiscal_Export_Declaration(
    p_company_id     INTEGER,
    p_declaration_id BIGINT
)
RETURNS TABLE(
    "DeclarationId"      BIGINT,
    "CompanyId"          INTEGER,
    "BranchId"           INTEGER,
    "CountryCode"        VARCHAR(2),
    "DeclarationType"    VARCHAR(30),
    "PeriodCode"         VARCHAR(7),
    "PeriodStart"        DATE,
    "PeriodEnd"          DATE,
    "SalesBase"          NUMERIC(18,2),
    "SalesTax"           NUMERIC(18,2),
    "PurchasesBase"      NUMERIC(18,2),
    "PurchasesTax"       NUMERIC(18,2),
    "TaxableBase"        NUMERIC(18,2),
    "TaxAmount"          NUMERIC(18,2),
    "WithholdingsCredit" NUMERIC(18,2),
    "PreviousBalance"    NUMERIC(18,2),
    "NetPayable"         NUMERIC(18,2),
    "Status"             VARCHAR(20),
    "SubmittedAt"        TIMESTAMP,
    "SubmittedFile"      VARCHAR(500),
    "AuthorityResponse"  TEXT,
    "PaidAt"             TIMESTAMP,
    "PaymentReference"   VARCHAR(100),
    "JournalEntryId"     BIGINT,
    "Notes"              VARCHAR(1000),
    "CreatedBy"          VARCHAR(40),
    "UpdatedBy"          VARCHAR(40),
    "CreatedAt"          TIMESTAMP,
    "UpdatedAt"          TIMESTAMP
)
LANGUAGE plpgsql
AS $$
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
$$;
