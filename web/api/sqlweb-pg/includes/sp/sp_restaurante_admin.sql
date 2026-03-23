-- ═══════════════════════════════════════════════════════════════════
-- DatqBox Restaurante — Subsistema Administrativo Completo
-- Traducido de SQL Server a PostgreSQL
-- ═══════════════════════════════════════════════════════════════════

-- =============================================
-- 1. AMBIENTES (Salon, Terraza, Barra, etc.)
-- =============================================
CREATE TABLE IF NOT EXISTS "RestauranteAmbientes" (
    "Id"     SERIAL PRIMARY KEY,
    "Nombre" VARCHAR(50) NOT NULL,
    "Color"  VARCHAR(10) NOT NULL DEFAULT '#4CAF50',
    "Activo" BOOLEAN NOT NULL DEFAULT TRUE,
    "Orden"  INT NOT NULL DEFAULT 0
);

INSERT INTO "RestauranteAmbientes" ("Nombre", "Color", "Orden")
SELECT * FROM (VALUES
    ('Salon Principal', '#4CAF50', 1),
    ('Terraza', '#FF9800', 2),
    ('Barra', '#9C27B0', 3)
) AS v("Nombre", "Color", "Orden")
WHERE NOT EXISTS (SELECT 1 FROM "RestauranteAmbientes");

-- =============================================
-- 2. Alterar RestauranteMesas: columna ColorAmbiente
-- =============================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'RestauranteMesas' AND column_name = 'ColorAmbiente'
    ) THEN
        ALTER TABLE "RestauranteMesas" ADD COLUMN "ColorAmbiente" VARCHAR(10) DEFAULT '#4CAF50';
    END IF;
END;
$$;

-- =============================================
-- 3. CATEGORIAS DEL MENU
-- =============================================
CREATE TABLE IF NOT EXISTS "RestauranteCategorias" (
    "Id"          SERIAL PRIMARY KEY,
    "Nombre"      VARCHAR(50) NOT NULL,
    "Descripcion" VARCHAR(200) NULL,
    "Color"       VARCHAR(10) DEFAULT '#E0E0E0',
    "Orden"       INT NOT NULL DEFAULT 0,
    "Activa"      BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO "RestauranteCategorias" ("Nombre", "Orden")
SELECT * FROM (VALUES
    ('Entradas', 1),
    ('Sopas', 2),
    ('Pastas', 3),
    ('Carnes', 4),
    ('Mariscos', 5),
    ('Ensaladas', 6),
    ('Bebidas', 7),
    ('Cocteles', 8),
    ('Postres', 9)
) AS v("Nombre", "Orden")
WHERE NOT EXISTS (SELECT 1 FROM "RestauranteCategorias");

-- =============================================
-- 4. PRODUCTOS DEL MENU
-- =============================================
CREATE TABLE IF NOT EXISTS "RestauranteProductos" (
    "Id"                   SERIAL PRIMARY KEY,
    "Codigo"               VARCHAR(20) NOT NULL,
    "Nombre"               VARCHAR(200) NOT NULL,
    "Descripcion"          VARCHAR(500) NULL,
    "CategoriaId"          INT NULL,
    "Precio"               NUMERIC(18,2) NOT NULL DEFAULT 0,
    "CostoEstimado"        NUMERIC(18,2) DEFAULT 0,
    "IVA"                  NUMERIC(5,2) NOT NULL DEFAULT 16,
    "EsCompuesto"          BOOLEAN NOT NULL DEFAULT FALSE,
    "TiempoPreparacion"    INT NOT NULL DEFAULT 0,
    "Imagen"               VARCHAR(500) NULL,
    "EsSugerenciaDelDia"   BOOLEAN NOT NULL DEFAULT FALSE,
    "Disponible"           BOOLEAN NOT NULL DEFAULT TRUE,
    "Activo"               BOOLEAN NOT NULL DEFAULT TRUE,
    "ArticuloInventarioId" VARCHAR(15) NULL,
    "FechaCreacion"        TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "FechaModificacion"    TIMESTAMP NULL,
    CONSTRAINT "FK_RestProd_Cat" FOREIGN KEY ("CategoriaId") REFERENCES "RestauranteCategorias"("Id"),
    CONSTRAINT "UQ_RestProd_Codigo" UNIQUE ("Codigo")
);

-- =============================================
-- 5. COMPONENTES / OPCIONES DE PRODUCTOS COMPUESTOS
-- =============================================
CREATE TABLE IF NOT EXISTS "RestauranteProductoComponentes" (
    "Id"          SERIAL PRIMARY KEY,
    "ProductoId"  INT NOT NULL,
    "Nombre"      VARCHAR(100) NOT NULL,
    "Obligatorio" BOOLEAN NOT NULL DEFAULT FALSE,
    "Orden"       INT NOT NULL DEFAULT 0,
    CONSTRAINT "FK_RestComp_Prod" FOREIGN KEY ("ProductoId") REFERENCES "RestauranteProductos"("Id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "RestauranteComponenteOpciones" (
    "Id"            SERIAL PRIMARY KEY,
    "ComponenteId"  INT NOT NULL,
    "Nombre"        VARCHAR(100) NOT NULL,
    "PrecioExtra"   NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Orden"         INT NOT NULL DEFAULT 0,
    CONSTRAINT "FK_RestOpc_Comp" FOREIGN KEY ("ComponenteId") REFERENCES "RestauranteProductoComponentes"("Id") ON DELETE CASCADE
);

-- =============================================
-- 6. RECETAS (consumo de materias primas del inventario)
-- =============================================
CREATE TABLE IF NOT EXISTS "RestauranteRecetas" (
    "Id"           SERIAL PRIMARY KEY,
    "ProductoId"   INT NOT NULL,
    "InventarioId" VARCHAR(15) NOT NULL,
    "Cantidad"     NUMERIC(10,3) NOT NULL,
    "Unidad"       VARCHAR(20) NULL,
    "Comentario"   VARCHAR(200) NULL,
    CONSTRAINT "FK_RestReceta_Prod" FOREIGN KEY ("ProductoId") REFERENCES "RestauranteProductos"("Id") ON DELETE CASCADE
);

-- =============================================
-- 7. COMPRAS DEL RESTAURANTE
-- =============================================
CREATE TABLE IF NOT EXISTS "RestauranteCompras" (
    "Id"              SERIAL PRIMARY KEY,
    "NumCompra"       VARCHAR(20) NOT NULL,
    "ProveedorId"     VARCHAR(12) NULL,
    "FechaCompra"     TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "FechaRecepcion"  TIMESTAMP NULL,
    "Estado"          VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    "Subtotal"        NUMERIC(18,2) NOT NULL DEFAULT 0,
    "IVA"             NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Total"           NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Observaciones"   VARCHAR(500) NULL,
    "CodUsuario"      VARCHAR(10) NULL,
    CONSTRAINT "UQ_RestCompra_Num" UNIQUE ("NumCompra")
);

CREATE TABLE IF NOT EXISTS "RestauranteComprasDetalle" (
    "Id"            SERIAL PRIMARY KEY,
    "CompraId"      INT NOT NULL,
    "InventarioId"  VARCHAR(15) NULL,
    "Descripcion"   VARCHAR(200) NOT NULL,
    "Cantidad"      NUMERIC(10,3) NOT NULL,
    "PrecioUnit"    NUMERIC(18,2) NOT NULL,
    "Subtotal"      NUMERIC(18,2) NOT NULL,
    "IVA"           NUMERIC(5,2) NOT NULL DEFAULT 16,
    CONSTRAINT "FK_RestCompDet_Compra" FOREIGN KEY ("CompraId") REFERENCES "RestauranteCompras"("Id") ON DELETE CASCADE
);

-- =============================================
-- 8. SEED: Datos iniciales de productos del menu
-- =============================================
DO $$
DECLARE
    v_pasta_id INT;
    v_filete_id INT;
    v_comp_pasta1 INT;
    v_comp_pasta2 INT;
    v_comp_filete1 INT;
    v_comp_filete2 INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "RestauranteProductos") THEN
        -- Entradas
        INSERT INTO "RestauranteProductos" ("Codigo", "Nombre", "Descripcion", "CategoriaId", "Precio", "TiempoPreparacion", "EsCompuesto") VALUES
        ('ENT001', 'Bruschetta', 'Pan tostado con tomate fresco y albahaca', 1, 8.00, 10, FALSE),
        ('ENT002', 'Calamares Fritos', 'Con salsa tartara casera', 1, 12.00, 15, FALSE),
        ('ENT003', 'Tequenos', 'Deditos de queso venezolanos (12 pzas)', 1, 7.00, 12, FALSE),
        ('ENT004', 'Empanadas', 'De carne mechada, pollo o queso', 1, 6.00, 8, FALSE);

        -- Pastas
        INSERT INTO "RestauranteProductos" ("Codigo", "Nombre", "Descripcion", "CategoriaId", "Precio", "TiempoPreparacion", "EsCompuesto") VALUES
        ('PAST001', 'Pasta Carbonara', 'Con huevo, queso parmesano y panceta', 3, 15.00, 20, TRUE),
        ('PAST002', 'Lasagna', 'Casera con carne molida y bechamel', 3, 16.00, 25, FALSE),
        ('PAST003', 'Raviolis de Carne', 'Con salsa roja napolitana', 3, 14.00, 22, FALSE),
        ('PAST004', 'Gnocchi al Pesto', 'Pesto genovese artesanal', 3, 13.00, 18, FALSE);

        -- Carnes
        INSERT INTO "RestauranteProductos" ("Codigo", "Nombre", "Descripcion", "CategoriaId", "Precio", "TiempoPreparacion", "EsCompuesto") VALUES
        ('CARNE001', 'Filete de Res', 'Con vegetales grillados 300g', 4, 25.00, 30, TRUE),
        ('CARNE002', 'Costillas BBQ', 'Medio rack con salsa barbecue', 4, 22.00, 25, FALSE),
        ('CARNE003', 'Pollo a la Plancha', 'Pechuga marinada con especias', 4, 18.00, 20, FALSE);

        -- Bebidas
        INSERT INTO "RestauranteProductos" ("Codigo", "Nombre", "Descripcion", "CategoriaId", "Precio", "TiempoPreparacion") VALUES
        ('BEB001', 'Coca Cola', NULL, 7, 3.00, 0),
        ('BEB002', 'Agua Mineral', NULL, 7, 2.00, 0),
        ('BEB003', 'Cerveza Artesanal', NULL, 7, 5.00, 0),
        ('BEB004', 'Jugo de Naranja', 'Natural recien exprimido', 7, 4.00, 3);

        -- Postres
        INSERT INTO "RestauranteProductos" ("Codigo", "Nombre", "Descripcion", "CategoriaId", "Precio", "TiempoPreparacion") VALUES
        ('POST001', 'Tiramisu', 'Postre italiano clasico', 9, 8.00, 5),
        ('POST002', 'Flan Casero', 'Con dulce de leche artesanal', 9, 6.00, 2);

        -- Sugerencia del dia
        UPDATE "RestauranteProductos" SET "EsSugerenciaDelDia" = TRUE WHERE "Codigo" IN ('ENT002', 'CARNE001');

        -- Componentes para Pasta Carbonara
        SELECT "Id" INTO v_pasta_id FROM "RestauranteProductos" WHERE "Codigo" = 'PAST001';
        INSERT INTO "RestauranteProductoComponentes" ("ProductoId", "Nombre", "Obligatorio", "Orden") VALUES
        (v_pasta_id, 'Tipo de Pasta', TRUE, 1),
        (v_pasta_id, 'Extra Queso', FALSE, 2);

        SELECT "Id" INTO v_comp_pasta1 FROM "RestauranteProductoComponentes" WHERE "ProductoId" = v_pasta_id AND "Orden" = 1;
        SELECT "Id" INTO v_comp_pasta2 FROM "RestauranteProductoComponentes" WHERE "ProductoId" = v_pasta_id AND "Orden" = 2;

        INSERT INTO "RestauranteComponenteOpciones" ("ComponenteId", "Nombre", "Orden") VALUES
        (v_comp_pasta1, 'Spaghetti', 1),
        (v_comp_pasta1, 'Penne', 2),
        (v_comp_pasta1, 'Fettuccine', 3);
        INSERT INTO "RestauranteComponenteOpciones" ("ComponenteId", "Nombre", "Orden") VALUES
        (v_comp_pasta2, 'Si', 1),
        (v_comp_pasta2, 'No', 2);

        -- Componentes para Filete de Res
        SELECT "Id" INTO v_filete_id FROM "RestauranteProductos" WHERE "Codigo" = 'CARNE001';
        INSERT INTO "RestauranteProductoComponentes" ("ProductoId", "Nombre", "Obligatorio", "Orden") VALUES
        (v_filete_id, 'Coccion', TRUE, 1),
        (v_filete_id, 'Guarnicion', TRUE, 2);

        SELECT "Id" INTO v_comp_filete1 FROM "RestauranteProductoComponentes" WHERE "ProductoId" = v_filete_id AND "Orden" = 1;
        SELECT "Id" INTO v_comp_filete2 FROM "RestauranteProductoComponentes" WHERE "ProductoId" = v_filete_id AND "Orden" = 2;

        INSERT INTO "RestauranteComponenteOpciones" ("ComponenteId", "Nombre", "Orden") VALUES
        (v_comp_filete1, 'Poco hecho', 1),
        (v_comp_filete1, 'Al punto', 2),
        (v_comp_filete1, 'Bien hecho', 3);
        INSERT INTO "RestauranteComponenteOpciones" ("ComponenteId", "Nombre", "Orden") VALUES
        (v_comp_filete2, 'Papas fritas', 1),
        (v_comp_filete2, 'Ensalada', 2),
        (v_comp_filete2, 'Arroz', 3);
    END IF;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════
-- FUNCIONES — ADMINISTRATIVOS DEL RESTAURANTE
-- ═══════════════════════════════════════════════════════════════════

-- ─── Ambientes ───
CREATE OR REPLACE FUNCTION usp_rest_ambientes_list()
RETURNS TABLE(
    "id"     INT,
    "nombre" VARCHAR,
    "color"  VARCHAR,
    "orden"  INT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT "Id", "Nombre", "Color", "Orden"
    FROM "RestauranteAmbientes" WHERE "Activo" = TRUE ORDER BY "Orden";
END;
$$;

CREATE OR REPLACE FUNCTION usp_rest_ambiente_upsert(
    p_id     INT DEFAULT 0,
    p_nombre VARCHAR(50) DEFAULT '',
    p_color  VARCHAR(10) DEFAULT '#4CAF50',
    p_orden  INT DEFAULT 0
)
RETURNS TABLE(
    "ResultId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteAmbientes" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteAmbientes" SET "Nombre" = p_nombre, "Color" = p_color, "Orden" = p_orden WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteAmbientes" ("Nombre", "Color", "Orden") VALUES (p_nombre, p_color, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;

-- ─── Categorias del Menu ───
CREATE OR REPLACE FUNCTION usp_rest_categorias_list()
RETURNS TABLE(
    "id"           INT,
    "nombre"       VARCHAR,
    "descripcion"  VARCHAR,
    "color"        VARCHAR,
    "orden"        INT,
    "productCount" BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT c."Id", c."Nombre", c."Descripcion", c."Color", c."Orden",
        (SELECT COUNT(1) FROM "RestauranteProductos" p WHERE p."CategoriaId" = c."Id" AND p."Activo" = TRUE)
    FROM "RestauranteCategorias" c WHERE c."Activa" = TRUE ORDER BY c."Orden";
END;
$$;

CREATE OR REPLACE FUNCTION usp_rest_categoria_upsert(
    p_id          INT DEFAULT 0,
    p_nombre      VARCHAR(50) DEFAULT '',
    p_descripcion VARCHAR(200) DEFAULT NULL,
    p_color       VARCHAR(10) DEFAULT NULL,
    p_orden       INT DEFAULT 0
)
RETURNS TABLE(
    "ResultId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteCategorias" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteCategorias" SET "Nombre" = p_nombre, "Descripcion" = p_descripcion, "Color" = p_color, "Orden" = p_orden WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteCategorias" ("Nombre", "Descripcion", "Color", "Orden") VALUES (p_nombre, p_descripcion, p_color, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;

-- ─── Productos del Menu ───
CREATE OR REPLACE FUNCTION usp_rest_productos_list(
    p_categoria_id     INT DEFAULT NULL,
    p_search           VARCHAR(100) DEFAULT NULL,
    p_solo_disponibles BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(
    "id"                 INT,
    "codigo"             VARCHAR,
    "nombre"             VARCHAR,
    "descripcion"        VARCHAR,
    "precio"             NUMERIC,
    "categoriaId"        INT,
    "categoria"          VARCHAR,
    "esCompuesto"        BOOLEAN,
    "tiempoPreparacion"  INT,
    "imagen"             VARCHAR,
    "esSugerenciaDelDia" BOOLEAN,
    "disponible"         BOOLEAN,
    "iva"                NUMERIC,
    "costoEstimado"      NUMERIC
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."Id",
        p."Codigo",
        p."Nombre",
        p."Descripcion",
        p."Precio",
        p."CategoriaId",
        c."Nombre",
        p."EsCompuesto",
        p."TiempoPreparacion",
        p."Imagen",
        p."EsSugerenciaDelDia",
        p."Disponible",
        p."IVA",
        p."CostoEstimado"
    FROM "RestauranteProductos" p
    LEFT JOIN "RestauranteCategorias" c ON c."Id" = p."CategoriaId"
    WHERE p."Activo" = TRUE
      AND (p_solo_disponibles = FALSE OR p."Disponible" = TRUE)
      AND (p_categoria_id IS NULL OR p."CategoriaId" = p_categoria_id)
      AND (p_search IS NULL OR p."Nombre" ILIKE '%' || p_search || '%' OR p."Codigo" ILIKE '%' || p_search || '%')
    ORDER BY c."Orden", p."Nombre";
END;
$$;

CREATE OR REPLACE FUNCTION usp_rest_producto_get(
    p_id INT
)
RETURNS TABLE(
    "id"                    INT,
    "codigo"                VARCHAR,
    "nombre"                VARCHAR,
    "descripcion"           VARCHAR,
    "precio"                NUMERIC,
    "categoriaId"           INT,
    "categoria"             VARCHAR,
    "esCompuesto"           BOOLEAN,
    "tiempoPreparacion"     INT,
    "imagen"                VARCHAR,
    "esSugerenciaDelDia"    BOOLEAN,
    "disponible"            BOOLEAN,
    "iva"                   NUMERIC,
    "costoEstimado"         NUMERIC,
    "articuloInventarioId"  VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."Id", p."Codigo", p."Nombre", p."Descripcion",
        p."Precio", p."CategoriaId", c."Nombre",
        p."EsCompuesto", p."TiempoPreparacion",
        p."Imagen", p."EsSugerenciaDelDia",
        p."Disponible", p."IVA", p."CostoEstimado",
        p."ArticuloInventarioId"
    FROM "RestauranteProductos" p
    LEFT JOIN "RestauranteCategorias" c ON c."Id" = p."CategoriaId"
    WHERE p."Id" = p_id;
END;
$$;

-- Componentes con opciones (segundo result set del SP original)
CREATE OR REPLACE FUNCTION usp_rest_producto_get_componentes(
    p_id INT
)
RETURNS TABLE(
    "id"            INT,
    "nombre"        VARCHAR,
    "obligatorio"   BOOLEAN,
    "orden"         INT,
    "opcionId"      INT,
    "opcionNombre"  VARCHAR,
    "precioExtra"   NUMERIC,
    "opcionOrden"   INT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        comp."Id", comp."Nombre", comp."Obligatorio", comp."Orden",
        opc."Id", opc."Nombre", opc."PrecioExtra", opc."Orden"
    FROM "RestauranteProductoComponentes" comp
    LEFT JOIN "RestauranteComponenteOpciones" opc ON opc."ComponenteId" = comp."Id"
    WHERE comp."ProductoId" = p_id
    ORDER BY comp."Orden", opc."Orden";
END;
$$;

-- Receta (tercer result set del SP original)
CREATE OR REPLACE FUNCTION usp_rest_producto_get_receta(
    p_id INT
)
RETURNS TABLE(
    "id"               INT,
    "inventarioId"     VARCHAR,
    "inventarioNombre" VARCHAR,
    "cantidad"         NUMERIC,
    "unidad"           VARCHAR,
    "comentario"       VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        r."Id", r."InventarioId",
        i."ProductName",
        r."Cantidad", r."Unidad", r."Comentario"
    FROM "RestauranteRecetas" r
    LEFT JOIN master."Product" i ON i."ProductCode" = r."InventarioId"
    WHERE r."ProductoId" = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION usp_rest_producto_upsert(
    p_id                     INT DEFAULT 0,
    p_codigo                 VARCHAR(20) DEFAULT '',
    p_nombre                 VARCHAR(200) DEFAULT '',
    p_descripcion            VARCHAR(500) DEFAULT NULL,
    p_categoria_id           INT DEFAULT NULL,
    p_precio                 NUMERIC(18,2) DEFAULT 0,
    p_costo_estimado         NUMERIC(18,2) DEFAULT 0,
    p_iva                    NUMERIC(5,2) DEFAULT 16,
    p_es_compuesto           BOOLEAN DEFAULT FALSE,
    p_tiempo_preparacion     INT DEFAULT 0,
    p_imagen                 VARCHAR(500) DEFAULT NULL,
    p_es_sugerencia_del_dia  BOOLEAN DEFAULT FALSE,
    p_disponible             BOOLEAN DEFAULT TRUE,
    p_articulo_inventario_id VARCHAR(15) DEFAULT NULL
)
RETURNS TABLE(
    "ResultId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteProductos" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteProductos" SET
            "Codigo" = p_codigo, "Nombre" = p_nombre, "Descripcion" = p_descripcion,
            "CategoriaId" = p_categoria_id, "Precio" = p_precio, "CostoEstimado" = p_costo_estimado,
            "IVA" = p_iva, "EsCompuesto" = p_es_compuesto, "TiempoPreparacion" = p_tiempo_preparacion,
            "Imagen" = p_imagen, "EsSugerenciaDelDia" = p_es_sugerencia_del_dia,
            "Disponible" = p_disponible, "ArticuloInventarioId" = p_articulo_inventario_id,
            "FechaModificacion" = NOW() AT TIME ZONE 'UTC'
        WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteProductos" ("Codigo", "Nombre", "Descripcion", "CategoriaId", "Precio", "CostoEstimado", "IVA", "EsCompuesto", "TiempoPreparacion", "Imagen", "EsSugerenciaDelDia", "Disponible", "ArticuloInventarioId")
        VALUES (p_codigo, p_nombre, p_descripcion, p_categoria_id, p_precio, p_costo_estimado, p_iva, p_es_compuesto, p_tiempo_preparacion, p_imagen, p_es_sugerencia_del_dia, p_disponible, p_articulo_inventario_id)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;

CREATE OR REPLACE FUNCTION usp_rest_producto_delete(
    p_id INT
)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "RestauranteProductos" SET "Activo" = FALSE WHERE "Id" = p_id;
END;
$$;

-- ─── Componentes de Producto ───
CREATE OR REPLACE FUNCTION usp_rest_componente_upsert(
    p_id          INT DEFAULT 0,
    p_producto_id INT DEFAULT 0,
    p_nombre      VARCHAR(100) DEFAULT '',
    p_obligatorio BOOLEAN DEFAULT FALSE,
    p_orden       INT DEFAULT 0
)
RETURNS TABLE(
    "ResultId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteProductoComponentes" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteProductoComponentes" SET "Nombre" = p_nombre, "Obligatorio" = p_obligatorio, "Orden" = p_orden WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteProductoComponentes" ("ProductoId", "Nombre", "Obligatorio", "Orden") VALUES (p_producto_id, p_nombre, p_obligatorio, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;

CREATE OR REPLACE FUNCTION usp_rest_opcion_upsert(
    p_id            INT DEFAULT 0,
    p_componente_id INT DEFAULT 0,
    p_nombre        VARCHAR(100) DEFAULT '',
    p_precio_extra  NUMERIC(18,2) DEFAULT 0,
    p_orden         INT DEFAULT 0
)
RETURNS TABLE(
    "ResultId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteComponenteOpciones" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteComponenteOpciones" SET "Nombre" = p_nombre, "PrecioExtra" = p_precio_extra, "Orden" = p_orden WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteComponenteOpciones" ("ComponenteId", "Nombre", "PrecioExtra", "Orden") VALUES (p_componente_id, p_nombre, p_precio_extra, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;

-- ─── Compras Restaurante ───
CREATE OR REPLACE FUNCTION usp_rest_compras_list(
    p_estado VARCHAR(20) DEFAULT NULL,
    p_from   TIMESTAMP   DEFAULT NULL,
    p_to     TIMESTAMP   DEFAULT NULL
)
RETURNS TABLE(
    "id"               INT,
    "numCompra"        VARCHAR,
    "proveedorId"      VARCHAR,
    "proveedorNombre"  VARCHAR,
    "fechaCompra"      TIMESTAMP,
    "fechaRecepcion"   TIMESTAMP,
    "estado"           VARCHAR,
    "subtotal"         NUMERIC,
    "iva"              NUMERIC,
    "total"            NUMERIC,
    "observaciones"    VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."Id", c."NumCompra",
        c."ProveedorId",
        p."SupplierName",
        c."FechaCompra", c."FechaRecepcion",
        c."Estado", c."Subtotal", c."IVA", c."Total",
        c."Observaciones"
    FROM "RestauranteCompras" c
    LEFT JOIN master."Supplier" p ON p."SupplierCode" = c."ProveedorId"
    WHERE (COALESCE(p."IsDeleted", FALSE) = FALSE OR p."SupplierCode" IS NULL)
      AND (p_estado IS NULL OR c."Estado" = p_estado)
      AND (p_from IS NULL OR c."FechaCompra" >= p_from)
      AND (p_to IS NULL OR c."FechaCompra" <= p_to)
    ORDER BY c."FechaCompra" DESC;
END;
$$;

CREATE OR REPLACE FUNCTION usp_rest_compra_crear(
    p_proveedor_id   VARCHAR(12) DEFAULT NULL,
    p_observaciones  VARCHAR(500) DEFAULT NULL,
    p_cod_usuario    VARCHAR(10) DEFAULT NULL,
    p_detalle_json   JSONB DEFAULT '[]'::JSONB
)
RETURNS TABLE(
    "CompraId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_compra_id  INT;
    v_num_compra VARCHAR(20);
    v_seq        INT;
BEGIN
    SELECT COALESCE(MAX("Id"), 0) + 1 INTO v_seq FROM "RestauranteCompras";
    v_num_compra := 'RC-' || REPLACE(TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM'), '-',''::VARCHAR) || '-' || LPAD(v_seq::TEXT, 4, '0');

    INSERT INTO "RestauranteCompras" ("NumCompra", "ProveedorId", "Estado", "Observaciones", "CodUsuario")
    VALUES (v_num_compra, p_proveedor_id, 'pendiente', p_observaciones, p_cod_usuario)
    RETURNING "Id" INTO v_compra_id;

    INSERT INTO "RestauranteComprasDetalle" ("CompraId", "InventarioId", "Descripcion", "Cantidad", "PrecioUnit", "Subtotal", "IVA")
    SELECT
        v_compra_id,
        (item->>'invId')::VARCHAR(15),
        (item->>'desc')::VARCHAR(200),
        (item->>'cant')::NUMERIC(10,3),
        (item->>'precio')::NUMERIC(18,2),
        (item->>'cant')::NUMERIC(10,3) * (item->>'precio')::NUMERIC(18,2),
        COALESCE((item->>'iva')::NUMERIC(5,2), 16)
    FROM jsonb_array_elements(p_detalle_json) AS item;

    UPDATE "RestauranteCompras" SET
        "Subtotal" = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id),
        "IVA" = (SELECT COALESCE(SUM("Subtotal" * "IVA" / 100), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id),
        "Total" = (SELECT COALESCE(SUM("Subtotal" + "Subtotal" * "IVA" / 100), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id)
    WHERE "Id" = v_compra_id;

    RETURN QUERY SELECT v_compra_id;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;

-- ─── Receta (ingredientes) ───
CREATE OR REPLACE FUNCTION usp_rest_receta_upsert(
    p_id            INT DEFAULT 0,
    p_producto_id   INT DEFAULT 0,
    p_inventario_id VARCHAR(15) DEFAULT '',
    p_cantidad      NUMERIC(10,3) DEFAULT 0,
    p_unidad        VARCHAR(20) DEFAULT NULL,
    p_comentario    VARCHAR(200) DEFAULT NULL
)
RETURNS TABLE(
    "ResultId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteRecetas" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteRecetas" SET "InventarioId" = p_inventario_id, "Cantidad" = p_cantidad, "Unidad" = p_unidad, "Comentario" = p_comentario WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteRecetas" ("ProductoId", "InventarioId", "Cantidad", "Unidad", "Comentario") VALUES (p_producto_id, p_inventario_id, p_cantidad, p_unidad, p_comentario)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$$;
