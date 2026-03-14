SET NOCOUNT ON;

BEGIN TRY
  BEGIN TRAN;

  DECLARE @CompanyId INT = (
    SELECT TOP (1) CompanyId
    FROM cfg.Company
    WHERE CompanyCode = N'DEFAULT'
    ORDER BY CompanyId
  );

  IF @CompanyId IS NULL SET @CompanyId = 1;

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

  -- 1) Seed de insumos base para recetas
  DECLARE @Insumos TABLE (
    ProductCode NVARCHAR(80) NOT NULL,
    ProductName NVARCHAR(300) NOT NULL,
    UnitCode NVARCHAR(20) NOT NULL,
    CostPrice DECIMAL(18,2) NOT NULL
  );

  INSERT INTO @Insumos (ProductCode, ProductName, UnitCode, CostPrice)
  VALUES
    (N'INS-CARNE-RES', N'Insumo Carne de Res (kg)', N'KG', 5.20),
    (N'INS-PAN-HAMB', N'Insumo Pan de Hamburguesa', N'UND', 0.35),
    (N'INS-QUESO-CHD', N'Insumo Queso Cheddar (kg)', N'KG', 6.10),
    (N'INS-POLLO-FILET', N'Insumo Filete de Pollo (kg)', N'KG', 4.80),
    (N'INS-PAPA-FRITA', N'Insumo Papa para Freir (kg)', N'KG', 1.50),
    (N'INS-MASA-PIZZA', N'Insumo Masa de Pizza', N'UND', 1.10),
    (N'INS-SALSA-TOMATE', N'Insumo Salsa de Tomate (kg)', N'KG', 1.90),
    (N'INS-MOZZARELLA', N'Insumo Queso Mozzarella (kg)', N'KG', 6.80),
    (N'INS-PEPPERONI', N'Insumo Pepperoni (kg)', N'KG', 7.50),
    (N'INS-BEBIDA-VASO', N'Insumo Bebida Vaso', N'UND', 0.65);

  MERGE [master].Product AS tgt
  USING @Insumos AS src
    ON tgt.CompanyId = @CompanyId
   AND UPPER(tgt.ProductCode) = UPPER(src.ProductCode)
  WHEN MATCHED THEN
    UPDATE SET
      ProductName = src.ProductName,
      CategoryCode = N'INSUMOS',
      UnitCode = src.UnitCode,
      CostPrice = src.CostPrice,
      SalesPrice = CASE WHEN tgt.SalesPrice IS NULL OR tgt.SalesPrice < src.CostPrice THEN src.CostPrice ELSE tgt.SalesPrice END,
      DefaultTaxCode = ISNULL(tgt.DefaultTaxCode, N'EXENTO'),
      DefaultTaxRate = ISNULL(tgt.DefaultTaxRate, 0),
      IsService = 0,
      IsActive = 1,
      IsDeleted = 0,
      DeletedAt = NULL,
      DeletedByUserId = NULL,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedByUserId = @UserId
  WHEN NOT MATCHED THEN
    INSERT (
      CompanyId,
      ProductCode,
      ProductName,
      CategoryCode,
      UnitCode,
      SalesPrice,
      CostPrice,
      DefaultTaxCode,
      DefaultTaxRate,
      StockQty,
      IsService,
      IsActive,
      CreatedByUserId,
      UpdatedByUserId,
      IsDeleted
    )
    VALUES (
      @CompanyId,
      src.ProductCode,
      src.ProductName,
      N'INSUMOS',
      src.UnitCode,
      src.CostPrice,
      src.CostPrice,
      N'EXENTO',
      0,
      0,
      0,
      1,
      @UserId,
      @UserId,
      0
    );

  -- 2) Marcar productos compuestos
  UPDATE mp
  SET
    IsComposite = 1,
    UpdatedAt = SYSUTCDATETIME(),
    UpdatedByUserId = @UserId
  FROM rest.MenuProduct mp
  WHERE mp.CompanyId = @CompanyId
    AND mp.BranchId = @BranchId
    AND mp.IsActive = 1
    AND UPPER(mp.ProductCode) IN (
      N'HAMB-CLASICA',
      N'HAMB-DOBLE-QUESO',
      N'HAMB-POLLO-CRISPY',
      N'PIZZA-PEPPERONI',
      N'COMBO-ALMUERZO',
      N'PROMO-PAREJA'
    );

  -- 3) Componentes
  DECLARE @Componentes TABLE (
    ProductCode NVARCHAR(80) NOT NULL,
    ComponentName NVARCHAR(120) NOT NULL,
    IsRequired BIT NOT NULL,
    SortOrder INT NOT NULL
  );

  INSERT INTO @Componentes (ProductCode, ComponentName, IsRequired, SortOrder)
  VALUES
    (N'HAMB-CLASICA', N'Tipo de Queso', 0, 10),
    (N'HAMB-CLASICA', N'Punto de coccion', 1, 20),
    (N'HAMB-CLASICA', N'Extras', 0, 30),

    (N'HAMB-DOBLE-QUESO', N'Punto de coccion', 1, 10),
    (N'HAMB-DOBLE-QUESO', N'Acompanante', 1, 20),
    (N'HAMB-DOBLE-QUESO', N'Extras', 0, 30),

    (N'HAMB-POLLO-CRISPY', N'Salsa de la casa', 0, 10),
    (N'HAMB-POLLO-CRISPY', N'Acompanante', 1, 20),

    (N'PIZZA-PEPPERONI', N'Tamano', 1, 10),
    (N'PIZZA-PEPPERONI', N'Tipo de masa', 1, 20),

    (N'COMBO-ALMUERZO', N'Bebida incluida', 1, 10),
    (N'COMBO-ALMUERZO', N'Postre incluido', 0, 20),

    (N'PROMO-PAREJA', N'Bebidas', 1, 10),
    (N'PROMO-PAREJA', N'Entrada compartida', 0, 20);

  ;WITH SourceComp AS (
    SELECT
      p.MenuProductId,
      c.ComponentName,
      c.IsRequired,
      c.SortOrder
    FROM @Componentes c
    INNER JOIN rest.MenuProduct p
      ON p.CompanyId = @CompanyId
     AND p.BranchId = @BranchId
     AND p.IsActive = 1
     AND UPPER(p.ProductCode) = UPPER(c.ProductCode)
  )
  MERGE rest.MenuComponent AS tgt
  USING SourceComp AS src
    ON tgt.MenuProductId = src.MenuProductId
   AND UPPER(tgt.ComponentName) = UPPER(src.ComponentName)
  WHEN MATCHED THEN
    UPDATE SET
      IsRequired = src.IsRequired,
      SortOrder = src.SortOrder,
      IsActive = 1,
      UpdatedAt = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (
      MenuProductId,
      ComponentName,
      IsRequired,
      SortOrder,
      IsActive
    )
    VALUES (
      src.MenuProductId,
      src.ComponentName,
      src.IsRequired,
      src.SortOrder,
      1
    );

  -- 4) Opciones
  DECLARE @Opciones TABLE (
    ProductCode NVARCHAR(80) NOT NULL,
    ComponentName NVARCHAR(120) NOT NULL,
    OptionName NVARCHAR(120) NOT NULL,
    ExtraPrice DECIMAL(18,2) NOT NULL,
    SortOrder INT NOT NULL
  );

  INSERT INTO @Opciones (ProductCode, ComponentName, OptionName, ExtraPrice, SortOrder)
  VALUES
    (N'HAMB-CLASICA', N'Tipo de Queso', N'Sin queso', 0.00, 10),
    (N'HAMB-CLASICA', N'Tipo de Queso', N'Con cheddar', 1.50, 20),
    (N'HAMB-CLASICA', N'Punto de coccion', N'Termino medio', 0.00, 10),
    (N'HAMB-CLASICA', N'Punto de coccion', N'Bien cocida', 0.00, 20),
    (N'HAMB-CLASICA', N'Extras', N'Tocineta', 1.80, 10),
    (N'HAMB-CLASICA', N'Extras', N'Huevo', 1.20, 20),

    (N'HAMB-DOBLE-QUESO', N'Punto de coccion', N'Termino medio', 0.00, 10),
    (N'HAMB-DOBLE-QUESO', N'Punto de coccion', N'Bien cocida', 0.00, 20),
    (N'HAMB-DOBLE-QUESO', N'Acompanante', N'Papas rusticas', 0.00, 10),
    (N'HAMB-DOBLE-QUESO', N'Acompanante', N'Ensalada fresca', 0.00, 20),
    (N'HAMB-DOBLE-QUESO', N'Extras', N'Aros de cebolla', 1.30, 10),

    (N'HAMB-POLLO-CRISPY', N'Salsa de la casa', N'Salsa ajo', 0.00, 10),
    (N'HAMB-POLLO-CRISPY', N'Salsa de la casa', N'BBQ', 0.00, 20),
    (N'HAMB-POLLO-CRISPY', N'Salsa de la casa', N'Picante', 0.00, 30),
    (N'HAMB-POLLO-CRISPY', N'Acompanante', N'Papas', 0.00, 10),
    (N'HAMB-POLLO-CRISPY', N'Acompanante', N'Yuca frita', 0.60, 20),

    (N'PIZZA-PEPPERONI', N'Tamano', N'Mediana', 0.00, 10),
    (N'PIZZA-PEPPERONI', N'Tamano', N'Familiar', 4.00, 20),
    (N'PIZZA-PEPPERONI', N'Tipo de masa', N'Delgada', 0.00, 10),
    (N'PIZZA-PEPPERONI', N'Tipo de masa', N'Tradicional', 0.00, 20),

    (N'COMBO-ALMUERZO', N'Bebida incluida', N'Refresco cola', 0.00, 10),
    (N'COMBO-ALMUERZO', N'Bebida incluida', N'Limonada', 0.00, 20),
    (N'COMBO-ALMUERZO', N'Bebida incluida', N'Agua mineral', 0.00, 30),
    (N'COMBO-ALMUERZO', N'Postre incluido', N'Brownie mini', 0.00, 10),
    (N'COMBO-ALMUERZO', N'Postre incluido', N'Cheesecake mini', 0.80, 20),

    (N'PROMO-PAREJA', N'Bebidas', N'2 Refrescos cola', 0.00, 10),
    (N'PROMO-PAREJA', N'Bebidas', N'2 Limonadas', 0.00, 20),
    (N'PROMO-PAREJA', N'Entrada compartida', N'Tequenos', 0.00, 10),
    (N'PROMO-PAREJA', N'Entrada compartida', N'Papas rusticas', 0.00, 20);

  ;WITH OptionSource AS (
    SELECT
      mc.MenuComponentId,
      o.OptionName,
      o.ExtraPrice,
      o.SortOrder
    FROM @Opciones o
    INNER JOIN rest.MenuProduct mp
      ON mp.CompanyId = @CompanyId
     AND mp.BranchId = @BranchId
     AND mp.IsActive = 1
     AND UPPER(mp.ProductCode) = UPPER(o.ProductCode)
    INNER JOIN rest.MenuComponent mc
      ON mc.MenuProductId = mp.MenuProductId
     AND mc.IsActive = 1
     AND UPPER(mc.ComponentName) = UPPER(o.ComponentName)
  )
  MERGE rest.MenuOption AS tgt
  USING OptionSource AS src
    ON tgt.MenuComponentId = src.MenuComponentId
   AND UPPER(tgt.OptionName) = UPPER(src.OptionName)
  WHEN MATCHED THEN
    UPDATE SET
      ExtraPrice = src.ExtraPrice,
      SortOrder = src.SortOrder,
      IsActive = 1,
      UpdatedAt = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (
      MenuComponentId,
      OptionName,
      ExtraPrice,
      SortOrder,
      IsActive
    )
    VALUES (
      src.MenuComponentId,
      src.OptionName,
      src.ExtraPrice,
      src.SortOrder,
      1
    );

  -- 5) Recetas
  DECLARE @Recetas TABLE (
    ProductCode NVARCHAR(80) NOT NULL,
    IngredientCode NVARCHAR(80) NOT NULL,
    Quantity DECIMAL(18,4) NOT NULL,
    UnitCode NVARCHAR(20) NOT NULL,
    Notes NVARCHAR(200) NULL
  );

  INSERT INTO @Recetas (ProductCode, IngredientCode, Quantity, UnitCode, Notes)
  VALUES
    (N'HAMB-CLASICA', N'INS-CARNE-RES', 0.1800, N'KG', N'Carne por unidad'),
    (N'HAMB-CLASICA', N'INS-PAN-HAMB', 1.0000, N'UND', N'Pan de hamburguesa'),
    (N'HAMB-CLASICA', N'INS-QUESO-CHD', 0.0300, N'KG', N'Queso cheddar estandar'),

    (N'HAMB-DOBLE-QUESO', N'INS-CARNE-RES', 0.3000, N'KG', N'Doble porcion de carne'),
    (N'HAMB-DOBLE-QUESO', N'INS-PAN-HAMB', 1.0000, N'UND', N'Pan de hamburguesa'),
    (N'HAMB-DOBLE-QUESO', N'INS-QUESO-CHD', 0.0600, N'KG', N'Doble queso cheddar'),

    (N'HAMB-POLLO-CRISPY', N'INS-POLLO-FILET', 0.2200, N'KG', N'Filete por sandwich'),
    (N'HAMB-POLLO-CRISPY', N'INS-PAN-HAMB', 1.0000, N'UND', N'Pan de hamburguesa'),
    (N'HAMB-POLLO-CRISPY', N'INS-PAPA-FRITA', 0.1500, N'KG', N'Acompanante de papas'),

    (N'PIZZA-PEPPERONI', N'INS-MASA-PIZZA', 1.0000, N'UND', N'Masa base por pizza'),
    (N'PIZZA-PEPPERONI', N'INS-SALSA-TOMATE', 0.1200, N'KG', N'Salsa base'),
    (N'PIZZA-PEPPERONI', N'INS-MOZZARELLA', 0.2200, N'KG', N'Queso principal'),
    (N'PIZZA-PEPPERONI', N'INS-PEPPERONI', 0.1200, N'KG', N'Topping pepperoni'),

    (N'COMBO-ALMUERZO', N'INS-CARNE-RES', 0.1800, N'KG', N'Base combo proteina'),
    (N'COMBO-ALMUERZO', N'INS-PAN-HAMB', 1.0000, N'UND', N'Pan para sandwich combo'),
    (N'COMBO-ALMUERZO', N'INS-BEBIDA-VASO', 1.0000, N'UND', N'Bebida incluida'),

    (N'PROMO-PAREJA', N'INS-CARNE-RES', 0.3600, N'KG', N'Dos porciones de carne'),
    (N'PROMO-PAREJA', N'INS-PAN-HAMB', 2.0000, N'UND', N'Dos panes'),
    (N'PROMO-PAREJA', N'INS-QUESO-CHD', 0.0600, N'KG', N'Queso para dos'),
    (N'PROMO-PAREJA', N'INS-BEBIDA-VASO', 2.0000, N'UND', N'Dos bebidas incluidas');

  ;WITH RecipeSource AS (
    SELECT
      mp.MenuProductId,
      ip.ProductId AS IngredientProductId,
      r.Quantity,
      r.UnitCode,
      r.Notes
    FROM @Recetas r
    INNER JOIN rest.MenuProduct mp
      ON mp.CompanyId = @CompanyId
     AND mp.BranchId = @BranchId
     AND mp.IsActive = 1
     AND UPPER(mp.ProductCode) = UPPER(r.ProductCode)
    INNER JOIN [master].Product ip
      ON ip.CompanyId = @CompanyId
     AND ip.IsDeleted = 0
     AND UPPER(ip.ProductCode) = UPPER(r.IngredientCode)
  )
  MERGE rest.MenuRecipe AS tgt
  USING RecipeSource AS src
    ON tgt.MenuProductId = src.MenuProductId
   AND tgt.IngredientProductId = src.IngredientProductId
  WHEN MATCHED THEN
    UPDATE SET
      Quantity = src.Quantity,
      UnitCode = src.UnitCode,
      Notes = src.Notes,
      IsActive = 1,
      UpdatedAt = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (
      MenuProductId,
      IngredientProductId,
      Quantity,
      UnitCode,
      Notes,
      IsActive
    )
    VALUES (
      src.MenuProductId,
      src.IngredientProductId,
      src.Quantity,
      src.UnitCode,
      src.Notes,
      1
    );

  COMMIT TRAN;

  SELECT COUNT(*) AS menu_componentes_activos
  FROM rest.MenuComponent
  WHERE IsActive = 1;

  SELECT COUNT(*) AS menu_opciones_activas
  FROM rest.MenuOption
  WHERE IsActive = 1;

  SELECT COUNT(*) AS menu_recetas_activas
  FROM rest.MenuRecipe
  WHERE IsActive = 1;

END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  THROW;
END CATCH;
