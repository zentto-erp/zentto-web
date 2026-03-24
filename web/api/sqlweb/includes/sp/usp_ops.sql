/*
 * ============================================================================
 *  Archivo : usp_ops.sql
 *  Esquemas: dbo (procedimientos), pos / rest / master / fin / cfg / sec (tablas)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-14
 *
 *  Descripcion:
 *    Procedimientos almacenados operacionales que reemplazan SQL inline en los
 *    servicios TypeScript de: POS, Restaurante, MovInvent y Bancos.
 *
 *  Convenciones de nombrado:
 *    - POS         : usp_POS_[Entity]_[Action]
 *    - Restaurante : usp_Rest_[Entity]_[Action]
 *    - MovInvent   : usp_Inv_Movement_[Action]
 *    - Bancos      : usp_Bank_[Entity]_[Action]
 *
 *  Patron: CREATE OR ALTER (idempotente, re-ejecutable)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  SECCION 1: PROCEDIMIENTOS COMPARTIDOS (Scope, User, Tax, Product, Customer)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_POS_ResolveDefaultScope
--  Resuelve CompanyId, BranchId y CountryCode para la empresa DEFAULT / MAIN.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_ResolveDefaultScope
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        c.CompanyId  AS companyId,
        b.BranchId   AS branchId,
        UPPER(ISNULL(NULLIF(b.CountryCode, ''), c.FiscalCountryCode)) AS countryCode
    FROM cfg.Company c
    INNER JOIN cfg.Branch b ON b.CompanyId = c.CompanyId
    WHERE c.CompanyCode = N'DEFAULT'
      AND b.BranchCode  = N'MAIN'
    ORDER BY c.CompanyId, b.BranchId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_ResolveUserId
--  Resuelve UserId a partir de UserCode.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_ResolveUserId
    @UserCode NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 UserId AS userId
    FROM sec.[User]
    WHERE UPPER(UserCode) = UPPER(@UserCode)
      AND IsDeleted = 0
      AND IsActive  = 1;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_LoadCountryTaxRates
--  Lista las tasas de impuesto por pais.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_LoadCountryTaxRates
    @CountryCode NVARCHAR(5)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TaxCode   AS taxCode,
        Rate      AS rate,
        IsDefault AS isDefault
    FROM fiscal.TaxRate
    WHERE CountryCode = @CountryCode
      AND IsActive = 1
    ORDER BY IsDefault DESC, SortOrder, TaxCode;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_ResolveProduct
--  Busca un producto por codigo o ID numerico.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_ResolveProduct
    @CompanyId   INT,
    @Identifier  NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        ProductId       AS productId,
        ProductCode     AS productCode,
        ProductName     AS productName,
        DefaultTaxCode  AS defaultTaxCode,
        DefaultTaxRate  AS defaultTaxRate
    FROM [master].Product
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND (
          ProductCode = @Identifier
          OR CAST(ProductId AS NVARCHAR(50)) = @Identifier
      )
    ORDER BY ProductId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_ResolveCustomerById
--  Busca cliente por CustomerCode o CustomerId textual.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_ResolveCustomerById
    @CompanyId INT,
    @IdInput   NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        CustomerId   AS customerId,
        CustomerCode AS customerCode,
        CustomerName AS customerName,
        FiscalId     AS fiscalId
    FROM [master].Customer
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND (
          CustomerCode = @IdInput
          OR CAST(CustomerId AS NVARCHAR(50)) = @IdInput
      )
    ORDER BY CustomerId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_ResolveCustomerByRif
--  Busca cliente por FiscalId.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_ResolveCustomerByRif
    @CompanyId INT,
    @Rif       NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        CustomerId   AS customerId,
        CustomerCode AS customerCode,
        CustomerName AS customerName,
        FiscalId     AS fiscalId
    FROM [master].Customer
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND FiscalId  = @Rif
    ORDER BY CustomerId DESC;
END;
GO


-- =============================================================================
--  SECCION 2: POS - SERVICE (pos/service.ts)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_POS_Product_List
--  Lista productos POS paginados, con imagen, filtros de busqueda y categoria.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_Product_List
    @CompanyId  INT,
    @BranchId   INT,
    @Search     NVARCHAR(200) = NULL,
    @Categoria  NVARCHAR(100) = NULL,
    @Offset     INT = 0,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Total
    SELECT @TotalCount = COUNT(1)
    FROM [master].Product
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND IsActive  = 1
      AND (StockQty > 0 OR IsService = 1)
      AND (@Search IS NULL OR ProductCode LIKE @Search OR ProductName LIKE @Search)
      AND (@Categoria IS NULL OR CategoryCode = @Categoria);

    -- Filas paginadas
    SELECT
        ProductId       AS id,
        ProductCode     AS codigo,
        ProductName     AS nombre,
        img.PublicUrl   AS imagen,
        SalesPrice      AS precioDetal,
        StockQty        AS existencia,
        CategoryCode    AS categoria,
        CASE
            WHEN DefaultTaxRate > 1 THEN DefaultTaxRate
            ELSE DefaultTaxRate * 100
        END AS iva
    FROM [master].Product p
    OUTER APPLY (
        SELECT TOP 1 ma.PublicUrl
        FROM cfg.EntityImage ei
        INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
        WHERE ei.CompanyId   = p.CompanyId
          AND ei.BranchId    = @BranchId
          AND ei.EntityType  = N'MASTER_PRODUCT'
          AND ei.EntityId    = p.ProductId
          AND ei.IsDeleted   = 0
          AND ei.IsActive    = 1
          AND ma.IsDeleted   = 0
          AND ma.IsActive    = 1
        ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    WHERE p.CompanyId = @CompanyId
      AND p.IsDeleted = 0
      AND p.IsActive  = 1
      AND (p.StockQty > 0 OR p.IsService = 1)
      AND (@Search IS NULL OR p.ProductCode LIKE @Search OR p.ProductName LIKE @Search)
      AND (@Categoria IS NULL OR p.CategoryCode = @Categoria)
    ORDER BY p.ProductCode
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_Product_GetByCode
--  Obtiene un producto por codigo o ID.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_Product_GetByCode
    @CompanyId INT,
    @BranchId  INT,
    @Codigo    NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        ProductId       AS id,
        ProductCode     AS codigo,
        ProductName     AS nombre,
        img.PublicUrl   AS imagen,
        SalesPrice      AS precioDetal,
        StockQty        AS existencia,
        CategoryCode    AS categoria,
        CASE
            WHEN DefaultTaxRate > 1 THEN DefaultTaxRate
            ELSE DefaultTaxRate * 100
        END AS iva
    FROM [master].Product p
    OUTER APPLY (
        SELECT TOP 1 ma.PublicUrl
        FROM cfg.EntityImage ei
        INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
        WHERE ei.CompanyId   = p.CompanyId
          AND ei.BranchId    = @BranchId
          AND ei.EntityType  = N'MASTER_PRODUCT'
          AND ei.EntityId    = p.ProductId
          AND ei.IsDeleted   = 0
          AND ei.IsActive    = 1
          AND ma.IsDeleted   = 0
          AND ma.IsActive    = 1
        ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    WHERE p.CompanyId = @CompanyId
      AND p.IsDeleted = 0
      AND p.IsActive  = 1
      AND (
          p.ProductCode = @Codigo
          OR CAST(p.ProductId AS NVARCHAR(40)) = @Codigo
      )
    ORDER BY p.ProductId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_Customer_Search
--  Busca clientes POS con filtro de texto.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_Customer_Search
    @CompanyId INT,
    @Search    NVARCHAR(200) = NULL,
    @Limit     INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        CustomerId   AS id,
        CustomerCode AS codigo,
        CustomerName AS nombre,
        FiscalId     AS rif,
        Phone        AS telefono,
        Email        AS email,
        AddressLine  AS direccion,
        N'Detal'     AS tipoPrecio,
        CreditLimit  AS credito
    FROM [master].Customer
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND IsActive  = 1
      AND (
          @Search IS NULL
          OR CustomerCode LIKE @Search
          OR CustomerName LIKE @Search
          OR FiscalId LIKE @Search
      )
    ORDER BY CustomerName;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_Category_List
--  Lista categorias de productos con conteo.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_Category_List
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ISNULL(NULLIF(LTRIM(RTRIM(CategoryCode)), N''), N'(Sin Categoria)') AS id,
        ISNULL(NULLIF(LTRIM(RTRIM(CategoryCode)), N''), N'(Sin Categoria)') AS nombre,
        COUNT(1) AS productCount
    FROM [master].Product
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND IsActive  = 1
      AND (StockQty > 0 OR IsService = 1)
    GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(CategoryCode)), N''), N'(Sin Categoria)')
    ORDER BY nombre;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_FiscalCorrelative_List
--  Lista correlativos fiscales.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_FiscalCorrelative_List
    @CompanyId INT,
    @BranchId  INT,
    @CajaId    NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CASE
            WHEN fc.CashRegisterCode = N'GLOBAL' THEN fc.CorrelativeType
            ELSE fc.CorrelativeType + N'|CAJA:' + fc.CashRegisterCode
        END AS tipo,
        CASE WHEN fc.CashRegisterCode = N'GLOBAL' THEN NULL ELSE fc.CashRegisterCode END AS cajaId,
        fc.SerialFiscal     AS serialFiscal,
        fc.CurrentNumber    AS correlativoActual,
        fc.Description      AS descripcion
    FROM pos.FiscalCorrelative fc
    WHERE fc.CompanyId = @CompanyId
      AND fc.BranchId  = @BranchId
      AND fc.IsActive  = 1
      AND (@CajaId IS NULL OR fc.CashRegisterCode IN (N'GLOBAL', @CajaId))
    ORDER BY
        CASE WHEN fc.CashRegisterCode = N'GLOBAL' THEN 0 ELSE 1 END,
        fc.CashRegisterCode,
        fc.CorrelativeType;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_FiscalCorrelative_Upsert
--  Inserta o actualiza un correlativo fiscal.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_FiscalCorrelative_Upsert
    @CompanyId          INT,
    @BranchId           INT,
    @CajaId             NVARCHAR(20),
    @SerialFiscal       NVARCHAR(20),
    @CorrelativoActual  INT = 0,
    @Descripcion        NVARCHAR(200) = N'',
    @Resultado          INT OUTPUT,
    @Mensaje            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM pos.FiscalCorrelative
        WHERE CompanyId       = @CompanyId
          AND BranchId        = @BranchId
          AND CorrelativeType = N'FACTURA'
          AND CashRegisterCode = @CajaId
    )
    BEGIN
        UPDATE pos.FiscalCorrelative
        SET SerialFiscal  = @SerialFiscal,
            CurrentNumber = @CorrelativoActual,
            Description   = @Descripcion,
            UpdatedAt     = SYSUTCDATETIME(),
            IsActive      = 1
        WHERE CompanyId       = @CompanyId
          AND BranchId        = @BranchId
          AND CorrelativeType = N'FACTURA'
          AND CashRegisterCode = @CajaId;
    END
    ELSE
    BEGIN
        INSERT INTO pos.FiscalCorrelative (
            CompanyId, BranchId, CorrelativeType, CashRegisterCode,
            SerialFiscal, CurrentNumber, Description, IsActive
        )
        VALUES (
            @CompanyId, @BranchId, N'FACTURA', @CajaId,
            @SerialFiscal, @CorrelativoActual, @Descripcion, 1
        );
    END

    SET @Resultado = 1;
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_Report_Resumen
--  Resumen de ventas POS por rango de fechas.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_Report_Resumen
    @CompanyId INT,
    @BranchId  INT,
    @FromDate  DATE,
    @ToDate    DATE,
    @CajaId    NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ventas AS (
        SELECT SaleTicketId, TotalAmount
        FROM pos.SaleTicket
        WHERE CompanyId = @CompanyId
          AND BranchId  = @BranchId
          AND CAST(SoldAt AS date) BETWEEN @FromDate AND @ToDate
          AND (@CajaId IS NULL OR UPPER(CashRegisterCode) = @CajaId)
    ),
    detalle AS (
        SELECT l.ProductCode, l.Quantity
        FROM pos.SaleTicketLine l
        INNER JOIN ventas v ON v.SaleTicketId = l.SaleTicketId
    )
    SELECT
        ISNULL((SELECT SUM(TotalAmount) FROM ventas), 0)                  AS totalVentas,
        ISNULL((SELECT COUNT(1) FROM ventas), 0)                          AS transacciones,
        ISNULL((SELECT SUM(Quantity) FROM detalle), 0)                    AS productosVendidos,
        ISNULL((SELECT COUNT(DISTINCT ProductCode) FROM detalle), 0)      AS productosDiferentes,
        CASE
            WHEN (SELECT COUNT(1) FROM ventas) = 0 THEN 0
            ELSE ISNULL((SELECT SUM(TotalAmount) FROM ventas), 0)
                 / NULLIF((SELECT COUNT(1) FROM ventas), 0)
        END AS ticketPromedio;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_Report_Ventas
--  Lista ventas POS detalladas.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_Report_Ventas
    @CompanyId INT,
    @BranchId  INT,
    @FromDate  DATE,
    @ToDate    DATE,
    @CajaId    NVARCHAR(20) = NULL,
    @Limit     INT = 200
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        v.SaleTicketId      AS id,
        v.InvoiceNumber     AS numFactura,
        v.SoldAt            AS fecha,
        ISNULL(NULLIF(LTRIM(RTRIM(v.CustomerName)), N''), N'Consumidor Final') AS cliente,
        v.CashRegisterCode  AS cajaId,
        v.TotalAmount       AS total,
        N'Completada'       AS estado,
        v.PaymentMethod     AS metodoPago,
        v.FiscalPayload     AS tramaFiscal,
        corr.SerialFiscal   AS serialFiscal,
        corr.CurrentNumber  AS correlativoFiscal
    FROM pos.SaleTicket v
    OUTER APPLY (
        SELECT TOP 1
            fc.SerialFiscal,
            fc.CurrentNumber
        FROM pos.FiscalCorrelative fc
        WHERE fc.CompanyId       = v.CompanyId
          AND fc.BranchId        = v.BranchId
          AND fc.CorrelativeType = N'FACTURA'
          AND fc.IsActive        = 1
          AND fc.CashRegisterCode IN (UPPER(v.CashRegisterCode), N'GLOBAL')
        ORDER BY CASE WHEN fc.CashRegisterCode = UPPER(v.CashRegisterCode) THEN 0 ELSE 1 END,
                 fc.FiscalCorrelativeId DESC
    ) corr
    WHERE v.CompanyId = @CompanyId
      AND v.BranchId  = @BranchId
      AND CAST(v.SoldAt AS date) BETWEEN @FromDate AND @ToDate
      AND (@CajaId IS NULL OR UPPER(v.CashRegisterCode) = @CajaId)
    ORDER BY v.SoldAt DESC, v.SaleTicketId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_Report_ProductosTop
--  Top productos vendidos por rango de fechas.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_Report_ProductosTop
    @CompanyId INT,
    @BranchId  INT,
    @FromDate  DATE,
    @ToDate    DATE,
    @CajaId    NVARCHAR(20) = NULL,
    @Limit     INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        l.ProductId   AS productoId,
        l.ProductCode AS codigo,
        l.ProductName AS nombre,
        SUM(l.Quantity)    AS cantidad,
        SUM(l.TotalAmount) AS total
    FROM pos.SaleTicketLine l
    INNER JOIN pos.SaleTicket v ON v.SaleTicketId = l.SaleTicketId
    WHERE v.CompanyId = @CompanyId
      AND v.BranchId  = @BranchId
      AND CAST(v.SoldAt AS date) BETWEEN @FromDate AND @ToDate
      AND (@CajaId IS NULL OR UPPER(v.CashRegisterCode) = @CajaId)
    GROUP BY l.ProductId, l.ProductCode, l.ProductName
    ORDER BY total DESC, cantidad DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_Report_FormasPago
--  Reporte agrupado por forma de pago.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_Report_FormasPago
    @CompanyId INT,
    @BranchId  INT,
    @FromDate  DATE,
    @ToDate    DATE,
    @CajaId    NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ISNULL(NULLIF(LTRIM(RTRIM(v.PaymentMethod)), N''), N'No especificado') AS metodoPago,
        COUNT(1)            AS transacciones,
        SUM(v.TotalAmount)  AS total
    FROM pos.SaleTicket v
    WHERE v.CompanyId = @CompanyId
      AND v.BranchId  = @BranchId
      AND CAST(v.SoldAt AS date) BETWEEN @FromDate AND @ToDate
      AND (@CajaId IS NULL OR UPPER(v.CashRegisterCode) = @CajaId)
    GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(v.PaymentMethod)), N''), N'No especificado')
    ORDER BY total DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_Report_Cajas
--  Reporte agrupado por caja.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_Report_Cajas
    @CompanyId INT,
    @BranchId  INT,
    @FromDate  DATE,
    @ToDate    DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        UPPER(v.CashRegisterCode) AS cajaId,
        COUNT(1)                  AS transacciones,
        SUM(v.TotalAmount)        AS total,
        MAX(ISNULL(corr.SerialFiscal, N'')) AS serialFiscal
    FROM pos.SaleTicket v
    OUTER APPLY (
        SELECT TOP 1 fc.SerialFiscal
        FROM pos.FiscalCorrelative fc
        WHERE fc.CompanyId       = v.CompanyId
          AND fc.BranchId        = v.BranchId
          AND fc.CorrelativeType = N'FACTURA'
          AND fc.IsActive        = 1
          AND fc.CashRegisterCode IN (UPPER(v.CashRegisterCode), N'GLOBAL')
        ORDER BY CASE WHEN fc.CashRegisterCode = UPPER(v.CashRegisterCode) THEN 0 ELSE 1 END,
                 fc.FiscalCorrelativeId DESC
    ) corr
    WHERE v.CompanyId = @CompanyId
      AND v.BranchId  = @BranchId
      AND CAST(v.SoldAt AS date) BETWEEN @FromDate AND @ToDate
    GROUP BY UPPER(v.CashRegisterCode)
    ORDER BY cajaId;
END;
GO


-- =============================================================================
--  SECCION 3: POS ESPERA - SERVICE (pos/espera.service.ts)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_POS_WaitTicket_Create
--  Crea un ticket de espera con cabecera y retorna el ID.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_WaitTicket_Create
    @CompanyId        INT,
    @BranchId         INT,
    @CountryCode      NVARCHAR(5),
    @CashRegisterCode NVARCHAR(20),
    @StationName      NVARCHAR(100)  = NULL,
    @CreatedByUserId  INT            = NULL,
    @CustomerId       INT            = NULL,
    @CustomerCode     NVARCHAR(50)   = NULL,
    @CustomerName     NVARCHAR(255)  = NULL,
    @CustomerFiscalId NVARCHAR(50)   = NULL,
    @PriceTier        NVARCHAR(50)   = N'Detal',
    @Reason           NVARCHAR(500)  = NULL,
    @NetAmount        DECIMAL(18,2)  = 0,
    @DiscountAmount   DECIMAL(18,2)  = 0,
    @TaxAmount        DECIMAL(18,2)  = 0,
    @TotalAmount      DECIMAL(18,2)  = 0,
    @Resultado        BIGINT OUTPUT,
    @Mensaje          NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pos.WaitTicket (
        CompanyId, BranchId, CountryCode, CashRegisterCode, StationName,
        CreatedByUserId, CustomerId, CustomerCode, CustomerName, CustomerFiscalId,
        PriceTier, Reason, NetAmount, DiscountAmount, TaxAmount, TotalAmount,
        Status, CreatedAt, UpdatedAt
    )
    VALUES (
        @CompanyId, @BranchId, @CountryCode, @CashRegisterCode, @StationName,
        @CreatedByUserId, @CustomerId, @CustomerCode, @CustomerName, @CustomerFiscalId,
        @PriceTier, @Reason, @NetAmount, @DiscountAmount, @TaxAmount, @TotalAmount,
        N'WAITING', SYSUTCDATETIME(), SYSUTCDATETIME()
    );

    SET @Resultado = SCOPE_IDENTITY();
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_WaitTicketLine_Insert
--  Inserta una linea de ticket de espera.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_WaitTicketLine_Insert
    @WaitTicketId        BIGINT,
    @LineNumber          INT,
    @CountryCode         NVARCHAR(5),
    @ProductId           INT            = NULL,
    @ProductCode         NVARCHAR(60),
    @ProductName         NVARCHAR(255),
    @Quantity            DECIMAL(18,4),
    @UnitPrice           DECIMAL(18,4),
    @DiscountAmount      DECIMAL(18,2)  = 0,
    @TaxCode             NVARCHAR(20),
    @TaxRate             DECIMAL(10,6),
    @NetAmount           DECIMAL(18,2),
    @TaxAmount           DECIMAL(18,2),
    @TotalAmount         DECIMAL(18,2),
    @SupervisorApprovalId INT           = NULL,
    @LineMetaJson        NVARCHAR(MAX)  = NULL,
    @Resultado           INT OUTPUT,
    @Mensaje             NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pos.WaitTicketLine (
        WaitTicketId, LineNumber, CountryCode, ProductId, ProductCode, ProductName,
        Quantity, UnitPrice, DiscountAmount, TaxCode, TaxRate,
        NetAmount, TaxAmount, TotalAmount,
        SupervisorApprovalId, LineMetaJson, CreatedAt
    )
    VALUES (
        @WaitTicketId, @LineNumber, @CountryCode, @ProductId, @ProductCode, @ProductName,
        @Quantity, @UnitPrice, @DiscountAmount, @TaxCode, @TaxRate,
        @NetAmount, @TaxAmount, @TotalAmount,
        @SupervisorApprovalId, @LineMetaJson, SYSUTCDATETIME()
    );

    SET @Resultado = 1;
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_WaitTicket_List
--  Lista tickets en espera (WAITING).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_WaitTicket_List
    @CompanyId INT,
    @BranchId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        WaitTicketId   AS id,
        CashRegisterCode AS cajaId,
        StationName    AS estacionNombre,
        CustomerName   AS clienteNombre,
        Reason         AS motivo,
        TotalAmount    AS total,
        CreatedAt      AS fechaCreacion
    FROM pos.WaitTicket
    WHERE CompanyId = @CompanyId
      AND BranchId  = @BranchId
      AND Status    = N'WAITING'
    ORDER BY CreatedAt;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_WaitTicket_GetHeader
--  Obtiene la cabecera de un ticket de espera.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_WaitTicket_GetHeader
    @CompanyId    INT,
    @BranchId     INT,
    @WaitTicketId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        WaitTicketId    AS id,
        CashRegisterCode AS cajaId,
        StationName     AS estacionNombre,
        CustomerCode    AS clienteId,
        CustomerName    AS clienteNombre,
        CustomerFiscalId AS clienteRif,
        PriceTier       AS tipoPrecio,
        Reason          AS motivo,
        NetAmount       AS subtotal,
        TaxAmount       AS impuestos,
        TotalAmount     AS total,
        Status          AS estado,
        CreatedAt       AS fechaCreacion
    FROM pos.WaitTicket
    WHERE CompanyId    = @CompanyId
      AND BranchId     = @BranchId
      AND WaitTicketId = @WaitTicketId
    ORDER BY WaitTicketId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_WaitTicket_Recover
--  Marca un WaitTicket como RECOVERED.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_WaitTicket_Recover
    @CompanyId            INT,
    @BranchId             INT,
    @WaitTicketId         BIGINT,
    @RecoveredByUserId    INT          = NULL,
    @RecoveredAtRegister  NVARCHAR(20) = NULL,
    @Resultado            INT OUTPUT,
    @Mensaje              NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pos.WaitTicket
    SET Status              = N'RECOVERED',
        RecoveredByUserId   = @RecoveredByUserId,
        RecoveredAtRegister = @RecoveredAtRegister,
        RecoveredAt         = SYSUTCDATETIME(),
        UpdatedAt           = SYSUTCDATETIME()
    WHERE CompanyId    = @CompanyId
      AND BranchId     = @BranchId
      AND WaitTicketId = @WaitTicketId;

    SET @Resultado = 1;
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_WaitTicketLine_GetItems
--  Obtiene las lineas de un ticket de espera.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_WaitTicketLine_GetItems
    @WaitTicketId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        WaitTicketLineId AS id,
        ISNULL(CAST(ProductId AS NVARCHAR(50)), ProductCode) AS productoId,
        ProductCode      AS codigo,
        ProductName      AS nombre,
        Quantity         AS cantidad,
        UnitPrice        AS precioUnitario,
        DiscountAmount   AS descuento,
        CASE WHEN TaxRate > 1 THEN TaxRate ELSE TaxRate * 100 END AS iva,
        NetAmount        AS subtotal,
        TotalAmount      AS total,
        SupervisorApprovalId AS supervisorApprovalId,
        LineMetaJson     AS lineMetaJson
    FROM pos.WaitTicketLine
    WHERE WaitTicketId = @WaitTicketId
    ORDER BY LineNumber;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_WaitTicket_Void
--  Anula un ticket de espera.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_WaitTicket_Void
    @CompanyId    INT,
    @BranchId     INT,
    @WaitTicketId BIGINT,
    @Resultado    INT OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pos.WaitTicket
    SET Status    = N'VOIDED',
        UpdatedAt = SYSUTCDATETIME()
    WHERE CompanyId    = @CompanyId
      AND BranchId     = @BranchId
      AND WaitTicketId = @WaitTicketId
      AND Status       = N'WAITING';

    SET @Resultado = 1;
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_SaleTicket_Create
--  Crea un ticket de venta y retorna el ID.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_SaleTicket_Create
    @CompanyId        INT,
    @BranchId         INT,
    @CountryCode      NVARCHAR(5),
    @InvoiceNumber    NVARCHAR(50),
    @CashRegisterCode NVARCHAR(20),
    @SoldByUserId     INT            = NULL,
    @CustomerId       INT            = NULL,
    @CustomerCode     NVARCHAR(50)   = NULL,
    @CustomerName     NVARCHAR(255)  = NULL,
    @CustomerFiscalId NVARCHAR(50)   = NULL,
    @PriceTier        NVARCHAR(50)   = N'Detal',
    @PaymentMethod    NVARCHAR(50)   = NULL,
    @FiscalPayload    NVARCHAR(MAX)  = NULL,
    @WaitTicketId     BIGINT         = NULL,
    @NetAmount        DECIMAL(18,2)  = 0,
    @DiscountAmount   DECIMAL(18,2)  = 0,
    @TaxAmount        DECIMAL(18,2)  = 0,
    @TotalAmount      DECIMAL(18,2)  = 0,
    @Resultado        INT OUTPUT,
    @Mensaje          NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pos.SaleTicket (
        CompanyId, BranchId, CountryCode, InvoiceNumber, CashRegisterCode,
        SoldByUserId, CustomerId, CustomerCode, CustomerName, CustomerFiscalId,
        PriceTier, PaymentMethod, FiscalPayload, WaitTicketId,
        NetAmount, DiscountAmount, TaxAmount, TotalAmount, SoldAt
    )
    VALUES (
        @CompanyId, @BranchId, @CountryCode, @InvoiceNumber, @CashRegisterCode,
        @SoldByUserId, @CustomerId, @CustomerCode, @CustomerName, @CustomerFiscalId,
        @PriceTier, @PaymentMethod, @FiscalPayload, @WaitTicketId,
        @NetAmount, @DiscountAmount, @TaxAmount, @TotalAmount, SYSUTCDATETIME()
    );

    SET @Resultado = SCOPE_IDENTITY();
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_POS_SaleTicketLine_Insert
--  Inserta una linea de ticket de venta.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_POS_SaleTicketLine_Insert
    @SaleTicketId         BIGINT,
    @LineNumber           INT,
    @CountryCode          NVARCHAR(5),
    @ProductId            INT            = NULL,
    @ProductCode          NVARCHAR(60),
    @ProductName          NVARCHAR(255),
    @Quantity             DECIMAL(18,4),
    @UnitPrice            DECIMAL(18,4),
    @DiscountAmount       DECIMAL(18,2)  = 0,
    @TaxCode              NVARCHAR(20),
    @TaxRate              DECIMAL(10,6),
    @NetAmount            DECIMAL(18,2),
    @TaxAmount            DECIMAL(18,2),
    @TotalAmount          DECIMAL(18,2),
    @SupervisorApprovalId INT            = NULL,
    @LineMetaJson         NVARCHAR(MAX)  = NULL,
    @Resultado            BIGINT OUTPUT,
    @Mensaje              NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pos.SaleTicketLine (
        SaleTicketId, LineNumber, CountryCode, ProductId, ProductCode, ProductName,
        Quantity, UnitPrice, DiscountAmount, TaxCode, TaxRate,
        NetAmount, TaxAmount, TotalAmount,
        SupervisorApprovalId, LineMetaJson
    )
    VALUES (
        @SaleTicketId, @LineNumber, @CountryCode, @ProductId, @ProductCode, @ProductName,
        @Quantity, @UnitPrice, @DiscountAmount, @TaxCode, @TaxRate,
        @NetAmount, @TaxAmount, @TotalAmount,
        @SupervisorApprovalId, @LineMetaJson
    );

    SET @Resultado = SCOPE_IDENTITY();
    SET @Mensaje = N'OK';
END;
GO


-- =============================================================================
--  SECCION 4: RESTAURANTE (restaurante/service.ts)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Rest_DiningTable_List
--  Lista mesas del restaurante con estado (libre/ocupada).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_DiningTable_List
    @CompanyId  INT,
    @BranchId   INT,
    @AmbienteId NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        dt.DiningTableId     AS id,
        dt.TableNumber       AS numero,
        ISNULL(NULLIF(dt.TableName, N''), N'Mesa ' + dt.TableNumber) AS nombre,
        dt.Capacity          AS capacidad,
        dt.EnvironmentCode   AS ambienteId,
        dt.EnvironmentName   AS ambiente,
        dt.PositionX         AS posicionX,
        dt.PositionY         AS posicionY,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM rest.OrderTicket o
                WHERE o.CompanyId   = dt.CompanyId
                  AND o.BranchId    = dt.BranchId
                  AND o.TableNumber = dt.TableNumber
                  AND o.Status IN (N'OPEN', N'SENT')
            ) THEN N'ocupada'
            ELSE N'libre'
        END AS estado
    FROM rest.DiningTable dt
    WHERE dt.CompanyId = @CompanyId
      AND dt.BranchId  = @BranchId
      AND dt.IsActive  = 1
      AND (@AmbienteId IS NULL OR dt.EnvironmentCode = @AmbienteId)
    ORDER BY dt.EnvironmentCode, TRY_CONVERT(INT, dt.TableNumber), dt.TableNumber;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_DiningTable_GetById
--  Obtiene una mesa por ID.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_DiningTable_GetById
    @CompanyId INT,
    @BranchId  INT,
    @MesaId    INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        DiningTableId    AS id,
        TableNumber      AS tableNumber,
        TableName        AS tableName,
        Capacity         AS capacity,
        EnvironmentCode  AS ambienteId,
        EnvironmentName  AS ambiente,
        PositionX        AS posicionX,
        PositionY        AS posicionY
    FROM rest.DiningTable
    WHERE CompanyId = @CompanyId
      AND BranchId  = @BranchId
      AND DiningTableId = @MesaId
      AND IsActive  = 1;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicket_GetOpenByTable
--  Busca un pedido abierto para un numero de mesa.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicket_GetOpenByTable
    @CompanyId    INT,
    @BranchId     INT,
    @TableNumber  NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        OrderTicketId AS id,
        Status        AS status
    FROM rest.OrderTicket
    WHERE CompanyId   = @CompanyId
      AND BranchId    = @BranchId
      AND TableNumber = @TableNumber
      AND Status IN (N'OPEN', N'SENT')
    ORDER BY OrderTicketId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicket_Create
--  Crea un pedido de restaurante.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicket_Create
    @CompanyId        INT,
    @BranchId         INT,
    @CountryCode      NVARCHAR(5),
    @TableNumber      NVARCHAR(20),
    @OpenedByUserId   INT           = NULL,
    @CustomerName     NVARCHAR(255) = NULL,
    @CustomerFiscalId NVARCHAR(50)  = NULL,
    @Resultado        INT OUTPUT,
    @Mensaje          NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO rest.OrderTicket (
        CompanyId, BranchId, CountryCode, TableNumber, OpenedByUserId,
        CustomerName, CustomerFiscalId,
        Status, NetAmount, TaxAmount, TotalAmount, OpenedAt
    )
    VALUES (
        @CompanyId, @BranchId, @CountryCode, @TableNumber, @OpenedByUserId,
        @CustomerName, @CustomerFiscalId,
        N'OPEN', 0, 0, 0, SYSUTCDATETIME()
    );

    SET @Resultado = SCOPE_IDENTITY();
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicket_GetById
--  Obtiene cabecera de un pedido para validacion.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicket_GetById
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        OrderTicketId AS orderId,
        CompanyId     AS companyId,
        BranchId      AS branchId,
        CountryCode   AS countryCode,
        Status        AS status
    FROM rest.OrderTicket
    WHERE OrderTicketId = @PedidoId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicketLine_NextLineNumber
--  Calcula el siguiente numero de linea.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicketLine_NextLineNumber
    @OrderId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL(MAX(LineNumber), 0) + 1 AS nextLine
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @OrderId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicketLine_Insert
--  Inserta una linea de pedido restaurante.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicketLine_Insert
    @OrderId              INT,
    @LineNumber           INT,
    @CountryCode          NVARCHAR(5),
    @ProductId            INT            = NULL,
    @ProductCode          NVARCHAR(60),
    @ProductName          NVARCHAR(255),
    @Quantity             DECIMAL(18,4),
    @UnitPrice            DECIMAL(18,4),
    @TaxCode              NVARCHAR(20),
    @TaxRate              DECIMAL(10,6),
    @NetAmount            DECIMAL(18,2),
    @TaxAmount            DECIMAL(18,2),
    @TotalAmount          DECIMAL(18,2),
    @Notes                NVARCHAR(600)  = NULL,
    @SupervisorApprovalId INT            = NULL,
    @Resultado            INT OUTPUT,
    @Mensaje              NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO rest.OrderTicketLine (
        OrderTicketId, LineNumber, CountryCode,
        ProductId, ProductCode, ProductName,
        Quantity, UnitPrice, TaxCode, TaxRate,
        NetAmount, TaxAmount, TotalAmount,
        Notes, SupervisorApprovalId,
        CreatedAt, UpdatedAt
    )
    VALUES (
        @OrderId, @LineNumber, @CountryCode,
        @ProductId, @ProductCode, @ProductName,
        @Quantity, @UnitPrice, @TaxCode, @TaxRate,
        @NetAmount, @TaxAmount, @TotalAmount,
        @Notes, @SupervisorApprovalId,
        SYSUTCDATETIME(), SYSUTCDATETIME()
    );

    SET @Resultado = SCOPE_IDENTITY();
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicket_RecalcTotals
--  Recalcula totales de un pedido a partir de sus lineas.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicket_RecalcTotals
    @OrderId INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Net   DECIMAL(18,2);
    DECLARE @Tax   DECIMAL(18,2);
    DECLARE @Total DECIMAL(18,2);

    SELECT
        @Net   = ISNULL(SUM(NetAmount), 0),
        @Tax   = ISNULL(SUM(TaxAmount), 0),
        @Total = ISNULL(SUM(TotalAmount), 0)
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @OrderId;

    UPDATE rest.OrderTicket
    SET NetAmount   = @Net,
        TaxAmount   = @Tax,
        TotalAmount = @Total,
        UpdatedAt   = SYSUTCDATETIME()
    WHERE OrderTicketId = @OrderId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicket_CheckPriorVoid
--  Verifica si un item ya fue anulado previamente.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicket_CheckPriorVoid
    @PedidoId INT,
    @ItemId   INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 1 AS alreadyVoided
    FROM sec.SupervisorOverride
    WHERE ModuleCode      = N'RESTAURANTE'
      AND ActionCode      = N'ORDER_LINE_VOID'
      AND Status          = N'CONSUMED'
      AND SourceDocumentId = @PedidoId
      AND SourceLineId    = @ItemId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicketLine_GetById
--  Obtiene una linea de pedido por ID.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicketLine_GetById
    @PedidoId INT,
    @ItemId   INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        OrderTicketLineId AS itemId,
        LineNumber        AS lineNumber,
        CountryCode       AS countryCode,
        ProductId         AS productId,
        ProductCode       AS productCode,
        ProductName       AS nombre,
        Quantity          AS cantidad,
        UnitPrice         AS unitPrice,
        TaxCode           AS taxCode,
        TaxRate           AS taxRate,
        NetAmount         AS netAmount,
        TaxAmount         AS taxAmount,
        TotalAmount       AS totalAmount
    FROM rest.OrderTicketLine
    WHERE OrderTicketId     = @PedidoId
      AND OrderTicketLineId = @ItemId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicket_SendToKitchen
--  Envia comanda a cocina (cambia OPEN -> SENT).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicket_SendToKitchen
    @PedidoId  INT,
    @Resultado INT OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE rest.OrderTicket
    SET Status    = CASE WHEN Status = N'OPEN' THEN N'SENT' ELSE Status END,
        UpdatedAt = SYSUTCDATETIME()
    WHERE OrderTicketId = @PedidoId;

    SET @Resultado = 1;
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicket_InferCountryCode
--  Infiere CountryCode desde fiscal.CountryConfig.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicket_InferCountryCode
    @EmpresaId  INT,
    @SucursalId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 CountryCode AS countryCode
    FROM fiscal.CountryConfig
    WHERE CompanyId = @EmpresaId
      AND BranchId  = @SucursalId
      AND IsActive  = 1
    ORDER BY UpdatedAt DESC, CountryConfigId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicket_GetHeaderForClose
--  Obtiene cabecera de pedido completa para cierre.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicket_GetHeaderForClose
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        o.OrderTicketId     AS id,
        o.CompanyId         AS empresaId,
        o.BranchId          AS sucursalId,
        o.CountryCode       AS countryCode,
        dt.DiningTableId    AS mesaId,
        o.CustomerName      AS clienteNombre,
        o.CustomerFiscalId  AS clienteRif,
        o.Status            AS estado,
        o.TotalAmount       AS total,
        o.ClosedAt          AS fechaCierre,
        COALESCE(uClose.UserCode, uOpen.UserCode) AS codUsuario
    FROM rest.OrderTicket o
    LEFT JOIN rest.DiningTable dt
       ON dt.CompanyId   = o.CompanyId
      AND dt.BranchId    = o.BranchId
      AND dt.TableNumber = o.TableNumber
    LEFT JOIN sec.[User] uOpen  ON uOpen.UserId  = o.OpenedByUserId
    LEFT JOIN sec.[User] uClose ON uClose.UserId = o.ClosedByUserId
    WHERE o.OrderTicketId = @PedidoId
    ORDER BY o.OrderTicketId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicket_Close
--  Cierra un pedido.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicket_Close
    @PedidoId        INT,
    @ClosedByUserId  INT = NULL,
    @Resultado       INT OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE rest.OrderTicket
    SET Status          = N'CLOSED',
        ClosedByUserId  = @ClosedByUserId,
        ClosedAt        = SYSUTCDATETIME(),
        UpdatedAt       = SYSUTCDATETIME()
    WHERE OrderTicketId = @PedidoId;

    SET @Resultado = 1;
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicketLine_GetFiscalBreakdown
--  Obtiene lineas de pedido para desglose fiscal.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicketLine_GetFiscalBreakdown
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        OrderTicketLineId AS itemId,
        ProductCode       AS productoId,
        ProductName       AS nombre,
        Quantity          AS quantity,
        UnitPrice         AS unitPrice,
        NetAmount         AS baseAmount,
        TaxCode           AS taxCode,
        TaxRate           AS taxRate,
        TaxAmount         AS taxAmount,
        TotalAmount       AS totalAmount
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @PedidoId
    ORDER BY LineNumber;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicket_GetByMesaHeader
--  Obtiene pedido abierto para una mesa con datos de cabecera.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicket_GetByMesaHeader
    @CompanyId    INT,
    @BranchId     INT,
    @TableNumber  NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        OrderTicketId    AS id,
        CustomerName     AS clienteNombre,
        CustomerFiscalId AS clienteRif,
        Status           AS estado,
        TotalAmount      AS total
    FROM rest.OrderTicket
    WHERE CompanyId   = @CompanyId
      AND BranchId    = @BranchId
      AND TableNumber = @TableNumber
      AND Status IN (N'OPEN', N'SENT')
    ORDER BY OrderTicketId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicketLine_GetByPedido
--  Obtiene lineas de pedido con formato para frontend.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicketLine_GetByPedido
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        OrderTicketLineId AS id,
        ProductCode       AS productoId,
        ProductName       AS nombre,
        Quantity          AS cantidad,
        UnitPrice         AS precioUnitario,
        NetAmount         AS subtotal,
        CASE WHEN TaxRate > 1 THEN TaxRate ELSE TaxRate * 100 END AS iva,
        TaxCode           AS taxCode,
        TaxAmount         AS impuesto,
        TotalAmount       AS total
    FROM rest.OrderTicketLine
    WHERE OrderTicketId = @PedidoId
    ORDER BY LineNumber;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Rest_OrderTicket_UpdateTimestamp
--  Actualiza el timestamp de un pedido.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Rest_OrderTicket_UpdateTimestamp
    @PedidoId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE rest.OrderTicket
    SET UpdatedAt = SYSUTCDATETIME()
    WHERE OrderTicketId = @PedidoId;
END;
GO


-- =============================================================================
--  SECCION 5: MOVIMIENTO INVENTARIO (movinvent/service.ts)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Movinvent_List (legacy master.InventoryMovement)
--  Lista movimientos de inventario paginados.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Movinvent_List
    @Search     NVARCHAR(200) = NULL,
    @Tipo       NVARCHAR(50)  = NULL,
    @Offset     INT = 0,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(1)
    FROM master.InventoryMovement
    WHERE IsDeleted = 0
      AND (@Search IS NULL
           OR ProductCode LIKE @Search
           OR ProductName LIKE @Search
           OR DocumentRef LIKE @Search)
      AND (@Tipo IS NULL OR MovementType = @Tipo);

    SELECT
        MovementId,
        ProductCode  AS Codigo,
        ProductName  AS Product,
        DocumentRef  AS Documento,
        MovementType AS Tipo,
        MovementDate AS Fecha,
        Quantity,
        UnitCost,
        TotalCost,
        Notes
    FROM master.InventoryMovement
    WHERE IsDeleted = 0
      AND (@Search IS NULL
           OR ProductCode LIKE @Search
           OR ProductName LIKE @Search
           OR DocumentRef LIKE @Search)
      AND (@Tipo IS NULL OR MovementType = @Tipo)
    ORDER BY MovementDate DESC, MovementId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Inv_Movement_GetById
--  Obtiene un movimiento de inventario por ID.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Inv_Movement_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        MovementId,
        ProductCode  AS Codigo,
        ProductName  AS Product,
        DocumentRef  AS Documento,
        MovementType AS Tipo,
        MovementDate AS Fecha,
        Quantity,
        UnitCost,
        TotalCost,
        Notes
    FROM master.InventoryMovement
    WHERE MovementId = @Id
      AND IsDeleted  = 0;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Inv_Movement_ListPeriodSummary
--  Lista resumenes de inventario por periodo, paginados.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Inv_Movement_ListPeriodSummary
    @Periodo    NVARCHAR(10) = NULL,
    @Codigo     NVARCHAR(60) = NULL,
    @Offset     INT = 0,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(1)
    FROM master.InventoryPeriodSummary
    WHERE (@Periodo IS NULL OR Period      = @Periodo)
      AND (@Codigo  IS NULL OR ProductCode = @Codigo);

    SELECT
        SummaryId,
        Period       AS Periodo,
        ProductCode  AS Codigo,
        OpeningQty,
        InboundQty,
        OutboundQty,
        ClosingQty,
        SummaryDate  AS fecha,
        IsClosed
    FROM master.InventoryPeriodSummary
    WHERE (@Periodo IS NULL OR Period      = @Periodo)
      AND (@Codigo  IS NULL OR ProductCode = @Codigo)
    ORDER BY Period DESC, ProductCode
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO


-- =============================================================================
--  SECCION 6: BANCOS - CONCILIACION (bancos/conciliacion.service.ts)
-- =============================================================================

-- -----------------------------------------------------------------------------
--  usp_Bank_ResolveScope
--  Resuelve scope con SystemUserId para modulo de bancos.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_ResolveScope
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        c.CompanyId  AS companyId,
        b.BranchId   AS branchId,
        su.UserId    AS systemUserId
    FROM cfg.Company c
    INNER JOIN cfg.Branch b
       ON b.CompanyId  = c.CompanyId
      AND b.BranchCode = N'MAIN'
    LEFT JOIN sec.[User] su
       ON su.UserCode = N'SYSTEM'
    WHERE c.CompanyCode = N'DEFAULT'
    ORDER BY c.CompanyId, b.BranchId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_ResolveUserId
--  Resuelve userId a partir de codigo, sin requerir IsDeleted/IsActive.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_ResolveUserId
    @Code NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 UserId AS userId
    FROM sec.[User]
    WHERE UPPER(UserCode) = UPPER(@Code)
    ORDER BY UserId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Account_GetByNumber
--  Obtiene una cuenta bancaria por numero de cuenta.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Account_GetByNumber
    @CompanyId INT,
    @NroCta    NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        ba.BankAccountId    AS bankAccountId,
        ba.AccountNumber    AS nroCta,
        b.BankName          AS bankName,
        ba.Balance          AS balance,
        ba.AvailableBalance AS availableBalance
    FROM fin.BankAccount ba
    INNER JOIN fin.Bank b ON b.BankId = ba.BankId
    WHERE ba.CompanyId     = @CompanyId
      AND ba.AccountNumber = @NroCta
      AND ba.IsActive      = 1
      AND b.IsActive       = 1
    ORDER BY ba.BankAccountId;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Movement_Create
--  Crea un movimiento bancario actualizando saldos en transaccion atomica.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Movement_Create
    @BankAccountId      BIGINT,
    @MovementType       NVARCHAR(12),
    @MovementSign       SMALLINT,
    @Amount             DECIMAL(18,2),
    @NetAmount          DECIMAL(18,2),
    @ReferenceNo        NVARCHAR(50)  = NULL,
    @Beneficiary        NVARCHAR(255) = NULL,
    @Concept            NVARCHAR(255) = NULL,
    @CategoryCode       NVARCHAR(50)  = NULL,
    @RelatedDocumentNo  NVARCHAR(60)  = NULL,
    @RelatedDocumentType NVARCHAR(20) = NULL,
    @CreatedByUserId    INT           = NULL,
    @Resultado          INT OUTPUT,
    @Mensaje            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentBalance    DECIMAL(18,2);
    DECLARE @CurrentAvailable  DECIMAL(18,2);
    DECLARE @NewBalance        DECIMAL(18,2);
    DECLARE @NewAvailable      DECIMAL(18,2);
    DECLARE @MovementId        INT;

    BEGIN TRANSACTION;

    -- Lock la cuenta y leer saldos actuales
    SELECT TOP 1
        @CurrentBalance   = Balance,
        @CurrentAvailable = AvailableBalance
    FROM fin.BankAccount WITH (UPDLOCK, ROWLOCK)
    WHERE BankAccountId = @BankAccountId;

    SET @NewBalance   = ROUND(@CurrentBalance + @NetAmount, 2);
    SET @NewAvailable = ROUND(ISNULL(@CurrentAvailable, @CurrentBalance) + @NetAmount, 2);

    -- Actualizar saldos
    UPDATE fin.BankAccount
    SET Balance          = @NewBalance,
        AvailableBalance = @NewAvailable,
        UpdatedAt        = SYSUTCDATETIME()
    WHERE BankAccountId  = @BankAccountId;

    -- Insertar movimiento
    INSERT INTO fin.BankMovement (
        BankAccountId, MovementDate, MovementType, MovementSign,
        Amount, NetAmount, ReferenceNo, Beneficiary, Concept,
        CategoryCode, RelatedDocumentNo, RelatedDocumentType,
        BalanceAfter, CreatedByUserId
    )
    VALUES (
        @BankAccountId, SYSUTCDATETIME(), @MovementType, @MovementSign,
        @Amount, @NetAmount, @ReferenceNo, @Beneficiary, @Concept,
        @CategoryCode, @RelatedDocumentNo, @RelatedDocumentType,
        @NewBalance, @CreatedByUserId
    );

    SET @MovementId = SCOPE_IDENTITY();

    COMMIT TRANSACTION;

    SET @Resultado = @MovementId;
    SET @Mensaje = CAST(@NewBalance AS NVARCHAR(50));

    -- Retornar resultado como recordset para lectura directa
    SELECT @MovementId AS movementId, @NewBalance AS newBalance;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Reconciliation_GetNetTotal
--  Calcula el total neto de movimientos en un rango de fechas.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Reconciliation_GetNetTotal
    @BankAccountId BIGINT,
    @FromDate      DATE,
    @ToDate        DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COALESCE(SUM(NetAmount), 0) AS netTotal
    FROM fin.BankMovement
    WHERE BankAccountId = @BankAccountId
      AND CAST(MovementDate AS DATE) BETWEEN @FromDate AND @ToDate;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Reconciliation_Create
--  Crea una conciliacion bancaria.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Reconciliation_Create
    @CompanyId        INT,
    @BranchId         INT,
    @BankAccountId    BIGINT,
    @FromDate         DATE,
    @ToDate           DATE,
    @Opening          DECIMAL(18,2),
    @Closing          DECIMAL(18,2),
    @CreatedByUserId  INT = NULL,
    @Resultado        INT OUTPUT,
    @Mensaje          NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO fin.BankReconciliation (
        CompanyId, BranchId, BankAccountId, DateFrom, DateTo,
        OpeningSystemBalance, ClosingSystemBalance, OpeningBankBalance,
        CreatedByUserId
    )
    VALUES (
        @CompanyId, @BranchId, @BankAccountId, @FromDate, @ToDate,
        @Opening, @Closing, @Opening,
        @CreatedByUserId
    );

    SET @Resultado = SCOPE_IDENTITY();
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Reconciliation_List
--  Lista conciliaciones bancarias paginadas.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Reconciliation_List
    @CompanyId  INT,
    @NroCta     NVARCHAR(40) = NULL,
    @Estado     NVARCHAR(30) = NULL,
    @Offset     INT = 0,
    @Limit      INT = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(1)
    FROM fin.BankReconciliation r
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = r.BankAccountId
    WHERE r.CompanyId = @CompanyId
      AND (@NroCta  IS NULL OR ba.AccountNumber = @NroCta)
      AND (@Estado  IS NULL OR r.Status         = @Estado);

    SELECT
        CAST(r.BankReconciliationId AS INT) AS ID,
        ba.AccountNumber                    AS Nro_Cta,
        CONVERT(VARCHAR(10), r.DateFrom, 23) AS Fecha_Desde,
        CONVERT(VARCHAR(10), r.DateTo, 23)   AS Fecha_Hasta,
        r.OpeningSystemBalance  AS Saldo_Inicial_Sistema,
        r.ClosingSystemBalance  AS Saldo_Final_Sistema,
        r.OpeningBankBalance    AS Saldo_Inicial_Banco,
        r.ClosingBankBalance    AS Saldo_Final_Banco,
        r.DifferenceAmount      AS Diferencia,
        r.Status                AS Estado,
        r.Notes                 AS Observaciones,
        b.BankName              AS Banco,
        (
            SELECT COUNT(1)
            FROM fin.BankStatementLine s
            WHERE s.ReconciliationId = r.BankReconciliationId
              AND s.IsMatched = 0
        ) AS Pendientes,
        (
            SELECT COUNT(1)
            FROM fin.BankStatementLine s
            WHERE s.ReconciliationId = r.BankReconciliationId
              AND s.IsMatched = 1
        ) AS Conciliados
    FROM fin.BankReconciliation r
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = r.BankAccountId
    INNER JOIN fin.Bank b         ON b.BankId         = ba.BankId
    WHERE r.CompanyId = @CompanyId
      AND (@NroCta  IS NULL OR ba.AccountNumber = @NroCta)
      AND (@Estado  IS NULL OR r.Status         = @Estado)
    ORDER BY r.BankReconciliationId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Reconciliation_GetById
--  Obtiene detalle de una conciliacion (cabecera).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Reconciliation_GetById
    @CompanyId INT,
    @Id        INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        CAST(r.BankReconciliationId AS INT) AS ID,
        ba.AccountNumber                    AS Nro_Cta,
        CONVERT(VARCHAR(10), r.DateFrom, 23) AS Fecha_Desde,
        CONVERT(VARCHAR(10), r.DateTo, 23)   AS Fecha_Hasta,
        r.OpeningSystemBalance  AS Saldo_Inicial_Sistema,
        r.ClosingSystemBalance  AS Saldo_Final_Sistema,
        r.OpeningBankBalance    AS Saldo_Inicial_Banco,
        r.ClosingBankBalance    AS Saldo_Final_Banco,
        r.DifferenceAmount      AS Diferencia,
        r.Status                AS Estado,
        r.Notes                 AS Observaciones,
        b.BankName              AS Banco
    FROM fin.BankReconciliation r
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = r.BankAccountId
    INNER JOIN fin.Bank b         ON b.BankId         = ba.BankId
    WHERE r.CompanyId            = @CompanyId
      AND r.BankReconciliationId = @Id;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Reconciliation_GetSystemMovements
--  Obtiene movimientos sistema de una conciliacion.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Reconciliation_GetSystemMovements
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.BankMovementId AS id,
        m.MovementDate   AS Fecha,
        m.MovementType   AS Tipo,
        m.ReferenceNo    AS Nro_Ref,
        m.Beneficiary    AS Beneficiario,
        m.Concept        AS Concepto,
        m.Amount         AS Monto,
        m.NetAmount      AS MontoNeto,
        m.BalanceAfter   AS SaldoPosterior,
        m.IsReconciled   AS Conciliado
    FROM fin.BankMovement m
    INNER JOIN fin.BankReconciliation r ON r.BankAccountId = m.BankAccountId
    WHERE r.BankReconciliationId = @Id
      AND CAST(m.MovementDate AS DATE) BETWEEN r.DateFrom AND r.DateTo
    ORDER BY m.MovementDate DESC, m.BankMovementId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Reconciliation_GetPendingStatements
--  Obtiene lineas de extracto pendientes.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Reconciliation_GetPendingStatements
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        StatementLineId  AS id,
        StatementDate    AS Fecha,
        DescriptionText  AS Descripcion,
        ReferenceNo      AS Referencia,
        EntryType        AS Tipo,
        Amount           AS Monto,
        Balance          AS Saldo
    FROM fin.BankStatementLine
    WHERE ReconciliationId = @Id
      AND IsMatched = 0
    ORDER BY StatementDate DESC, StatementLineId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Reconciliation_GetOpenForAccount
--  Obtiene la conciliacion abierta mas reciente para una cuenta.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Reconciliation_GetOpenForAccount
    @CompanyId      INT,
    @BankAccountId  BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 BankReconciliationId AS id
    FROM fin.BankReconciliation
    WHERE CompanyId      = @CompanyId
      AND BankAccountId  = @BankAccountId
      AND Status         = N'OPEN'
    ORDER BY BankReconciliationId DESC;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_StatementLine_Insert
--  Inserta una linea de extracto bancario.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_StatementLine_Insert
    @ReconciliationId  BIGINT,
    @StatementDate     DATETIME2,
    @DescriptionText   NVARCHAR(255) = NULL,
    @ReferenceNo       NVARCHAR(50)  = NULL,
    @EntryType         NVARCHAR(12),
    @Amount            DECIMAL(18,2),
    @Balance           DECIMAL(18,2) = NULL,
    @CreatedByUserId   INT           = NULL,
    @Resultado         INT OUTPUT,
    @Mensaje           NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO fin.BankStatementLine (
        ReconciliationId, StatementDate, DescriptionText, ReferenceNo,
        EntryType, Amount, Balance, CreatedByUserId
    )
    VALUES (
        @ReconciliationId, @StatementDate, @DescriptionText, @ReferenceNo,
        @EntryType, @Amount, @Balance, @CreatedByUserId
    );

    SET @Resultado = SCOPE_IDENTITY();
    SET @Mensaje = N'OK';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Reconciliation_MatchMovement
--  Concilia un movimiento con una linea de extracto (transaccion atomica).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Reconciliation_MatchMovement
    @ReconciliationId  BIGINT,
    @MovementId        BIGINT,
    @StatementId       BIGINT = NULL,
    @MatchedByUserId   INT    = NULL,
    @Resultado         INT OUTPUT,
    @Mensaje           NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validar que la conciliacion existe
    DECLARE @AccountId BIGINT;
    SELECT TOP 1 @AccountId = BankAccountId
    FROM fin.BankReconciliation
    WHERE BankReconciliationId = @ReconciliationId;

    IF @AccountId IS NULL
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = N'Conciliacion no encontrada';
        RETURN;
    END;

    -- Validar que el movimiento existe
    IF NOT EXISTS (
        SELECT 1
        FROM fin.BankMovement
        WHERE BankMovementId = @MovementId
          AND BankAccountId  = @AccountId
    )
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = N'Movimiento no encontrado';
        RETURN;
    END;

    -- Si no se pasa StatementId, buscar coincidencia automatica
    IF @StatementId IS NULL OR @StatementId = 0
    BEGIN
        DECLARE @ExpectedType NVARCHAR(12);
        DECLARE @MoveAmount   DECIMAL(18,2);

        SELECT TOP 1
            @ExpectedType = CASE WHEN MovementSign < 0 THEN N'DEBITO' ELSE N'CREDITO' END,
            @MoveAmount   = Amount
        FROM fin.BankMovement
        WHERE BankMovementId = @MovementId;

        SELECT TOP 1 @StatementId = StatementLineId
        FROM fin.BankStatementLine
        WHERE ReconciliationId = @ReconciliationId
          AND IsMatched        = 0
          AND EntryType        = @ExpectedType
          AND ABS(Amount - @MoveAmount) <= 0.01
        ORDER BY StatementDate, StatementLineId;
    END;

    BEGIN TRANSACTION;

    -- Insertar match (si no existe)
    IF NOT EXISTS (
        SELECT 1
        FROM fin.BankReconciliationMatch
        WHERE ReconciliationId = @ReconciliationId
          AND BankMovementId   = @MovementId
    )
    BEGIN
        INSERT INTO fin.BankReconciliationMatch (
            ReconciliationId, BankMovementId, StatementLineId, MatchedByUserId
        )
        VALUES (
            @ReconciliationId, @MovementId,
            CASE WHEN @StatementId > 0 THEN @StatementId ELSE NULL END,
            @MatchedByUserId
        );
    END;

    -- Marcar movimiento como conciliado
    UPDATE fin.BankMovement
    SET IsReconciled    = 1,
        ReconciledAt    = SYSUTCDATETIME(),
        ReconciliationId = @ReconciliationId
    WHERE BankMovementId = @MovementId;

    -- Si hay linea de extracto, marcarla como matched
    IF @StatementId IS NOT NULL AND @StatementId > 0
    BEGIN
        UPDATE fin.BankStatementLine
        SET IsMatched = 1,
            MatchedAt = SYSUTCDATETIME()
        WHERE StatementLineId = @StatementId;
    END;

    COMMIT TRANSACTION;

    SET @Resultado = 1;
    SET @Mensaje = N'Movimiento conciliado';
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Reconciliation_GetAccountNoById
--  Obtiene el numero de cuenta de una conciliacion.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Reconciliation_GetAccountNoById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 ba.AccountNumber AS accountNo
    FROM fin.BankReconciliation r
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = r.BankAccountId
    WHERE r.BankReconciliationId = @Id;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Reconciliation_Close
--  Cierra una conciliacion bancaria.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Reconciliation_Close
    @Id              INT,
    @BankClosing     DECIMAL(18,2),
    @Notes           NVARCHAR(500) = NULL,
    @ClosedByUserId  INT           = NULL,
    @Resultado       INT OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BankAccountId  BIGINT;
    DECLARE @SystemClosing  DECIMAL(18,2);
    DECLARE @Difference     DECIMAL(18,2);
    DECLARE @Status         NVARCHAR(30);

    -- Obtener la cuenta asociada
    SELECT TOP 1 @BankAccountId = BankAccountId
    FROM fin.BankReconciliation
    WHERE BankReconciliationId = @Id;

    IF @BankAccountId IS NULL
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje = N'Conciliacion no encontrada';
        RETURN;
    END;

    -- Obtener saldo actual del sistema
    SELECT TOP 1 @SystemClosing = Balance
    FROM fin.BankAccount
    WHERE BankAccountId = @BankAccountId;

    SET @Difference = ROUND(@BankClosing - @SystemClosing, 2);
    SET @Status = CASE WHEN ABS(@Difference) <= 0.01 THEN N'CLOSED' ELSE N'CLOSED_WITH_DIFF' END;

    -- Actualizar conciliacion
    UPDATE fin.BankReconciliation
    SET ClosingSystemBalance = @SystemClosing,
        ClosingBankBalance   = @BankClosing,
        DifferenceAmount     = @Difference,
        Status               = @Status,
        Notes                = COALESCE(@Notes, Notes),
        ClosedAt             = SYSUTCDATETIME(),
        ClosedByUserId       = @ClosedByUserId,
        UpdatedAt            = SYSUTCDATETIME()
    WHERE BankReconciliationId = @Id;

    SET @Resultado = 1;
    SET @Mensaje = N'OK';

    -- Retornar resultado
    SELECT @Difference AS diferencia, @Status AS estado;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Account_List
--  Lista cuentas bancarias activas.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Account_List
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ba.AccountNumber    AS Nro_Cta,
        b.BankName          AS Banco,
        ba.AccountName      AS Descripcion,
        ba.CurrencyCode     AS Moneda,
        ba.Balance          AS Saldo,
        ba.AvailableBalance AS Saldo_Disponible,
        b.BankName          AS BancoNombre
    FROM fin.BankAccount ba
    INNER JOIN fin.Bank b ON b.BankId = ba.BankId
    WHERE ba.CompanyId = @CompanyId
      AND ba.IsActive  = 1
      AND b.IsActive   = 1
    ORDER BY b.BankName, ba.AccountNumber;
END;
GO

-- -----------------------------------------------------------------------------
--  usp_Bank_Movement_ListByAccount
--  Lista movimientos de una cuenta bancaria paginados.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Movement_ListByAccount
    @CompanyId  INT,
    @NroCta     NVARCHAR(40),
    @FromDate   DATE = NULL,
    @ToDate     DATE = NULL,
    @Offset     INT  = 0,
    @Limit      INT  = 50,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(1)
    FROM fin.BankMovement m
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = m.BankAccountId
    WHERE ba.CompanyId     = @CompanyId
      AND ba.AccountNumber = @NroCta
      AND (@FromDate IS NULL OR m.MovementDate >= @FromDate)
      AND (@ToDate   IS NULL OR m.MovementDate <= @ToDate);

    SELECT
        m.BankMovementId     AS id,
        ba.AccountNumber     AS Nro_Cta,
        m.MovementDate       AS Fecha,
        m.MovementType       AS Tipo,
        m.ReferenceNo        AS Nro_Ref,
        m.Beneficiary        AS Beneficiario,
        m.Amount             AS Monto,
        m.NetAmount          AS MontoNeto,
        m.Concept            AS Concepto,
        m.CategoryCode       AS Categoria,
        m.RelatedDocumentNo  AS Documento_Relacionado,
        m.RelatedDocumentType AS Tipo_Doc_Rel,
        m.BalanceAfter       AS SaldoPosterior,
        m.IsReconciled       AS Conciliado
    FROM fin.BankMovement m
    INNER JOIN fin.BankAccount ba ON ba.BankAccountId = m.BankAccountId
    WHERE ba.CompanyId     = @CompanyId
      AND ba.AccountNumber = @NroCta
      AND (@FromDate IS NULL OR m.MovementDate >= @FromDate)
      AND (@ToDate   IS NULL OR m.MovementDate <= @ToDate)
    ORDER BY m.MovementDate DESC, m.BankMovementId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- usp_Bank_Movement_LinkJournalEntry
-- Vincula un movimiento bancario con un asiento contable autogenerado.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Movement_LinkJournalEntry
    @MovementId      BIGINT,
    @JournalEntryId  BIGINT,
    @Resultado       INT           OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF NOT EXISTS (SELECT 1 FROM fin.BankMovement WHERE BankMovementId = @MovementId)
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = N'Movimiento no encontrado';
        RETURN;
    END;

    UPDATE fin.BankMovement
    SET JournalEntryId = @JournalEntryId
    WHERE BankMovementId = @MovementId;

    SET @Resultado = 1;
    SET @Mensaje   = N'OK';
END;
GO

-- =============================================================================
-- usp_Bank_Reconciliation_GetLinkedEntries
-- Obtiene asientos contables vinculados a una conciliación bancaria.
-- Busca por: BankMovement.JournalEntryId + acct.DocumentLink(BANCOS/CONCILIACION).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Bank_Reconciliation_GetLinkedEntries
    @ReconciliationId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DISTINCT
        je.JournalEntryId,
        je.EntryNumber,
        je.EntryDate,
        je.Concept,
        je.TotalDebit,
        je.TotalCredit,
        je.[Status],
        je.SourceModule,
        je.SourceDocumentNo
    FROM fin.BankMovement m
    INNER JOIN acct.JournalEntry je ON je.JournalEntryId = m.JournalEntryId
    WHERE m.ReconciliationId = @ReconciliationId
      AND m.JournalEntryId IS NOT NULL
      AND je.IsDeleted = 0

    UNION

    SELECT
        je2.JournalEntryId,
        je2.EntryNumber,
        je2.EntryDate,
        je2.Concept,
        je2.TotalDebit,
        je2.TotalCredit,
        je2.[Status],
        je2.SourceModule,
        je2.SourceDocumentNo
    FROM acct.DocumentLink dl
    INNER JOIN acct.JournalEntry je2 ON je2.JournalEntryId = dl.JournalEntryId
    WHERE dl.ModuleCode       = N'BANCOS'
      AND dl.DocumentType     = N'CONCILIACION'
      AND dl.NativeDocumentId = @ReconciliationId
      AND je2.IsDeleted = 0

    ORDER BY EntryDate DESC, JournalEntryId DESC;
END;
GO

PRINT '>>> usp_ops.sql ejecutado correctamente <<<';
GO
