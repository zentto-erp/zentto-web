-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_cxc_aplicar_cobro_v2.sql
-- Cuentas por Cobrar: Aplicacion de cobros v2 (modelo canonico)
-- Esquema: master.Customer + ar.ReceivableDocument/ar.ReceivableApplication
-- Entrada arrays por JSONB (reemplazo de XML en SQL Server)
-- ============================================================

DROP FUNCTION IF EXISTS usp_cxc_aplicar_cobro(
    VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR, VARCHAR, JSONB, JSONB
);

CREATE OR REPLACE FUNCTION usp_cxc_aplicar_cobro(
    p_request_id       VARCHAR(100),
    p_cod_cliente      VARCHAR(24),
    p_fecha            VARCHAR(10),
    p_monto_total      NUMERIC(18,2),
    p_cod_usuario      VARCHAR(40),
    p_observaciones    VARCHAR(500) DEFAULT '',
    p_documentos_json  JSONB DEFAULT NULL,
    p_formas_pago_json JSONB DEFAULT NULL
)
RETURNS TABLE (
    "NumRecibo"  VARCHAR(50),
    "Resultado"  INT,
    "Mensaje"    VARCHAR(500)
)
LANGUAGE plpgsql
AS $fn$
DECLARE
    v_resultado     INT := 0;
    v_mensaje       VARCHAR(500) := '';
    v_num_recibo    VARCHAR(50) := '';
    v_fecha_date    DATE;
    v_customer_id   BIGINT;
    v_receivable_id BIGINT;
    v_pending       NUMERIC(18,2);
    v_total         NUMERIC(18,2);
    v_apply         NUMERIC(18,2);
    v_applied_total NUMERIC(18,2) := 0;
    v_doc           RECORD;
    v_dup_ref       VARCHAR(150);
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
    -- Buscar cliente
    -- -------------------------------------------------------
    SELECT c."CustomerId"
      INTO v_customer_id
      FROM master."Customer" c
     WHERE c."CustomerCode" = p_cod_cliente
       AND c."IsDeleted" = FALSE
     LIMIT 1;

    IF v_customer_id IS NULL THEN
        RETURN QUERY SELECT
            ''::VARCHAR(50),
            -1,
            ('Cliente no encontrado: ' || p_cod_cliente)::VARCHAR(500);
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
         WHERE COALESCE(NULLIF(elem->>'numDoc', ''), '') <> ''
    ) THEN
        RETURN QUERY SELECT
            ''::VARCHAR(50),
            -3,
            'No se recibieron documentos validos para aplicar'::VARCHAR(500);
        RETURN;
    END IF;

    -- -------------------------------------------------------
    -- Generar numero de recibo
    -- -------------------------------------------------------
    v_num_recibo := 'RCB-' || TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYYMMDDHH24MISS');

    -- -------------------------------------------------------
    -- Idempotencia: verificar si ya se proceso este RequestId
    -- -------------------------------------------------------
    SELECT SUBSTRING(ra."PaymentReference" FROM POSITION(':' IN ra."PaymentReference") + 1)
      INTO v_dup_ref
      FROM ar."ReceivableApplication" ra
     INNER JOIN ar."ReceivableDocument" rd
        ON rd."ReceivableDocumentId" = ra."ReceivableDocumentId"
     WHERE rd."CustomerId" = v_customer_id
       AND ra."PaymentReference" LIKE p_request_id || ':%'
     ORDER BY ra."ReceivableApplicationId" DESC
     LIMIT 1;

    IF v_dup_ref IS NOT NULL THEN
        RETURN QUERY SELECT
            v_dup_ref::VARCHAR(50),
            1,
            ('Duplicado idempotente. Recibo: ' || COALESCE(v_dup_ref, ''))::VARCHAR(500);
        RETURN;
    END IF;

    -- -------------------------------------------------------
    -- Iterar documentos y aplicar cobros
    -- -------------------------------------------------------
    FOR v_doc IN
        SELECT
            UPPER(COALESCE(NULLIF(elem->>'tipoDoc', ''), 'FACT')) AS tipo_doc,
            COALESCE(NULLIF(elem->>'numDoc', ''), '')             AS num_doc,
            COALESCE(NULLIF(elem->>'montoAplicar', ''), '0')::NUMERIC(18,2) AS monto_aplicar
          FROM jsonb_array_elements(p_documentos_json) AS elem
         WHERE COALESCE(NULLIF(elem->>'numDoc', ''), '') <> ''
    LOOP
        -- Buscar documento pendiente
        SELECT rd."ReceivableDocumentId",
               rd."PendingAmount",
               rd."TotalAmount"
          INTO v_receivable_id, v_pending, v_total
          FROM ar."ReceivableDocument" rd
         WHERE rd."CustomerId" = v_customer_id
           AND rd."DocumentType" = v_doc.tipo_doc
           AND rd."DocumentNumber" = v_doc.num_doc
           AND rd."Status" <> 'VOIDED'
         ORDER BY rd."ReceivableDocumentId" DESC
         LIMIT 1
           FOR UPDATE;

        IF v_receivable_id IS NOT NULL AND v_pending > 0 AND v_doc.monto_aplicar > 0 THEN
            v_apply := LEAST(v_doc.monto_aplicar, v_pending);

            INSERT INTO ar."ReceivableApplication" (
                "ReceivableDocumentId",
                "ApplyDate",
                "AppliedAmount",
                "PaymentReference"
            )
            VALUES (
                v_receivable_id,
                v_fecha_date,
                v_apply,
                p_request_id || ':' || v_num_recibo
            );

            UPDATE ar."ReceivableDocument"
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
             WHERE "ReceivableDocumentId" = v_receivable_id;

            v_applied_total := v_applied_total + v_apply;
        END IF;

        -- Limpiar variables para siguiente iteracion
        v_receivable_id := NULL;
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
    -- Actualizar saldo total del cliente
    -- -------------------------------------------------------
    UPDATE master."Customer"
       SET "TotalBalance" = (
               SELECT COALESCE(SUM("PendingAmount"), 0)
                 FROM ar."ReceivableDocument"
                WHERE "CustomerId" = v_customer_id
                  AND "Status" <> 'VOIDED'
           ),
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
     WHERE "CustomerId" = v_customer_id;

    -- -------------------------------------------------------
    -- Retornar resultado exitoso
    -- -------------------------------------------------------
    v_resultado := 1;
    v_mensaje := 'Cobro aplicado exitosamente. Recibo: ' || v_num_recibo;

    RETURN QUERY SELECT
        v_num_recibo::VARCHAR(50),
        v_resultado,
        v_mensaje::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    v_resultado := -99;
    v_mensaje := SQLERRM;

    RETURN QUERY SELECT
        ''::VARCHAR(50),
        v_resultado,
        v_mensaje::VARCHAR(500);
END;
$fn$;
