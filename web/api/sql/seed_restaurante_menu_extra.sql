SET NOCOUNT ON;

BEGIN TRY
  BEGIN TRAN;

  DECLARE @CompanyId INT = (
    SELECT TOP (1) CompanyId
    FROM cfg.Company
    WHERE CompanyCode = N'DEFAULT'
    ORDER BY CompanyId
  );

  IF @CompanyId IS NULL
    SET @CompanyId = 1;

  DECLARE @BranchId INT = (
    SELECT TOP (1) BranchId
    FROM cfg.Branch
    WHERE CompanyId = @CompanyId
      AND BranchCode = N'MAIN'
    ORDER BY BranchId
  );

  IF @BranchId IS NULL
    SET @BranchId = (
      SELECT TOP (1) BranchId
      FROM cfg.Branch
      WHERE CompanyId = @CompanyId
      ORDER BY BranchId
    );

  DECLARE @UserId INT = (
    SELECT TOP (1) UserId
    FROM sec.[User]
    WHERE IsActive = 1
      AND IsDeleted = 0
      AND UPPER(UserCode) IN (N'SYSTEM', N'SUP')
    ORDER BY CASE WHEN UPPER(UserCode) = N'SYSTEM' THEN 0 ELSE 1 END, UserId
  );

  DECLARE @Categorias TABLE (
    CategoryCode NVARCHAR(30) NOT NULL,
    CategoryName NVARCHAR(120) NOT NULL,
    DescriptionText NVARCHAR(300) NULL,
    ColorHex NVARCHAR(20) NULL,
    SortOrder INT NOT NULL
  );

  INSERT INTO @Categorias (CategoryCode, CategoryName, DescriptionText, ColorHex, SortOrder)
  VALUES
    (N'ENTRADAS', N'Entradas', N'Entradas y para compartir', N'#F59E0B', 5),
    (N'PIZZAS', N'Pizzas', N'Pizzas artesanales', N'#EF4444', 15),
    (N'PASTAS', N'Pastas', N'Pastas y salsas de la casa', N'#FB7185', 18),
    (N'POSTRES', N'Postres', N'Postres y dulces', N'#8B5CF6', 25),
    (N'CAFETERIA', N'Cafeteria', N'Cafes e infusiones', N'#A16207', 30),
    (N'COCTELES', N'Cocteles', N'Cocteleria clasica', N'#06B6D4', 35),
    (N'COMBOS', N'Combos', N'Promociones y menus combo', N'#22C55E', 40);

  MERGE rest.MenuCategory AS tgt
  USING @Categorias AS src
    ON tgt.CompanyId = @CompanyId
   AND tgt.BranchId = @BranchId
   AND UPPER(tgt.CategoryCode) = UPPER(src.CategoryCode)
  WHEN MATCHED THEN
    UPDATE SET
      CategoryName = src.CategoryName,
      DescriptionText = src.DescriptionText,
      ColorHex = src.ColorHex,
      SortOrder = src.SortOrder,
      IsActive = 1,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @UserId
  WHEN NOT MATCHED THEN
    INSERT (
      CompanyId,
      BranchId,
      CategoryCode,
      CategoryName,
      DescriptionText,
      ColorHex,
      SortOrder,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId
    )
    VALUES (
      @CompanyId,
      @BranchId,
      src.CategoryCode,
      src.CategoryName,
      src.DescriptionText,
      src.ColorHex,
      src.SortOrder,
      1,
      @UserId,
      @UserId
    );

  DECLARE @Productos TABLE (
    ProductCode NVARCHAR(80) NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    DescriptionText NVARCHAR(500) NULL,
    CategoryCode NVARCHAR(30) NOT NULL,
    PriceAmount DECIMAL(18,2) NOT NULL,
    EstimatedCost DECIMAL(18,2) NOT NULL,
    TaxRatePercent DECIMAL(9,4) NOT NULL,
    PrepMinutes INT NOT NULL,
    IsDailySuggestion BIT NOT NULL
  );

  INSERT INTO @Productos (
    ProductCode,
    ProductName,
    DescriptionText,
    CategoryCode,
    PriceAmount,
    EstimatedCost,
    TaxRatePercent,
    PrepMinutes,
    IsDailySuggestion
  )
  VALUES
    (N'PAPAS-RUSTICAS', N'Papas Rusticas', N'Papas crujientes con salsa de ajo', N'ENTRADAS', 4.50, 1.80, 16.0000, 8, 0),
    (N'TEQUENOS-QUESO', N'Tequenos de Queso', N'Seis tequenos con salsa tartara', N'ENTRADAS', 5.90, 2.30, 16.0000, 10, 0),
    (N'ALITAS-BBQ', N'Alitas BBQ', N'Ocho alitas glaseadas estilo BBQ', N'ENTRADAS', 8.50, 3.20, 16.0000, 12, 0),

    (N'PIZZA-MARGHERITA', N'Pizza Margherita', N'Salsa de tomate, mozzarella y albahaca', N'PIZZAS', 11.00, 4.30, 16.0000, 15, 0),
    (N'PIZZA-PEPPERONI', N'Pizza Pepperoni', N'Pizza artesanal con pepperoni premium', N'PIZZAS', 12.50, 4.90, 16.0000, 15, 1),

    (N'PASTA-ALFREDO', N'Pasta Alfredo', N'Fettuccine en salsa alfredo', N'PASTAS', 10.75, 4.20, 16.0000, 14, 0),
    (N'PASTA-BOLO', N'Pasta Bolognesa', N'Spaghetti con salsa bolognesa de la casa', N'PASTAS', 11.25, 4.40, 16.0000, 14, 0),

    (N'CHEESECAKE-FRESA', N'Cheesecake de Fresa', N'Porcion individual', N'POSTRES', 4.80, 1.60, 16.0000, 3, 0),
    (N'BROWNIE-HELADO', N'Brownie con Helado', N'Brownie tibio con helado de vainilla', N'POSTRES', 5.50, 1.90, 16.0000, 5, 1),

    (N'CAFE-ESPRESSO', N'Café Espresso', N'Taza de espresso doble', N'CAFETERIA', 1.80, 0.60, 16.0000, 2, 0),
    (N'CAPPUCCINO', N'Cappuccino', N'Cappuccino con espuma de leche', N'CAFETERIA', 2.90, 1.00, 16.0000, 3, 0),

    (N'MOJITO-CLASICO', N'Mojito Clasico', N'Ron blanco, hierbabuena y limon', N'COCTELES', 6.80, 2.40, 16.0000, 4, 0),
    (N'GIN-TONIC', N'Gin Tonic', N'Gin premium con agua tonica', N'COCTELES', 7.50, 2.70, 16.0000, 4, 0),

    (N'HAMB-DOBLE-QUESO', N'Hamburguesa Doble Queso', N'Doble carne, doble queso cheddar', N'HAMBURGUESAS', 12.00, 4.80, 16.0000, 12, 1),
    (N'HAMB-POLLO-CRISPY', N'Hamburguesa Pollo Crispy', N'Pechuga crispy con salsa especial', N'HAMBURGUESAS', 10.90, 4.10, 16.0000, 12, 0),

    (N'LIMONADA-HIERBABUENA', N'Limonada Hierbabuena', N'Limonada natural con menta', N'BEBIDAS', 3.20, 1.00, 16.0000, 2, 0),
    (N'JUGO-NARANJA', N'Jugo de Naranja', N'Jugo natural recien exprimido', N'BEBIDAS', 2.80, 0.90, 16.0000, 2, 0),

    (N'COMBO-ALMUERZO', N'Combo Almuerzo', N'Plato principal + bebida + postre', N'COMBOS', 13.90, 5.20, 16.0000, 10, 1),
    (N'PROMO-PAREJA', N'Promo Pareja', N'Dos platos fuertes y una entrada', N'COMBOS', 24.90, 9.20, 16.0000, 12, 1);

  ;WITH ProductSource AS (
    SELECT
      p.ProductCode,
      p.ProductName,
      p.DescriptionText,
      c.MenuCategoryId,
      p.PriceAmount,
      p.EstimatedCost,
      p.TaxRatePercent,
      p.PrepMinutes,
      p.IsDailySuggestion
    FROM @Productos p
    LEFT JOIN rest.MenuCategory c
      ON c.CompanyId = @CompanyId
     AND c.BranchId = @BranchId
     AND UPPER(c.CategoryCode) = UPPER(p.CategoryCode)
  )
  MERGE rest.MenuProduct AS tgt
  USING ProductSource AS src
    ON tgt.CompanyId = @CompanyId
   AND tgt.BranchId = @BranchId
   AND UPPER(tgt.ProductCode) = UPPER(src.ProductCode)
  WHEN MATCHED THEN
    UPDATE SET
      ProductName = src.ProductName,
      DescriptionText = src.DescriptionText,
      MenuCategoryId = COALESCE(src.MenuCategoryId, tgt.MenuCategoryId),
      PriceAmount = src.PriceAmount,
      EstimatedCost = src.EstimatedCost,
      TaxRatePercent = src.TaxRatePercent,
      IsComposite = 0,
      PrepMinutes = src.PrepMinutes,
      ImageUrl = NULL,
      IsDailySuggestion = src.IsDailySuggestion,
      IsAvailable = 1,
      IsActive = 1,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @UserId
  WHEN NOT MATCHED THEN
    INSERT (
      CompanyId,
      BranchId,
      ProductCode,
      ProductName,
      DescriptionText,
      MenuCategoryId,
      PriceAmount,
      EstimatedCost,
      TaxRatePercent,
      IsComposite,
      PrepMinutes,
      ImageUrl,
      IsDailySuggestion,
      IsAvailable,
      InventoryProductId,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId
    )
    VALUES (
      @CompanyId,
      @BranchId,
      src.ProductCode,
      src.ProductName,
      src.DescriptionText,
      src.MenuCategoryId,
      src.PriceAmount,
      src.EstimatedCost,
      src.TaxRatePercent,
      0,
      src.PrepMinutes,
      NULL,
      src.IsDailySuggestion,
      1,
      NULL,
      1,
      @UserId,
      @UserId
    );

  COMMIT TRAN;

  SELECT COUNT(*) AS categorias_activas
  FROM rest.MenuCategory
  WHERE CompanyId = @CompanyId
    AND BranchId = @BranchId
    AND IsActive = 1;

  SELECT COUNT(*) AS productos_activos
  FROM rest.MenuProduct
  WHERE CompanyId = @CompanyId
    AND BranchId = @BranchId
    AND IsActive = 1
    AND IsAvailable = 1;

END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0
    ROLLBACK TRAN;

  THROW;
END CATCH;
