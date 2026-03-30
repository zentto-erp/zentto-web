-- =============================================
-- Funcion: Emitir Presupuesto (100% canonico) - PostgreSQL
-- Tablas: ar."SalesDocument", ar."SalesDocumentLine", ar."SalesDocumentPayment"
-- CxC: ar."ReceivableDocument"
-- Inventario: master."Product", master."InventoryMovement", master."AlternateStock"
-- Depositos: acct."BankDeposit"
-- Clientes: master."Customer"
-- OperationType: PRESUP
-- Traducido de SQL Server a PostgreSQL
-- =============================================

DROP FUNCTION IF EXISTS sp_emitir_presupuesto_tx(JSONB, JSONB, JSONB, BOOLEAN, BOOLEAN, BOOLEAN);

CREATE OR REPLACE FUNCTION sp_emitir_presupuesto_tx(
    p_presupuesto_json  JSONB,
    p_detalle_json      JSONB,
    p_formas_pago_json  JSONB DEFAULT NULL,
    p_actualizar_inventario     BOOLEAN DEFAULT TRUE,
    p_generar_cxc               BOOLEAN DEFAULT TRUE,
    p_actualizar_saldos_cliente BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    "ok"              BOOLEAN,
    "numFact"         VARCHAR(60),
    "detalleRows"     INT,
    "montoEfectivo"   NUMERIC(18,4),
    "montoCheque"     NUMERIC(18,4),
    "montoTarjeta"    NUMERIC(18,4),
    "saldoPendiente"  NUMERIC(18,4),
    "abono"           NUMERIC(18,4)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_num_fact        VARCHAR(60);
    v_codigo          VARCHAR(60);
    v_pago            VARCHAR(30);
    v_cod_usuario     VARCHAR(60);
    v_serial_tipo     VARCHAR(60);
    v_tipo_orden      VARCHAR(80);
    v_observ          VARCHAR(4000);
    v_fecha           TIMESTAMP;
    v_fecha_reporte   TIMESTAMP;
    v_total           NUMERIC(18,4);
    v_default_company_id INT := 1;
    v_default_branch_id  INT := 1;
    v_customer_id     BIGINT;
    v_memoria         VARCHAR(80);
    v_monto_efectivo  NUMERIC(18,4) := 0;
    v_monto_cheque    NUMERIC(18,4) := 0;
    v_monto_tarjeta   NUMERIC(18,4) := 0;
    v_saldo_pendiente NUMERIC(18,4) := 0;
    v_num_tarjeta     VARCHAR(60) := '0';
    v_cta             VARCHAR(80) := ' ';
    v_banco_cheque    VARCHAR(120) := ' ';
    v_banco_tarjeta   VARCHAR(120) := ' ';
    v_abono           NUMERIC(18,4);
    v_cancelada       CHAR(1);
    v_detalle_rows    INT;
BEGIN
    -- Parsear cabecera (soporta nodos presupuesto y factura por compat)
    v_num_fact := COALESCE(NULLIF(TRIM(p_presupuesto_json->>'NUM_FACT'), ''::VARCHAR), NULL);
    v_codigo := NULLIF(TRIM(p_presupuesto_json->>'CODIGO'), ''::VARCHAR);
    v_pago := UPPER(COALESCE(NULLIF(TRIM(p_presupuesto_json->>'PAGO'), ''::VARCHAR),''::VARCHAR));
    v_cod_usuario := COALESCE(NULLIF(TRIM(p_presupuesto_json->>'COD_USUARIO'), ''::VARCHAR), 'API');
    v_serial_tipo := COALESCE(NULLIF(TRIM(p_presupuesto_json->>'SERIALTIPO'), ''::VARCHAR),''::VARCHAR);
    v_tipo_orden := COALESCE(NULLIF(TRIM(p_presupuesto_json->>'TIPO_ORDEN'), ''::VARCHAR),
                    COALESCE(NULLIF(TRIM(p_presupuesto_json->>'Tipo_orden'), ''::VARCHAR), '1'));
    v_observ := NULLIF(TRIM(p_presupuesto_json->>'OBSERV'), ''::VARCHAR);

    BEGIN
        v_fecha := (p_presupuesto_json->>'FECHA')::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        v_fecha := NOW() AT TIME ZONE 'UTC';
    END;

    BEGIN
        v_fecha_reporte := (p_presupuesto_json->>'FECHA_REPORTE')::TIMESTAMP;
    EXCEPTION WHEN OTHERS THEN
        v_fecha_reporte := v_fecha;
    END;

    v_total := COALESCE((p_presupuesto_json->>'TOTAL')::NUMERIC(18,4), 0);

    IF v_num_fact IS NULL OR TRIM(v_num_fact) = '' THEN
        RAISE EXCEPTION 'missing_num_fact';
    END IF;

    -- Resolver IDs canonicos
    SELECT "CompanyId" INTO v_default_company_id
      FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;
    v_default_company_id := COALESCE(v_default_company_id, 1);

    SELECT "BranchId" INTO v_default_branch_id
      FROM cfg."Branch" WHERE "CompanyId" = v_default_company_id AND "BranchCode" = 'MAIN' LIMIT 1;
    v_default_branch_id := COALESCE(v_default_branch_id, 1);

    IF v_codigo IS NOT NULL THEN
        SELECT "CustomerId" INTO v_customer_id
          FROM master."Customer"
         WHERE "CustomerCode" = v_codigo AND COALESCE("IsDeleted", FALSE) = FALSE
         LIMIT 1;
    END IF;

    -- 1. Cabecera -> ar."SalesDocument" (OperationType='PRESUP')
    INSERT INTO ar."SalesDocument" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "CustomerCode", "DocumentDate", "ReportDate", "PaymentTerms",
        "TotalAmount", "UserCode", "Notes"
    )
    VALUES (
        v_num_fact, v_serial_tipo, v_tipo_orden, 'PRESUP',
        v_codigo, v_fecha, v_fecha_reporte, v_pago,
        v_total, v_cod_usuario, v_observ
    );

    -- 2. Detalle -> ar."SalesDocumentLine"
    INSERT INTO ar."SalesDocumentLine" (
        "DocumentNumber", "SerialType", "FiscalMemoryNumber", "OperationType",
        "ProductCode", "Quantity", "UnitPrice", "TaxRate", "TotalAmount",
        "DiscountedPrice", "RelatedRef", "AlternateCode"
    )
    SELECT
        COALESCE(NULLIF(TRIM(d->>'NUM_FACT'), ''::VARCHAR), v_num_fact),
        COALESCE(NULLIF(TRIM(d->>'SERIALTIPO'), ''::VARCHAR), v_serial_tipo),
        v_tipo_orden, 'PRESUP',
        NULLIF(TRIM(d->>'COD_SERV'), ''::VARCHAR),
        COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
        COALESCE((d->>'PRECIO')::NUMERIC(18,4), 0),
        COALESCE((d->>'ALICUOTA')::NUMERIC(18,4), 0),
        COALESCE(
            (d->>'TOTAL')::NUMERIC(18,4),
            COALESCE((d->>'PRECIO')::NUMERIC(18,4), 0) * COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0)
        ),
        COALESCE(
            (d->>'PRECIO_DESCUENTO')::NUMERIC(18,4),
            COALESCE((d->>'PRECIO')::NUMERIC(18,4), 0)
        ),
        COALESCE(NULLIF(TRIM(d->>'RELACIONADA'), ''::VARCHAR), '0'),
        NULLIF(TRIM(d->>'COD_ALTERNO'), ''::VARCHAR)
    FROM jsonb_array_elements(p_detalle_json) AS d;

    SELECT COUNT(*) INTO v_detalle_rows FROM jsonb_array_elements(p_detalle_json);

    -- 3. Formas de pago
    v_memoria := v_tipo_orden;

    IF p_formas_pago_json IS NOT NULL THEN
        DELETE FROM ar."SalesDocumentPayment"
         WHERE "DocumentNumber" = v_num_fact
           AND "FiscalMemoryNumber" = v_memoria
           AND "SerialType" = v_serial_tipo
           AND "OperationType" = 'PRESUP';

        INSERT INTO ar."SalesDocumentPayment" (
            "ExchangeRate", "PaymentMethod", "DocumentNumber", "Amount",
            "BankCode", "ReferenceNumber", "PaymentDate", "PaymentNumber",
            "FiscalMemoryNumber", "SerialType", "OperationType"
        )
        SELECT
            COALESCE((fp->>'tasacambio')::NUMERIC(18,6), 1),
            NULLIF(TRIM(fp->>'tipo'), ''::VARCHAR),
            v_num_fact,
            COALESCE((fp->>'monto')::NUMERIC(18,4), 0),
            COALESCE(NULLIF(TRIM(fp->>'banco'), ''::VARCHAR), ' '),
            COALESCE(NULLIF(TRIM(fp->>'cuenta'), ''::VARCHAR), ' '),
            v_fecha,
            COALESCE(NULLIF(TRIM(fp->>'numero'), ''::VARCHAR), '0'),
            v_memoria, v_serial_tipo, 'PRESUP'
        FROM jsonb_array_elements(p_formas_pago_json) AS fp;

        SELECT
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(fp->>'tipo','')) = 'EFECTIVO' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(fp->>'tipo','')) = 'CHEQUE' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(fp->>'tipo','')) LIKE 'TARJETA%' OR UPPER(COALESCE(fp->>'tipo','')) LIKE 'TICKET%' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN UPPER(COALESCE(fp->>'tipo','')) = 'SALDO PENDIENTE' THEN COALESCE((fp->>'monto')::NUMERIC(18,4), 0) ELSE 0 END), 0)
        INTO v_monto_efectivo, v_monto_cheque, v_monto_tarjeta, v_saldo_pendiente
        FROM jsonb_array_elements(p_formas_pago_json) AS fp;

        -- Depositos cheque
        INSERT INTO acct."BankDeposit" ("Amount", "CheckNumber", "BankAccount", "CustomerCode", "IsRelated", "BankName", "DocumentRef", "OperationType")
        SELECT
            COALESCE((fp->>'monto')::NUMERIC(18,4), 0),
            COALESCE(NULLIF(TRIM(fp->>'numero'), ''::VARCHAR), '0'),
            COALESCE(NULLIF(TRIM(fp->>'cuenta'), ''::VARCHAR), ' '),
            v_codigo, FALSE,
            COALESCE(NULLIF(TRIM(fp->>'banco'), ''::VARCHAR), ' '),
            v_num_fact, 'PRESUP'
        FROM jsonb_array_elements(p_formas_pago_json) AS fp
        WHERE UPPER(COALESCE(fp->>'tipo',''::VARCHAR)) = 'CHEQUE';
    END IF;

    v_abono := v_total - v_saldo_pendiente;
    v_cancelada := CASE WHEN v_saldo_pendiente > 0 THEN 'N' ELSE 'S' END;

    UPDATE ar."SalesDocument"
       SET "IsPaid" = v_cancelada,
           "ReportDate" = v_fecha_reporte,
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
     WHERE "DocumentNumber" = v_num_fact AND "OperationType" = 'PRESUP';

    -- 4. CxC
    IF p_generar_cxc AND v_customer_id IS NOT NULL AND (v_pago = 'CREDITO' OR v_saldo_pendiente > 0) THEN
        DELETE FROM ar."ReceivableDocument"
         WHERE "CompanyId" = v_default_company_id AND "BranchId" = v_default_branch_id
           AND "DocumentType" = 'PRESUP' AND "DocumentNumber" = v_num_fact;

        INSERT INTO ar."ReceivableDocument" (
            "CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber",
            "IssueDate", "CurrencyCode", "TotalAmount", "PendingAmount", "PaidFlag", "Status"
        )
        VALUES (
            v_default_company_id, v_default_branch_id, v_customer_id, 'PRESUP', v_num_fact,
            v_fecha::DATE, 'VES', v_saldo_pendiente, v_saldo_pendiente, 0, 'PENDING'
        );
    END IF;

    -- 5. Inventario
    IF p_actualizar_inventario THEN
        INSERT INTO master."InventoryMovement" ("CompanyId", "ProductCode", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes")
        SELECT v_default_company_id, NULLIF(TRIM(d->>'COD_SERV'), ''::VARCHAR), v_num_fact, 'SALIDA', v_fecha::DATE,
            COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0),
            COALESCE(i."COSTO_REFERENCIA", 0),
            COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0) * COALESCE(i."COSTO_REFERENCIA", 0),
            'Presup:' || v_num_fact
        FROM jsonb_array_elements(p_detalle_json) AS d
        INNER JOIN master."Product" i ON i."ProductCode" = NULLIF(TRIM(d->>'COD_SERV'), ''::VARCHAR)
        WHERE NULLIF(TRIM(d->>'COD_SERV'), ''::VARCHAR) IS NOT NULL AND COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0) > 0;

        UPDATE master."Product" AS p
           SET "StockQty" = COALESCE(p."StockQty", 0) - agg."Total"
          FROM (
              SELECT NULLIF(TRIM(d->>'COD_SERV'), ''::VARCHAR) AS cod_serv, SUM(COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0)) AS "Total"
                FROM jsonb_array_elements(p_detalle_json) AS d
               GROUP BY NULLIF(TRIM(d->>'COD_SERV'), ''::VARCHAR)
          ) agg
         WHERE p."ProductCode" = agg.cod_serv;

        UPDATE master."AlternateStock" AS a
           SET "StockQty" = COALESCE(a."StockQty", 0) - agg."Total"
          FROM (
              SELECT NULLIF(TRIM(d->>'COD_ALTERNO'), ''::VARCHAR) AS cod_alterno, SUM(COALESCE((d->>'CANTIDAD')::NUMERIC(18,4), 0)) AS "Total"
                FROM jsonb_array_elements(p_detalle_json) AS d
               WHERE COALESCE((d->>'RELACIONADA')::INT, 0) = 1
               GROUP BY NULLIF(TRIM(d->>'COD_ALTERNO'), ''::VARCHAR)
          ) agg
         WHERE a."ProductCode" = agg.cod_alterno;
    END IF;

    -- 6. Saldos
    IF p_actualizar_saldos_cliente AND v_customer_id IS NOT NULL THEN
        UPDATE master."Customer"
           SET "TotalBalance" = COALESCE((
               SELECT SUM("PendingAmount") FROM ar."ReceivableDocument"
                WHERE "CustomerId" = v_customer_id AND "Status" <> 'VOIDED' AND "PaidFlag" = 0
           ), 0)
         WHERE "CustomerId" = v_customer_id AND COALESCE("IsDeleted", FALSE) = FALSE;
    END IF;

    RETURN QUERY SELECT
        TRUE AS "ok",
        v_num_fact AS "numFact",
        v_detalle_rows AS "detalleRows",
        v_monto_efectivo AS "montoEfectivo",
        v_monto_cheque AS "montoCheque",
        v_monto_tarjeta AS "montoTarjeta",
        v_saldo_pendiente AS "saldoPendiente",
        v_abono AS "abono";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;
