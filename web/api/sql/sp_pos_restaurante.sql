-- ═══════════════════════════════════════════════════════════════════
-- DatqBox POS & Restaurante — Stored Procedures
-- Productos para POS, Clientes POS, Mesas, Pedidos y Facturación
-- ═══════════════════════════════════════════════════════════════════

-- =============================================
-- 1. PRODUCTOS POS: Listar artículos para POS con precios y stock
-- =============================================
IF OBJECT_ID('usp_POS_Productos_List', 'P') IS NOT NULL DROP PROCEDURE usp_POS_Productos_List;
GO
CREATE PROCEDURE usp_POS_Productos_List
  @Search    NVARCHAR(100)  = NULL,
  @Categoria NVARCHAR(50)   = NULL,
  @AlmacenId NVARCHAR(10)   = NULL,
  @Page      INT            = 1,
  @Limit     INT            = 50,
  @TotalCount INT           = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Offset INT = (@Page - 1) * @Limit;

  -- Contar total
  SELECT @TotalCount = COUNT(1)
  FROM Inventario i
  WHERE (i.EXISTENCIA > 0 OR i.Servicio = 1)
    AND (@Search IS NULL
         OR i.CODIGO LIKE '%' + @Search + '%'
         OR i.DESCRIPCION LIKE '%' + @Search + '%'
         OR i.Referencia LIKE '%' + @Search + '%'
         OR i.Barra LIKE '%' + @Search + '%'
         OR i.Categoria LIKE '%' + @Search + '%')
    AND (@Categoria IS NULL OR i.Categoria = @Categoria);

  -- Resultados paginados con precios y DescripcionCompleta
  SELECT
    i.CODIGO        AS id,
    i.CODIGO        AS codigo,
    LTRIM(RTRIM(
      ISNULL(RTRIM(i.Categoria), '') +
      CASE WHEN RTRIM(ISNULL(i.Tipo, '')) <> '' THEN ' ' + RTRIM(i.Tipo) ELSE '' END +
      CASE WHEN RTRIM(ISNULL(i.DESCRIPCION, '')) <> '' THEN ' ' + RTRIM(i.DESCRIPCION) ELSE '' END +
      CASE WHEN RTRIM(ISNULL(i.Marca, '')) <> '' THEN ' ' + RTRIM(i.Marca) ELSE '' END +
      CASE WHEN RTRIM(ISNULL(i.Clase, '')) <> '' THEN ' ' + RTRIM(i.Clase) ELSE '' END
    )) AS nombre,
    i.PRECIO_VENTA       AS precioDetal,
    ISNULL(i.PRECIO_VENTA2, i.PRECIO_VENTA * 0.90) AS precioMayor,
    ISNULL(i.PRECIO_VENTA3, i.PRECIO_VENTA * 0.80) AS precioDistribuidor,
    i.EXISTENCIA         AS existencia,
    i.Categoria          AS categoria,
    ISNULL(i.PORCENTAJE, 16) AS iva,
    i.Barra              AS barra,
    i.Referencia         AS referencia,
    i.Servicio           AS esServicio,
    ISNULL(i.PRECIO_COMPRA, 0) AS costoPromedio
  FROM Inventario i
  WHERE (i.EXISTENCIA > 0 OR i.Servicio = 1)
    AND (@Search IS NULL
         OR i.CODIGO LIKE '%' + @Search + '%'
         OR i.DESCRIPCION LIKE '%' + @Search + '%'
         OR i.Referencia LIKE '%' + @Search + '%'
         OR i.Barra LIKE '%' + @Search + '%'
         OR i.Categoria LIKE '%' + @Search + '%')
    AND (@Categoria IS NULL OR i.Categoria = @Categoria)
  ORDER BY i.CODIGO
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================
-- 2. PRODUCTO POR CÓDIGO DE BARRAS / CÓDIGO
-- =============================================
IF OBJECT_ID('usp_POS_Producto_GetByCodigo', 'P') IS NOT NULL DROP PROCEDURE usp_POS_Producto_GetByCodigo;
GO
CREATE PROCEDURE usp_POS_Producto_GetByCodigo
  @Codigo NVARCHAR(20)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP 1
    i.CODIGO        AS id,
    i.CODIGO        AS codigo,
    LTRIM(RTRIM(
      ISNULL(RTRIM(i.Categoria), '') +
      CASE WHEN RTRIM(ISNULL(i.Tipo, '')) <> '' THEN ' ' + RTRIM(i.Tipo) ELSE '' END +
      CASE WHEN RTRIM(ISNULL(i.DESCRIPCION, '')) <> '' THEN ' ' + RTRIM(i.DESCRIPCION) ELSE '' END +
      CASE WHEN RTRIM(ISNULL(i.Marca, '')) <> '' THEN ' ' + RTRIM(i.Marca) ELSE '' END +
      CASE WHEN RTRIM(ISNULL(i.Clase, '')) <> '' THEN ' ' + RTRIM(i.Clase) ELSE '' END
    )) AS nombre,
    i.PRECIO_VENTA       AS precioDetal,
    ISNULL(i.PRECIO_VENTA2, i.PRECIO_VENTA * 0.90) AS precioMayor,
    ISNULL(i.PRECIO_VENTA3, i.PRECIO_VENTA * 0.80) AS precioDistribuidor,
    i.EXISTENCIA         AS existencia,
    i.Categoria          AS categoria,
    ISNULL(i.PORCENTAJE, 16) AS iva,
    i.Barra              AS barra,
    i.Referencia         AS referencia
  FROM Inventario i
  WHERE i.CODIGO = @Codigo
     OR i.Barra = @Codigo
     OR i.Referencia = @Codigo;
END
GO

-- =============================================
-- 3. CLIENTES POS: Búsqueda rápida
-- =============================================
IF OBJECT_ID('usp_POS_Clientes_Search', 'P') IS NOT NULL DROP PROCEDURE usp_POS_Clientes_Search;
GO
CREATE PROCEDURE usp_POS_Clientes_Search
  @Search NVARCHAR(100) = NULL,
  @Limit  INT = 20
AS
BEGIN
  SET NOCOUNT ON;

  SELECT TOP (@Limit)
    c.CODIGO     AS id,
    c.CODIGO     AS codigo,
    c.NOMBRE     AS nombre,
    c.RIF        AS rif,
    c.TELEFONO   AS telefono,
    c.EMAIL      AS email,
    c.DIRECCION  AS direccion,
    ISNULL(c.LISTA_PRECIO, 'Detal') AS tipoPrecio,
    ISNULL(c.LIMITE, 0) AS credito
  FROM Clientes c
  WHERE @Search IS NULL
     OR c.CODIGO LIKE '%' + @Search + '%'
     OR c.NOMBRE LIKE '%' + @Search + '%'
     OR c.RIF LIKE '%' + @Search + '%'
  ORDER BY c.NOMBRE;
END
GO

-- =============================================
-- 4. CATEGORÍAS POS: Lista de categorías con conteo
-- =============================================
IF OBJECT_ID('usp_POS_Categorias_List', 'P') IS NOT NULL DROP PROCEDURE usp_POS_Categorias_List;
GO
CREATE PROCEDURE usp_POS_Categorias_List
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    RTRIM(ISNULL(i.Categoria, '(Sin Categoría)')) AS id,
    RTRIM(ISNULL(i.Categoria, '(Sin Categoría)')) AS nombre,
    COUNT(1) AS productCount
  FROM Inventario i
  WHERE i.EXISTENCIA > 0 OR i.Servicio = 1
  GROUP BY i.Categoria
  ORDER BY i.Categoria;
END
GO

-- =============================================
-- 5. RESTAURANTE: Gestión de Mesas
-- =============================================
-- Tabla de mesas (solo si no existe)
IF OBJECT_ID('dbo.RestauranteMesas', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.RestauranteMesas (
    Id           INT IDENTITY(1,1) PRIMARY KEY,
    Numero       INT NOT NULL,
    Nombre       NVARCHAR(50) NOT NULL,
    Capacidad    INT NOT NULL DEFAULT 4,
    AmbienteId   NVARCHAR(10) NOT NULL DEFAULT '1',
    Ambiente     NVARCHAR(50) NOT NULL DEFAULT 'Salón Principal',
    PosicionX    INT NOT NULL DEFAULT 0,
    PosicionY    INT NOT NULL DEFAULT 0,
    Estado       NVARCHAR(20) NOT NULL DEFAULT 'libre', -- libre, ocupada, reservada, cuenta
    Activa       BIT NOT NULL DEFAULT 1,
    FechaCreacion DATETIME NOT NULL DEFAULT GETDATE()
  );
  
  -- Seed: mesas iniciales
  INSERT INTO RestauranteMesas (Numero, Nombre, Capacidad, AmbienteId, Ambiente, PosicionX, PosicionY) VALUES
  (1, 'Mesa 1', 4, '1', N'Salón Principal', 20, 20),
  (2, 'Mesa 2', 2, '1', N'Salón Principal', 180, 20),
  (3, 'Mesa 3', 6, '1', N'Salón Principal', 340, 20),
  (4, 'Mesa 4', 4, '1', N'Salón Principal', 20, 180),
  (5, 'Mesa 5', 8, '1', N'Salón Principal', 180, 180),
  (6, 'Mesa 6', 4, '2', N'Terraza', 20, 20),
  (7, 'Mesa 7', 2, '2', N'Terraza', 180, 20),
  (8, 'Barra 1', 1, '3', N'Barra', 20, 20),
  (9, 'Barra 2', 1, '3', N'Barra', 180, 20),
  (10, 'Barra 3', 1, '3', N'Barra', 340, 20);
END
GO

-- Tabla de pedidos de restaurante
IF OBJECT_ID('dbo.RestaurantePedidos', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.RestaurantePedidos (
    Id             INT IDENTITY(1,1) PRIMARY KEY,
    MesaId         INT NOT NULL,
    ClienteNombre  NVARCHAR(100) NULL,
    ClienteRif     NVARCHAR(20) NULL,
    Estado         NVARCHAR(20) NOT NULL DEFAULT 'abierto', -- abierto, en_preparacion, listo, cerrado
    Total          DECIMAL(18,2) NOT NULL DEFAULT 0,
    Comentarios    NVARCHAR(500) NULL,
    FechaApertura  DATETIME NOT NULL DEFAULT GETDATE(),
    FechaCierre    DATETIME NULL,
    CodUsuario     NVARCHAR(10) NULL,
    CONSTRAINT FK_RestPedido_Mesa FOREIGN KEY (MesaId) REFERENCES RestauranteMesas(Id)
  );
END
GO

-- Tabla de items de pedido
IF OBJECT_ID('dbo.RestaurantePedidoItems', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.RestaurantePedidoItems (
    Id                 INT IDENTITY(1,1) PRIMARY KEY,
    PedidoId           INT NOT NULL,
    ProductoId         NVARCHAR(15) NOT NULL,
    Nombre             NVARCHAR(200) NOT NULL,
    Cantidad           DECIMAL(10,3) NOT NULL DEFAULT 1,
    PrecioUnitario     DECIMAL(18,2) NOT NULL,
    Subtotal           DECIMAL(18,2) NOT NULL,
    Estado             NVARCHAR(20) NOT NULL DEFAULT 'pendiente',
    EsCompuesto        BIT NOT NULL DEFAULT 0,
    Componentes        NVARCHAR(MAX) NULL, -- JSON con selecciones
    Comentarios        NVARCHAR(500) NULL,
    EnviadoACocina     BIT NOT NULL DEFAULT 0,
    HoraEnvio          DATETIME NULL,
    CONSTRAINT FK_RestItem_Pedido FOREIGN KEY (PedidoId) REFERENCES RestaurantePedidos(Id)
  );
END
GO

-- SP Listar Mesas
IF OBJECT_ID('usp_REST_Mesas_List', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Mesas_List;
GO
CREATE PROCEDURE usp_REST_Mesas_List
  @AmbienteId NVARCHAR(10) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    m.Id         AS id,
    m.Numero     AS numero,
    m.Nombre     AS nombre,
    m.Capacidad  AS capacidad,
    m.AmbienteId AS ambienteId,
    m.Ambiente   AS ambiente,
    m.PosicionX  AS posicionX,
    m.PosicionY  AS posicionY,
    m.Estado     AS estado
  FROM RestauranteMesas m
  WHERE m.Activa = 1
    AND (@AmbienteId IS NULL OR m.AmbienteId = @AmbienteId)
  ORDER BY m.AmbienteId, m.Numero;
END
GO

-- SP Abrir Pedido en mesa
IF OBJECT_ID('usp_REST_Pedido_Abrir', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Pedido_Abrir;
GO
CREATE PROCEDURE usp_REST_Pedido_Abrir
  @MesaId        INT,
  @ClienteNombre NVARCHAR(100) = NULL,
  @ClienteRif    NVARCHAR(20)  = NULL,
  @CodUsuario    NVARCHAR(10)  = NULL,
  @PedidoId      INT           = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRAN;

    INSERT INTO RestaurantePedidos (MesaId, ClienteNombre, ClienteRif, Estado, CodUsuario)
    VALUES (@MesaId, @ClienteNombre, @ClienteRif, 'abierto', @CodUsuario);

    SET @PedidoId = SCOPE_IDENTITY();

    UPDATE RestauranteMesas SET Estado = 'ocupada' WHERE Id = @MesaId;

    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END
GO

-- SP Agregar Item a Pedido
IF OBJECT_ID('usp_REST_PedidoItem_Agregar', 'P') IS NOT NULL DROP PROCEDURE usp_REST_PedidoItem_Agregar;
GO
CREATE PROCEDURE usp_REST_PedidoItem_Agregar
  @PedidoId       INT,
  @ProductoId     NVARCHAR(15),
  @Nombre         NVARCHAR(200),
  @Cantidad       DECIMAL(10,3),
  @PrecioUnitario DECIMAL(18,2),
  @EsCompuesto    BIT = 0,
  @Componentes    NVARCHAR(MAX) = NULL,
  @Comentarios    NVARCHAR(500) = NULL,
  @ItemId         INT = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Subtotal DECIMAL(18,2) = @Cantidad * @PrecioUnitario;

  INSERT INTO RestaurantePedidoItems (PedidoId, ProductoId, Nombre, Cantidad, PrecioUnitario, Subtotal, EsCompuesto, Componentes, Comentarios)
  VALUES (@PedidoId, @ProductoId, @Nombre, @Cantidad, @PrecioUnitario, @Subtotal, @EsCompuesto, @Componentes, @Comentarios);

  SET @ItemId = SCOPE_IDENTITY();

  -- Recalcular total del pedido
  UPDATE RestaurantePedidos
  SET Total = (SELECT ISNULL(SUM(Subtotal), 0) FROM RestaurantePedidoItems WHERE PedidoId = @PedidoId)
  WHERE Id = @PedidoId;
END
GO

-- SP Enviar comanda a cocina (marcar items como enviados)
IF OBJECT_ID('usp_REST_Comanda_Enviar', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Comanda_Enviar;
GO
CREATE PROCEDURE usp_REST_Comanda_Enviar
  @PedidoId INT
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE RestaurantePedidoItems
  SET EnviadoACocina = 1,
      HoraEnvio = GETDATE(),
      Estado = 'en_preparacion'
  WHERE PedidoId = @PedidoId
    AND EnviadoACocina = 0;

  UPDATE RestaurantePedidos
  SET Estado = 'en_preparacion'
  WHERE Id = @PedidoId AND Estado = 'abierto';
END
GO

-- SP Cerrar pedido (mesa queda libre)
IF OBJECT_ID('usp_REST_Pedido_Cerrar', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Pedido_Cerrar;
GO
CREATE PROCEDURE usp_REST_Pedido_Cerrar
  @PedidoId INT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRAN;

    DECLARE @MesaId INT;
    SELECT @MesaId = MesaId FROM RestaurantePedidos WHERE Id = @PedidoId;

    UPDATE RestaurantePedidos
    SET Estado = 'cerrado', FechaCierre = GETDATE()
    WHERE Id = @PedidoId;

    UPDATE RestauranteMesas SET Estado = 'libre' WHERE Id = @MesaId;

    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END
GO

-- SP obtener pedido activo de una mesa
IF OBJECT_ID('usp_REST_Pedido_GetByMesa', 'P') IS NOT NULL DROP PROCEDURE usp_REST_Pedido_GetByMesa;
GO
CREATE PROCEDURE usp_REST_Pedido_GetByMesa
  @MesaId INT
AS
BEGIN
  SET NOCOUNT ON;

  -- Pedido header
  SELECT TOP 1
    p.Id            AS id,
    p.MesaId        AS mesaId,
    p.ClienteNombre AS clienteNombre,
    p.ClienteRif    AS clienteRif,
    p.Estado        AS estado,
    p.Total         AS total,
    p.Comentarios   AS comentarios,
    p.FechaApertura AS fechaApertura
  FROM RestaurantePedidos p
  WHERE p.MesaId = @MesaId AND p.Estado NOT IN ('cerrado')
  ORDER BY p.FechaApertura DESC;

  -- Items del pedido
  SELECT
    i.Id              AS id,
    i.PedidoId        AS pedidoId,
    i.ProductoId      AS productoId,
    i.Nombre          AS nombre,
    i.Cantidad        AS cantidad,
    i.PrecioUnitario  AS precioUnitario,
    i.Subtotal        AS subtotal,
    i.Estado          AS estado,
    i.EsCompuesto     AS esCompuesto,
    i.Componentes     AS componentes,
    i.Comentarios     AS comentarios,
    i.EnviadoACocina  AS enviadoACocina,
    i.HoraEnvio       AS horaEnvio
  FROM RestaurantePedidoItems i
  INNER JOIN RestaurantePedidos p ON i.PedidoId = p.Id
  WHERE p.MesaId = @MesaId AND p.Estado NOT IN ('cerrado')
  ORDER BY i.Id;
END
GO

PRINT '✅ SP POS y Restaurante creados exitosamente.'
GO
