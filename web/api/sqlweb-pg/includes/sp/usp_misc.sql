/* ============================================================================
 *  usp_misc.sql  (PostgreSQL)
 *  ---------------------------------------------------------------------------
 *  Funciones miscelaneas para modulos CxC, CxP, Nomina
 *  y Conceptos Legales de Nomina.
 *
 *  Traducido de SQL Server -> PostgreSQL.
 *  Convenciones:
 *    - CxC  : usp_ar_receivable_*, usp_ar_balance_*
 *    - CxP  : usp_ap_payable_*, usp_ap_balance_*
 *    - Nomina: usp_hr_payroll_*, usp_hr_legalconcept_*
 *
 *  Patron: CREATE OR REPLACE FUNCTION (idempotente)
 * ============================================================================ */


-- =============================================================================
--  SECCION 1: CUENTAS POR COBRAR (AR - Accounts Receivable)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_applypayment
--  Aplica un cobro transaccional a documentos CxC de un cliente.
--  Recibe la lista de documentos como JSON.
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ar_receivable_applypayment(VARCHAR(24), DATE, VARCHAR(120), VARCHAR(120), TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_applypayment(
    p_cod_cliente      VARCHAR(24),
    p_fecha            DATE             DEFAULT NULL,
    p_request_id       VARCHAR(120)     DEFAULT NULL,
    p_num_recibo       VARCHAR(120)     DEFAULT NULL,
    p_documentos_json  TEXT             DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
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

    -- Iterar documentos desde JSON
    FOR rec IN
        SELECT
            elem->>'tipoDoc'      AS tipo_doc,
            elem->>'numDoc'       AS num_doc,
            (elem->>'montoAplicar')::NUMERIC(18,2) AS monto_aplicar
        FROM jsonb_array_elements(p_documentos_json::JSONB) AS elem
    LOOP
        v_doc_id := NULL;
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
                                       ELSE "PendingAmount" - v_apply_amount END,
                "PaidFlag" = CASE WHEN "PendingAmount" - v_apply_amount <= 0 THEN TRUE ELSE FALSE END,
                "Status" = CASE
                             WHEN "PendingAmount" - v_apply_amount <= 0 THEN 'PAID'
                             WHEN "PendingAmount" - v_apply_amount < "TotalAmount" THEN 'PARTIAL'
                             ELSE 'PENDING'
                           END,
                "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
            WHERE "ReceivableDocumentId" = v_doc_id;

            v_applied := v_applied + v_apply_amount;
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
$$;

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_list
--  Lista paginada de documentos CxC.
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ar_receivable_list(VARCHAR(24), VARCHAR(20), VARCHAR(20), DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_list(
    p_cod_cliente   VARCHAR(24)    DEFAULT NULL,
    p_tipo_doc      VARCHAR(20)    DEFAULT NULL,
    p_estado        VARCHAR(20)    DEFAULT NULL,
    p_fecha_desde   DATE           DEFAULT NULL,
    p_fecha_hasta   DATE           DEFAULT NULL,
    p_offset        INT            DEFAULT 0,
    p_limit         INT            DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "codCliente" VARCHAR,
    "tipoDoc" VARCHAR,
    "numDoc" VARCHAR,
    "fecha" DATE,
    "total" NUMERIC,
    "pendiente" NUMERIC,
    "estado" VARCHAR,
    "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
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
$$;

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_getpending
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ar_receivable_getpending(VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_getpending(
    p_cod_cliente VARCHAR(24)
)
RETURNS TABLE(
    "tipoDoc" VARCHAR,
    "numDoc" VARCHAR,
    "fecha" DATE,
    "pendiente" NUMERIC,
    "total" NUMERIC
)
LANGUAGE plpgsql AS $$
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
$$;

-- -----------------------------------------------------------------------------
--  usp_ar_balance_getbycustomer
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ar_balance_getbycustomer(VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_balance_getbycustomer(
    p_cod_cliente VARCHAR(24)
)
RETURNS TABLE(
    "saldoTotal" NUMERIC,
    "saldo30" NUMERIC,
    "saldo60" NUMERIC,
    "saldo90" NUMERIC,
    "saldo91" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(c."TotalBalance", 0)::NUMERIC(18,2),
        0::NUMERIC(18,2),
        0::NUMERIC(18,2),
        0::NUMERIC(18,2),
        0::NUMERIC(18,2)
    FROM master."Customer" c
    WHERE c."CustomerCode" = p_cod_cliente
      AND c."IsDeleted" = FALSE;
END;
$$;


-- =============================================================================
--  SECCION 2: CUENTAS POR PAGAR (AP - Accounts Payable)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_ap_payable_applypayment
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ap_payable_applypayment(VARCHAR(24), DATE, VARCHAR(120), VARCHAR(120), TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_applypayment(
    p_cod_proveedor    VARCHAR(24),
    p_fecha            DATE             DEFAULT NULL,
    p_request_id       VARCHAR(120)     DEFAULT NULL,
    p_num_pago         VARCHAR(120)     DEFAULT NULL,
    p_documentos_json  TEXT             DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
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
        RETURN;
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
        INTO v_doc_id, v_pending
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
$$;

-- -----------------------------------------------------------------------------
--  usp_ap_payable_list
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ap_payable_list(VARCHAR(24), VARCHAR(20), VARCHAR(20), DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_list(
    p_cod_proveedor  VARCHAR(24)    DEFAULT NULL,
    p_tipo_doc       VARCHAR(20)    DEFAULT NULL,
    p_estado         VARCHAR(20)    DEFAULT NULL,
    p_fecha_desde    DATE           DEFAULT NULL,
    p_fecha_hasta    DATE           DEFAULT NULL,
    p_offset         INT            DEFAULT 0,
    p_limit          INT            DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "codProveedor" VARCHAR,
    "tipoDoc" VARCHAR,
    "numDoc" VARCHAR,
    "fecha" DATE,
    "total" NUMERIC,
    "pendiente" NUMERIC,
    "estado" VARCHAR,
    "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
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
$$;

-- -----------------------------------------------------------------------------
--  usp_ap_payable_getpending
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ap_payable_getpending(VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_getpending(
    p_cod_proveedor VARCHAR(24)
)
RETURNS TABLE(
    "tipoDoc" VARCHAR,
    "numDoc" VARCHAR,
    "fecha" DATE,
    "pendiente" NUMERIC,
    "total" NUMERIC
)
LANGUAGE plpgsql AS $$
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
$$;

-- -----------------------------------------------------------------------------
--  usp_ap_balance_getbysupplier
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ap_balance_getbysupplier(VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_balance_getbysupplier(
    p_cod_proveedor VARCHAR(24)
)
RETURNS TABLE(
    "saldoTotal" NUMERIC,
    "saldo30" NUMERIC,
    "saldo60" NUMERIC,
    "saldo90" NUMERIC,
    "saldo91" NUMERIC
)
LANGUAGE plpgsql AS $$
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
$$;


-- =============================================================================
--  SECCION 3: CUENTAS POR PAGAR CRUD
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_ap_payable_listfull
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ap_payable_listfull(VARCHAR(200), VARCHAR(24), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_listfull(
    p_search   VARCHAR(200)  DEFAULT NULL,
    p_codigo   VARCHAR(24)   DEFAULT NULL,
    p_offset   INT           DEFAULT 0,
    p_limit    INT           DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "id" BIGINT,
    "codigo" VARCHAR,
    "nombre" VARCHAR,
    "tipo" VARCHAR,
    "documento" VARCHAR,
    "fecha" DATE,
    "fechaVence" DATE,
    "total" NUMERIC,
    "pendiente" NUMERIC,
    "estado" VARCHAR,
    "moneda" VARCHAR,
    "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
    v_total      BIGINT;
    v_search_pat VARCHAR(202) := CASE WHEN p_search IS NOT NULL THEN '%' || p_search || '%' ELSE NULL END;
BEGIN
    SELECT "CompanyId" INTO v_company_id
    FROM cfg."Company" WHERE "IsDeleted" = FALSE
    ORDER BY CASE WHEN "CompanyCode" = 'DEFAULT' THEN 0 ELSE 1 END, "CompanyId"
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
        d."TotalAmount",
        d."PendingAmount",
        d."Status",
        d."CurrencyCode"::VARCHAR,
        d."Notes"
    FROM ap."PayableDocument" d
    INNER JOIN master."Supplier" s ON s."SupplierId" = d."SupplierId"
    WHERE d."CompanyId" = v_company_id
      AND d."BranchId"  = v_branch_id
      AND (v_search_pat IS NULL OR (d."DocumentNumber" ILIKE v_search_pat OR d."Notes" ILIKE v_search_pat OR s."SupplierName" ILIKE v_search_pat))
      AND (p_codigo IS NULL OR s."SupplierCode" = p_codigo)
    ORDER BY d."IssueDate" DESC, d."PayableDocumentId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_ap_payable_getbyid
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ap_payable_getbyid(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_getbyid(
    p_id BIGINT
)
RETURNS TABLE(
    "id" BIGINT, "codigo" VARCHAR, "nombre" VARCHAR, "tipo" VARCHAR,
    "documento" VARCHAR, "fecha" DATE, "fechaVence" DATE,
    "total" NUMERIC, "pendiente" NUMERIC, "estado" VARCHAR,
    "moneda" VARCHAR, "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
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
$$;

-- -----------------------------------------------------------------------------
--  usp_ap_payable_create
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ap_payable_create(VARCHAR(24), VARCHAR(20), VARCHAR(120), DATE, DATE, VARCHAR(10), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_create(
    p_codigo         VARCHAR(24),
    p_document_type  VARCHAR(20)    DEFAULT 'COMPRA',
    p_document_number VARCHAR(120)  DEFAULT NULL,
    p_issue_date     DATE           DEFAULT NULL,
    p_due_date       DATE           DEFAULT NULL,
    p_currency_code  VARCHAR(10)    DEFAULT 'USD',
    p_total_amount   NUMERIC(18,2)  DEFAULT 0,
    p_pending_amount NUMERIC(18,2)  DEFAULT NULL,
    p_notes          VARCHAR(500)   DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
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
        RETURN;
    END IF;

    INSERT INTO ap."PayableDocument" (
        "CompanyId", "BranchId", "SupplierId", "DocumentType", "DocumentNumber",
        "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount",
        "PaidFlag", "Status", "Notes", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_company_id, v_branch_id, v_supplier_id, p_document_type, p_document_number,
        COALESCE(p_issue_date, (NOW() AT TIME ZONE 'UTC')::DATE),
        COALESCE(p_due_date, p_issue_date, (NOW() AT TIME ZONE 'UTC')::DATE),
        p_currency_code, p_total_amount, v_pend,
        CASE WHEN v_pend <= 0 THEN TRUE ELSE FALSE END,
        CASE WHEN v_pend <= 0 THEN 'PAID' WHEN v_pend < p_total_amount THEN 'PARTIAL' ELSE 'PENDING' END,
        p_notes, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_ap_payable_update
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ap_payable_update(BIGINT, VARCHAR(20), VARCHAR(120), DATE, DATE, NUMERIC(18,2), NUMERIC(18,2), VARCHAR(20), VARCHAR(10), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_update(
    p_id              BIGINT,
    p_document_type   VARCHAR(20)    DEFAULT NULL,
    p_document_number VARCHAR(120)   DEFAULT NULL,
    p_issue_date      DATE           DEFAULT NULL,
    p_due_date        DATE           DEFAULT NULL,
    p_total_amount    NUMERIC(18,2)  DEFAULT NULL,
    p_pending_amount  NUMERIC(18,2)  DEFAULT NULL,
    p_status          VARCHAR(20)    DEFAULT NULL,
    p_currency_code   VARCHAR(10)    DEFAULT NULL,
    p_notes           VARCHAR(500)   DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE ap."PayableDocument"
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
    WHERE "PayableDocumentId" = p_id;

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_ap_payable_void
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ap_payable_void(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ap_payable_void(
    p_id BIGINT
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE ap."PayableDocument"
    SET "PendingAmount" = 0,
        "PaidFlag"      = TRUE,
        "Status"        = 'VOIDED',
        "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
    WHERE "PayableDocumentId" = p_id;

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;


-- =============================================================================
--  SECCION 4: CUENTAS POR COBRAR CRUD
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_listfull
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ar_receivable_listfull(VARCHAR(200), VARCHAR(24), VARCHAR(10), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_listfull(
    p_search        VARCHAR(200)  DEFAULT NULL,
    p_codigo        VARCHAR(24)   DEFAULT NULL,
    p_currency_code VARCHAR(10)   DEFAULT NULL,
    p_offset        INT           DEFAULT 0,
    p_limit         INT           DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "id" BIGINT, "codigo" VARCHAR, "nombre" VARCHAR, "tipo" VARCHAR,
    "documento" VARCHAR, "fecha" DATE, "fechaVence" DATE,
    "total" NUMERIC, "pendiente" NUMERIC, "estado" VARCHAR,
    "moneda" VARCHAR, "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
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
        d."CurrencyCode"::VARCHAR, d."Notes"
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
$$;

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_getbyid
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ar_receivable_getbyid(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_getbyid(p_id BIGINT)
RETURNS TABLE(
    "id" BIGINT, "codigo" VARCHAR, "nombre" VARCHAR, "tipo" VARCHAR,
    "documento" VARCHAR, "fecha" DATE, "fechaVence" DATE,
    "total" NUMERIC, "pendiente" NUMERIC, "estado" VARCHAR,
    "moneda" VARCHAR, "observacion" VARCHAR
)
LANGUAGE plpgsql AS $$
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
$$;

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_create
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ar_receivable_create(VARCHAR(24), VARCHAR(20), VARCHAR(120), DATE, DATE, VARCHAR(10), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_create(
    p_codigo          VARCHAR(24),
    p_document_type   VARCHAR(20)    DEFAULT 'FACT',
    p_document_number VARCHAR(120)   DEFAULT NULL,
    p_issue_date      DATE           DEFAULT NULL,
    p_due_date        DATE           DEFAULT NULL,
    p_currency_code   VARCHAR(10)    DEFAULT 'USD',
    p_total_amount    NUMERIC(18,2)  DEFAULT 0,
    p_pending_amount  NUMERIC(18,2)  DEFAULT NULL,
    p_notes           VARCHAR(500)   DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
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
$$;

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_update
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ar_receivable_update(BIGINT, VARCHAR(20), VARCHAR(120), DATE, DATE, NUMERIC(18,2), NUMERIC(18,2), VARCHAR(20), VARCHAR(10), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_update(
    p_id              BIGINT,
    p_document_type   VARCHAR(20)    DEFAULT NULL,
    p_document_number VARCHAR(120)   DEFAULT NULL,
    p_issue_date      DATE           DEFAULT NULL,
    p_due_date        DATE           DEFAULT NULL,
    p_total_amount    NUMERIC(18,2)  DEFAULT NULL,
    p_pending_amount  NUMERIC(18,2)  DEFAULT NULL,
    p_status          VARCHAR(20)    DEFAULT NULL,
    p_currency_code   VARCHAR(10)    DEFAULT NULL,
    p_notes           VARCHAR(500)   DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
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
$$;

-- -----------------------------------------------------------------------------
--  usp_ar_receivable_void
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_ar_receivable_void(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_ar_receivable_void(p_id BIGINT)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE ar."ReceivableDocument"
    SET "PendingAmount" = 0,
        "PaidFlag"      = TRUE,
        "Status"        = 'VOIDED',
        "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
    WHERE "ReceivableDocumentId" = p_id;

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;


-- =============================================================================
--  SECCION 5: NOMINA (HR - Human Resources)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_resolvescope
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_resolvescope() CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_resolvescope()
RETURNS TABLE("companyId" INT, "branchId" INT, "systemUserId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CompanyId",
        b."BranchId",
        su."UserId"
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

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_resolveuser
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_resolveuser(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_resolveuser(
    p_user_code VARCHAR(60) DEFAULT NULL
)
RETURNS TABLE("userId" INT)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_user_code IS NOT NULL AND TRIM(p_user_code) <> '' THEN
        RETURN QUERY
        SELECT u."UserId"
        FROM sec."User" u
        WHERE UPPER(u."UserCode") = UPPER(p_user_code)
        ORDER BY u."UserId"
        LIMIT 1;
        RETURN;
    END IF;

    RETURN QUERY
    SELECT u."UserId"
    FROM sec."User" u
    WHERE u."UserCode" = 'SYSTEM'
    ORDER BY u."UserId"
    LIMIT 1;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getconstant
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_getconstant(INT, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getconstant(
    p_company_id INT,
    p_code       VARCHAR(60)
)
RETURNS TABLE("value" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT pc."ConstantValue"
    FROM hr."PayrollConstant" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."ConstantCode" = p_code
      AND pc."IsActive" = TRUE
    ORDER BY pc."PayrollConstantId" DESC
    LIMIT 1;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_ensuretype
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_ensuretype(INT, VARCHAR(15), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_ensuretype(
    p_company_id   INT,
    p_payroll_code VARCHAR(15),
    p_user_id      INT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM hr."PayrollType"
        WHERE "CompanyId" = p_company_id AND "PayrollCode" = p_payroll_code
    ) THEN
        INSERT INTO hr."PayrollType" ("CompanyId", "PayrollCode", "PayrollName", "IsActive", "CreatedByUserId", "UpdatedByUserId")
        VALUES (p_company_id, p_payroll_code, 'Nomina ' || p_payroll_code, TRUE, p_user_id, p_user_id);
    END IF;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_ensureemployee
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_ensureemployee(INT, VARCHAR(24), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_ensureemployee(
    p_company_id INT,
    p_document   VARCHAR(24),
    p_user_id    INT DEFAULT NULL
)
RETURNS TABLE("employeeId" BIGINT, "employeeCode" VARCHAR, "employeeName" VARCHAR, "hireDate" DATE)
LANGUAGE plpgsql AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM master."Employee"
        WHERE "CompanyId" = p_company_id AND "IsDeleted" = FALSE
          AND ("EmployeeCode" = p_document OR "FiscalId" = p_document)
    ) INTO v_exists;

    IF v_exists THEN
        RETURN QUERY
        SELECT e."EmployeeId", e."EmployeeCode", e."EmployeeName", e."HireDate"
        FROM master."Employee" e
        WHERE e."CompanyId" = p_company_id AND e."IsDeleted" = FALSE
          AND (e."EmployeeCode" = p_document OR e."FiscalId" = p_document)
        ORDER BY e."EmployeeId"
        LIMIT 1;
        RETURN;
    END IF;

    RETURN QUERY
    INSERT INTO master."Employee" (
        "CompanyId", "EmployeeCode", "EmployeeName", "FiscalId",
        "HireDate", "IsActive", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
        p_company_id, p_document, 'Empleado ' || p_document, p_document,
        (NOW() AT TIME ZONE 'UTC')::DATE, TRUE, p_user_id, p_user_id
    )
    RETURNING "EmployeeId", "EmployeeCode", "EmployeeName", "HireDate";
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listconcepts
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_listconcepts(INT, VARCHAR(15), VARCHAR(15), VARCHAR(200), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listconcepts(
    p_company_id   INT,
    p_payroll_code VARCHAR(15)  DEFAULT NULL,
    p_concept_type VARCHAR(15)  DEFAULT NULL,
    p_search       VARCHAR(200) DEFAULT NULL,
    p_offset       INT          DEFAULT 0,
    p_limit        INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "codigo" VARCHAR, "codigoNomina" VARCHAR, "nombre" VARCHAR,
    "formula" VARCHAR, "sobre" VARCHAR, "clase" VARCHAR,
    "tipo" VARCHAR, "uso" VARCHAR, "bonificable" VARCHAR,
    "esAntiguedad" VARCHAR, "cuentaContable" VARCHAR,
    "aplica" VARCHAR, "valorDefecto" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
    v_search_pat VARCHAR(202) := CASE WHEN p_search IS NOT NULL THEN '%' || p_search || '%' ELSE NULL END;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollConcept"
    WHERE "CompanyId" = p_company_id
      AND "IsActive" = TRUE
      AND (p_payroll_code IS NULL OR "PayrollCode" = p_payroll_code)
      AND (p_concept_type IS NULL OR "ConceptType" = p_concept_type)
      AND (v_search_pat IS NULL OR ("ConceptCode" ILIKE v_search_pat OR "ConceptName" ILIKE v_search_pat));

    RETURN QUERY
    SELECT
        v_total,
        pc."ConceptCode", pc."PayrollCode", pc."ConceptName",
        pc."Formula", pc."BaseExpression", pc."ConceptClass",
        pc."ConceptType", pc."UsageType",
        CASE WHEN pc."IsBonifiable" THEN 'S' ELSE 'N' END,
        CASE WHEN pc."IsSeniority" THEN 'S' ELSE 'N' END,
        pc."AccountingAccountCode",
        CASE WHEN pc."AppliesFlag" THEN 'S' ELSE 'N' END,
        pc."DefaultValue"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."IsActive" = TRUE
      AND (p_payroll_code IS NULL OR pc."PayrollCode" = p_payroll_code)
      AND (p_concept_type IS NULL OR pc."ConceptType" = p_concept_type)
      AND (v_search_pat IS NULL OR (pc."ConceptCode" ILIKE v_search_pat OR pc."ConceptName" ILIKE v_search_pat))
    ORDER BY pc."PayrollCode", pc."SortOrder", pc."ConceptCode"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_saveconcept
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_saveconcept(INT, VARCHAR(15), VARCHAR(20), VARCHAR(120), VARCHAR(500), VARCHAR(200), VARCHAR(30), VARCHAR(15), VARCHAR(30), BOOLEAN, BOOLEAN, VARCHAR(50), BOOLEAN, NUMERIC(18,4), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_saveconcept(
    p_company_id              INT,
    p_payroll_code            VARCHAR(15),
    p_concept_code            VARCHAR(20),
    p_concept_name            VARCHAR(120),
    p_formula                 VARCHAR(500)  DEFAULT NULL,
    p_base_expression         VARCHAR(200)  DEFAULT NULL,
    p_concept_class           VARCHAR(30)   DEFAULT NULL,
    p_concept_type            VARCHAR(15)   DEFAULT 'ASIGNACION',
    p_usage_type              VARCHAR(30)   DEFAULT NULL,
    p_is_bonifiable           BOOLEAN       DEFAULT FALSE,
    p_is_seniority            BOOLEAN       DEFAULT FALSE,
    p_accounting_account_code VARCHAR(50)   DEFAULT NULL,
    p_applies_flag            BOOLEAN       DEFAULT TRUE,
    p_default_value           NUMERIC(18,4) DEFAULT 0,
    p_user_id                 INT           DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_existing_id BIGINT;
BEGIN
    SELECT "PayrollConceptId" INTO v_existing_id
    FROM hr."PayrollConcept"
    WHERE "CompanyId" = p_company_id
      AND "PayrollCode" = p_payroll_code
      AND "ConceptCode" = p_concept_code
      AND "ConventionCode" IS NULL
      AND "CalculationType" IS NULL
    ORDER BY "PayrollConceptId"
    LIMIT 1;

    IF v_existing_id IS NOT NULL THEN
        UPDATE hr."PayrollConcept"
        SET "ConceptName"           = p_concept_name,
            "Formula"               = p_formula,
            "BaseExpression"        = p_base_expression,
            "ConceptClass"          = p_concept_class,
            "ConceptType"           = p_concept_type,
            "UsageType"             = p_usage_type,
            "IsBonifiable"          = p_is_bonifiable,
            "IsSeniority"           = p_is_seniority,
            "AccountingAccountCode" = p_accounting_account_code,
            "AppliesFlag"           = p_applies_flag,
            "DefaultValue"          = p_default_value,
            "UpdatedAt"             = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"       = p_user_id
        WHERE "PayrollConceptId" = v_existing_id;
    ELSE
        INSERT INTO hr."PayrollConcept" (
            "CompanyId", "PayrollCode", "ConceptCode", "ConceptName",
            "Formula", "BaseExpression", "ConceptClass", "ConceptType",
            "UsageType", "IsBonifiable", "IsSeniority", "AccountingAccountCode",
            "AppliesFlag", "DefaultValue", "ConventionCode", "CalculationType",
            "SortOrder", "IsActive", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_payroll_code, p_concept_code, p_concept_name,
            p_formula, p_base_expression, p_concept_class, p_concept_type,
            p_usage_type, p_is_bonifiable, p_is_seniority, p_accounting_account_code,
            p_applies_flag, p_default_value, NULL, NULL,
            0, TRUE, p_user_id, p_user_id
        );
    END IF;

    RETURN QUERY SELECT 1, 'Concepto guardado'::TEXT;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_loadconceptsforrun
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_loadconceptsforrun(INT, VARCHAR(15), VARCHAR(15), VARCHAR(30), VARCHAR(30), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_loadconceptsforrun(
    p_company_id       INT,
    p_payroll_code     VARCHAR(15),
    p_concept_type     VARCHAR(15)  DEFAULT NULL,
    p_convention_code  VARCHAR(30)  DEFAULT NULL,
    p_calculation_type VARCHAR(30)  DEFAULT NULL,
    p_solo_legales     BOOLEAN      DEFAULT FALSE
)
RETURNS TABLE(
    "conceptCode" VARCHAR, "conceptName" VARCHAR, "conceptType" VARCHAR,
    "defaultValue" NUMERIC, "formula" VARCHAR, "accountingAccountCode" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc."ConceptCode", pc."ConceptName", pc."ConceptType",
        pc."DefaultValue", pc."Formula", pc."AccountingAccountCode"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId"   = p_company_id
      AND pc."PayrollCode" = p_payroll_code
      AND pc."IsActive"    = TRUE
      AND pc."AppliesFlag" = TRUE
      AND (p_concept_type IS NULL OR pc."ConceptType" = p_concept_type)
      AND (
            (p_solo_legales AND (
                (p_convention_code IS NOT NULL AND pc."ConventionCode" = p_convention_code)
                OR
                (p_convention_code IS NULL AND pc."ConventionCode" IS NOT NULL)
            ))
            OR
            (NOT p_solo_legales AND (
                (p_convention_code IS NOT NULL AND (pc."ConventionCode" = p_convention_code OR pc."ConventionCode" IS NULL))
                OR
                (p_convention_code IS NULL)
            ))
          )
      AND (p_calculation_type IS NULL OR pc."CalculationType" = p_calculation_type OR pc."CalculationType" IS NULL)
    ORDER BY pc."SortOrder", pc."ConceptCode";
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_upsertrun
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_upsertrun(INT, INT, VARCHAR(15), BIGINT, VARCHAR(24), VARCHAR(200), DATE, DATE, NUMERIC(18,2), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(50), INT, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_upsertrun(
    p_company_id         INT,
    p_branch_id          INT,
    p_payroll_code       VARCHAR(15),
    p_employee_id        BIGINT,
    p_employee_code      VARCHAR(24),
    p_employee_name      VARCHAR(200),
    p_from_date          DATE,
    p_to_date            DATE,
    p_total_assignments  NUMERIC(18,2),
    p_total_deductions   NUMERIC(18,2),
    p_net_total          NUMERIC(18,2),
    p_payroll_type_name  VARCHAR(50)  DEFAULT NULL,
    p_user_id            INT          DEFAULT NULL,
    p_lines_json         TEXT         DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_run_id BIGINT;
BEGIN
    -- Buscar run existente
    SELECT "PayrollRunId" INTO v_run_id
    FROM hr."PayrollRun"
    WHERE "CompanyId"    = p_company_id
      AND "BranchId"     = p_branch_id
      AND "PayrollCode"  = p_payroll_code
      AND "EmployeeCode" = p_employee_code
      AND "DateFrom"     = p_from_date
      AND "DateTo"       = p_to_date
      AND "RunSource"    = 'MANUAL'
    ORDER BY "PayrollRunId" DESC
    LIMIT 1;

    IF v_run_id IS NOT NULL THEN
        UPDATE hr."PayrollRun"
        SET "ProcessDate"      = (NOW() AT TIME ZONE 'UTC')::DATE,
            "TotalAssignments" = p_total_assignments,
            "TotalDeductions"  = p_total_deductions,
            "NetTotal"         = p_net_total,
            "PayrollTypeName"  = COALESCE(p_payroll_type_name, "PayrollTypeName"),
            "UpdatedAt"        = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"  = p_user_id
        WHERE "PayrollRunId" = v_run_id;

        DELETE FROM hr."PayrollRunLine" WHERE "PayrollRunId" = v_run_id;
    ELSE
        INSERT INTO hr."PayrollRun" (
            "CompanyId", "BranchId", "PayrollCode", "EmployeeId", "EmployeeCode",
            "EmployeeName", "PositionName", "ProcessDate", "DateFrom", "DateTo",
            "TotalAssignments", "TotalDeductions", "NetTotal", "PayrollTypeName",
            "RunSource", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_payroll_code, p_employee_id, p_employee_code,
            p_employee_name, NULL, (NOW() AT TIME ZONE 'UTC')::DATE, p_from_date, p_to_date,
            p_total_assignments, p_total_deductions, p_net_total, p_payroll_type_name,
            'MANUAL', p_user_id, p_user_id
        )
        RETURNING "PayrollRunId" INTO v_run_id;
    END IF;

    -- Insertar lineas desde JSON
    IF p_lines_json IS NOT NULL AND LENGTH(p_lines_json) > 2 THEN
        INSERT INTO hr."PayrollRunLine" (
            "PayrollRunId", "ConceptCode", "ConceptName", "ConceptType",
            "Quantity", "Amount", "Total", "DescriptionText", "AccountingAccountCode"
        )
        SELECT
            v_run_id,
            elem->>'code',
            elem->>'name',
            elem->>'type',
            (elem->>'quantity')::NUMERIC(18,4),
            (elem->>'amount')::NUMERIC(18,4),
            (elem->>'total')::NUMERIC(18,2),
            elem->>'description',
            elem->>'account'
        FROM jsonb_array_elements(p_lines_json::JSONB) AS elem;
    END IF;

    RETURN QUERY SELECT 1, 'ok'::TEXT;

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, ('Error en upsert run: ' || SQLERRM)::TEXT;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listactiveemployees
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_listactiveemployees(INT, BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listactiveemployees(
    p_company_id   INT,
    p_solo_activos BOOLEAN DEFAULT TRUE
)
RETURNS TABLE("employeeCode" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT e."EmployeeCode"
    FROM master."Employee" e
    WHERE e."CompanyId" = p_company_id
      AND e."IsDeleted" = FALSE
      AND (NOT p_solo_activos OR e."IsActive" = TRUE)
    ORDER BY e."EmployeeCode";
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listruns
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_listruns(INT, VARCHAR(15), VARCHAR(24), DATE, DATE, BOOLEAN, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listruns(
    p_company_id    INT,
    p_payroll_code  VARCHAR(15)  DEFAULT NULL,
    p_employee_code VARCHAR(24)  DEFAULT NULL,
    p_from_date     DATE         DEFAULT NULL,
    p_to_date       DATE         DEFAULT NULL,
    p_solo_abiertas BOOLEAN      DEFAULT FALSE,
    p_offset        INT          DEFAULT 0,
    p_limit         INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "nomina" VARCHAR, "cedula" VARCHAR, "nombreEmpleado" VARCHAR,
    "cargo" VARCHAR, "fechaProceso" DATE, "fechaInicio" DATE, "fechaHasta" DATE,
    "totalAsignaciones" NUMERIC, "totalDeducciones" NUMERIC, "totalNeto" NUMERIC,
    "cerrada" BOOLEAN, "tipoNomina" VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollRun"
    WHERE "CompanyId" = p_company_id
      AND (p_payroll_code IS NULL OR "PayrollCode" = p_payroll_code)
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code)
      AND (p_from_date IS NULL OR "DateFrom" >= p_from_date)
      AND (p_to_date IS NULL OR "DateTo" <= p_to_date)
      AND (NOT p_solo_abiertas OR "IsClosed" = FALSE);

    RETURN QUERY
    SELECT
        v_total,
        pr."PayrollCode", pr."EmployeeCode", pr."EmployeeName",
        pr."PositionName", pr."ProcessDate", pr."DateFrom", pr."DateTo",
        pr."TotalAssignments", pr."TotalDeductions", pr."NetTotal",
        pr."IsClosed", pr."PayrollTypeName"
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId" = p_company_id
      AND (p_payroll_code IS NULL OR pr."PayrollCode" = p_payroll_code)
      AND (p_employee_code IS NULL OR pr."EmployeeCode" = p_employee_code)
      AND (p_from_date IS NULL OR pr."DateFrom" >= p_from_date)
      AND (p_to_date IS NULL OR pr."DateTo" <= p_to_date)
      AND (NOT p_solo_abiertas OR pr."IsClosed" = FALSE)
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_closerun
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_closerun(INT, VARCHAR(15), VARCHAR(24), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_closerun(
    p_company_id    INT,
    p_payroll_code  VARCHAR(15),
    p_employee_code VARCHAR(24) DEFAULT NULL,
    p_user_id       INT         DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_affected INT;
BEGIN
    UPDATE hr."PayrollRun"
    SET "IsClosed"        = TRUE,
        "ClosedAt"        = NOW() AT TIME ZONE 'UTC',
        "ClosedByUserId"  = p_user_id,
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "CompanyId"   = p_company_id
      AND "PayrollCode" = p_payroll_code
      AND "IsClosed"    = FALSE
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code);

    GET DIAGNOSTICS v_affected = ROW_COUNT;

    IF v_affected > 0 THEN
        RETURN QUERY SELECT v_affected, 'Nomina cerrada'::TEXT;
    ELSE
        RETURN QUERY SELECT 0, 'No se encontraron registros abiertos'::TEXT;
    END IF;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_upsertvacation
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_upsertvacation(INT, INT, VARCHAR(60), BIGINT, VARCHAR(24), VARCHAR(200), DATE, DATE, DATE, NUMERIC(18,2), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_upsertvacation(
    p_company_id        INT,
    p_branch_id         INT,
    p_vacation_code     VARCHAR(60),
    p_employee_id       BIGINT,
    p_employee_code     VARCHAR(24),
    p_employee_name     VARCHAR(200),
    p_start_date        DATE,
    p_end_date          DATE,
    p_reintegration_date DATE DEFAULT NULL,
    p_total_amount      NUMERIC(18,2) DEFAULT 0,
    p_user_id           INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_vacation_id BIGINT;
BEGIN
    SELECT "VacationProcessId" INTO v_vacation_id
    FROM hr."VacationProcess"
    WHERE "CompanyId" = p_company_id AND "VacationCode" = p_vacation_code
    LIMIT 1;

    IF v_vacation_id IS NOT NULL THEN
        UPDATE hr."VacationProcess"
        SET "EmployeeId"         = p_employee_id,
            "EmployeeCode"       = p_employee_code,
            "EmployeeName"       = p_employee_name,
            "StartDate"          = p_start_date,
            "EndDate"            = p_end_date,
            "ReintegrationDate"  = p_reintegration_date,
            "ProcessDate"        = (NOW() AT TIME ZONE 'UTC')::DATE,
            "TotalAmount"        = p_total_amount,
            "CalculatedAmount"   = p_total_amount,
            "UpdatedAt"          = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId"    = p_user_id
        WHERE "VacationProcessId" = v_vacation_id;
    ELSE
        INSERT INTO hr."VacationProcess" (
            "CompanyId", "BranchId", "VacationCode", "EmployeeId", "EmployeeCode",
            "EmployeeName", "StartDate", "EndDate", "ReintegrationDate",
            "ProcessDate", "TotalAmount", "CalculatedAmount",
            "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_vacation_code, p_employee_id, p_employee_code,
            p_employee_name, p_start_date, p_end_date, p_reintegration_date,
            (NOW() AT TIME ZONE 'UTC')::DATE, p_total_amount, p_total_amount,
            p_user_id, p_user_id
        )
        RETURNING "VacationProcessId" INTO v_vacation_id;
    END IF;

    DELETE FROM hr."VacationProcessLine" WHERE "VacationProcessId" = v_vacation_id;

    INSERT INTO hr."VacationProcessLine" ("VacationProcessId", "ConceptCode", "ConceptName", "Amount")
    VALUES (v_vacation_id, 'VACACIONES', 'Pago de vacaciones', p_total_amount);

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listvacations
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_listvacations(INT, VARCHAR(24), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listvacations(
    p_company_id    INT,
    p_employee_code VARCHAR(24) DEFAULT NULL,
    p_offset        INT         DEFAULT 0,
    p_limit         INT         DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "vacacion" VARCHAR, "cedula" VARCHAR, "nombreEmpleado" VARCHAR,
    "inicio" DATE, "hasta" DATE, "reintegro" DATE,
    "fechaCalculo" DATE, "total" NUMERIC, "totalCalculado" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."VacationProcess"
    WHERE "CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code);

    RETURN QUERY
    SELECT
        v_total,
        vp."VacationCode", vp."EmployeeCode", vp."EmployeeName",
        vp."StartDate", vp."EndDate", vp."ReintegrationDate",
        vp."ProcessDate", vp."TotalAmount", vp."CalculatedAmount"
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR vp."EmployeeCode" = p_employee_code)
    ORDER BY vp."VacationProcessId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_upsertsettlement
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_upsertsettlement(INT, INT, VARCHAR(60), BIGINT, VARCHAR(24), VARCHAR(200), DATE, VARCHAR(120), NUMERIC(18,2), NUMERIC(18,2), NUMERIC(18,2), NUMERIC(18,2), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_upsertsettlement(
    p_company_id       INT,
    p_branch_id        INT,
    p_settlement_code  VARCHAR(60),
    p_employee_id      BIGINT,
    p_employee_code    VARCHAR(24),
    p_employee_name    VARCHAR(200),
    p_retirement_date  DATE,
    p_retirement_cause VARCHAR(120) DEFAULT NULL,
    p_total_amount     NUMERIC(18,2) DEFAULT 0,
    p_prestaciones     NUMERIC(18,2) DEFAULT 0,
    p_vac_pendientes   NUMERIC(18,2) DEFAULT 0,
    p_bono_salida      NUMERIC(18,2) DEFAULT 0,
    p_user_id          INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_settlement_id BIGINT;
BEGIN
    SELECT "SettlementProcessId" INTO v_settlement_id
    FROM hr."SettlementProcess"
    WHERE "CompanyId" = p_company_id AND "SettlementCode" = p_settlement_code
    LIMIT 1;

    IF v_settlement_id IS NOT NULL THEN
        UPDATE hr."SettlementProcess"
        SET "EmployeeId"      = p_employee_id,
            "EmployeeCode"    = p_employee_code,
            "EmployeeName"    = p_employee_name,
            "RetirementDate"  = p_retirement_date,
            "RetirementCause" = p_retirement_cause,
            "TotalAmount"     = p_total_amount,
            "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "SettlementProcessId" = v_settlement_id;
    ELSE
        INSERT INTO hr."SettlementProcess" (
            "CompanyId", "BranchId", "SettlementCode", "EmployeeId", "EmployeeCode",
            "EmployeeName", "RetirementDate", "RetirementCause", "TotalAmount",
            "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_settlement_code, p_employee_id, p_employee_code,
            p_employee_name, p_retirement_date, p_retirement_cause, p_total_amount,
            p_user_id, p_user_id
        )
        RETURNING "SettlementProcessId" INTO v_settlement_id;
    END IF;

    DELETE FROM hr."SettlementProcessLine" WHERE "SettlementProcessId" = v_settlement_id;

    INSERT INTO hr."SettlementProcessLine" ("SettlementProcessId", "ConceptCode", "ConceptName", "Amount")
    VALUES
        (v_settlement_id, 'PRESTACIONES', 'Prestaciones sociales', p_prestaciones),
        (v_settlement_id, 'VACACIONES_PEND', 'Vacaciones pendientes', p_vac_pendientes),
        (v_settlement_id, 'BONO_SALIDA', 'Bono de salida', p_bono_salida);

    RETURN QUERY SELECT 1, 'ok'::TEXT;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listsettlements
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_listsettlements(INT, VARCHAR(24), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listsettlements(
    p_company_id    INT,
    p_employee_code VARCHAR(24) DEFAULT NULL,
    p_offset        INT         DEFAULT 0,
    p_limit         INT         DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "liquidacion" VARCHAR, "cedula" VARCHAR, "nombreEmpleado" VARCHAR,
    "fechaRetiro" DATE, "causaRetiro" VARCHAR, "total" NUMERIC
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."SettlementProcess"
    WHERE "CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR "EmployeeCode" = p_employee_code);

    RETURN QUERY
    SELECT
        v_total,
        sp."SettlementCode", sp."EmployeeCode", sp."EmployeeName",
        sp."RetirementDate", sp."RetirementCause", sp."TotalAmount"
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = p_company_id
      AND (p_employee_code IS NULL OR sp."EmployeeCode" = p_employee_code)
    ORDER BY sp."SettlementProcessId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_listconstants
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_listconstants(INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_listconstants(
    p_company_id INT,
    p_offset     INT DEFAULT 0,
    p_limit      INT DEFAULT 50
)
RETURNS TABLE(
    "TotalCount" BIGINT,
    "codigo" VARCHAR, "nombre" VARCHAR, "valor" NUMERIC,
    "origen" VARCHAR, "activo" BOOLEAN
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM hr."PayrollConstant"
    WHERE "CompanyId" = p_company_id;

    RETURN QUERY
    SELECT
        v_total,
        pc."ConstantCode", pc."ConstantName", pc."ConstantValue",
        pc."SourceName", pc."IsActive"
    FROM hr."PayrollConstant" pc
    WHERE pc."CompanyId" = p_company_id
    ORDER BY pc."ConstantCode"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_saveconstant
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_saveconstant(INT, VARCHAR(60), VARCHAR(200), NUMERIC(18,4), VARCHAR(120), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_saveconstant(
    p_company_id  INT,
    p_code        VARCHAR(60),
    p_name        VARCHAR(200)   DEFAULT NULL,
    p_value       NUMERIC(18,4)  DEFAULT NULL,
    p_source_name VARCHAR(120)   DEFAULT NULL,
    p_user_id     INT            DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_existing_id BIGINT;
BEGIN
    SELECT "PayrollConstantId" INTO v_existing_id
    FROM hr."PayrollConstant"
    WHERE "CompanyId" = p_company_id AND "ConstantCode" = p_code
    LIMIT 1;

    IF v_existing_id IS NOT NULL THEN
        UPDATE hr."PayrollConstant"
        SET "ConstantName"  = COALESCE(p_name, "ConstantName"),
            "ConstantValue" = COALESCE(p_value, "ConstantValue"),
            "SourceName"    = COALESCE(p_source_name, "SourceName"),
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "PayrollConstantId" = v_existing_id;
    ELSE
        INSERT INTO hr."PayrollConstant" (
            "CompanyId", "ConstantCode", "ConstantName", "ConstantValue",
            "SourceName", "IsActive", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_code, COALESCE(p_name, p_code), COALESCE(p_value, 0),
            p_source_name, TRUE, p_user_id, p_user_id
        );
    END IF;

    RETURN QUERY SELECT 1, 'Constante guardada'::TEXT;
END;
$$;


-- =============================================================================
--  SECCION 6: CONCEPTOS LEGALES DE NOMINA
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_hr_legalconcept_list
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_legalconcept_list(INT, VARCHAR(30), VARCHAR(30), VARCHAR(15), BOOLEAN) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_legalconcept_list(
    p_company_id       INT,
    p_convention_code  VARCHAR(30)  DEFAULT NULL,
    p_calculation_type VARCHAR(30)  DEFAULT NULL,
    p_concept_type     VARCHAR(15)  DEFAULT NULL,
    p_solo_activos     BOOLEAN      DEFAULT TRUE
)
RETURNS TABLE(
    "id" BIGINT, "convencion" VARCHAR, "tipoCalculo" VARCHAR,
    "coConcept" VARCHAR, "nbConcepto" VARCHAR, "formula" VARCHAR,
    "sobre" VARCHAR, "tipo" VARCHAR, "bonificable" VARCHAR,
    "lotttArticulo" VARCHAR, "ccpClausula" VARCHAR,
    "orden" INT, "activo" BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc."PayrollConceptId", pc."ConventionCode", pc."CalculationType",
        pc."ConceptCode", pc."ConceptName", pc."Formula",
        pc."BaseExpression", pc."ConceptType",
        CASE WHEN pc."IsBonifiable" THEN 'S' ELSE 'N' END,
        pc."LotttArticle", pc."CcpClause",
        pc."SortOrder", pc."IsActive"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."ConventionCode" IS NOT NULL
      AND (NOT p_solo_activos OR pc."IsActive" = TRUE)
      AND (p_convention_code IS NULL OR pc."ConventionCode" = p_convention_code)
      AND (p_calculation_type IS NULL OR pc."CalculationType" = p_calculation_type)
      AND (p_concept_type IS NULL OR pc."ConceptType" = p_concept_type)
    ORDER BY pc."ConventionCode", pc."CalculationType", pc."SortOrder", pc."ConceptCode";
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_legalconcept_validateformulas
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_legalconcept_validateformulas(INT, VARCHAR(30), VARCHAR(30)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_legalconcept_validateformulas(
    p_company_id       INT,
    p_convention_code  VARCHAR(30) DEFAULT NULL,
    p_calculation_type VARCHAR(30) DEFAULT NULL
)
RETURNS TABLE("coConcept" VARCHAR, "nbConcepto" VARCHAR, "formula" VARCHAR, "defaultValue" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc."ConceptCode", pc."ConceptName", pc."Formula", pc."DefaultValue"
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."ConventionCode" IS NOT NULL
      AND pc."IsActive" = TRUE
      AND (p_convention_code IS NULL OR pc."ConventionCode" = p_convention_code)
      AND (p_calculation_type IS NULL OR pc."CalculationType" = p_calculation_type)
    ORDER BY pc."SortOrder", pc."ConceptCode";
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_legalconcept_listconventions
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_legalconcept_listconventions(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_legalconcept_listconventions(
    p_company_id INT
)
RETURNS TABLE(
    "Convencion" VARCHAR, "TotalConceptos" BIGINT,
    "ConceptosMensual" BIGINT, "ConceptosVacaciones" BIGINT,
    "ConceptosLiquidacion" BIGINT, "OrdenInicio" INT, "OrdenFin" INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc."ConventionCode",
        COUNT(1),
        COUNT(CASE WHEN pc."CalculationType" = 'MENSUAL' THEN 1 END),
        COUNT(CASE WHEN pc."CalculationType" = 'VACACIONES' THEN 1 END),
        COUNT(CASE WHEN pc."CalculationType" = 'LIQUIDACION' THEN 1 END),
        MIN(pc."SortOrder"),
        MAX(pc."SortOrder")
    FROM hr."PayrollConcept" pc
    WHERE pc."CompanyId" = p_company_id
      AND pc."IsActive" = TRUE
      AND pc."ConventionCode" IS NOT NULL
    GROUP BY pc."ConventionCode"
    ORDER BY pc."ConventionCode";
END;
$$;


-- =============================================================================
--  SECCION 7: SPs auxiliares para detalle (recordset unico)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getrunheader
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_getrunheader(INT, VARCHAR(15), VARCHAR(24)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getrunheader(
    p_company_id    INT,
    p_payroll_code  VARCHAR(15),
    p_employee_code VARCHAR(24)
)
RETURNS TABLE(
    "runId" BIGINT, "nomina" VARCHAR, "cedula" VARCHAR,
    "nombreEmpleado" VARCHAR, "cargo" VARCHAR, "fechaProceso" DATE,
    "fechaInicio" DATE, "fechaHasta" DATE,
    "totalAsignaciones" NUMERIC, "totalDeducciones" NUMERIC, "totalNeto" NUMERIC,
    "cerrada" BOOLEAN, "tipoNomina" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pr."PayrollRunId", pr."PayrollCode", pr."EmployeeCode",
        pr."EmployeeName", pr."PositionName", pr."ProcessDate",
        pr."DateFrom", pr."DateTo",
        pr."TotalAssignments", pr."TotalDeductions", pr."NetTotal",
        pr."IsClosed", pr."PayrollTypeName"
    FROM hr."PayrollRun" pr
    WHERE pr."CompanyId"    = p_company_id
      AND pr."PayrollCode"  = p_payroll_code
      AND pr."EmployeeCode" = p_employee_code
    ORDER BY pr."ProcessDate" DESC, pr."PayrollRunId" DESC
    LIMIT 1;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getrunlines
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_getrunlines(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getrunlines(p_run_id BIGINT)
RETURNS TABLE(
    "coConcepto" VARCHAR, "nombreConcepto" VARCHAR, "tipoConcepto" VARCHAR,
    "cantidad" NUMERIC, "monto" NUMERIC, "total" NUMERIC,
    "descripcion" TEXT, "cuentaContable" VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        rl."ConceptCode", rl."ConceptName", rl."ConceptType",
        rl."Quantity", rl."Amount", rl."Total",
        rl."DescriptionText", rl."AccountingAccountCode"
    FROM hr."PayrollRunLine" rl
    WHERE rl."PayrollRunId" = p_run_id
    ORDER BY rl."PayrollRunLineId";
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getvacationheader
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_getvacationheader(INT, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getvacationheader(
    p_company_id   INT,
    p_vacation_code VARCHAR(60)
)
RETURNS TABLE(
    "id" BIGINT, "vacacion" VARCHAR, "cedula" VARCHAR,
    "nombreEmpleado" VARCHAR, "inicio" DATE, "hasta" DATE,
    "reintegro" DATE, "fechaCalculo" DATE,
    "total" NUMERIC, "totalCalculado" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        vp."VacationProcessId", vp."VacationCode", vp."EmployeeCode",
        vp."EmployeeName", vp."StartDate", vp."EndDate",
        vp."ReintegrationDate", vp."ProcessDate",
        vp."TotalAmount", vp."CalculatedAmount"
    FROM hr."VacationProcess" vp
    WHERE vp."CompanyId" = p_company_id AND vp."VacationCode" = p_vacation_code
    LIMIT 1;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getvacationlines
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_getvacationlines(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getvacationlines(p_vacation_process_id BIGINT)
RETURNS TABLE("codigo" VARCHAR, "nombre" VARCHAR, "monto" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT vl."ConceptCode", vl."ConceptName", vl."Amount"
    FROM hr."VacationProcessLine" vl
    WHERE vl."VacationProcessId" = p_vacation_process_id
    ORDER BY vl."VacationProcessLineId";
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getsettlementheader
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_getsettlementheader(INT, VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getsettlementheader(
    p_company_id      INT,
    p_settlement_code VARCHAR(60)
)
RETURNS TABLE("id" BIGINT, "total" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT sp."SettlementProcessId", sp."TotalAmount"
    FROM hr."SettlementProcess" sp
    WHERE sp."CompanyId" = p_company_id AND sp."SettlementCode" = p_settlement_code
    LIMIT 1;
END;
$$;

-- -----------------------------------------------------------------------------
--  usp_hr_payroll_getsettlementlines
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS usp_hr_payroll_getsettlementlines(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_hr_payroll_getsettlementlines(p_settlement_process_id BIGINT)
RETURNS TABLE("codigo" VARCHAR, "nombre" VARCHAR, "monto" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT sl."ConceptCode", sl."ConceptName", sl."Amount"
    FROM hr."SettlementProcessLine" sl
    WHERE sl."SettlementProcessId" = p_settlement_process_id
    ORDER BY sl."SettlementProcessLineId";
END;
$$;
