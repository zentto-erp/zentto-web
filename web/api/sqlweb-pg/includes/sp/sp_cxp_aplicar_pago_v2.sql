-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_cxp_aplicar_pago_v2.sql
-- Cuentas por Pagar: Aplicacion de pagos v2 (modelo canonico)
-- Esquema: master.Supplier + ap.PayableDocument/ap.PayableApplication
-- Entrada arrays por JSONB (reemplazo de XML en SQL Server)
-- ============================================================

DROP FUNCTION IF EXISTS usp_cxp_aplicar_pago(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR, VARCHAR, JSONB, JSONB, BOOLEAN, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS usp_cxp_aplicar_pago(VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR, VARCHAR, JSONB, JSONB) CASCADE;

CREATE OR REPLACE FUNCTION usp_cxp_aplicar_pago(
    p_request_id       VARCHAR(100),
    p_cod_proveedor    VARCHAR(24),
    p_fecha            VARCHAR(10),
    p_monto_total      NUMERIC(18,2),
    p_cod_usuario      VARCHAR(40),
    p_observaciones    VARCHAR(500) DEFAULT '',
    p_documentos_json  JSONB DEFAULT NULL,
    p_formas_pago_json JSONB DEFAULT NULL,
    p_apply_retention  BOOLEAN DEFAULT FALSE,
    p_retention_type   VARCHAR(20) DEFAULT 'ISLR',
    p_country_code     VARCHAR(2) DEFAULT 'VE'
)
RETURNS TABLE (
    "NumPago"          VARCHAR(50),
    "Resultado"        INT,
    "Mensaje"          VARCHAR(500),
    "RetentionAmount"  NUMERIC(18,2),
    "RetentionRate"    NUMERIC(8,4),
    "VoucherId"        BIGINT
)
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_resultado        INT := 0;
    v_mensaje          VARCHAR(500) := '';
    v_num_pago         VARCHAR(50) := '';
    v_fecha_date       DATE;
    v_supplier_id      BIGINT;
    v_company_id       INT := 1;
    v_payable_id       BIGINT;
    v_pending          NUMERIC(18,2);
    v_total            NUMERIC(18,2);
    v_apply            NUMERIC(18,2);
    v_applied_total    NUMERIC(18,2) := 0;
    v_doc              RECORD;
    v_dup_ref          VARCHAR(150);
    -- Retention variables
    v_ret_rate         NUMERIC(8,4) := 0;
    v_ret_amount       NUMERIC(18,2) := 0;
    v_ret_total        NUMERIC(18,2) := 0;
    v_ret_concept      VARCHAR(20) := '';
    v_ret_subtrahend   NUMERIC(18,2) := 0;
    v_voucher_id       BIGINT := 0;
    v_ret_calc         RECORD;
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
    SELECT s."SupplierId", s."CompanyId"
      INTO v_supplier_id, v_company_id
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
         WHERE COALESCE(NULLIF(elem->>'numDoc', ''::VARCHAR),''::VARCHAR) <> ''
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
            ('Duplicado idempotente. Pago: ' || COALESCE(v_dup_ref,''::VARCHAR))::VARCHAR(500);
        RETURN;
    END IF;

    -- -------------------------------------------------------
    -- Iterar documentos y aplicar pagos
    -- -------------------------------------------------------
    FOR v_doc IN
        SELECT
            UPPER(COALESCE(NULLIF(elem->>'tipoDoc', ''::VARCHAR), 'COMPRA')) AS tipo_doc,
            COALESCE(NULLIF(elem->>'numDoc', ''::VARCHAR),''::VARCHAR)               AS num_doc,
            COALESCE(NULLIF(elem->>'montoAplicar', ''::VARCHAR), '0')::NUMERIC(18,2) AS monto_aplicar
          FROM jsonb_array_elements(p_documentos_json) AS elem
         WHERE COALESCE(NULLIF(elem->>'numDoc', ''::VARCHAR),''::VARCHAR) <> ''
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

            -- Calcular retenciÃ³n si estÃ¡ habilitado
            v_ret_rate := 0;
            v_ret_amount := 0;
            IF p_apply_retention THEN
                SELECT r."Rate", r."Amount", r."ConceptCode", r."Subtrahend"
                INTO v_ret_rate, v_ret_amount, v_ret_concept, v_ret_subtrahend
                FROM usp_Fiscal_Withholding_Calculate(
                    v_company_id, p_cod_proveedor, v_apply, p_retention_type, p_country_code
                ) r;

                -- Acumular total retenido
                IF v_ret_amount > 0 THEN
                    v_ret_total := v_ret_total + v_ret_amount;
                END IF;
            END IF;

            INSERT INTO ap."PayableApplication" (
                "PayableDocumentId",
                "ApplyDate",
                "AppliedAmount",
                "PaymentReference",
                "RetentionType",
                "RetentionRate",
                "RetentionAmount",
                "NetAmount"
            )
            VALUES (
                v_payable_id,
                v_fecha_date,
                v_apply,
                p_request_id || ':' || v_num_pago,
                CASE WHEN v_ret_amount > 0 THEN p_retention_type ELSE NULL END,
                CASE WHEN v_ret_amount > 0 THEN v_ret_rate ELSE NULL END,
                COALESCE(v_ret_amount, 0),
                v_apply - COALESCE(v_ret_amount, 0)
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
    -- Generar comprobante de retenciÃ³n si hubo retenciÃ³n
    -- -------------------------------------------------------
    IF v_ret_total > 0 THEN
        BEGIN
            SELECT wg.p_voucher_id INTO v_voucher_id
            FROM usp_Fiscal_Withholding_Generate(
                v_company_id,
                NULL, -- document_id (no aplica en pago directo)
                p_retention_type,
                p_country_code,
                p_cod_usuario
            ) wg
            WHERE wg.p_resultado = 1;
        EXCEPTION WHEN OTHERS THEN
            v_voucher_id := 0; -- best-effort
        END;

        -- Actualizar WithholdingVoucherId en las aplicaciones generadas
        IF v_voucher_id > 0 THEN
            UPDATE ap."PayableApplication"
            SET "WithholdingVoucherId" = v_voucher_id
            WHERE "PaymentReference" = p_request_id || ':' || v_num_pago
              AND "RetentionAmount" > 0;
        END IF;
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
    IF v_ret_total > 0 THEN
        v_mensaje := v_mensaje || ' | RetenciÃ³n: ' || v_ret_total::TEXT;
    END IF;

    RETURN QUERY SELECT
        v_num_pago::VARCHAR(50),
        v_resultado,
        v_mensaje::VARCHAR(500),
        v_ret_total,
        v_ret_rate,
        v_voucher_id;

EXCEPTION WHEN OTHERS THEN
    v_resultado := -99;
    v_mensaje := SQLERRM;

    RETURN QUERY SELECT
        ''::VARCHAR(50),
        v_resultado,
        v_mensaje::VARCHAR(500),
        0::NUMERIC(18,2),
        0::NUMERIC(8,4),
        0::BIGINT;
END;
$fn$;
