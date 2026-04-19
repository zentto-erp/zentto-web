-- Migration: 00135_inv_conteo_fisico_albaranes.sql
-- Physical count (hoja de conteo), albaranes (delivery documents), multi-step transfer states
-- Sprint 2 — Inventario PR4

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. inv.HojaConteo — Physical count header
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inv."HojaConteo" (
    "HojaConteoId"  SERIAL       PRIMARY KEY,
    "CompanyId"     INT          NOT NULL,
    "WarehouseCode" VARCHAR(20)  NOT NULL,
    "Numero"        VARCHAR(30)  NOT NULL,                 -- human-readable ref
    "Estado"        VARCHAR(20)  NOT NULL DEFAULT 'BORRADOR',  -- BORRADOR | EN_PROCESO | APROBADA | CERRADA | CANCELADA
    "FechaConteo"   TIMESTAMP    NOT NULL DEFAULT NOW(),
    "FechaCierre"   TIMESTAMP    NULL,
    "ResponsableId" INT          NULL,
    "Notas"         TEXT         NULL,
    "CreatedAt"     TIMESTAMP    NOT NULL DEFAULT NOW(),
    "CreatedByUserId" INT        NULL,
    CONSTRAINT chk_hoja_estado CHECK ("Estado" IN ('BORRADOR','EN_PROCESO','APROBADA','CERRADA','CANCELADA')),
    CONSTRAINT uq_hoja_numero   UNIQUE ("CompanyId", "Numero")
);

CREATE INDEX IF NOT EXISTS idx_hoja_conteo_company ON inv."HojaConteo" ("CompanyId", "Estado");

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. inv.HojaConteoLinea — Physical count lines (one per SKU counted)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inv."HojaConteoLinea" (
    "LineaId"        SERIAL      PRIMARY KEY,
    "HojaConteoId"   INT         NOT NULL REFERENCES inv."HojaConteo"("HojaConteoId"),
    "ProductCode"    VARCHAR(50) NOT NULL,
    "StockSistema"   NUMERIC(14,4) NOT NULL DEFAULT 0,   -- snapshot at count start
    "StockFisico"    NUMERIC(14,4) NULL,                 -- entered by counter
    "Diferencia"     NUMERIC(14,4) GENERATED ALWAYS AS ("StockFisico" - "StockSistema") STORED,
    "UnitCost"       NUMERIC(14,4) NOT NULL DEFAULT 0,
    "Justificacion"  VARCHAR(500) NULL,
    "ContadoPorId"   INT         NULL,
    "ContadoAt"      TIMESTAMP   NULL,
    CONSTRAINT uq_hoja_linea    UNIQUE ("HojaConteoId", "ProductCode")
);

CREATE INDEX IF NOT EXISTS idx_hoja_linea_hoja ON inv."HojaConteoLinea" ("HojaConteoId");

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. inv.Albaran — Delivery/reception document with legal value
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inv."Albaran" (
    "AlbaranId"      SERIAL       PRIMARY KEY,
    "CompanyId"      INT          NOT NULL,
    "Numero"         VARCHAR(40)  NOT NULL,
    "Tipo"           VARCHAR(20)  NOT NULL DEFAULT 'DESPACHO',  -- DESPACHO | RECEPCION | TRASLADO
    "Estado"         VARCHAR(20)  NOT NULL DEFAULT 'BORRADOR',  -- BORRADOR | EMITIDO | FIRMADO | ANULADO
    "FechaEmision"   TIMESTAMP    NOT NULL DEFAULT NOW(),
    "FechaFirma"     TIMESTAMP    NULL,
    "WarehouseFrom"  VARCHAR(20)  NULL,
    "WarehouseTo"    VARCHAR(20)  NULL,
    "DestinatarioNombre" VARCHAR(200) NULL,
    "DestinatarioRif"    VARCHAR(30)  NULL,
    "DestinatarioDireccion" TEXT  NULL,
    "Observaciones"  TEXT         NULL,
    "FirmadoPorId"   INT          NULL,
    "FirmadoPorNombre" VARCHAR(200) NULL,
    "SourceDocumentType" VARCHAR(30) NULL,  -- ORDER | TRASLADO | CONTEO | MANUAL
    "SourceDocumentId"   INT          NULL,
    "ReportLayoutId" INT          NULL,     -- zentto-report layout reference
    "CreatedByUserId" INT         NULL,
    "CreatedAt"      TIMESTAMP    NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_albaran_tipo   CHECK ("Tipo"   IN ('DESPACHO','RECEPCION','TRASLADO')),
    CONSTRAINT chk_albaran_estado CHECK ("Estado" IN ('BORRADOR','EMITIDO','FIRMADO','ANULADO')),
    CONSTRAINT uq_albaran_numero  UNIQUE ("CompanyId", "Numero")
);

CREATE INDEX IF NOT EXISTS idx_albaran_company ON inv."Albaran" ("CompanyId", "Estado", "Tipo");
CREATE INDEX IF NOT EXISTS idx_albaran_fecha   ON inv."Albaran" ("CompanyId", "FechaEmision");

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. inv.AlbaranLinea — Line items of a delivery document
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inv."AlbaranLinea" (
    "AlbaranLineaId" SERIAL       PRIMARY KEY,
    "AlbaranId"      INT          NOT NULL REFERENCES inv."Albaran"("AlbaranId"),
    "ProductCode"    VARCHAR(50)  NOT NULL,
    "Descripcion"    VARCHAR(500) NULL,
    "Cantidad"       NUMERIC(14,4) NOT NULL,
    "Unidad"         VARCHAR(20)  NULL,
    "CostoUnitario"  NUMERIC(14,4) NOT NULL DEFAULT 0,
    "Lote"           VARCHAR(50)  NULL,
    "FechaVencimiento" DATE       NULL,
    "Observaciones"  VARCHAR(500) NULL
);

CREATE INDEX IF NOT EXISTS idx_albaran_linea_albaran ON inv."AlbaranLinea" ("AlbaranId");

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. inv.TrasladoMultiPaso — Tracked multi-step warehouse transfer
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inv."TrasladoMultiPaso" (
    "TrasladoId"     SERIAL       PRIMARY KEY,
    "CompanyId"      INT          NOT NULL,
    "Numero"         VARCHAR(40)  NOT NULL,
    "Estado"         VARCHAR(20)  NOT NULL DEFAULT 'BORRADOR',
    -- BORRADOR → PENDIENTE → EN_TRANSITO → RECIBIDO → CERRADO | CANCELADO
    "WarehouseFrom"  VARCHAR(20)  NOT NULL,
    "WarehouseTo"    VARCHAR(20)  NOT NULL,
    "FechaSolicitud" TIMESTAMP    NOT NULL DEFAULT NOW(),
    "FechaSalida"    TIMESTAMP    NULL,
    "FechaRecepcion" TIMESTAMP    NULL,
    "AlbaranSalidaId"  INT        NULL REFERENCES inv."Albaran"("AlbaranId"),
    "AlbaranEntradaId" INT        NULL REFERENCES inv."Albaran"("AlbaranId"),
    "Notas"          TEXT         NULL,
    "SolicitadoPorId"  INT        NULL,
    "AprobadoPorId"    INT        NULL,
    "RecibidoPorId"    INT        NULL,
    "CreatedAt"      TIMESTAMP    NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_traslado_estado CHECK ("Estado" IN ('BORRADOR','PENDIENTE','EN_TRANSITO','RECIBIDO','CERRADO','CANCELADO')),
    CONSTRAINT uq_traslado_numero  UNIQUE ("CompanyId", "Numero")
);

CREATE INDEX IF NOT EXISTS idx_traslado_company ON inv."TrasladoMultiPaso" ("CompanyId", "Estado");

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. inv.TrasladoMultiPasoLinea — Line items of a multi-step transfer
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inv."TrasladoMultiPasoLinea" (
    "TrasladoLineaId" SERIAL      PRIMARY KEY,
    "TrasladoId"      INT         NOT NULL REFERENCES inv."TrasladoMultiPaso"("TrasladoId"),
    "ProductCode"     VARCHAR(50) NOT NULL,
    "CantidadSolicitada" NUMERIC(14,4) NOT NULL,
    "CantidadDespachada" NUMERIC(14,4) NULL,
    "CantidadRecibida"   NUMERIC(14,4) NULL,
    "CostoUnitario"      NUMERIC(14,4) NOT NULL DEFAULT 0,
    "Observaciones"      VARCHAR(500) NULL,
    CONSTRAINT uq_traslado_linea UNIQUE ("TrasladoId", "ProductCode")
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. SEQUENCE helpers — numero generation
-- ─────────────────────────────────────────────────────────────────────────────
CREATE SEQUENCE IF NOT EXISTS inv.seq_hoja_conteo_numero START 1 INCREMENT 1;
CREATE SEQUENCE IF NOT EXISTS inv.seq_albaran_numero     START 1 INCREMENT 1;
CREATE SEQUENCE IF NOT EXISTS inv.seq_traslado_numero    START 1 INCREMENT 1;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. usp_inv_conteo_fisico_create — Create physical count sheet
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_inv_conteo_fisico_create(
    p_company_id      INT,
    p_warehouse_code  VARCHAR(20),
    p_user_id         INT,
    p_notas           TEXT DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "HojaConteoId" INT, "Numero" VARCHAR, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id      INT;
    v_numero  VARCHAR(30);
    v_seq     BIGINT;
BEGIN
    IF p_company_id IS NULL OR p_company_id <= 0 THEN
        RETURN QUERY SELECT FALSE, NULL::INT, NULL::VARCHAR, 'CompanyId requerido';
        RETURN;
    END IF;

    v_seq    := nextval('inv.seq_hoja_conteo_numero');
    v_numero := 'CNT-' || TO_CHAR(NOW(), 'YYYYMM') || '-' || LPAD(v_seq::TEXT, 5, '0');

    INSERT INTO inv."HojaConteo"
        ("CompanyId","WarehouseCode","Numero","Estado","FechaConteo","Notas","CreatedByUserId")
    VALUES
        (p_company_id, p_warehouse_code, v_numero, 'BORRADOR', NOW(), p_notas, p_user_id)
    RETURNING "HojaConteoId" INTO v_id;

    RETURN QUERY SELECT TRUE, v_id, v_numero, 'Hoja de conteo creada';
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 9. usp_inv_conteo_fisico_upsert_linea — Add/update count line
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_inv_conteo_fisico_upsert_linea(
    p_hoja_conteo_id  INT,
    p_product_code    VARCHAR(50),
    p_stock_fisico    NUMERIC(14,4),
    p_unit_cost       NUMERIC(14,4) DEFAULT 0,
    p_justificacion   VARCHAR(500)  DEFAULT NULL,
    p_user_id         INT           DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "LineaId" INT, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_linea_id  INT;
    v_stock_sis NUMERIC(14,4);
    v_estado    VARCHAR(20);
BEGIN
    SELECT h."Estado" INTO v_estado
    FROM inv."HojaConteo" h
    WHERE h."HojaConteoId" = p_hoja_conteo_id;

    IF v_estado IS NULL THEN
        RETURN QUERY SELECT FALSE, NULL::INT, 'Hoja de conteo no encontrada';
        RETURN;
    END IF;

    IF v_estado NOT IN ('BORRADOR','EN_PROCESO') THEN
        RETURN QUERY SELECT FALSE, NULL::INT, 'La hoja no está en estado editable';
        RETURN;
    END IF;

    -- Snapshot current logical stock for this company
    SELECT COALESCE(SUM(
        CASE WHEN sm."MovementType" IN ('PURCHASE_IN','TRANSFER_IN','ADJUSTMENT_IN') THEN sm."Quantity"
             WHEN sm."MovementType" IN ('SALE_OUT','TRANSFER_OUT','ADJUSTMENT_OUT') THEN -sm."Quantity"
             ELSE 0 END
    ), 0)
    INTO v_stock_sis
    FROM inv."StockMovement" sm
    JOIN inv."HojaConteo" hc ON hc."HojaConteoId" = p_hoja_conteo_id
    WHERE sm."ProductCode" = p_product_code
      AND sm."CompanyId"   = hc."CompanyId"
      AND sm."MovementDate" <= hc."FechaConteo";

    INSERT INTO inv."HojaConteoLinea"
        ("HojaConteoId","ProductCode","StockSistema","StockFisico","UnitCost","Justificacion","ContadoPorId","ContadoAt")
    VALUES
        (p_hoja_conteo_id, p_product_code, v_stock_sis, p_stock_fisico, p_unit_cost, p_justificacion, p_user_id, NOW())
    ON CONFLICT ("HojaConteoId","ProductCode") DO UPDATE
        SET "StockFisico"   = EXCLUDED."StockFisico",
            "UnitCost"      = EXCLUDED."UnitCost",
            "Justificacion" = EXCLUDED."Justificacion",
            "ContadoPorId"  = EXCLUDED."ContadoPorId",
            "ContadoAt"     = NOW()
    RETURNING "LineaId" INTO v_linea_id;

    RETURN QUERY SELECT TRUE, v_linea_id, 'Línea guardada';
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 10. usp_inv_conteo_fisico_close — Approve count and generate AJUSTE movements
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_inv_conteo_fisico_close(
    p_hoja_conteo_id  INT,
    p_company_id      INT,
    p_user_id         INT
)
RETURNS TABLE("ok" BOOLEAN, "AjustesGenerados" INT, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_ajustes   INT := 0;
    v_estado    VARCHAR(20);
    v_warehouse VARCHAR(20);
    rec         RECORD;
BEGIN
    SELECT h."Estado", h."WarehouseCode"
    INTO v_estado, v_warehouse
    FROM inv."HojaConteo" h
    WHERE h."HojaConteoId" = p_hoja_conteo_id
      AND h."CompanyId"    = p_company_id;

    IF v_estado IS NULL THEN
        RETURN QUERY SELECT FALSE, 0, 'Hoja de conteo no encontrada';
        RETURN;
    END IF;

    IF v_estado NOT IN ('BORRADOR','EN_PROCESO','APROBADA') THEN
        RETURN QUERY SELECT FALSE, 0, 'La hoja no puede cerrarse desde estado: ' || v_estado;
        RETURN;
    END IF;

    -- Generate AJUSTE movement for every line with non-zero difference
    FOR rec IN
        SELECT l."ProductCode", l."Diferencia", l."UnitCost"
        FROM inv."HojaConteoLinea" l
        WHERE l."HojaConteoId" = p_hoja_conteo_id
          AND l."StockFisico"  IS NOT NULL
          AND l."Diferencia"   <> 0
    LOOP
        INSERT INTO inv."StockMovement"
            ("CompanyId","ProductCode","MovementType","Quantity","UnitCost",
             "WarehouseCode","SourceDocumentType","SourceDocumentId",
             "MovementDate","CreatedByUserId","Notes")
        VALUES (
            p_company_id,
            rec."ProductCode",
            CASE WHEN rec."Diferencia" > 0 THEN 'ADJUSTMENT_IN' ELSE 'ADJUSTMENT_OUT' END,
            ABS(rec."Diferencia"),
            rec."UnitCost",
            v_warehouse,
            'CONTEO_FISICO',
            p_hoja_conteo_id,
            NOW(),
            p_user_id,
            'Ajuste por conteo físico CNT#' || p_hoja_conteo_id
        );
        v_ajustes := v_ajustes + 1;
    END LOOP;

    UPDATE inv."HojaConteo"
    SET "Estado" = 'CERRADA', "FechaCierre" = NOW()
    WHERE "HojaConteoId" = p_hoja_conteo_id;

    RETURN QUERY SELECT TRUE, v_ajustes, 'Conteo cerrado. Ajustes generados: ' || v_ajustes;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 11. usp_inv_conteo_fisico_list — List physical count sheets (paginated)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_inv_conteo_fisico_list(
    p_company_id     INT,
    p_estado         VARCHAR(20) DEFAULT NULL,
    p_warehouse_code VARCHAR(20) DEFAULT NULL,
    p_page           INT         DEFAULT 1,
    p_limit          INT         DEFAULT 50
)
RETURNS TABLE(
    "HojaConteoId"   INT,
    "Numero"         VARCHAR,
    "WarehouseCode"  VARCHAR,
    "Estado"         VARCHAR,
    "FechaConteo"    TIMESTAMP,
    "FechaCierre"    TIMESTAMP,
    "TotalLineas"    BIGINT,
    "LineasContadas" BIGINT,
    "TotalCount"     BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT := (GREATEST(1, p_page) - 1) * LEAST(GREATEST(1, p_limit), 500);
    v_limit  INT := LEAST(GREATEST(1, p_limit), 500);
BEGIN
    RETURN QUERY
    SELECT
        h."HojaConteoId",
        h."Numero"::VARCHAR,
        h."WarehouseCode"::VARCHAR,
        h."Estado"::VARCHAR,
        h."FechaConteo",
        h."FechaCierre",
        COUNT(l."LineaId"),
        COUNT(l."LineaId") FILTER (WHERE l."StockFisico" IS NOT NULL),
        COUNT(*) OVER () AS "TotalCount"
    FROM inv."HojaConteo" h
    LEFT JOIN inv."HojaConteoLinea" l ON l."HojaConteoId" = h."HojaConteoId"
    WHERE h."CompanyId" = p_company_id
      AND (p_estado         IS NULL OR h."Estado"         = p_estado)
      AND (p_warehouse_code IS NULL OR h."WarehouseCode"  = p_warehouse_code)
    GROUP BY h."HojaConteoId"
    ORDER BY h."FechaConteo" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 12. usp_inv_albaran_create — Create delivery/reception document
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_inv_albaran_create(
    p_company_id       INT,
    p_tipo             VARCHAR(20),
    p_warehouse_from   VARCHAR(20)  DEFAULT NULL,
    p_warehouse_to     VARCHAR(20)  DEFAULT NULL,
    p_destinatario_nombre VARCHAR(200) DEFAULT NULL,
    p_destinatario_rif    VARCHAR(30)  DEFAULT NULL,
    p_source_type      VARCHAR(30)  DEFAULT NULL,
    p_source_id        INT          DEFAULT NULL,
    p_observaciones    TEXT         DEFAULT NULL,
    p_user_id          INT          DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "AlbaranId" INT, "Numero" VARCHAR, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id     INT;
    v_numero VARCHAR(40);
    v_seq    BIGINT;
BEGIN
    IF p_company_id IS NULL OR p_company_id <= 0 THEN
        RETURN QUERY SELECT FALSE, NULL::INT, NULL::VARCHAR, 'CompanyId requerido';
        RETURN;
    END IF;

    IF p_tipo NOT IN ('DESPACHO','RECEPCION','TRASLADO') THEN
        RETURN QUERY SELECT FALSE, NULL::INT, NULL::VARCHAR, 'Tipo inválido: ' || COALESCE(p_tipo,'NULL');
        RETURN;
    END IF;

    v_seq    := nextval('inv.seq_albaran_numero');
    v_numero := CASE p_tipo
        WHEN 'DESPACHO'  THEN 'ALB-D-'
        WHEN 'RECEPCION' THEN 'ALB-R-'
        ELSE                  'ALB-T-'
    END || TO_CHAR(NOW(), 'YYYYMM') || '-' || LPAD(v_seq::TEXT, 5, '0');

    INSERT INTO inv."Albaran"
        ("CompanyId","Numero","Tipo","Estado","FechaEmision",
         "WarehouseFrom","WarehouseTo",
         "DestinatarioNombre","DestinatarioRif",
         "SourceDocumentType","SourceDocumentId",
         "Observaciones","CreatedByUserId")
    VALUES
        (p_company_id, v_numero, p_tipo, 'BORRADOR', NOW(),
         p_warehouse_from, p_warehouse_to,
         p_destinatario_nombre, p_destinatario_rif,
         p_source_type, p_source_id,
         p_observaciones, p_user_id)
    RETURNING "AlbaranId" INTO v_id;

    RETURN QUERY SELECT TRUE, v_id, v_numero, 'Albarán creado';
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 13. usp_inv_albaran_add_linea — Add line to albarán
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_inv_albaran_add_linea(
    p_albaran_id    INT,
    p_product_code  VARCHAR(50),
    p_cantidad      NUMERIC(14,4),
    p_unidad        VARCHAR(20)  DEFAULT NULL,
    p_costo         NUMERIC(14,4) DEFAULT 0,
    p_lote          VARCHAR(50)  DEFAULT NULL,
    p_vencimiento   DATE         DEFAULT NULL,
    p_observaciones VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "AlbaranLineaId" INT, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id     INT;
    v_estado VARCHAR(20);
BEGIN
    SELECT "Estado" INTO v_estado FROM inv."Albaran" WHERE "AlbaranId" = p_albaran_id;
    IF v_estado IS NULL THEN
        RETURN QUERY SELECT FALSE, NULL::INT, 'Albarán no encontrado';
        RETURN;
    END IF;
    IF v_estado NOT IN ('BORRADOR') THEN
        RETURN QUERY SELECT FALSE, NULL::INT, 'El albarán no está en estado BORRADOR';
        RETURN;
    END IF;

    INSERT INTO inv."AlbaranLinea"
        ("AlbaranId","ProductCode","Cantidad","Unidad","CostoUnitario","Lote","FechaVencimiento","Observaciones")
    VALUES
        (p_albaran_id, p_product_code, p_cantidad, p_unidad, p_costo, p_lote, p_vencimiento, p_observaciones)
    RETURNING "AlbaranLineaId" INTO v_id;

    RETURN QUERY SELECT TRUE, v_id, 'Línea agregada';
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 14. usp_inv_albaran_emit — Emit albarán (BORRADOR → EMITIDO)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_inv_albaran_emit(
    p_albaran_id INT,
    p_company_id INT,
    p_user_id    INT
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_estado VARCHAR(20);
    v_lineas INT;
BEGIN
    SELECT "Estado" INTO v_estado
    FROM inv."Albaran"
    WHERE "AlbaranId" = p_albaran_id AND "CompanyId" = p_company_id;

    IF v_estado IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Albarán no encontrado';
        RETURN;
    END IF;
    IF v_estado <> 'BORRADOR' THEN
        RETURN QUERY SELECT FALSE, 'Solo se puede emitir desde estado BORRADOR';
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_lineas
    FROM inv."AlbaranLinea" WHERE "AlbaranId" = p_albaran_id;

    IF v_lineas = 0 THEN
        RETURN QUERY SELECT FALSE, 'El albarán no tiene líneas';
        RETURN;
    END IF;

    UPDATE inv."Albaran"
    SET "Estado" = 'EMITIDO', "FechaEmision" = NOW()
    WHERE "AlbaranId" = p_albaran_id;

    RETURN QUERY SELECT TRUE, 'Albarán emitido';
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 15. usp_inv_albaran_sign — Digitally sign albarán (EMITIDO → FIRMADO)
--     Signing triggers stock movement for DESPACHO/RECEPCION
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_inv_albaran_sign(
    p_albaran_id  INT,
    p_company_id  INT,
    p_user_id     INT,
    p_firmante    VARCHAR(200) DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "MovimientosGenerados" INT, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_estado   VARCHAR(20);
    v_tipo     VARCHAR(20);
    v_whfrom   VARCHAR(20);
    v_whto     VARCHAR(20);
    v_albnum   VARCHAR(40);
    v_movs     INT := 0;
    rec        RECORD;
    v_movtype  VARCHAR(30);
    v_whcode   VARCHAR(20);
BEGIN
    SELECT "Estado","Tipo","WarehouseFrom","WarehouseTo","Numero"
    INTO v_estado, v_tipo, v_whfrom, v_whto, v_albnum
    FROM inv."Albaran"
    WHERE "AlbaranId" = p_albaran_id AND "CompanyId" = p_company_id;

    IF v_estado IS NULL THEN
        RETURN QUERY SELECT FALSE, 0, 'Albarán no encontrado';
        RETURN;
    END IF;
    IF v_estado <> 'EMITIDO' THEN
        RETURN QUERY SELECT FALSE, 0, 'Solo se puede firmar desde estado EMITIDO';
        RETURN;
    END IF;

    -- Determine movement type and warehouse
    IF v_tipo = 'DESPACHO' THEN
        v_movtype := 'SALE_OUT';
        v_whcode  := COALESCE(v_whfrom, 'PRINCIPAL');
    ELSIF v_tipo = 'RECEPCION' THEN
        v_movtype := 'PURCHASE_IN';
        v_whcode  := COALESCE(v_whto, 'PRINCIPAL');
    ELSE
        -- TRASLADO: movements handled by TrasladoMultiPaso workflow
        v_movtype := NULL;
        v_whcode  := NULL;
    END IF;

    IF v_movtype IS NOT NULL THEN
        FOR rec IN
            SELECT l."ProductCode", l."Cantidad", l."CostoUnitario"
            FROM inv."AlbaranLinea" l
            WHERE l."AlbaranId" = p_albaran_id
        LOOP
            INSERT INTO inv."StockMovement"
                ("CompanyId","ProductCode","MovementType","Quantity","UnitCost",
                 "WarehouseCode","SourceDocumentType","SourceDocumentId",
                 "MovementDate","CreatedByUserId","Notes")
            VALUES (
                p_company_id, rec."ProductCode", v_movtype,
                rec."Cantidad", rec."CostoUnitario",
                v_whcode, 'ALBARAN', p_albaran_id,
                NOW(), p_user_id, 'Albarán ' || v_albnum
            );
            v_movs := v_movs + 1;
        END LOOP;
    END IF;

    UPDATE inv."Albaran"
    SET "Estado"          = 'FIRMADO',
        "FechaFirma"      = NOW(),
        "FirmadoPorId"    = p_user_id,
        "FirmadoPorNombre" = COALESCE(p_firmante, 'Usuario #' || p_user_id)
    WHERE "AlbaranId" = p_albaran_id;

    RETURN QUERY SELECT TRUE, v_movs, 'Albarán firmado. Movimientos generados: ' || v_movs;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 16. usp_inv_traslado_create — Create multi-step warehouse transfer
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_inv_traslado_create(
    p_company_id     INT,
    p_warehouse_from VARCHAR(20),
    p_warehouse_to   VARCHAR(20),
    p_user_id        INT,
    p_notas          TEXT DEFAULT NULL
)
RETURNS TABLE("ok" BOOLEAN, "TrasladoId" INT, "Numero" VARCHAR, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_id     INT;
    v_numero VARCHAR(40);
    v_seq    BIGINT;
BEGIN
    IF p_company_id IS NULL OR p_company_id <= 0 THEN
        RETURN QUERY SELECT FALSE, NULL::INT, NULL::VARCHAR, 'CompanyId requerido';
        RETURN;
    END IF;
    IF p_warehouse_from = p_warehouse_to THEN
        RETURN QUERY SELECT FALSE, NULL::INT, NULL::VARCHAR, 'WarehouseFrom y WarehouseTo no pueden ser iguales';
        RETURN;
    END IF;

    v_seq    := nextval('inv.seq_traslado_numero');
    v_numero := 'TRL-' || TO_CHAR(NOW(), 'YYYYMM') || '-' || LPAD(v_seq::TEXT, 5, '0');

    INSERT INTO inv."TrasladoMultiPaso"
        ("CompanyId","Numero","Estado","WarehouseFrom","WarehouseTo",
         "FechaSolicitud","Notas","SolicitadoPorId")
    VALUES
        (p_company_id, v_numero, 'BORRADOR', p_warehouse_from, p_warehouse_to,
         NOW(), p_notas, p_user_id)
    RETURNING "TrasladoId" INTO v_id;

    RETURN QUERY SELECT TRUE, v_id, v_numero, 'Traslado creado';
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 17. usp_inv_traslado_advance — Advance multi-step transfer state machine
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_inv_traslado_advance(
    p_traslado_id INT,
    p_company_id  INT,
    p_user_id     INT,
    p_action      VARCHAR(20)  -- APROBAR | DESPACHAR | RECIBIR | CANCELAR
)
RETURNS TABLE("ok" BOOLEAN, "NuevoEstado" VARCHAR, "AlbaranId" INT, "mensaje" TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    v_estado    VARCHAR(20);
    v_whfrom    VARCHAR(20);
    v_whto      VARCHAR(20);
    v_numero    VARCHAR(40);
    v_alb_id    INT;
    v_nuevo_est VARCHAR(20);
    rec         RECORD;
BEGIN
    SELECT t."Estado", t."WarehouseFrom", t."WarehouseTo", t."Numero"
    INTO v_estado, v_whfrom, v_whto, v_numero
    FROM inv."TrasladoMultiPaso" t
    WHERE t."TrasladoId" = p_traslado_id AND t."CompanyId" = p_company_id;

    IF v_estado IS NULL THEN
        RETURN QUERY SELECT FALSE, NULL::VARCHAR, NULL::INT, 'Traslado no encontrado';
        RETURN;
    END IF;

    -- State machine validation
    IF p_action = 'APROBAR' AND v_estado = 'BORRADOR' THEN
        v_nuevo_est := 'PENDIENTE';
        UPDATE inv."TrasladoMultiPaso"
        SET "Estado" = 'PENDIENTE', "AprobadoPorId" = p_user_id
        WHERE "TrasladoId" = p_traslado_id;

    ELSIF p_action = 'DESPACHAR' AND v_estado = 'PENDIENTE' THEN
        -- Create exit albarán and stock movements (TRANSFER_OUT)
        SELECT a."AlbaranId" INTO v_alb_id
        FROM usp_inv_albaran_create(
            p_company_id, 'TRASLADO', v_whfrom, v_whto,
            NULL, NULL, 'TRASLADO', p_traslado_id, 'Salida TRL ' || v_numero, p_user_id
        ) a;

        FOR rec IN
            SELECT l."ProductCode", l."CantidadSolicitada", l."CostoUnitario"
            FROM inv."TrasladoMultiPasoLinea" l
            WHERE l."TrasladoId" = p_traslado_id
        LOOP
            PERFORM usp_inv_albaran_add_linea(v_alb_id, rec."ProductCode", rec."CantidadSolicitada", NULL, rec."CostoUnitario");

            INSERT INTO inv."StockMovement"
                ("CompanyId","ProductCode","MovementType","Quantity","UnitCost",
                 "WarehouseCode","SourceDocumentType","SourceDocumentId",
                 "MovementDate","CreatedByUserId","Notes")
            VALUES (
                p_company_id, rec."ProductCode", 'TRANSFER_OUT',
                rec."CantidadSolicitada", rec."CostoUnitario",
                v_whfrom, 'TRASLADO', p_traslado_id,
                NOW(), p_user_id, 'Salida traslado ' || v_numero
            );

            UPDATE inv."TrasladoMultiPasoLinea"
            SET "CantidadDespachada" = "CantidadSolicitada"
            WHERE "TrasladoId" = p_traslado_id AND "ProductCode" = rec."ProductCode";
        END LOOP;

        UPDATE inv."TrasladoMultiPaso"
        SET "Estado" = 'EN_TRANSITO', "FechaSalida" = NOW(),
            "AlbaranSalidaId" = v_alb_id
        WHERE "TrasladoId" = p_traslado_id;
        v_nuevo_est := 'EN_TRANSITO';

    ELSIF p_action = 'RECIBIR' AND v_estado = 'EN_TRANSITO' THEN
        -- Create reception albarán and stock movements (TRANSFER_IN)
        SELECT a."AlbaranId" INTO v_alb_id
        FROM usp_inv_albaran_create(
            p_company_id, 'TRASLADO', v_whfrom, v_whto,
            NULL, NULL, 'TRASLADO', p_traslado_id, 'Entrada TRL ' || v_numero, p_user_id
        ) a;

        FOR rec IN
            SELECT l."ProductCode", l."CantidadDespachada", l."CostoUnitario"
            FROM inv."TrasladoMultiPasoLinea" l
            WHERE l."TrasladoId" = p_traslado_id
        LOOP
            PERFORM usp_inv_albaran_add_linea(v_alb_id, rec."ProductCode", COALESCE(rec."CantidadDespachada",0), NULL, rec."CostoUnitario");

            INSERT INTO inv."StockMovement"
                ("CompanyId","ProductCode","MovementType","Quantity","UnitCost",
                 "WarehouseCode","SourceDocumentType","SourceDocumentId",
                 "MovementDate","CreatedByUserId","Notes")
            VALUES (
                p_company_id, rec."ProductCode", 'TRANSFER_IN',
                COALESCE(rec."CantidadDespachada",0), rec."CostoUnitario",
                v_whto, 'TRASLADO', p_traslado_id,
                NOW(), p_user_id, 'Entrada traslado ' || v_numero
            );

            UPDATE inv."TrasladoMultiPasoLinea"
            SET "CantidadRecibida" = "CantidadDespachada"
            WHERE "TrasladoId" = p_traslado_id AND "ProductCode" = rec."ProductCode";
        END LOOP;

        UPDATE inv."TrasladoMultiPaso"
        SET "Estado" = 'RECIBIDO', "FechaRecepcion" = NOW(),
            "AlbaranEntradaId" = v_alb_id, "RecibidoPorId" = p_user_id
        WHERE "TrasladoId" = p_traslado_id;
        v_nuevo_est := 'RECIBIDO';

    ELSIF p_action = 'CANCELAR' AND v_estado IN ('BORRADOR','PENDIENTE') THEN
        UPDATE inv."TrasladoMultiPaso"
        SET "Estado" = 'CANCELADO'
        WHERE "TrasladoId" = p_traslado_id;
        v_nuevo_est := 'CANCELADO';

    ELSE
        RETURN QUERY SELECT FALSE, v_estado, NULL::INT,
            'Acción ' || p_action || ' no válida desde estado ' || v_estado;
        RETURN;
    END IF;

    RETURN QUERY SELECT TRUE, v_nuevo_est, v_alb_id, 'Traslado avanzado a ' || v_nuevo_est;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 18. usp_inv_albaran_list — List albaranes (paginated)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION usp_inv_albaran_list(
    p_company_id INT,
    p_tipo       VARCHAR(20) DEFAULT NULL,
    p_estado     VARCHAR(20) DEFAULT NULL,
    p_fecha_desde TIMESTAMP  DEFAULT NULL,
    p_fecha_hasta TIMESTAMP  DEFAULT NULL,
    p_page       INT         DEFAULT 1,
    p_limit      INT         DEFAULT 50
)
RETURNS TABLE(
    "AlbaranId"   INT,
    "Numero"      VARCHAR,
    "Tipo"        VARCHAR,
    "Estado"      VARCHAR,
    "FechaEmision" TIMESTAMP,
    "WarehouseFrom" VARCHAR,
    "WarehouseTo"   VARCHAR,
    "DestinatarioNombre" VARCHAR,
    "TotalLineas"   BIGINT,
    "TotalCount"    BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT := (GREATEST(1, p_page) - 1) * LEAST(GREATEST(1, p_limit), 500);
    v_limit  INT := LEAST(GREATEST(1, p_limit), 500);
BEGIN
    RETURN QUERY
    SELECT
        a."AlbaranId",
        a."Numero"::VARCHAR,
        a."Tipo"::VARCHAR,
        a."Estado"::VARCHAR,
        a."FechaEmision",
        a."WarehouseFrom"::VARCHAR,
        a."WarehouseTo"::VARCHAR,
        a."DestinatarioNombre"::VARCHAR,
        COUNT(l."AlbaranLineaId"),
        COUNT(*) OVER () AS "TotalCount"
    FROM inv."Albaran" a
    LEFT JOIN inv."AlbaranLinea" l ON l."AlbaranId" = a."AlbaranId"
    WHERE a."CompanyId" = p_company_id
      AND (p_tipo        IS NULL OR a."Tipo"         = p_tipo)
      AND (p_estado      IS NULL OR a."Estado"        = p_estado)
      AND (p_fecha_desde IS NULL OR a."FechaEmision" >= p_fecha_desde)
      AND (p_fecha_hasta IS NULL OR a."FechaEmision" <= p_fecha_hasta)
    GROUP BY a."AlbaranId"
    ORDER BY a."FechaEmision" DESC
    LIMIT v_limit OFFSET v_offset;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- SQL Server equivalents are in web/api/sqlweb/includes/sp/ (see PR notes)
-- ─────────────────────────────────────────────────────────────────────────────
