/*
 * seed_demo_clientes_documentos.sql (PostgreSQL)
 * ─────────────────────────────────────────────
 * Seed de datos demo para módulos comerciales/transaccionales.
 * Idempotente: ON CONFLICT DO NOTHING / WHERE NOT EXISTS.
 *
 * Tablas afectadas:
 *   master."Customer", master."CustomerAddress", master."CustomerPaymentMethod",
 *   ar."SalesDocument", ar."SalesDocumentLine", ar."ReceivableDocument",
 *   ap."PurchaseDocument", ap."PurchaseDocumentLine", ap."PayableDocument",
 *   master."InventoryMovement"
 */

DO $$
BEGIN
  RAISE NOTICE '=== Seed demo: Clientes y Documentos Comerciales ===';

  -- ============================================================================
  -- SECCIÓN 1: master."Customer"  (agregar 9 clientes)
  -- ============================================================================
  RAISE NOTICE '>> 1. Clientes demo...';

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "IsActive", "CreatedByUserId")
  VALUES (1, 'CLT002', 'Constructora Bolívar C.A.', 'J-30123456-7', 'admin@constructorabvr.ve', '+58-212-5551234', 'Av. Libertador, Torre Delta, Piso 8, Caracas', 500000.00, TRUE, 1)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "IsActive", "CreatedByUserId")
  VALUES (1, 'CLT003', 'María del Carmen Rodríguez', 'V-12345678-9', 'maria.rodriguez@gmail.com', '+58-414-3210001', 'Urb. El Paraíso, Calle 4, Casa 12, Maracaibo', 100000.00, TRUE, 1)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "IsActive", "CreatedByUserId")
  VALUES (1, 'CLT004', 'Grupo Alimenticio Oriente S.A.', 'J-40234567-0', 'ventas@grupoalioriente.com', '+58-281-2654321', 'Zona Industrial Los Montones, Galpón 3, Barcelona', 750000.00, TRUE, 1)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "IsActive", "CreatedByUserId")
  VALUES (1, 'CLT005', 'José Antonio Pérez Mendoza', 'V-9876543-2', 'japerez@hotmail.com', '+58-412-5550088', 'Calle Bolívar cruce con Sucre, Local 5, Valencia', 80000.00, TRUE, 1)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "IsActive", "CreatedByUserId")
  VALUES (1, 'CLT006', 'Alcaldía del Municipio Sucre', 'G-20000123-4', 'compras@alcaldiasucre.gob.ve', '+58-212-9990001', 'Av. Francisco de Miranda, Edif. Municipal, Petare', 1000000.00, TRUE, 1)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "IsActive", "CreatedByUserId")
  VALUES (1, 'CLT007', 'Farmacia Santa Elena C.A.', 'J-31456789-1', 'pedidos@farmaciasantaelena.ve', '+58-243-2340567', 'Av. Constitución No. 45, Maracay', 200000.00, TRUE, 1)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "IsActive", "CreatedByUserId")
  VALUES (1, 'CLT008', 'Ana Gabriela Torres Linares', 'V-15678901-3', 'anatorres@gmail.com', '+58-416-8882233', 'Res. Los Samanes, Torre B, Apto 7-C, Barquisimeto', 60000.00, TRUE, 1)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "IsActive", "CreatedByUserId")
  VALUES (1, 'CLT009', 'TecnoServicios del Caribe C.A.', 'J-50345678-5', 'info@tecnocaribe.com', '+58-261-7654321', 'C.C. Lago Mall, Nivel PB, Local 22, Maracaibo', 350000.00, TRUE, 1)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  INSERT INTO master."Customer" ("CompanyId", "CustomerCode", "CustomerName", "FiscalId", "Email", "Phone", "AddressLine", "CreditLimit", "IsActive", "CreatedByUserId")
  VALUES (1, 'CLT010', 'Restaurante El Fogón Criollo S.R.L.', 'J-41567890-8', 'reservas@elfogoncriollo.ve', '+58-212-7773344', 'Av. Baralt, Edif. La Candelaria, PB, Caracas', 150000.00, TRUE, 1)
  ON CONFLICT ("CompanyId", "CustomerCode") DO NOTHING;

  -- ============================================================================
  -- SECCIÓN 2: master."CustomerAddress"  (2-3 por cliente)
  -- ============================================================================
  RAISE NOTICE '>> 2. Direcciones de clientes demo...';

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT002', 'Oficina Principal', 'Constructora Bolívar C.A.', '+58-212-5551234', 'Av. Libertador, Torre Delta, Piso 8', 'Caracas', 'Distrito Capital', '1010', 'Venezuela', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT002' AND "Label" = 'Oficina Principal');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT002', 'Almacén Obras', 'Ing. Carlos Mejía', '+58-212-5551235', 'Zona Industrial La Yaguara, Galpón 7', 'Caracas', 'Distrito Capital', '1020', 'Venezuela', FALSE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT002' AND "Label" = 'Almacén Obras');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT003', 'Casa', 'María del Carmen Rodríguez', '+58-414-3210001', 'Urb. El Paraíso, Calle 4, Casa 12', 'Maracaibo', 'Zulia', '4001', 'Venezuela', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT003' AND "Label" = 'Casa');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT004', 'Sede Principal', 'Grupo Alimenticio Oriente S.A.', '+58-281-2654321', 'Zona Industrial Los Montones, Galpón 3', 'Barcelona', 'Anzoátegui', '6001', 'Venezuela', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT004' AND "Label" = 'Sede Principal');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT004', 'Punto de Distribución', 'Logística Oriente', '+58-281-2654322', 'Av. Intercomunal, Km 5, Galpón 12', 'Puerto La Cruz', 'Anzoátegui', '6023', 'Venezuela', FALSE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT004' AND "Label" = 'Punto de Distribución');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT005', 'Local Comercial', 'José Antonio Pérez', '+58-412-5550088', 'Calle Bolívar cruce con Sucre, Local 5', 'Valencia', 'Carabobo', '2001', 'Venezuela', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT005' AND "Label" = 'Local Comercial');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT006', 'Edificio Municipal', 'Dpto. de Compras - Alcaldía Sucre', '+58-212-9990001', 'Av. Francisco de Miranda, Edif. Municipal', 'Petare', 'Miranda', '1073', 'Venezuela', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT006' AND "Label" = 'Edificio Municipal');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT007', 'Farmacia Sede', 'Farmacia Santa Elena C.A.', '+58-243-2340567', 'Av. Constitución No. 45', 'Maracay', 'Aragua', '2101', 'Venezuela', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT007' AND "Label" = 'Farmacia Sede');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT007', 'Sucursal Sur', 'Farmacia Santa Elena - Sucursal', '+58-243-2340999', 'Av. Las Delicias, C.C. Hiper Jumbo, Local 4', 'Maracay', 'Aragua', '2103', 'Venezuela', FALSE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT007' AND "Label" = 'Sucursal Sur');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT008', 'Residencia', 'Ana Gabriela Torres', '+58-416-8882233', 'Res. Los Samanes, Torre B, Apto 7-C', 'Barquisimeto', 'Lara', '3001', 'Venezuela', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT008' AND "Label" = 'Residencia');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT009', 'Oficina Comercial', 'TecnoServicios del Caribe C.A.', '+58-261-7654321', 'C.C. Lago Mall, Nivel PB, Local 22', 'Maracaibo', 'Zulia', '4001', 'Venezuela', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT009' AND "Label" = 'Oficina Comercial');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT009', 'Depósito', 'Almacén TecnoCaribe', '+58-261-7654322', 'Av. 5 de Julio, Galpón 15-B', 'Maracaibo', 'Zulia', '4002', 'Venezuela', FALSE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT009' AND "Label" = 'Depósito');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT010', 'Restaurante', 'Restaurante El Fogón Criollo', '+58-212-7773344', 'Av. Baralt, Edif. La Candelaria, PB', 'Caracas', 'Distrito Capital', '1010', 'Venezuela', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT010' AND "Label" = 'Restaurante');

  INSERT INTO master."CustomerAddress" ("CompanyId", "CustomerCode", "Label", "RecipientName", "Phone", "AddressLine", "City", "State", "ZipCode", "Country", "IsDefault")
  SELECT 1, 'CLT010', 'Cocina Central', 'Chef Marcos Salazar', '+58-212-7773345', 'Calle Carabobo con Av. Universidad, Local 8', 'Caracas', 'Distrito Capital', '1010', 'Venezuela', FALSE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerAddress" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT010' AND "Label" = 'Cocina Central');

  -- ============================================================================
  -- SECCIÓN 3: master."CustomerPaymentMethod"  (1-2 por cliente)
  -- ============================================================================
  RAISE NOTICE '>> 3. Métodos de pago de clientes demo...';

  INSERT INTO master."CustomerPaymentMethod" ("CompanyId", "CustomerCode", "MethodType", "Label", "BankName", "AccountNumber", "HolderName", "HolderFiscalId", "IsDefault")
  SELECT 1, 'CLT002', 'TRANSFER', 'Banesco Jurídica', 'Banesco', '01340123456789012345', 'Constructora Bolívar C.A.', 'J-30123456-7', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT002' AND "MethodType" = 'TRANSFER');

  INSERT INTO master."CustomerPaymentMethod" ("CompanyId", "CustomerCode", "MethodType", "Label", "BankName", "AccountPhone", "HolderName", "HolderFiscalId", "IsDefault")
  SELECT 1, 'CLT003', 'MOBILE_PAY', 'Pago Móvil BDV', 'Banco de Venezuela', '04143210001', 'María del Carmen Rodríguez', 'V-12345678-9', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT003' AND "MethodType" = 'MOBILE_PAY');

  INSERT INTO master."CustomerPaymentMethod" ("CompanyId", "CustomerCode", "MethodType", "Label", "BankName", "AccountNumber", "HolderName", "HolderFiscalId", "IsDefault")
  SELECT 1, 'CLT004', 'TRANSFER', 'Provincial Empresarial', 'BBVA Provincial', '01080234567890123456', 'Grupo Alimenticio Oriente S.A.', 'J-40234567-0', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT004' AND "MethodType" = 'TRANSFER');

  INSERT INTO master."CustomerPaymentMethod" ("CompanyId", "CustomerCode", "MethodType", "Label", "BankName", "AccountPhone", "HolderName", "HolderFiscalId", "IsDefault")
  SELECT 1, 'CLT005', 'MOBILE_PAY', 'Pago Móvil Mercantil', 'Mercantil', '04125550088', 'José Antonio Pérez Mendoza', 'V-9876543-2', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT005' AND "MethodType" = 'MOBILE_PAY');

  INSERT INTO master."CustomerPaymentMethod" ("CompanyId", "CustomerCode", "MethodType", "Label", "BankName", "AccountNumber", "HolderName", "HolderFiscalId", "IsDefault")
  SELECT 1, 'CLT006', 'TRANSFER', 'Tesoro Nacional', 'Banco del Tesoro', '01630200001234567890', 'Alcaldía del Municipio Sucre', 'G-20000123-4', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT006' AND "MethodType" = 'TRANSFER');

  INSERT INTO master."CustomerPaymentMethod" ("CompanyId", "CustomerCode", "MethodType", "Label", "BankName", "AccountNumber", "HolderName", "HolderFiscalId", "IsDefault")
  SELECT 1, 'CLT007', 'TRANSFER', 'BOD Farmacia', 'BOD', '01160456789012345678', 'Farmacia Santa Elena C.A.', 'J-31456789-1', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT007' AND "MethodType" = 'TRANSFER');

  INSERT INTO master."CustomerPaymentMethod" ("CompanyId", "CustomerCode", "MethodType", "Label", "BankName", "AccountPhone", "HolderName", "HolderFiscalId", "IsDefault")
  SELECT 1, 'CLT008', 'MOBILE_PAY', 'Pago Móvil Banesco', 'Banesco', '04168882233', 'Ana Gabriela Torres Linares', 'V-15678901-3', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT008' AND "MethodType" = 'MOBILE_PAY');

  INSERT INTO master."CustomerPaymentMethod" ("CompanyId", "CustomerCode", "MethodType", "Label", "BankName", "AccountNumber", "HolderName", "HolderFiscalId", "IsDefault")
  SELECT 1, 'CLT009', 'TRANSFER', 'Mercantil Empresarial', 'Mercantil', '01050567890123456789', 'TecnoServicios del Caribe C.A.', 'J-50345678-5', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT009' AND "MethodType" = 'TRANSFER');

  INSERT INTO master."CustomerPaymentMethod" ("CompanyId", "CustomerCode", "MethodType", "Label", "AccountEmail", "HolderName", "IsDefault")
  SELECT 1, 'CLT009', 'ZELLE', 'Zelle USD', 'payments@tecnocaribe.com', 'TecnoServicios del Caribe C.A.', FALSE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT009' AND "MethodType" = 'ZELLE');

  INSERT INTO master."CustomerPaymentMethod" ("CompanyId", "CustomerCode", "MethodType", "Label", "BankName", "AccountPhone", "HolderName", "HolderFiscalId", "IsDefault")
  SELECT 1, 'CLT010', 'MOBILE_PAY', 'Pago Móvil Venezuela', 'Banco de Venezuela', '04127773344', 'El Fogón Criollo S.R.L.', 'J-41567890-8', TRUE
  WHERE NOT EXISTS (SELECT 1 FROM master."CustomerPaymentMethod" WHERE "CompanyId" = 1 AND "CustomerCode" = 'CLT010' AND "MethodType" = 'MOBILE_PAY');

  -- ============================================================================
  -- SECCIÓN 4: ar."SalesDocument" + ar."SalesDocumentLine"  (5 facturas)
  -- ============================================================================
  RAISE NOTICE '>> 4. Documentos de venta demo...';

  -- Factura 1 - Constructora Bolívar
  IF NOT EXISTS (SELECT 1 FROM ar."SalesDocument" WHERE "DocumentNumber" = 'FACT-2026-00001' AND "OperationType" = 'FACT') THEN
    INSERT INTO ar."SalesDocument" (
      "DocumentNumber", "SerialType", "OperationType",
      "CustomerCode", "CustomerName", "FiscalId",
      "DocumentDate", "DueDate",
      "SubTotal", "TaxableAmount", "TaxAmount", "TaxRate", "TotalAmount",
      "IsPaid", "IsInvoiced", "SellerCode", "CurrencyCode", "ExchangeRate",
      "UserCode", "CreatedByUserId"
    ) VALUES (
      'FACT-2026-00001', 'A', 'FACT',
      'CLT002', 'Constructora Bolívar C.A.', 'J-30123456-7',
      '2026-03-01', '2026-03-31',
      85000.0000, 85000.0000, 13600.0000, 16.0000, 98600.0000,
      'N', 'S', 'V001', 'VES', 1.000000,
      'API', 1
    );
    INSERT INTO ar."SalesDocumentLine" ("DocumentNumber", "SerialType", "OperationType", "LineNumber", "ProductCode", "Description", "Quantity", "UnitPrice", "SubTotal", "TaxRate", "TaxAmount", "TotalAmount", "UserCode", "CreatedByUserId")
    VALUES
      ('FACT-2026-00001', 'A', 'FACT', 1, 'PROD001', 'Cemento Portland 42.5 kg', 50.0000, 800.0000, 40000.0000, 16.0000, 6400.0000, 46400.0000, 'API', 1),
      ('FACT-2026-00001', 'A', 'FACT', 2, 'PROD002', 'Cabilla 1/2" x 12m', 100.0000, 450.0000, 45000.0000, 16.0000, 7200.0000, 52200.0000, 'API', 1);
  END IF;

  -- Factura 2 - Grupo Alimenticio Oriente
  IF NOT EXISTS (SELECT 1 FROM ar."SalesDocument" WHERE "DocumentNumber" = 'FACT-2026-00002' AND "OperationType" = 'FACT') THEN
    INSERT INTO ar."SalesDocument" (
      "DocumentNumber", "SerialType", "OperationType",
      "CustomerCode", "CustomerName", "FiscalId",
      "DocumentDate", "DueDate",
      "SubTotal", "TaxableAmount", "TaxAmount", "TaxRate", "TotalAmount",
      "IsPaid", "IsInvoiced", "SellerCode", "CurrencyCode", "ExchangeRate",
      "UserCode", "CreatedByUserId"
    ) VALUES (
      'FACT-2026-00002', 'A', 'FACT',
      'CLT004', 'Grupo Alimenticio Oriente S.A.', 'J-40234567-0',
      '2026-03-05', '2026-04-04',
      120000.0000, 120000.0000, 19200.0000, 16.0000, 139200.0000,
      'N', 'S', 'V002', 'VES', 1.000000,
      'API', 1
    );
    INSERT INTO ar."SalesDocumentLine" ("DocumentNumber", "SerialType", "OperationType", "LineNumber", "ProductCode", "Description", "Quantity", "UnitPrice", "SubTotal", "TaxRate", "TaxAmount", "TotalAmount", "UserCode", "CreatedByUserId")
    VALUES
      ('FACT-2026-00002', 'A', 'FACT', 1, 'PROD010', 'Aceite vegetal 1L (caja x12)', 200.0000, 350.0000, 70000.0000, 16.0000, 11200.0000, 81200.0000, 'API', 1),
      ('FACT-2026-00002', 'A', 'FACT', 2, 'PROD011', 'Harina precocida 1kg', 500.0000, 100.0000, 50000.0000, 16.0000, 8000.0000, 58000.0000, 'API', 1);
  END IF;

  -- Factura 3 - Alcaldía Sucre
  IF NOT EXISTS (SELECT 1 FROM ar."SalesDocument" WHERE "DocumentNumber" = 'FACT-2026-00003' AND "OperationType" = 'FACT') THEN
    INSERT INTO ar."SalesDocument" (
      "DocumentNumber", "SerialType", "OperationType",
      "CustomerCode", "CustomerName", "FiscalId",
      "DocumentDate", "DueDate",
      "SubTotal", "TaxableAmount", "TaxAmount", "TaxRate", "TotalAmount",
      "IsPaid", "IsInvoiced", "SellerCode", "CurrencyCode", "ExchangeRate",
      "UserCode", "CreatedByUserId"
    ) VALUES (
      'FACT-2026-00003', 'A', 'FACT',
      'CLT006', 'Alcaldía del Municipio Sucre', 'G-20000123-4',
      '2026-03-08', '2026-04-07',
      250000.0000, 250000.0000, 40000.0000, 16.0000, 290000.0000,
      'N', 'S', 'V002', 'VES', 1.000000,
      'API', 1
    );
    INSERT INTO ar."SalesDocumentLine" ("DocumentNumber", "SerialType", "OperationType", "LineNumber", "ProductCode", "Description", "Quantity", "UnitPrice", "SubTotal", "TaxRate", "TaxAmount", "TotalAmount", "UserCode", "CreatedByUserId")
    VALUES
      ('FACT-2026-00003', 'A', 'FACT', 1, 'PROD020', 'Escritorio ejecutivo madera', 10.0000, 15000.0000, 150000.0000, 16.0000, 24000.0000, 174000.0000, 'API', 1),
      ('FACT-2026-00003', 'A', 'FACT', 2, 'PROD021', 'Silla ergonómica ajustable', 20.0000, 5000.0000, 100000.0000, 16.0000, 16000.0000, 116000.0000, 'API', 1);
  END IF;

  -- Factura 4 - TecnoServicios
  IF NOT EXISTS (SELECT 1 FROM ar."SalesDocument" WHERE "DocumentNumber" = 'FACT-2026-00004' AND "OperationType" = 'FACT') THEN
    INSERT INTO ar."SalesDocument" (
      "DocumentNumber", "SerialType", "OperationType",
      "CustomerCode", "CustomerName", "FiscalId",
      "DocumentDate", "DueDate",
      "SubTotal", "TaxableAmount", "TaxAmount", "TaxRate", "TotalAmount",
      "IsPaid", "IsInvoiced", "SellerCode", "CurrencyCode", "ExchangeRate",
      "UserCode", "CreatedByUserId"
    ) VALUES (
      'FACT-2026-00004', 'A', 'FACT',
      'CLT009', 'TecnoServicios del Caribe C.A.', 'J-50345678-5',
      '2026-03-10', '2026-04-09',
      45000.0000, 45000.0000, 7200.0000, 16.0000, 52200.0000,
      'N', 'S', 'V003', 'VES', 1.000000,
      'API', 1
    );
    INSERT INTO ar."SalesDocumentLine" ("DocumentNumber", "SerialType", "OperationType", "LineNumber", "ProductCode", "Description", "Quantity", "UnitPrice", "SubTotal", "TaxRate", "TaxAmount", "TotalAmount", "UserCode", "CreatedByUserId")
    VALUES
      ('FACT-2026-00004', 'A', 'FACT', 1, 'PROD030', 'Cable UTP Cat6 (caja 305m)', 5.0000, 5000.0000, 25000.0000, 16.0000, 4000.0000, 29000.0000, 'API', 1),
      ('FACT-2026-00004', 'A', 'FACT', 2, 'PROD031', 'Switch 24 puertos PoE', 2.0000, 10000.0000, 20000.0000, 16.0000, 3200.0000, 23200.0000, 'API', 1);
  END IF;

  -- Factura 5 - Restaurante El Fogón Criollo
  IF NOT EXISTS (SELECT 1 FROM ar."SalesDocument" WHERE "DocumentNumber" = 'FACT-2026-00005' AND "OperationType" = 'FACT') THEN
    INSERT INTO ar."SalesDocument" (
      "DocumentNumber", "SerialType", "OperationType",
      "CustomerCode", "CustomerName", "FiscalId",
      "DocumentDate", "DueDate",
      "SubTotal", "TaxableAmount", "TaxAmount", "TaxRate", "TotalAmount",
      "IsPaid", "IsInvoiced", "SellerCode", "CurrencyCode", "ExchangeRate",
      "UserCode", "CreatedByUserId"
    ) VALUES (
      'FACT-2026-00005', 'A', 'FACT',
      'CLT010', 'Restaurante El Fogón Criollo S.R.L.', 'J-41567890-8',
      '2026-03-12', '2026-03-27',
      35000.0000, 35000.0000, 5600.0000, 16.0000, 40600.0000,
      'S', 'S', 'SHOW', 'VES', 1.000000,
      'API', 1
    );
    INSERT INTO ar."SalesDocumentLine" ("DocumentNumber", "SerialType", "OperationType", "LineNumber", "ProductCode", "Description", "Quantity", "UnitPrice", "SubTotal", "TaxRate", "TaxAmount", "TotalAmount", "UserCode", "CreatedByUserId")
    VALUES
      ('FACT-2026-00005', 'A', 'FACT', 1, 'PROD040', 'Horno industrial a gas', 1.0000, 25000.0000, 25000.0000, 16.0000, 4000.0000, 29000.0000, 'API', 1),
      ('FACT-2026-00005', 'A', 'FACT', 2, 'PROD041', 'Juego de ollas acero inox.', 2.0000, 5000.0000, 10000.0000, 16.0000, 1600.0000, 11600.0000, 'API', 1);
  END IF;

  -- ============================================================================
  -- SECCIÓN 5: ar."ReceivableDocument"  (5 CxC)
  -- ============================================================================
  RAISE NOTICE '>> 5. Cuentas por cobrar demo...';

  INSERT INTO ar."ReceivableDocument" ("CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber", "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount", "Status", "CreatedByUserId")
  SELECT 1, 1, c."CustomerId", 'FACTURA', 'FACT-2026-00001', '2026-03-01', '2026-03-31', 'VES', 98600.00, 98600.00, 'PENDING', 1
  FROM master."Customer" c WHERE c."CompanyId" = 1 AND c."CustomerCode" = 'CLT002'
  AND NOT EXISTS (SELECT 1 FROM ar."ReceivableDocument" WHERE "CompanyId" = 1 AND "DocumentType" = 'FACTURA' AND "DocumentNumber" = 'FACT-2026-00001');

  INSERT INTO ar."ReceivableDocument" ("CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber", "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount", "Status", "CreatedByUserId")
  SELECT 1, 1, c."CustomerId", 'FACTURA', 'FACT-2026-00002', '2026-03-05', '2026-04-04', 'VES', 139200.00, 139200.00, 'PENDING', 1
  FROM master."Customer" c WHERE c."CompanyId" = 1 AND c."CustomerCode" = 'CLT004'
  AND NOT EXISTS (SELECT 1 FROM ar."ReceivableDocument" WHERE "CompanyId" = 1 AND "DocumentType" = 'FACTURA' AND "DocumentNumber" = 'FACT-2026-00002');

  INSERT INTO ar."ReceivableDocument" ("CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber", "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount", "Status", "CreatedByUserId")
  SELECT 1, 1, c."CustomerId", 'FACTURA', 'FACT-2026-00003', '2026-03-08', '2026-04-07', 'VES', 290000.00, 290000.00, 'PENDING', 1
  FROM master."Customer" c WHERE c."CompanyId" = 1 AND c."CustomerCode" = 'CLT006'
  AND NOT EXISTS (SELECT 1 FROM ar."ReceivableDocument" WHERE "CompanyId" = 1 AND "DocumentType" = 'FACTURA' AND "DocumentNumber" = 'FACT-2026-00003');

  INSERT INTO ar."ReceivableDocument" ("CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber", "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount", "Status", "CreatedByUserId")
  SELECT 1, 1, c."CustomerId", 'FACTURA', 'FACT-2026-00004', '2026-03-10', '2026-04-09', 'VES', 52200.00, 52200.00, 'PENDING', 1
  FROM master."Customer" c WHERE c."CompanyId" = 1 AND c."CustomerCode" = 'CLT009'
  AND NOT EXISTS (SELECT 1 FROM ar."ReceivableDocument" WHERE "CompanyId" = 1 AND "DocumentType" = 'FACTURA' AND "DocumentNumber" = 'FACT-2026-00004');

  INSERT INTO ar."ReceivableDocument" ("CompanyId", "BranchId", "CustomerId", "DocumentType", "DocumentNumber", "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount", "PaidFlag", "Status", "CreatedByUserId")
  SELECT 1, 1, c."CustomerId", 'FACTURA', 'FACT-2026-00005', '2026-03-12', '2026-03-27', 'VES', 40600.00, 0.00, TRUE, 'PAID', 1
  FROM master."Customer" c WHERE c."CompanyId" = 1 AND c."CustomerCode" = 'CLT010'
  AND NOT EXISTS (SELECT 1 FROM ar."ReceivableDocument" WHERE "CompanyId" = 1 AND "DocumentType" = 'FACTURA' AND "DocumentNumber" = 'FACT-2026-00005');

  -- ============================================================================
  -- SECCIÓN 6: ap."PurchaseDocument" + ap."PurchaseDocumentLine"  (3 compras)
  -- ============================================================================
  RAISE NOTICE '>> 6. Documentos de compra demo...';

  -- Compra 1 - Proveedor de materiales
  IF NOT EXISTS (SELECT 1 FROM ap."PurchaseDocument" WHERE "DocumentNumber" = 'OC-2026-00001' AND "OperationType" = 'COMPRA') THEN
    INSERT INTO ap."PurchaseDocument" (
      "DocumentNumber", "SerialType", "OperationType",
      "SupplierCode", "SupplierName", "FiscalId",
      "DocumentDate", "DueDate",
      "SubTotal", "TaxableAmount", "TaxAmount", "TaxRate", "TotalAmount",
      "IsPaid", "IsReceived", "WarehouseCode", "CurrencyCode", "ExchangeRate",
      "UserCode", "CreatedByUserId"
    ) VALUES (
      'OC-2026-00001', 'A', 'COMPRA',
      'PROV001', 'Distribuidora de Materiales C.A.', 'J-12345678-0',
      '2026-02-25', '2026-03-27',
      62000.0000, 62000.0000, 9920.0000, 16.0000, 71920.0000,
      'N', 'S', 'PRINCIPAL', 'VES', 1.000000,
      'API', 1
    );
    INSERT INTO ap."PurchaseDocumentLine" ("DocumentNumber", "SerialType", "OperationType", "LineNumber", "ProductCode", "Description", "Quantity", "UnitPrice", "UnitCost", "SubTotal", "TaxRate", "TaxAmount", "TotalAmount", "UserCode", "CreatedByUserId")
    VALUES
      ('OC-2026-00001', 'A', 'COMPRA', 1, 'PROD001', 'Cemento Portland 42.5 kg', 80.0000, 500.0000, 500.0000, 40000.0000, 16.0000, 6400.0000, 46400.0000, 'API', 1),
      ('OC-2026-00001', 'A', 'COMPRA', 2, 'PROD002', 'Cabilla 1/2" x 12m', 80.0000, 275.0000, 275.0000, 22000.0000, 16.0000, 3520.0000, 25520.0000, 'API', 1);
  END IF;

  -- Compra 2 - Proveedor de alimentos
  IF NOT EXISTS (SELECT 1 FROM ap."PurchaseDocument" WHERE "DocumentNumber" = 'OC-2026-00002' AND "OperationType" = 'COMPRA') THEN
    INSERT INTO ap."PurchaseDocument" (
      "DocumentNumber", "SerialType", "OperationType",
      "SupplierCode", "SupplierName", "FiscalId",
      "DocumentDate", "DueDate",
      "SubTotal", "TaxableAmount", "TaxAmount", "TaxRate", "TotalAmount",
      "IsPaid", "IsReceived", "WarehouseCode", "CurrencyCode", "ExchangeRate",
      "UserCode", "CreatedByUserId"
    ) VALUES (
      'OC-2026-00002', 'A', 'COMPRA',
      'PROV002', 'Alimentos del Centro S.A.', 'J-23456789-1',
      '2026-03-01', '2026-03-31',
      95000.0000, 95000.0000, 15200.0000, 16.0000, 110200.0000,
      'N', 'S', 'PRINCIPAL', 'VES', 1.000000,
      'API', 1
    );
    INSERT INTO ap."PurchaseDocumentLine" ("DocumentNumber", "SerialType", "OperationType", "LineNumber", "ProductCode", "Description", "Quantity", "UnitPrice", "UnitCost", "SubTotal", "TaxRate", "TaxAmount", "TotalAmount", "UserCode", "CreatedByUserId")
    VALUES
      ('OC-2026-00002', 'A', 'COMPRA', 1, 'PROD010', 'Aceite vegetal 1L (caja x12)', 300.0000, 200.0000, 200.0000, 60000.0000, 16.0000, 9600.0000, 69600.0000, 'API', 1),
      ('OC-2026-00002', 'A', 'COMPRA', 2, 'PROD011', 'Harina precocida 1kg', 700.0000, 50.0000, 50.0000, 35000.0000, 16.0000, 5600.0000, 40600.0000, 'API', 1);
  END IF;

  -- Compra 3 - Proveedor de tecnología
  IF NOT EXISTS (SELECT 1 FROM ap."PurchaseDocument" WHERE "DocumentNumber" = 'OC-2026-00003' AND "OperationType" = 'COMPRA') THEN
    INSERT INTO ap."PurchaseDocument" (
      "DocumentNumber", "SerialType", "OperationType",
      "SupplierCode", "SupplierName", "FiscalId",
      "DocumentDate", "DueDate",
      "SubTotal", "TaxableAmount", "TaxAmount", "TaxRate", "TotalAmount",
      "IsPaid", "IsReceived", "WarehouseCode", "CurrencyCode", "ExchangeRate",
      "UserCode", "CreatedByUserId"
    ) VALUES (
      'OC-2026-00003', 'A', 'COMPRA',
      'PROV003', 'Importadora TechVen C.A.', 'J-34567890-2',
      '2026-03-05', '2026-04-04',
      38000.0000, 38000.0000, 6080.0000, 16.0000, 44080.0000,
      'S', 'S', 'PRINCIPAL', 'VES', 1.000000,
      'API', 1
    );
    INSERT INTO ap."PurchaseDocumentLine" ("DocumentNumber", "SerialType", "OperationType", "LineNumber", "ProductCode", "Description", "Quantity", "UnitPrice", "UnitCost", "SubTotal", "TaxRate", "TaxAmount", "TotalAmount", "UserCode", "CreatedByUserId")
    VALUES
      ('OC-2026-00003', 'A', 'COMPRA', 1, 'PROD030', 'Cable UTP Cat6 (caja 305m)', 10.0000, 2800.0000, 2800.0000, 28000.0000, 16.0000, 4480.0000, 32480.0000, 'API', 1),
      ('OC-2026-00003', 'A', 'COMPRA', 2, 'PROD031', 'Switch 24 puertos PoE', 2.0000, 5000.0000, 5000.0000, 10000.0000, 16.0000, 1600.0000, 11600.0000, 'API', 1);
  END IF;

  -- ============================================================================
  -- SECCIÓN 7: ap."PayableDocument"  (3 CxP)
  -- ============================================================================
  RAISE NOTICE '>> 7. Cuentas por pagar demo...';

  INSERT INTO ap."PayableDocument" ("CompanyId", "BranchId", "SupplierId", "DocumentType", "DocumentNumber", "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount", "Status", "CreatedByUserId")
  SELECT 1, 1, s."SupplierId", 'COMPRA', 'OC-2026-00001', '2026-02-25', '2026-03-27', 'VES', 71920.00, 71920.00, 'PENDING', 1
  FROM master."Supplier" s WHERE s."CompanyId" = 1 AND s."SupplierCode" = 'PROV001'
  AND NOT EXISTS (SELECT 1 FROM ap."PayableDocument" WHERE "CompanyId" = 1 AND "DocumentType" = 'COMPRA' AND "DocumentNumber" = 'OC-2026-00001');

  INSERT INTO ap."PayableDocument" ("CompanyId", "BranchId", "SupplierId", "DocumentType", "DocumentNumber", "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount", "Status", "CreatedByUserId")
  SELECT 1, 1, s."SupplierId", 'COMPRA', 'OC-2026-00002', '2026-03-01', '2026-03-31', 'VES', 110200.00, 110200.00, 'PENDING', 1
  FROM master."Supplier" s WHERE s."CompanyId" = 1 AND s."SupplierCode" = 'PROV002'
  AND NOT EXISTS (SELECT 1 FROM ap."PayableDocument" WHERE "CompanyId" = 1 AND "DocumentType" = 'COMPRA' AND "DocumentNumber" = 'OC-2026-00002');

  INSERT INTO ap."PayableDocument" ("CompanyId", "BranchId", "SupplierId", "DocumentType", "DocumentNumber", "IssueDate", "DueDate", "CurrencyCode", "TotalAmount", "PendingAmount", "PaidFlag", "Status", "CreatedByUserId")
  SELECT 1, 1, s."SupplierId", 'COMPRA', 'OC-2026-00003', '2026-03-05', '2026-04-04', 'VES', 44080.00, 0.00, TRUE, 'PAID', 1
  FROM master."Supplier" s WHERE s."CompanyId" = 1 AND s."SupplierCode" = 'PROV003'
  AND NOT EXISTS (SELECT 1 FROM ap."PayableDocument" WHERE "CompanyId" = 1 AND "DocumentType" = 'COMPRA' AND "DocumentNumber" = 'OC-2026-00003');

  -- ============================================================================
  -- SECCIÓN 8: master."InventoryMovement"  (20 movimientos)
  -- ============================================================================
  RAISE NOTICE '>> 8. Movimientos de inventario demo...';

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD001', 'Cemento Portland 42.5 kg', 'OC-2026-00001', 'ENTRADA', '2026-02-26', 80.0000, 500.0000, 40000.0000, 'Recepción compra OC-2026-00001', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD002', 'Cabilla 1/2" x 12m', 'OC-2026-00001', 'ENTRADA', '2026-02-26', 80.0000, 275.0000, 22000.0000, 'Recepción compra OC-2026-00001', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD010', 'Aceite vegetal 1L (caja x12)', 'OC-2026-00002', 'ENTRADA', '2026-03-02', 300.0000, 200.0000, 60000.0000, 'Recepción compra OC-2026-00002', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD011', 'Harina precocida 1kg', 'OC-2026-00002', 'ENTRADA', '2026-03-02', 700.0000, 50.0000, 35000.0000, 'Recepción compra OC-2026-00002', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD030', 'Cable UTP Cat6 (caja 305m)', 'OC-2026-00003', 'ENTRADA', '2026-03-06', 10.0000, 2800.0000, 28000.0000, 'Recepción compra OC-2026-00003', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD031', 'Switch 24 puertos PoE', 'OC-2026-00003', 'ENTRADA', '2026-03-06', 2.0000, 5000.0000, 10000.0000, 'Recepción compra OC-2026-00003', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD020', 'Escritorio ejecutivo madera', 'AJUSTE-INV-001', 'ENTRADA', '2026-02-15', 15.0000, 10000.0000, 150000.0000, 'Inventario inicial - ajuste', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD021', 'Silla ergonómica ajustable', 'AJUSTE-INV-001', 'ENTRADA', '2026-02-15', 30.0000, 3500.0000, 105000.0000, 'Inventario inicial - ajuste', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD040', 'Horno industrial a gas', 'AJUSTE-INV-001', 'ENTRADA', '2026-02-15', 3.0000, 18000.0000, 54000.0000, 'Inventario inicial - ajuste', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD041', 'Juego de ollas acero inox.', 'AJUSTE-INV-001', 'ENTRADA', '2026-02-15', 10.0000, 3500.0000, 35000.0000, 'Inventario inicial - ajuste', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD001', 'Cemento Portland 42.5 kg', 'FACT-2026-00001', 'SALIDA', '2026-03-01', 50.0000, 500.0000, 25000.0000, 'Despacho factura FACT-2026-00001', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD002', 'Cabilla 1/2" x 12m', 'FACT-2026-00001', 'SALIDA', '2026-03-01', 100.0000, 275.0000, 27500.0000, 'Despacho factura FACT-2026-00001', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD010', 'Aceite vegetal 1L (caja x12)', 'FACT-2026-00002', 'SALIDA', '2026-03-05', 200.0000, 200.0000, 40000.0000, 'Despacho factura FACT-2026-00002', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD011', 'Harina precocida 1kg', 'FACT-2026-00002', 'SALIDA', '2026-03-05', 500.0000, 50.0000, 25000.0000, 'Despacho factura FACT-2026-00002', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD020', 'Escritorio ejecutivo madera', 'FACT-2026-00003', 'SALIDA', '2026-03-08', 10.0000, 10000.0000, 100000.0000, 'Despacho factura FACT-2026-00003', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD021', 'Silla ergonómica ajustable', 'FACT-2026-00003', 'SALIDA', '2026-03-08', 20.0000, 3500.0000, 70000.0000, 'Despacho factura FACT-2026-00003', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD030', 'Cable UTP Cat6 (caja 305m)', 'FACT-2026-00004', 'SALIDA', '2026-03-10', 5.0000, 2800.0000, 14000.0000, 'Despacho factura FACT-2026-00004', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD040', 'Horno industrial a gas', 'FACT-2026-00005', 'SALIDA', '2026-03-12', 1.0000, 18000.0000, 18000.0000, 'Despacho factura FACT-2026-00005', 1)
  ON CONFLICT DO NOTHING;

  INSERT INTO master."InventoryMovement" ("CompanyId", "BranchId", "ProductCode", "ProductName", "DocumentRef", "MovementType", "MovementDate", "Quantity", "UnitCost", "TotalCost", "Notes", "CreatedByUserId")
  VALUES (1, 1, 'PROD041', 'Juego de ollas acero inox.', 'FACT-2026-00005', 'SALIDA', '2026-03-12', 2.0000, 3500.0000, 7000.0000, 'Despacho factura FACT-2026-00005', 1)
  ON CONFLICT DO NOTHING;

  RAISE NOTICE '=== Seed completado ===';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed_demo_clientes_documentos.sql: %', SQLERRM;
  RAISE;
END $$;
