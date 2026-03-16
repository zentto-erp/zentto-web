-- ═══════════════════════════════════════════════════════════════════
-- DatqBox POS & Restaurante — Funciones PostgreSQL
-- Productos para POS, Clientes POS, Mesas, Pedidos y Facturacion
-- Traducido de SQL Server a PostgreSQL
-- ═══════════════════════════════════════════════════════════════════

-- =============================================
-- 1. PRODUCTOS POS: Listar articulos para POS con precios y stock
-- =============================================
CREATE OR REPLACE FUNCTION usp_pos_productos_list(
    p_search     VARCHAR(100) DEFAULT NULL,
    p_categoria  VARCHAR(50)  DEFAULT NULL,
    p_almacen_id VARCHAR(10)  DEFAULT NULL,
    p_page       INT          DEFAULT 1,
    p_limit      INT          DEFAULT 50
)
RETURNS TABLE(
    "TotalCount"         BIGINT,
    "id"                 VARCHAR,
    "codigo"             VARCHAR,
    "nombre"             VARCHAR,
    "precioDetal"        NUMERIC,
    "precioMayor"        NUMERIC,
    "precioDistribuidor" NUMERIC,
    "existencia"         NUMERIC,
    "categoria"          VARCHAR,
    "iva"                NUMERIC,
    "barra"              VARCHAR,
    "referencia"         VARCHAR,
    "esServicio"         BOOLEAN,
    "costoPromedio"      NUMERIC
) LANGUAGE plpgsql AS $$
DECLARE
    v_offset INT := (p_page - 1) * p_limit;
    v_total  BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
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
            COALESCE(RTRIM(i."Categoria"), '') ||
            CASE WHEN RTRIM(COALESCE(i."Tipo", '')) <> '' THEN ' ' || RTRIM(i."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."ProductName", '')) <> '' THEN ' ' || RTRIM(i."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Marca", '')) <> '' THEN ' ' || RTRIM(i."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Clase", '')) <> '' THEN ' ' || RTRIM(i."Clase") ELSE '' END
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

-- =============================================
-- 2. PRODUCTO POR CODIGO DE BARRAS / CODIGO
-- =============================================
CREATE OR REPLACE FUNCTION usp_pos_producto_get_by_codigo(
    p_codigo VARCHAR(20)
)
RETURNS TABLE(
    "id"                 VARCHAR,
    "codigo"             VARCHAR,
    "nombre"             VARCHAR,
    "precioDetal"        NUMERIC,
    "precioMayor"        NUMERIC,
    "precioDistribuidor" NUMERIC,
    "existencia"         NUMERIC,
    "categoria"          VARCHAR,
    "iva"                NUMERIC,
    "barra"              VARCHAR,
    "referencia"         VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        i."ProductCode",
        i."ProductCode",
        TRIM(
            COALESCE(RTRIM(i."Categoria"), '') ||
            CASE WHEN RTRIM(COALESCE(i."Tipo", '')) <> '' THEN ' ' || RTRIM(i."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."ProductName", '')) <> '' THEN ' ' || RTRIM(i."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Marca", '')) <> '' THEN ' ' || RTRIM(i."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Clase", '')) <> '' THEN ' ' || RTRIM(i."Clase") ELSE '' END
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
      AND (
           i."ProductCode" = p_codigo
        OR i."Barra" = p_codigo
        OR i."Referencia" = p_codigo
      )
    LIMIT 1;
END;
$$;

-- =============================================
-- 3. CLIENTES POS: Busqueda rapida
-- =============================================
CREATE OR REPLACE FUNCTION usp_pos_clientes_search(
    p_search VARCHAR(100) DEFAULT NULL,
    p_limit  INT          DEFAULT 20
)
RETURNS TABLE(
    "id"          VARCHAR,
    "codigo"      VARCHAR,
    "nombre"      VARCHAR,
    "rif"         VARCHAR,
    "telefono"    VARCHAR,
    "email"       VARCHAR,
    "direccion"   VARCHAR,
    "tipoPrecio"  VARCHAR,
    "credito"     NUMERIC
) LANGUAGE plpgsql AS $$
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

-- =============================================
-- 4. CATEGORIAS POS: Lista de categorias con conteo
-- =============================================
CREATE OR REPLACE FUNCTION usp_pos_categorias_list()
RETURNS TABLE(
    "id"           VARCHAR,
    "nombre"       VARCHAR,
    "productCount" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        RTRIM(COALESCE(i."Categoria", '(Sin Categoria)')),
        RTRIM(COALESCE(i."Categoria", '(Sin Categoria)')),
        COUNT(1)
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
      AND (i."StockQty" > 0 OR i."IsService" = TRUE)
    GROUP BY i."Categoria"
    ORDER BY i."Categoria";
END;
$$;

-- =============================================
-- 5. RESTAURANTE: Gestion de Mesas
-- =============================================
CREATE TABLE IF NOT EXISTS "RestauranteMesas" (
    "Id"            SERIAL PRIMARY KEY,
    "Numero"        INT NOT NULL,
    "Nombre"        VARCHAR(50) NOT NULL,
    "Capacidad"     INT NOT NULL DEFAULT 4,
    "AmbienteId"    VARCHAR(10) NOT NULL DEFAULT '1',
    "Ambiente"      VARCHAR(50) NOT NULL DEFAULT 'Salon Principal',
    "PosicionX"     INT NOT NULL DEFAULT 0,
    "PosicionY"     INT NOT NULL DEFAULT 0,
    "Estado"        VARCHAR(20) NOT NULL DEFAULT 'libre',
    "Activa"        BOOLEAN NOT NULL DEFAULT TRUE,
    "FechaCreacion" TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- Seed: mesas iniciales (solo si esta vacia)
INSERT INTO "RestauranteMesas" ("Numero", "Nombre", "Capacidad", "AmbienteId", "Ambiente", "PosicionX", "PosicionY")
SELECT * FROM (VALUES
    (1, 'Mesa 1', 4, '1', 'Salon Principal', 20, 20),
    (2, 'Mesa 2', 2, '1', 'Salon Principal', 180, 20),
    (3, 'Mesa 3', 6, '1', 'Salon Principal', 340, 20),
    (4, 'Mesa 4', 4, '1', 'Salon Principal', 20, 180),
    (5, 'Mesa 5', 8, '1', 'Salon Principal', 180, 180),
    (6, 'Mesa 6', 4, '2', 'Terraza', 20, 20),
    (7, 'Mesa 7', 2, '2', 'Terraza', 180, 20),
    (8, 'Barra 1', 1, '3', 'Barra', 20, 20),
    (9, 'Barra 2', 1, '3', 'Barra', 180, 20),
    (10, 'Barra 3', 1, '3', 'Barra', 340, 20)
) AS v("Numero", "Nombre", "Capacidad", "AmbienteId", "Ambiente", "PosicionX", "PosicionY")
WHERE NOT EXISTS (SELECT 1 FROM "RestauranteMesas");

-- Tabla de pedidos de restaurante
CREATE TABLE IF NOT EXISTS "RestaurantePedidos" (
    "Id"             SERIAL PRIMARY KEY,
    "MesaId"         INT NOT NULL,
    "ClienteNombre"  VARCHAR(100) NULL,
    "ClienteRif"     VARCHAR(20) NULL,
    "Estado"         VARCHAR(20) NOT NULL DEFAULT 'abierto',
    "Total"          NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Comentarios"    VARCHAR(500) NULL,
    "FechaApertura"  TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "FechaCierre"    TIMESTAMP NULL,
    "CodUsuario"     VARCHAR(10) NULL,
    CONSTRAINT "FK_RestPedido_Mesa" FOREIGN KEY ("MesaId") REFERENCES "RestauranteMesas"("Id")
);

-- Tabla de items de pedido
CREATE TABLE IF NOT EXISTS "RestaurantePedidoItems" (
    "Id"                 SERIAL PRIMARY KEY,
    "PedidoId"           INT NOT NULL,
    "ProductoId"         VARCHAR(15) NOT NULL,
    "Nombre"             VARCHAR(200) NOT NULL,
    "Cantidad"           NUMERIC(10,3) NOT NULL DEFAULT 1,
    "PrecioUnitario"     NUMERIC(18,2) NOT NULL,
    "Subtotal"           NUMERIC(18,2) NOT NULL,
    "IvaPct"             NUMERIC(9,4) NULL,
    "Estado"             VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    "EsCompuesto"        BOOLEAN NOT NULL DEFAULT FALSE,
    "Componentes"        TEXT NULL,
    "Comentarios"        VARCHAR(500) NULL,
    "EnviadoACocina"     BOOLEAN NOT NULL DEFAULT FALSE,
    "HoraEnvio"          TIMESTAMP NULL,
    CONSTRAINT "FK_RestItem_Pedido" FOREIGN KEY ("PedidoId") REFERENCES "RestaurantePedidos"("Id")
);

-- SP Listar Mesas
CREATE OR REPLACE FUNCTION usp_rest_mesas_list(
    p_ambiente_id VARCHAR(10) DEFAULT NULL
)
RETURNS TABLE(
    "id"          INT,
    "numero"      INT,
    "nombre"      VARCHAR,
    "capacidad"   INT,
    "ambienteId"  VARCHAR,
    "ambiente"    VARCHAR,
    "posicionX"   INT,
    "posicionY"   INT,
    "estado"      VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        m."Id",
        m."Numero",
        m."Nombre",
        m."Capacidad",
        m."AmbienteId",
        m."Ambiente",
        m."PosicionX",
        m."PosicionY",
        m."Estado"
    FROM "RestauranteMesas" m
    WHERE m."Activa" = TRUE
      AND (p_ambiente_id IS NULL OR m."AmbienteId" = p_ambiente_id)
    ORDER BY m."AmbienteId", m."Numero";
END;
$$;

-- SP Abrir Pedido en mesa
CREATE OR REPLACE FUNCTION usp_rest_pedido_abrir(
    p_mesa_id        INT,
    p_cliente_nombre VARCHAR(100) DEFAULT NULL,
    p_cliente_rif    VARCHAR(20)  DEFAULT NULL,
    p_cod_usuario    VARCHAR(10)  DEFAULT NULL
)
RETURNS TABLE(
    "PedidoId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_pedido_id INT;
BEGIN
    INSERT INTO "RestaurantePedidos" ("MesaId", "ClienteNombre", "ClienteRif", "Estado", "CodUsuario")
    VALUES (p_mesa_id, p_cliente_nombre, p_cliente_rif, 'abierto', p_cod_usuario)
    RETURNING "Id" INTO v_pedido_id;

    UPDATE "RestauranteMesas" SET "Estado" = 'ocupada' WHERE "Id" = p_mesa_id;

    RETURN QUERY SELECT v_pedido_id AS "PedidoId";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;

-- SP Agregar Item a Pedido
CREATE OR REPLACE FUNCTION usp_rest_pedido_item_agregar(
    p_pedido_id       INT,
    p_producto_id     VARCHAR(15),
    p_nombre          VARCHAR(200),
    p_cantidad        NUMERIC(10,3),
    p_precio_unitario NUMERIC(18,2),
    p_iva             NUMERIC(9,4) DEFAULT NULL,
    p_es_compuesto    BOOLEAN DEFAULT FALSE,
    p_componentes     TEXT DEFAULT NULL,
    p_comentarios     VARCHAR(500) DEFAULT NULL
)
RETURNS TABLE(
    "ItemId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_subtotal NUMERIC(18,2) := p_cantidad * p_precio_unitario;
    v_iva_pct  NUMERIC(9,4) := p_iva;
    v_item_id  INT;
BEGIN
    IF v_iva_pct IS NULL THEN
        SELECT
            CASE
                WHEN COALESCE(inv."PORCENTAJE", 0) > 1 THEN (inv."PORCENTAJE" / 100.0)::NUMERIC(9,4)
                ELSE COALESCE(inv."PORCENTAJE", 0)::NUMERIC(9,4)
            END
        INTO v_iva_pct
        FROM master."Product" inv
        WHERE COALESCE(inv."IsDeleted", FALSE) = FALSE
          AND TRIM(inv."ProductCode") = TRIM(p_producto_id)
        LIMIT 1;
    END IF;

    IF v_iva_pct IS NULL THEN
        v_iva_pct := 0;
    END IF;

    INSERT INTO "RestaurantePedidoItems" ("PedidoId", "ProductoId", "Nombre", "Cantidad", "PrecioUnitario", "Subtotal", "IvaPct", "EsCompuesto", "Componentes", "Comentarios")
    VALUES (p_pedido_id, p_producto_id, p_nombre, p_cantidad, p_precio_unitario, v_subtotal, v_iva_pct, p_es_compuesto, p_componentes, p_comentarios)
    RETURNING "Id" INTO v_item_id;

    -- Recalcular total del pedido
    UPDATE "RestaurantePedidos"
    SET "Total" = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "RestaurantePedidoItems" WHERE "PedidoId" = p_pedido_id)
    WHERE "Id" = p_pedido_id;

    RETURN QUERY SELECT v_item_id AS "ItemId";
END;
$$;

-- SP Enviar comanda a cocina (marcar items como enviados)
CREATE OR REPLACE FUNCTION usp_rest_comanda_enviar(
    p_pedido_id INT
)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "RestaurantePedidoItems"
    SET "EnviadoACocina" = TRUE,
        "HoraEnvio" = NOW() AT TIME ZONE 'UTC',
        "Estado" = 'en_preparacion'
    WHERE "PedidoId" = p_pedido_id
      AND "EnviadoACocina" = FALSE;

    UPDATE "RestaurantePedidos"
    SET "Estado" = 'en_preparacion'
    WHERE "Id" = p_pedido_id AND "Estado" = 'abierto';
END;
$$;

-- SP Cerrar pedido (mesa queda libre)
CREATE OR REPLACE FUNCTION usp_rest_pedido_cerrar(
    p_pedido_id INT
)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_mesa_id INT;
BEGIN
    SELECT "MesaId" INTO v_mesa_id FROM "RestaurantePedidos" WHERE "Id" = p_pedido_id;

    UPDATE "RestaurantePedidos"
    SET "Estado" = 'cerrado', "FechaCierre" = NOW() AT TIME ZONE 'UTC'
    WHERE "Id" = p_pedido_id;

    UPDATE "RestauranteMesas" SET "Estado" = 'libre' WHERE "Id" = v_mesa_id;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;

-- SP obtener pedido activo de una mesa (header)
CREATE OR REPLACE FUNCTION usp_rest_pedido_get_by_mesa_header(
    p_mesa_id INT
)
RETURNS TABLE(
    "id"             INT,
    "mesaId"         INT,
    "clienteNombre"  VARCHAR,
    "clienteRif"     VARCHAR,
    "estado"         VARCHAR,
    "total"          NUMERIC,
    "comentarios"    VARCHAR,
    "fechaApertura"  TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."Id",
        p."MesaId",
        p."ClienteNombre",
        p."ClienteRif",
        p."Estado",
        p."Total",
        p."Comentarios",
        p."FechaApertura"
    FROM "RestaurantePedidos" p
    WHERE p."MesaId" = p_mesa_id AND p."Estado" <> 'cerrado'
    ORDER BY p."FechaApertura" DESC
    LIMIT 1;
END;
$$;

-- SP obtener items del pedido activo de una mesa
CREATE OR REPLACE FUNCTION usp_rest_pedido_get_by_mesa_items(
    p_mesa_id INT
)
RETURNS TABLE(
    "id"              INT,
    "pedidoId"        INT,
    "productoId"      VARCHAR,
    "nombre"          VARCHAR,
    "cantidad"        NUMERIC,
    "precioUnitario"  NUMERIC,
    "subtotal"        NUMERIC,
    "iva"             NUMERIC,
    "estado"          VARCHAR,
    "esCompuesto"     BOOLEAN,
    "componentes"     TEXT,
    "comentarios"     VARCHAR,
    "enviadoACocina"  BOOLEAN,
    "horaEnvio"       TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        i."Id",
        i."PedidoId",
        i."ProductoId",
        i."Nombre",
        i."Cantidad",
        i."PrecioUnitario",
        i."Subtotal",
        i."IvaPct",
        i."Estado",
        i."EsCompuesto",
        i."Componentes",
        i."Comentarios",
        i."EnviadoACocina",
        i."HoraEnvio"
    FROM "RestaurantePedidoItems" i
    INNER JOIN "RestaurantePedidos" p ON i."PedidoId" = p."Id"
    WHERE p."MesaId" = p_mesa_id AND p."Estado" <> 'cerrado'
    ORDER BY i."Id";
END;
$$;
