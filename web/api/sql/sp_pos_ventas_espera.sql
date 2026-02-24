-- ═══════════════════════════════════════════════════════════════════
-- DatqBox POS — Ventas en Espera (multi-estación)
-- Permite a una cajera "aparcar" un carrito completo y que
-- otra estación lo pueda recuperar.
-- ═══════════════════════════════════════════════════════════════════

-- =============================================
-- 1. TABLA: Ventas en Espera (header)
-- =============================================
IF OBJECT_ID('dbo.PosVentasEnEspera', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.PosVentasEnEspera (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    CajaId          NVARCHAR(10) NOT NULL,         -- Caja que originó la espera
    EstacionNombre  NVARCHAR(50) NULL,              -- "Caja 1", "Caja Principal"
    CodUsuario      NVARCHAR(10) NULL,              -- Cajero que puso en espera
    ClienteId       NVARCHAR(12) NULL,              -- FK a Clientes.CODIGO
    ClienteNombre   NVARCHAR(100) NULL,
    ClienteRif      NVARCHAR(20) NULL,
    TipoPrecio      NVARCHAR(20) NOT NULL DEFAULT 'Detal', -- Detal, Mayor, Distribuidor
    Motivo          NVARCHAR(200) NULL,             -- "Tarjeta rechazada", "Cliente buscando más", etc.
    Subtotal        DECIMAL(18,2) NOT NULL DEFAULT 0,
    Descuento       DECIMAL(18,2) NOT NULL DEFAULT 0,
    Impuestos       DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total           DECIMAL(18,2) NOT NULL DEFAULT 0,
    FechaCreacion   DATETIME NOT NULL DEFAULT GETDATE(),
    Estado          NVARCHAR(20) NOT NULL DEFAULT 'espera', -- espera, recuperado, anulado
    RecuperadoPor   NVARCHAR(10) NULL,              -- Cajero que recuperó
    RecuperadoEn    NVARCHAR(10) NULL,              -- Caja donde se recuperó
    FechaRecuperado DATETIME NULL,
    CONSTRAINT CK_PosEspera_Estado CHECK (Estado IN ('espera', 'recuperado', 'anulado'))
  );
END
GO

-- =============================================
-- 2. TABLA: Detalle de la venta en espera
-- =============================================
IF OBJECT_ID('dbo.PosVentasEnEsperaDetalle', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.PosVentasEnEsperaDetalle (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    VentaEsperaId   INT NOT NULL,
    ProductoId      NVARCHAR(15) NOT NULL,          -- FK a Inventario.CODIGO
    Codigo          NVARCHAR(30) NULL,              -- Código de barras o código visible
    Nombre          NVARCHAR(200) NOT NULL,
    Cantidad        DECIMAL(10,3) NOT NULL,
    PrecioUnitario  DECIMAL(18,2) NOT NULL,
    Descuento       DECIMAL(18,2) NOT NULL DEFAULT 0,
    IVA             DECIMAL(5,2) NOT NULL DEFAULT 16,
    Subtotal        DECIMAL(18,2) NOT NULL,
    Orden           INT NOT NULL DEFAULT 0,          -- Para mantener el orden original
    CONSTRAINT FK_PosEsperaDetalle_Espera FOREIGN KEY (VentaEsperaId) REFERENCES PosVentasEnEspera(Id) ON DELETE CASCADE
  );
END
GO

-- =============================================
-- 3. TABLA: Ventas completadas (facturadas)
-- =============================================
IF OBJECT_ID('dbo.PosVentas', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.PosVentas (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    NumFactura      NVARCHAR(20) NOT NULL,          -- Número fiscal/factura
    CajaId          NVARCHAR(10) NOT NULL,
    CodUsuario      NVARCHAR(10) NULL,
    ClienteId       NVARCHAR(12) NULL,
    ClienteNombre   NVARCHAR(100) NULL,
    ClienteRif      NVARCHAR(20) NULL,
    TipoPrecio      NVARCHAR(20) NOT NULL DEFAULT 'Detal',
    Subtotal        DECIMAL(18,2) NOT NULL DEFAULT 0,
    Descuento       DECIMAL(18,2) NOT NULL DEFAULT 0,
    Impuestos       DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total           DECIMAL(18,2) NOT NULL DEFAULT 0,
    MetodoPago      NVARCHAR(50) NULL,              -- Efectivo, Tarjeta, Mixto
    FechaVenta      DATETIME NOT NULL DEFAULT GETDATE(),
    TramaFiscal     NVARCHAR(MAX) NULL,             -- Respuesta de la impresora fiscal
    EsperaOrigenId  INT NULL,                        -- Si vino de "en espera"
    CONSTRAINT UQ_PosVentas_NumFact UNIQUE (NumFactura)
  );
END
GO

IF OBJECT_ID('dbo.PosVentasDetalle', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.PosVentasDetalle (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    VentaId         INT NOT NULL,
    ProductoId      NVARCHAR(15) NOT NULL,
    Codigo          NVARCHAR(30) NULL,
    Nombre          NVARCHAR(200) NOT NULL,
    Cantidad        DECIMAL(10,3) NOT NULL,
    PrecioUnitario  DECIMAL(18,2) NOT NULL,
    Descuento       DECIMAL(18,2) NOT NULL DEFAULT 0,
    IVA             DECIMAL(5,2) NOT NULL DEFAULT 16,
    Subtotal        DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_PosVentaDetalle_Venta FOREIGN KEY (VentaId) REFERENCES PosVentas(Id) ON DELETE CASCADE
  );
END
GO

-- ═══════════════════════════════════════════════════════════════════
-- STORED PROCEDURES
-- ═══════════════════════════════════════════════════════════════════

-- ─── PONER EN ESPERA ───
IF OBJECT_ID('usp_POS_Espera_Crear', 'P') IS NOT NULL DROP PROCEDURE usp_POS_Espera_Crear;
GO
CREATE PROCEDURE usp_POS_Espera_Crear
  @CajaId          NVARCHAR(10),
  @EstacionNombre  NVARCHAR(50) = NULL,
  @CodUsuario      NVARCHAR(10) = NULL,
  @ClienteId       NVARCHAR(12) = NULL,
  @ClienteNombre   NVARCHAR(100) = NULL,
  @ClienteRif      NVARCHAR(20) = NULL,
  @TipoPrecio      NVARCHAR(20) = 'Detal',
  @Motivo          NVARCHAR(200) = NULL,
  @DetalleXml      XML,   -- <items><item prodId="" cod="" nom="" cant="" precio="" desc="" iva="" sub="" ord="" /></items>
  @EsperaId        INT = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRAN;

    INSERT INTO PosVentasEnEspera (CajaId, EstacionNombre, CodUsuario, ClienteId, ClienteNombre, ClienteRif, TipoPrecio, Motivo)
    VALUES (@CajaId, @EstacionNombre, @CodUsuario, @ClienteId, @ClienteNombre, @ClienteRif, @TipoPrecio, @Motivo);
    SET @EsperaId = SCOPE_IDENTITY();

    INSERT INTO PosVentasEnEsperaDetalle (VentaEsperaId, ProductoId, Codigo, Nombre, Cantidad, PrecioUnitario, Descuento, IVA, Subtotal, Orden)
    SELECT
      @EsperaId,
      t.c.value('@prodId', 'NVARCHAR(15)'),
      t.c.value('@cod', 'NVARCHAR(30)'),
      t.c.value('@nom', 'NVARCHAR(200)'),
      t.c.value('@cant', 'DECIMAL(10,3)'),
      t.c.value('@precio', 'DECIMAL(18,2)'),
      ISNULL(t.c.value('@desc', 'DECIMAL(18,2)'), 0),
      ISNULL(t.c.value('@iva', 'DECIMAL(5,2)'), 16),
      t.c.value('@sub', 'DECIMAL(18,2)'),
      ISNULL(t.c.value('@ord', 'INT'), 0)
    FROM @DetalleXml.nodes('/items/item') t(c);

    -- Calcular totales
    UPDATE PosVentasEnEspera SET
      Subtotal  = (SELECT ISNULL(SUM(Subtotal), 0) FROM PosVentasEnEsperaDetalle WHERE VentaEsperaId = @EsperaId),
      Descuento = (SELECT ISNULL(SUM(Descuento * Cantidad), 0) FROM PosVentasEnEsperaDetalle WHERE VentaEsperaId = @EsperaId),
      Impuestos = (SELECT ISNULL(SUM(Subtotal * IVA / 100), 0) FROM PosVentasEnEsperaDetalle WHERE VentaEsperaId = @EsperaId),
      Total     = (SELECT ISNULL(SUM(Subtotal + Subtotal * IVA / 100), 0) FROM PosVentasEnEsperaDetalle WHERE VentaEsperaId = @EsperaId)
    WHERE Id = @EsperaId;

    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END
GO

-- ─── LISTAR EN ESPERA (visible para todas las estaciones) ───
IF OBJECT_ID('usp_POS_Espera_List', 'P') IS NOT NULL DROP PROCEDURE usp_POS_Espera_List;
GO
CREATE PROCEDURE usp_POS_Espera_List
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    e.Id AS id,
    e.CajaId AS cajaId,
    e.EstacionNombre AS estacionNombre,
    e.CodUsuario AS codUsuario,
    e.ClienteNombre AS clienteNombre,
    e.ClienteRif AS clienteRif,
    e.TipoPrecio AS tipoPrecio,
    e.Motivo AS motivo,
    e.Total AS total,
    e.FechaCreacion AS fechaCreacion,
    (SELECT COUNT(1) FROM PosVentasEnEsperaDetalle d WHERE d.VentaEsperaId = e.Id) AS cantItems
  FROM PosVentasEnEspera e
  WHERE e.Estado = 'espera'
  ORDER BY e.FechaCreacion ASC;
END
GO

-- ─── RECUPERAR (trae header + detalle; marca como recuperado) ───
IF OBJECT_ID('usp_POS_Espera_Recuperar', 'P') IS NOT NULL DROP PROCEDURE usp_POS_Espera_Recuperar;
GO
CREATE PROCEDURE usp_POS_Espera_Recuperar
  @Id             INT,
  @RecuperadoPor  NVARCHAR(10) = NULL,
  @RecuperadoEn   NVARCHAR(10) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  -- Header
  SELECT
    e.Id AS id, e.CajaId AS cajaId, e.ClienteId AS clienteId,
    e.ClienteNombre AS clienteNombre, e.ClienteRif AS clienteRif,
    e.TipoPrecio AS tipoPrecio, e.Motivo AS motivo,
    e.Subtotal AS subtotal, e.Descuento AS descuento,
    e.Impuestos AS impuestos, e.Total AS total, e.FechaCreacion AS fechaCreacion
  FROM PosVentasEnEspera e
  WHERE e.Id = @Id AND e.Estado = 'espera';

  -- Detalle
  SELECT
    d.Id AS id, d.ProductoId AS productoId, d.Codigo AS codigo,
    d.Nombre AS nombre, d.Cantidad AS cantidad, d.PrecioUnitario AS precioUnitario,
    d.Descuento AS descuento, d.IVA AS iva, d.Subtotal AS subtotal, d.Orden AS orden
  FROM PosVentasEnEsperaDetalle d
  WHERE d.VentaEsperaId = @Id
  ORDER BY d.Orden;

  -- Marcar como recuperado
  UPDATE PosVentasEnEspera SET
    Estado = 'recuperado',
    RecuperadoPor = @RecuperadoPor,
    RecuperadoEn = @RecuperadoEn,
    FechaRecuperado = GETDATE()
  WHERE Id = @Id AND Estado = 'espera';
END
GO

-- ─── ANULAR ESPERA ───
IF OBJECT_ID('usp_POS_Espera_Anular', 'P') IS NOT NULL DROP PROCEDURE usp_POS_Espera_Anular;
GO
CREATE PROCEDURE usp_POS_Espera_Anular @Id INT
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE PosVentasEnEspera SET Estado = 'anulado' WHERE Id = @Id AND Estado = 'espera';
END
GO

-- ─── REGISTRAR VENTA COMPLETADA ───
IF OBJECT_ID('usp_POS_Venta_Crear', 'P') IS NOT NULL DROP PROCEDURE usp_POS_Venta_Crear;
GO
CREATE PROCEDURE usp_POS_Venta_Crear
  @NumFactura      NVARCHAR(20),
  @CajaId          NVARCHAR(10),
  @CodUsuario      NVARCHAR(10) = NULL,
  @ClienteId       NVARCHAR(12) = NULL,
  @ClienteNombre   NVARCHAR(100) = NULL,
  @ClienteRif      NVARCHAR(20) = NULL,
  @TipoPrecio      NVARCHAR(20) = 'Detal',
  @MetodoPago      NVARCHAR(50) = NULL,
  @TramaFiscal     NVARCHAR(MAX) = NULL,
  @EsperaOrigenId  INT = NULL,
  @DetalleXml      XML,
  @VentaId         INT = 0 OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRAN;

    INSERT INTO PosVentas (NumFactura, CajaId, CodUsuario, ClienteId, ClienteNombre, ClienteRif, TipoPrecio, MetodoPago, TramaFiscal, EsperaOrigenId)
    VALUES (@NumFactura, @CajaId, @CodUsuario, @ClienteId, @ClienteNombre, @ClienteRif, @TipoPrecio, @MetodoPago, @TramaFiscal, @EsperaOrigenId);
    SET @VentaId = SCOPE_IDENTITY();

    INSERT INTO PosVentasDetalle (VentaId, ProductoId, Codigo, Nombre, Cantidad, PrecioUnitario, Descuento, IVA, Subtotal)
    SELECT
      @VentaId,
      t.c.value('@prodId', 'NVARCHAR(15)'),
      t.c.value('@cod', 'NVARCHAR(30)'),
      t.c.value('@nom', 'NVARCHAR(200)'),
      t.c.value('@cant', 'DECIMAL(10,3)'),
      t.c.value('@precio', 'DECIMAL(18,2)'),
      ISNULL(t.c.value('@desc', 'DECIMAL(18,2)'), 0),
      ISNULL(t.c.value('@iva', 'DECIMAL(5,2)'), 16),
      t.c.value('@sub', 'DECIMAL(18,2)')
    FROM @DetalleXml.nodes('/items/item') t(c);

    UPDATE PosVentas SET
      Subtotal  = (SELECT ISNULL(SUM(Subtotal), 0) FROM PosVentasDetalle WHERE VentaId = @VentaId),
      Descuento = (SELECT ISNULL(SUM(Descuento * Cantidad), 0) FROM PosVentasDetalle WHERE VentaId = @VentaId),
      Impuestos = (SELECT ISNULL(SUM(Subtotal * IVA / 100), 0) FROM PosVentasDetalle WHERE VentaId = @VentaId),
      Total     = (SELECT ISNULL(SUM(Subtotal + Subtotal * IVA / 100), 0) FROM PosVentasDetalle WHERE VentaId = @VentaId)
    WHERE Id = @VentaId;

    COMMIT;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
  END CATCH
END
GO

PRINT N'✅ POS — Tablas y SPs de Ventas/Espera creados exitosamente.'
GO
