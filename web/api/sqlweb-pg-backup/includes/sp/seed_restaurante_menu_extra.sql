-- ============================================================
-- DatqBoxWeb PostgreSQL - seed_restaurante_menu_extra.sql
-- Seed de categorias y productos adicionales para el menu
-- de restaurante (entradas, pizzas, pastas, postres, etc.)
-- ============================================================

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

  -- ── Categorias ──
  INSERT INTO rest."MenuCategory" (
    "CompanyId", "BranchId", "CategoryCode", "CategoryName",
    "DescriptionText", "ColorHex", "SortOrder", "IsActive",
    "CreatedByUserId", "UpdatedByUserId"
  )
  VALUES
    (v_CompanyId, v_BranchId, 'ENTRADAS',  'Entradas',  'Entradas y para compartir',      '#F59E0B',  5, TRUE, v_UserId, v_UserId),
    (v_CompanyId, v_BranchId, 'PIZZAS',    'Pizzas',    'Pizzas artesanales',              '#EF4444', 15, TRUE, v_UserId, v_UserId),
    (v_CompanyId, v_BranchId, 'PASTAS',    'Pastas',    'Pastas y salsas de la casa',      '#FB7185', 18, TRUE, v_UserId, v_UserId),
    (v_CompanyId, v_BranchId, 'POSTRES',   'Postres',   'Postres y dulces',                '#8B5CF6', 25, TRUE, v_UserId, v_UserId),
    (v_CompanyId, v_BranchId, 'CAFETERIA', 'Cafeteria', 'Cafes e infusiones',              '#A16207', 30, TRUE, v_UserId, v_UserId),
    (v_CompanyId, v_BranchId, 'COCTELES',  'Cocteles',  'Cocteleria clasica',              '#06B6D4', 35, TRUE, v_UserId, v_UserId),
    (v_CompanyId, v_BranchId, 'COMBOS',    'Combos',    'Promociones y menus combo',       '#22C55E', 40, TRUE, v_UserId, v_UserId)
  ON CONFLICT ("CompanyId", "BranchId", "CategoryCode") DO UPDATE SET
    "CategoryName"    = EXCLUDED."CategoryName",
    "DescriptionText" = EXCLUDED."DescriptionText",
    "ColorHex"        = EXCLUDED."ColorHex",
    "SortOrder"       = EXCLUDED."SortOrder",
    "IsActive"        = TRUE,
    "UpdatedAt"       = NOW() AT TIME ZONE 'UTC',
    "UpdatedByUserId" = v_UserId;

  -- ── Productos ──
  INSERT INTO rest."MenuProduct" (
    "CompanyId", "BranchId", "ProductCode", "ProductName",
    "DescriptionText", "MenuCategoryId", "PriceAmount", "EstimatedCost",
    "TaxRatePercent", "IsComposite", "PrepMinutes", "ImageUrl",
    "IsDailySuggestion", "IsAvailable", "InventoryProductId",
    "IsActive", "CreatedByUserId", "UpdatedByUserId"
  )
  SELECT
    v_CompanyId,
    v_BranchId,
    p."ProductCode",
    p."ProductName",
    p."DescriptionText",
    c."MenuCategoryId",
    p."PriceAmount",
    p."EstimatedCost",
    p."TaxRatePercent",
    FALSE,
    p."PrepMinutes",
    NULL,
    p."IsDailySuggestion",
    TRUE,
    NULL,
    TRUE,
    v_UserId,
    v_UserId
  FROM (
    VALUES
      ('PAPAS-RUSTICAS',       'Papas Rusticas',            'Papas crujientes con salsa de ajo',            'ENTRADAS',     4.50,  1.80, 16.0000,  8, FALSE),
      ('TEQUENOS-QUESO',       'Tequenos de Queso',         'Seis tequenos con salsa tartara',              'ENTRADAS',     5.90,  2.30, 16.0000, 10, FALSE),
      ('ALITAS-BBQ',           'Alitas BBQ',                'Ocho alitas glaseadas estilo BBQ',             'ENTRADAS',     8.50,  3.20, 16.0000, 12, FALSE),

      ('PIZZA-MARGHERITA',     'Pizza Margherita',          'Salsa de tomate, mozzarella y albahaca',       'PIZZAS',      11.00,  4.30, 16.0000, 15, FALSE),
      ('PIZZA-PEPPERONI',      'Pizza Pepperoni',           'Pizza artesanal con pepperoni premium',        'PIZZAS',      12.50,  4.90, 16.0000, 15, TRUE),

      ('PASTA-ALFREDO',        'Pasta Alfredo',             'Fettuccine en salsa alfredo',                  'PASTAS',      10.75,  4.20, 16.0000, 14, FALSE),
      ('PASTA-BOLO',           'Pasta Bolognesa',           'Spaghetti con salsa bolognesa de la casa',     'PASTAS',      11.25,  4.40, 16.0000, 14, FALSE),

      ('CHEESECAKE-FRESA',     'Cheesecake de Fresa',       'Porcion individual',                           'POSTRES',      4.80,  1.60, 16.0000,  3, FALSE),
      ('BROWNIE-HELADO',       'Brownie con Helado',        'Brownie tibio con helado de vainilla',         'POSTRES',      5.50,  1.90, 16.0000,  5, TRUE),

      ('CAFE-ESPRESSO',        'Cafe Espresso',             'Taza de espresso doble',                       'CAFETERIA',    1.80,  0.60, 16.0000,  2, FALSE),
      ('CAPPUCCINO',           'Cappuccino',                'Cappuccino con espuma de leche',               'CAFETERIA',    2.90,  1.00, 16.0000,  3, FALSE),

      ('MOJITO-CLASICO',       'Mojito Clasico',            'Ron blanco, hierbabuena y limon',              'COCTELES',     6.80,  2.40, 16.0000,  4, FALSE),
      ('GIN-TONIC',            'Gin Tonic',                 'Gin premium con agua tonica',                  'COCTELES',     7.50,  2.70, 16.0000,  4, FALSE),

      ('HAMB-DOBLE-QUESO',     'Hamburguesa Doble Queso',   'Doble carne, doble queso cheddar',            'HAMBURGUESAS', 12.00,  4.80, 16.0000, 12, TRUE),
      ('HAMB-POLLO-CRISPY',    'Hamburguesa Pollo Crispy',  'Pechuga crispy con salsa especial',           'HAMBURGUESAS', 10.90,  4.10, 16.0000, 12, FALSE),

      ('LIMONADA-HIERBABUENA', 'Limonada Hierbabuena',      'Limonada natural con menta',                  'BEBIDAS',      3.20,  1.00, 16.0000,  2, FALSE),
      ('JUGO-NARANJA',         'Jugo de Naranja',           'Jugo natural recien exprimido',               'BEBIDAS',      2.80,  0.90, 16.0000,  2, FALSE),

      ('COMBO-ALMUERZO',       'Combo Almuerzo',            'Plato principal + bebida + postre',           'COMBOS',      13.90,  5.20, 16.0000, 10, TRUE),
      ('PROMO-PAREJA',         'Promo Pareja',              'Dos platos fuertes y una entrada',            'COMBOS',      24.90,  9.20, 16.0000, 12, TRUE)
  ) AS p("ProductCode", "ProductName", "DescriptionText", "CategoryCode",
         "PriceAmount", "EstimatedCost", "TaxRatePercent", "PrepMinutes", "IsDailySuggestion")
  LEFT JOIN rest."MenuCategory" c
    ON c."CompanyId" = v_CompanyId
   AND c."BranchId"  = v_BranchId
   AND UPPER(c."CategoryCode") = UPPER(p."CategoryCode")
  ON CONFLICT ("CompanyId", "BranchId", "ProductCode") DO UPDATE SET
    "ProductName"       = EXCLUDED."ProductName",
    "DescriptionText"   = EXCLUDED."DescriptionText",
    "MenuCategoryId"    = COALESCE(EXCLUDED."MenuCategoryId", rest."MenuProduct"."MenuCategoryId"),
    "PriceAmount"       = EXCLUDED."PriceAmount",
    "EstimatedCost"     = EXCLUDED."EstimatedCost",
    "TaxRatePercent"    = EXCLUDED."TaxRatePercent",
    "IsComposite"       = FALSE,
    "PrepMinutes"       = EXCLUDED."PrepMinutes",
    "ImageUrl"          = NULL,
    "IsDailySuggestion" = EXCLUDED."IsDailySuggestion",
    "IsAvailable"       = TRUE,
    "IsActive"          = TRUE,
    "UpdatedAt"         = NOW() AT TIME ZONE 'UTC',
    "UpdatedByUserId"   = v_UserId;

  -- Resumen
  RAISE NOTICE 'Categorias activas: %',
    (SELECT COUNT(*) FROM rest."MenuCategory"
     WHERE "CompanyId" = v_CompanyId AND "BranchId" = v_BranchId AND "IsActive" = TRUE);
  RAISE NOTICE 'Productos activos: %',
    (SELECT COUNT(*) FROM rest."MenuProduct"
     WHERE "CompanyId" = v_CompanyId AND "BranchId" = v_BranchId
       AND "IsActive" = TRUE AND "IsAvailable" = TRUE);

END $$;
