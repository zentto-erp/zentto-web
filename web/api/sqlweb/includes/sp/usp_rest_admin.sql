/*
 * ============================================================================
 *  Archivo : usp_rest_admin.sql
 *  Esquema : rest (subsistema restaurante - tablas canonicas)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-14
 *
 *  Descripcion:
 *    Procedimientos almacenados para el modulo administrativo del restaurante
 *    usando tablas canonicas (rest.MenuEnvironment, rest.MenuCategory,
 *    rest.MenuProduct, rest.MenuComponent, rest.MenuOption, rest.MenuRecipe,
 *    rest.Purchase, rest.PurchaseLine, master.Supplier, master.Product).
 *
 *  Patron  : CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- ============================================================================
-- HELPERS INTERNOS
-- ============================================================================

-- ============================================================================
-- usp_Rest_Admin_ResolveSupplier
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_ResolveSupplier
    @CompanyId INT,
    @Key       NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 SupplierId AS supplierId
    FROM [master].Supplier
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND IsActive = 1
      AND (
          SupplierCode = @Key
          OR CAST(SupplierId AS NVARCHAR(30)) = @Key
      )
    ORDER BY SupplierId;
END;
GO

-- ============================================================================
-- usp_Rest_Admin_ResolveProduct
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_ResolveProduct
    @CompanyId INT,
    @Key       NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 ProductId AS productId
    FROM [master].Product
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND IsActive = 1
      AND (
          ProductCode = @Key
          OR CAST(ProductId AS NVARCHAR(30)) = @Key
      )
    ORDER BY ProductId;
END;
GO

-- ============================================================================
-- usp_Rest_Admin_ResolveMenuCategory
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_ResolveMenuCategory
    @MenuCategoryId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 MenuCategoryId AS id
    FROM rest.MenuCategory
    WHERE MenuCategoryId = @MenuCategoryId;
END;
GO

-- ============================================================================
-- AMBIENTES
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Ambiente_List
    @CompanyId INT,
    @BranchId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        MenuEnvironmentId AS id,
        EnvironmentName   AS nombre,
        ColorHex          AS color,
        SortOrder         AS orden
    FROM rest.MenuEnvironment
    WHERE CompanyId = @CompanyId
      AND BranchId  = @BranchId
      AND IsActive  = 1
    ORDER BY SortOrder, EnvironmentName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Ambiente_Upsert
    @Id        INT = 0,
    @CompanyId INT,
    @BranchId  INT,
    @Code      NVARCHAR(30),
    @Nombre    NVARCHAR(100),
    @Color     NVARCHAR(10) = NULL,
    @Orden     INT = 0,
    @UserId    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id > 0 AND EXISTS (SELECT 1 FROM rest.MenuEnvironment WHERE MenuEnvironmentId = @Id)
    BEGIN
        UPDATE rest.MenuEnvironment
        SET EnvironmentName = @Nombre,
            ColorHex = @Color,
            SortOrder = @Orden,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedByUserId = @UserId
        WHERE MenuEnvironmentId = @Id;

        SELECT @Id AS id;
    END
    ELSE
    BEGIN
        INSERT INTO rest.MenuEnvironment (
            CompanyId, BranchId, EnvironmentCode, EnvironmentName,
            ColorHex, SortOrder, IsActive, CreatedByUserId, UpdatedByUserId
        )
        VALUES (
            @CompanyId, @BranchId, @Code, @Nombre,
            @Color, @Orden, 1, @UserId, @UserId
        );

        SELECT SCOPE_IDENTITY() AS id;
    END;
END;
GO

-- ============================================================================
-- CATEGORIAS MENU
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Categoria_List
    @CompanyId INT,
    @BranchId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        MenuCategoryId  AS id,
        CategoryName    AS nombre,
        DescriptionText AS descripcion,
        ColorHex        AS color,
        SortOrder       AS orden
    FROM rest.MenuCategory
    WHERE CompanyId = @CompanyId
      AND BranchId  = @BranchId
      AND IsActive  = 1
    ORDER BY SortOrder, CategoryName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Categoria_Upsert
    @Id          INT = 0,
    @CompanyId   INT,
    @BranchId    INT,
    @Code        NVARCHAR(30),
    @Nombre      NVARCHAR(100),
    @Descripcion NVARCHAR(500) = NULL,
    @Color       NVARCHAR(10) = NULL,
    @Orden       INT = 0,
    @UserId      INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id > 0 AND EXISTS (SELECT 1 FROM rest.MenuCategory WHERE MenuCategoryId = @Id)
    BEGIN
        UPDATE rest.MenuCategory
        SET CategoryName = @Nombre,
            DescriptionText = @Descripcion,
            ColorHex = @Color,
            SortOrder = @Orden,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedByUserId = @UserId
        WHERE MenuCategoryId = @Id;

        SELECT @Id AS id;
    END
    ELSE
    BEGIN
        INSERT INTO rest.MenuCategory (
            CompanyId, BranchId, CategoryCode, CategoryName,
            DescriptionText, ColorHex, SortOrder, IsActive,
            CreatedByUserId, UpdatedByUserId
        )
        VALUES (
            @CompanyId, @BranchId, @Code, @Nombre,
            @Descripcion, @Color, @Orden, 1,
            @UserId, @UserId
        );

        SELECT SCOPE_IDENTITY() AS id;
    END;
END;
GO

-- ============================================================================
-- PRODUCTOS MENU
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Producto_List
    @CompanyId       INT,
    @BranchId        INT,
    @MenuCategoryId  INT = NULL,
    @Search          NVARCHAR(100) = NULL,
    @SoloDisponibles BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        mp.MenuProductId AS id,
        mp.ProductCode   AS codigo,
        mp.ProductName   AS nombre,
        mp.DescriptionText AS descripcion,
        mp.MenuCategoryId  AS categoriaId,
        mc.CategoryName    AS categoriaNombre,
        mp.PriceAmount     AS precio,
        mp.EstimatedCost   AS costoEstimado,
        mp.TaxRatePercent  AS iva,
        mp.IsComposite     AS esCompuesto,
        mp.PrepMinutes     AS tiempoPreparacion,
        COALESCE(img.PublicUrl, mp.ImageUrl) AS imagen,
        mp.IsDailySuggestion AS esSugerenciaDelDia,
        mp.IsAvailable       AS disponible,
        inv.ProductCode      AS articuloInventarioId
    FROM rest.MenuProduct mp
    LEFT JOIN rest.MenuCategory mc ON mc.MenuCategoryId = mp.MenuCategoryId
    LEFT JOIN [master].Product inv ON inv.ProductId = mp.InventoryProductId
    OUTER APPLY (
        SELECT TOP 1 ma.PublicUrl
        FROM cfg.EntityImage ei
        INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
        WHERE ei.CompanyId = mp.CompanyId
          AND ei.BranchId = mp.BranchId
          AND ei.EntityType = N'REST_MENU_PRODUCT'
          AND ei.EntityId = mp.MenuProductId
          AND ei.IsDeleted = 0 AND ei.IsActive = 1
          AND ma.IsDeleted = 0 AND ma.IsActive = 1
        ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    WHERE mp.CompanyId = @CompanyId
      AND mp.BranchId  = @BranchId
      AND mp.IsActive = 1
      AND (@SoloDisponibles = 0 OR mp.IsAvailable = 1)
      AND (@MenuCategoryId IS NULL OR mp.MenuCategoryId = @MenuCategoryId)
      AND (@Search IS NULL OR mp.ProductCode LIKE @Search OR mp.ProductName LIKE @Search)
    ORDER BY mp.ProductName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Producto_Get
    @Id       INT,
    @BranchId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Resultset 1: producto
    SELECT TOP 1
        mp.MenuProductId AS id,
        mp.ProductCode   AS codigo,
        mp.ProductName   AS nombre,
        mp.DescriptionText AS descripcion,
        mp.MenuCategoryId  AS categoriaId,
        mp.PriceAmount     AS precio,
        mp.EstimatedCost   AS costoEstimado,
        mp.TaxRatePercent  AS iva,
        mp.IsComposite     AS esCompuesto,
        mp.PrepMinutes     AS tiempoPreparacion,
        COALESCE(img.PublicUrl, mp.ImageUrl) AS imagen,
        mp.IsDailySuggestion AS esSugerenciaDelDia,
        mp.IsAvailable       AS disponible,
        inv.ProductCode      AS articuloInventarioId
    FROM rest.MenuProduct mp
    LEFT JOIN [master].Product inv ON inv.ProductId = mp.InventoryProductId
    OUTER APPLY (
        SELECT TOP 1 ma.PublicUrl
        FROM cfg.EntityImage ei
        INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
        WHERE ei.CompanyId = mp.CompanyId
          AND ei.BranchId = mp.BranchId
          AND ei.EntityType = N'REST_MENU_PRODUCT'
          AND ei.EntityId = mp.MenuProductId
          AND ei.IsDeleted = 0 AND ei.IsActive = 1
          AND ma.IsDeleted = 0 AND ma.IsActive = 1
        ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    WHERE mp.MenuProductId = @Id
      AND mp.IsActive = 1;

    -- Resultset 2: componentes + opciones
    SELECT
        c.MenuComponentId AS id,
        c.ComponentName   AS nombre,
        c.IsRequired      AS obligatorio,
        c.SortOrder       AS orden,
        o.MenuOptionId    AS opcionId,
        o.OptionName      AS opcionNombre,
        o.ExtraPrice      AS precioExtra,
        o.SortOrder       AS opcionOrden
    FROM rest.MenuComponent c
    LEFT JOIN rest.MenuOption o
      ON o.MenuComponentId = c.MenuComponentId
     AND o.IsActive = 1
    WHERE c.MenuProductId = @Id
      AND c.IsActive = 1
    ORDER BY c.SortOrder, c.MenuComponentId, o.SortOrder, o.MenuOptionId;

    -- Resultset 3: receta
    SELECT
        r.MenuRecipeId AS id,
        r.MenuProductId AS productoId,
        p.ProductCode   AS inventarioId,
        p.ProductName   AS descripcion,
        img.PublicUrl   AS imagen,
        r.Quantity      AS cantidad,
        r.UnitCode      AS unidad,
        r.Notes         AS comentario
    FROM rest.MenuRecipe r
    INNER JOIN [master].Product p ON p.ProductId = r.IngredientProductId
    OUTER APPLY (
        SELECT TOP 1 ma.PublicUrl
        FROM cfg.EntityImage ei
        INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
        WHERE ei.CompanyId = p.CompanyId
          AND ei.BranchId = @BranchId
          AND ei.EntityType = N'MASTER_PRODUCT'
          AND ei.EntityId = p.ProductId
          AND ei.IsDeleted = 0 AND ei.IsActive = 1
          AND ma.IsDeleted = 0 AND ma.IsActive = 1
        ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    WHERE r.MenuProductId = @Id
      AND r.IsActive = 1
    ORDER BY r.MenuRecipeId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Producto_Upsert
    @Id                 INT = 0,
    @CompanyId          INT,
    @BranchId           INT,
    @Code               NVARCHAR(20),
    @Name               NVARCHAR(200),
    @Description        NVARCHAR(500) = NULL,
    @MenuCategoryId     INT = NULL,
    @Price              DECIMAL(18,2) = 0,
    @EstimatedCost      DECIMAL(18,2) = 0,
    @TaxRatePercent     DECIMAL(5,2) = 16,
    @IsComposite        BIT = 0,
    @PrepMinutes        INT = 0,
    @ImageUrl           NVARCHAR(500) = NULL,
    @IsDailySuggestion  BIT = 0,
    @IsAvailable        BIT = 1,
    @InventoryProductId INT = NULL,
    @UserId             INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id > 0 AND EXISTS (SELECT 1 FROM rest.MenuProduct WHERE MenuProductId = @Id)
    BEGIN
        UPDATE rest.MenuProduct
        SET ProductCode = @Code,
            ProductName = @Name,
            DescriptionText = @Description,
            MenuCategoryId = @MenuCategoryId,
            PriceAmount = @Price,
            EstimatedCost = @EstimatedCost,
            TaxRatePercent = @TaxRatePercent,
            IsComposite = @IsComposite,
            PrepMinutes = @PrepMinutes,
            ImageUrl = @ImageUrl,
            IsDailySuggestion = @IsDailySuggestion,
            IsAvailable = @IsAvailable,
            InventoryProductId = @InventoryProductId,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedByUserId = @UserId
        WHERE MenuProductId = @Id;

        SELECT @Id AS id;
    END
    ELSE
    BEGIN
        INSERT INTO rest.MenuProduct (
            CompanyId, BranchId, ProductCode, ProductName, DescriptionText,
            MenuCategoryId, PriceAmount, EstimatedCost, TaxRatePercent,
            IsComposite, PrepMinutes, ImageUrl, IsDailySuggestion,
            IsAvailable, InventoryProductId, IsActive,
            CreatedByUserId, UpdatedByUserId
        )
        VALUES (
            @CompanyId, @BranchId, @Code, @Name, @Description,
            @MenuCategoryId, @Price, @EstimatedCost, @TaxRatePercent,
            @IsComposite, @PrepMinutes, @ImageUrl, @IsDailySuggestion,
            @IsAvailable, @InventoryProductId, 1,
            @UserId, @UserId
        );

        SELECT SCOPE_IDENTITY() AS id;
    END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Producto_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE rest.MenuProduct
    SET IsActive = 0,
        IsAvailable = 0,
        UpdatedAt = SYSUTCDATETIME()
    WHERE MenuProductId = @Id;
END;
GO

-- ============================================================================
-- COMPONENTES / OPCIONES
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Componente_Upsert
    @Id          INT = 0,
    @ProductoId  INT,
    @Nombre      NVARCHAR(100),
    @Obligatorio BIT = 0,
    @Orden       INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id > 0 AND EXISTS (SELECT 1 FROM rest.MenuComponent WHERE MenuComponentId = @Id)
    BEGIN
        UPDATE rest.MenuComponent
        SET ComponentName = @Nombre,
            IsRequired = @Obligatorio,
            SortOrder = @Orden,
            UpdatedAt = SYSUTCDATETIME()
        WHERE MenuComponentId = @Id;

        SELECT @Id AS id;
    END
    ELSE
    BEGIN
        INSERT INTO rest.MenuComponent (
            MenuProductId, ComponentName, IsRequired, SortOrder, IsActive
        )
        VALUES (@ProductoId, @Nombre, @Obligatorio, @Orden, 1);

        SELECT SCOPE_IDENTITY() AS id;
    END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Opcion_Upsert
    @Id           INT = 0,
    @ComponenteId INT,
    @Nombre       NVARCHAR(100),
    @PrecioExtra  DECIMAL(18,2) = 0,
    @Orden        INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id > 0 AND EXISTS (SELECT 1 FROM rest.MenuOption WHERE MenuOptionId = @Id)
    BEGIN
        UPDATE rest.MenuOption
        SET OptionName = @Nombre,
            ExtraPrice = @PrecioExtra,
            SortOrder = @Orden,
            UpdatedAt = SYSUTCDATETIME()
        WHERE MenuOptionId = @Id;

        SELECT @Id AS id;
    END
    ELSE
    BEGIN
        INSERT INTO rest.MenuOption (
            MenuComponentId, OptionName, ExtraPrice, SortOrder, IsActive
        )
        VALUES (@ComponenteId, @Nombre, @PrecioExtra, @Orden, 1);

        SELECT SCOPE_IDENTITY() AS id;
    END;
END;
GO

-- ============================================================================
-- RECETAS
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Receta_Upsert
    @Id                  INT = 0,
    @ProductoId          INT,
    @IngredientProductId INT,
    @Quantity            DECIMAL(10,3),
    @UnitCode            NVARCHAR(20) = NULL,
    @Notes               NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id > 0 AND EXISTS (SELECT 1 FROM rest.MenuRecipe WHERE MenuRecipeId = @Id)
    BEGIN
        UPDATE rest.MenuRecipe
        SET IngredientProductId = @IngredientProductId,
            Quantity = @Quantity,
            UnitCode = @UnitCode,
            Notes = @Notes,
            IsActive = 1,
            UpdatedAt = SYSUTCDATETIME()
        WHERE MenuRecipeId = @Id;

        SELECT @Id AS id;
    END
    ELSE
    BEGIN
        INSERT INTO rest.MenuRecipe (
            MenuProductId, IngredientProductId, Quantity, UnitCode, Notes, IsActive
        )
        VALUES (@ProductoId, @IngredientProductId, @Quantity, @UnitCode, @Notes, 1);

        SELECT SCOPE_IDENTITY() AS id;
    END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Receta_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE rest.MenuRecipe
    SET IsActive = 0,
        UpdatedAt = SYSUTCDATETIME()
    WHERE MenuRecipeId = @Id;
END;
GO

-- ============================================================================
-- COMPRAS
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Compra_List
    @CompanyId INT,
    @BranchId  INT,
    @Status    NVARCHAR(20) = NULL,
    @FromDate  DATETIME = NULL,
    @ToDate    DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.PurchaseId      AS id,
        p.PurchaseNumber  AS numCompra,
        s.SupplierCode    AS proveedorId,
        s.SupplierName    AS proveedorNombre,
        p.PurchaseDate    AS fechaCompra,
        p.Status          AS estado,
        p.SubtotalAmount  AS subtotal,
        p.TaxAmount       AS iva,
        p.TotalAmount     AS total,
        p.Notes           AS observaciones
    FROM rest.Purchase p
    LEFT JOIN [master].Supplier s ON s.SupplierId = p.SupplierId
    WHERE p.CompanyId = @CompanyId
      AND p.BranchId  = @BranchId
      AND (@Status IS NULL OR p.Status = @Status)
      AND (@FromDate IS NULL OR p.PurchaseDate >= @FromDate)
      AND (@ToDate IS NULL OR p.PurchaseDate <= @ToDate)
    ORDER BY p.PurchaseDate DESC, p.PurchaseId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Compra_GetDetalle
    @CompraId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Resultset 1: cabecera
    SELECT TOP 1
        p.PurchaseId     AS id,
        p.PurchaseNumber AS numCompra,
        s.SupplierCode   AS proveedorId,
        s.SupplierName   AS proveedorNombre,
        p.PurchaseDate   AS fechaCompra,
        p.Status         AS estado,
        p.SubtotalAmount AS subtotal,
        p.TaxAmount      AS iva,
        p.TotalAmount    AS total,
        p.Notes          AS observaciones,
        u.UserCode       AS codUsuario
    FROM rest.Purchase p
    LEFT JOIN [master].Supplier s ON s.SupplierId = p.SupplierId
    LEFT JOIN sec.[User] u ON u.UserId = p.CreatedByUserId
    WHERE p.PurchaseId = @CompraId;

    -- Resultset 2: lineas
    SELECT
        pl.PurchaseLineId   AS id,
        pl.PurchaseId       AS compraId,
        pr.ProductCode      AS inventarioId,
        pl.DescriptionText  AS descripcion,
        pl.Quantity         AS cantidad,
        pl.UnitPrice        AS precioUnit,
        pl.SubtotalAmount   AS subtotal,
        pl.TaxRatePercent   AS iva
    FROM rest.PurchaseLine pl
    LEFT JOIN [master].Product pr ON pr.ProductId = pl.IngredientProductId
    WHERE pl.PurchaseId = @CompraId
    ORDER BY pl.PurchaseLineId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Compra_GetNextSeq
    @CompanyId INT,
    @BranchId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COALESCE(MAX(PurchaseId), 0) + 1 AS seq
    FROM rest.Purchase
    WHERE CompanyId = @CompanyId
      AND BranchId  = @BranchId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Compra_Insert
    @CompanyId      INT,
    @BranchId       INT,
    @PurchaseNumber NVARCHAR(20),
    @SupplierId     INT = NULL,
    @Notes          NVARCHAR(500) = NULL,
    @UserId         INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO rest.Purchase (
        CompanyId, BranchId, PurchaseNumber, SupplierId,
        PurchaseDate, Status, Notes, CreatedByUserId, UpdatedByUserId
    )
    VALUES (
        @CompanyId, @BranchId, @PurchaseNumber, @SupplierId,
        SYSUTCDATETIME(), N'PENDIENTE', @Notes, @UserId, @UserId
    );

    SELECT SCOPE_IDENTITY() AS id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Compra_Update
    @CompraId   INT,
    @SupplierId INT = NULL,
    @Status     NVARCHAR(20) = NULL,
    @Notes      NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE rest.Purchase
    SET SupplierId = COALESCE(@SupplierId, SupplierId),
        Status     = COALESCE(@Status, Status),
        Notes      = COALESCE(@Notes, Notes),
        UpdatedAt  = SYSUTCDATETIME()
    WHERE PurchaseId = @CompraId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_CompraLinea_GetPrev
    @Id       INT,
    @CompraId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        IngredientProductId AS ingredientProductId,
        Quantity            AS quantity
    FROM rest.PurchaseLine
    WHERE PurchaseLineId = @Id
      AND PurchaseId = @CompraId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_CompraLinea_Upsert
    @Id                  INT = 0,
    @CompraId            INT,
    @IngredientProductId INT = NULL,
    @Descripcion         NVARCHAR(200),
    @Quantity            DECIMAL(10,3),
    @UnitPrice           DECIMAL(18,2),
    @TaxRatePercent      DECIMAL(5,2) = 16,
    @Subtotal            DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id > 0
    BEGIN
        UPDATE rest.PurchaseLine
        SET IngredientProductId = @IngredientProductId,
            DescriptionText = @Descripcion,
            Quantity = @Quantity,
            UnitPrice = @UnitPrice,
            TaxRatePercent = @TaxRatePercent,
            SubtotalAmount = @Subtotal,
            UpdatedAt = SYSUTCDATETIME()
        WHERE PurchaseLineId = @Id
          AND PurchaseId = @CompraId;

        SELECT @Id AS id;
    END
    ELSE
    BEGIN
        INSERT INTO rest.PurchaseLine (
            PurchaseId, IngredientProductId, DescriptionText,
            Quantity, UnitPrice, TaxRatePercent, SubtotalAmount
        )
        VALUES (
            @CompraId, @IngredientProductId, @Descripcion,
            @Quantity, @UnitPrice, @TaxRatePercent, @Subtotal
        );

        SELECT SCOPE_IDENTITY() AS id;
    END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_CompraLinea_Delete
    @CompraId  INT,
    @DetalleId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Devolver datos previos antes de borrar
    SELECT TOP 1
        IngredientProductId AS ingredientProductId,
        Quantity            AS quantity
    FROM rest.PurchaseLine
    WHERE PurchaseLineId = @DetalleId
      AND PurchaseId = @CompraId;

    DELETE FROM rest.PurchaseLine
    WHERE PurchaseLineId = @DetalleId
      AND PurchaseId = @CompraId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Compra_RecalcTotals
    @PurchaseId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET SubtotalAmount = x.subtotal,
        TaxAmount      = x.tax,
        TotalAmount    = x.total,
        UpdatedAt      = SYSUTCDATETIME()
    FROM rest.Purchase p
    CROSS APPLY (
        SELECT
            COALESCE(SUM(SubtotalAmount), 0) AS subtotal,
            COALESCE(SUM(SubtotalAmount * TaxRatePercent / 100.0), 0) AS tax,
            COALESCE(SUM(SubtotalAmount + (SubtotalAmount * TaxRatePercent / 100.0)), 0) AS total
        FROM rest.PurchaseLine
        WHERE PurchaseId = @PurchaseId
    ) x
    WHERE p.PurchaseId = @PurchaseId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_AdjustStock
    @ProductId INT,
    @DeltaQty  DECIMAL(18,4)
AS
BEGIN
    SET NOCOUNT ON;

    IF @ProductId IS NULL OR @DeltaQty = 0 RETURN;

    UPDATE [master].Product
    SET StockQty = COALESCE(StockQty, 0) + @DeltaQty,
        UpdatedAt = SYSUTCDATETIME()
    WHERE ProductId = @ProductId;
END;
GO

-- ============================================================================
-- SYNC IMAGE LINK (para vincular imagen al producto del menu)
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_SyncMenuProductImage
    @CompanyId     INT,
    @BranchId      INT,
    @MenuProductId INT,
    @StorageKey    NVARCHAR(500),
    @UserId        INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @StorageKey IS NULL OR LEN(@StorageKey) = 0 RETURN;

    DECLARE @MediaAssetId INT;

    SELECT TOP 1 @MediaAssetId = MediaAssetId
    FROM cfg.MediaAsset
    WHERE CompanyId = @CompanyId
      AND BranchId  = @BranchId
      AND StorageKey = @StorageKey
      AND IsDeleted = 0
      AND IsActive = 1
    ORDER BY MediaAssetId DESC;

    IF @MediaAssetId IS NULL RETURN;

    -- Quitar primary de todos
    UPDATE cfg.EntityImage
    SET IsPrimary = 0,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @UserId
    WHERE CompanyId = @CompanyId
      AND BranchId  = @BranchId
      AND EntityType = N'REST_MENU_PRODUCT'
      AND EntityId   = @MenuProductId
      AND IsDeleted  = 0
      AND IsActive   = 1;

    IF EXISTS (
        SELECT 1 FROM cfg.EntityImage
        WHERE CompanyId = @CompanyId
          AND BranchId  = @BranchId
          AND EntityType = N'REST_MENU_PRODUCT'
          AND EntityId   = @MenuProductId
          AND MediaAssetId = @MediaAssetId
    )
    BEGIN
        UPDATE cfg.EntityImage
        SET IsPrimary = 1,
            SortOrder = 0,
            IsActive  = 1,
            IsDeleted = 0,
            UpdatedAt = SYSUTCDATETIME(),
            UpdatedByUserId = @UserId
        WHERE CompanyId = @CompanyId
          AND BranchId  = @BranchId
          AND EntityType = N'REST_MENU_PRODUCT'
          AND EntityId   = @MenuProductId
          AND MediaAssetId = @MediaAssetId;
    END
    ELSE
    BEGIN
        INSERT INTO cfg.EntityImage (
            CompanyId, BranchId, EntityType, EntityId, MediaAssetId,
            SortOrder, IsPrimary, CreatedByUserId, UpdatedByUserId
        )
        VALUES (
            @CompanyId, @BranchId, N'REST_MENU_PRODUCT', @MenuProductId, @MediaAssetId,
            0, 1, @UserId, @UserId
        );
    END;
END;
GO

-- ============================================================================
-- BUSQUEDA DE PROVEEDORES
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Proveedor_Search
    @CompanyId INT,
    @Search    NVARCHAR(100) = NULL,
    @Limit     INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        SupplierId   AS id,
        SupplierCode AS codigo,
        SupplierName AS nombre,
        FiscalId     AS rif,
        Phone        AS telefono,
        AddressLine  AS direccion
    FROM [master].Supplier
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND IsActive = 1
      AND (
          @Search IS NULL
          OR SupplierCode LIKE @Search
          OR SupplierName LIKE @Search
          OR FiscalId LIKE @Search
      )
    ORDER BY SupplierName;
END;
GO

-- ============================================================================
-- BUSQUEDA DE INSUMOS
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.usp_Rest_Admin_Insumo_Search
    @CompanyId INT,
    @BranchId  INT,
    @Search    NVARCHAR(100) = NULL,
    @Limit     INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        p.ProductCode AS codigo,
        p.ProductName AS descripcion,
        img.PublicUrl AS imagen,
        p.UnitCode    AS unidad,
        p.StockQty    AS existencia
    FROM [master].Product p
    OUTER APPLY (
        SELECT TOP 1 ma.PublicUrl
        FROM cfg.EntityImage ei
        INNER JOIN cfg.MediaAsset ma ON ma.MediaAssetId = ei.MediaAssetId
        WHERE ei.CompanyId = p.CompanyId
          AND ei.BranchId = @BranchId
          AND ei.EntityType = N'MASTER_PRODUCT'
          AND ei.EntityId = p.ProductId
          AND ei.IsDeleted = 0 AND ei.IsActive = 1
          AND ma.IsDeleted = 0 AND ma.IsActive = 1
        ORDER BY CASE WHEN ei.IsPrimary = 1 THEN 0 ELSE 1 END, ei.SortOrder, ei.EntityImageId
    ) img
    WHERE p.CompanyId = @CompanyId
      AND p.IsDeleted = 0
      AND p.IsActive = 1
      AND (
          @Search IS NULL
          OR p.ProductCode LIKE @Search
          OR p.ProductName LIKE @Search
      )
    ORDER BY p.ProductCode;
END;
GO

PRINT N'SPs administrativos restaurante (tablas canonicas) creados exitosamente.';
GO
