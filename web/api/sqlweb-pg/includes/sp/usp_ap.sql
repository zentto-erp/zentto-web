-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_ap.sql
-- Funciones de Cuentas por Pagar (Accounts Payable)
-- Operaciones sobre ap.PayableDocument y ap.PayableApplication
-- ============================================================

-- =============================================================================
-- 1. usp_AP_Application_List
--    Listado paginado de aplicaciones (pagos) realizados a proveedores.
--    Permite filtrar por proveedor, tipo de documento y rango de fechas.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AP_Application_List;
DROP FUNCTION IF EXISTS usp_AP_Application_List(BIGINT, VARCHAR(20), DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_AP_Application_List(
    p_supplier_id    BIGINT       DEFAULT NULL,
    p_document_type  VARCHAR(20)  DEFAULT NULL,
    p_from_date      DATE         DEFAULT NULL,
    p_to_date        DATE         DEFAULT NULL,
    p_page           INT          DEFAULT 1,
    p_limit          INT          DEFAULT 50
)
RETURNS TABLE (
    "PayableApplicationId" BIGINT,
    "PayableDocumentId"    BIGINT,
    "ApplyDate"            DATE,
    "AppliedAmount"        DECIMAL(18,2),
    "PaymentReference"     VARCHAR(120),
    "CreatedAt"            TIMESTAMP,
    "DocumentNumber"       VARCHAR(120),
    "DocumentType"         VARCHAR(20),
    "TotalAmount"          DECIMAL(18,2),
    "PendingAmount"        DECIMAL(18,2),
    "DocumentStatus"       VARCHAR(20),
    "SupplierId"           BIGINT,
    "SupplierCode"         VARCHAR(24),
    "SupplierName"         VARCHAR(255),
    "TotalCount"           BIGINT
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
$$;

-- =============================================================================
-- 2. usp_AP_Application_Get
--    Obtiene el detalle de una aplicacion (pago) especifica junto con la
--    informacion del documento y del proveedor asociado.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AP_Application_Get;
DROP FUNCTION IF EXISTS usp_AP_Application_Get(BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_AP_Application_Get(
    p_application_id  BIGINT
)
RETURNS TABLE (
    "PayableApplicationId" BIGINT,
    "PayableDocumentId"    BIGINT,
    "ApplyDate"            DATE,
    "AppliedAmount"        DECIMAL(18,2),
    "PaymentReference"     VARCHAR(120),
    "CreatedAt"            TIMESTAMP,
    "DocumentNumber"       VARCHAR(120),
    "DocumentType"         VARCHAR(20),
    "IssueDate"            DATE,
    "DueDate"              DATE,
    "CurrencyCode"         VARCHAR(10),
    "TotalAmount"          DECIMAL(18,2),
    "PendingAmount"        DECIMAL(18,2),
    "PaidFlag"             BOOLEAN,
    "DocumentStatus"       VARCHAR(20),
    "DocumentNotes"        TEXT,
    "SupplierId"           BIGINT,
    "SupplierCode"         VARCHAR(24),
    "SupplierName"         VARCHAR(255),
    "SupplierFiscalId"     VARCHAR(30)
)
LANGUAGE plpgsql AS $$
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
        d."CurrencyCode"::VARCHAR(10),
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
    WHERE a."PayableApplicationId" = p_application_id;
END;
$$;

-- =============================================================================
-- 3. usp_AP_Application_Apply
--    Aplica un pago a un documento por pagar.
--    Operacion transaccional:
--      - Bloquea el documento con FOR UPDATE
--      - Valida que el monto no exceda el saldo pendiente
--      - Inserta la aplicacion en ap.PayableApplication
--      - Actualiza PendingAmount, PaidFlag y Status del documento
--      - Recalcula el saldo del proveedor via usp_Master_Supplier_UpdateBalance
--
--    Retorna: ok, ApplicationId, NewPending, Message
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AP_Application_Apply;
DROP FUNCTION IF EXISTS usp_AP_Application_Apply(BIGINT, DECIMAL(18,2), VARCHAR(120), DATE, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_AP_Application_Apply(
    p_payable_document_id  BIGINT,
    p_amount               DECIMAL(18,2),
    p_payment_reference    VARCHAR(120)  DEFAULT NULL,
    p_apply_date           DATE          DEFAULT NULL,
    p_updated_by_user_id   INT           DEFAULT NULL
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
    FROM ap."PayableDocument" d
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
    PERFORM usp_Master_Supplier_UpdateBalance(v_supplier_id, p_updated_by_user_id);

    -- Retornar resultado exitoso
    RETURN QUERY SELECT 1, v_application_id, v_new_pending,
        'Pago aplicado correctamente.'::TEXT;
END;
$$;

-- =============================================================================
-- 4. usp_AP_Application_Reverse
--    Reversa (elimina) una aplicacion de pago previamente registrada.
--    Operacion transaccional:
--      - Bloquea la aplicacion con FOR UPDATE
--      - Elimina el registro de ap.PayableApplication
--      - Restaura el PendingAmount del documento y recalcula PaidFlag/Status
--      - Recalcula el saldo del proveedor via usp_Master_Supplier_UpdateBalance
--
--    Retorna: ok, NewPending, Message
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AP_Application_Reverse;
DROP FUNCTION IF EXISTS usp_AP_Application_Reverse(BIGINT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_AP_Application_Reverse(
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
    IF v_applied_amount IS NULL THEN
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
    WHERE "PayableDocumentId" = v_payable_document_id;

    -- Recalcular saldo total del proveedor
    PERFORM usp_Master_Supplier_UpdateBalance(v_supplier_id, p_updated_by_user_id);

    -- Retornar resultado exitoso
    RETURN QUERY SELECT 1, v_new_pending,
        'Pago reversado correctamente.'::TEXT;
END;
$$;

-- =============================================================================
-- 5. usp_AP_Application_ListByContext
--    Listado paginado de aplicaciones (pagos) por contexto empresa/sucursal.
--    Permite filtrar por busqueda libre, codigo de proveedor y moneda.
--    Retorna columnas con alias legacy y canonico para compatibilidad VB6.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AP_Application_ListByContext;
DROP FUNCTION IF EXISTS usp_AP_Application_ListByContext(INT, INT, VARCHAR(100), VARCHAR(60), VARCHAR(10), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_AP_Application_ListByContext(
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
    FROM ap."PayableApplication" a
    INNER JOIN ap."PayableDocument" d ON d."PayableDocumentId" = a."PayableDocumentId"
    INNER JOIN master."Supplier" s    ON s."SupplierId"        = d."SupplierId"
    WHERE d."CompanyId" = p_company_id
      AND d."BranchId"  = p_branch_id
      AND (v_search_pattern IS NULL OR (
              d."DocumentNumber" ILIKE v_search_pattern
           OR s."SupplierName"   ILIKE v_search_pattern
           OR COALESCE(a."PaymentReference",''::VARCHAR) ILIKE v_search_pattern
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
        d."CurrencyCode"::VARCHAR(10),
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
           OR COALESCE(a."PaymentReference",''::VARCHAR) ILIKE v_search_pattern
          ))
      AND (p_codigo       IS NULL OR s."SupplierCode" = p_codigo)
      AND (p_currency_code IS NULL OR d."CurrencyCode" = p_currency_code)
    ORDER BY a."ApplyDate" DESC, a."PayableApplicationId" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- =============================================================================
-- 6. usp_AP_Application_GetByContext
--    Obtiene un registro de aplicacion (pago) por su Id validando contexto
--    empresa/sucursal y opcionalmente moneda.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AP_Application_GetByContext;
DROP FUNCTION IF EXISTS usp_AP_Application_GetByContext(BIGINT, INT, INT, VARCHAR(10)) CASCADE;
CREATE OR REPLACE FUNCTION usp_AP_Application_GetByContext(
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
        d."CurrencyCode"::VARCHAR(10),
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
$$;

-- =============================================================================
-- 7. usp_AP_Application_Resolve
--    Resuelve un documento por pagar a partir de su numero, codigo de proveedor
--    y tipo de documento.  Retorna los datos necesarios para aplicar un pago.
--    Usa FOR UPDATE para seguridad transaccional.
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AP_Application_Resolve;
DROP FUNCTION IF EXISTS usp_AP_Application_Resolve(INT, INT, VARCHAR(120), VARCHAR(24), VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_AP_Application_Resolve(
    p_company_id       INT,
    p_branch_id        INT,
    p_document_number  VARCHAR(120),
    p_supplier_code    VARCHAR(24)  DEFAULT NULL,
    p_document_type    VARCHAR(20)  DEFAULT NULL
)
RETURNS TABLE (
    "PayableDocumentId" BIGINT,
    "PendingAmount"     DECIMAL(18,2),
    "TotalAmount"       DECIMAL(18,2),
    "SupplierId"        BIGINT,
    "CurrencyCode"      VARCHAR(10)
)
LANGUAGE plpgsql AS $$
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
$$;

-- =============================================================================
-- 8. usp_AP_Application_Update
--    Actualiza una aplicacion de pago existente.
--    Operacion transaccional:
--      - Obtiene la aplicacion y el documento con FOR UPDATE
--      - Valida moneda si se proporciona
--      - Calcula el delta entre monto original y nuevo
--      - Actualiza la aplicacion (monto, fecha, referencia)
--      - Actualiza PendingAmount, PaidFlag y Status del documento
--      - Recalcula el saldo del proveedor via usp_Master_Supplier_UpdateBalance
--
--    Retorna: ok (1=exito, 0=error), Message
-- =============================================================================
DROP FUNCTION IF EXISTS usp_AP_Application_Update;
DROP FUNCTION IF EXISTS usp_AP_Application_Update(BIGINT, DECIMAL(18,2), DATE, VARCHAR(120), VARCHAR(10)) CASCADE;
CREATE OR REPLACE FUNCTION usp_AP_Application_Update(
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
        ON d."PayableDocumentId" = a."PayableDocumentId"
    WHERE a."PayableApplicationId" = p_application_id
    FOR UPDATE;

    -- Validar que la aplicacion existe
    IF v_original_amount IS NULL THEN
        RETURN QUERY SELECT 0, 'Aplicacion de pago no encontrada.'::TEXT;
        RETURN;
    END IF;

    -- Validar moneda si se especifica
    IF p_currency_code IS NOT NULL
       AND UPPER(v_doc_currency) <> UPPER(p_currency_code) THEN
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

    -- Actualizar la aplicacion
    UPDATE ap."PayableApplication"
    SET "AppliedAmount"    = v_updated_amount,
        "ApplyDate"        = COALESCE(p_apply_date, "ApplyDate"),
        "PaymentReference" = COALESCE(p_payment_reference, "PaymentReference")
    WHERE "PayableApplicationId" = p_application_id;

    -- Actualizar documento si hubo cambio de monto
    IF v_delta <> 0 THEN
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
$$;
