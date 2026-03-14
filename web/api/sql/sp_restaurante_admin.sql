-- ═══════════════════════════════════════════════════════════════════
-- DatqBox Restaurante — Subsistema Administrativo Completo
-- Tablas: Ambientes, Productos del Menú, Categorías, Componentes,
--         Compras Restaurante y Proveedores (usa Proveedores comunes)
-- Referencias a dbo.Proveedores actualizadas a master.Supplier (SupplierCode, SupplierName).
-- Referencias a dbo.Inventario actualizadas a master.Product (ProductCode, ProductName).
-- ═══════════════════════════════════════════════════════════════════

-- =============================================
-- 1. AMBIENTES (Salón, Terraza, Barra, etc.)
-- =============================================
IF OBJECT_ID('dbo.RestauranteAmbientes', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.RestauranteAmbientes (
    Id         INT IDENTITY(1,1) PRIMARY KEY,
    Nombre     NVARCHAR(50) NOT NULL,
    Color      NVARCHAR(10) NOT NULL DEFAULT '#4CAF50',
    Activo     BIT NOT NULL DEFAULT 1,
    Orden      INT NOT NULL DEFAULT 0
  );

  INSERT INTO RestauranteAmbientes (Nombre, Color, Orden) VALUES
  (N'Salón Principal', '#4CAF50', 1),
  (N'Terraza', '#FF9800', 2),
  (N'Barra', '#9C27B0', 3);
END
GO

-- =============================================
-- 2. Alterar RestauranteMesas: FK a Ambientes
-- =============================================
-- Añadir columna ColorAmbiente si no existe
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='RestauranteMesas' AND COLUMN_NAME='ColorAmbiente')
  ALTER TABLE RestauranteMesas ADD ColorAmbiente NVARCHAR(10) NULL DEFAULT '#4CAF50';
GO

-- =============================================
-- 3. CATEGORÍAS DEL MENÚ (Entradas, Pastas, Carnes, Bebidas, Postres)
-- =============================================
IF OBJECT_ID('dbo.RestauranteCategorias', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.RestauranteCategorias (
    Id         INT IDENTITY(1,1) PRIMARY KEY,
    Nombre     NVARCHAR(50) NOT NULL,
    Descripcion NVARCHAR(200) NULL,
    Color      NVARCHAR(10) NULL DEFAULT '#E0E0E0',
    Orden      INT NOT NULL DEFAULT 0,
    Activa     BIT NOT NULL DEFAULT 1
  );

  INSERT INTO RestauranteCategorias (Nombre, Orden) VALUES
  (N'Entradas', 1),
  (N'Sopas', 2),
  (N'Pastas', 3),
  (N'Carnes', 4),
  (N'Mariscos', 5),
  (N'Ensaladas', 6),
  (N'Bebidas', 7),
  (N'Cócteles', 8),
  (N'Postres', 9);
END
GO

-- =============================================
-- 4. PRODUCTOS DEL MENÚ (tabla propia del restaurante)
-- =============================================
IF OBJECT_ID('dbo.RestauranteProductos', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.RestauranteProductos (
    Id                  INT IDENTITY(1,1) PRIMARY KEY,
    Codigo              NVARCHAR(20) NOT NULL,
    Nombre              NVARCHAR(200) NOT NULL,
    Descripcion         NVARCHAR(500) NULL,
    CategoriaId         INT NULL,
    Precio              DECIMAL(18,2) NOT NULL DEFAULT 0,
    CostoEstimado       DECIMAL(18,2) NULL DEFAULT 0, -- Costo de receta / materia prima
    IVA                 DECIMAL(5,2) NOT NULL DEFAULT 16,
    EsCompuesto         BIT NOT NULL DEFAULT 0,       -- Producto con opciones/componentes
    TiempoPreparacion   INT NOT NULL DEFAULT 0,       -- Minutos
    Imagen              NVARCHAR(500) NULL,
    EsSugerenciaDelDia  BIT NOT NULL DEFAULT 0,
    Disponible          BIT NOT NULL DEFAULT 1,
    Activo              BIT NOT NULL DEFAULT 1,
    -- Referencia cruzada: si este plato consume artículos del inventario principal
    ArticuloInventarioId NVARCHAR(15) NULL,            -- FK opcional a master.Product.ProductCode
    FechaCreacion       DATETIME NOT NULL DEFAULT GETDATE(),
    FechaModificacion   DATETIME NULL,
    CONSTRAINT FK_RestProd_Cat FOREIGN KEY (CategoriaId) REFERENCES RestauranteCategorias(Id),
    CONSTRAINT UQ_RestProd_Codigo UNIQUE (Codigo)
  );
END
GO

-- =============================================
-- 5. COMPONENTES / OPCIONES DE PRODUCTOS COMPUESTOS
--    Ej: "Tipo de Pasta" con opciones "Spaghetti, Penne, Fettuccine"
-- =============================================
IF OBJECT_ID('dbo.RestauranteProductoComponentes', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.RestauranteProductoComponentes (
    Id           INT IDENTITY(1,1) PRIMARY KEY,
    ProductoId   INT NOT NULL,
    Nombre       NVARCHAR(100) NOT NULL, -- "Tipo de Pasta", "Cocción", "Guarnición"
    Obligatorio  BIT NOT NULL DEFAULT 0,
    Orden        INT NOT NULL DEFAULT 0,
    CONSTRAINT FK_RestComp_Prod FOREIGN KEY (ProductoId) REFERENCES RestauranteProductos(Id) ON DELETE CASCADE
  );
END
GO

IF OBJECT_ID('dbo.RestauranteComponenteOpciones', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.RestauranteComponenteOpciones (
    Id             INT IDENTITY(1,1) PRIMARY KEY,
    ComponenteId   INT NOT NULL,
    Nombre         NVARCHAR(100) NOT NULL, -- "Spaghetti", "Penne", "Fettuccine"
    PrecioExtra    DECIMAL(18,2) NOT NULL DEFAULT 0,
    Orden          INT NOT NULL DEFAULT 0,
    CONSTRAINT FK_RestOpc_Comp FOREIGN KEY (ComponenteId) REFERENCES RestauranteProductoComponentes(Id) ON DELETE CASCADE
  );
END
GO

-- =============================================
-- 6. RECETAS (consumo de materias primas del inventario)
-- =============================================
IF OBJECT_ID('dbo.RestauranteRecetas', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.RestauranteRecetas (
    Id            INT IDENTITY(1,1) PRIMARY KEY,
    ProductoId    INT NOT NULL,               -- Plato del menú
    InventarioId  NVARCHAR(15) NOT NULL,      -- Materia prima del inventario principal (= master.Product.ProductCode)
    Cantidad      DECIMAL(10,3) NOT NULL,     -- Cantidad por porción
    Unidad        NVARCHAR(20) NULL,          -- KG, LT, UNID, etc.
    Comentario    NVARCHAR(200) NULL,
    CONSTRAINT FK_RestReceta_Prod FOREIGN KEY (ProductoId) REFERENCES RestauranteProductos(Id) ON DELETE CASCADE
  );
END
GO

-- =============================================
-- 7. COMPRAS DEL RESTAURANTE (usa master.Supplier + generación de compras)
-- =============================================
IF OBJECT_ID('dbo.RestauranteCompras', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.RestauranteCompras (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    NumCompra       NVARCHAR(20) NOT NULL,
    ProveedorId     NVARCHAR(12) NULL,    -- FK a master.Supplier.SupplierCode (tabla canonica)
    FechaCompra     DATETIME NOT NULL DEFAULT GETDATE(),
    FechaRecepcion  DATETIME NULL,
    Estado          NVARCHAR(20) NOT NULL DEFAULT 'pendiente', -- pendiente, recibida, anulada
    Subtotal        DECIMAL(18,2) NOT NULL DEFAULT 0,
    IVA             DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total           DECIMAL(18,2) NOT NULL DEFAULT 0,
    Observaciones   NVARCHAR(500) NULL,
    CodUsuario      NVARCHAR(10) NULL,
    CONSTRAINT UQ_RestCompra_Num UNIQUE (NumCompra)
  );
END
GO

IF OBJECT_ID('dbo.RestauranteComprasDetalle', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.RestauranteComprasDetalle (
    Id            INT IDENTITY(1,1) PRIMARY KEY,
    CompraId      INT NOT NULL,
    InventarioId  NVARCHAR(15) NULL,    -- Material del inventario (= master.Product.ProductCode)
    Descripcion   NVARCHAR(200) NOT NULL,
    Cantidad      DECIMAL(10,3) NOT NULL,
    PrecioUnit    DECIMAL(18,2) NOT NULL,
    Subtotal      DECIMAL(18,2) NOT NULL,
    IVA           DECIMAL(5,2) NOT NULL DEFAULT 16,
    CONSTRAINT FK_RestCompDet_Compra FOREIGN KEY (CompraId) REFERENCES RestauranteCompras(Id) ON DELETE CASCADE
  );
END
GO

-- =============================================
-- 8. SEED: Datos iniciales de productos del menú
-- =============================================
IF NOT EXISTS (SELECT 1 FROM RestauranteProductos)
BEGIN
  -- Entradas
  INSERT INTO RestauranteProductos (Codigo, Nombre, Descripcion, CategoriaId, Precio, TiempoPreparacion, EsCompuesto) VALUES
  ('ENT001', N'Bruschetta', N'Pan tostado con tomate fresco y albahaca', 1, 8.00, 10, 0),
  ('ENT002', N'Calamares Fritos', N'Con salsa tártara casera', 1, 12.00, 15, 0),
  ('ENT003', N'Tequeños', N'Deditos de queso venezolanos (12 pzas)', 1, 7.00, 12, 0),
  ('ENT004', N'Empanadas', N'De carne mechada, pollo o queso', 1, 6.00, 8, 0);

  -- Pastas
  INSERT INTO RestauranteProductos (Codigo, Nombre, Descripcion, CategoriaId, Precio, TiempoPreparacion, EsCompuesto) VALUES
  ('PAST001', N'Pasta Carbonara', N'Con huevo, queso parmesano y panceta', 3, 15.00, 20, 1),
  ('PAST002', N'Lasagna', N'Casera con carne molida y bechamel', 3, 16.00, 25, 0),
  ('PAST003', N'Raviolis de Carne', N'Con salsa roja napolitana', 3, 14.00, 22, 0),
  ('PAST004', N'Gnocchi al Pesto', N'Pesto genovese artesanal', 3, 13.00, 18, 0);

  -- Carnes
  INSERT INTO RestauranteProductos (Codigo, Nombre, Descripcion, CategoriaId, Precio, TiempoPreparacion, EsCompuesto) VALUES
  ('CARNE001', N'Filete de Res', N'Con vegetales grillados 300g', 4, 25.00, 30, 1),
  ('CARNE002', N'Costillas BBQ', N'Medio rack con salsa barbecue', 4, 22.00, 25, 0),
  ('CARNE003', N'Pollo a la Plancha', N'Pechuga marinada con especias', 4, 18.00, 20, 0);

  -- Bebidas
  INSERT INTO RestauranteProductos (Codigo, Nombre, Descripcion, CategoriaId, Precio, TiempoPreparacion) VALUES
  ('BEB001', N'Coca Cola', NULL, 7, 3.00, 0),
  ('BEB002', N'Agua Mineral', NULL, 7, 2.00, 0),
  ('BEB003', N'Cerveza Artesanal', NULL, 7, 5.00, 0),
  ('BEB004', N'Jugo de Naranja', N'Natural recién exprimido', 7, 4.00, 3);

  -- Postres
  INSERT INTO RestauranteProductos (Codigo, Nombre, Descripcion, CategoriaId, Precio, TiempoPreparacion) VALUES
  ('POST001', N'Tiramisú', N'Postre italiano clásico', 9, 8.00, 5),
  ('POST002', N'Flan Casero', N'Con dulce de leche artesanal', 9, 6.00, 2);

  -- Sugerencia del día
  UPDATE RestauranteProductos SET EsSugerenciaDelDia = 1 WHERE Codigo IN ('ENT002', 'CARNE001');

  -- Componentes para Pasta Carbonara
  DECLARE @PastaId INT = (SELECT Id FROM RestauranteProductos WHERE Codigo = 'PAST001');
  INSERT INTO RestauranteProductoComponentes (ProductoId, Nombre, Obligatorio, Orden) VALUES
  (@PastaId, N'Tipo de Pasta', 1, 1),
  (@PastaId, N'Extra Queso', 0, 2);

  DECLARE @CompPasta1 INT = (SELECT Id FROM RestauranteProductoComponentes WHERE ProductoId = @PastaId AND Orden = 1);
  DECLARE @CompPasta2 INT = (SELECT Id FROM RestauranteProductoComponentes WHERE ProductoId = @PastaId AND Orden = 2);

  INSERT INTO RestauranteComponenteOpciones (ComponenteId, Nombre, Orden) VALUES
  (@CompPasta1, 'Spaghetti', 1),
  (@CompPasta1, 'Penne', 2),
  (@CompPasta1, 'Fettuccine', 3);
  INSERT INTO RestauranteComponenteOpciones (ComponenteId, Nombre, Orden) VALUES
  (@CompPasta2, N'Sí', 1),
  (@CompPasta2, N'No', 2);

  -- Componentes para Filete de Res
  DECLARE @FileteId INT = (SELECT Id FROM RestauranteProductos WHERE Codigo = 'CARNE001');
  INSERT INTO RestauranteProductoComponentes (ProductoId, Nombre, Obligatorio, Orden) VALUES
  (@FileteId, N'Cocción', 1, 1),
  (@FileteId, N'Guarnición', 1, 2);

  DECLARE @CompFilete1 INT = (SELECT Id FROM RestauranteProductoComponentes WHERE ProductoId = @FileteId AND Orden = 1);
  DECLARE @CompFilete2 INT = (SELECT Id FROM RestauranteProductoComponentes WHERE ProductoId = @FileteId AND Orden = 2);

  INSERT INTO RestauranteComponenteOpciones (ComponenteId, Nombre, Orden) VALUES
  (@CompFilete1, 'Poco hecho', 1),
  (@CompFilete1, 'Al punto', 2),
  (@CompFilete1, 'Bien hecho', 3);
  INSERT INTO RestauranteComponenteOpciones (ComponenteId, Nombre, Orden) VALUES
  (@CompFilete2, 'Papas fritas', 1),
  (@CompFilete2, 'Ensalada', 2),
  (@CompFilete2, 'Arroz', 3);
END
GO

-- ═══════════════════════════════════════════════════════════════════
-- STORED PROCEDURES — ADMINISTRATIVOS DEL RESTAURANTE
-- ═══════════════════════════════════════════════════════════════════

-- ─── Ambientes ───
IF OBJECT_ID('usp_REST_Ambientes_List', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Ambientes_List;
GO
CREATE PROCEDURE usp_REST_Ambientes_List
AS
BEGIN
  SET NOCOUNT ON;
  SELECT Id AS id, Nombre AS nombre, Color AS color, Orden AS orden
  FROM RestauranteAmbientes WHERE Activo = 1 ORDER BY Orden;
END
GO

IF OBJECT_ID('usp_REST_Ambiente_Upsert', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Ambiente_Upsert;
GO
CREATE PROCEDURE usp_REST_Ambiente_Upsert
  @Id     INT = 0,
  @Nombre NVARCHAR(50),
  @Color  NVARCHAR(10) = '#4CAF50',
  @Orden  INT = 0,
  @ResultId INT = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF @Id > 0 AND EXISTS (SELECT 1 FROM RestauranteAmbientes WHERE Id = @Id)
  BEGIN
    UPDATE RestauranteAmbientes SET Nombre=@Nombre, Color=@Color, Orden=@Orden WHERE Id=@Id;
    SET @ResultId = @Id;
  END
  ELSE
  BEGIN
    INSERT INTO RestauranteAmbientes (Nombre, Color, Orden) VALUES (@Nombre, @Color, @Orden);
    SET @ResultId = SCOPE_IDENTITY();
  END
END
GO

-- ─── Categorías del Menú ───
IF OBJECT_ID('usp_REST_Categorias_List', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Categorias_List;
GO
CREATE PROCEDURE usp_REST_Categorias_List
AS
BEGIN
  SET NOCOUNT ON;
  SELECT c.Id AS id, c.Nombre AS nombre, c.Descripcion AS descripcion, c.Color AS color, c.Orden AS orden,
    (SELECT COUNT(1) FROM RestauranteProductos p WHERE p.CategoriaId = c.Id AND p.Activo = 1) AS productCount
  FROM RestauranteCategorias c WHERE c.Activa = 1 ORDER BY c.Orden;
END
GO

IF OBJECT_ID('usp_REST_Categoria_Upsert', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Categoria_Upsert;
GO
CREATE PROCEDURE usp_REST_Categoria_Upsert
  @Id          INT = 0,
  @Nombre      NVARCHAR(50),
  @Descripcion NVARCHAR(200) = NULL,
  @Color       NVARCHAR(10) = NULL,
  @Orden       INT = 0,
  @ResultId    INT = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF @Id > 0 AND EXISTS (SELECT 1 FROM RestauranteCategorias WHERE Id = @Id)
  BEGIN
    UPDATE RestauranteCategorias SET Nombre=@Nombre, Descripcion=@Descripcion, Color=@Color, Orden=@Orden WHERE Id=@Id;
    SET @ResultId = @Id;
  END
  ELSE
  BEGIN
    INSERT INTO RestauranteCategorias (Nombre, Descripcion, Color, Orden) VALUES (@Nombre, @Descripcion, @Color, @Orden);
    SET @ResultId = SCOPE_IDENTITY();
  END
END
GO

-- ─── Productos del Menú ───
IF OBJECT_ID('usp_REST_Productos_List', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Productos_List;
GO
CREATE PROCEDURE usp_REST_Productos_List
  @CategoriaId INT = NULL,
  @Search      NVARCHAR(100) = NULL,
  @SoloDisponibles BIT = 1
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    p.Id AS id,
    p.Codigo AS codigo,
    p.Nombre AS nombre,
    p.Descripcion AS descripcion,
    p.Precio AS precio,
    p.CategoriaId AS categoriaId,
    c.Nombre AS categoria,
    p.EsCompuesto AS esCompuesto,
    p.TiempoPreparacion AS tiempoPreparacion,
    p.Imagen AS imagen,
    p.EsSugerenciaDelDia AS esSugerenciaDelDia,
    p.Disponible AS disponible,
    p.IVA AS iva,
    p.CostoEstimado AS costoEstimado
  FROM RestauranteProductos p
  LEFT JOIN RestauranteCategorias c ON c.Id = p.CategoriaId
  WHERE p.Activo = 1
    AND (@SoloDisponibles = 0 OR p.Disponible = 1)
    AND (@CategoriaId IS NULL OR p.CategoriaId = @CategoriaId)
    AND (@Search IS NULL OR p.Nombre LIKE '%' + @Search + '%' OR p.Codigo LIKE '%' + @Search + '%')
  ORDER BY c.Orden, p.Nombre;
END
GO

IF OBJECT_ID('usp_REST_Producto_Get', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Producto_Get;
GO
CREATE PROCEDURE usp_REST_Producto_Get
  @Id INT
AS
BEGIN
  SET NOCOUNT ON;
  -- Producto
  SELECT
    p.Id AS id, p.Codigo AS codigo, p.Nombre AS nombre, p.Descripcion AS descripcion,
    p.Precio AS precio, p.CategoriaId AS categoriaId, c.Nombre AS categoria,
    p.EsCompuesto AS esCompuesto, p.TiempoPreparacion AS tiempoPreparacion,
    p.Imagen AS imagen, p.EsSugerenciaDelDia AS esSugerenciaDelDia,
    p.Disponible AS disponible, p.IVA AS iva, p.CostoEstimado AS costoEstimado,
    p.ArticuloInventarioId AS articuloInventarioId
  FROM RestauranteProductos p
  LEFT JOIN RestauranteCategorias c ON c.Id = p.CategoriaId
  WHERE p.Id = @Id;

  -- Componentes con opciones
  SELECT
    comp.Id AS id, comp.Nombre AS nombre, comp.Obligatorio AS obligatorio, comp.Orden AS orden,
    opc.Id AS opcionId, opc.Nombre AS opcionNombre, opc.PrecioExtra AS precioExtra, opc.Orden AS opcionOrden
  FROM RestauranteProductoComponentes comp
  LEFT JOIN RestauranteComponenteOpciones opc ON opc.ComponenteId = comp.Id
  WHERE comp.ProductoId = @Id
  ORDER BY comp.Orden, opc.Orden;

  -- Receta (ingredientes del inventario)
  -- Ahora se usa master.Product (antes dbo.Inventario)
  SELECT
    r.Id AS id, r.InventarioId AS inventarioId,
    i.ProductName AS inventarioNombre,                -- ProductName = DESCRIPCION
    r.Cantidad AS cantidad, r.Unidad AS unidad, r.Comentario AS comentario
  FROM RestauranteRecetas r
  LEFT JOIN master.Product i ON i.ProductCode = r.InventarioId   -- ProductCode = CODIGO
  WHERE r.ProductoId = @Id;
END
GO

IF OBJECT_ID('usp_REST_Producto_Upsert', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Producto_Upsert;
GO
CREATE PROCEDURE usp_REST_Producto_Upsert
  @Id                INT = 0,
  @Codigo            NVARCHAR(20),
  @Nombre            NVARCHAR(200),
  @Descripcion       NVARCHAR(500) = NULL,
  @CategoriaId       INT = NULL,
  @Precio            DECIMAL(18,2) = 0,
  @CostoEstimado     DECIMAL(18,2) = 0,
  @IVA               DECIMAL(5,2) = 16,
  @EsCompuesto       BIT = 0,
  @TiempoPreparacion INT = 0,
  @Imagen            NVARCHAR(500) = NULL,
  @EsSugerenciaDelDia BIT = 0,
  @Disponible        BIT = 1,
  @ArticuloInventarioId NVARCHAR(15) = NULL,
  @ResultId          INT = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF @Id > 0 AND EXISTS (SELECT 1 FROM RestauranteProductos WHERE Id = @Id)
  BEGIN
    UPDATE RestauranteProductos SET
      Codigo=@Codigo, Nombre=@Nombre, Descripcion=@Descripcion,
      CategoriaId=@CategoriaId, Precio=@Precio, CostoEstimado=@CostoEstimado,
      IVA=@IVA, EsCompuesto=@EsCompuesto, TiempoPreparacion=@TiempoPreparacion,
      Imagen=@Imagen, EsSugerenciaDelDia=@EsSugerenciaDelDia,
      Disponible=@Disponible, ArticuloInventarioId=@ArticuloInventarioId,
      FechaModificacion=GETDATE()
    WHERE Id = @Id;
    SET @ResultId = @Id;
  END
  ELSE
  BEGIN
    INSERT INTO RestauranteProductos (Codigo, Nombre, Descripcion, CategoriaId, Precio, CostoEstimado, IVA, EsCompuesto, TiempoPreparacion, Imagen, EsSugerenciaDelDia, Disponible, ArticuloInventarioId)
    VALUES (@Codigo, @Nombre, @Descripcion, @CategoriaId, @Precio, @CostoEstimado, @IVA, @EsCompuesto, @TiempoPreparacion, @Imagen, @EsSugerenciaDelDia, @Disponible, @ArticuloInventarioId);
    SET @ResultId = SCOPE_IDENTITY();
  END
END
GO

IF OBJECT_ID('usp_REST_Producto_Delete', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Producto_Delete;
GO
CREATE PROCEDURE usp_REST_Producto_Delete @Id INT
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE RestauranteProductos SET Activo = 0 WHERE Id = @Id;
END
GO

-- ─── Componentes de Producto ───
IF OBJECT_ID('usp_REST_Componente_Upsert', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Componente_Upsert;
GO
CREATE PROCEDURE usp_REST_Componente_Upsert
  @Id          INT = 0,
  @ProductoId  INT,
  @Nombre      NVARCHAR(100),
  @Obligatorio BIT = 0,
  @Orden       INT = 0,
  @ResultId    INT = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF @Id > 0 AND EXISTS (SELECT 1 FROM RestauranteProductoComponentes WHERE Id = @Id)
  BEGIN
    UPDATE RestauranteProductoComponentes SET Nombre=@Nombre, Obligatorio=@Obligatorio, Orden=@Orden WHERE Id=@Id;
    SET @ResultId = @Id;
  END
  ELSE
  BEGIN
    INSERT INTO RestauranteProductoComponentes (ProductoId, Nombre, Obligatorio, Orden) VALUES (@ProductoId, @Nombre, @Obligatorio, @Orden);
    SET @ResultId = SCOPE_IDENTITY();
  END
END
GO

IF OBJECT_ID('usp_REST_Opcion_Upsert', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Opcion_Upsert;
GO
CREATE PROCEDURE usp_REST_Opcion_Upsert
  @Id           INT = 0,
  @ComponenteId INT,
  @Nombre       NVARCHAR(100),
  @PrecioExtra  DECIMAL(18,2) = 0,
  @Orden        INT = 0,
  @ResultId     INT = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF @Id > 0 AND EXISTS (SELECT 1 FROM RestauranteComponenteOpciones WHERE Id = @Id)
  BEGIN
    UPDATE RestauranteComponenteOpciones SET Nombre=@Nombre, PrecioExtra=@PrecioExtra, Orden=@Orden WHERE Id=@Id;
    SET @ResultId = @Id;
  END
  ELSE
  BEGIN
    INSERT INTO RestauranteComponenteOpciones (ComponenteId, Nombre, PrecioExtra, Orden) VALUES (@ComponenteId, @Nombre, @PrecioExtra, @Orden);
    SET @ResultId = SCOPE_IDENTITY();
  END
END
GO

-- ─── Compras Restaurante ───
IF OBJECT_ID('usp_REST_Compras_List', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Compras_List;
GO
CREATE PROCEDURE usp_REST_Compras_List
  @Estado NVARCHAR(20) = NULL,
  @From   DATETIME = NULL,
  @To     DATETIME = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    c.Id AS id, c.NumCompra AS numCompra,
    c.ProveedorId AS proveedorId,
    p.SupplierName AS proveedorNombre,              -- SupplierName = NOMBRE; ahora se usa master.Supplier
    c.FechaCompra AS fechaCompra, c.FechaRecepcion AS fechaRecepcion,
    c.Estado AS estado, c.Subtotal AS subtotal, c.IVA AS iva, c.Total AS total,
    c.Observaciones AS observaciones
  FROM RestauranteCompras c
  -- Ahora se usa master.Supplier (antes dbo.Proveedores)
  LEFT JOIN master.Supplier p ON p.SupplierCode = c.ProveedorId   -- SupplierCode = CODIGO
  WHERE ISNULL(p.IsDeleted, 0) = 0 OR p.SupplierCode IS NULL
    AND (@Estado IS NULL OR c.Estado = @Estado)
    AND (@From IS NULL OR c.FechaCompra >= @From)
    AND (@To IS NULL OR c.FechaCompra <= @To)
  ORDER BY c.FechaCompra DESC;
END
GO

IF OBJECT_ID('usp_REST_Compra_Crear', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Compra_Crear;
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE usp_REST_Compra_Crear
  @ProveedorId   NVARCHAR(12) = NULL,
  @Observaciones NVARCHAR(500) = NULL,
  @CodUsuario    NVARCHAR(10) = NULL,
  @DetalleXml    XML,  -- <items><item desc="" cant="" precio="" iva="" invId="" /></items>
  @CompraId      INT = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRAN;

    DECLARE @NumCompra NVARCHAR(20);
    DECLARE @Seq INT = (SELECT ISNULL(MAX(Id), 0) + 1 FROM RestauranteCompras);
    SET @NumCompra = 'RC-' + REPLACE(CONVERT(NVARCHAR(7), GETDATE(), 120), '-', '') + '-' + RIGHT('0000' + CAST(@Seq AS NVARCHAR), 4);

    INSERT INTO RestauranteCompras (NumCompra, ProveedorId, Estado, Observaciones, CodUsuario)
    VALUES (@NumCompra, @ProveedorId, 'pendiente', @Observaciones, @CodUsuario);
    SET @CompraId = SCOPE_IDENTITY();

    INSERT INTO RestauranteComprasDetalle (CompraId, InventarioId, Descripcion, Cantidad, PrecioUnit, Subtotal, IVA)
    SELECT
      @CompraId,
      t.c.value('@invId', 'NVARCHAR(15)'),
      t.c.value('@desc', 'NVARCHAR(200)'),
      t.c.value('@cant', 'DECIMAL(10,3)'),
      t.c.value('@precio', 'DECIMAL(18,2)'),
      t.c.value('@cant', 'DECIMAL(10,3)') * t.c.value('@precio', 'DECIMAL(18,2)'),
      ISNULL(t.c.value('@iva', 'DECIMAL(5,2)'), 16)
    FROM @DetalleXml.nodes('/items/item') t(c);

    UPDATE RestauranteCompras SET
      Subtotal = (SELECT ISNULL(SUM(Subtotal), 0) FROM RestauranteComprasDetalle WHERE CompraId = @CompraId),
      IVA = (SELECT ISNULL(SUM(Subtotal * IVA / 100), 0) FROM RestauranteComprasDetalle WHERE CompraId = @CompraId),
      Total = (SELECT ISNULL(SUM(Subtotal + Subtotal * IVA / 100), 0) FROM RestauranteComprasDetalle WHERE CompraId = @CompraId)
    WHERE Id = @CompraId;

    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END
GO

-- ─── Receta (ingredientes) ───
IF OBJECT_ID('usp_REST_Receta_Upsert', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Receta_Upsert;
GO
CREATE PROCEDURE usp_REST_Receta_Upsert
  @Id           INT = 0,
  @ProductoId   INT,
  @InventarioId NVARCHAR(15),
  @Cantidad     DECIMAL(10,3),
  @Unidad       NVARCHAR(20) = NULL,
  @Comentario   NVARCHAR(200) = NULL,
  @ResultId     INT = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF @Id > 0 AND EXISTS (SELECT 1 FROM RestauranteRecetas WHERE Id = @Id)
  BEGIN
    UPDATE RestauranteRecetas SET InventarioId=@InventarioId, Cantidad=@Cantidad, Unidad=@Unidad, Comentario=@Comentario WHERE Id=@Id;
    SET @ResultId = @Id;
  END
  ELSE
  BEGIN
    INSERT INTO RestauranteRecetas (ProductoId, InventarioId, Cantidad, Unidad, Comentario) VALUES (@ProductoId, @InventarioId, @Cantidad, @Unidad, @Comentario);
    SET @ResultId = SCOPE_IDENTITY();
  END
END
GO

PRINT N'Subsistema Administrativo Restaurante creado exitosamente.'
GO
