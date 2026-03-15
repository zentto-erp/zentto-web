-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_ar.sql
-- Funciones de Cuentas por Cobrar (Accounts Receivable)
-- Tablas: ar.ReceivableDocument, ar.ReceivableApplication
-- 8 funciones: List, Get, Apply, Reverse, ListByContext,
--              GetByContext, Resolve, Update
-- ============================================================

-- =============================================================================
-- 1. usp_AR_Application_List
-- Listado paginado de aplicaciones (abonos/cobros) recibidos.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_ar_application_list(
    p_customer_id   BIGINT        DEFAULT NULL,
    p_document_type VARCHAR(20)   DEFAULT NULL,
    p_from_date     DATE          DEFAULT NULL,
    p_to_date       DATE          DEFAULT NULL,
    p_page          INT           DEFAULT 1,
    p_limit         INT           DEFAULT 50
)
RETURNS TABLE(
    "ReceivableApplicationId" BIGINT,
    "ReceivableDocumentId"    BIGINT,
    "ApplyDate"               DATE,
    "AppliedAmount"           NUMERIC,
    "PaymentReference"        VARCHAR,
    "CreatedAt"               TIMESTAMP,
    "DocumentNumber"          VARCHAR,
    "DocumentType"            VARCHAR,
    "TotalAmount"             NUMERIC,
    "PendingAmount"           NUMERIC,
    "DocumentStatus"          VARCHAR,
    "CustomerId"              BIGINT,
    "CustomerCode"            VARCHAR,
    "CustomerName"            VARCHAR,
    "TotalCount"              BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total  BIGINT;
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := LEAST(GREATEST(p_limit, 1), 500);
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM ar."ReceivableApplication" a
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
    WHERE (p_customer_id   IS NULL OR d."CustomerId"   = p_customer_id)
      AND (p_document_type IS NULL OR d."DocumentType" = p_document_type)
      AND (p_from_date     IS NULL OR a."ApplyDate"   >= p_from_date)
      AND (p_to_date       IS NULL OR a."ApplyDate"   <= p_to_date);

    RETURN QUERY
    SELECT
        a."ReceivableApplicationId",
        a."ReceivableDocumentId",
        a."ApplyDate",
        a."AppliedAmount",
        a."PaymentReference"::VARCHAR,
        a."CreatedAt",
        d."DocumentNumber"::VARCHAR,
        d."DocumentType"::VARCHAR,
        d."TotalAmount",
        d."PendingAmount",
        d."Status"::VARCHAR        AS "DocumentStatus",
        c."CustomerId",
        c."CustomerCode"::VARCHAR,
        c."CustomerName"::VARCHAR,
        v_total
    FROM ar."ReceivableApplication" a
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"
    WHERE (p_customer_id   IS NULL OR d."CustomerId"   = p_customer_id)
      AND (p_document_type IS NULL OR d."DocumentType" = p_document_type)
      AND (p_from_date     IS NULL OR a."ApplyDate"   >= p_from_date)
      AND (p_to_date       IS NULL OR a."ApplyDate"   <= p_to_date)
    ORDER BY a."ApplyDate" DESC, a."ReceivableApplicationId" DESC
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$$;

-- =============================================================================
-- 2. usp_AR_Application_Get
-- Detalle de una aplicacion (abono) especifica.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_ar_application_get(
    p_application_id BIGINT
)
RETURNS TABLE(
    "ReceivableApplicationId" BIGINT,
    "ReceivableDocumentId"    BIGINT,
    "ApplyDate"               DATE,
    "AppliedAmount"           NUMERIC,
    "PaymentReference"        VARCHAR,
    "CreatedAt"               TIMESTAMP,
    "DocumentNumber"          VARCHAR,
    "DocumentType"            VARCHAR,
    "IssueDate"               TIMESTAMP,
    "DueDate"                 TIMESTAMP,
    "CurrencyCode"            VARCHAR,
    "TotalAmount"             NUMERIC,
    "PendingAmount"           NUMERIC,
    "PaidFlag"                BOOLEAN,
    "DocumentStatus"          VARCHAR,
    "DocumentNotes"           TEXT,
    "CustomerId"              BIGINT,
    "CustomerCode"            VARCHAR,
    "CustomerName"            VARCHAR,
    "CustomerFiscalId"        VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        a."ReceivableApplicationId",
        a."ReceivableDocumentId",
        a."ApplyDate",
        a."AppliedAmount",
        a."PaymentReference"::VARCHAR,
        a."CreatedAt",
        d."DocumentNumber"::VARCHAR,
        d."DocumentType"::VARCHAR,
        d."IssueDate",
        d."DueDate",
        d."CurrencyCode"::VARCHAR,
        d."TotalAmount",
        d."PendingAmount",
        d."PaidFlag",
        d."Status"::VARCHAR        AS "DocumentStatus",
        d."Notes"::TEXT            AS "DocumentNotes",
        c."CustomerId",
        c."CustomerCode"::VARCHAR,
        c."CustomerName"::VARCHAR,
        c."FiscalId"::VARCHAR      AS "CustomerFiscalId"
    FROM ar."ReceivableApplication" a
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"
    WHERE a."ReceivableApplicationId" = p_application_id;
END;
$$;

-- =============================================================================
-- 3. usp_AR_Application_Apply
-- Aplicar un cobro (abono) a un documento por cobrar. Transaccional.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_ar_application_apply(
    p_receivable_document_id BIGINT,
    p_amount                 NUMERIC(18,2),
    p_payment_reference      VARCHAR(120)  DEFAULT NULL,
    p_apply_date             DATE          DEFAULT NULL,
    p_updated_by_user_id     INT           DEFAULT NULL
)
RETURNS TABLE("ok" INT, "ApplicationId" BIGINT, "NewPending" NUMERIC, "Message" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_current_pending NUMERIC(18,2);
    v_new_pending     NUMERIC(18,2);
    v_customer_id     BIGINT;
    v_total_amount    NUMERIC(18,2);
    v_application_id  BIGINT;
    v_doc_status      VARCHAR(20);
    v_apply_date      DATE := COALESCE(p_apply_date, (NOW() AT TIME ZONE 'UTC')::DATE);
BEGIN
    -- Validaciones basicas
    IF p_amount IS NULL OR p_amount <= 0 THEN
        RETURN QUERY SELECT 0, NULL::BIGINT, NULL::NUMERIC, 'El monto debe ser mayor a cero.'::TEXT;
        RETURN;
    END IF;

    -- Obtener documento con bloqueo
    SELECT d."PendingAmount", d."TotalAmount", d."CustomerId", d."Status"
    INTO v_current_pending, v_total_amount, v_customer_id, v_doc_status
    FROM ar."ReceivableDocument" d
    WHERE d."ReceivableDocumentId" = p_receivable_document_id
    FOR UPDATE;

    IF v_current_pending IS NULL THEN
        RETURN QUERY SELECT 0, NULL::BIGINT, NULL::NUMERIC, 'Documento por cobrar no encontrado.'::TEXT;
        RETURN;
    END IF;

    IF v_doc_status = 'VOIDED' THEN
        RETURN QUERY SELECT 0, NULL::BIGINT, NULL::NUMERIC, 'No se puede aplicar abono a un documento anulado.'::TEXT;
        RETURN;
    END IF;

    IF p_amount > v_current_pending THEN
        RETURN QUERY SELECT 0, NULL::BIGINT, v_current_pending,
            ('El monto (' || p_amount::TEXT || ') excede el saldo pendiente (' || v_current_pending::TEXT || ').')::TEXT;
        RETURN;
    END IF;

    -- Insertar la aplicacion
    INSERT INTO ar."ReceivableApplication" ("ReceivableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference")
    VALUES (p_receivable_document_id, v_apply_date, p_amount, p_payment_reference)
    RETURNING "ReceivableApplicationId" INTO v_application_id;

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
    WHERE "ReceivableDocumentId" = p_receivable_document_id;

    -- Recalcular saldo total del cliente
    PERFORM usp_master_customer_updatebalance(v_customer_id, p_updated_by_user_id);

    RETURN QUERY SELECT 1, v_application_id, v_new_pending, 'Abono aplicado correctamente.'::TEXT;
END;
$$;

-- =============================================================================
-- 4. usp_AR_Application_Reverse
-- Reversar (eliminar) una aplicacion de cobro. Transaccional.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_ar_application_reverse(
    p_application_id    BIGINT,
    p_updated_by_user_id INT DEFAULT NULL
)
RETURNS TABLE("ok" INT, "NewPending" NUMERIC, "Message" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_applied_amount         NUMERIC(18,2);
    v_receivable_document_id BIGINT;
    v_customer_id            BIGINT;
    v_total_amount           NUMERIC(18,2);
    v_new_pending            NUMERIC(18,2);
BEGIN
    -- Obtener datos de la aplicacion con bloqueo
    SELECT a."AppliedAmount", a."ReceivableDocumentId"
    INTO v_applied_amount, v_receivable_document_id
    FROM ar."ReceivableApplication" a
    WHERE a."ReceivableApplicationId" = p_application_id
    FOR UPDATE;

    IF v_applied_amount IS NULL THEN
        RETURN QUERY SELECT 0, NULL::NUMERIC, 'Aplicacion de cobro no encontrada.'::TEXT;
        RETURN;
    END IF;

    -- Obtener datos del documento
    SELECT d."CustomerId", d."TotalAmount"
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
                              WHEN v_new_pending <= 0            THEN 'PAID'
                              WHEN v_new_pending < v_total_amount THEN 'PARTIAL'
                              ELSE 'PENDING'
                            END,
        "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_updated_by_user_id
    WHERE "ReceivableDocumentId" = v_receivable_document_id;

    PERFORM usp_master_customer_updatebalance(v_customer_id, p_updated_by_user_id);

    RETURN QUERY SELECT 1, v_new_pending, 'Abono reversado correctamente.'::TEXT;
END;
$$;

-- =============================================================================
-- 5. usp_AR_Application_ListByContext
-- Listado paginado por contexto (Company/Branch).
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_ar_application_listbycontext(
    p_company_id    INT,
    p_branch_id     INT,
    p_search        VARCHAR(100)  DEFAULT NULL,
    p_codigo        VARCHAR(60)   DEFAULT NULL,
    p_currency_code VARCHAR(10)   DEFAULT NULL,
    p_page          INT           DEFAULT 1,
    p_limit         INT           DEFAULT 50
)
RETURNS TABLE(
    "Id"            BIGINT,
    "ApplicationId" BIGINT,
    "DocumentoId"   BIGINT,
    "CODIGO"        VARCHAR,
    "Codigo"        VARCHAR,
    "NOMBRE"        VARCHAR,
    "TIPO_DOC"      VARCHAR,
    "TipoDoc"       VARCHAR,
    "DOCUMENTO"     VARCHAR,
    "Num_fact"      VARCHAR,
    "FECHA"         DATE,
    "Fecha"         DATE,
    "MONTO"         NUMERIC,
    "Monto"         NUMERIC,
    "MONEDA"        VARCHAR,
    "REFERENCIA"    VARCHAR,
    "Concepto"      VARCHAR,
    "PENDIENTE"     NUMERIC,
    "TOTAL"         NUMERIC,
    "ESTADO_DOC"    VARCHAR,
    "TotalCount"    BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_total          BIGINT;
    v_page           INT := GREATEST(p_page, 1);
    v_limit          INT := LEAST(GREATEST(p_limit, 1), 500);
    v_search_pattern VARCHAR(102);
BEGIN
    IF p_search IS NOT NULL AND LENGTH(TRIM(p_search)) > 0 THEN
        v_search_pattern := '%' || TRIM(p_search) || '%';
    END IF;

    SELECT COUNT(*) INTO v_total
    FROM ar."ReceivableApplication" a
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"
    WHERE d."CompanyId" = p_company_id
      AND d."BranchId"  = p_branch_id
      AND (v_search_pattern IS NULL
           OR d."DocumentNumber"    LIKE v_search_pattern
           OR c."CustomerName"      LIKE v_search_pattern
           OR a."PaymentReference"  LIKE v_search_pattern)
      AND (p_codigo       IS NULL OR c."CustomerCode" = p_codigo)
      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code);

    RETURN QUERY
    SELECT
        a."ReceivableApplicationId"   AS "Id",
        a."ReceivableApplicationId"   AS "ApplicationId",
        d."ReceivableDocumentId"      AS "DocumentoId",
        c."CustomerCode"::VARCHAR     AS "CODIGO",
        c."CustomerCode"::VARCHAR     AS "Codigo",
        c."CustomerName"::VARCHAR     AS "NOMBRE",
        d."DocumentType"::VARCHAR     AS "TIPO_DOC",
        d."DocumentType"::VARCHAR     AS "TipoDoc",
        d."DocumentNumber"::VARCHAR   AS "DOCUMENTO",
        d."DocumentNumber"::VARCHAR   AS "Num_fact",
        a."ApplyDate"                 AS "FECHA",
        a."ApplyDate"                 AS "Fecha",
        a."AppliedAmount"             AS "MONTO",
        a."AppliedAmount"             AS "Monto",
        d."CurrencyCode"::VARCHAR     AS "MONEDA",
        a."PaymentReference"::VARCHAR AS "REFERENCIA",
        a."PaymentReference"::VARCHAR AS "Concepto",
        d."PendingAmount"             AS "PENDIENTE",
        d."TotalAmount"               AS "TOTAL",
        d."Status"::VARCHAR           AS "ESTADO_DOC",
        v_total
    FROM ar."ReceivableApplication" a
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"
    WHERE d."CompanyId" = p_company_id
      AND d."BranchId"  = p_branch_id
      AND (v_search_pattern IS NULL
           OR d."DocumentNumber"    LIKE v_search_pattern
           OR c."CustomerName"      LIKE v_search_pattern
           OR a."PaymentReference"  LIKE v_search_pattern)
      AND (p_codigo       IS NULL OR c."CustomerCode" = p_codigo)
      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code)
    ORDER BY a."ApplyDate" DESC, a."ReceivableApplicationId" DESC
    LIMIT v_limit OFFSET (v_page - 1) * v_limit;
END;
$$;

-- =============================================================================
-- 6. usp_AR_Application_GetByContext
-- Obtiene una aplicacion por Id, validando Company/Branch.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_ar_application_getbycontext(
    p_application_id BIGINT,
    p_company_id     INT,
    p_branch_id      INT,
    p_currency_code  VARCHAR(10) DEFAULT NULL
)
RETURNS TABLE(
    "Id"            BIGINT,
    "ApplicationId" BIGINT,
    "DocumentoId"   BIGINT,
    "CODIGO"        VARCHAR,
    "Codigo"        VARCHAR,
    "NOMBRE"        VARCHAR,
    "TIPO_DOC"      VARCHAR,
    "TipoDoc"       VARCHAR,
    "DOCUMENTO"     VARCHAR,
    "Num_fact"      VARCHAR,
    "FECHA"         DATE,
    "Fecha"         DATE,
    "MONTO"         NUMERIC,
    "Monto"         NUMERIC,
    "MONEDA"        VARCHAR,
    "REFERENCIA"    VARCHAR,
    "Concepto"      VARCHAR,
    "PENDIENTE"     NUMERIC,
    "TOTAL"         NUMERIC,
    "ESTADO_DOC"    VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        a."ReceivableApplicationId"   AS "Id",
        a."ReceivableApplicationId"   AS "ApplicationId",
        d."ReceivableDocumentId"      AS "DocumentoId",
        c."CustomerCode"::VARCHAR     AS "CODIGO",
        c."CustomerCode"::VARCHAR     AS "Codigo",
        c."CustomerName"::VARCHAR     AS "NOMBRE",
        d."DocumentType"::VARCHAR     AS "TIPO_DOC",
        d."DocumentType"::VARCHAR     AS "TipoDoc",
        d."DocumentNumber"::VARCHAR   AS "DOCUMENTO",
        d."DocumentNumber"::VARCHAR   AS "Num_fact",
        a."ApplyDate"                 AS "FECHA",
        a."ApplyDate"                 AS "Fecha",
        a."AppliedAmount"             AS "MONTO",
        a."AppliedAmount"             AS "Monto",
        d."CurrencyCode"::VARCHAR     AS "MONEDA",
        a."PaymentReference"::VARCHAR AS "REFERENCIA",
        a."PaymentReference"::VARCHAR AS "Concepto",
        d."PendingAmount"             AS "PENDIENTE",
        d."TotalAmount"               AS "TOTAL",
        d."Status"::VARCHAR           AS "ESTADO_DOC"
    FROM ar."ReceivableApplication" a
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"
    WHERE a."ReceivableApplicationId" = p_application_id
      AND d."CompanyId"  = p_company_id
      AND d."BranchId"   = p_branch_id
      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code)
    LIMIT 1;
END;
$$;

-- =============================================================================
-- 7. usp_AR_Application_Resolve
-- Resuelve un documento por cobrar a partir de DocumentNumber.
-- Usa FOR UPDATE para seguridad transaccional.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_ar_application_resolve(
    p_company_id      INT,
    p_branch_id       INT,
    p_document_number VARCHAR(120),
    p_customer_code   VARCHAR(24)  DEFAULT NULL,
    p_document_type   VARCHAR(20)  DEFAULT NULL
)
RETURNS TABLE(
    "ReceivableDocumentId" BIGINT,
    "PendingAmount"        NUMERIC,
    "TotalAmount"          NUMERIC,
    "CustomerId"           BIGINT,
    "CurrencyCode"         VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."ReceivableDocumentId",
        d."PendingAmount",
        d."TotalAmount",
        d."CustomerId",
        d."CurrencyCode"::VARCHAR
    FROM ar."ReceivableDocument" d
    INNER JOIN master."Customer" c ON c."CustomerId" = d."CustomerId"
    WHERE d."CompanyId"      = p_company_id
      AND d."BranchId"       = p_branch_id
      AND d."DocumentNumber" = p_document_number
      AND (p_customer_code IS NULL OR c."CustomerCode" = p_customer_code)
      AND (p_document_type IS NULL OR d."DocumentType" = p_document_type)
    ORDER BY d."ReceivableDocumentId" DESC
    LIMIT 1
    FOR UPDATE OF d;
END;
$$;

-- =============================================================================
-- 8. usp_AR_Application_Update
-- Actualiza una aplicacion (abono) existente. Transaccional.
-- =============================================================================
CREATE OR REPLACE FUNCTION usp_ar_application_update(
    p_application_id    BIGINT,
    p_amount            NUMERIC(18,2) DEFAULT NULL,
    p_apply_date        DATE          DEFAULT NULL,
    p_payment_reference VARCHAR(120)  DEFAULT NULL,
    p_currency_code     VARCHAR(10)   DEFAULT NULL
)
RETURNS TABLE("ok" INT, "Message" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_current_amount NUMERIC(18,2);
    v_doc_id         BIGINT;
    v_pending        NUMERIC(18,2);
    v_total_amount   NUMERIC(18,2);
    v_customer_id    BIGINT;
    v_doc_currency   VARCHAR(10);
    v_delta          NUMERIC(18,2);
    v_new_pending    NUMERIC(18,2);
    v_new_status     VARCHAR(20);
    v_new_paid_flag  BOOLEAN;
    v_amount         NUMERIC(18,2);
BEGIN
    -- Obtener aplicacion y documento con bloqueo
    SELECT a."AppliedAmount", a."ReceivableDocumentId",
           d."PendingAmount", d."TotalAmount", d."CustomerId", d."CurrencyCode"
    INTO v_current_amount, v_doc_id, v_pending, v_total_amount, v_customer_id, v_doc_currency
    FROM ar."ReceivableApplication" a
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
    WHERE a."ReceivableApplicationId" = p_application_id
    FOR UPDATE;

    IF v_current_amount IS NULL THEN
        RETURN QUERY SELECT 0, 'Aplicacion de cobro no encontrada.'::TEXT;
        RETURN;
    END IF;

    IF p_currency_code IS NOT NULL AND UPPER(v_doc_currency) <> UPPER(p_currency_code) THEN
        RETURN QUERY SELECT 0, 'La moneda del documento no coincide con la solicitada.'::TEXT;
        RETURN;
    END IF;

    v_amount := COALESCE(p_amount, v_current_amount);

    IF v_amount <= 0 THEN
        RETURN QUERY SELECT 0, 'El monto debe ser mayor a cero.'::TEXT;
        RETURN;
    END IF;

    v_delta := v_amount - v_current_amount;

    IF v_delta > 0 AND v_pending < v_delta THEN
        RETURN QUERY SELECT 0, ('Saldo insuficiente en el documento. Pendiente actual: ' || v_pending::TEXT)::TEXT;
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

    v_new_paid_flag := (v_new_pending <= 0);
    v_new_status := CASE
        WHEN v_new_pending <= 0            THEN 'PAID'
        WHEN v_new_pending < v_total_amount THEN 'PARTIAL'
        ELSE 'PENDING'
    END;

    -- Actualizar la aplicacion
    UPDATE ar."ReceivableApplication"
    SET "AppliedAmount"    = v_amount,
        "ApplyDate"        = COALESCE(p_apply_date, "ApplyDate"),
        "PaymentReference" = COALESCE(p_payment_reference, "PaymentReference")
    WHERE "ReceivableApplicationId" = p_application_id;

    -- Actualizar documento si hubo cambio de monto
    IF v_delta <> 0 THEN
        UPDATE ar."ReceivableDocument"
        SET "PendingAmount" = v_new_pending,
            "Status"        = v_new_status,
            "PaidFlag"      = v_new_paid_flag,
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC'
        WHERE "ReceivableDocumentId" = v_doc_id;

        PERFORM usp_master_customer_updatebalance(v_customer_id);
    END IF;

    RETURN QUERY SELECT 1, 'Abono actualizado correctamente.'::TEXT;
END;
$$;
