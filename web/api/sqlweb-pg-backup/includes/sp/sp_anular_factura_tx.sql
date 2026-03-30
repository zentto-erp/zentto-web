-- =============================================
-- Funcion: Anular Factura (100% canonico)
-- Tablas: ar."SalesDocument", ar."SalesDocumentLine"
-- CxC: ar."ReceivableDocument"
-- Inventario: master."Product", master."InventoryMovement", master."AlternateStock"
-- Clientes: master."Customer"
-- Traducido de SQL Server a PostgreSQL
-- =============================================

DROP FUNCTION IF EXISTS sp_anular_factura_tx(VARCHAR(60), VARCHAR(60), VARCHAR(500)) CASCADE;
CREATE OR REPLACE FUNCTION sp_anular_factura_tx(
    p_num_fact    VARCHAR(60),
    p_cod_usuario VARCHAR(60) DEFAULT 'API',
    p_motivo      VARCHAR(500) DEFAULT ''
)
RETURNS TABLE(
    "ok"         BOOLEAN,
    "numFact"    VARCHAR,
    "codCliente" VARCHAR,
    "mensaje"    VARCHAR
) LANGUAGE plpgsql AS $$
DECLARE
    v_fecha_anulacion    TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_cod_cliente        VARCHAR(60);
    v_customer_id        BIGINT;
    v_ya_anulada         BOOLEAN;
    v_default_company_id INT := 1;
    v_default_branch_id  INT := 1;
BEGIN
    SELECT "CompanyId" INTO v_default_company_id
    FROM cfg."Company" WHERE "CompanyCode" = 'DEFAULT' LIMIT 1;

    SELECT "BranchId" INTO v_default_branch_id
    FROM cfg."Branch" WHERE "CompanyId" = v_default_company_id AND "BranchCode" = 'MAIN' LIMIT 1;

    -- 1. Validar factura en ar.SalesDocument
    SELECT
        "CustomerCode",
        CASE WHEN "IsVoided" = TRUE THEN TRUE ELSE FALSE END
    INTO v_cod_cliente, v_ya_anulada
    FROM ar."SalesDocument"
    WHERE "DocumentNumber" = p_num_fact AND "OperationType" = 'FACT' AND "IsDeleted" = FALSE;

    IF v_cod_cliente IS NULL THEN
        RAISE EXCEPTION 'factura_not_found';
    END IF;

    IF v_ya_anulada = TRUE THEN
        RAISE EXCEPTION 'factura_already_anulled';
    END IF;

    -- Resolver CustomerId
    SELECT "CustomerId" INTO v_customer_id
    FROM master."Customer"
    WHERE "CustomerCode" = v_cod_cliente AND COALESCE("IsDeleted", FALSE) = FALSE
    LIMIT 1;

    -- 2. Marcar anulada -> ar.SalesDocument
    UPDATE ar."SalesDocument"
    SET "IsVoided" = TRUE,
        "Notes" = COALESCE("Notes",''::VARCHAR) || ' [ANULADA: ' || TO_CHAR(v_fecha_anulacion, 'YYYY-MM-DD HH24:MI:SS') || ']',
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_fact AND "OperationType" = 'FACT';

    -- 3. Anular detalle -> ar.SalesDocumentLine
    UPDATE ar."SalesDocumentLine"
    SET "IsVoided" = TRUE, "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_fact AND "OperationType" = 'FACT';

    -- 4. Revertir inventario
    CREATE TEMP TABLE IF NOT EXISTS _detalles_factura (
        "COD_SERV"     VARCHAR(60),
        "CANTIDAD"     NUMERIC(18,4),
        "RELACIONADA"  INT,
        "COD_ALTERNO"  VARCHAR(60)
    ) ON COMMIT DROP;

    DELETE FROM _detalles_factura;

    INSERT INTO _detalles_factura ("COD_SERV", "CANTIDAD", "RELACIONADA", "COD_ALTERNO")
    SELECT "ProductCode", COALESCE("Quantity", 0),
        CASE WHEN "RelatedRef" = '1' THEN 1 ELSE 0 END, "AlternateCode"
    FROM ar."SalesDocumentLine"
    WHERE "DocumentNumber" = p_num_fact AND "OperationType" = 'FACT' AND COALESCE("IsVoided", FALSE) = FALSE;

    -- Movimiento de anulacion -> master.InventoryMovement
    INSERT INTO master."InventoryMovement" ("CompanyId", "ProductCode", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes")
    SELECT v_default_company_id, d."COD_SERV", p_num_fact || '_ANUL', 'ENTRADA',
        v_fecha_anulacion::DATE, d."CANTIDAD",
        COALESCE(i."COSTO_REFERENCIA", 0), d."CANTIDAD" * COALESCE(i."COSTO_REFERENCIA", 0),
        'Anulacion Factura:' || p_num_fact || ' - ' || p_motivo
    FROM _detalles_factura d
    INNER JOIN master."Product" i ON i."ProductCode" = d."COD_SERV"
    WHERE d."COD_SERV" IS NOT NULL AND d."CANTIDAD" > 0;

    -- Sumar de vuelta stock -> master.Product
    WITH "Totales" AS (
        SELECT "COD_SERV", SUM("CANTIDAD") AS "TOTAL"
        FROM _detalles_factura WHERE "COD_SERV" IS NOT NULL GROUP BY "COD_SERV"
    )
    UPDATE master."Product" i
    SET "StockQty" = COALESCE(i."StockQty", 0) + t."TOTAL"
    FROM "Totales" t WHERE t."COD_SERV" = i."ProductCode";

    -- Sumar de vuelta stock auxiliar -> master.AlternateStock
    WITH "AuxTotales" AS (
        SELECT "COD_ALTERNO", SUM("CANTIDAD") AS "TOTAL"
        FROM _detalles_factura WHERE "RELACIONADA" = 1 AND "COD_ALTERNO" IS NOT NULL GROUP BY "COD_ALTERNO"
    )
    UPDATE master."AlternateStock" a
    SET "StockQty" = COALESCE(a."StockQty", 0) + at2."TOTAL"
    FROM "AuxTotales" at2 WHERE at2."COD_ALTERNO" = a."ProductCode";

    -- 5. Anular CxC -> ar.ReceivableDocument
    UPDATE ar."ReceivableDocument"
    SET "PaidFlag" = TRUE, "PendingAmount" = 0, "Status" = 'VOIDED', "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "DocumentNumber" = p_num_fact AND "DocumentType" = 'FACT'
      AND "CompanyId" = v_default_company_id AND "BranchId" = v_default_branch_id;

    -- 6. Recalcular saldos -> master.Customer.TotalBalance
    IF v_customer_id IS NOT NULL THEN
        UPDATE master."Customer"
        SET "TotalBalance" = COALESCE((
            SELECT SUM("PendingAmount")
            FROM ar."ReceivableDocument"
            WHERE "CustomerId" = v_customer_id AND "Status" <> 'VOIDED' AND "PaidFlag" = FALSE
        ), 0)
        WHERE "CustomerId" = v_customer_id AND COALESCE("IsDeleted", FALSE) = FALSE;
    END IF;

    RETURN QUERY
    SELECT TRUE, p_num_fact, v_cod_cliente, 'Factura anulada exitosamente'::VARCHAR;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;
