-- ============================================================
-- DatqBoxWeb PostgreSQL - seed_restaurante_componentes_recetas.sql
-- Seed de insumos, componentes, opciones y recetas para
-- productos del menu de restaurante
-- ============================================================

-- Unique constraints necesarios para ON CONFLICT
CREATE UNIQUE INDEX IF NOT EXISTS "UQ_MenuComponent_ProductName"
  ON rest."MenuComponent" ("MenuProductId", "ComponentName");

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_MenuOption_ComponentOption"
  ON rest."MenuOption" ("MenuComponentId", "OptionName");

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_MenuRecipe_ProductIngredient"
  ON rest."MenuRecipe" ("MenuProductId", "IngredientProductId");

DO $$
DECLARE
  v_CompanyId INT;
  v_BranchId  INT;
  v_UserId    INT;
BEGIN

  SELECT "CompanyId" INTO v_CompanyId
  FROM cfg."Company"
  WHERE "CompanyCode" = 'DEFAULT'
  ORDER BY "CompanyId"
  LIMIT 1;

  IF v_CompanyId IS NULL THEN
    v_CompanyId := 1;
  END IF;

  SELECT "BranchId" INTO v_BranchId
  FROM cfg."Branch"
  WHERE "CompanyId" = v_CompanyId
    AND "BranchCode" = 'MAIN'
  ORDER BY "BranchId"
  LIMIT 1;

  IF v_BranchId IS NULL THEN
    SELECT "BranchId" INTO v_BranchId
    FROM cfg."Branch"
    WHERE "CompanyId" = v_CompanyId
    ORDER BY "BranchId"
    LIMIT 1;
  END IF;

  SELECT "UserId" INTO v_UserId
  FROM sec."User"
  WHERE "IsActive" = TRUE
    AND "IsDeleted" = FALSE
    AND UPPER("UserCode") IN ('SYSTEM', 'SUP')
  ORDER BY CASE WHEN UPPER("UserCode") = 'SYSTEM' THEN 0 ELSE 1 END, "UserId"
  LIMIT 1;

  -- ── 1) Seed de insumos base para recetas ──
  INSERT INTO master."Product" (
    "CompanyId", "ProductCode", "ProductName", "CategoryCode", "UnitCode",
    "SalesPrice", "CostPrice", "DefaultTaxCode", "DefaultTaxRate",
    "StockQty", "IsService", "IsActive", "CreatedByUserId",
    "UpdatedByUserId", "IsDeleted"
  )
  VALUES
    (v_CompanyId, 'INS-CARNE-RES',    'Insumo Carne de Res (kg)',       'INSUMOS', 'KG',  5.20, 5.20, 'EXENTO', 0, 0, FALSE, TRUE, v_UserId, v_UserId, FALSE),
    (v_CompanyId, 'INS-PAN-HAMB',     'Insumo Pan de Hamburguesa',      'INSUMOS', 'UND', 0.35, 0.35, 'EXENTO', 0, 0, FALSE, TRUE, v_UserId, v_UserId, FALSE),
    (v_CompanyId, 'INS-QUESO-CHD',    'Insumo Queso Cheddar (kg)',      'INSUMOS', 'KG',  6.10, 6.10, 'EXENTO', 0, 0, FALSE, TRUE, v_UserId, v_UserId, FALSE),
    (v_CompanyId, 'INS-POLLO-FILET',  'Insumo Filete de Pollo (kg)',    'INSUMOS', 'KG',  4.80, 4.80, 'EXENTO', 0, 0, FALSE, TRUE, v_UserId, v_UserId, FALSE),
    (v_CompanyId, 'INS-PAPA-FRITA',   'Insumo Papa para Freir (kg)',    'INSUMOS', 'KG',  1.50, 1.50, 'EXENTO', 0, 0, FALSE, TRUE, v_UserId, v_UserId, FALSE),
    (v_CompanyId, 'INS-MASA-PIZZA',   'Insumo Masa de Pizza',           'INSUMOS', 'UND', 1.10, 1.10, 'EXENTO', 0, 0, FALSE, TRUE, v_UserId, v_UserId, FALSE),
    (v_CompanyId, 'INS-SALSA-TOMATE', 'Insumo Salsa de Tomate (kg)',    'INSUMOS', 'KG',  1.90, 1.90, 'EXENTO', 0, 0, FALSE, TRUE, v_UserId, v_UserId, FALSE),
    (v_CompanyId, 'INS-MOZZARELLA',   'Insumo Queso Mozzarella (kg)',   'INSUMOS', 'KG',  6.80, 6.80, 'EXENTO', 0, 0, FALSE, TRUE, v_UserId, v_UserId, FALSE),
    (v_CompanyId, 'INS-PEPPERONI',    'Insumo Pepperoni (kg)',           'INSUMOS', 'KG',  7.50, 7.50, 'EXENTO', 0, 0, FALSE, TRUE, v_UserId, v_UserId, FALSE),
    (v_CompanyId, 'INS-BEBIDA-VASO',  'Insumo Bebida Vaso',             'INSUMOS', 'UND', 0.65, 0.65, 'EXENTO', 0, 0, FALSE, TRUE, v_UserId, v_UserId, FALSE)
  ON CONFLICT ("CompanyId", "ProductCode") DO UPDATE SET
    "ProductName"    = EXCLUDED."ProductName",
    "CategoryCode"   = 'INSUMOS',
    "UnitCode"       = EXCLUDED."UnitCode",
    "CostPrice"      = EXCLUDED."CostPrice",
    "SalesPrice"     = CASE
                         WHEN master."Product"."SalesPrice" IS NULL
                           OR master."Product"."SalesPrice" < EXCLUDED."CostPrice"
                         THEN EXCLUDED."CostPrice"
                         ELSE master."Product"."SalesPrice"
                       END,
    "DefaultTaxCode" = COALESCE(master."Product"."DefaultTaxCode", 'EXENTO'),
    "DefaultTaxRate" = COALESCE(master."Product"."DefaultTaxRate", 0),
    "IsService"      = FALSE,
    "IsActive"       = TRUE,
    "IsDeleted"      = FALSE,
    "DeletedAt"      = NULL,
    "DeletedByUserId"= NULL,
    "UpdatedAt"      = NOW() AT TIME ZONE 'UTC',
    "UpdatedByUserId"= v_UserId;

  -- ── 2) Marcar productos compuestos ──
  UPDATE rest."MenuProduct"
  SET
    "IsComposite"     = TRUE,
    "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
    "UpdatedByUserId" = v_UserId
  WHERE "CompanyId" = v_CompanyId
    AND "BranchId"  = v_BranchId
    AND "IsActive"  = TRUE
    AND UPPER("ProductCode") IN (
      'HAMB-CLASICA',
      'HAMB-DOBLE-QUESO',
      'HAMB-POLLO-CRISPY',
      'PIZZA-PEPPERONI',
      'COMBO-ALMUERZO',
      'PROMO-PAREJA'
    );

  -- ── 3) Componentes ──
  INSERT INTO rest."MenuComponent" (
    "MenuProductId", "ComponentName", "IsRequired", "SortOrder", "IsActive"
  )
  SELECT
    p."MenuProductId",
    c."ComponentName",
    c."IsRequired",
    c."SortOrder",
    TRUE
  FROM (
    VALUES
      ('HAMB-CLASICA',       'Tipo de Queso',       FALSE, 10),
      ('HAMB-CLASICA',       'Punto de coccion',    TRUE,  20),
      ('HAMB-CLASICA',       'Extras',              FALSE, 30),
      ('HAMB-DOBLE-QUESO',   'Punto de coccion',    TRUE,  10),
      ('HAMB-DOBLE-QUESO',   'Acompanante',         TRUE,  20),
      ('HAMB-DOBLE-QUESO',   'Extras',              FALSE, 30),
      ('HAMB-POLLO-CRISPY',  'Salsa de la casa',    FALSE, 10),
      ('HAMB-POLLO-CRISPY',  'Acompanante',         TRUE,  20),
      ('PIZZA-PEPPERONI',    'Tamano',              TRUE,  10),
      ('PIZZA-PEPPERONI',    'Tipo de masa',        TRUE,  20),
      ('COMBO-ALMUERZO',     'Bebida incluida',     TRUE,  10),
      ('COMBO-ALMUERZO',     'Postre incluido',     FALSE, 20),
      ('PROMO-PAREJA',       'Bebidas',             TRUE,  10),
      ('PROMO-PAREJA',       'Entrada compartida',  FALSE, 20)
  ) AS c("ProductCode", "ComponentName", "IsRequired", "SortOrder")
  INNER JOIN rest."MenuProduct" p
    ON p."CompanyId" = v_CompanyId
   AND p."BranchId"  = v_BranchId
   AND p."IsActive"  = TRUE
   AND UPPER(p."ProductCode") = UPPER(c."ProductCode")
  ON CONFLICT ("MenuProductId", "ComponentName") DO UPDATE SET
    "IsRequired" = EXCLUDED."IsRequired",
    "SortOrder"  = EXCLUDED."SortOrder",
    "IsActive"   = TRUE,
    "UpdatedAt"  = NOW() AT TIME ZONE 'UTC';

  -- ── 4) Opciones ──
  INSERT INTO rest."MenuOption" (
    "MenuComponentId", "OptionName", "ExtraPrice", "SortOrder", "IsActive"
  )
  SELECT
    mc."MenuComponentId",
    o."OptionName",
    o."ExtraPrice",
    o."SortOrder",
    TRUE
  FROM (
    VALUES
      ('HAMB-CLASICA',      'Tipo de Queso',     'Sin queso',        0.00, 10),
      ('HAMB-CLASICA',      'Tipo de Queso',     'Con cheddar',      1.50, 20),
      ('HAMB-CLASICA',      'Punto de coccion',  'Termino medio',    0.00, 10),
      ('HAMB-CLASICA',      'Punto de coccion',  'Bien cocida',      0.00, 20),
      ('HAMB-CLASICA',      'Extras',            'Tocineta',         1.80, 10),
      ('HAMB-CLASICA',      'Extras',            'Huevo',            1.20, 20),

      ('HAMB-DOBLE-QUESO',  'Punto de coccion',  'Termino medio',    0.00, 10),
      ('HAMB-DOBLE-QUESO',  'Punto de coccion',  'Bien cocida',      0.00, 20),
      ('HAMB-DOBLE-QUESO',  'Acompanante',       'Papas rusticas',   0.00, 10),
      ('HAMB-DOBLE-QUESO',  'Acompanante',       'Ensalada fresca',  0.00, 20),
      ('HAMB-DOBLE-QUESO',  'Extras',            'Aros de cebolla',  1.30, 10),

      ('HAMB-POLLO-CRISPY', 'Salsa de la casa',  'Salsa ajo',        0.00, 10),
      ('HAMB-POLLO-CRISPY', 'Salsa de la casa',  'BBQ',              0.00, 20),
      ('HAMB-POLLO-CRISPY', 'Salsa de la casa',  'Picante',          0.00, 30),
      ('HAMB-POLLO-CRISPY', 'Acompanante',       'Papas',            0.00, 10),
      ('HAMB-POLLO-CRISPY', 'Acompanante',       'Yuca frita',       0.60, 20),

      ('PIZZA-PEPPERONI',   'Tamano',            'Mediana',          0.00, 10),
      ('PIZZA-PEPPERONI',   'Tamano',            'Familiar',         4.00, 20),
      ('PIZZA-PEPPERONI',   'Tipo de masa',      'Delgada',          0.00, 10),
      ('PIZZA-PEPPERONI',   'Tipo de masa',      'Tradicional',      0.00, 20),

      ('COMBO-ALMUERZO',    'Bebida incluida',   'Refresco cola',    0.00, 10),
      ('COMBO-ALMUERZO',    'Bebida incluida',   'Limonada',         0.00, 20),
      ('COMBO-ALMUERZO',    'Bebida incluida',   'Agua mineral',     0.00, 30),
      ('COMBO-ALMUERZO',    'Postre incluido',   'Brownie mini',     0.00, 10),
      ('COMBO-ALMUERZO',    'Postre incluido',   'Cheesecake mini',  0.80, 20),

      ('PROMO-PAREJA',      'Bebidas',           '2 Refrescos cola', 0.00, 10),
      ('PROMO-PAREJA',      'Bebidas',           '2 Limonadas',      0.00, 20),
      ('PROMO-PAREJA',      'Entrada compartida','Tequenos',         0.00, 10),
      ('PROMO-PAREJA',      'Entrada compartida','Papas rusticas',   0.00, 20)
  ) AS o("ProductCode", "ComponentName", "OptionName", "ExtraPrice", "SortOrder")
  INNER JOIN rest."MenuProduct" mp
    ON mp."CompanyId" = v_CompanyId
   AND mp."BranchId"  = v_BranchId
   AND mp."IsActive"  = TRUE
   AND UPPER(mp."ProductCode") = UPPER(o."ProductCode")
  INNER JOIN rest."MenuComponent" mc
    ON mc."MenuProductId" = mp."MenuProductId"
   AND mc."IsActive" = TRUE
   AND UPPER(mc."ComponentName") = UPPER(o."ComponentName")
  ON CONFLICT ("MenuComponentId", "OptionName") DO UPDATE SET
    "ExtraPrice" = EXCLUDED."ExtraPrice",
    "SortOrder"  = EXCLUDED."SortOrder",
    "IsActive"   = TRUE,
    "UpdatedAt"  = NOW() AT TIME ZONE 'UTC';

  -- ── 5) Recetas ──
  INSERT INTO rest."MenuRecipe" (
    "MenuProductId", "IngredientProductId", "Quantity",
    "UnitCode", "Notes", "IsActive"
  )
  SELECT
    mp."MenuProductId",
    ip."ProductId",
    r."Quantity",
    r."UnitCode",
    r."Notes",
    TRUE
  FROM (
    VALUES
      ('HAMB-CLASICA',       'INS-CARNE-RES',    0.1800, 'KG',  'Carne por unidad'),
      ('HAMB-CLASICA',       'INS-PAN-HAMB',     1.0000, 'UND', 'Pan de hamburguesa'),
      ('HAMB-CLASICA',       'INS-QUESO-CHD',    0.0300, 'KG',  'Queso cheddar estandar'),

      ('HAMB-DOBLE-QUESO',   'INS-CARNE-RES',    0.3000, 'KG',  'Doble porcion de carne'),
      ('HAMB-DOBLE-QUESO',   'INS-PAN-HAMB',     1.0000, 'UND', 'Pan de hamburguesa'),
      ('HAMB-DOBLE-QUESO',   'INS-QUESO-CHD',    0.0600, 'KG',  'Doble queso cheddar'),

      ('HAMB-POLLO-CRISPY',  'INS-POLLO-FILET',  0.2200, 'KG',  'Filete por sandwich'),
      ('HAMB-POLLO-CRISPY',  'INS-PAN-HAMB',     1.0000, 'UND', 'Pan de hamburguesa'),
      ('HAMB-POLLO-CRISPY',  'INS-PAPA-FRITA',   0.1500, 'KG',  'Acompanante de papas'),

      ('PIZZA-PEPPERONI',    'INS-MASA-PIZZA',   1.0000, 'UND', 'Masa base por pizza'),
      ('PIZZA-PEPPERONI',    'INS-SALSA-TOMATE', 0.1200, 'KG',  'Salsa base'),
      ('PIZZA-PEPPERONI',    'INS-MOZZARELLA',   0.2200, 'KG',  'Queso principal'),
      ('PIZZA-PEPPERONI',    'INS-PEPPERONI',    0.1200, 'KG',  'Topping pepperoni'),

      ('COMBO-ALMUERZO',     'INS-CARNE-RES',    0.1800, 'KG',  'Base combo proteina'),
      ('COMBO-ALMUERZO',     'INS-PAN-HAMB',     1.0000, 'UND', 'Pan para sandwich combo'),
      ('COMBO-ALMUERZO',     'INS-BEBIDA-VASO',  1.0000, 'UND', 'Bebida incluida'),

      ('PROMO-PAREJA',       'INS-CARNE-RES',    0.3600, 'KG',  'Dos porciones de carne'),
      ('PROMO-PAREJA',       'INS-PAN-HAMB',     2.0000, 'UND', 'Dos panes'),
      ('PROMO-PAREJA',       'INS-QUESO-CHD',    0.0600, 'KG',  'Queso para dos'),
      ('PROMO-PAREJA',       'INS-BEBIDA-VASO',  2.0000, 'UND', 'Dos bebidas incluidas')
  ) AS r("ProductCode", "IngredientCode", "Quantity", "UnitCode", "Notes")
  INNER JOIN rest."MenuProduct" mp
    ON mp."CompanyId" = v_CompanyId
   AND mp."BranchId"  = v_BranchId
   AND mp."IsActive"  = TRUE
   AND UPPER(mp."ProductCode") = UPPER(r."ProductCode")
  INNER JOIN master."Product" ip
    ON ip."CompanyId" = v_CompanyId
   AND ip."IsDeleted" = FALSE
   AND UPPER(ip."ProductCode") = UPPER(r."IngredientCode")
  ON CONFLICT ("MenuProductId", "IngredientProductId") DO UPDATE SET
    "Quantity"  = EXCLUDED."Quantity",
    "UnitCode"  = EXCLUDED."UnitCode",
    "Notes"     = EXCLUDED."Notes",
    "IsActive"  = TRUE,
    "UpdatedAt" = NOW() AT TIME ZONE 'UTC';

  -- Resumen
  RAISE NOTICE 'Componentes activos: %',
    (SELECT COUNT(*) FROM rest."MenuComponent" WHERE "IsActive" = TRUE);
  RAISE NOTICE 'Opciones activas: %',
    (SELECT COUNT(*) FROM rest."MenuOption" WHERE "IsActive" = TRUE);
  RAISE NOTICE 'Recetas activas: %',
    (SELECT COUNT(*) FROM rest."MenuRecipe" WHERE "IsActive" = TRUE);

END $$;
