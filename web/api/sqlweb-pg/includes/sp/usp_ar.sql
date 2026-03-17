-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_ar.sql
-- Funciones de Cuentas por Cobrar (Accounts Receivable)
-- Operaciones sobre ar.ReceivableDocument y ar.ReceivableApplication
-- ============================================================

-- =============================================================================
-- 1. usp_AR_Application_List
--    Listado paginado de aplicaciones (abonos/cobros) recibidos.
--    Permite filtrar por cliente, tipo de documento y rango de fechas.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AR_Application_List;
DROP FUNCTION IF EXISTS usp_AR_Application_List(BIGINT, VARCHAR(20), DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_AR_Application_List(
    p_customer_id    BIGINT       DEFAULT NULL,
    p_document_type  VARCHAR(20)  DEFAULT NULL,
    p_from_date      DATE         DEFAULT NULL,
    p_to_date        DATE         DEFAULT NULL,
    p_page           INT          DEFAULT 1,
    p_limit          INT          DEFAULT 50
)
RETURNS TABLE (
    "ReceivableApplicationId" BIGINT,
    "ReceivableDocumentId"    BIGINT,
    "ApplyDate"               DATE,
    "AppliedAmount"           DECIMAL(18,2),
    "PaymentReference"        VARCHAR(120),
    "CreatedAt"               TIMESTAMP,
    "DocumentNumber"          VARCHAR(120),
    "DocumentType"            VARCHAR(20),
    "TotalAmount"             DECIMAL(18,2),
    "PendingAmount"           DECIMAL(18,2),
    "DocumentStatus"          VARCHAR(20),
    "CustomerId"              BIGINT,
    "CustomerCode"            VARCHAR(24),
    "CustomerName"            VARCHAR(255),
    "TotalCount"              BIGINT
)
LANGUAGE plpgsql AS $$
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
    WHERE (p_customer_id   IS NULL OR d."CustomerId"    = p_customer_id)
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
    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"
    WHERE (p_customer_id   IS NULL OR d."CustomerId"    = p_customer_id)
      AND (p_document_type IS NULL OR d."DocumentType"  = p_document_type)
      AND (p_from_date     IS NULL OR a."ApplyDate"    >= p_from_date)
      AND (p_to_date       IS NULL OR a."ApplyDate"    <= p_to_date)
    ORDER BY a."ApplyDate" DESC, a."ReceivableApplicationId" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- =============================================================================
-- 2. usp_AR_Application_Get
--    Obtiene el detalle de una aplicacion (abono) especifica junto con la
--    informacion del documento y del cliente asociado.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AR_Application_Get;
DROP FUNCTION IF EXISTS usp_AR_Application_Get(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_AR_Application_Get(
    p_application_id  BIGINT
)
RETURNS TABLE (
    "ReceivableApplicationId" BIGINT,
    "ReceivableDocumentId"    BIGINT,
    "ApplyDate"               DATE,
    "AppliedAmount"           DECIMAL(18,2),
    "PaymentReference"        VARCHAR(120),
    "CreatedAt"               TIMESTAMP,
    "DocumentNumber"          VARCHAR(120),
    "DocumentType"            VARCHAR(20),
    "IssueDate"               DATE,
    "DueDate"                 DATE,
    "CurrencyCode"            VARCHAR(10),
    "TotalAmount"             DECIMAL(18,2),
    "PendingAmount"           DECIMAL(18,2),
    "PaidFlag"                BOOLEAN,
    "DocumentStatus"          VARCHAR(20),
    "DocumentNotes"           TEXT,
    "CustomerId"              BIGINT,
    "CustomerCode"            VARCHAR(24),
    "CustomerName"            VARCHAR(255),
    "CustomerFiscalId"        VARCHAR(30)
)
LANGUAGE plpgsql AS $$
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
        d."PaidFlag",
        d."Status",
        d."Notes",
        c."CustomerId",
        c."CustomerCode",
        c."CustomerName",
        c."FiscalId"
    FROM ar."ReceivableApplication" a
    INNER JOIN ar."ReceivableDocument" d ON d."ReceivableDocumentId" = a."ReceivableDocumentId"
    INNER JOIN master."Customer" c      ON c."CustomerId"           = d."CustomerId"
    WHERE a."ReceivableApplicationId" = p_application_id;
END;
$$;

-- =============================================================================
-- 3. usp_AR_Application_Apply
--    Aplica un cobro (abono) a un documento por cobrar.
--    Operacion transaccional:
--      - Bloquea el documento con FOR UPDATE
--      - Valida que el monto no exceda el saldo pendiente
--      - Inserta la aplicacion en ar.ReceivableApplication
--      - Actualiza PendingAmount, PaidFlag y Status del documento
--      - Recalcula el saldo del cliente via usp_Master_Customer_UpdateBalance
--
--    Retorna: ok, ApplicationId, NewPending, Message
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AR_Application_Apply;
DROP FUNCTION IF EXISTS usp_AR_Application_Apply(BIGINT, DECIMAL(18,2), VARCHAR(120), DATE, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_AR_Application_Apply(
    p_receivable_document_id  BIGINT,
    p_amount                  DECIMAL(18,2),
    p_payment_reference       VARCHAR(120)  DEFAULT NULL,
    p_apply_date              DATE          DEFAULT NULL,
    p_updated_by_user_id      INT           DEFAULT NULL
)
RETURNS TABLE (
    "ok"              INT,
    "ApplicationId"   BIGINT,
    "NewPending"      DECIMAL(18,2),
    "Message"         TEXT
)
LANGUAGE plpgsql AS $$
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
            'El monto debe ser mayor a cero.'::TEXT;
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
        RETURN QUERY SELECT 0, NULL::BIGINT, NULL::DECIMAL(18,2),
            'Documento por cobrar no encontrado.'::TEXT;
        RETURN;
    END IF;

    -- Validar que el documento no este anulado
    IF v_doc_status = 'VOIDED' THEN
        RETURN QUERY SELECT 0, NULL::BIGINT, NULL::DECIMAL(18,2),
            'No se puede aplicar abono a un documento anulado.'::TEXT;
        RETURN;
    END IF;

    -- Validar que el monto no exceda el saldo pendiente
    IF p_amount > v_current_pending THEN
        RETURN QUERY SELECT 0, NULL::BIGINT, v_current_pending,
            ('El monto (' || p_amount::TEXT || ') excede el saldo pendiente (' || v_current_pending::TEXT || ').')::TEXT;
        RETURN;
    END IF;

    -- Insertar la aplicacion (abono)
    INSERT INTO ar."ReceivableApplication" ("ReceivableDocumentId", "ApplyDate", "AppliedAmount", "PaymentReference")
    VALUES (p_receivable_document_id, v_apply_date, p_amount, p_payment_reference)
    RETURNING "ReceivableApplicationId" INTO v_application_id;

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
    WHERE "ReceivableDocumentId" = p_receivable_document_id;

    -- Recalcular saldo total del cliente
    PERFORM usp_Master_Customer_UpdateBalance(v_customer_id, p_updated_by_user_id);

    -- Retornar resultado exitoso
    RETURN QUERY SELECT 1, v_application_id, v_new_pending,
        'Abono aplicado correctamente.'::TEXT;
END;
$$;

-- =============================================================================
-- 4. usp_AR_Application_Reverse
--    Reversa (elimina) una aplicacion de cobro previamente registrada.
--    Operacion transaccional:
--      - Bloquea la aplicacion con FOR UPDATE
--      - Elimina el registro de ar.ReceivableApplication
--      - Restaura el PendingAmount del documento y recalcula PaidFlag/Status
--      - Recalcula el saldo del cliente via usp_Master_Customer_UpdateBalance
--
--    Retorna: ok, NewPending, Message
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AR_Application_Reverse;
DROP FUNCTION IF EXISTS usp_AR_Application_Reverse(BIGINT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_AR_Application_Reverse(
    p_application_id     BIGINT,
    p_updated_by_user_id INT DEFAULT NULL
)
RETURNS TABLE (
    "ok"          INT,
    "NewPending"  DECIMAL(18,2),
    "Message"     TEXT
)
LANGUAGE plpgsql AS $$
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
$$;

-- =============================================================================
-- 5. usp_AR_Application_ListByContext
--    Listado paginado de aplicaciones filtrado por contexto (Company/Branch).
--    Permite busqueda por DocumentNumber, CustomerName, PaymentReference,
--    filtro por CustomerCode y CurrencyCode.
--    Retorna las columnas alias legacy + canonical para compatibilidad VB6.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AR_Application_ListByContext;
DROP FUNCTION IF EXISTS usp_AR_Application_ListByContext(INT, INT, VARCHAR(100), VARCHAR(60), VARCHAR(10), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_AR_Application_ListByContext(
    p_company_id     INT,
    p_branch_id      INT,
    p_search         VARCHAR(100)  DEFAULT NULL,
    p_codigo         VARCHAR(60)   DEFAULT NULL,
    p_currency_code  VARCHAR(10)   DEFAULT NULL,
    p_page           INT           DEFAULT 1,
    p_limit          INT           DEFAULT 50
)
RETURNS TABLE (
    "Id"            BIGINT,
    "ApplicationId" BIGINT,
    "DocumentoId"   BIGINT,
    "CODIGO"        VARCHAR(24),
    "Codigo"        VARCHAR(24),
    "NOMBRE"        VARCHAR(255),
    "TIPO_DOC"      VARCHAR(20),
    "TipoDoc"       VARCHAR(20),
    "DOCUMENTO"     VARCHAR(120),
    "Num_fact"      VARCHAR(120),
    "FECHA"         DATE,
    "Fecha"         DATE,
    "MONTO"         DECIMAL(18,2),
    "Monto"         DECIMAL(18,2),
    "MONEDA"        VARCHAR(10),
    "REFERENCIA"    VARCHAR(120),
    "Concepto"      VARCHAR(120),
    "PENDIENTE"     DECIMAL(18,2),
    "TOTAL"         DECIMAL(18,2),
    "ESTADO_DOC"    VARCHAR(20),
    "TotalCount"    BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_page           INT := GREATEST(COALESCE(p_page, 1), 1);
    v_limit          INT := LEAST(GREATEST(COALESCE(p_limit, 50), 1), 500);
    v_offset         INT := (v_page - 1) * v_limit;
    v_search_pattern VARCHAR(102);
    v_total          BIGINT;
BEGIN
    IF p_search IS NOT NULL AND LENGTH(TRIM(p_search)) > 0 THEN
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
        d."CurrencyCode"::VARCHAR(10),
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
$$;

-- =============================================================================
-- 6. usp_AR_Application_GetByContext
--    Obtiene una aplicacion (abono) por Id, validando Company/Branch y
--    opcionalmente filtrando por moneda.
--    Retorna las mismas columnas alias que ListByContext.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AR_Application_GetByContext;
DROP FUNCTION IF EXISTS usp_AR_Application_GetByContext(BIGINT, INT, INT, VARCHAR(10)) CASCADE;
CREATE OR REPLACE FUNCTION usp_AR_Application_GetByContext(
    p_application_id  BIGINT,
    p_company_id      INT,
    p_branch_id       INT,
    p_currency_code   VARCHAR(10) DEFAULT NULL
)
RETURNS TABLE (
    "Id"            BIGINT,
    "ApplicationId" BIGINT,
    "DocumentoId"   BIGINT,
    "CODIGO"        VARCHAR(24),
    "Codigo"        VARCHAR(24),
    "NOMBRE"        VARCHAR(255),
    "TIPO_DOC"      VARCHAR(20),
    "TipoDoc"       VARCHAR(20),
    "DOCUMENTO"     VARCHAR(120),
    "Num_fact"      VARCHAR(120),
    "FECHA"         DATE,
    "Fecha"         DATE,
    "MONTO"         DECIMAL(18,2),
    "Monto"         DECIMAL(18,2),
    "MONEDA"        VARCHAR(10),
    "REFERENCIA"    VARCHAR(120),
    "Concepto"      VARCHAR(120),
    "PENDIENTE"     DECIMAL(18,2),
    "TOTAL"         DECIMAL(18,2),
    "ESTADO_DOC"    VARCHAR(20)
)
LANGUAGE plpgsql AS $$
BEGIN
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
        d."CurrencyCode"::VARCHAR(10),
        a."PaymentReference",
        a."PaymentReference",
        d."PendingAmount",
        d."TotalAmount",
        d."Status"
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
--    Resuelve un documento por cobrar a partir de DocumentNumber, Company,
--    Branch, y opcionalmente CustomerCode y DocumentType.
--    Bloquea la fila con FOR UPDATE para uso dentro de transacciones.
--    Retorna: ReceivableDocumentId, PendingAmount, TotalAmount, CustomerId,
--             CurrencyCode.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AR_Application_Resolve;
DROP FUNCTION IF EXISTS usp_AR_Application_Resolve(INT, INT, VARCHAR(120), VARCHAR(24), VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_AR_Application_Resolve(
    p_company_id       INT,
    p_branch_id        INT,
    p_document_number  VARCHAR(120),
    p_customer_code    VARCHAR(24)  DEFAULT NULL,
    p_document_type    VARCHAR(20)  DEFAULT NULL
)
RETURNS TABLE (
    "ReceivableDocumentId" BIGINT,
    "PendingAmount"        DECIMAL(18,2),
    "TotalAmount"          DECIMAL(18,2),
    "CustomerId"           BIGINT,
    "CurrencyCode"         VARCHAR(10)
)
LANGUAGE plpgsql AS $$
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
$$;

-- =============================================================================
-- 8. usp_AR_Application_Update
--    Actualiza una aplicacion (abono) existente.
--    Operacion transaccional:
--      - Bloquea aplicacion + documento con FOR UPDATE
--      - Valida moneda si se especifica p_currency_code
--      - Calcula delta de monto y valida saldo suficiente
--      - Actualiza aplicacion (monto, fecha, referencia)
--      - Actualiza PendingAmount/Status/PaidFlag del documento
--      - Recalcula saldo del cliente via usp_Master_Customer_UpdateBalance
--
--    Retorna: ok (1=exito, 0=error), Message
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AR_Application_Update;
DROP FUNCTION IF EXISTS usp_AR_Application_Update(BIGINT, DECIMAL(18,2), DATE, VARCHAR(120), VARCHAR(10)) CASCADE;
CREATE OR REPLACE FUNCTION usp_AR_Application_Update(
    p_application_id     BIGINT,
    p_amount             DECIMAL(18,2)  DEFAULT NULL,
    p_apply_date         DATE           DEFAULT NULL,
    p_payment_reference  VARCHAR(120)   DEFAULT NULL,
    p_currency_code      VARCHAR(10)    DEFAULT NULL
)
RETURNS TABLE (
    "ok"       INT,
    "Message"  TEXT
)
LANGUAGE plpgsql AS $$
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
    IF p_currency_code IS NOT NULL AND UPPER(v_doc_currency) <> UPPER(p_currency_code) THEN
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

    -- Calcular nuevo estado del documento
    v_new_paid_flag := (v_new_pending <= 0);
    v_new_status    := CASE
                         WHEN v_new_pending <= 0           THEN 'PAID'
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
        SET "PendingAmount"   = v_new_pending,
            "Status"          = v_new_status,
            "PaidFlag"        = v_new_paid_flag,
            "UpdatedAt"       = NOW() AT TIME ZONE 'UTC'
        WHERE "ReceivableDocumentId" = v_doc_id;

        -- Recalcular saldo total del cliente
        PERFORM usp_Master_Customer_UpdateBalance(v_customer_id);
    END IF;

    RETURN QUERY SELECT 1, 'Abono actualizado correctamente.'::TEXT;
END;
$$;
