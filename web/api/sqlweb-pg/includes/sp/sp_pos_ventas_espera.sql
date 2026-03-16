-- ═══════════════════════════════════════════════════════════════════
-- DatqBox POS — Ventas en Espera (multi-estacion)
-- Traducido de SQL Server a PostgreSQL
-- ═══════════════════════════════════════════════════════════════════

-- =============================================
-- 1. TABLA: Ventas en Espera (header)
-- =============================================
CREATE TABLE IF NOT EXISTS "PosVentasEnEspera" (
    "Id"              SERIAL PRIMARY KEY,
    "CajaId"          VARCHAR(10) NOT NULL,
    "EstacionNombre"  VARCHAR(50) NULL,
    "CodUsuario"      VARCHAR(10) NULL,
    "ClienteId"       VARCHAR(12) NULL,
    "ClienteNombre"   VARCHAR(100) NULL,
    "ClienteRif"      VARCHAR(20) NULL,
    "TipoPrecio"      VARCHAR(20) NOT NULL DEFAULT 'Detal',
    "Motivo"          VARCHAR(200) NULL,
    "Subtotal"        NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Descuento"       NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Impuestos"       NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Total"           NUMERIC(18,2) NOT NULL DEFAULT 0,
    "FechaCreacion"   TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "Estado"          VARCHAR(20) NOT NULL DEFAULT 'espera',
    "RecuperadoPor"   VARCHAR(10) NULL,
    "RecuperadoEn"    VARCHAR(10) NULL,
    "FechaRecuperado" TIMESTAMP NULL,
    CONSTRAINT "CK_PosEspera_Estado" CHECK ("Estado" IN ('espera', 'recuperado', 'anulado'))
);

-- =============================================
-- 2. TABLA: Detalle de la venta en espera
-- =============================================
CREATE TABLE IF NOT EXISTS "PosVentasEnEsperaDetalle" (
    "Id"              SERIAL PRIMARY KEY,
    "VentaEsperaId"   INT NOT NULL,
    "ProductoId"      VARCHAR(15) NOT NULL,
    "Codigo"          VARCHAR(30) NULL,
    "Nombre"          VARCHAR(200) NOT NULL,
    "Cantidad"        NUMERIC(10,3) NOT NULL,
    "PrecioUnitario"  NUMERIC(18,2) NOT NULL,
    "Descuento"       NUMERIC(18,2) NOT NULL DEFAULT 0,
    "IVA"             NUMERIC(5,2) NOT NULL DEFAULT 16,
    "Subtotal"        NUMERIC(18,2) NOT NULL,
    "Orden"           INT NOT NULL DEFAULT 0,
    CONSTRAINT "FK_PosEsperaDetalle_Espera" FOREIGN KEY ("VentaEsperaId") REFERENCES "PosVentasEnEspera"("Id") ON DELETE CASCADE
);

-- =============================================
-- 3. TABLA: Ventas completadas (facturadas)
-- =============================================
CREATE TABLE IF NOT EXISTS "PosVentas" (
    "Id"              SERIAL PRIMARY KEY,
    "NumFactura"      VARCHAR(20) NOT NULL,
    "CajaId"          VARCHAR(10) NOT NULL,
    "CodUsuario"      VARCHAR(10) NULL,
    "ClienteId"       VARCHAR(12) NULL,
    "ClienteNombre"   VARCHAR(100) NULL,
    "ClienteRif"      VARCHAR(20) NULL,
    "TipoPrecio"      VARCHAR(20) NOT NULL DEFAULT 'Detal',
    "Subtotal"        NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Descuento"       NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Impuestos"       NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Total"           NUMERIC(18,2) NOT NULL DEFAULT 0,
    "MetodoPago"      VARCHAR(50) NULL,
    "FechaVenta"      TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "TramaFiscal"     TEXT NULL,
    "EsperaOrigenId"  INT NULL,
    CONSTRAINT "UQ_PosVentas_NumFact" UNIQUE ("NumFactura")
);

CREATE TABLE IF NOT EXISTS "PosVentasDetalle" (
    "Id"              SERIAL PRIMARY KEY,
    "VentaId"         INT NOT NULL,
    "ProductoId"      VARCHAR(15) NOT NULL,
    "Codigo"          VARCHAR(30) NULL,
    "Nombre"          VARCHAR(200) NOT NULL,
    "Cantidad"        NUMERIC(10,3) NOT NULL,
    "PrecioUnitario"  NUMERIC(18,2) NOT NULL,
    "Descuento"       NUMERIC(18,2) NOT NULL DEFAULT 0,
    "IVA"             NUMERIC(5,2) NOT NULL DEFAULT 16,
    "Subtotal"        NUMERIC(18,2) NOT NULL,
    CONSTRAINT "FK_PosVentaDetalle_Venta" FOREIGN KEY ("VentaId") REFERENCES "PosVentas"("Id") ON DELETE CASCADE
);

-- ═══════════════════════════════════════════════════════════════════
-- FUNCIONES
-- ═══════════════════════════════════════════════════════════════════

-- ─── PONER EN ESPERA ───
CREATE OR REPLACE FUNCTION usp_pos_espera_crear(
    p_caja_id          VARCHAR(10),
    p_estacion_nombre  VARCHAR(50) DEFAULT NULL,
    p_cod_usuario      VARCHAR(10) DEFAULT NULL,
    p_cliente_id       VARCHAR(12) DEFAULT NULL,
    p_cliente_nombre   VARCHAR(100) DEFAULT NULL,
    p_cliente_rif      VARCHAR(20) DEFAULT NULL,
    p_tipo_precio      VARCHAR(20) DEFAULT 'Detal',
    p_motivo           VARCHAR(200) DEFAULT NULL,
    p_detalle_json     JSONB DEFAULT '[]'::JSONB
)
RETURNS TABLE(
    "EsperaId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_espera_id INT;
BEGIN
    INSERT INTO "PosVentasEnEspera" ("CajaId", "EstacionNombre", "CodUsuario", "ClienteId", "ClienteNombre", "ClienteRif", "TipoPrecio", "Motivo")
    VALUES (p_caja_id, p_estacion_nombre, p_cod_usuario, p_cliente_id, p_cliente_nombre, p_cliente_rif, p_tipo_precio, p_motivo)
    RETURNING "Id" INTO v_espera_id;

    INSERT INTO "PosVentasEnEsperaDetalle" ("VentaEsperaId", "ProductoId", "Codigo", "Nombre", "Cantidad", "PrecioUnitario", "Descuento", "IVA", "Subtotal", "Orden")
    SELECT
        v_espera_id,
        (item->>'prodId')::VARCHAR(15),
        (item->>'cod')::VARCHAR(30),
        (item->>'nom')::VARCHAR(200),
        (item->>'cant')::NUMERIC(10,3),
        (item->>'precio')::NUMERIC(18,2),
        COALESCE((item->>'desc')::NUMERIC(18,2), 0),
        COALESCE((item->>'iva')::NUMERIC(5,2), 16),
        (item->>'sub')::NUMERIC(18,2),
        COALESCE((item->>'ord')::INT, 0)
    FROM jsonb_array_elements(p_detalle_json) AS item;

    -- Calcular totales
    UPDATE "PosVentasEnEspera" SET
        "Subtotal"  = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id),
        "Descuento" = (SELECT COALESCE(SUM("Descuento" * "Cantidad"), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id),
        "Impuestos" = (SELECT COALESCE(SUM("Subtotal" * "IVA" / 100), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id),
        "Total"     = (SELECT COALESCE(SUM("Subtotal" + "Subtotal" * "IVA" / 100), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id)
    WHERE "Id" = v_espera_id;

    RETURN QUERY SELECT v_espera_id AS "EsperaId";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;

-- ─── LISTAR EN ESPERA (visible para todas las estaciones) ───
CREATE OR REPLACE FUNCTION usp_pos_espera_list()
RETURNS TABLE(
    "id"              INT,
    "cajaId"          VARCHAR,
    "estacionNombre"  VARCHAR,
    "codUsuario"      VARCHAR,
    "clienteNombre"   VARCHAR,
    "clienteRif"      VARCHAR,
    "tipoPrecio"      VARCHAR,
    "motivo"          VARCHAR,
    "total"           NUMERIC,
    "fechaCreacion"   TIMESTAMP,
    "cantItems"       BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."Id",
        e."CajaId",
        e."EstacionNombre",
        e."CodUsuario",
        e."ClienteNombre",
        e."ClienteRif",
        e."TipoPrecio",
        e."Motivo",
        e."Total",
        e."FechaCreacion",
        (SELECT COUNT(1) FROM "PosVentasEnEsperaDetalle" d WHERE d."VentaEsperaId" = e."Id")
    FROM "PosVentasEnEspera" e
    WHERE e."Estado" = 'espera'
    ORDER BY e."FechaCreacion" ASC;
END;
$$;

-- ─── RECUPERAR (trae header + detalle; marca como recuperado) ───
-- Nota: PostgreSQL no soporta múltiples result sets nativamente.
-- Se divide en dos funciones: header y detalle, más la función de marcado.

CREATE OR REPLACE FUNCTION usp_pos_espera_recuperar_header(
    p_id              INT,
    p_recuperado_por  VARCHAR(10) DEFAULT NULL,
    p_recuperado_en   VARCHAR(10) DEFAULT NULL
)
RETURNS TABLE(
    "id"             INT,
    "cajaId"         VARCHAR,
    "clienteId"      VARCHAR,
    "clienteNombre"  VARCHAR,
    "clienteRif"     VARCHAR,
    "tipoPrecio"     VARCHAR,
    "motivo"         VARCHAR,
    "subtotal"       NUMERIC,
    "descuento"      NUMERIC,
    "impuestos"      NUMERIC,
    "total"          NUMERIC,
    "fechaCreacion"  TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."Id", e."CajaId", e."ClienteId",
        e."ClienteNombre", e."ClienteRif",
        e."TipoPrecio", e."Motivo",
        e."Subtotal", e."Descuento",
        e."Impuestos", e."Total", e."FechaCreacion"
    FROM "PosVentasEnEspera" e
    WHERE e."Id" = p_id AND e."Estado" = 'espera';

    -- Marcar como recuperado
    UPDATE "PosVentasEnEspera" SET
        "Estado" = 'recuperado',
        "RecuperadoPor" = p_recuperado_por,
        "RecuperadoEn" = p_recuperado_en,
        "FechaRecuperado" = NOW() AT TIME ZONE 'UTC'
    WHERE "Id" = p_id AND "Estado" = 'espera';
END;
$$;

CREATE OR REPLACE FUNCTION usp_pos_espera_recuperar_detalle(
    p_id INT
)
RETURNS TABLE(
    "id"              INT,
    "productoId"      VARCHAR,
    "codigo"          VARCHAR,
    "nombre"          VARCHAR,
    "cantidad"        NUMERIC,
    "precioUnitario"  NUMERIC,
    "descuento"       NUMERIC,
    "iva"             NUMERIC,
    "subtotal"        NUMERIC,
    "orden"           INT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."Id", d."ProductoId", d."Codigo",
        d."Nombre", d."Cantidad", d."PrecioUnitario",
        d."Descuento", d."IVA", d."Subtotal", d."Orden"
    FROM "PosVentasEnEsperaDetalle" d
    WHERE d."VentaEsperaId" = p_id
    ORDER BY d."Orden";
END;
$$;

-- ─── ANULAR ESPERA ───
CREATE OR REPLACE FUNCTION usp_pos_espera_anular(
    p_id INT
)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "PosVentasEnEspera" SET "Estado" = 'anulado' WHERE "Id" = p_id AND "Estado" = 'espera';
END;
$$;

-- ─── REGISTRAR VENTA COMPLETADA ───
CREATE OR REPLACE FUNCTION usp_pos_venta_crear(
    p_num_factura      VARCHAR(20),
    p_caja_id          VARCHAR(10),
    p_cod_usuario      VARCHAR(10) DEFAULT NULL,
    p_cliente_id       VARCHAR(12) DEFAULT NULL,
    p_cliente_nombre   VARCHAR(100) DEFAULT NULL,
    p_cliente_rif      VARCHAR(20) DEFAULT NULL,
    p_tipo_precio      VARCHAR(20) DEFAULT 'Detal',
    p_metodo_pago      VARCHAR(50) DEFAULT NULL,
    p_trama_fiscal     TEXT DEFAULT NULL,
    p_espera_origen_id INT DEFAULT NULL,
    p_detalle_json     JSONB DEFAULT '[]'::JSONB
)
RETURNS TABLE(
    "VentaId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_venta_id INT;
BEGIN
    INSERT INTO "PosVentas" ("NumFactura", "CajaId", "CodUsuario", "ClienteId", "ClienteNombre", "ClienteRif", "TipoPrecio", "MetodoPago", "TramaFiscal", "EsperaOrigenId")
    VALUES (p_num_factura, p_caja_id, p_cod_usuario, p_cliente_id, p_cliente_nombre, p_cliente_rif, p_tipo_precio, p_metodo_pago, p_trama_fiscal, p_espera_origen_id)
    RETURNING "Id" INTO v_venta_id;

    INSERT INTO "PosVentasDetalle" ("VentaId", "ProductoId", "Codigo", "Nombre", "Cantidad", "PrecioUnitario", "Descuento", "IVA", "Subtotal")
    SELECT
        v_venta_id,
        (item->>'prodId')::VARCHAR(15),
        (item->>'cod')::VARCHAR(30),
        (item->>'nom')::VARCHAR(200),
        (item->>'cant')::NUMERIC(10,3),
        (item->>'precio')::NUMERIC(18,2),
        COALESCE((item->>'desc')::NUMERIC(18,2), 0),
        COALESCE((item->>'iva')::NUMERIC(5,2), 16),
        (item->>'sub')::NUMERIC(18,2)
    FROM jsonb_array_elements(p_detalle_json) AS item;

    UPDATE "PosVentas" SET
        "Subtotal"  = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id),
        "Descuento" = (SELECT COALESCE(SUM("Descuento" * "Cantidad"), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id),
        "Impuestos" = (SELECT COALESCE(SUM("Subtotal" * "IVA" / 100), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id),
        "Total"     = (SELECT COALESCE(SUM("Subtotal" + "Subtotal" * "IVA" / 100), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id)
    WHERE "Id" = v_venta_id;

    RETURN QUERY SELECT v_venta_id AS "VentaId";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;
