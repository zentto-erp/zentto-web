-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_acct.sql
-- Funciones de contabilidad (esquema acct)
-- Traducido desde SQL Server stored procedures
-- 30 funciones: CRUD cuentas, asientos, reportes, seeds
-- ============================================================

-- =============================================================================
--  1. usp_Acct_Account_List
--  Lista paginada de cuentas contables con filtros opcionales.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_account_list(INT, VARCHAR(100), VARCHAR(1), VARCHAR(20), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_account_list(
    p_company_id   INT,
    p_search       VARCHAR(100)  DEFAULT NULL,
    p_tipo         VARCHAR(1)    DEFAULT NULL,
    p_grupo        VARCHAR(20)   DEFAULT NULL,
    p_page         INT           DEFAULT 1,
    p_limit        INT           DEFAULT 50
)
RETURNS TABLE(
    "AccountId"       BIGINT,
    "AccountCode"     VARCHAR,
    "AccountName"     VARCHAR,
    "AccountType"     VARCHAR,
    "AccountLevel"    INT,
    "ParentAccountId" BIGINT,
    "AllowsPosting"   BOOLEAN,
    "IsActive"        BOOLEAN,
    "TotalCount"      BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM   acct."Account" a2
    WHERE  a2."CompanyId" = p_company_id
      AND  a2."IsDeleted" = FALSE
      AND  (p_search IS NULL
            OR a2."AccountCode" LIKE '%' || p_search || '%'
            OR a2."AccountName" LIKE '%' || p_search || '%')
      AND  (p_tipo IS NULL OR a2."AccountType"::VARCHAR(1) = p_tipo)
      AND  (p_grupo IS NULL OR a2."AccountCode" LIKE p_grupo || '%');

    RETURN QUERY
    SELECT a."AccountId",
           a."AccountCode",
           a."AccountName",
           a."AccountType"::VARCHAR,
           a."AccountLevel",
           a."ParentAccountId",
           a."AllowsPosting",
           a."IsActive",
           v_total
    FROM   acct."Account" a
    WHERE  a."CompanyId" = p_company_id
      AND  a."IsDeleted" = FALSE
      AND  (p_search IS NULL
            OR a."AccountCode" LIKE '%' || p_search || '%'
            OR a."AccountName" LIKE '%' || p_search || '%')
      AND  (p_tipo IS NULL OR a."AccountType"::VARCHAR(1) = p_tipo)
      AND  (p_grupo IS NULL OR a."AccountCode" LIKE p_grupo || '%')
    ORDER BY a."AccountCode"
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$$;

-- =============================================================================
--  2. usp_Acct_Account_Get
--  Obtiene todos los campos de una cuenta contable dado su codigo.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_account_get(INT, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_account_get(
    p_company_id   INT,
    p_account_code VARCHAR(20)
)
RETURNS SETOF acct."Account"
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM   acct."Account"
    WHERE  "CompanyId"   = p_company_id
      AND  "AccountCode" = p_account_code
      AND  "IsDeleted"   = FALSE
    LIMIT 1;
END;
$$;

-- =============================================================================
--  3. usp_Acct_Account_Insert
--  Inserta una nueva cuenta contable.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_account_insert(INT, VARCHAR(20), VARCHAR(200), VARCHAR(1), INT, INT, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_account_insert(
    p_company_id        INT,
    p_account_code      VARCHAR(20),
    p_account_name      VARCHAR(200),
    p_account_type      VARCHAR(1)   DEFAULT 'A',
    p_account_level     INT          DEFAULT NULL,
    p_parent_account_id INT          DEFAULT NULL,
    p_allows_posting    BOOLEAN      DEFAULT TRUE
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_level    INT := p_account_level;
    v_parent   INT := p_parent_account_id;
    v_parent_code VARCHAR(20);
BEGIN
    -- Validar que no exista duplicado
    IF EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "AccountCode" = p_account_code
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Ya existe una cuenta con el codigo ' || p_account_code || ' para esta empresa.';
        RETURN;
    END IF;

    -- Auto-resolver nivel desde AccountCode si no se proporciono
    IF v_level IS NULL OR v_level < 1 THEN
        v_level := LENGTH(p_account_code) - LENGTH(REPLACE(p_account_code, '.', '')) + 1;
        IF v_level < 1 THEN v_level := 1; END IF;
    END IF;

    -- Auto-resolver cuenta padre desde AccountCode si no se proporciono
    IF v_parent IS NULL AND POSITION('.' IN p_account_code) > 0 THEN
        v_parent_code := LEFT(p_account_code,
            LENGTH(p_account_code) - POSITION('.' IN REVERSE(p_account_code)));

        SELECT "AccountId" INTO v_parent
        FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "AccountCode" = v_parent_code
          AND "IsDeleted" = FALSE
        LIMIT 1;

        IF v_parent IS NULL THEN
            RETURN QUERY SELECT 0, 'Cuenta padre ' || v_parent_code || ' no encontrada.';
            RETURN;
        END IF;
    END IF;

    BEGIN
        INSERT INTO acct."Account" (
            "CompanyId", "AccountCode", "AccountName", "AccountType",
            "AccountLevel", "ParentAccountId", "AllowsPosting",
            "RequiresAuxiliary", "IsActive",
            "CreatedAt", "UpdatedAt", "IsDeleted"
        )
        VALUES (
            p_company_id, p_account_code, p_account_name, p_account_type,
            v_level, v_parent, p_allows_posting,
            FALSE, TRUE,
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
        );

        RETURN QUERY SELECT 1, 'Cuenta ' || p_account_code || ' creada exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error al insertar cuenta: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  4. usp_Acct_Account_Update
--  Actualiza campos de una cuenta existente.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_account_update(INT, VARCHAR(20), VARCHAR(200), VARCHAR(1), INT, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_account_update(
    p_company_id     INT,
    p_account_code   VARCHAR(20),
    p_account_name   VARCHAR(200) DEFAULT NULL,
    p_account_type   VARCHAR(1)   DEFAULT NULL,
    p_account_level  INT          DEFAULT NULL,
    p_allows_posting BOOLEAN      DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "AccountCode" = p_account_code
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'No se encontro la cuenta con codigo ' || p_account_code || '.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."Account"
        SET "AccountName"   = COALESCE(p_account_name,   "AccountName"),
            "AccountType"   = COALESCE(p_account_type,   "AccountType"),
            "AccountLevel"  = COALESCE(p_account_level,  "AccountLevel"),
            "AllowsPosting" = COALESCE(p_allows_posting, "AllowsPosting"),
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId"   = p_company_id
          AND "AccountCode" = p_account_code
          AND "IsDeleted"   = FALSE;

        RETURN QUERY SELECT 1, 'Cuenta ' || p_account_code || ' actualizada exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error al actualizar cuenta: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  5. usp_Acct_Account_Delete
--  Eliminacion logica (soft delete).
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_account_delete(INT, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_account_delete(
    p_company_id   INT,
    p_account_code VARCHAR(20)
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_account_id INT;
BEGIN
    SELECT "AccountId" INTO v_account_id
    FROM acct."Account"
    WHERE "CompanyId" = p_company_id
      AND "AccountCode" = p_account_code
      AND "IsDeleted" = FALSE
    LIMIT 1;

    IF v_account_id IS NULL THEN
        RETURN QUERY SELECT 0, 'No se encontro la cuenta con codigo ' || p_account_code || ' o ya fue eliminada.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND "ParentAccountId" = v_account_id
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'No se puede eliminar: la cuenta tiene cuentas hijas activas.';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."Account"
        SET "IsDeleted" = TRUE,
            "IsActive"  = FALSE,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "AccountId" = v_account_id
          AND "IsDeleted" = FALSE;

        RETURN QUERY SELECT 1, 'Cuenta ' || p_account_code || ' eliminada exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error al eliminar cuenta: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  6. usp_Acct_Infra_Check
--  Verifica si las tablas de contabilidad existen.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_infra_check() CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_infra_check()
RETURNS TABLE("ok" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN
        EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'Account')
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'JournalEntry')
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'JournalEntryLine')
    THEN 1 ELSE 0 END;
END;
$$;

-- =============================================================================
--  7. usp_Acct_Account_Exists
--  Verifica si una cuenta existe por su codigo.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_account_exists(INT, VARCHAR(40)) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_account_exists(
    p_company_id   INT,
    p_account_code VARCHAR(40)
)
RETURNS TABLE("ok" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM acct."Account"
        WHERE "CompanyId" = p_company_id
          AND TRIM("AccountCode") = TRIM(p_account_code)
          AND "IsDeleted" = FALSE
    ) THEN 1 ELSE 0 END;
END;
$$;

-- =============================================================================
--  8. usp_Acct_Policy_Load
--  Carga las politicas contables para un modulo.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_policy_load(INT, VARCHAR(40)) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_policy_load(
    p_company_id INT,
    p_module     VARCHAR(40)
)
RETURNS TABLE(
    "Proceso"             VARCHAR,
    "Naturaleza"          VARCHAR,
    "CuentaContable"      VARCHAR,
    "CentroCostoDefault"  VARCHAR(20)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."ProcessCode"::VARCHAR                                           AS "Proceso",
        (CASE WHEN p."Nature" = 'DEBIT' THEN 'DEBE' ELSE 'HABER' END)::VARCHAR AS "Naturaleza",
        a."AccountCode"::VARCHAR                                           AS "CuentaContable",
        NULL::VARCHAR(20)                                                   AS "CentroCostoDefault"
    FROM acct."AccountingPolicy" p
    INNER JOIN acct."Account" a ON a."AccountId" = p."AccountId"
    WHERE p."CompanyId" = p_company_id
      AND p."ModuleCode" = p_module
      AND p."IsActive" = TRUE
      AND p."ProcessCode" IN ('VENTA_TOTAL', 'VENTA_TOTAL_CAJA', 'VENTA_TOTAL_BANCO', 'VENTA_BASE', 'VENTA_IVA')
    ORDER BY p."PriorityOrder", p."AccountingPolicyId";
END;
$$;

-- =============================================================================
--  9. usp_Acct_Entry_FindByOrigin
--  Busca un asiento contable existente por origen (modulo + doc).
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_entry_findbyorigin(INT, INT, VARCHAR(40), VARCHAR(120)) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_entry_findbyorigin(
    p_company_id      INT,
    p_branch_id       INT,
    p_module          VARCHAR(40),
    p_origin_document VARCHAR(120)
)
RETURNS TABLE("asientoId" BIGINT, "numeroAsiento" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT je."JournalEntryId" AS "asientoId",
           je."EntryNumber"::VARCHAR    AS "numeroAsiento"
    FROM acct."JournalEntry" je
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."SourceModule" = p_module
      AND je."SourceDocumentNo" = p_origin_document
      AND je."IsDeleted" = FALSE
    ORDER BY je."JournalEntryId" DESC
    LIMIT 1;
END;
$$;

-- =============================================================================
--  10. usp_Acct_Entry_ResolveIdBySource
--  Resuelve el JournalEntryId por modulo/documento origen.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_entry_resolveidbysource(INT, INT, VARCHAR(40), VARCHAR(120)) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_entry_resolveidbysource(
    p_company_id      INT,
    p_branch_id       INT,
    p_module          VARCHAR(40),
    p_origin_document VARCHAR(120)
)
RETURNS TABLE("journalEntryId" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT je."JournalEntryId" AS "journalEntryId"
    FROM acct."JournalEntry" je
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."SourceModule" = p_module
      AND je."SourceDocumentNo" = p_origin_document
      AND je."IsDeleted" = FALSE
    ORDER BY je."JournalEntryId" DESC
    LIMIT 1;
END;
$$;

-- =============================================================================
--  11. usp_Acct_DocumentLink_Upsert
--  Inserta un link de documento contable si no existe.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_documentlink_upsert(INT, INT, VARCHAR(40), VARCHAR(40), VARCHAR(120), BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_documentlink_upsert(
    p_company_id       INT,
    p_branch_id        INT,
    p_module           VARCHAR(40),
    p_document_type    VARCHAR(40),
    p_origin_document  VARCHAR(120),
    p_journal_entry_id BIGINT
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM acct."DocumentLink"
        WHERE "CompanyId" = p_company_id
          AND "BranchId" = p_branch_id
          AND "ModuleCode" = p_module
          AND "DocumentType" = p_document_type
          AND "DocumentNumber" = p_origin_document
    ) THEN
        RETURN QUERY SELECT 0, 'El enlace de documento ya existe.';
        RETURN;
    END IF;

    BEGIN
        INSERT INTO acct."DocumentLink" (
            "CompanyId", "BranchId", "ModuleCode", "DocumentType",
            "DocumentNumber", "NativeDocumentId", "JournalEntryId"
        )
        VALUES (
            p_company_id, p_branch_id, p_module, p_document_type,
            p_origin_document, NULL, p_journal_entry_id
        );

        RETURN QUERY SELECT 1, 'Enlace de documento creado exitosamente.';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error al insertar enlace: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  12. usp_Acct_Pos_GetHeader
--  Obtiene cabecera de una venta POS para contabilizacion.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_pos_getheader(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_pos_getheader(
    p_sale_ticket_id BIGINT
)
RETURNS TABLE(
    "id"          BIGINT,
    "numFactura"  VARCHAR,
    "fechaVenta"  TIMESTAMP,
    "metodoPago"  VARCHAR,
    "codUsuario"  VARCHAR,
    "subtotal"    NUMERIC,
    "impuestos"   NUMERIC,
    "total"       NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        v."SaleTicketId"   AS "id",
        v."InvoiceNumber"::VARCHAR  AS "numFactura",
        v."SoldAt"         AS "fechaVenta",
        v."PaymentMethod"::VARCHAR  AS "metodoPago",
        u."UserCode"::VARCHAR       AS "codUsuario",
        v."NetAmount"      AS "subtotal",
        v."TaxAmount"      AS "impuestos",
        v."TotalAmount"    AS "total"
    FROM pos."SaleTicket" v
    LEFT JOIN sec."User" u ON u."UserId" = v."SoldByUserId"
    WHERE v."SaleTicketId" = p_sale_ticket_id
    LIMIT 1;
END;
$$;

-- =============================================================================
--  13. usp_Acct_Pos_GetTaxSummary
--  Resumen de impuestos por tasa de una venta POS.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_pos_gettaxsummary(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_pos_gettaxsummary(
    p_sale_ticket_id BIGINT
)
RETURNS TABLE(
    "taxRate"     NUMERIC,
    "baseAmount"  NUMERIC,
    "taxAmount"   NUMERIC,
    "totalAmount" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        stl."TaxRate"          AS "taxRate",
        SUM(stl."NetAmount")   AS "baseAmount",
        SUM(stl."TaxAmount")   AS "taxAmount",
        SUM(stl."TotalAmount") AS "totalAmount"
    FROM pos."SaleTicketLine" stl
    WHERE stl."SaleTicketId" = p_sale_ticket_id
    GROUP BY stl."TaxRate";
END;
$$;

-- =============================================================================
--  14. usp_Acct_Rest_GetHeader
--  Cabecera de un pedido restaurante para contabilizacion.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_rest_getheader(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_rest_getheader(
    p_order_ticket_id BIGINT
)
RETURNS TABLE(
    "id"          BIGINT,
    "total"       NUMERIC,
    "fechaCierre" TIMESTAMP,
    "codUsuario"  VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        o."OrderTicketId"  AS "id",
        o."TotalAmount"    AS "total",
        o."ClosedAt"       AS "fechaCierre",
        COALESCE(uclose."UserCode", uopen."UserCode")::VARCHAR AS "codUsuario"
    FROM rest."OrderTicket" o
    LEFT JOIN sec."User" uopen  ON uopen."UserId"  = o."OpenedByUserId"
    LEFT JOIN sec."User" uclose ON uclose."UserId" = o."ClosedByUserId"
    WHERE o."OrderTicketId" = p_order_ticket_id
    LIMIT 1;
END;
$$;

-- =============================================================================
--  15. usp_Acct_Rest_GetTaxSummary
--  Resumen de impuestos por tasa de un pedido restaurante.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_rest_gettaxsummary(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_rest_gettaxsummary(
    p_order_ticket_id BIGINT
)
RETURNS TABLE(
    "taxRate"     NUMERIC,
    "baseAmount"  NUMERIC,
    "taxAmount"   NUMERIC,
    "totalAmount" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        otl."TaxRate"          AS "taxRate",
        SUM(otl."NetAmount")   AS "baseAmount",
        SUM(otl."TaxAmount")   AS "taxAmount",
        SUM(otl."TotalAmount") AS "totalAmount"
    FROM rest."OrderTicketLine" otl
    WHERE otl."OrderTicketId" = p_order_ticket_id
    GROUP BY otl."TaxRate";
END;
$$;

-- =============================================================================
--  16. usp_Acct_Entry_List
--  Lista paginada de asientos contables con filtros opcionales.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_entry_list(INT, INT, DATE, DATE, VARCHAR(20), VARCHAR(20), VARCHAR(40), VARCHAR(120), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_entry_list(
    p_company_id        INT,
    p_branch_id         INT,
    p_fecha_desde       DATE          DEFAULT NULL,
    p_fecha_hasta       DATE          DEFAULT NULL,
    p_tipo_asiento      VARCHAR(20)   DEFAULT NULL,
    p_estado            VARCHAR(20)   DEFAULT NULL,
    p_origen_modulo     VARCHAR(40)   DEFAULT NULL,
    p_origen_documento  VARCHAR(120)  DEFAULT NULL,
    p_page              INT           DEFAULT 1,
    p_limit             INT           DEFAULT 50
)
RETURNS TABLE(
    "asientoId"        BIGINT,
    "numeroAsiento"    VARCHAR,
    "fecha"            DATE,
    "tipoAsiento"      VARCHAR,
    "referencia"       VARCHAR,
    "concepto"         VARCHAR,
    "moneda"           VARCHAR,
    "tasa"             NUMERIC,
    "totalDebe"        NUMERIC,
    "totalHaber"       NUMERIC,
    "estado"           VARCHAR,
    "origenModulo"     VARCHAR,
    "origenDocumento"  VARCHAR,
    "CreatedAt"        TIMESTAMP,
    "TotalCount"       BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM acct."JournalEntry" je
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND (p_fecha_desde IS NULL OR je."EntryDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR je."EntryDate" <= p_fecha_hasta)
      AND (p_tipo_asiento IS NULL OR je."EntryType" = p_tipo_asiento)
      AND (p_estado IS NULL OR je."Status" = p_estado)
      AND (p_origen_modulo IS NULL OR je."SourceModule" = p_origen_modulo)
      AND (p_origen_documento IS NULL OR je."SourceDocumentNo" = p_origen_documento);

    RETURN QUERY
    SELECT
        je."JournalEntryId"::BIGINT    AS "asientoId",
        je."EntryNumber"::VARCHAR      AS "numeroAsiento",
        je."EntryDate"                 AS "fecha",
        je."EntryType"::VARCHAR        AS "tipoAsiento",
        je."ReferenceNumber"::VARCHAR  AS "referencia",
        je."Concept"::VARCHAR          AS "concepto",
        je."CurrencyCode"::VARCHAR     AS "moneda",
        je."ExchangeRate"              AS "tasa",
        je."TotalDebit"               AS "totalDebe",
        je."TotalCredit"              AS "totalHaber",
        je."Status"::VARCHAR           AS "estado",
        je."SourceModule"::VARCHAR     AS "origenModulo",
        je."SourceDocumentNo"::VARCHAR AS "origenDocumento",
        je."CreatedAt",
        v_total                        AS "TotalCount"
    FROM acct."JournalEntry" je
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND (p_fecha_desde IS NULL OR je."EntryDate" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR je."EntryDate" <= p_fecha_hasta)
      AND (p_tipo_asiento IS NULL OR je."EntryType" = p_tipo_asiento)
      AND (p_estado IS NULL OR je."Status" = p_estado)
      AND (p_origen_modulo IS NULL OR je."SourceModule" = p_origen_modulo)
      AND (p_origen_documento IS NULL OR je."SourceDocumentNo" = p_origen_documento)
    ORDER BY je."EntryDate" DESC, je."JournalEntryId" DESC
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$$;

-- =============================================================================
--  17. usp_Acct_Entry_Get
--  Obtiene la cabecera de un asiento contable por su ID.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_entry_get(INT, INT, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_entry_get(
    p_company_id INT,
    p_branch_id  INT,
    p_asiento_id BIGINT
)
RETURNS TABLE(
    "asientoId"        BIGINT,
    "numeroAsiento"    VARCHAR,
    "fecha"            DATE,
    "tipoAsiento"      VARCHAR,
    "referencia"       VARCHAR,
    "concepto"         VARCHAR,
    "moneda"           VARCHAR,
    "tasa"             NUMERIC,
    "totalDebe"        NUMERIC,
    "totalHaber"       NUMERIC,
    "estado"           VARCHAR,
    "origenModulo"     VARCHAR,
    "origenDocumento"  VARCHAR,
    "CreatedAt"        TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        je."JournalEntryId"::BIGINT    AS "asientoId",
        je."EntryNumber"::VARCHAR      AS "numeroAsiento",
        je."EntryDate"                 AS "fecha",
        je."EntryType"::VARCHAR        AS "tipoAsiento",
        je."ReferenceNumber"::VARCHAR  AS "referencia",
        je."Concept"::VARCHAR          AS "concepto",
        je."CurrencyCode"::VARCHAR     AS "moneda",
        je."ExchangeRate"              AS "tasa",
        je."TotalDebit"               AS "totalDebe",
        je."TotalCredit"              AS "totalHaber",
        je."Status"::VARCHAR           AS "estado",
        je."SourceModule"::VARCHAR     AS "origenModulo",
        je."SourceDocumentNo"::VARCHAR AS "origenDocumento",
        je."CreatedAt"
    FROM acct."JournalEntry" je
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."JournalEntryId" = p_asiento_id
      AND je."IsDeleted" = FALSE
    LIMIT 1;
END;
$$;

-- =============================================================================
--  18. usp_Acct_Entry_GetDetail
--  Obtiene el detalle (lineas) de un asiento contable.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_entry_getdetail(INT, INT, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_entry_getdetail(
    p_company_id INT,
    p_branch_id  INT,
    p_asiento_id BIGINT
)
RETURNS TABLE(
    "detalleId"      BIGINT,
    "renglon"        INT,
    "codCuenta"      VARCHAR,
    "nombreCuenta"   VARCHAR,
    "descripcion"    VARCHAR,
    "centroCosto"    VARCHAR,
    "auxiliarTipo"   VARCHAR,
    "auxiliarCodigo"  VARCHAR,
    "documento"      VARCHAR,
    "debe"           NUMERIC,
    "haber"          NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        l."JournalEntryLineId"::BIGINT   AS "detalleId",
        l."LineNumber"                    AS "renglon",
        l."AccountCodeSnapshot"::VARCHAR  AS "codCuenta",
        a."AccountName"::VARCHAR          AS "nombreCuenta",
        l."Description"::VARCHAR          AS "descripcion",
        l."CostCenterCode"::VARCHAR       AS "centroCosto",
        l."AuxiliaryType"::VARCHAR        AS "auxiliarTipo",
        l."AuxiliaryCode"::VARCHAR        AS "auxiliarCodigo",
        l."SourceDocumentNo"::VARCHAR     AS "documento",
        l."DebitAmount"                   AS "debe",
        l."CreditAmount"                  AS "haber"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    LEFT JOIN acct."Account" a ON a."AccountId" = l."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."JournalEntryId" = p_asiento_id
    ORDER BY l."LineNumber", l."JournalEntryLineId";
END;
$$;

-- =============================================================================
--  19. usp_Acct_Entry_Insert
--  Crea un asiento contable completo (cabecera + lineas) en una transaccion.
--  Recibe las lineas como JSONB.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_entry_insert(INT, INT, VARCHAR(40), DATE, VARCHAR(10), VARCHAR(20), VARCHAR(120), VARCHAR(400), CHAR(3), NUMERIC(18,6), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(40), VARCHAR(120), JSONB) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_entry_insert(
    p_company_id        INT,
    p_branch_id         INT,
    p_entry_number      VARCHAR(40),
    p_entry_date        DATE,
    p_period_code       VARCHAR(10),
    p_entry_type        VARCHAR(20),
    p_reference_number  VARCHAR(120)  DEFAULT NULL,
    p_concept           VARCHAR(400)  DEFAULT '',
    p_currency_code     CHAR(3)       DEFAULT 'VES',
    p_exchange_rate     NUMERIC(18,6) DEFAULT 1.0,
    p_total_debit       NUMERIC(18,2) DEFAULT 0,
    p_total_credit      NUMERIC(18,2) DEFAULT 0,
    p_source_module     VARCHAR(40)   DEFAULT NULL,
    p_source_document_no VARCHAR(120) DEFAULT NULL,
    p_detalle_json      JSONB         DEFAULT '[]'::JSONB
)
RETURNS TABLE("AsientoId" BIGINT, "Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_asiento_id BIGINT := 0;
    v_missing    TEXT;
    v_elem       JSONB;
    v_idx        INT := 0;
    v_account_id INT;
BEGIN
    -- Validar balance
    IF ABS(p_total_debit - p_total_credit) > 0.005 THEN
        RETURN QUERY SELECT 0::BIGINT, 0,
            'Asiento desbalanceado: debe=' || p_total_debit::TEXT || ' haber=' || p_total_credit::TEXT;
        RETURN;
    END IF;

    -- Validar que el detalle no este vacio
    IF jsonb_array_length(p_detalle_json) = 0 THEN
        RETURN QUERY SELECT 0::BIGINT, 0, 'Detalle de asiento requerido';
        RETURN;
    END IF;

    -- Verificar que todas las cuentas existen
    SELECT string_agg(elem->>'codCuenta', ', ') INTO v_missing
    FROM jsonb_array_elements(p_detalle_json) elem
    LEFT JOIN acct."Account" a
        ON a."CompanyId" = p_company_id
       AND a."AccountCode" = elem->>'codCuenta'
       AND a."IsDeleted" = FALSE
    WHERE a."AccountId" IS NULL;

    IF v_missing IS NOT NULL AND LENGTH(v_missing) > 0 THEN
        RETURN QUERY SELECT 0::BIGINT, 0, 'Cuentas no encontradas: ' || v_missing;
        RETURN;
    END IF;

    BEGIN
        -- Insertar cabecera
        INSERT INTO acct."JournalEntry" (
            "CompanyId", "BranchId", "EntryNumber", "EntryDate", "PeriodCode", "EntryType",
            "ReferenceNumber", "Concept", "CurrencyCode", "ExchangeRate",
            "TotalDebit", "TotalCredit", "Status",
            "SourceModule", "SourceDocumentType", "SourceDocumentNo",
            "CreatedAt", "UpdatedAt", "IsDeleted"
        )
        VALUES (
            p_company_id, p_branch_id, p_entry_number, p_entry_date, p_period_code, p_entry_type,
            p_reference_number, p_concept, p_currency_code, p_exchange_rate,
            p_total_debit, p_total_credit, 'APPROVED',
            p_source_module, p_source_module, p_source_document_no,
            NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC', FALSE
        )
        RETURNING "JournalEntryId" INTO v_asiento_id;

        -- Insertar lineas
        v_idx := 0;
        FOR v_elem IN SELECT * FROM jsonb_array_elements(p_detalle_json)
        LOOP
            v_idx := v_idx + 1;

            SELECT a."AccountId" INTO v_account_id
            FROM acct."Account" a
            WHERE a."CompanyId" = p_company_id
              AND a."AccountCode" = v_elem->>'codCuenta'
              AND a."IsDeleted" = FALSE
            LIMIT 1;

            INSERT INTO acct."JournalEntryLine" (
                "JournalEntryId", "LineNumber", "AccountId", "AccountCodeSnapshot",
                "Description", "DebitAmount", "CreditAmount",
                "AuxiliaryType", "AuxiliaryCode", "CostCenterCode", "SourceDocumentNo",
                "CreatedAt", "UpdatedAt"
            )
            VALUES (
                v_asiento_id,
                v_idx,
                v_account_id,
                v_elem->>'codCuenta',
                v_elem->>'descripcion',
                COALESCE((v_elem->>'debe')::NUMERIC(18,2), 0),
                COALESCE((v_elem->>'haber')::NUMERIC(18,2), 0),
                v_elem->>'auxiliarTipo',
                v_elem->>'auxiliarCodigo',
                v_elem->>'centroCosto',
                COALESCE(v_elem->>'documento', p_source_document_no),
                NOW() AT TIME ZONE 'UTC',
                NOW() AT TIME ZONE 'UTC'
            );
        END LOOP;

        RETURN QUERY SELECT v_asiento_id, 1, 'Asiento creado en modelo canonico';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0::BIGINT, 0, 'Error creando asiento canonico: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  20. usp_Acct_Entry_Void
--  Anula un asiento contable.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_entry_void(INT, INT, BIGINT, VARCHAR(400)) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_entry_void(
    p_company_id INT,
    p_branch_id  INT,
    p_asiento_id BIGINT,
    p_motivo     VARCHAR(400)
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_rows INT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM acct."JournalEntry"
        WHERE "CompanyId" = p_company_id
          AND "BranchId" = p_branch_id
          AND "JournalEntryId" = p_asiento_id
          AND "IsDeleted" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'Asiento no encontrado';
        RETURN;
    END IF;

    BEGIN
        UPDATE acct."JournalEntry"
        SET "Status"    = 'VOIDED',
            "Concept"   = CONCAT(
                COALESCE("Concept", ''),
                CASE WHEN COALESCE("Concept", '') = '' THEN '' ELSE ' | ' END,
                'ANULADO: ',
                p_motivo
            ),
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "CompanyId" = p_company_id
          AND "BranchId" = p_branch_id
          AND "JournalEntryId" = p_asiento_id
          AND "IsDeleted" = FALSE;

        GET DIAGNOSTICS v_rows = ROW_COUNT;

        IF v_rows > 0 THEN
            RETURN QUERY SELECT 1, 'Asiento anulado';
        ELSE
            RETURN QUERY SELECT 0, 'Asiento no encontrado';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error al anular asiento: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  21. usp_Acct_Report_LibroMayor
--  Reporte de libro mayor.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_report_libromayor(INT, INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_report_libromayor(
    p_company_id  INT,
    p_branch_id   INT,
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "fecha"          DATE,
    "numeroAsiento"  VARCHAR,
    "codCuenta"      VARCHAR,
    "cuenta"         VARCHAR,
    "descripcion"    VARCHAR,
    "debe"           NUMERIC,
    "haber"          NUMERIC,
    "saldo"          NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        je."EntryDate"                    AS "fecha",
        je."EntryNumber"::VARCHAR         AS "numeroAsiento",
        l."AccountCodeSnapshot"::VARCHAR  AS "codCuenta",
        a."AccountName"::VARCHAR          AS "cuenta",
        l."Description"::VARCHAR          AS "descripcion",
        l."DebitAmount"                   AS "debe",
        l."CreditAmount"                  AS "haber",
        SUM(l."DebitAmount" - l."CreditAmount") OVER (
            PARTITION BY l."AccountCodeSnapshot"
            ORDER BY je."EntryDate", je."JournalEntryId", l."LineNumber"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "saldo"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    LEFT JOIN acct."Account" a ON a."AccountId" = l."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND je."Status" <> 'VOIDED'
      AND je."EntryDate" >= p_fecha_desde
      AND je."EntryDate" <= p_fecha_hasta
    ORDER BY je."EntryDate", je."JournalEntryId", l."LineNumber";
END;
$$;

-- =============================================================================
--  22. usp_Acct_Report_MayorAnalitico
--  Reporte de mayor analitico para una cuenta especifica.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_report_mayoranalitico(INT, INT, VARCHAR(40), DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_report_mayoranalitico(
    p_company_id  INT,
    p_branch_id   INT,
    p_cod_cuenta  VARCHAR(40),
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "fecha"          DATE,
    "numeroAsiento"  VARCHAR,
    "renglon"        INT,
    "descripcion"    VARCHAR,
    "debe"           NUMERIC,
    "haber"          NUMERIC,
    "saldo"          NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        je."EntryDate"               AS "fecha",
        je."EntryNumber"::VARCHAR    AS "numeroAsiento",
        l."LineNumber"               AS "renglon",
        l."Description"::VARCHAR     AS "descripcion",
        l."DebitAmount"              AS "debe",
        l."CreditAmount"             AS "haber",
        SUM(l."DebitAmount" - l."CreditAmount") OVER (
            ORDER BY je."EntryDate", je."JournalEntryId", l."LineNumber"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "saldo"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND je."Status" <> 'VOIDED'
      AND l."AccountCodeSnapshot" = p_cod_cuenta
      AND je."EntryDate" >= p_fecha_desde
      AND je."EntryDate" <= p_fecha_hasta
    ORDER BY je."EntryDate", je."JournalEntryId", l."LineNumber";
END;
$$;

-- =============================================================================
--  23. usp_Acct_Report_BalanceComprobacion
--  Reporte de balance de comprobacion.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_report_balancecomprobacion(INT, INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_report_balancecomprobacion(
    p_company_id  INT,
    p_branch_id   INT,
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "codCuenta"   VARCHAR,
    "cuenta"      VARCHAR,
    "totalDebe"   NUMERIC,
    "totalHaber"  NUMERIC,
    "saldo"       NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        l."AccountCodeSnapshot"::VARCHAR  AS "codCuenta",
        MAX(a."AccountName")::VARCHAR     AS "cuenta",
        SUM(l."DebitAmount")              AS "totalDebe",
        SUM(l."CreditAmount")             AS "totalHaber",
        SUM(l."DebitAmount" - l."CreditAmount") AS "saldo"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    LEFT JOIN acct."Account" a ON a."AccountId" = l."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND je."Status" <> 'VOIDED'
      AND je."EntryDate" >= p_fecha_desde
      AND je."EntryDate" <= p_fecha_hasta
    GROUP BY l."AccountCodeSnapshot"
    ORDER BY l."AccountCodeSnapshot";
END;
$$;

-- =============================================================================
--  24. usp_Acct_Report_EstadoResultados
--  Reporte de estado de resultados (ingresos y gastos).
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_report_estadoresultados(INT, INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_report_estadoresultados(
    p_company_id  INT,
    p_branch_id   INT,
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "codCuenta"   VARCHAR,
    "cuenta"      VARCHAR,
    "tipo"        VARCHAR,
    "totalDebe"   NUMERIC,
    "totalHaber"  NUMERIC,
    "monto"       NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        l."AccountCodeSnapshot"::VARCHAR  AS "codCuenta",
        MAX(a."AccountName")::VARCHAR     AS "cuenta",
        MAX(a."AccountType")::VARCHAR     AS "tipo",
        SUM(l."DebitAmount")              AS "totalDebe",
        SUM(l."CreditAmount")             AS "totalHaber",
        CASE
            WHEN MAX(a."AccountType") = 'I' THEN SUM(l."CreditAmount" - l."DebitAmount")
            WHEN MAX(a."AccountType") = 'G' THEN SUM(l."DebitAmount" - l."CreditAmount")
            ELSE 0
        END AS "monto"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    INNER JOIN acct."Account" a ON a."AccountId" = l."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND je."Status" <> 'VOIDED'
      AND a."AccountType" IN ('I', 'G')
      AND je."EntryDate" >= p_fecha_desde
      AND je."EntryDate" <= p_fecha_hasta
    GROUP BY l."AccountCodeSnapshot"
    ORDER BY l."AccountCodeSnapshot";
END;
$$;

-- =============================================================================
--  25. usp_Acct_Report_BalanceGeneral
--  Reporte de balance general (activos, pasivos, patrimonio).
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_report_balancegeneral(INT, INT, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_report_balancegeneral(
    p_company_id INT,
    p_branch_id  INT,
    p_fecha_corte DATE
)
RETURNS TABLE(
    "codCuenta"   VARCHAR,
    "cuenta"      VARCHAR,
    "tipo"        VARCHAR,
    "totalDebe"   NUMERIC,
    "totalHaber"  NUMERIC,
    "saldo"       NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        l."AccountCodeSnapshot"::VARCHAR  AS "codCuenta",
        MAX(a."AccountName")::VARCHAR     AS "cuenta",
        MAX(a."AccountType")::VARCHAR     AS "tipo",
        SUM(l."DebitAmount")              AS "totalDebe",
        SUM(l."CreditAmount")             AS "totalHaber",
        CASE
            WHEN MAX(a."AccountType") = 'A' THEN SUM(l."DebitAmount" - l."CreditAmount")
            WHEN MAX(a."AccountType") IN ('P','C') THEN SUM(l."CreditAmount" - l."DebitAmount")
            ELSE 0
        END AS "saldo"
    FROM acct."JournalEntryLine" l
    INNER JOIN acct."JournalEntry" je ON je."JournalEntryId" = l."JournalEntryId"
    INNER JOIN acct."Account" a ON a."AccountId" = l."AccountId"
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId" = p_branch_id
      AND je."IsDeleted" = FALSE
      AND je."Status" <> 'VOIDED'
      AND a."AccountType" IN ('A', 'P', 'C')
      AND je."EntryDate" <= p_fecha_corte
    GROUP BY l."AccountCodeSnapshot"
    ORDER BY l."AccountCodeSnapshot";
END;
$$;

-- =============================================================================
--  26. usp_Acct_SeedPlanCuentas
--  Siembra el plan de cuentas base para una empresa.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_seedplancuentas(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_seedplancuentas(
    p_company_id    INT,
    p_system_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_inserted INT := 1;
BEGIN
    IF p_company_id IS NULL OR p_company_id <= 0 THEN
        RETURN QUERY SELECT 0, 'No existe cfg.Company DEFAULT para sembrar plan de cuentas';
        RETURN;
    END IF;

    -- Crear tabla temporal con plan de cuentas
    CREATE TEMP TABLE _plan (
        "AccountCode"   VARCHAR(40)  NOT NULL,
        "AccountName"   VARCHAR(200) NOT NULL,
        "AccountType"   CHAR(1)      NOT NULL,
        "AccountLevel"  INT          NOT NULL,
        "ParentCode"    VARCHAR(40),
        "AllowsPosting" BOOLEAN      NOT NULL
    ) ON COMMIT DROP;

    INSERT INTO _plan VALUES
        ('1',       'ACTIVO',                    'A', 1, NULL,   FALSE),
        ('1.1',     'ACTIVO CORRIENTE',           'A', 2, '1',   FALSE),
        ('1.2',     'ACTIVO NO CORRIENTE',        'A', 2, '1',   FALSE),
        ('1.1.01',  'CAJA',                       'A', 3, '1.1', TRUE),
        ('1.1.02',  'BANCOS',                     'A', 3, '1.1', TRUE),
        ('1.1.03',  'INVERSIONES TEMPORALES',     'A', 3, '1.1', TRUE),
        ('1.1.04',  'CLIENTES',                   'A', 3, '1.1', TRUE),
        ('1.1.05',  'DOCUMENTOS POR COBRAR',      'A', 3, '1.1', TRUE),
        ('1.1.06',  'INVENTARIOS',                'A', 3, '1.1', TRUE),
        ('1.2.01',  'PROPIEDAD PLANTA Y EQUIPO',  'A', 3, '1.2', TRUE),
        ('1.2.02',  'DEPRECIACION ACUMULADA',     'A', 3, '1.2', TRUE),
        ('2',       'PASIVO',                     'P', 1, NULL,   FALSE),
        ('2.1',     'PASIVO CORRIENTE',           'P', 2, '2',   FALSE),
        ('2.2',     'PASIVO NO CORRIENTE',        'P', 2, '2',   FALSE),
        ('2.1.01',  'PROVEEDORES',                'P', 3, '2.1', TRUE),
        ('2.1.02',  'DOCUMENTOS POR PAGAR',       'P', 3, '2.1', TRUE),
        ('2.1.03',  'IMPUESTOS POR PAGAR',        'P', 3, '2.1', TRUE),
        ('2.1.04',  'SUELDOS POR PAGAR',          'P', 3, '2.1', TRUE),
        ('3',       'PATRIMONIO',                 'C', 1, NULL,   FALSE),
        ('3.1',     'CAPITAL SOCIAL',             'C', 2, '3',   FALSE),
        ('3.1.01',  'CAPITAL SUSCRITO',           'C', 3, '3.1', TRUE),
        ('4',       'INGRESOS',                   'I', 1, NULL,   FALSE),
        ('4.1',     'INGRESOS OPERACIONALES',     'I', 2, '4',   FALSE),
        ('4.1.01',  'VENTAS',                     'I', 3, '4.1', TRUE),
        ('4.1.02',  'DESCUENTOS EN VENTAS',       'I', 3, '4.1', TRUE),
        ('5',       'COSTOS Y GASTOS',            'G', 1, NULL,   FALSE),
        ('5.1',     'COSTO DE VENTAS',            'G', 2, '5',   FALSE),
        ('5.2',     'GASTOS OPERACIONALES',       'G', 2, '5',   FALSE),
        ('5.1.01',  'COSTO DE MERCADERIA',        'G', 3, '5.1', TRUE),
        ('5.2.01',  'SUELDOS Y SALARIOS',         'G', 3, '5.2', TRUE),
        ('5.2.02',  'ALQUILERES',                 'G', 3, '5.2', TRUE),
        ('5.2.03',  'DEPRECIACION',               'G', 3, '5.2', TRUE);

    BEGIN
        WHILE v_inserted > 0
        LOOP
            INSERT INTO acct."Account" (
                "CompanyId", "AccountCode", "AccountName", "AccountType", "AccountLevel",
                "ParentAccountId", "AllowsPosting", "RequiresAuxiliary",
                "IsActive", "CreatedAt", "UpdatedAt", "CreatedByUserId", "UpdatedByUserId", "IsDeleted"
            )
            SELECT
                p_company_id,
                p."AccountCode",
                p."AccountName",
                p."AccountType",
                p."AccountLevel",
                parent."AccountId",
                p."AllowsPosting",
                FALSE,
                TRUE,
                NOW() AT TIME ZONE 'UTC',
                NOW() AT TIME ZONE 'UTC',
                p_system_user_id,
                p_system_user_id,
                FALSE
            FROM _plan p
            LEFT JOIN acct."Account" existing
                ON existing."CompanyId" = p_company_id
               AND existing."AccountCode" = p."AccountCode"
            LEFT JOIN acct."Account" parent
                ON parent."CompanyId" = p_company_id
               AND parent."AccountCode" = p."ParentCode"
            WHERE existing."AccountId" IS NULL
              AND (p."ParentCode" IS NULL OR parent."AccountId" IS NOT NULL);

            GET DIAGNOSTICS v_inserted = ROW_COUNT;
        END LOOP;

        RETURN QUERY SELECT 1, 'Plan de cuentas canonico listo';
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 0, 'Error sembrando plan de cuentas: ' || SQLERRM;
    END;
END;
$$;

-- =============================================================================
--  27. usp_Acct_Scope_GetDefault
--  Obtiene el CompanyId y BranchId por defecto.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_scope_getdefault() CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_scope_getdefault()
RETURNS TABLE("CompanyId" INT, "BranchId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."CompanyId", b."BranchId"
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId"
    WHERE c."IsDeleted" = FALSE
      AND b."IsDeleted" = FALSE
    ORDER BY
        CASE WHEN c."CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, c."CompanyId",
        CASE WHEN b."BranchCode" = 'MAIN' THEN 0 ELSE 1 END, b."BranchId"
    LIMIT 1;
END;
$$;

-- =============================================================================
--  28. usp_Acct_Scope_GetDefaultForSeed
--  Obtiene CompanyId, BranchId y SystemUserId para seed.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_scope_getdefaultforseed() CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_scope_getdefaultforseed()
RETURNS TABLE("CompanyId" INT, "BranchId" INT, "SystemUserId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."CompanyId", b."BranchId", u."UserId" AS "SystemUserId"
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId" AND b."BranchCode" = 'MAIN'
    LEFT JOIN sec."User" u ON u."UserCode" = 'SYSTEM'
    WHERE c."CompanyCode" = 'DEFAULT'
    LIMIT 1;
END;
$$;

-- =============================================================================
--  29. usp_Acct_Report_LibroDiario
--  Reporte de Libro Diario.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_report_librodiario(BIGINT, BIGINT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_report_librodiario(
    p_company_id  BIGINT,
    p_branch_id   BIGINT,
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "fecha"              VARCHAR,
    "asientoId"          BIGINT,
    "numeroAsiento"      VARCHAR,
    "tipoAsiento"        VARCHAR,
    "concepto"           VARCHAR,
    "estado"             VARCHAR,
    "renglon"            INT,
    "codCuenta"          VARCHAR,
    "descripcionCuenta"  VARCHAR,
    "descripcionLinea"   VARCHAR,
    "debe"               NUMERIC,
    "haber"              NUMERIC,
    "centroCosto"        VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        to_char(je."EntryDate", 'YYYY-MM-DD')::VARCHAR AS "fecha",
        je."JournalEntryId"                             AS "asientoId",
        je."EntryNumber"::VARCHAR                       AS "numeroAsiento",
        je."EntryType"::VARCHAR                         AS "tipoAsiento",
        je."Concept"::VARCHAR                           AS "concepto",
        je."Status"::VARCHAR                            AS "estado",
        jel."LineNumber"                                AS "renglon",
        jel."AccountCodeSnapshot"::VARCHAR              AS "codCuenta",
        COALESCE(a."AccountName", jel."Description")::VARCHAR AS "descripcionCuenta",
        jel."Description"::VARCHAR                      AS "descripcionLinea",
        jel."DebitAmount"                               AS "debe",
        jel."CreditAmount"                              AS "haber",
        jel."CostCenterCode"::VARCHAR                   AS "centroCosto"
    FROM acct."JournalEntry" je
    INNER JOIN acct."JournalEntryLine" jel ON jel."JournalEntryId" = je."JournalEntryId"
    LEFT JOIN acct."Account" a ON a."AccountId" = jel."AccountId" AND a."CompanyId" = p_company_id
    WHERE je."CompanyId" = p_company_id
      AND je."BranchId"  = p_branch_id
      AND je."EntryDate" >= p_fecha_desde
      AND je."EntryDate" <= p_fecha_hasta
      AND je."IsDeleted"  = FALSE
      AND je."Status"    <> 'VOIDED'
    ORDER BY je."EntryDate", je."JournalEntryId", jel."LineNumber";
END;
$$;

-- =============================================================================
--  30. usp_Acct_Dashboard_Resumen
--  Resumen de dashboard del modulo contable.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_acct_dashboard_resumen(BIGINT, BIGINT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_acct_dashboard_resumen(
    p_company_id  BIGINT,
    p_branch_id   BIGINT,
    p_fecha_desde DATE,
    p_fecha_hasta DATE
)
RETURNS TABLE(
    "totalIngresos"    NUMERIC,
    "totalGastos"      NUMERIC,
    "margenPorcentaje" NUMERIC,
    "cuentasPorPagar"  NUMERIC,
    "totalAsientos"    INT,
    "totalCuentas"     INT,
    "totalAnulados"    INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total_ingresos   NUMERIC(18,2) := 0;
    v_total_gastos     NUMERIC(18,2) := 0;
    v_cuentas_por_pagar NUMERIC(18,2) := 0;
    v_total_asientos   INT := 0;
    v_total_cuentas    INT := 0;
    v_total_anulados   INT := 0;
BEGIN
    -- Total Ingresos (account type I)
    SELECT COALESCE(SUM(jel."CreditAmount" - jel."DebitAmount"), 0) INTO v_total_ingresos
    FROM acct."JournalEntry" je
    INNER JOIN acct."JournalEntryLine" jel ON jel."JournalEntryId" = je."JournalEntryId"
    INNER JOIN acct."Account" a ON a."AccountId" = jel."AccountId" AND a."CompanyId" = p_company_id
    WHERE je."CompanyId" = p_company_id AND je."BranchId" = p_branch_id
      AND je."EntryDate" >= p_fecha_desde AND je."EntryDate" <= p_fecha_hasta
      AND je."IsDeleted" = FALSE AND je."Status" <> 'VOIDED'
      AND a."AccountType" = 'I';

    -- Total Gastos (account type G)
    SELECT COALESCE(SUM(jel."DebitAmount" - jel."CreditAmount"), 0) INTO v_total_gastos
    FROM acct."JournalEntry" je
    INNER JOIN acct."JournalEntryLine" jel ON jel."JournalEntryId" = je."JournalEntryId"
    INNER JOIN acct."Account" a ON a."AccountId" = jel."AccountId" AND a."CompanyId" = p_company_id
    WHERE je."CompanyId" = p_company_id AND je."BranchId" = p_branch_id
      AND je."EntryDate" >= p_fecha_desde AND je."EntryDate" <= p_fecha_hasta
      AND je."IsDeleted" = FALSE AND je."Status" <> 'VOIDED'
      AND a."AccountType" = 'G';

    -- Cuentas por pagar (account type P, code starts with '2.1')
    SELECT COALESCE(SUM(jel."CreditAmount" - jel."DebitAmount"), 0) INTO v_cuentas_por_pagar
    FROM acct."JournalEntry" je
    INNER JOIN acct."JournalEntryLine" jel ON jel."JournalEntryId" = je."JournalEntryId"
    INNER JOIN acct."Account" a ON a."AccountId" = jel."AccountId" AND a."CompanyId" = p_company_id
    WHERE je."CompanyId" = p_company_id AND je."BranchId" = p_branch_id
      AND je."EntryDate" >= p_fecha_desde AND je."EntryDate" <= p_fecha_hasta
      AND je."IsDeleted" = FALSE AND je."Status" <> 'VOIDED'
      AND a."AccountType" = 'P' AND a."AccountCode" LIKE '2.1%';

    -- Counts
    SELECT COUNT(*) INTO v_total_asientos
    FROM acct."JournalEntry"
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
      AND "EntryDate" >= p_fecha_desde AND "EntryDate" <= p_fecha_hasta
      AND "IsDeleted" = FALSE AND "Status" <> 'VOIDED';

    SELECT COUNT(*) INTO v_total_anulados
    FROM acct."JournalEntry"
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
      AND "EntryDate" >= p_fecha_desde AND "EntryDate" <= p_fecha_hasta
      AND "IsDeleted" = FALSE AND "Status" = 'VOIDED';

    SELECT COUNT(*) INTO v_total_cuentas
    FROM acct."Account"
    WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE AND "IsActive" = TRUE;

    RETURN QUERY
    SELECT
        v_total_ingresos,
        v_total_gastos,
        CASE WHEN v_total_ingresos > 0
             THEN ROUND((v_total_ingresos - v_total_gastos) / v_total_ingresos * 100, 2)
             ELSE 0
        END,
        v_cuentas_por_pagar,
        v_total_asientos,
        v_total_cuentas,
        v_total_anulados;
END;
$$;
