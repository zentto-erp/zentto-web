-- +goose Up
-- Migración: agregar filtro p_company_id a funciones POS que no lo tienen.
-- Tablas hijas (SaleTicketLine, WaitTicketLine) se filtran via JOIN al padre.
-- Tablas legacy (PosVentas*, PosVentasEnEspera*) no tienen CompanyId; se omiten.

-- ============================================================
-- 1) usp_acct_pos_getheader  (pos."SaleTicket" → agregar CompanyId)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_pos_getheader(
    p_company_id       INTEGER,
    p_sale_ticket_id   BIGINT
) RETURNS TABLE(
    id            BIGINT,
    "numFactura"  CHARACTER VARYING,
    "fechaVenta"  TIMESTAMP WITHOUT TIME ZONE,
    "metodoPago"  CHARACTER VARYING,
    "codUsuario"  CHARACTER VARYING,
    subtotal      NUMERIC,
    impuestos     NUMERIC,
    total         NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v."SaleTicketId"   AS "id",
        v."InvoiceNumber"::VARCHAR  AS "numFactura",
        v."SoldAt"         AS "fechaVenta",
        v."PaymentMethod"::VARCHAR  AS "metodoPago",
        u."UserCode"::VARCHAR       AS "codUsuario",
        v."NetAmount"      AS "subtotal",
        v."TaxAmount"      AS "impuestos",
        v."TotalAmount"    AS "total"
    FROM pos."SaleTicket" v
    LEFT JOIN sec."User" u ON u."UserId" = v."SoldByUserId"
    WHERE v."SaleTicketId" = p_sale_ticket_id
      AND v."CompanyId" = p_company_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 2) usp_acct_pos_gettaxsummary  (pos."SaleTicketLine" → JOIN a SaleTicket)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_pos_gettaxsummary(
    p_company_id       INTEGER,
    p_sale_ticket_id   BIGINT
) RETURNS TABLE(
    "taxRate"     NUMERIC,
    "baseAmount"  NUMERIC,
    "taxAmount"   NUMERIC,
    "totalAmount" NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        stl."TaxRate"          AS "taxRate",
        SUM(stl."NetAmount")   AS "baseAmount",
        SUM(stl."TaxAmount")   AS "taxAmount",
        SUM(stl."TotalAmount") AS "totalAmount"
    FROM pos."SaleTicketLine" stl
    INNER JOIN pos."SaleTicket" st ON st."SaleTicketId" = stl."SaleTicketId"
    WHERE stl."SaleTicketId" = p_sale_ticket_id
      AND st."CompanyId" = p_company_id
    GROUP BY stl."TaxRate";
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 3) usp_pos_categorias_list  (master."Product" → agregar CompanyId)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_categorias_list(
    p_company_id INTEGER
) RETURNS TABLE(
    id            CHARACTER VARYING,
    nombre        CHARACTER VARYING,
    "productCount" BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        RTRIM(COALESCE(i."Categoria", '(Sin Categoria)')),
        RTRIM(COALESCE(i."Categoria", '(Sin Categoria)')),
        COUNT(1)
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
      AND (i."StockQty" > 0 OR i."IsService" = TRUE)
      AND i."CompanyId" = p_company_id
    GROUP BY i."Categoria"
    ORDER BY i."Categoria";
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 4) usp_pos_clientes_search  (master."Customer" → agregar CompanyId)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_clientes_search(
    p_company_id INTEGER,
    p_search     CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_limit      INTEGER DEFAULT 20
) RETURNS TABLE(
    id            CHARACTER VARYING,
    codigo        CHARACTER VARYING,
    nombre        CHARACTER VARYING,
    rif           CHARACTER VARYING,
    telefono      CHARACTER VARYING,
    email         CHARACTER VARYING,
    direccion     CHARACTER VARYING,
    "tipoPrecio"  CHARACTER VARYING,
    credito       NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CustomerCode",
        c."CustomerCode",
        c."CustomerName",
        c."FiscalId",
        c."TELEFONO",
        c."EMAIL",
        c."DIRECCION",
        COALESCE(c."LISTA_PRECIO", 'Detal'),
        COALESCE(c."CreditLimit", 0)
    FROM master."Customer" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND c."CompanyId" = p_company_id
      AND (
           p_search IS NULL
        OR c."CustomerCode" ILIKE '%' || p_search || '%'
        OR c."CustomerName" ILIKE '%' || p_search || '%'
        OR c."FiscalId" ILIKE '%' || p_search || '%'
      )
    ORDER BY c."CustomerName"
    LIMIT p_limit;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 5) usp_pos_producto_get_by_codigo  (master."Product" → agregar CompanyId)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_producto_get_by_codigo(
    p_company_id INTEGER,
    p_codigo     CHARACTER VARYING
) RETURNS TABLE(
    id                   CHARACTER VARYING,
    codigo               CHARACTER VARYING,
    nombre               CHARACTER VARYING,
    "precioDetal"        NUMERIC,
    "precioMayor"        NUMERIC,
    "precioDistribuidor" NUMERIC,
    existencia           NUMERIC,
    categoria            CHARACTER VARYING,
    iva                  NUMERIC,
    barra                CHARACTER VARYING,
    referencia           CHARACTER VARYING
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        i."ProductCode",
        i."ProductCode",
        TRIM(
            COALESCE(RTRIM(i."Categoria"),''::VARCHAR) ||
            CASE WHEN RTRIM(COALESCE(i."Tipo",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."ProductName",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Marca",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Clase",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Clase") ELSE '' END
        ),
        i."SalesPrice",
        COALESCE(i."PRECIO_VENTA2", i."SalesPrice" * 0.90),
        COALESCE(i."PRECIO_VENTA3", i."SalesPrice" * 0.80),
        i."StockQty",
        i."Categoria",
        COALESCE(i."PORCENTAJE", 16),
        i."Barra",
        i."Referencia"
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
      AND i."CompanyId" = p_company_id
      AND (
           i."ProductCode" = p_codigo
        OR i."Barra" = p_codigo
        OR i."Referencia" = p_codigo
      )
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 6) usp_pos_productos_list  (master."Product" → agregar CompanyId)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_productos_list(
    p_company_id  INTEGER,
    p_search      CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_categoria   CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_almacen_id  CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_page        INTEGER DEFAULT 1,
    p_limit       INTEGER DEFAULT 50
) RETURNS TABLE(
    "TotalCount"         BIGINT,
    id                   CHARACTER VARYING,
    codigo               CHARACTER VARYING,
    nombre               CHARACTER VARYING,
    "precioDetal"        NUMERIC,
    "precioMayor"        NUMERIC,
    "precioDistribuidor" NUMERIC,
    existencia           NUMERIC,
    categoria            CHARACTER VARYING,
    iva                  NUMERIC,
    barra                CHARACTER VARYING,
    referencia           CHARACTER VARYING,
    "esServicio"         BOOLEAN,
    "costoPromedio"      NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT := (p_page - 1) * p_limit;
    v_total  BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
      AND i."CompanyId" = p_company_id
      AND (i."StockQty" > 0 OR i."IsService" = TRUE)
      AND (p_search IS NULL
           OR i."ProductCode" ILIKE '%' || p_search || '%'
           OR i."ProductName" ILIKE '%' || p_search || '%'
           OR i."Referencia" ILIKE '%' || p_search || '%'
           OR i."Barra" ILIKE '%' || p_search || '%'
           OR i."Categoria" ILIKE '%' || p_search || '%')
      AND (p_categoria IS NULL OR i."Categoria" = p_categoria);

    RETURN QUERY
    SELECT
        v_total,
        i."ProductCode",
        i."ProductCode",
        TRIM(
            COALESCE(RTRIM(i."Categoria"),''::VARCHAR) ||
            CASE WHEN RTRIM(COALESCE(i."Tipo",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."ProductName",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Marca",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Clase",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Clase") ELSE '' END
        ),
        i."SalesPrice",
        COALESCE(i."PRECIO_VENTA2", i."SalesPrice" * 0.90),
        COALESCE(i."PRECIO_VENTA3", i."SalesPrice" * 0.80),
        i."StockQty",
        i."Categoria",
        COALESCE(i."PORCENTAJE", 16),
        i."Barra",
        i."Referencia",
        i."IsService",
        COALESCE(i."CostPrice", 0)
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
      AND i."CompanyId" = p_company_id
      AND (i."StockQty" > 0 OR i."IsService" = TRUE)
      AND (p_search IS NULL
           OR i."ProductCode" ILIKE '%' || p_search || '%'
           OR i."ProductName" ILIKE '%' || p_search || '%'
           OR i."Referencia" ILIKE '%' || p_search || '%'
           OR i."Barra" ILIKE '%' || p_search || '%'
           OR i."Categoria" ILIKE '%' || p_search || '%')
      AND (p_categoria IS NULL OR i."Categoria" = p_categoria)
    ORDER BY i."ProductCode"
    LIMIT p_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 7) usp_pos_waitticketline_getitems  (pos."WaitTicketLine" → JOIN a WaitTicket)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_waitticketline_getitems(
    p_company_id      INTEGER,
    p_branch_id       INTEGER,
    p_wait_ticket_id  BIGINT
) RETURNS TABLE(
    id                     BIGINT,
    "productoId"           CHARACTER VARYING,
    codigo                 CHARACTER VARYING,
    nombre                 CHARACTER VARYING,
    cantidad               NUMERIC,
    "precioUnitario"       NUMERIC,
    descuento              NUMERIC,
    iva                    NUMERIC,
    subtotal               NUMERIC,
    total                  NUMERIC,
    "supervisorApprovalId" INTEGER,
    "lineMetaJson"         TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        wl."WaitTicketLineId",
        COALESCE(wl."ProductId"::TEXT, wl."ProductCode")::VARCHAR,
        wl."ProductCode", wl."ProductName",
        wl."Quantity", wl."UnitPrice", wl."DiscountAmount",
        CASE WHEN wl."TaxRate" > 1 THEN wl."TaxRate" ELSE wl."TaxRate" * 100 END,
        wl."NetAmount", wl."TotalAmount",
        wl."SupervisorApprovalId", wl."LineMetaJson"
    FROM pos."WaitTicketLine" wl
    INNER JOIN pos."WaitTicket" wt ON wt."WaitTicketId" = wl."WaitTicketId"
    WHERE wl."WaitTicketId" = p_wait_ticket_id
      AND wt."CompanyId" = p_company_id
      AND wt."BranchId"  = p_branch_id
    ORDER BY wl."LineNumber";
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 8) usp_pos_espera_anular  (legacy "PosVentasEnEspera" — sin CompanyId en tabla,
--    se agrega p_company_id para consistencia de firma pero no se filtra)
-- ============================================================
-- NOTA: Las tablas legacy public."PosVentasEnEspera" y public."PosVentasEnEsperaDetalle"
-- no poseen columna CompanyId. Se agrega el parámetro para uniformidad de la API
-- pero el filtro real queda pendiente de migración DDL de estas tablas.

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_espera_anular(
    p_company_id INTEGER,
    p_id         INTEGER
) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE "PosVentasEnEspera" SET "Estado" = 'anulado' WHERE "Id" = p_id AND "Estado" = 'espera';
END;
$$;
-- +goose StatementEnd

-- ============================================================
-- 9) usp_pos_espera_crear  (legacy — sin CompanyId en tabla)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_espera_crear(
    p_company_id        INTEGER,
    p_caja_id           CHARACTER VARYING,
    p_estacion_nombre   CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_cod_usuario       CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_cliente_id        CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_cliente_nombre    CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_cliente_rif       CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_tipo_precio       CHARACTER VARYING DEFAULT 'Detal'::CHARACTER VARYING,
    p_motivo            CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_detalle_json      JSONB DEFAULT '[]'::JSONB
) RETURNS TABLE("EsperaId" INTEGER)
LANGUAGE plpgsql
AS $$
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
-- +goose StatementEnd

-- ============================================================
-- 10) usp_pos_espera_list  (legacy — sin CompanyId en tabla)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_espera_list(
    p_company_id INTEGER
) RETURNS TABLE(
    id                INTEGER,
    "cajaId"          CHARACTER VARYING,
    "estacionNombre"  CHARACTER VARYING,
    "codUsuario"      CHARACTER VARYING,
    "clienteNombre"   CHARACTER VARYING,
    "clienteRif"      CHARACTER VARYING,
    "tipoPrecio"      CHARACTER VARYING,
    motivo            CHARACTER VARYING,
    total             NUMERIC,
    "fechaCreacion"   TIMESTAMP WITHOUT TIME ZONE,
    "cantItems"       BIGINT
)
LANGUAGE plpgsql
AS $$
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
-- +goose StatementEnd

-- ============================================================
-- 11) usp_pos_espera_recuperar_detalle  (legacy — sin CompanyId en tabla)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_espera_recuperar_detalle(
    p_company_id INTEGER,
    p_id         INTEGER
) RETURNS TABLE(
    id               INTEGER,
    "productoId"     CHARACTER VARYING,
    codigo           CHARACTER VARYING,
    nombre           CHARACTER VARYING,
    cantidad         NUMERIC,
    "precioUnitario" NUMERIC,
    descuento        NUMERIC,
    iva              NUMERIC,
    subtotal         NUMERIC,
    orden            INTEGER
)
LANGUAGE plpgsql
AS $$
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
-- +goose StatementEnd

-- ============================================================
-- 12) usp_pos_espera_recuperar_header  (legacy — sin CompanyId en tabla)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_espera_recuperar_header(
    p_company_id      INTEGER,
    p_id              INTEGER,
    p_recuperado_por  CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_recuperado_en   CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING
) RETURNS TABLE(
    id              INTEGER,
    "cajaId"        CHARACTER VARYING,
    "clienteId"     CHARACTER VARYING,
    "clienteNombre" CHARACTER VARYING,
    "clienteRif"    CHARACTER VARYING,
    "tipoPrecio"    CHARACTER VARYING,
    motivo          CHARACTER VARYING,
    subtotal        NUMERIC,
    descuento       NUMERIC,
    impuestos       NUMERIC,
    total           NUMERIC,
    "fechaCreacion" TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql
AS $$
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
-- +goose StatementEnd

-- ============================================================
-- 13) usp_pos_venta_crear  (legacy — sin CompanyId en tabla)
-- ============================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_venta_crear(
    p_company_id       INTEGER,
    p_num_factura      CHARACTER VARYING,
    p_caja_id          CHARACTER VARYING,
    p_cod_usuario      CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_cliente_id       CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_cliente_nombre   CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_cliente_rif      CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_tipo_precio      CHARACTER VARYING DEFAULT 'Detal'::CHARACTER VARYING,
    p_metodo_pago      CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING,
    p_trama_fiscal     TEXT DEFAULT NULL::TEXT,
    p_espera_origen_id INTEGER DEFAULT NULL::INTEGER,
    p_detalle_json     JSONB DEFAULT '[]'::JSONB
) RETURNS TABLE("VentaId" INTEGER)
LANGUAGE plpgsql
AS $$
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
-- +goose StatementEnd

-- +goose Down
-- Down: revertir a firmas originales sin p_company_id

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_pos_getheader(
    p_sale_ticket_id BIGINT
) RETURNS TABLE(id BIGINT, "numFactura" CHARACTER VARYING, "fechaVenta" TIMESTAMP WITHOUT TIME ZONE, "metodoPago" CHARACTER VARYING, "codUsuario" CHARACTER VARYING, subtotal NUMERIC, impuestos NUMERIC, total NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT v."SaleTicketId", v."InvoiceNumber"::VARCHAR, v."SoldAt", v."PaymentMethod"::VARCHAR,
           u."UserCode"::VARCHAR, v."NetAmount", v."TaxAmount", v."TotalAmount"
    FROM pos."SaleTicket" v
    LEFT JOIN sec."User" u ON u."UserId" = v."SoldByUserId"
    WHERE v."SaleTicketId" = p_sale_ticket_id
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_acct_pos_gettaxsummary(
    p_sale_ticket_id BIGINT
) RETURNS TABLE("taxRate" NUMERIC, "baseAmount" NUMERIC, "taxAmount" NUMERIC, "totalAmount" NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT stl."TaxRate", SUM(stl."NetAmount"), SUM(stl."TaxAmount"), SUM(stl."TotalAmount")
    FROM pos."SaleTicketLine" stl
    WHERE stl."SaleTicketId" = p_sale_ticket_id
    GROUP BY stl."TaxRate";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_categorias_list()
RETURNS TABLE(id CHARACTER VARYING, nombre CHARACTER VARYING, "productCount" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT RTRIM(COALESCE(i."Categoria", '(Sin Categoria)')), RTRIM(COALESCE(i."Categoria", '(Sin Categoria)')), COUNT(1)
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE AND (i."StockQty" > 0 OR i."IsService" = TRUE)
    GROUP BY i."Categoria" ORDER BY i."Categoria";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_clientes_search(
    p_search CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_limit INTEGER DEFAULT 20
) RETURNS TABLE(id CHARACTER VARYING, codigo CHARACTER VARYING, nombre CHARACTER VARYING, rif CHARACTER VARYING, telefono CHARACTER VARYING, email CHARACTER VARYING, direccion CHARACTER VARYING, "tipoPrecio" CHARACTER VARYING, credito NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."CustomerCode", c."CustomerCode", c."CustomerName", c."FiscalId", c."TELEFONO", c."EMAIL", c."DIRECCION",
           COALESCE(c."LISTA_PRECIO", 'Detal'), COALESCE(c."CreditLimit", 0)
    FROM master."Customer" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND (p_search IS NULL OR c."CustomerCode" ILIKE '%' || p_search || '%' OR c."CustomerName" ILIKE '%' || p_search || '%' OR c."FiscalId" ILIKE '%' || p_search || '%')
    ORDER BY c."CustomerName" LIMIT p_limit;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_producto_get_by_codigo(p_codigo CHARACTER VARYING)
RETURNS TABLE(id CHARACTER VARYING, codigo CHARACTER VARYING, nombre CHARACTER VARYING, "precioDetal" NUMERIC, "precioMayor" NUMERIC, "precioDistribuidor" NUMERIC, existencia NUMERIC, categoria CHARACTER VARYING, iva NUMERIC, barra CHARACTER VARYING, referencia CHARACTER VARYING)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT i."ProductCode", i."ProductCode",
        TRIM(COALESCE(RTRIM(i."Categoria"),''::VARCHAR) || CASE WHEN RTRIM(COALESCE(i."Tipo",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Tipo") ELSE '' END || CASE WHEN RTRIM(COALESCE(i."ProductName",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."ProductName") ELSE '' END || CASE WHEN RTRIM(COALESCE(i."Marca",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Marca") ELSE '' END || CASE WHEN RTRIM(COALESCE(i."Clase",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Clase") ELSE '' END),
        i."SalesPrice", COALESCE(i."PRECIO_VENTA2", i."SalesPrice" * 0.90), COALESCE(i."PRECIO_VENTA3", i."SalesPrice" * 0.80),
        i."StockQty", i."Categoria", COALESCE(i."PORCENTAJE", 16), i."Barra", i."Referencia"
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE AND (i."ProductCode" = p_codigo OR i."Barra" = p_codigo OR i."Referencia" = p_codigo)
    LIMIT 1;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_productos_list(
    p_search CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_categoria CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_almacen_id CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_page INTEGER DEFAULT 1, p_limit INTEGER DEFAULT 50
) RETURNS TABLE("TotalCount" BIGINT, id CHARACTER VARYING, codigo CHARACTER VARYING, nombre CHARACTER VARYING, "precioDetal" NUMERIC, "precioMayor" NUMERIC, "precioDistribuidor" NUMERIC, existencia NUMERIC, categoria CHARACTER VARYING, iva NUMERIC, barra CHARACTER VARYING, referencia CHARACTER VARYING, "esServicio" BOOLEAN, "costoPromedio" NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE v_offset INT := (p_page - 1) * p_limit; v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE AND (i."StockQty" > 0 OR i."IsService" = TRUE)
      AND (p_search IS NULL OR i."ProductCode" ILIKE '%' || p_search || '%' OR i."ProductName" ILIKE '%' || p_search || '%' OR i."Referencia" ILIKE '%' || p_search || '%' OR i."Barra" ILIKE '%' || p_search || '%' OR i."Categoria" ILIKE '%' || p_search || '%')
      AND (p_categoria IS NULL OR i."Categoria" = p_categoria);
    RETURN QUERY
    SELECT v_total, i."ProductCode", i."ProductCode",
        TRIM(COALESCE(RTRIM(i."Categoria"),''::VARCHAR) || CASE WHEN RTRIM(COALESCE(i."Tipo",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Tipo") ELSE '' END || CASE WHEN RTRIM(COALESCE(i."ProductName",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."ProductName") ELSE '' END || CASE WHEN RTRIM(COALESCE(i."Marca",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Marca") ELSE '' END || CASE WHEN RTRIM(COALESCE(i."Clase",''::VARCHAR)) <> '' THEN ' ' || RTRIM(i."Clase") ELSE '' END),
        i."SalesPrice", COALESCE(i."PRECIO_VENTA2", i."SalesPrice" * 0.90), COALESCE(i."PRECIO_VENTA3", i."SalesPrice" * 0.80),
        i."StockQty", i."Categoria", COALESCE(i."PORCENTAJE", 16), i."Barra", i."Referencia", i."IsService", COALESCE(i."CostPrice", 0)
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE AND (i."StockQty" > 0 OR i."IsService" = TRUE)
      AND (p_search IS NULL OR i."ProductCode" ILIKE '%' || p_search || '%' OR i."ProductName" ILIKE '%' || p_search || '%' OR i."Referencia" ILIKE '%' || p_search || '%' OR i."Barra" ILIKE '%' || p_search || '%' OR i."Categoria" ILIKE '%' || p_search || '%')
      AND (p_categoria IS NULL OR i."Categoria" = p_categoria)
    ORDER BY i."ProductCode" LIMIT p_limit OFFSET v_offset;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_waitticketline_getitems(p_wait_ticket_id BIGINT)
RETURNS TABLE(id BIGINT, "productoId" CHARACTER VARYING, codigo CHARACTER VARYING, nombre CHARACTER VARYING, cantidad NUMERIC, "precioUnitario" NUMERIC, descuento NUMERIC, iva NUMERIC, subtotal NUMERIC, total NUMERIC, "supervisorApprovalId" INTEGER, "lineMetaJson" TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT wl."WaitTicketLineId", COALESCE(wl."ProductId"::TEXT, wl."ProductCode")::VARCHAR,
           wl."ProductCode", wl."ProductName", wl."Quantity", wl."UnitPrice", wl."DiscountAmount",
           CASE WHEN wl."TaxRate" > 1 THEN wl."TaxRate" ELSE wl."TaxRate" * 100 END,
           wl."NetAmount", wl."TotalAmount", wl."SupervisorApprovalId", wl."LineMetaJson"
    FROM pos."WaitTicketLine" wl
    WHERE wl."WaitTicketId" = p_wait_ticket_id
    ORDER BY wl."LineNumber";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_espera_anular(p_id INTEGER) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "PosVentasEnEspera" SET "Estado" = 'anulado' WHERE "Id" = p_id AND "Estado" = 'espera';
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_espera_crear(
    p_caja_id CHARACTER VARYING, p_estacion_nombre CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_cod_usuario CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_cliente_id CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_cliente_nombre CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_cliente_rif CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_tipo_precio CHARACTER VARYING DEFAULT 'Detal'::CHARACTER VARYING, p_motivo CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_detalle_json JSONB DEFAULT '[]'::JSONB
) RETURNS TABLE("EsperaId" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE v_espera_id INT;
BEGIN
    INSERT INTO "PosVentasEnEspera" ("CajaId", "EstacionNombre", "CodUsuario", "ClienteId", "ClienteNombre", "ClienteRif", "TipoPrecio", "Motivo")
    VALUES (p_caja_id, p_estacion_nombre, p_cod_usuario, p_cliente_id, p_cliente_nombre, p_cliente_rif, p_tipo_precio, p_motivo)
    RETURNING "Id" INTO v_espera_id;
    INSERT INTO "PosVentasEnEsperaDetalle" ("VentaEsperaId", "ProductoId", "Codigo", "Nombre", "Cantidad", "PrecioUnitario", "Descuento", "IVA", "Subtotal", "Orden")
    SELECT v_espera_id, (item->>'prodId')::VARCHAR(15), (item->>'cod')::VARCHAR(30), (item->>'nom')::VARCHAR(200), (item->>'cant')::NUMERIC(10,3), (item->>'precio')::NUMERIC(18,2), COALESCE((item->>'desc')::NUMERIC(18,2), 0), COALESCE((item->>'iva')::NUMERIC(5,2), 16), (item->>'sub')::NUMERIC(18,2), COALESCE((item->>'ord')::INT, 0)
    FROM jsonb_array_elements(p_detalle_json) AS item;
    UPDATE "PosVentasEnEspera" SET
        "Subtotal"  = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id),
        "Descuento" = (SELECT COALESCE(SUM("Descuento" * "Cantidad"), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id),
        "Impuestos" = (SELECT COALESCE(SUM("Subtotal" * "IVA" / 100), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id),
        "Total"     = (SELECT COALESCE(SUM("Subtotal" + "Subtotal" * "IVA" / 100), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id)
    WHERE "Id" = v_espera_id;
    RETURN QUERY SELECT v_espera_id AS "EsperaId";
EXCEPTION WHEN OTHERS THEN RAISE EXCEPTION '%', SQLERRM;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_espera_list()
RETURNS TABLE(id INTEGER, "cajaId" CHARACTER VARYING, "estacionNombre" CHARACTER VARYING, "codUsuario" CHARACTER VARYING, "clienteNombre" CHARACTER VARYING, "clienteRif" CHARACTER VARYING, "tipoPrecio" CHARACTER VARYING, motivo CHARACTER VARYING, total NUMERIC, "fechaCreacion" TIMESTAMP WITHOUT TIME ZONE, "cantItems" BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT e."Id", e."CajaId", e."EstacionNombre", e."CodUsuario", e."ClienteNombre", e."ClienteRif", e."TipoPrecio", e."Motivo", e."Total", e."FechaCreacion",
           (SELECT COUNT(1) FROM "PosVentasEnEsperaDetalle" d WHERE d."VentaEsperaId" = e."Id")
    FROM "PosVentasEnEspera" e WHERE e."Estado" = 'espera' ORDER BY e."FechaCreacion" ASC;
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_espera_recuperar_detalle(p_id INTEGER)
RETURNS TABLE(id INTEGER, "productoId" CHARACTER VARYING, codigo CHARACTER VARYING, nombre CHARACTER VARYING, cantidad NUMERIC, "precioUnitario" NUMERIC, descuento NUMERIC, iva NUMERIC, subtotal NUMERIC, orden INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT d."Id", d."ProductoId", d."Codigo", d."Nombre", d."Cantidad", d."PrecioUnitario", d."Descuento", d."IVA", d."Subtotal", d."Orden"
    FROM "PosVentasEnEsperaDetalle" d WHERE d."VentaEsperaId" = p_id ORDER BY d."Orden";
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_espera_recuperar_header(
    p_id INTEGER, p_recuperado_por CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_recuperado_en CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING
) RETURNS TABLE(id INTEGER, "cajaId" CHARACTER VARYING, "clienteId" CHARACTER VARYING, "clienteNombre" CHARACTER VARYING, "clienteRif" CHARACTER VARYING, "tipoPrecio" CHARACTER VARYING, motivo CHARACTER VARYING, subtotal NUMERIC, descuento NUMERIC, impuestos NUMERIC, total NUMERIC, "fechaCreacion" TIMESTAMP WITHOUT TIME ZONE)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT e."Id", e."CajaId", e."ClienteId", e."ClienteNombre", e."ClienteRif", e."TipoPrecio", e."Motivo",
           e."Subtotal", e."Descuento", e."Impuestos", e."Total", e."FechaCreacion"
    FROM "PosVentasEnEspera" e WHERE e."Id" = p_id AND e."Estado" = 'espera';
    UPDATE "PosVentasEnEspera" SET "Estado" = 'recuperado', "RecuperadoPor" = p_recuperado_por, "RecuperadoEn" = p_recuperado_en, "FechaRecuperado" = NOW() AT TIME ZONE 'UTC'
    WHERE "Id" = p_id AND "Estado" = 'espera';
END;
$$;
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_pos_venta_crear(
    p_num_factura CHARACTER VARYING, p_caja_id CHARACTER VARYING, p_cod_usuario CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_cliente_id CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_cliente_nombre CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_cliente_rif CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_tipo_precio CHARACTER VARYING DEFAULT 'Detal'::CHARACTER VARYING, p_metodo_pago CHARACTER VARYING DEFAULT NULL::CHARACTER VARYING, p_trama_fiscal TEXT DEFAULT NULL::TEXT, p_espera_origen_id INTEGER DEFAULT NULL::INTEGER, p_detalle_json JSONB DEFAULT '[]'::JSONB
) RETURNS TABLE("VentaId" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE v_venta_id INT;
BEGIN
    INSERT INTO "PosVentas" ("NumFactura", "CajaId", "CodUsuario", "ClienteId", "ClienteNombre", "ClienteRif", "TipoPrecio", "MetodoPago", "TramaFiscal", "EsperaOrigenId")
    VALUES (p_num_factura, p_caja_id, p_cod_usuario, p_cliente_id, p_cliente_nombre, p_cliente_rif, p_tipo_precio, p_metodo_pago, p_trama_fiscal, p_espera_origen_id)
    RETURNING "Id" INTO v_venta_id;
    INSERT INTO "PosVentasDetalle" ("VentaId", "ProductoId", "Codigo", "Nombre", "Cantidad", "PrecioUnitario", "Descuento", "IVA", "Subtotal")
    SELECT v_venta_id, (item->>'prodId')::VARCHAR(15), (item->>'cod')::VARCHAR(30), (item->>'nom')::VARCHAR(200), (item->>'cant')::NUMERIC(10,3), (item->>'precio')::NUMERIC(18,2), COALESCE((item->>'desc')::NUMERIC(18,2), 0), COALESCE((item->>'iva')::NUMERIC(5,2), 16), (item->>'sub')::NUMERIC(18,2)
    FROM jsonb_array_elements(p_detalle_json) AS item;
    UPDATE "PosVentas" SET
        "Subtotal"  = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id),
        "Descuento" = (SELECT COALESCE(SUM("Descuento" * "Cantidad"), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id),
        "Impuestos" = (SELECT COALESCE(SUM("Subtotal" * "IVA" / 100), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id),
        "Total"     = (SELECT COALESCE(SUM("Subtotal" + "Subtotal" * "IVA" / 100), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id)
    WHERE "Id" = v_venta_id;
    RETURN QUERY SELECT v_venta_id AS "VentaId";
EXCEPTION WHEN OTHERS THEN RAISE EXCEPTION '%', SQLERRM;
END;
$$;
-- +goose StatementEnd
