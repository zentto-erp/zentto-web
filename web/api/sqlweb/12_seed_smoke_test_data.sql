SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
  BEGIN TRAN;

  DECLARE @CompanyId INT = (
    SELECT TOP 1 CompanyId
    FROM cfg.Company
    WHERE CompanyCode = N'DEFAULT'
    ORDER BY CompanyId
  );

  DECLARE @BranchId INT = (
    SELECT TOP 1 BranchId
    FROM cfg.Branch
    WHERE CompanyId = @CompanyId
      AND BranchCode = N'MAIN'
    ORDER BY BranchId
  );

  DECLARE @CountryCode CHAR(2) = (
    SELECT TOP 1 UPPER(FiscalCountryCode)
    FROM cfg.Company
    WHERE CompanyId = @CompanyId
  );

  DECLARE @SystemUserId INT = (
    SELECT TOP 1 UserId
    FROM sec.[User]
    WHERE UserCode = N'SYSTEM'
    ORDER BY UserId
  );

  IF @CompanyId IS NULL OR @BranchId IS NULL
    RAISERROR('Falta company/branch DEFAULT-MAIN.',16,1);

  DECLARE @DefaultTaxCode NVARCHAR(30) = (
    SELECT TOP 1 TaxCode
    FROM fiscal.TaxRate
    WHERE CountryCode = @CountryCode
      AND IsActive = 1
      AND IsDefault = 1
    ORDER BY SortOrder, TaxRateId
  );

  DECLARE @DefaultTaxRate DECIMAL(9,4) = (
    SELECT TOP 1 Rate
    FROM fiscal.TaxRate
    WHERE CountryCode = @CountryCode
      AND IsActive = 1
      AND TaxCode = @DefaultTaxCode
  );

  IF @DefaultTaxCode IS NULL SET @DefaultTaxCode = N'IVA_GENERAL';
  IF @DefaultTaxRate IS NULL SET @DefaultTaxRate = 0.16;

  DECLARE @DefaultTaxPercent DECIMAL(9,2) = CASE WHEN @DefaultTaxRate <= 1 THEN @DefaultTaxRate * 100 ELSE @DefaultTaxRate END;

  /* Usuarios operativos */
  IF NOT EXISTS (
    SELECT 1 FROM sec.[User]
    WHERE UserCode = N'OPERADOR'
      AND IsDeleted = 0
  )
  BEGIN
    INSERT INTO sec.[User] (
      UserCode,
      UserName,
      Email,
      IsAdmin,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId
    )
    VALUES (
      N'OPERADOR',
      N'Operador Restaurante',
      N'operador@datqbox.local',
      0,
      1,
      @SystemUserId,
      @SystemUserId
    );
  END;

  /* Maestro proveedor */
  IF NOT EXISTS (
    SELECT 1
    FROM [master].Supplier
    WHERE CompanyId = @CompanyId
      AND SupplierCode = N'SUP-REST-01'
      AND IsDeleted = 0
  )
  BEGIN
    INSERT INTO [master].Supplier (
      CompanyId,
      SupplierCode,
      SupplierName,
      FiscalId,
      Email,
      Phone,
      AddressLine,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId
    )
    VALUES (
      @CompanyId,
      N'SUP-REST-01',
      N'Proveedor Restaurante Demo',
      N'J-00000000-1',
      N'compras@proveedor-demo.local',
      N'0212-5550101',
      N'Zona Industrial Demo',
      1,
      @SystemUserId,
      @SystemUserId
    );
  END;

  /* Maestro cliente */
  IF NOT EXISTS (
    SELECT 1
    FROM [master].Customer
    WHERE CompanyId = @CompanyId
      AND CustomerCode = N'CLI-DEMO-01'
      AND IsDeleted = 0
  )
  BEGIN
    INSERT INTO [master].Customer (
      CompanyId,
      CustomerCode,
      CustomerName,
      FiscalId,
      Email,
      Phone,
      AddressLine,
      CreditLimit,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId
    )
    VALUES (
      @CompanyId,
      N'CLI-DEMO-01',
      N'Cliente Mostrador Demo',
      N'V-00000000',
      N'cliente.demo@datqbox.local',
      N'0414-0000001',
      N'Sector Centro',
      500,
      1,
      @SystemUserId,
      @SystemUserId
    );
  END;

  /* Maestro productos (insumos + venta) */
  IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'INS-CARNE-RES' AND IsDeleted = 0)
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, N'INS-CARNE-RES', N'Insumo Carne de Res (kg)', N'INSUMO', N'KG', 0, 8.50, @DefaultTaxCode, @DefaultTaxRate, 120, 0, 1, @SystemUserId, @SystemUserId);

  IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'INS-PAN-HAMB' AND IsDeleted = 0)
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, N'INS-PAN-HAMB', N'Insumo Pan de Hamburguesa', N'INSUMO', N'UND', 0, 0.35, @DefaultTaxCode, @DefaultTaxRate, 500, 0, 1, @SystemUserId, @SystemUserId);

  IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'INS-QUESO-CHD' AND IsDeleted = 0)
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, N'INS-QUESO-CHD', N'Insumo Queso Cheddar (kg)', N'INSUMO', N'KG', 0, 6.25, @DefaultTaxCode, @DefaultTaxRate, 40, 0, 1, @SystemUserId, @SystemUserId);

  IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'INS-REF-COLA' AND IsDeleted = 0)
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, N'INS-REF-COLA', N'Insumo Refresco Cola 355ml', N'INSUMO', N'UND', 0, 0.60, @DefaultTaxCode, @DefaultTaxRate, 300, 0, 1, @SystemUserId, @SystemUserId);

  IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'MNU-HAMB-CLA' AND IsDeleted = 0)
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, N'MNU-HAMB-CLA', N'Hamburguesa Clasica', N'MENU', N'UND', 9.50, 4.10, @DefaultTaxCode, @DefaultTaxRate, 200, 0, 1, @SystemUserId, @SystemUserId);

  IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'MNU-COLA-355' AND IsDeleted = 0)
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, N'MNU-COLA-355', N'Refresco Cola 355ml', N'MENU', N'UND', 2.50, 0.90, @DefaultTaxCode, @DefaultTaxRate, 250, 0, 1, @SystemUserId, @SystemUserId);

  /* Ambientes */
  IF EXISTS (
    SELECT 1
    FROM rest.MenuEnvironment
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND EnvironmentCode = N'SALON'
  )
  BEGIN
    UPDATE rest.MenuEnvironment
    SET EnvironmentName = N'Salon Principal',
        ColorHex = N'#0EA5E9',
        SortOrder = 10,
        UpdatedAt = SYSUTCDATETIME(),
        UpdatedByUserId = @SystemUserId
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND EnvironmentCode = N'SALON';
  END
  ELSE
  BEGIN
    INSERT INTO rest.MenuEnvironment (CompanyId, BranchId, EnvironmentCode, EnvironmentName, ColorHex, SortOrder, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, @BranchId, N'SALON', N'Salon Principal', N'#0EA5E9', 10, 1, @SystemUserId, @SystemUserId);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM rest.MenuEnvironment
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND EnvironmentCode = N'TERRAZA'
  )
  BEGIN
    INSERT INTO rest.MenuEnvironment (CompanyId, BranchId, EnvironmentCode, EnvironmentName, ColorHex, SortOrder, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, @BranchId, N'TERRAZA', N'Terraza', N'#22C55E', 20, 1, @SystemUserId, @SystemUserId);
  END;

  /* Categorias menu */
  IF NOT EXISTS (
    SELECT 1
    FROM rest.MenuCategory
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND CategoryCode = N'HAMBURGUESAS'
  )
  BEGIN
    INSERT INTO rest.MenuCategory (CompanyId, BranchId, CategoryCode, CategoryName, DescriptionText, ColorHex, SortOrder, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, @BranchId, N'HAMBURGUESAS', N'Hamburguesas', N'Linea de hamburguesas', N'#EF4444', 10, 1, @SystemUserId, @SystemUserId);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM rest.MenuCategory
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND CategoryCode = N'BEBIDAS'
  )
  BEGIN
    INSERT INTO rest.MenuCategory (CompanyId, BranchId, CategoryCode, CategoryName, DescriptionText, ColorHex, SortOrder, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, @BranchId, N'BEBIDAS', N'Bebidas', N'Bebidas frias', N'#3B82F6', 20, 1, @SystemUserId, @SystemUserId);
  END;

  DECLARE @CatHamb BIGINT = (
    SELECT TOP 1 MenuCategoryId
    FROM rest.MenuCategory
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND CategoryCode = N'HAMBURGUESAS'
  );

  DECLARE @CatBeb BIGINT = (
    SELECT TOP 1 MenuCategoryId
    FROM rest.MenuCategory
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND CategoryCode = N'BEBIDAS'
  );

  DECLARE @InvHamb BIGINT = (
    SELECT TOP 1 ProductId
    FROM [master].Product
    WHERE CompanyId = @CompanyId
      AND ProductCode = N'MNU-HAMB-CLA'
      AND IsDeleted = 0
  );

  DECLARE @InvCola BIGINT = (
    SELECT TOP 1 ProductId
    FROM [master].Product
    WHERE CompanyId = @CompanyId
      AND ProductCode = N'MNU-COLA-355'
      AND IsDeleted = 0
  );

  /* Productos menu */
  IF NOT EXISTS (
    SELECT 1
    FROM rest.MenuProduct
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND ProductCode = N'HAMB-CLASICA'
  )
  BEGIN
    INSERT INTO rest.MenuProduct (
      CompanyId, BranchId, ProductCode, ProductName, DescriptionText, MenuCategoryId,
      PriceAmount, EstimatedCost, TaxRatePercent, IsComposite, PrepMinutes,
      IsDailySuggestion, IsAvailable, InventoryProductId, IsActive, CreatedByUserId, UpdatedByUserId
    )
    VALUES (
      @CompanyId, @BranchId, N'HAMB-CLASICA', N'Hamburguesa Clasica', N'Carne, pan y queso', @CatHamb,
      9.50, 4.10, @DefaultTaxPercent, 1, 12,
      1, 1, @InvHamb, 1, @SystemUserId, @SystemUserId
    );
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM rest.MenuProduct
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND ProductCode = N'COLA-355'
  )
  BEGIN
    INSERT INTO rest.MenuProduct (
      CompanyId, BranchId, ProductCode, ProductName, DescriptionText, MenuCategoryId,
      PriceAmount, EstimatedCost, TaxRatePercent, IsComposite, PrepMinutes,
      IsDailySuggestion, IsAvailable, InventoryProductId, IsActive, CreatedByUserId, UpdatedByUserId
    )
    VALUES (
      @CompanyId, @BranchId, N'COLA-355', N'Refresco Cola 355ml', N'Lata fria', @CatBeb,
      2.50, 0.90, @DefaultTaxPercent, 0, 1,
      0, 1, @InvCola, 1, @SystemUserId, @SystemUserId
    );
  END;

  DECLARE @MenuHamb BIGINT = (
    SELECT TOP 1 MenuProductId
    FROM rest.MenuProduct
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND ProductCode = N'HAMB-CLASICA'
  );

  /* Componentes y opciones */
  IF @MenuHamb IS NOT NULL
  BEGIN
    IF NOT EXISTS (
      SELECT 1
      FROM rest.MenuComponent
      WHERE MenuProductId = @MenuHamb
        AND ComponentName = N'Tipo de Queso'
    )
    BEGIN
      INSERT INTO rest.MenuComponent (MenuProductId, ComponentName, IsRequired, SortOrder, IsActive)
      VALUES (@MenuHamb, N'Tipo de Queso', 0, 10, 1);
    END;

    DECLARE @CompQueso BIGINT = (
      SELECT TOP 1 MenuComponentId
      FROM rest.MenuComponent
      WHERE MenuProductId = @MenuHamb
        AND ComponentName = N'Tipo de Queso'
      ORDER BY MenuComponentId
    );

    IF @CompQueso IS NOT NULL
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM rest.MenuOption WHERE MenuComponentId = @CompQueso AND OptionName = N'Sin queso')
        INSERT INTO rest.MenuOption (MenuComponentId, OptionName, ExtraPrice, SortOrder, IsActive) VALUES (@CompQueso, N'Sin queso', 0, 10, 1);

      IF NOT EXISTS (SELECT 1 FROM rest.MenuOption WHERE MenuComponentId = @CompQueso AND OptionName = N'Con cheddar')
        INSERT INTO rest.MenuOption (MenuComponentId, OptionName, ExtraPrice, SortOrder, IsActive) VALUES (@CompQueso, N'Con cheddar', 1.50, 20, 1);
    END;
  END;

  /* Receta */
  DECLARE @IngCarne BIGINT = (SELECT TOP 1 ProductId FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'INS-CARNE-RES' AND IsDeleted = 0);
  DECLARE @IngPan BIGINT = (SELECT TOP 1 ProductId FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'INS-PAN-HAMB' AND IsDeleted = 0);
  DECLARE @IngQueso BIGINT = (SELECT TOP 1 ProductId FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'INS-QUESO-CHD' AND IsDeleted = 0);

  IF @MenuHamb IS NOT NULL AND @IngCarne IS NOT NULL AND NOT EXISTS (SELECT 1 FROM rest.MenuRecipe WHERE MenuProductId = @MenuHamb AND IngredientProductId = @IngCarne AND IsActive = 1)
    INSERT INTO rest.MenuRecipe (MenuProductId, IngredientProductId, Quantity, UnitCode, Notes, IsActive) VALUES (@MenuHamb, @IngCarne, 0.18, N'KG', N'Carne por unidad', 1);

  IF @MenuHamb IS NOT NULL AND @IngPan IS NOT NULL AND NOT EXISTS (SELECT 1 FROM rest.MenuRecipe WHERE MenuProductId = @MenuHamb AND IngredientProductId = @IngPan AND IsActive = 1)
    INSERT INTO rest.MenuRecipe (MenuProductId, IngredientProductId, Quantity, UnitCode, Notes, IsActive) VALUES (@MenuHamb, @IngPan, 1.00, N'UND', N'Pan por unidad', 1);

  IF @MenuHamb IS NOT NULL AND @IngQueso IS NOT NULL AND NOT EXISTS (SELECT 1 FROM rest.MenuRecipe WHERE MenuProductId = @MenuHamb AND IngredientProductId = @IngQueso AND IsActive = 1)
    INSERT INTO rest.MenuRecipe (MenuProductId, IngredientProductId, Quantity, UnitCode, Notes, IsActive) VALUES (@MenuHamb, @IngQueso, 0.03, N'KG', N'Queso por unidad', 1);

  /* Mesas adicionales en terraza */
  IF NOT EXISTS (SELECT 1 FROM rest.DiningTable WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND TableNumber = N'21')
    INSERT INTO rest.DiningTable (CompanyId, BranchId, TableNumber, TableName, Capacity, EnvironmentCode, EnvironmentName, PositionX, PositionY, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, @BranchId, N'21', N'Mesa Terraza 21', 4, N'TERRAZA', N'Terraza', 10, 5, 1, @SystemUserId, @SystemUserId);

  IF NOT EXISTS (SELECT 1 FROM rest.DiningTable WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND TableNumber = N'22')
    INSERT INTO rest.DiningTable (CompanyId, BranchId, TableNumber, TableName, Capacity, EnvironmentCode, EnvironmentName, PositionX, PositionY, IsActive, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, @BranchId, N'22', N'Mesa Terraza 22', 2, N'TERRAZA', N'Terraza', 12, 5, 1, @SystemUserId, @SystemUserId);

  /* Compra de prueba */
  DECLARE @SupplierId BIGINT = (
    SELECT TOP 1 SupplierId
    FROM [master].Supplier
    WHERE CompanyId = @CompanyId
      AND SupplierCode = N'SUP-REST-01'
      AND IsDeleted = 0
  );

  DECLARE @CompraId BIGINT = (
    SELECT TOP 1 PurchaseId
    FROM rest.Purchase
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND PurchaseNumber = N'RC-SEED-0001'
  );

  IF @CompraId IS NULL
  BEGIN
    INSERT INTO rest.Purchase (CompanyId, BranchId, PurchaseNumber, SupplierId, PurchaseDate, Status, Notes, CreatedByUserId, UpdatedByUserId)
    VALUES (@CompanyId, @BranchId, N'RC-SEED-0001', @SupplierId, SYSUTCDATETIME(), N'PENDIENTE', N'Compra seed para pruebas', @SystemUserId, @SystemUserId);

    SET @CompraId = SCOPE_IDENTITY();
  END;

  IF @CompraId IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM rest.PurchaseLine WHERE PurchaseId = @CompraId AND DescriptionText = N'Carne de res fresca')
      INSERT INTO rest.PurchaseLine (PurchaseId, IngredientProductId, DescriptionText, Quantity, UnitPrice, TaxRatePercent, SubtotalAmount)
      VALUES (@CompraId, @IngCarne, N'Carne de res fresca', 8.00, 8.50, @DefaultTaxPercent, 68.00);

    IF NOT EXISTS (SELECT 1 FROM rest.PurchaseLine WHERE PurchaseId = @CompraId AND DescriptionText = N'Pan hamburguesa')
      INSERT INTO rest.PurchaseLine (PurchaseId, IngredientProductId, DescriptionText, Quantity, UnitPrice, TaxRatePercent, SubtotalAmount)
      VALUES (@CompraId, @IngPan, N'Pan hamburguesa', 120.00, 0.35, @DefaultTaxPercent, 42.00);

    UPDATE p
    SET
      SubtotalAmount = x.subtotal,
      TaxAmount = x.tax,
      TotalAmount = x.total,
      UpdatedAt = SYSUTCDATETIME()
    FROM rest.Purchase p
    CROSS APPLY (
      SELECT
        COALESCE(SUM(SubtotalAmount), 0) AS subtotal,
        COALESCE(SUM(SubtotalAmount * TaxRatePercent / 100.0), 0) AS tax,
        COALESCE(SUM(SubtotalAmount + (SubtotalAmount * TaxRatePercent / 100.0)), 0) AS total
      FROM rest.PurchaseLine
      WHERE PurchaseId = @CompraId
    ) x
    WHERE p.PurchaseId = @CompraId;
  END;

  /* Pedido abierto de prueba (mesa 1) */
  DECLARE @Mesa1 NVARCHAR(20) = (
    SELECT TOP 1 TableNumber
    FROM rest.DiningTable
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND TableNumber = N'1'
  );

  DECLARE @PedidoId BIGINT = (
    SELECT TOP 1 OrderTicketId
    FROM rest.OrderTicket
    WHERE CompanyId = @CompanyId
      AND BranchId = @BranchId
      AND TableNumber = @Mesa1
      AND Status IN (N'OPEN', N'SENT')
    ORDER BY OrderTicketId DESC
  );

  IF @PedidoId IS NULL AND @Mesa1 IS NOT NULL
  BEGIN
    INSERT INTO rest.OrderTicket (CompanyId, BranchId, CountryCode, TableNumber, OpenedByUserId, CustomerName, CustomerFiscalId, Status, NetAmount, TaxAmount, TotalAmount, OpenedAt)
    VALUES (@CompanyId, @BranchId, @CountryCode, @Mesa1, @SystemUserId, N'Cliente Mostrador Demo', N'V-00000000', N'OPEN', 0, 0, 0, SYSUTCDATETIME());

    SET @PedidoId = SCOPE_IDENTITY();
  END;

  IF @PedidoId IS NOT NULL
  BEGIN
    DECLARE @TaxCodeLine NVARCHAR(30) = @DefaultTaxCode;
    DECLARE @TaxRateLine DECIMAL(9,4) = @DefaultTaxRate;

    IF NOT EXISTS (SELECT 1 FROM rest.OrderTicketLine WHERE OrderTicketId = @PedidoId)
    BEGIN
      INSERT INTO rest.OrderTicketLine (
        OrderTicketId, LineNumber, CountryCode, ProductId, ProductCode, ProductName,
        Quantity, UnitPrice, TaxCode, TaxRate, NetAmount, TaxAmount, TotalAmount, Notes
      )
      VALUES (
        @PedidoId, 1, @CountryCode, @InvHamb, N'HAMB-CLASICA', N'Hamburguesa Clasica',
        2, 9.50, @TaxCodeLine, @TaxRateLine, 19.00, ROUND(19.00 * @TaxRateLine, 2), ROUND(19.00 * (1 + @TaxRateLine), 2), N'Seed'
      );

      INSERT INTO rest.OrderTicketLine (
        OrderTicketId, LineNumber, CountryCode, ProductId, ProductCode, ProductName,
        Quantity, UnitPrice, TaxCode, TaxRate, NetAmount, TaxAmount, TotalAmount, Notes
      )
      VALUES (
        @PedidoId, 2, @CountryCode, @InvCola, N'COLA-355', N'Refresco Cola 355ml',
        2, 2.50, @TaxCodeLine, @TaxRateLine, 5.00, ROUND(5.00 * @TaxRateLine, 2), ROUND(5.00 * (1 + @TaxRateLine), 2), N'Seed'
      );
    END;

    UPDATE o
    SET
      NetAmount = x.netAmount,
      TaxAmount = x.taxAmount,
      TotalAmount = x.totalAmount
    FROM rest.OrderTicket o
    CROSS APPLY (
      SELECT
        COALESCE(SUM(NetAmount), 0) AS netAmount,
        COALESCE(SUM(TaxAmount), 0) AS taxAmount,
        COALESCE(SUM(TotalAmount), 0) AS totalAmount
      FROM rest.OrderTicketLine
      WHERE OrderTicketId = @PedidoId
    ) x
    WHERE o.OrderTicketId = @PedidoId;
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error 12_seed_smoke_test_data.sql: %s', 16, 1, @Err);
END CATCH;
GO
