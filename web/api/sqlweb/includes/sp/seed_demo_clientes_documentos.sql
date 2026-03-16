/*
 * seed_demo_clientes_documentos.sql
 * ──────────────────────────────────
 * Seed de datos demo para módulos comerciales/transaccionales.
 * Idempotente: verifica existencia antes de cada INSERT.
 *
 * Tablas afectadas:
 *   master.Customer, master.CustomerAddress, master.CustomerPaymentMethod,
 *   ar.SalesDocument, ar.SalesDocumentLine, ar.ReceivableDocument,
 *   ap.PurchaseDocument, ap.PurchaseDocumentLine, ap.PayableDocument,
 *   master.InventoryMovement
 */
USE DatqBoxWeb;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

SET NOCOUNT ON;
GO

PRINT '=== Seed demo: Clientes y Documentos Comerciales ===';
GO

-- ============================================================================
-- SECCIÓN 1: master.Customer  (agregar 9 clientes → total 10)
-- ============================================================================
PRINT '>> 1. Clientes demo...';

IF (SELECT COUNT(*) FROM [master].Customer WHERE CompanyId = 1 AND IsDeleted = 0) < 10
BEGIN
  -- CLT002 – Empresa constructora
  IF NOT EXISTS (SELECT 1 FROM [master].Customer WHERE CompanyId = 1 AND CustomerCode = N'CLT002')
    INSERT INTO [master].Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, IsActive, CreatedByUserId)
    VALUES (1, N'CLT002', N'Constructora Bolívar C.A.', N'J-30123456-7', N'admin@constructorabvr.ve', N'+58-212-5551234', N'Av. Libertador, Torre Delta, Piso 8, Caracas', 500000.00, 1, 1);

  -- CLT003 – Persona natural
  IF NOT EXISTS (SELECT 1 FROM [master].Customer WHERE CompanyId = 1 AND CustomerCode = N'CLT003')
    INSERT INTO [master].Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, IsActive, CreatedByUserId)
    VALUES (1, N'CLT003', N'María del Carmen Rodríguez', N'V-12345678-9', N'maria.rodriguez@gmail.com', N'+58-414-3210001', N'Urb. El Paraíso, Calle 4, Casa 12, Maracaibo', 100000.00, 1, 1);

  -- CLT004 – Corporación
  IF NOT EXISTS (SELECT 1 FROM [master].Customer WHERE CompanyId = 1 AND CustomerCode = N'CLT004')
    INSERT INTO [master].Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, IsActive, CreatedByUserId)
    VALUES (1, N'CLT004', N'Grupo Alimenticio Oriente S.A.', N'J-40234567-0', N'ventas@grupoalioriente.com', N'+58-281-2654321', N'Zona Industrial Los Montones, Galpón 3, Barcelona', 750000.00, 1, 1);

  -- CLT005 – Persona natural
  IF NOT EXISTS (SELECT 1 FROM [master].Customer WHERE CompanyId = 1 AND CustomerCode = N'CLT005')
    INSERT INTO [master].Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, IsActive, CreatedByUserId)
    VALUES (1, N'CLT005', N'José Antonio Pérez Mendoza', N'V-9876543-2', N'japerez@hotmail.com', N'+58-412-5550088', N'Calle Bolívar cruce con Sucre, Local 5, Valencia', 80000.00, 1, 1);

  -- CLT006 – Gobierno
  IF NOT EXISTS (SELECT 1 FROM [master].Customer WHERE CompanyId = 1 AND CustomerCode = N'CLT006')
    INSERT INTO [master].Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, IsActive, CreatedByUserId)
    VALUES (1, N'CLT006', N'Alcaldía del Municipio Sucre', N'G-20000123-4', N'compras@alcaldiasucre.gob.ve', N'+58-212-9990001', N'Av. Francisco de Miranda, Edif. Municipal, Petare', 1000000.00, 1, 1);

  -- CLT007 – Farmacia
  IF NOT EXISTS (SELECT 1 FROM [master].Customer WHERE CompanyId = 1 AND CustomerCode = N'CLT007')
    INSERT INTO [master].Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, IsActive, CreatedByUserId)
    VALUES (1, N'CLT007', N'Farmacia Santa Elena C.A.', N'J-31456789-1', N'pedidos@farmaciasantaelena.ve', N'+58-243-2340567', N'Av. Constitución No. 45, Maracay', 200000.00, 1, 1);

  -- CLT008 – Persona natural
  IF NOT EXISTS (SELECT 1 FROM [master].Customer WHERE CompanyId = 1 AND CustomerCode = N'CLT008')
    INSERT INTO [master].Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, IsActive, CreatedByUserId)
    VALUES (1, N'CLT008', N'Ana Gabriela Torres Linares', N'V-15678901-3', N'anatorres@gmail.com', N'+58-416-8882233', N'Res. Los Samanes, Torre B, Apto 7-C, Barquisimeto', 60000.00, 1, 1);

  -- CLT009 – Tecnología
  IF NOT EXISTS (SELECT 1 FROM [master].Customer WHERE CompanyId = 1 AND CustomerCode = N'CLT009')
    INSERT INTO [master].Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, IsActive, CreatedByUserId)
    VALUES (1, N'CLT009', N'TecnoServicios del Caribe C.A.', N'J-50345678-5', N'info@tecnocaribe.com', N'+58-261-7654321', N'C.C. Lago Mall, Nivel PB, Local 22, Maracaibo', 350000.00, 1, 1);

  -- CLT010 – Restaurante
  IF NOT EXISTS (SELECT 1 FROM [master].Customer WHERE CompanyId = 1 AND CustomerCode = N'CLT010')
    INSERT INTO [master].Customer (CompanyId, CustomerCode, CustomerName, FiscalId, Email, Phone, AddressLine, CreditLimit, IsActive, CreatedByUserId)
    VALUES (1, N'CLT010', N'Restaurante El Fogón Criollo S.R.L.', N'J-41567890-8', N'reservas@elfogoncriollo.ve', N'+58-212-7773344', N'Av. Baralt, Edif. La Candelaria, PB, Caracas', 150000.00, 1, 1);
END;
GO

-- ============================================================================
-- SECCIÓN 2: master.CustomerAddress  (2-3 por cliente)
-- ============================================================================
PRINT '>> 2. Direcciones de clientes demo...';

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT002' AND Label = N'Oficina Principal')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT002', N'Oficina Principal', N'Constructora Bolívar C.A.', N'+58-212-5551234', N'Av. Libertador, Torre Delta, Piso 8', N'Caracas', N'Distrito Capital', N'1010', N'Venezuela', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT002' AND Label = N'Almacén Obras')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT002', N'Almacén Obras', N'Ing. Carlos Mejía', N'+58-212-5551235', N'Zona Industrial La Yaguara, Galpón 7', N'Caracas', N'Distrito Capital', N'1020', N'Venezuela', 0);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT003' AND Label = N'Casa')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT003', N'Casa', N'María del Carmen Rodríguez', N'+58-414-3210001', N'Urb. El Paraíso, Calle 4, Casa 12', N'Maracaibo', N'Zulia', N'4001', N'Venezuela', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT004' AND Label = N'Sede Principal')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT004', N'Sede Principal', N'Grupo Alimenticio Oriente S.A.', N'+58-281-2654321', N'Zona Industrial Los Montones, Galpón 3', N'Barcelona', N'Anzoátegui', N'6001', N'Venezuela', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT004' AND Label = N'Punto de Distribución')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT004', N'Punto de Distribución', N'Logística Oriente', N'+58-281-2654322', N'Av. Intercomunal, Km 5, Galpón 12', N'Puerto La Cruz', N'Anzoátegui', N'6023', N'Venezuela', 0);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT005' AND Label = N'Local Comercial')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT005', N'Local Comercial', N'José Antonio Pérez', N'+58-412-5550088', N'Calle Bolívar cruce con Sucre, Local 5', N'Valencia', N'Carabobo', N'2001', N'Venezuela', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT006' AND Label = N'Edificio Municipal')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT006', N'Edificio Municipal', N'Dpto. de Compras - Alcaldía Sucre', N'+58-212-9990001', N'Av. Francisco de Miranda, Edif. Municipal', N'Petare', N'Miranda', N'1073', N'Venezuela', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT007' AND Label = N'Farmacia Sede')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT007', N'Farmacia Sede', N'Farmacia Santa Elena C.A.', N'+58-243-2340567', N'Av. Constitución No. 45', N'Maracay', N'Aragua', N'2101', N'Venezuela', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT007' AND Label = N'Sucursal Sur')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT007', N'Sucursal Sur', N'Farmacia Santa Elena - Sucursal', N'+58-243-2340999', N'Av. Las Delicias, C.C. Hiper Jumbo, Local 4', N'Maracay', N'Aragua', N'2103', N'Venezuela', 0);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT008' AND Label = N'Residencia')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT008', N'Residencia', N'Ana Gabriela Torres', N'+58-416-8882233', N'Res. Los Samanes, Torre B, Apto 7-C', N'Barquisimeto', N'Lara', N'3001', N'Venezuela', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT009' AND Label = N'Oficina Comercial')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT009', N'Oficina Comercial', N'TecnoServicios del Caribe C.A.', N'+58-261-7654321', N'C.C. Lago Mall, Nivel PB, Local 22', N'Maracaibo', N'Zulia', N'4001', N'Venezuela', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT009' AND Label = N'Depósito')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT009', N'Depósito', N'Almacén TecnoCaribe', N'+58-261-7654322', N'Av. 5 de Julio, Galpón 15-B', N'Maracaibo', N'Zulia', N'4002', N'Venezuela', 0);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT010' AND Label = N'Restaurante')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT010', N'Restaurante', N'Restaurante El Fogón Criollo', N'+58-212-7773344', N'Av. Baralt, Edif. La Candelaria, PB', N'Caracas', N'Distrito Capital', N'1010', N'Venezuela', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerAddress WHERE CompanyId = 1 AND CustomerCode = N'CLT010' AND Label = N'Cocina Central')
  INSERT INTO [master].CustomerAddress (CompanyId, CustomerCode, Label, RecipientName, Phone, AddressLine, City, [State], ZipCode, Country, IsDefault)
  VALUES (1, N'CLT010', N'Cocina Central', N'Chef Marcos Salazar', N'+58-212-7773345', N'Calle Carabobo con Av. Universidad, Local 8', N'Caracas', N'Distrito Capital', N'1010', N'Venezuela', 0);
GO

-- ============================================================================
-- SECCIÓN 3: master.CustomerPaymentMethod  (1-2 por cliente)
-- ============================================================================
PRINT '>> 3. Métodos de pago de clientes demo...';

IF NOT EXISTS (SELECT 1 FROM [master].CustomerPaymentMethod WHERE CompanyId = 1 AND CustomerCode = N'CLT002' AND MethodType = N'TRANSFER')
  INSERT INTO [master].CustomerPaymentMethod (CompanyId, CustomerCode, MethodType, Label, BankName, AccountNumber, HolderName, HolderFiscalId, IsDefault)
  VALUES (1, N'CLT002', N'TRANSFER', N'Banesco Jurídica', N'Banesco', N'01340123456789012345', N'Constructora Bolívar C.A.', N'J-30123456-7', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerPaymentMethod WHERE CompanyId = 1 AND CustomerCode = N'CLT003' AND MethodType = N'MOBILE_PAY')
  INSERT INTO [master].CustomerPaymentMethod (CompanyId, CustomerCode, MethodType, Label, BankName, AccountPhone, HolderName, HolderFiscalId, IsDefault)
  VALUES (1, N'CLT003', N'MOBILE_PAY', N'Pago Móvil BDV', N'Banco de Venezuela', N'04143210001', N'María del Carmen Rodríguez', N'V-12345678-9', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerPaymentMethod WHERE CompanyId = 1 AND CustomerCode = N'CLT004' AND MethodType = N'TRANSFER')
  INSERT INTO [master].CustomerPaymentMethod (CompanyId, CustomerCode, MethodType, Label, BankName, AccountNumber, HolderName, HolderFiscalId, IsDefault)
  VALUES (1, N'CLT004', N'TRANSFER', N'Provincial Empresarial', N'BBVA Provincial', N'01080234567890123456', N'Grupo Alimenticio Oriente S.A.', N'J-40234567-0', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerPaymentMethod WHERE CompanyId = 1 AND CustomerCode = N'CLT004' AND MethodType = N'CHECK')
  INSERT INTO [master].CustomerPaymentMethod (CompanyId, CustomerCode, MethodType, Label, BankName, AccountNumber, HolderName, HolderFiscalId, IsDefault)
  VALUES (1, N'CLT004', N'CHECK', N'Cheque Provincial', N'BBVA Provincial', N'01080234567890123456', N'Grupo Alimenticio Oriente S.A.', N'J-40234567-0', 0);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerPaymentMethod WHERE CompanyId = 1 AND CustomerCode = N'CLT005' AND MethodType = N'MOBILE_PAY')
  INSERT INTO [master].CustomerPaymentMethod (CompanyId, CustomerCode, MethodType, Label, BankName, AccountPhone, HolderName, HolderFiscalId, IsDefault)
  VALUES (1, N'CLT005', N'MOBILE_PAY', N'Pago Móvil Mercantil', N'Mercantil', N'04125550088', N'José Antonio Pérez Mendoza', N'V-9876543-2', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerPaymentMethod WHERE CompanyId = 1 AND CustomerCode = N'CLT006' AND MethodType = N'TRANSFER')
  INSERT INTO [master].CustomerPaymentMethod (CompanyId, CustomerCode, MethodType, Label, BankName, AccountNumber, HolderName, HolderFiscalId, IsDefault)
  VALUES (1, N'CLT006', N'TRANSFER', N'Tesoro Nacional', N'Banco del Tesoro', N'01630200001234567890', N'Alcaldía del Municipio Sucre', N'G-20000123-4', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerPaymentMethod WHERE CompanyId = 1 AND CustomerCode = N'CLT007' AND MethodType = N'TRANSFER')
  INSERT INTO [master].CustomerPaymentMethod (CompanyId, CustomerCode, MethodType, Label, BankName, AccountNumber, HolderName, HolderFiscalId, IsDefault)
  VALUES (1, N'CLT007', N'TRANSFER', N'BOD Farmacia', N'BOD', N'01160456789012345678', N'Farmacia Santa Elena C.A.', N'J-31456789-1', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerPaymentMethod WHERE CompanyId = 1 AND CustomerCode = N'CLT008' AND MethodType = N'MOBILE_PAY')
  INSERT INTO [master].CustomerPaymentMethod (CompanyId, CustomerCode, MethodType, Label, BankName, AccountPhone, HolderName, HolderFiscalId, IsDefault)
  VALUES (1, N'CLT008', N'MOBILE_PAY', N'Pago Móvil Banesco', N'Banesco', N'04168882233', N'Ana Gabriela Torres Linares', N'V-15678901-3', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerPaymentMethod WHERE CompanyId = 1 AND CustomerCode = N'CLT009' AND MethodType = N'TRANSFER')
  INSERT INTO [master].CustomerPaymentMethod (CompanyId, CustomerCode, MethodType, Label, BankName, AccountNumber, HolderName, HolderFiscalId, IsDefault)
  VALUES (1, N'CLT009', N'TRANSFER', N'Mercantil Empresarial', N'Mercantil', N'01050567890123456789', N'TecnoServicios del Caribe C.A.', N'J-50345678-5', 1);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerPaymentMethod WHERE CompanyId = 1 AND CustomerCode = N'CLT009' AND MethodType = N'ZELLE')
  INSERT INTO [master].CustomerPaymentMethod (CompanyId, CustomerCode, MethodType, Label, AccountEmail, HolderName, IsDefault)
  VALUES (1, N'CLT009', N'ZELLE', N'Zelle USD', N'payments@tecnocaribe.com', N'TecnoServicios del Caribe C.A.', 0);

IF NOT EXISTS (SELECT 1 FROM [master].CustomerPaymentMethod WHERE CompanyId = 1 AND CustomerCode = N'CLT010' AND MethodType = N'MOBILE_PAY')
  INSERT INTO [master].CustomerPaymentMethod (CompanyId, CustomerCode, MethodType, Label, BankName, AccountPhone, HolderName, HolderFiscalId, IsDefault)
  VALUES (1, N'CLT010', N'MOBILE_PAY', N'Pago Móvil Venezuela', N'Banco de Venezuela', N'04127773344', N'El Fogón Criollo S.R.L.', N'J-41567890-8', 1);
GO

-- ============================================================================
-- SECCIÓN 4: ar.SalesDocument + ar.SalesDocumentLine  (5 facturas demo)
-- ============================================================================
PRINT '>> 4. Documentos de venta demo...';

-- Factura 1 - Constructora Bolívar
IF NOT EXISTS (SELECT 1 FROM ar.SalesDocument WHERE DocumentNumber = N'FACT-2026-00001' AND OperationType = N'FACT')
BEGIN
  INSERT INTO ar.SalesDocument (
    DocumentNumber, SerialType, OperationType,
    CustomerCode, CustomerName, FiscalId,
    DocumentDate, DueDate,
    SubTotal, TaxableAmount, TaxAmount, TaxRate, TotalAmount,
    IsPaid, IsInvoiced, SellerCode, CurrencyCode, ExchangeRate,
    UserCode, CreatedByUserId
  ) VALUES (
    N'FACT-2026-00001', N'A', N'FACT',
    N'CLT002', N'Constructora Bolívar C.A.', N'J-30123456-7',
    '2026-03-01', '2026-03-31',
    85000.0000, 85000.0000, 13600.0000, 16.0000, 98600.0000,
    N'N', N'S', N'V001', N'VES', 1.000000,
    N'API', 1
  );

  INSERT INTO ar.SalesDocumentLine (DocumentNumber, SerialType, OperationType, LineNumber, ProductCode, Description, Quantity, UnitPrice, SubTotal, TaxRate, TaxAmount, TotalAmount, UserCode, CreatedByUserId)
  VALUES
    (N'FACT-2026-00001', N'A', N'FACT', 1, N'PROD001', N'Cemento Portland 42.5 kg', 50.0000, 800.0000, 40000.0000, 16.0000, 6400.0000, 46400.0000, N'API', 1),
    (N'FACT-2026-00001', N'A', N'FACT', 2, N'PROD002', N'Cabilla 1/2" x 12m', 100.0000, 450.0000, 45000.0000, 16.0000, 7200.0000, 52200.0000, N'API', 1);
END;
GO

-- Factura 2 - Grupo Alimenticio Oriente
IF NOT EXISTS (SELECT 1 FROM ar.SalesDocument WHERE DocumentNumber = N'FACT-2026-00002' AND OperationType = N'FACT')
BEGIN
  INSERT INTO ar.SalesDocument (
    DocumentNumber, SerialType, OperationType,
    CustomerCode, CustomerName, FiscalId,
    DocumentDate, DueDate,
    SubTotal, TaxableAmount, TaxAmount, TaxRate, TotalAmount,
    IsPaid, IsInvoiced, SellerCode, CurrencyCode, ExchangeRate,
    UserCode, CreatedByUserId
  ) VALUES (
    N'FACT-2026-00002', N'A', N'FACT',
    N'CLT004', N'Grupo Alimenticio Oriente S.A.', N'J-40234567-0',
    '2026-03-05', '2026-04-04',
    120000.0000, 120000.0000, 19200.0000, 16.0000, 139200.0000,
    N'N', N'S', N'V002', N'VES', 1.000000,
    N'API', 1
  );

  INSERT INTO ar.SalesDocumentLine (DocumentNumber, SerialType, OperationType, LineNumber, ProductCode, Description, Quantity, UnitPrice, SubTotal, TaxRate, TaxAmount, TotalAmount, UserCode, CreatedByUserId)
  VALUES
    (N'FACT-2026-00002', N'A', N'FACT', 1, N'PROD010', N'Aceite vegetal 1L (caja x12)', 200.0000, 350.0000, 70000.0000, 16.0000, 11200.0000, 81200.0000, N'API', 1),
    (N'FACT-2026-00002', N'A', N'FACT', 2, N'PROD011', N'Harina precocida 1kg', 500.0000, 100.0000, 50000.0000, 16.0000, 8000.0000, 58000.0000, N'API', 1);
END;
GO

-- Factura 3 - Alcaldía Sucre
IF NOT EXISTS (SELECT 1 FROM ar.SalesDocument WHERE DocumentNumber = N'FACT-2026-00003' AND OperationType = N'FACT')
BEGIN
  INSERT INTO ar.SalesDocument (
    DocumentNumber, SerialType, OperationType,
    CustomerCode, CustomerName, FiscalId,
    DocumentDate, DueDate,
    SubTotal, TaxableAmount, TaxAmount, TaxRate, TotalAmount,
    IsPaid, IsInvoiced, SellerCode, CurrencyCode, ExchangeRate,
    UserCode, CreatedByUserId
  ) VALUES (
    N'FACT-2026-00003', N'A', N'FACT',
    N'CLT006', N'Alcaldía del Municipio Sucre', N'G-20000123-4',
    '2026-03-08', '2026-04-07',
    250000.0000, 250000.0000, 40000.0000, 16.0000, 290000.0000,
    N'N', N'S', N'V002', N'VES', 1.000000,
    N'API', 1
  );

  INSERT INTO ar.SalesDocumentLine (DocumentNumber, SerialType, OperationType, LineNumber, ProductCode, Description, Quantity, UnitPrice, SubTotal, TaxRate, TaxAmount, TotalAmount, UserCode, CreatedByUserId)
  VALUES
    (N'FACT-2026-00003', N'A', N'FACT', 1, N'PROD020', N'Escritorio ejecutivo madera', 10.0000, 15000.0000, 150000.0000, 16.0000, 24000.0000, 174000.0000, N'API', 1),
    (N'FACT-2026-00003', N'A', N'FACT', 2, N'PROD021', N'Silla ergonómica ajustable', 20.0000, 5000.0000, 100000.0000, 16.0000, 16000.0000, 116000.0000, N'API', 1);
END;
GO

-- Factura 4 - TecnoServicios (USD)
IF NOT EXISTS (SELECT 1 FROM ar.SalesDocument WHERE DocumentNumber = N'FACT-2026-00004' AND OperationType = N'FACT')
BEGIN
  INSERT INTO ar.SalesDocument (
    DocumentNumber, SerialType, OperationType,
    CustomerCode, CustomerName, FiscalId,
    DocumentDate, DueDate,
    SubTotal, TaxableAmount, TaxAmount, TaxRate, TotalAmount,
    IsPaid, IsInvoiced, SellerCode, CurrencyCode, ExchangeRate,
    UserCode, CreatedByUserId
  ) VALUES (
    N'FACT-2026-00004', N'A', N'FACT',
    N'CLT009', N'TecnoServicios del Caribe C.A.', N'J-50345678-5',
    '2026-03-10', '2026-04-09',
    45000.0000, 45000.0000, 7200.0000, 16.0000, 52200.0000,
    N'N', N'S', N'V003', N'VES', 1.000000,
    N'API', 1
  );

  INSERT INTO ar.SalesDocumentLine (DocumentNumber, SerialType, OperationType, LineNumber, ProductCode, Description, Quantity, UnitPrice, SubTotal, TaxRate, TaxAmount, TotalAmount, UserCode, CreatedByUserId)
  VALUES
    (N'FACT-2026-00004', N'A', N'FACT', 1, N'PROD030', N'Cable UTP Cat6 (caja 305m)', 5.0000, 5000.0000, 25000.0000, 16.0000, 4000.0000, 29000.0000, N'API', 1),
    (N'FACT-2026-00004', N'A', N'FACT', 2, N'PROD031', N'Switch 24 puertos PoE', 2.0000, 10000.0000, 20000.0000, 16.0000, 3200.0000, 23200.0000, N'API', 1);
END;
GO

-- Factura 5 - Restaurante El Fogón Criollo
IF NOT EXISTS (SELECT 1 FROM ar.SalesDocument WHERE DocumentNumber = N'FACT-2026-00005' AND OperationType = N'FACT')
BEGIN
  INSERT INTO ar.SalesDocument (
    DocumentNumber, SerialType, OperationType,
    CustomerCode, CustomerName, FiscalId,
    DocumentDate, DueDate,
    SubTotal, TaxableAmount, TaxAmount, TaxRate, TotalAmount,
    IsPaid, IsInvoiced, SellerCode, CurrencyCode, ExchangeRate,
    UserCode, CreatedByUserId
  ) VALUES (
    N'FACT-2026-00005', N'A', N'FACT',
    N'CLT010', N'Restaurante El Fogón Criollo S.R.L.', N'J-41567890-8',
    '2026-03-12', '2026-03-27',
    35000.0000, 35000.0000, 5600.0000, 16.0000, 40600.0000,
    N'S', N'S', N'SHOW', N'VES', 1.000000,
    N'API', 1
  );

  INSERT INTO ar.SalesDocumentLine (DocumentNumber, SerialType, OperationType, LineNumber, ProductCode, Description, Quantity, UnitPrice, SubTotal, TaxRate, TaxAmount, TotalAmount, UserCode, CreatedByUserId)
  VALUES
    (N'FACT-2026-00005', N'A', N'FACT', 1, N'PROD040', N'Horno industrial a gas', 1.0000, 25000.0000, 25000.0000, 16.0000, 4000.0000, 29000.0000, N'API', 1),
    (N'FACT-2026-00005', N'A', N'FACT', 2, N'PROD041', N'Juego de ollas acero inox.', 2.0000, 5000.0000, 10000.0000, 16.0000, 1600.0000, 11600.0000, N'API', 1);
END;
GO

-- ============================================================================
-- SECCIÓN 5: ar.ReceivableDocument  (5 CxC correspondientes)
-- ============================================================================
PRINT '>> 5. Cuentas por cobrar demo...';

-- Necesitamos CustomerId - usamos subconsultas
IF NOT EXISTS (SELECT 1 FROM ar.ReceivableDocument WHERE CompanyId = 1 AND DocumentType = N'FACTURA' AND DocumentNumber = N'FACT-2026-00001')
  INSERT INTO ar.ReceivableDocument (CompanyId, BranchId, CustomerId, DocumentType, DocumentNumber, IssueDate, DueDate, CurrencyCode, TotalAmount, PendingAmount, Status, CreatedByUserId)
  SELECT 1, 1, c.CustomerId, N'FACTURA', N'FACT-2026-00001', '2026-03-01', '2026-03-31', N'VES', 98600.00, 98600.00, N'PENDING', 1
  FROM [master].Customer c WHERE c.CompanyId = 1 AND c.CustomerCode = N'CLT002';

IF NOT EXISTS (SELECT 1 FROM ar.ReceivableDocument WHERE CompanyId = 1 AND DocumentType = N'FACTURA' AND DocumentNumber = N'FACT-2026-00002')
  INSERT INTO ar.ReceivableDocument (CompanyId, BranchId, CustomerId, DocumentType, DocumentNumber, IssueDate, DueDate, CurrencyCode, TotalAmount, PendingAmount, Status, CreatedByUserId)
  SELECT 1, 1, c.CustomerId, N'FACTURA', N'FACT-2026-00002', '2026-03-05', '2026-04-04', N'VES', 139200.00, 139200.00, N'PENDING', 1
  FROM [master].Customer c WHERE c.CompanyId = 1 AND c.CustomerCode = N'CLT004';

IF NOT EXISTS (SELECT 1 FROM ar.ReceivableDocument WHERE CompanyId = 1 AND DocumentType = N'FACTURA' AND DocumentNumber = N'FACT-2026-00003')
  INSERT INTO ar.ReceivableDocument (CompanyId, BranchId, CustomerId, DocumentType, DocumentNumber, IssueDate, DueDate, CurrencyCode, TotalAmount, PendingAmount, Status, CreatedByUserId)
  SELECT 1, 1, c.CustomerId, N'FACTURA', N'FACT-2026-00003', '2026-03-08', '2026-04-07', N'VES', 290000.00, 290000.00, N'PENDING', 1
  FROM [master].Customer c WHERE c.CompanyId = 1 AND c.CustomerCode = N'CLT006';

IF NOT EXISTS (SELECT 1 FROM ar.ReceivableDocument WHERE CompanyId = 1 AND DocumentType = N'FACTURA' AND DocumentNumber = N'FACT-2026-00004')
  INSERT INTO ar.ReceivableDocument (CompanyId, BranchId, CustomerId, DocumentType, DocumentNumber, IssueDate, DueDate, CurrencyCode, TotalAmount, PendingAmount, Status, CreatedByUserId)
  SELECT 1, 1, c.CustomerId, N'FACTURA', N'FACT-2026-00004', '2026-03-10', '2026-04-09', N'VES', 52200.00, 52200.00, N'PENDING', 1
  FROM [master].Customer c WHERE c.CompanyId = 1 AND c.CustomerCode = N'CLT009';

IF NOT EXISTS (SELECT 1 FROM ar.ReceivableDocument WHERE CompanyId = 1 AND DocumentType = N'FACTURA' AND DocumentNumber = N'FACT-2026-00005')
  INSERT INTO ar.ReceivableDocument (CompanyId, BranchId, CustomerId, DocumentType, DocumentNumber, IssueDate, DueDate, CurrencyCode, TotalAmount, PendingAmount, PaidFlag, Status, CreatedByUserId)
  SELECT 1, 1, c.CustomerId, N'FACTURA', N'FACT-2026-00005', '2026-03-12', '2026-03-27', N'VES', 40600.00, 0.00, 1, N'PAID', 1
  FROM [master].Customer c WHERE c.CompanyId = 1 AND c.CustomerCode = N'CLT010';
GO

-- ============================================================================
-- SECCIÓN 6: ap.PurchaseDocument + ap.PurchaseDocumentLine  (3 compras demo)
-- ============================================================================
PRINT '>> 6. Documentos de compra demo...';

-- Compra 1 - Proveedor de materiales de construcción
IF NOT EXISTS (SELECT 1 FROM ap.PurchaseDocument WHERE DocumentNumber = N'OC-2026-00001' AND OperationType = N'COMPRA')
BEGIN
  INSERT INTO ap.PurchaseDocument (
    DocumentNumber, SerialType, OperationType,
    SupplierCode, SupplierName, FiscalId,
    DocumentDate, DueDate,
    SubTotal, TaxableAmount, TaxAmount, TaxRate, TotalAmount,
    IsPaid, IsReceived, WarehouseCode, CurrencyCode, ExchangeRate,
    UserCode, CreatedByUserId
  ) VALUES (
    N'OC-2026-00001', N'A', N'COMPRA',
    N'PROV001', N'Distribuidora de Materiales C.A.', N'J-12345678-0',
    '2026-02-25', '2026-03-27',
    62000.0000, 62000.0000, 9920.0000, 16.0000, 71920.0000,
    N'N', N'S', N'PRINCIPAL', N'VES', 1.000000,
    N'API', 1
  );

  INSERT INTO ap.PurchaseDocumentLine (DocumentNumber, SerialType, OperationType, LineNumber, ProductCode, Description, Quantity, UnitPrice, UnitCost, SubTotal, TaxRate, TaxAmount, TotalAmount, UserCode, CreatedByUserId)
  VALUES
    (N'OC-2026-00001', N'A', N'COMPRA', 1, N'PROD001', N'Cemento Portland 42.5 kg', 80.0000, 500.0000, 500.0000, 40000.0000, 16.0000, 6400.0000, 46400.0000, N'API', 1),
    (N'OC-2026-00001', N'A', N'COMPRA', 2, N'PROD002', N'Cabilla 1/2" x 12m', 80.0000, 275.0000, 275.0000, 22000.0000, 16.0000, 3520.0000, 25520.0000, N'API', 1);
END;
GO

-- Compra 2 - Proveedor de alimentos
IF NOT EXISTS (SELECT 1 FROM ap.PurchaseDocument WHERE DocumentNumber = N'OC-2026-00002' AND OperationType = N'COMPRA')
BEGIN
  INSERT INTO ap.PurchaseDocument (
    DocumentNumber, SerialType, OperationType,
    SupplierCode, SupplierName, FiscalId,
    DocumentDate, DueDate,
    SubTotal, TaxableAmount, TaxAmount, TaxRate, TotalAmount,
    IsPaid, IsReceived, WarehouseCode, CurrencyCode, ExchangeRate,
    UserCode, CreatedByUserId
  ) VALUES (
    N'OC-2026-00002', N'A', N'COMPRA',
    N'PROV002', N'Alimentos del Centro S.A.', N'J-23456789-1',
    '2026-03-01', '2026-03-31',
    95000.0000, 95000.0000, 15200.0000, 16.0000, 110200.0000,
    N'N', N'S', N'PRINCIPAL', N'VES', 1.000000,
    N'API', 1
  );

  INSERT INTO ap.PurchaseDocumentLine (DocumentNumber, SerialType, OperationType, LineNumber, ProductCode, Description, Quantity, UnitPrice, UnitCost, SubTotal, TaxRate, TaxAmount, TotalAmount, UserCode, CreatedByUserId)
  VALUES
    (N'OC-2026-00002', N'A', N'COMPRA', 1, N'PROD010', N'Aceite vegetal 1L (caja x12)', 300.0000, 200.0000, 200.0000, 60000.0000, 16.0000, 9600.0000, 69600.0000, N'API', 1),
    (N'OC-2026-00002', N'A', N'COMPRA', 2, N'PROD011', N'Harina precocida 1kg', 700.0000, 50.0000, 50.0000, 35000.0000, 16.0000, 5600.0000, 40600.0000, N'API', 1);
END;
GO

-- Compra 3 - Proveedor de tecnología
IF NOT EXISTS (SELECT 1 FROM ap.PurchaseDocument WHERE DocumentNumber = N'OC-2026-00003' AND OperationType = N'COMPRA')
BEGIN
  INSERT INTO ap.PurchaseDocument (
    DocumentNumber, SerialType, OperationType,
    SupplierCode, SupplierName, FiscalId,
    DocumentDate, DueDate,
    SubTotal, TaxableAmount, TaxAmount, TaxRate, TotalAmount,
    IsPaid, IsReceived, WarehouseCode, CurrencyCode, ExchangeRate,
    UserCode, CreatedByUserId
  ) VALUES (
    N'OC-2026-00003', N'A', N'COMPRA',
    N'PROV003', N'Importadora TechVen C.A.', N'J-34567890-2',
    '2026-03-05', '2026-04-04',
    38000.0000, 38000.0000, 6080.0000, 16.0000, 44080.0000,
    N'S', N'S', N'PRINCIPAL', N'VES', 1.000000,
    N'API', 1
  );

  INSERT INTO ap.PurchaseDocumentLine (DocumentNumber, SerialType, OperationType, LineNumber, ProductCode, Description, Quantity, UnitPrice, UnitCost, SubTotal, TaxRate, TaxAmount, TotalAmount, UserCode, CreatedByUserId)
  VALUES
    (N'OC-2026-00003', N'A', N'COMPRA', 1, N'PROD030', N'Cable UTP Cat6 (caja 305m)', 10.0000, 2800.0000, 2800.0000, 28000.0000, 16.0000, 4480.0000, 32480.0000, N'API', 1),
    (N'OC-2026-00003', N'A', N'COMPRA', 2, N'PROD031', N'Switch 24 puertos PoE', 2.0000, 5000.0000, 5000.0000, 10000.0000, 16.0000, 1600.0000, 11600.0000, N'API', 1);
END;
GO

-- ============================================================================
-- SECCIÓN 7: ap.PayableDocument  (3 CxP correspondientes)
-- ============================================================================
PRINT '>> 7. Cuentas por pagar demo...';

IF NOT EXISTS (SELECT 1 FROM ap.PayableDocument WHERE CompanyId = 1 AND DocumentType = N'COMPRA' AND DocumentNumber = N'OC-2026-00001')
  INSERT INTO ap.PayableDocument (CompanyId, BranchId, SupplierId, DocumentType, DocumentNumber, IssueDate, DueDate, CurrencyCode, TotalAmount, PendingAmount, Status, CreatedByUserId)
  SELECT 1, 1, s.SupplierId, N'COMPRA', N'OC-2026-00001', '2026-02-25', '2026-03-27', N'VES', 71920.00, 71920.00, N'PENDING', 1
  FROM [master].Supplier s WHERE s.CompanyId = 1 AND s.SupplierCode = N'PROV001';

IF NOT EXISTS (SELECT 1 FROM ap.PayableDocument WHERE CompanyId = 1 AND DocumentType = N'COMPRA' AND DocumentNumber = N'OC-2026-00002')
  INSERT INTO ap.PayableDocument (CompanyId, BranchId, SupplierId, DocumentType, DocumentNumber, IssueDate, DueDate, CurrencyCode, TotalAmount, PendingAmount, Status, CreatedByUserId)
  SELECT 1, 1, s.SupplierId, N'COMPRA', N'OC-2026-00002', '2026-03-01', '2026-03-31', N'VES', 110200.00, 110200.00, N'PENDING', 1
  FROM [master].Supplier s WHERE s.CompanyId = 1 AND s.SupplierCode = N'PROV002';

IF NOT EXISTS (SELECT 1 FROM ap.PayableDocument WHERE CompanyId = 1 AND DocumentType = N'COMPRA' AND DocumentNumber = N'OC-2026-00003')
  INSERT INTO ap.PayableDocument (CompanyId, BranchId, SupplierId, DocumentType, DocumentNumber, IssueDate, DueDate, CurrencyCode, TotalAmount, PendingAmount, PaidFlag, Status, CreatedByUserId)
  SELECT 1, 1, s.SupplierId, N'COMPRA', N'OC-2026-00003', '2026-03-05', '2026-04-04', N'VES', 44080.00, 0.00, 1, N'PAID', 1
  FROM [master].Supplier s WHERE s.CompanyId = 1 AND s.SupplierCode = N'PROV003';
GO

-- ============================================================================
-- SECCIÓN 8: master.InventoryMovement  (20 movimientos)
-- ============================================================================
PRINT '>> 8. Movimientos de inventario demo...';

-- Entradas de la Compra OC-2026-00001
IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'OC-2026-00001' AND ProductCode = N'PROD001')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD001', N'Cemento Portland 42.5 kg', N'OC-2026-00001', N'ENTRADA', '2026-02-26', 80.0000, 500.0000, 40000.0000, N'Recepción compra OC-2026-00001', 1);

IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'OC-2026-00001' AND ProductCode = N'PROD002')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD002', N'Cabilla 1/2" x 12m', N'OC-2026-00001', N'ENTRADA', '2026-02-26', 80.0000, 275.0000, 22000.0000, N'Recepción compra OC-2026-00001', 1);

-- Entradas de la Compra OC-2026-00002
IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'OC-2026-00002' AND ProductCode = N'PROD010')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD010', N'Aceite vegetal 1L (caja x12)', N'OC-2026-00002', N'ENTRADA', '2026-03-02', 300.0000, 200.0000, 60000.0000, N'Recepción compra OC-2026-00002', 1);

IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'OC-2026-00002' AND ProductCode = N'PROD011')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD011', N'Harina precocida 1kg', N'OC-2026-00002', N'ENTRADA', '2026-03-02', 700.0000, 50.0000, 35000.0000, N'Recepción compra OC-2026-00002', 1);

-- Entradas de la Compra OC-2026-00003
IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'OC-2026-00003' AND ProductCode = N'PROD030')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD030', N'Cable UTP Cat6 (caja 305m)', N'OC-2026-00003', N'ENTRADA', '2026-03-06', 10.0000, 2800.0000, 28000.0000, N'Recepción compra OC-2026-00003', 1);

IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'OC-2026-00003' AND ProductCode = N'PROD031')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD031', N'Switch 24 puertos PoE', N'OC-2026-00003', N'ENTRADA', '2026-03-06', 2.0000, 5000.0000, 10000.0000, N'Recepción compra OC-2026-00003', 1);

-- Entradas extras (stock adicional)
IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'AJUSTE-INV-001' AND ProductCode = N'PROD020')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD020', N'Escritorio ejecutivo madera', N'AJUSTE-INV-001', N'ENTRADA', '2026-02-15', 15.0000, 10000.0000, 150000.0000, N'Inventario inicial - ajuste', 1);

IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'AJUSTE-INV-001' AND ProductCode = N'PROD021')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD021', N'Silla ergonómica ajustable', N'AJUSTE-INV-001', N'ENTRADA', '2026-02-15', 30.0000, 3500.0000, 105000.0000, N'Inventario inicial - ajuste', 1);

IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'AJUSTE-INV-001' AND ProductCode = N'PROD040')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD040', N'Horno industrial a gas', N'AJUSTE-INV-001', N'ENTRADA', '2026-02-15', 3.0000, 18000.0000, 54000.0000, N'Inventario inicial - ajuste', 1);

IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'AJUSTE-INV-001' AND ProductCode = N'PROD041')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD041', N'Juego de ollas acero inox.', N'AJUSTE-INV-001', N'ENTRADA', '2026-02-15', 10.0000, 3500.0000, 35000.0000, N'Inventario inicial - ajuste', 1);

-- Salidas por Factura FACT-2026-00001
IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'FACT-2026-00001' AND ProductCode = N'PROD001')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD001', N'Cemento Portland 42.5 kg', N'FACT-2026-00001', N'SALIDA', '2026-03-01', 50.0000, 500.0000, 25000.0000, N'Despacho factura FACT-2026-00001', 1);

IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'FACT-2026-00001' AND ProductCode = N'PROD002')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD002', N'Cabilla 1/2" x 12m', N'FACT-2026-00001', N'SALIDA', '2026-03-01', 100.0000, 275.0000, 27500.0000, N'Despacho factura FACT-2026-00001', 1);

-- Salidas por Factura FACT-2026-00002
IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'FACT-2026-00002' AND ProductCode = N'PROD010')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD010', N'Aceite vegetal 1L (caja x12)', N'FACT-2026-00002', N'SALIDA', '2026-03-05', 200.0000, 200.0000, 40000.0000, N'Despacho factura FACT-2026-00002', 1);

IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'FACT-2026-00002' AND ProductCode = N'PROD011')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD011', N'Harina precocida 1kg', N'FACT-2026-00002', N'SALIDA', '2026-03-05', 500.0000, 50.0000, 25000.0000, N'Despacho factura FACT-2026-00002', 1);

-- Salidas por Factura FACT-2026-00003
IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'FACT-2026-00003' AND ProductCode = N'PROD020')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD020', N'Escritorio ejecutivo madera', N'FACT-2026-00003', N'SALIDA', '2026-03-08', 10.0000, 10000.0000, 100000.0000, N'Despacho factura FACT-2026-00003', 1);

IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'FACT-2026-00003' AND ProductCode = N'PROD021')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD021', N'Silla ergonómica ajustable', N'FACT-2026-00003', N'SALIDA', '2026-03-08', 20.0000, 3500.0000, 70000.0000, N'Despacho factura FACT-2026-00003', 1);

-- Salidas por Factura FACT-2026-00004
IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'FACT-2026-00004' AND ProductCode = N'PROD030')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD030', N'Cable UTP Cat6 (caja 305m)', N'FACT-2026-00004', N'SALIDA', '2026-03-10', 5.0000, 2800.0000, 14000.0000, N'Despacho factura FACT-2026-00004', 1);

-- Salida por Factura FACT-2026-00005
IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'FACT-2026-00005' AND ProductCode = N'PROD040')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD040', N'Horno industrial a gas', N'FACT-2026-00005', N'SALIDA', '2026-03-12', 1.0000, 18000.0000, 18000.0000, N'Despacho factura FACT-2026-00005', 1);

IF NOT EXISTS (SELECT 1 FROM master.InventoryMovement WHERE CompanyId = 1 AND DocumentRef = N'FACT-2026-00005' AND ProductCode = N'PROD041')
  INSERT INTO master.InventoryMovement (CompanyId, BranchId, ProductCode, ProductName, DocumentRef, MovementType, MovementDate, Quantity, UnitCost, TotalCost, Notes, CreatedByUserId)
  VALUES (1, 1, N'PROD041', N'Juego de ollas acero inox.', N'FACT-2026-00005', N'SALIDA', '2026-03-12', 2.0000, 3500.0000, 7000.0000, N'Despacho factura FACT-2026-00005', 1);
GO

-- ============================================================================
-- Resumen final
-- ============================================================================
PRINT '=== Seed completado ===';
PRINT 'Clientes:     ' + CAST((SELECT COUNT(*) FROM [master].Customer WHERE CompanyId = 1 AND IsDeleted = 0) AS NVARCHAR(10));
PRINT 'Direcciones:  ' + CAST((SELECT COUNT(*) FROM [master].CustomerAddress WHERE CompanyId = 1 AND IsDeleted = 0) AS NVARCHAR(10));
PRINT 'Pagos cliente:' + CAST((SELECT COUNT(*) FROM [master].CustomerPaymentMethod WHERE CompanyId = 1) AS NVARCHAR(10));
PRINT 'Facturas:     ' + CAST((SELECT COUNT(*) FROM ar.SalesDocument WHERE OperationType = N'FACT' AND IsDeleted = 0) AS NVARCHAR(10));
PRINT 'Líneas venta: ' + CAST((SELECT COUNT(*) FROM ar.SalesDocumentLine WHERE OperationType = N'FACT' AND IsDeleted = 0) AS NVARCHAR(10));
PRINT 'CxC:          ' + CAST((SELECT COUNT(*) FROM ar.ReceivableDocument WHERE CompanyId = 1) AS NVARCHAR(10));
PRINT 'Compras:      ' + CAST((SELECT COUNT(*) FROM ap.PurchaseDocument WHERE OperationType = N'COMPRA' AND IsDeleted = 0) AS NVARCHAR(10));
PRINT 'Líneas compra:' + CAST((SELECT COUNT(*) FROM ap.PurchaseDocumentLine WHERE OperationType = N'COMPRA' AND IsDeleted = 0) AS NVARCHAR(10));
PRINT 'CxP:          ' + CAST((SELECT COUNT(*) FROM ap.PayableDocument WHERE CompanyId = 1) AS NVARCHAR(10));
PRINT 'Mov.Inventario:' + CAST((SELECT COUNT(*) FROM master.InventoryMovement WHERE CompanyId = 1 AND IsDeleted = 0) AS NVARCHAR(10));
GO
