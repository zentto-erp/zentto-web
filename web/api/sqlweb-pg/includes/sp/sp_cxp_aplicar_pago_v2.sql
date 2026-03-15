-- =============================================
-- usp_CxP_AplicarPago v2 (modelo canonico) - PostgreSQL
-- Esquema: master."Supplier" + ap."PayableDocument"/ap."PayableApplication"
-- Entrada arrays por JSONB (reemplaza XML de SQL Server)
-- Traducido de SQL Server a PostgreSQL
-- =============================================

CREATE OR REPLACE FUNCTION usp_cxp_aplicar_pago(
    p_request_id       VARCHAR(100),
    p_cod_proveedor    VARCHAR(24),
    p_fecha            VARCHAR(10),
    p_monto_total      NUMERIC(18,2),
    p_cod_usuario      VARCHAR(40),
    p_observaciones    VARCHAR(500) DEFAULT '',
    p_documentos_json  JSONB DEFAULT NULL,
    p_formas_pago_json JSONB DEFAULT NULL,
    OUT p_num_pago     VARCHAR(50),
    OUT p_resultado    INT,
    OUT p_mensaje      VARCHAR(500)
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
    v_fecha_date DATE;
    v_supplier_id BIGINT;
    v_tipo_doc VARCHAR(20);
    v_num_doc VARCHAR(120);
    v_monto_aplicar NUMERIC(18,2);
    v_payable_id BIGINT;
    v_pending NUMERIC(18,2);
    v_total NUMERIC(18,2);
    v_apply NUMERIC(18,2);
    v_applied_total NUMERIC(18,2) := 0;
    elem JSONB;
    v_existing_pago VARCHAR(50);
BEGIN
    p_resultado := 0;
    p_mensaje := '';
    p_num_pago := '';

    -- Validar fecha
    BEGIN
        v_fecha_date := CAST(p_fecha AS DATE);
    EXCEPTION WHEN OTHERS THEN
        p_resultado := -91;
        p_mensaje := 'Fecha invalida: ' || COALESCE(p_fecha, 'NULL');
        RETURN;
    END;

    -- Buscar proveedor
    SELECT s."SupplierId" INTO v_supplier_id
    FROM master."Supplier" s
    WHERE s."SupplierCode" = p_cod_proveedor
      AND s."IsDeleted" = FALSE
    LIMIT 1;

    IF v_supplier_id IS NULL THEN
        p_resultado := -1;
        p_mensaje := 'Proveedor no encontrado: ' || p_cod_proveedor;
        RETURN;
    END IF;

    -- Validar documentos JSON
    IF p_documentos_json IS NULL THEN
        p_resultado := -2;
        p_mensaje := 'DocumentosJson invalido';
        RETURN;
    END IF;

    -- Crear tabla temporal de documentos
    CREATE TEMP TABLE IF NOT EXISTS tmp_docs_pago (
        row_num SERIAL PRIMARY KEY,
        tipo_doc VARCHAR(20) NOT NULL,
        num_doc VARCHAR(120) NOT NULL,
        monto_aplicar NUMERIC(18,2) NOT NULL
    ) ON COMMIT DROP;

    DELETE FROM tmp_docs_pago;

    FOR elem IN SELECT jsonb_array_elements(p_documentos_json)
    LOOP
        INSERT INTO tmp_docs_pago (tipo_doc, num_doc, monto_aplicar)
        VALUES (
            UPPER(COALESCE(NULLIF(elem->>'tipoDoc', ''), 'COMPRA')),
            COALESCE(NULLIF(elem->>'numDoc', ''), ''),
            COALESCE(CAST(NULLIF(elem->>'montoAplicar', '') AS NUMERIC(18,2)), 0)
        );
    END LOOP;

    -- Eliminar filas sin numDoc
    DELETE FROM tmp_docs_pago WHERE num_doc = '';

    IF NOT EXISTS (SELECT 1 FROM tmp_docs_pago) THEN
        p_resultado := -3;
        p_mensaje := 'No se recibieron documentos validos para aplicar';
        RETURN;
    END IF;

    p_num_pago := 'PAG-' || REPLACE(REPLACE(REPLACE(to_char(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI:SS'), '-', ''), ' ', ''), ':', '');

    -- Verificar idempotencia
    SELECT SUBSTRING(pa."PaymentReference" FROM POSITION(':' IN pa."PaymentReference") + 1)
    INTO v_existing_pago
    FROM ap."PayableApplication" pa
    INNER JOIN ap."PayableDocument" pd ON pd."PayableDocumentId" = pa."PayableDocumentId"
    WHERE pd."SupplierId" = v_supplier_id
      AND pa."PaymentReference" LIKE p_request_id || ':%'
    ORDER BY pa."PayableApplicationId" DESC
    LIMIT 1;

    IF v_existing_pago IS NOT NULL THEN
        p_num_pago := v_existing_pago;
        p_resultado := 1;
        p_mensaje := 'Duplicado idempotente. Pago: ' || COALESCE(p_num_pago, '');
        RETURN;
    END IF;

    -- Procesar documentos
    FOR elem IN SELECT row_to_json(t)::JSONB FROM tmp_docs_pago t ORDER BY t.row_num
    LOOP
        v_tipo_doc := elem->>'tipo_doc';
        v_num_doc := elem->>'num_doc';
        v_monto_aplicar := CAST(elem->>'monto_aplicar' AS NUMERIC(18,2));

        SELECT pd."PayableDocumentId", pd."PendingAmount", pd."TotalAmount"
        INTO v_payable_id, v_pending, v_total
        FROM ap."PayableDocument" pd
        WHERE pd."SupplierId" = v_supplier_id
          AND pd."DocumentType" = v_tipo_doc
          AND pd."DocumentNumber" = v_num_doc
          AND pd."Status" <> 'VOIDED'
        ORDER BY pd."PayableDocumentId" DESC
        LIMIT 1
        FOR UPDATE;

        IF v_payable_id IS NOT NULL AND v_pending > 0 AND v_monto_aplicar > 0 THEN
            v_apply := CASE WHEN v_monto_aplicar > v_pending THEN v_pending ELSE v_monto_aplicar END;

            INSERT INTO ap."PayableApplication" (
                "PayableDocumentId",
                "ApplyDate",
                "AppliedAmount",
                "PaymentReference"
            )
            VALUES (
                v_payable_id,
                v_fecha_date,
                v_apply,
                p_request_id || ':' || p_num_pago
            );

            UPDATE ap."PayableDocument"
            SET "PendingAmount" = CASE WHEN "PendingAmount" - v_apply < 0 THEN 0 ELSE "PendingAmount" - v_apply END,
                "PaidFlag" = CASE WHEN "PendingAmount" - v_apply <= 0 THEN TRUE ELSE FALSE END,
                "Status" = CASE
                    WHEN "PendingAmount" - v_apply <= 0 THEN 'PAID'
                    WHEN "PendingAmount" - v_apply < v_total THEN 'PARTIAL'
                    ELSE 'PENDING'
                END,
                "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
            WHERE "PayableDocumentId" = v_payable_id;

            v_applied_total := v_applied_total + v_apply;
        END IF;

        v_payable_id := NULL;
        v_pending := NULL;
        v_total := NULL;
        v_apply := NULL;
    END LOOP;

    IF v_applied_total <= 0 THEN
        p_resultado := -4;
        p_mensaje := 'No se aplico ningun monto';
        RAISE EXCEPTION 'rollback_pago';
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

    p_resultado := 1;
    p_mensaje := 'Pago aplicado exitosamente. Pago: ' || p_num_pago;

EXCEPTION
    WHEN OTHERS THEN
        IF p_resultado = 0 THEN
            p_resultado := -99;
            p_mensaje := SQLERRM;
        END IF;
END;
$$;
