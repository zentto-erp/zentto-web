/*  ═══════════════════════════════════════════════════════════════
    seed_demo_ecommerce_pos.sql — Datos demo para Ecommerce, POS y Auditoría
    Tablas: store.ProductVariant, store.ProductVariantOptionValue,
            store.ProductAttribute, pos.WaitTicket/Line, pos.SaleTicket/Line,
            pay.Transactions, audit.AuditLog
    Idempotente — safe to re-run.
    ═══════════════════════════════════════════════════════════════ */
USE [DatqBoxWeb];
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== seed_demo_ecommerce_pos.sql — START ===';
GO

-- ═══════════════════════════════════════════════════════════════
-- SECCIÓN 1: VARIANTES DE PRODUCTO
-- Parent products: ELEC-AUD-BT01 (Audífonos) y ROP-CAMI-01 (Camiseta)
-- Se crean 6 productos hijo en master.Product + 6 filas en store.ProductVariant
-- ═══════════════════════════════════════════════════════════════

DECLARE @CompanyId INT = 1;
DECLARE @now DATETIME2(0) = SYSUTCDATETIME();

-- 1a. Marcar padres como IsVariantParent = 1
UPDATE [master].Product SET IsVariantParent = 1
WHERE CompanyId = @CompanyId AND ProductCode = N'ELEC-AUD-BT01' AND IsVariantParent = 0;

UPDATE [master].Product SET IsVariantParent = 1
WHERE CompanyId = @CompanyId AND ProductCode = N'ROP-CAMI-01' AND IsVariantParent = 0;

-- 1b. Productos hijo — Audífonos BT (3 colores: Negro, Blanco, Azul)
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'ELEC-AUD-BT01-NEG')
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, IsDeleted, ParentProductCode, IsVariantParent, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, N'ELEC-AUD-BT01-NEG', N'Audífonos Bluetooth Pro - Negro', N'ELECTRO', N'UND', 89.99, 45.00, N'IVA', 16, 60, 0, 1, 0, N'ELEC-AUD-BT01', 0, @now, @now);

IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'ELEC-AUD-BT01-BLA')
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, IsDeleted, ParentProductCode, IsVariantParent, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, N'ELEC-AUD-BT01-BLA', N'Audífonos Bluetooth Pro - Blanco', N'ELECTRO', N'UND', 89.99, 45.00, N'IVA', 16, 50, 0, 1, 0, N'ELEC-AUD-BT01', 0, @now, @now);

IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'ELEC-AUD-BT01-AZU')
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, IsDeleted, ParentProductCode, IsVariantParent, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, N'ELEC-AUD-BT01-AZU', N'Audífonos Bluetooth Pro - Azul', N'ELECTRO', N'UND', 94.99, 45.00, N'IVA', 16, 40, 0, 1, 0, N'ELEC-AUD-BT01', 0, @now, @now);

-- 1c. Productos hijo — Camiseta Dry-Fit (3 tallas: S, M, L)
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'ROP-CAMI-01-S')
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, IsDeleted, ParentProductCode, IsVariantParent, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, N'ROP-CAMI-01-S', N'Camiseta Deportiva Dry-Fit - S', N'ROPA', N'UND', 18.99, 7.00, N'IVA', 16, 120, 0, 1, 0, N'ROP-CAMI-01', 0, @now, @now);

IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'ROP-CAMI-01-M')
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, IsDeleted, ParentProductCode, IsVariantParent, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, N'ROP-CAMI-01-M', N'Camiseta Deportiva Dry-Fit - M', N'ROPA', N'UND', 18.99, 7.00, N'IVA', 16, 150, 0, 1, 0, N'ROP-CAMI-01', 0, @now, @now);

IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE CompanyId = @CompanyId AND ProductCode = N'ROP-CAMI-01-L')
    INSERT INTO [master].Product (CompanyId, ProductCode, ProductName, CategoryCode, UnitCode, SalesPrice, CostPrice, DefaultTaxCode, DefaultTaxRate, StockQty, IsService, IsActive, IsDeleted, ParentProductCode, IsVariantParent, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, N'ROP-CAMI-01-L', N'Camiseta Deportiva Dry-Fit - L', N'ROPA', N'UND', 20.99, 7.00, N'IVA', 16, 130, 0, 1, 0, N'ROP-CAMI-01', 0, @now, @now);

PRINT 'Seeded 6 variant child products in master.Product';
GO

-- 1d. store.ProductVariant — vincular padres con hijos
DECLARE @CompanyId INT = 1;

-- Audífonos Negro (default)
IF NOT EXISTS (SELECT 1 FROM store.ProductVariant WHERE CompanyId = @CompanyId AND ParentProductCode = N'ELEC-AUD-BT01' AND VariantProductCode = N'ELEC-AUD-BT01-NEG')
    INSERT INTO store.ProductVariant (CompanyId, ParentProductCode, VariantProductCode, SKU, PriceDelta, StockOverride, IsDefault, SortOrder, IsActive, IsDeleted)
    VALUES (@CompanyId, N'ELEC-AUD-BT01', N'ELEC-AUD-BT01-NEG', N'AUD-BT01-NEG', 0, NULL, 1, 1, 1, 0);

-- Audífonos Blanco
IF NOT EXISTS (SELECT 1 FROM store.ProductVariant WHERE CompanyId = @CompanyId AND ParentProductCode = N'ELEC-AUD-BT01' AND VariantProductCode = N'ELEC-AUD-BT01-BLA')
    INSERT INTO store.ProductVariant (CompanyId, ParentProductCode, VariantProductCode, SKU, PriceDelta, StockOverride, IsDefault, SortOrder, IsActive, IsDeleted)
    VALUES (@CompanyId, N'ELEC-AUD-BT01', N'ELEC-AUD-BT01-BLA', N'AUD-BT01-BLA', 0, NULL, 0, 2, 1, 0);

-- Audífonos Azul (+5 delta)
IF NOT EXISTS (SELECT 1 FROM store.ProductVariant WHERE CompanyId = @CompanyId AND ParentProductCode = N'ELEC-AUD-BT01' AND VariantProductCode = N'ELEC-AUD-BT01-AZU')
    INSERT INTO store.ProductVariant (CompanyId, ParentProductCode, VariantProductCode, SKU, PriceDelta, StockOverride, IsDefault, SortOrder, IsActive, IsDeleted)
    VALUES (@CompanyId, N'ELEC-AUD-BT01', N'ELEC-AUD-BT01-AZU', N'AUD-BT01-AZU', 5.00, NULL, 0, 3, 1, 0);

-- Camiseta S
IF NOT EXISTS (SELECT 1 FROM store.ProductVariant WHERE CompanyId = @CompanyId AND ParentProductCode = N'ROP-CAMI-01' AND VariantProductCode = N'ROP-CAMI-01-S')
    INSERT INTO store.ProductVariant (CompanyId, ParentProductCode, VariantProductCode, SKU, PriceDelta, StockOverride, IsDefault, SortOrder, IsActive, IsDeleted)
    VALUES (@CompanyId, N'ROP-CAMI-01', N'ROP-CAMI-01-S', N'CAMI-01-S', 0, NULL, 0, 1, 1, 0);

-- Camiseta M (default)
IF NOT EXISTS (SELECT 1 FROM store.ProductVariant WHERE CompanyId = @CompanyId AND ParentProductCode = N'ROP-CAMI-01' AND VariantProductCode = N'ROP-CAMI-01-M')
    INSERT INTO store.ProductVariant (CompanyId, ParentProductCode, VariantProductCode, SKU, PriceDelta, StockOverride, IsDefault, SortOrder, IsActive, IsDeleted)
    VALUES (@CompanyId, N'ROP-CAMI-01', N'ROP-CAMI-01-M', N'CAMI-01-M', 0, NULL, 1, 2, 1, 0);

-- Camiseta L (+2 delta)
IF NOT EXISTS (SELECT 1 FROM store.ProductVariant WHERE CompanyId = @CompanyId AND ParentProductCode = N'ROP-CAMI-01' AND VariantProductCode = N'ROP-CAMI-01-L')
    INSERT INTO store.ProductVariant (CompanyId, ParentProductCode, VariantProductCode, SKU, PriceDelta, StockOverride, IsDefault, SortOrder, IsActive, IsDeleted)
    VALUES (@CompanyId, N'ROP-CAMI-01', N'ROP-CAMI-01-L', N'CAMI-01-L', 2.00, NULL, 0, 3, 1, 0);

PRINT 'Seeded 6 rows in store.ProductVariant';
GO

-- ═══════════════════════════════════════════════════════════════
-- SECCIÓN 2: store.ProductVariantOptionValue — enlazar variantes con opciones
-- Usa lookups dinámicos por GroupCode + OptionCode para obtener IDs
-- ═══════════════════════════════════════════════════════════════

DECLARE @CompanyId INT = 1;

-- Audífonos Negro -> COLOR / NEGRO
DECLARE @pvId_AudNeg INT = (SELECT ProductVariantId FROM store.ProductVariant WHERE CompanyId = @CompanyId AND VariantProductCode = N'ELEC-AUD-BT01-NEG');
DECLARE @optId_Negro INT = (SELECT vo.VariantOptionId FROM store.ProductVariantOption vo INNER JOIN store.ProductVariantGroup vg ON vo.VariantGroupId = vg.VariantGroupId WHERE vg.CompanyId = @CompanyId AND vg.GroupCode = N'COLOR' AND vo.OptionCode = N'NEGRO');

IF @pvId_AudNeg IS NOT NULL AND @optId_Negro IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM store.ProductVariantOptionValue WHERE ProductVariantId = @pvId_AudNeg AND VariantOptionId = @optId_Negro)
    INSERT INTO store.ProductVariantOptionValue (ProductVariantId, VariantOptionId) VALUES (@pvId_AudNeg, @optId_Negro);

-- Audífonos Blanco -> COLOR / BLANCO
DECLARE @pvId_AudBla INT = (SELECT ProductVariantId FROM store.ProductVariant WHERE CompanyId = @CompanyId AND VariantProductCode = N'ELEC-AUD-BT01-BLA');
DECLARE @optId_Blanco INT = (SELECT vo.VariantOptionId FROM store.ProductVariantOption vo INNER JOIN store.ProductVariantGroup vg ON vo.VariantGroupId = vg.VariantGroupId WHERE vg.CompanyId = @CompanyId AND vg.GroupCode = N'COLOR' AND vo.OptionCode = N'BLANCO');

IF @pvId_AudBla IS NOT NULL AND @optId_Blanco IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM store.ProductVariantOptionValue WHERE ProductVariantId = @pvId_AudBla AND VariantOptionId = @optId_Blanco)
    INSERT INTO store.ProductVariantOptionValue (ProductVariantId, VariantOptionId) VALUES (@pvId_AudBla, @optId_Blanco);

-- Audífonos Azul -> COLOR / AZUL
DECLARE @pvId_AudAzu INT = (SELECT ProductVariantId FROM store.ProductVariant WHERE CompanyId = @CompanyId AND VariantProductCode = N'ELEC-AUD-BT01-AZU');
DECLARE @optId_Azul INT = (SELECT vo.VariantOptionId FROM store.ProductVariantOption vo INNER JOIN store.ProductVariantGroup vg ON vo.VariantGroupId = vg.VariantGroupId WHERE vg.CompanyId = @CompanyId AND vg.GroupCode = N'COLOR' AND vo.OptionCode = N'AZUL');

IF @pvId_AudAzu IS NOT NULL AND @optId_Azul IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM store.ProductVariantOptionValue WHERE ProductVariantId = @pvId_AudAzu AND VariantOptionId = @optId_Azul)
    INSERT INTO store.ProductVariantOptionValue (ProductVariantId, VariantOptionId) VALUES (@pvId_AudAzu, @optId_Azul);

-- Camiseta S -> TALLA / S
DECLARE @pvId_CamiS INT = (SELECT ProductVariantId FROM store.ProductVariant WHERE CompanyId = @CompanyId AND VariantProductCode = N'ROP-CAMI-01-S');
DECLARE @optId_S INT = (SELECT vo.VariantOptionId FROM store.ProductVariantOption vo INNER JOIN store.ProductVariantGroup vg ON vo.VariantGroupId = vg.VariantGroupId WHERE vg.CompanyId = @CompanyId AND vg.GroupCode = N'TALLA' AND vo.OptionCode = N'S');

IF @pvId_CamiS IS NOT NULL AND @optId_S IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM store.ProductVariantOptionValue WHERE ProductVariantId = @pvId_CamiS AND VariantOptionId = @optId_S)
    INSERT INTO store.ProductVariantOptionValue (ProductVariantId, VariantOptionId) VALUES (@pvId_CamiS, @optId_S);

-- Camiseta M -> TALLA / M
DECLARE @pvId_CamiM INT = (SELECT ProductVariantId FROM store.ProductVariant WHERE CompanyId = @CompanyId AND VariantProductCode = N'ROP-CAMI-01-M');
DECLARE @optId_M INT = (SELECT vo.VariantOptionId FROM store.ProductVariantOption vo INNER JOIN store.ProductVariantGroup vg ON vo.VariantGroupId = vg.VariantGroupId WHERE vg.CompanyId = @CompanyId AND vg.GroupCode = N'TALLA' AND vo.OptionCode = N'M');

IF @pvId_CamiM IS NOT NULL AND @optId_M IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM store.ProductVariantOptionValue WHERE ProductVariantId = @pvId_CamiM AND VariantOptionId = @optId_M)
    INSERT INTO store.ProductVariantOptionValue (ProductVariantId, VariantOptionId) VALUES (@pvId_CamiM, @optId_M);

-- Camiseta L -> TALLA / L
DECLARE @pvId_CamiL INT = (SELECT ProductVariantId FROM store.ProductVariant WHERE CompanyId = @CompanyId AND VariantProductCode = N'ROP-CAMI-01-L');
DECLARE @optId_L INT = (SELECT vo.VariantOptionId FROM store.ProductVariantOption vo INNER JOIN store.ProductVariantGroup vg ON vo.VariantGroupId = vg.VariantGroupId WHERE vg.CompanyId = @CompanyId AND vg.GroupCode = N'TALLA' AND vo.OptionCode = N'L');

IF @pvId_CamiL IS NOT NULL AND @optId_L IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM store.ProductVariantOptionValue WHERE ProductVariantId = @pvId_CamiL AND VariantOptionId = @optId_L)
    INSERT INTO store.ProductVariantOptionValue (ProductVariantId, VariantOptionId) VALUES (@pvId_CamiL, @optId_L);

PRINT 'Seeded 6 rows in store.ProductVariantOptionValue';
GO

-- ═══════════════════════════════════════════════════════════════
-- SECCIÓN 3: store.ProductAttribute — 10 atributos de industria
-- Farmacia: SAL-VIT-01 (Multivitamínico) con template FARMACIA
-- Alimentos: MNU-HAMB-CLA (Hamburguesa) con template ALIMENTOS
-- ═══════════════════════════════════════════════════════════════

DECLARE @CompanyId INT = 1;

-- Marcar IndustryTemplateCode en los productos
UPDATE [master].Product SET IndustryTemplateCode = N'FARMACIA'
WHERE CompanyId = @CompanyId AND ProductCode = N'SAL-VIT-01' AND (IndustryTemplateCode IS NULL OR IndustryTemplateCode <> N'FARMACIA');

UPDATE [master].Product SET IndustryTemplateCode = N'ALIMENTOS'
WHERE CompanyId = @CompanyId AND ProductCode = N'MNU-HAMB-CLA' AND (IndustryTemplateCode IS NULL OR IndustryTemplateCode <> N'ALIMENTOS');

-- FARMACIA — SAL-VIT-01 (4 atributos)
IF NOT EXISTS (SELECT 1 FROM store.ProductAttribute WHERE CompanyId = @CompanyId AND ProductCode = N'SAL-VIT-01' AND AttributeKey = N'PrincipioActivo')
    INSERT INTO store.ProductAttribute (CompanyId, ProductCode, TemplateCode, AttributeKey, ValueText) VALUES (@CompanyId, N'SAL-VIT-01', N'FARMACIA', N'PrincipioActivo', N'Complejo multivitamínico (A, B1, B6, B12, C, D3, E, K)');

IF NOT EXISTS (SELECT 1 FROM store.ProductAttribute WHERE CompanyId = @CompanyId AND ProductCode = N'SAL-VIT-01' AND AttributeKey = N'Concentracion')
    INSERT INTO store.ProductAttribute (CompanyId, ProductCode, TemplateCode, AttributeKey, ValueText) VALUES (@CompanyId, N'SAL-VIT-01', N'FARMACIA', N'Concentracion', N'500mg por cápsula');

IF NOT EXISTS (SELECT 1 FROM store.ProductAttribute WHERE CompanyId = @CompanyId AND ProductCode = N'SAL-VIT-01' AND AttributeKey = N'FormaFarmaceutica')
    INSERT INTO store.ProductAttribute (CompanyId, ProductCode, TemplateCode, AttributeKey, ValueText) VALUES (@CompanyId, N'SAL-VIT-01', N'FARMACIA', N'FormaFarmaceutica', N'Cápsula');

IF NOT EXISTS (SELECT 1 FROM store.ProductAttribute WHERE CompanyId = @CompanyId AND ProductCode = N'SAL-VIT-01' AND AttributeKey = N'RegistroSanitario')
    INSERT INTO store.ProductAttribute (CompanyId, ProductCode, TemplateCode, AttributeKey, ValueText) VALUES (@CompanyId, N'SAL-VIT-01', N'FARMACIA', N'RegistroSanitario', N'INVIMA-2026-RS-0045821');

-- Extra pharmacy: RequiereReceta = false, Laboratorio
IF NOT EXISTS (SELECT 1 FROM store.ProductAttribute WHERE CompanyId = @CompanyId AND ProductCode = N'SAL-VIT-01' AND AttributeKey = N'RequiereReceta')
    INSERT INTO store.ProductAttribute (CompanyId, ProductCode, TemplateCode, AttributeKey, ValueBoolean) VALUES (@CompanyId, N'SAL-VIT-01', N'FARMACIA', N'RequiereReceta', 0);

IF NOT EXISTS (SELECT 1 FROM store.ProductAttribute WHERE CompanyId = @CompanyId AND ProductCode = N'SAL-VIT-01' AND AttributeKey = N'Laboratorio')
    INSERT INTO store.ProductAttribute (CompanyId, ProductCode, TemplateCode, AttributeKey, ValueText) VALUES (@CompanyId, N'SAL-VIT-01', N'FARMACIA', N'Laboratorio', N'Laboratorios Farma Plus C.A.');

-- ALIMENTOS — MNU-HAMB-CLA (4 atributos)
IF NOT EXISTS (SELECT 1 FROM store.ProductAttribute WHERE CompanyId = @CompanyId AND ProductCode = N'MNU-HAMB-CLA' AND AttributeKey = N'FechaVencimiento')
    INSERT INTO store.ProductAttribute (CompanyId, ProductCode, TemplateCode, AttributeKey, ValueDate) VALUES (@CompanyId, N'MNU-HAMB-CLA', N'ALIMENTOS', N'FechaVencimiento', '2026-06-30');

IF NOT EXISTS (SELECT 1 FROM store.ProductAttribute WHERE CompanyId = @CompanyId AND ProductCode = N'MNU-HAMB-CLA' AND AttributeKey = N'Lote')
    INSERT INTO store.ProductAttribute (CompanyId, ProductCode, TemplateCode, AttributeKey, ValueText) VALUES (@CompanyId, N'MNU-HAMB-CLA', N'ALIMENTOS', N'Lote', N'LOTE-2026-03-001');

IF NOT EXISTS (SELECT 1 FROM store.ProductAttribute WHERE CompanyId = @CompanyId AND ProductCode = N'MNU-HAMB-CLA' AND AttributeKey = N'PesoNeto')
    INSERT INTO store.ProductAttribute (CompanyId, ProductCode, TemplateCode, AttributeKey, ValueNumber) VALUES (@CompanyId, N'MNU-HAMB-CLA', N'ALIMENTOS', N'PesoNeto', 250.0000);

IF NOT EXISTS (SELECT 1 FROM store.ProductAttribute WHERE CompanyId = @CompanyId AND ProductCode = N'MNU-HAMB-CLA' AND AttributeKey = N'Ingredientes')
    INSERT INTO store.ProductAttribute (CompanyId, ProductCode, TemplateCode, AttributeKey, ValueText) VALUES (@CompanyId, N'MNU-HAMB-CLA', N'ALIMENTOS', N'Ingredientes', N'Carne de res 150g, pan artesanal, queso cheddar, lechuga, tomate, cebolla, salsa especial');

PRINT 'Seeded 10 rows in store.ProductAttribute (6 FARMACIA + 4 ALIMENTOS)';
GO

-- ═══════════════════════════════════════════════════════════════
-- SECCIÓN 4: pos.WaitTicket + pos.WaitTicketLine — 3 tickets en espera
-- ═══════════════════════════════════════════════════════════════

DECLARE @CompanyId INT = 1;
DECLARE @BranchId INT = 1;
DECLARE @CountryCode CHAR(2) = 'VE';
DECLARE @now DATETIME2(0) = SYSUTCDATETIME();

-- Ticket en espera 1
IF NOT EXISTS (SELECT 1 FROM pos.WaitTicket WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND CashRegisterCode = N'CAJA-01' AND CustomerName = N'María García' AND Status = 'WAITING')
BEGIN
    INSERT INTO pos.WaitTicket (CompanyId, BranchId, CountryCode, CashRegisterCode, StationName, CreatedByUserId, CustomerName, CustomerFiscalId, PriceTier, Reason, NetAmount, DiscountAmount, TaxAmount, TotalAmount, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, @BranchId, @CountryCode, N'CAJA-01', N'Estación Principal', 1, N'María García', N'V-18456789', N'DETAIL', N'Cliente fue a buscar forma de pago', 134.97, 0, 21.60, 156.57, N'WAITING', DATEADD(MINUTE, -45, @now), DATEADD(MINUTE, -45, @now));

    DECLARE @wt1 BIGINT = SCOPE_IDENTITY();

    INSERT INTO pos.WaitTicketLine (WaitTicketId, LineNumber, CountryCode, ProductCode, ProductName, Quantity, UnitPrice, DiscountAmount, TaxCode, TaxRate, NetAmount, TaxAmount, TotalAmount)
    VALUES
        (@wt1, 1, @CountryCode, N'ELEC-AUD-BT01', N'Audífonos Bluetooth Pro', 1, 89.99, 0, N'IVA', 16.0000, 89.99, 14.40, 104.39),
        (@wt1, 2, @CountryCode, N'ELEC-CHRG-01', N'Cargador Inalámbrico Rápido 15W', 1, 29.99, 0, N'IVA', 16.0000, 29.99, 4.80, 34.79),
        (@wt1, 3, @CountryCode, N'DEP-BOT-01', N'Botella Térmica Deportiva 1L', 1, 14.99, 0, N'IVA', 16.0000, 14.99, 2.40, 17.39);

    PRINT 'Seeded WaitTicket 1 with 3 lines';
END;

-- Ticket en espera 2
IF NOT EXISTS (SELECT 1 FROM pos.WaitTicket WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND CashRegisterCode = N'CAJA-02' AND CustomerName = N'José Rodríguez' AND Status = 'WAITING')
BEGIN
    INSERT INTO pos.WaitTicket (CompanyId, BranchId, CountryCode, CashRegisterCode, StationName, CreatedByUserId, CustomerName, CustomerFiscalId, PriceTier, Reason, NetAmount, DiscountAmount, TaxAmount, TotalAmount, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, @BranchId, @CountryCode, N'CAJA-02', N'Estación 2', 1, N'José Rodríguez', N'V-20123456', N'DETAIL', N'Esperando autorización de TDC', 74.99, 0, 12.00, 86.99, N'WAITING', DATEADD(MINUTE, -20, @now), DATEADD(MINUTE, -20, @now));

    DECLARE @wt2 BIGINT = SCOPE_IDENTITY();

    INSERT INTO pos.WaitTicketLine (WaitTicketId, LineNumber, CountryCode, ProductCode, ProductName, Quantity, UnitPrice, DiscountAmount, TaxCode, TaxRate, NetAmount, TaxAmount, TotalAmount)
    VALUES
        (@wt2, 1, @CountryCode, N'ROP-ZAP-01', N'Zapatillas Running Ultralight', 1, 74.99, 0, N'IVA', 16.0000, 74.99, 12.00, 86.99);

    PRINT 'Seeded WaitTicket 2 with 1 line';
END;

-- Ticket en espera 3
IF NOT EXISTS (SELECT 1 FROM pos.WaitTicket WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND CashRegisterCode = N'CAJA-01' AND CustomerName = N'Ana Martínez' AND Status = 'WAITING')
BEGIN
    INSERT INTO pos.WaitTicket (CompanyId, BranchId, CountryCode, CashRegisterCode, StationName, CreatedByUserId, CustomerName, CustomerFiscalId, PriceTier, Reason, NetAmount, DiscountAmount, TaxAmount, TotalAmount, Status, CreatedAt, UpdatedAt)
    VALUES (@CompanyId, @BranchId, @CountryCode, N'CAJA-01', N'Estación Principal', 1, N'Ana Martínez', N'V-15789012', N'DETAIL', N'Consultando disponibilidad de otro color', 64.98, 0, 10.40, 75.38, N'WAITING', DATEADD(MINUTE, -10, @now), DATEADD(MINUTE, -10, @now));

    DECLARE @wt3 BIGINT = SCOPE_IDENTITY();

    INSERT INTO pos.WaitTicketLine (WaitTicketId, LineNumber, CountryCode, ProductCode, ProductName, Quantity, UnitPrice, DiscountAmount, TaxCode, TaxRate, NetAmount, TaxAmount, TotalAmount)
    VALUES
        (@wt3, 1, @CountryCode, N'HOG-LAMP-01', N'Lámpara LED de Escritorio Regulable', 1, 34.99, 0, N'IVA', 16.0000, 34.99, 5.60, 40.59),
        (@wt3, 2, @CountryCode, N'ELEC-CHRG-01', N'Cargador Inalámbrico Rápido 15W', 1, 29.99, 0, N'IVA', 16.0000, 29.99, 4.80, 34.79);

    PRINT 'Seeded WaitTicket 3 with 2 lines';
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- SECCIÓN 5: pos.SaleTicket + pos.SaleTicketLine — 5 ventas completadas
-- ═══════════════════════════════════════════════════════════════

DECLARE @CompanyId INT = 1;
DECLARE @BranchId INT = 1;
DECLARE @CountryCode CHAR(2) = 'VE';
DECLARE @now DATETIME2(0) = SYSUTCDATETIME();

-- Venta 1 — Factura POS-000001
IF NOT EXISTS (SELECT 1 FROM pos.SaleTicket WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND InvoiceNumber = N'POS-000001')
BEGIN
    INSERT INTO pos.SaleTicket (CompanyId, BranchId, CountryCode, InvoiceNumber, CashRegisterCode, SoldByUserId, CustomerName, CustomerFiscalId, PriceTier, PaymentMethod, NetAmount, DiscountAmount, TaxAmount, TotalAmount, SoldAt)
    VALUES (@CompanyId, @BranchId, @CountryCode, N'POS-000001', N'CAJA-01', 1, N'Pedro López', N'V-12345678', N'DETAIL', N'EFECTIVO', 89.99, 0, 14.40, 104.39, DATEADD(HOUR, -6, @now));

    DECLARE @st1 BIGINT = SCOPE_IDENTITY();

    INSERT INTO pos.SaleTicketLine (SaleTicketId, LineNumber, CountryCode, ProductCode, ProductName, Quantity, UnitPrice, DiscountAmount, TaxCode, TaxRate, NetAmount, TaxAmount, TotalAmount)
    VALUES
        (@st1, 1, @CountryCode, N'ELEC-AUD-BT01-NEG', N'Audífonos Bluetooth Pro - Negro', 1, 89.99, 0, N'IVA', 16.0000, 89.99, 14.40, 104.39);

    PRINT 'Seeded SaleTicket POS-000001';
END;

-- Venta 2 — Factura POS-000002
IF NOT EXISTS (SELECT 1 FROM pos.SaleTicket WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND InvoiceNumber = N'POS-000002')
BEGIN
    INSERT INTO pos.SaleTicket (CompanyId, BranchId, CountryCode, InvoiceNumber, CashRegisterCode, SoldByUserId, CustomerName, CustomerFiscalId, PriceTier, PaymentMethod, NetAmount, DiscountAmount, TaxAmount, TotalAmount, SoldAt)
    VALUES (@CompanyId, @BranchId, @CountryCode, N'POS-000002', N'CAJA-01', 1, N'Laura Hernández', N'V-22334455', N'DETAIL', N'TDC', 159.97, 0, 25.60, 185.57, DATEADD(HOUR, -5, @now));

    DECLARE @st2 BIGINT = SCOPE_IDENTITY();

    INSERT INTO pos.SaleTicketLine (SaleTicketId, LineNumber, CountryCode, ProductCode, ProductName, Quantity, UnitPrice, DiscountAmount, TaxCode, TaxRate, NetAmount, TaxAmount, TotalAmount)
    VALUES
        (@st2, 1, @CountryCode, N'ELEC-WATCH-01', N'Smartwatch Fitness Tracker', 1, 129.99, 0, N'IVA', 16.0000, 129.99, 20.80, 150.79),
        (@st2, 2, @CountryCode, N'ELEC-CHRG-01', N'Cargador Inalámbrico Rápido 15W', 1, 29.99, 0, N'IVA', 16.0000, 29.99, 4.80, 34.79);

    PRINT 'Seeded SaleTicket POS-000002';
END;

-- Venta 3 — Factura POS-000003
IF NOT EXISTS (SELECT 1 FROM pos.SaleTicket WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND InvoiceNumber = N'POS-000003')
BEGIN
    INSERT INTO pos.SaleTicket (CompanyId, BranchId, CountryCode, InvoiceNumber, CashRegisterCode, SoldByUserId, CustomerName, CustomerFiscalId, PriceTier, PaymentMethod, NetAmount, DiscountAmount, TaxAmount, TotalAmount, SoldAt)
    VALUES (@CompanyId, @BranchId, @CountryCode, N'POS-000003', N'CAJA-02', 1, N'Carlos Mendoza', N'V-19876543', N'DETAIL', N'TRANSFERENCIA', 37.98, 0, 6.08, 44.06, DATEADD(HOUR, -4, @now));

    DECLARE @st3 BIGINT = SCOPE_IDENTITY();

    INSERT INTO pos.SaleTicketLine (SaleTicketId, LineNumber, CountryCode, ProductCode, ProductName, Quantity, UnitPrice, DiscountAmount, TaxCode, TaxRate, NetAmount, TaxAmount, TotalAmount)
    VALUES
        (@st3, 1, @CountryCode, N'ROP-CAMI-01-M', N'Camiseta Deportiva Dry-Fit - M', 2, 18.99, 0, N'IVA', 16.0000, 37.98, 6.08, 44.06);

    PRINT 'Seeded SaleTicket POS-000003';
END;

-- Venta 4 — Factura POS-000004
IF NOT EXISTS (SELECT 1 FROM pos.SaleTicket WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND InvoiceNumber = N'POS-000004')
BEGIN
    INSERT INTO pos.SaleTicket (CompanyId, BranchId, CountryCode, InvoiceNumber, CashRegisterCode, SoldByUserId, CustomerName, CustomerFiscalId, PriceTier, PaymentMethod, NetAmount, DiscountAmount, TaxAmount, TotalAmount, SoldAt)
    VALUES (@CompanyId, @BranchId, @CountryCode, N'POS-000004', N'CAJA-01', 1, N'Sofía Ramírez', N'V-25678901', N'DETAIL', N'PAGO_MOVIL', 62.97, 0, 10.08, 73.05, DATEADD(HOUR, -3, @now));

    DECLARE @st4 BIGINT = SCOPE_IDENTITY();

    INSERT INTO pos.SaleTicketLine (SaleTicketId, LineNumber, CountryCode, ProductCode, ProductName, Quantity, UnitPrice, DiscountAmount, TaxCode, TaxRate, NetAmount, TaxAmount, TotalAmount)
    VALUES
        (@st4, 1, @CountryCode, N'SAL-PROT-01', N'Proteína Whey 2lb Sabor Chocolate', 1, 42.99, 0, N'IVA', 16.0000, 42.99, 6.88, 49.87),
        (@st4, 2, @CountryCode, N'DEP-BOT-01', N'Botella Térmica Deportiva 1L', 1, 19.99, 0, N'IVA', 16.0000, 19.99, 3.20, 23.19);

    PRINT 'Seeded SaleTicket POS-000004';
END;

-- Venta 5 — Factura POS-000005
IF NOT EXISTS (SELECT 1 FROM pos.SaleTicket WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND InvoiceNumber = N'POS-000005')
BEGIN
    INSERT INTO pos.SaleTicket (CompanyId, BranchId, CountryCode, InvoiceNumber, CashRegisterCode, SoldByUserId, CustomerName, CustomerFiscalId, PriceTier, PaymentMethod, NetAmount, DiscountAmount, TaxAmount, TotalAmount, SoldAt)
    VALUES (@CompanyId, @BranchId, @CountryCode, N'POS-000005', N'CAJA-02', 1, N'Diego Torres', N'V-14567890', N'DETAIL', N'EFECTIVO', 117.97, 0, 18.88, 136.85, DATEADD(HOUR, -1, @now));

    DECLARE @st5 BIGINT = SCOPE_IDENTITY();

    INSERT INTO pos.SaleTicketLine (SaleTicketId, LineNumber, CountryCode, ProductCode, ProductName, Quantity, UnitPrice, DiscountAmount, TaxCode, TaxRate, NetAmount, TaxAmount, TotalAmount)
    VALUES
        (@st5, 1, @CountryCode, N'HOG-CAFE-01', N'Cafetera Programable 12 Tazas', 1, 59.99, 0, N'IVA', 16.0000, 59.99, 9.60, 69.59),
        (@st5, 2, @CountryCode, N'HOG-LAMP-01', N'Lámpara LED de Escritorio Regulable', 1, 34.99, 0, N'IVA', 16.0000, 34.99, 5.60, 40.59),
        (@st5, 3, @CountryCode, N'DEP-YOGA-01', N'Mat de Yoga Antideslizante 6mm', 1, 22.99, 0, N'IVA', 16.0000, 22.99, 3.68, 26.67);

    PRINT 'Seeded SaleTicket POS-000005';
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- SECCIÓN 6: pay.Transactions — 8 transacciones de pago
-- Vinculadas a los SaleTickets creados arriba
-- ═══════════════════════════════════════════════════════════════

DECLARE @CompanyId INT = 1;
DECLARE @now DATETIME = SYSUTCDATETIME();

-- Pago 1: Efectivo para POS-000001
IF NOT EXISTS (SELECT 1 FROM pay.Transactions WHERE TransactionUUID = 'seed-trx-pos-001')
    INSERT INTO pay.Transactions (TransactionUUID, EmpresaId, SucursalId, SourceType, SourceNumber, PaymentMethodCode, Currency, Amount, CommissionAmount, NetAmount, TrxType, Status, StationId, CashierId, IpAddress, CreatedAt, UpdatedAt)
    VALUES ('seed-trx-pos-001', @CompanyId, 0, 'TICKET_POS', 'POS-000001', 'EFECTIVO', 'VES', 104.39, 0, 104.39, 'SALE', 'APPROVED', 'CAJA-01', '1', '192.168.1.10', DATEADD(HOUR, -6, @now), DATEADD(HOUR, -6, @now));

-- Pago 2: TDC para POS-000002
IF NOT EXISTS (SELECT 1 FROM pay.Transactions WHERE TransactionUUID = 'seed-trx-pos-002')
    INSERT INTO pay.Transactions (TransactionUUID, EmpresaId, SucursalId, SourceType, SourceNumber, PaymentMethodCode, Currency, Amount, CommissionAmount, NetAmount, TrxType, Status, GatewayTrxId, GatewayAuthCode, CardLastFour, CardBrand, StationId, CashierId, IpAddress, CreatedAt, UpdatedAt)
    VALUES ('seed-trx-pos-002', @CompanyId, 0, 'TICKET_POS', 'POS-000002', 'TDC', 'VES', 185.57, 3.71, 181.86, 'SALE', 'APPROVED', 'GW-20260316-002', 'AUTH-5589', '4532', 'VISA', 'CAJA-01', '1', '192.168.1.10', DATEADD(HOUR, -5, @now), DATEADD(HOUR, -5, @now));

-- Pago 3: Transferencia para POS-000003
IF NOT EXISTS (SELECT 1 FROM pay.Transactions WHERE TransactionUUID = 'seed-trx-pos-003')
    INSERT INTO pay.Transactions (TransactionUUID, EmpresaId, SucursalId, SourceType, SourceNumber, PaymentMethodCode, Currency, Amount, CommissionAmount, NetAmount, TrxType, Status, PaymentRef, BankCode, StationId, CashierId, IpAddress, CreatedAt, UpdatedAt)
    VALUES ('seed-trx-pos-003', @CompanyId, 0, 'TICKET_POS', 'POS-000003', 'TRANSFER', 'VES', 44.06, 0, 44.06, 'SALE', 'APPROVED', 'REF-20260316-44060', '0102', 'CAJA-02', '1', '192.168.1.11', DATEADD(HOUR, -4, @now), DATEADD(HOUR, -4, @now));

-- Pago 4: Pago Móvil para POS-000004
IF NOT EXISTS (SELECT 1 FROM pay.Transactions WHERE TransactionUUID = 'seed-trx-pos-004')
    INSERT INTO pay.Transactions (TransactionUUID, EmpresaId, SucursalId, SourceType, SourceNumber, PaymentMethodCode, Currency, Amount, CommissionAmount, NetAmount, TrxType, Status, PaymentRef, MobileNumber, BankCode, StationId, CashierId, IpAddress, CreatedAt, UpdatedAt)
    VALUES ('seed-trx-pos-004', @CompanyId, 0, 'TICKET_POS', 'POS-000004', 'C2P', 'VES', 73.05, 0, 73.05, 'SALE', 'APPROVED', 'C2P-20260316-73050', '0412***4567', '0134', 'CAJA-01', '1', '192.168.1.10', DATEADD(HOUR, -3, @now), DATEADD(HOUR, -3, @now));

-- Pago 5: Efectivo para POS-000005
IF NOT EXISTS (SELECT 1 FROM pay.Transactions WHERE TransactionUUID = 'seed-trx-pos-005')
    INSERT INTO pay.Transactions (TransactionUUID, EmpresaId, SucursalId, SourceType, SourceNumber, PaymentMethodCode, Currency, Amount, CommissionAmount, NetAmount, TrxType, Status, StationId, CashierId, IpAddress, CreatedAt, UpdatedAt)
    VALUES ('seed-trx-pos-005', @CompanyId, 0, 'TICKET_POS', 'POS-000005', 'EFECTIVO', 'VES', 136.85, 0, 136.85, 'SALE', 'APPROVED', 'CAJA-02', '1', '192.168.1.11', DATEADD(HOUR, -1, @now), DATEADD(HOUR, -1, @now));

-- Pago 6: TDC pendiente (simulando una transacción en proceso)
IF NOT EXISTS (SELECT 1 FROM pay.Transactions WHERE TransactionUUID = 'seed-trx-pos-006')
    INSERT INTO pay.Transactions (TransactionUUID, EmpresaId, SucursalId, SourceType, SourceNumber, PaymentMethodCode, Currency, Amount, CommissionAmount, NetAmount, TrxType, Status, CardLastFour, CardBrand, StationId, CashierId, IpAddress, Notes, CreatedAt, UpdatedAt)
    VALUES ('seed-trx-pos-006', @CompanyId, 0, 'TICKET_POS', 'POS-PENDING-01', 'TDC', 'VES', 250.00, 5.00, 245.00, 'SALE', 'PENDING', '8901', 'MASTERCARD', 'CAJA-01', '1', '192.168.1.10', N'Esperando respuesta del procesador', @now, @now);

-- Pago 7: Pago en USD (multi-moneda)
IF NOT EXISTS (SELECT 1 FROM pay.Transactions WHERE TransactionUUID = 'seed-trx-pos-007')
    INSERT INTO pay.Transactions (TransactionUUID, EmpresaId, SucursalId, SourceType, SourceNumber, PaymentMethodCode, Currency, Amount, CommissionAmount, NetAmount, ExchangeRate, AmountInBase, TrxType, Status, StationId, CashierId, IpAddress, CreatedAt, UpdatedAt)
    VALUES ('seed-trx-pos-007', @CompanyId, 0, 'TICKET_POS', 'POS-000001', 'EFECTIVO', 'USD', 2.85, 0, 2.85, 36.60, 104.31, 'SALE', 'APPROVED', 'CAJA-01', '1', '192.168.1.10', DATEADD(HOUR, -6, @now), DATEADD(HOUR, -6, @now));

-- Pago 8: Transferencia declinada
IF NOT EXISTS (SELECT 1 FROM pay.Transactions WHERE TransactionUUID = 'seed-trx-pos-008')
    INSERT INTO pay.Transactions (TransactionUUID, EmpresaId, SucursalId, SourceType, SourceNumber, PaymentMethodCode, Currency, Amount, CommissionAmount, NetAmount, TrxType, Status, PaymentRef, BankCode, GatewayMessage, StationId, CashierId, IpAddress, Notes, CreatedAt, UpdatedAt)
    VALUES ('seed-trx-pos-008', @CompanyId, 0, 'TICKET_POS', 'POS-DECLINED-01', 'TRANSFER', 'VES', 500.00, 0, 500.00, 'SALE', 'DECLINED', 'REF-FAIL-001', '0105', N'Fondos insuficientes', 'CAJA-02', '1', '192.168.1.11', N'Cliente intentó con otra cuenta', DATEADD(HOUR, -2, @now), DATEADD(HOUR, -2, @now));

PRINT 'Seeded 8 rows in pay.Transactions';
GO

-- ═══════════════════════════════════════════════════════════════
-- SECCIÓN 7: audit.AuditLog — 10 entradas de auditoría
-- ═══════════════════════════════════════════════════════════════

DECLARE @CompanyId INT = 1;
DECLARE @BranchId INT = 1;
DECLARE @now DATETIME2(0) = SYSUTCDATETIME();

IF NOT EXISTS (SELECT 1 FROM audit.AuditLog WHERE CompanyId = @CompanyId AND Summary = N'SEED: Login admin exitoso')
    INSERT INTO audit.AuditLog (CompanyId, BranchId, UserId, UserName, ModuleName, EntityName, EntityId, ActionType, Summary, IpAddress, CreatedAt)
    VALUES (@CompanyId, @BranchId, 1, N'admin', N'SEGURIDAD', N'Session', N'SES-001', 'LOGIN', N'SEED: Login admin exitoso', '192.168.1.10', DATEADD(HOUR, -8, @now));

IF NOT EXISTS (SELECT 1 FROM audit.AuditLog WHERE CompanyId = @CompanyId AND Summary = N'SEED: Creación factura POS-000001')
    INSERT INTO audit.AuditLog (CompanyId, BranchId, UserId, UserName, ModuleName, EntityName, EntityId, ActionType, Summary, NewValues, IpAddress, CreatedAt)
    VALUES (@CompanyId, @BranchId, 1, N'admin', N'POS', N'SaleTicket', N'POS-000001', 'CREATE', N'SEED: Creación factura POS-000001', N'{"total":104.39,"paymentMethod":"EFECTIVO"}', '192.168.1.10', DATEADD(HOUR, -6, @now));

IF NOT EXISTS (SELECT 1 FROM audit.AuditLog WHERE CompanyId = @CompanyId AND Summary = N'SEED: Creación factura POS-000002')
    INSERT INTO audit.AuditLog (CompanyId, BranchId, UserId, UserName, ModuleName, EntityName, EntityId, ActionType, Summary, NewValues, IpAddress, CreatedAt)
    VALUES (@CompanyId, @BranchId, 1, N'admin', N'POS', N'SaleTicket', N'POS-000002', 'CREATE', N'SEED: Creación factura POS-000002', N'{"total":185.57,"paymentMethod":"TDC"}', '192.168.1.10', DATEADD(HOUR, -5, @now));

IF NOT EXISTS (SELECT 1 FROM audit.AuditLog WHERE CompanyId = @CompanyId AND Summary = N'SEED: Pago aprobado TDC POS-000002')
    INSERT INTO audit.AuditLog (CompanyId, BranchId, UserId, UserName, ModuleName, EntityName, EntityId, ActionType, Summary, NewValues, IpAddress, CreatedAt)
    VALUES (@CompanyId, @BranchId, 1, N'admin', N'PAGOS', N'Transaction', N'seed-trx-pos-002', 'CREATE', N'SEED: Pago aprobado TDC POS-000002', N'{"amount":185.57,"card":"VISA****4532","status":"APPROVED"}', '192.168.1.10', DATEADD(HOUR, -5, @now));

IF NOT EXISTS (SELECT 1 FROM audit.AuditLog WHERE CompanyId = @CompanyId AND Summary = N'SEED: Creación factura POS-000003')
    INSERT INTO audit.AuditLog (CompanyId, BranchId, UserId, UserName, ModuleName, EntityName, EntityId, ActionType, Summary, NewValues, IpAddress, CreatedAt)
    VALUES (@CompanyId, @BranchId, 1, N'admin', N'POS', N'SaleTicket', N'POS-000003', 'CREATE', N'SEED: Creación factura POS-000003', N'{"total":44.06,"paymentMethod":"TRANSFERENCIA"}', '192.168.1.11', DATEADD(HOUR, -4, @now));

IF NOT EXISTS (SELECT 1 FROM audit.AuditLog WHERE CompanyId = @CompanyId AND Summary = N'SEED: Actualización precio producto ELEC-AUD-BT01')
    INSERT INTO audit.AuditLog (CompanyId, BranchId, UserId, UserName, ModuleName, EntityName, EntityId, ActionType, Summary, OldValues, NewValues, IpAddress, CreatedAt)
    VALUES (@CompanyId, @BranchId, 1, N'admin', N'INVENTARIO', N'Product', N'ELEC-AUD-BT01', 'UPDATE', N'SEED: Actualización precio producto ELEC-AUD-BT01', N'{"salesPrice":85.99}', N'{"salesPrice":89.99}', '192.168.1.10', DATEADD(HOUR, -7, @now));

IF NOT EXISTS (SELECT 1 FROM audit.AuditLog WHERE CompanyId = @CompanyId AND Summary = N'SEED: Anulación documento DEV-001')
    INSERT INTO audit.AuditLog (CompanyId, BranchId, UserId, UserName, ModuleName, EntityName, EntityId, ActionType, Summary, OldValues, IpAddress, CreatedAt)
    VALUES (@CompanyId, @BranchId, 1, N'admin', N'FACTURACION', N'Invoice', N'DEV-001', 'VOID', N'SEED: Anulación documento DEV-001', N'{"total":320.00,"reason":"Error en datos fiscales"}', '192.168.1.10', DATEADD(HOUR, -3, @now));

IF NOT EXISTS (SELECT 1 FROM audit.AuditLog WHERE CompanyId = @CompanyId AND Summary = N'SEED: Pago declinado transferencia')
    INSERT INTO audit.AuditLog (CompanyId, BranchId, UserId, UserName, ModuleName, EntityName, EntityId, ActionType, Summary, NewValues, IpAddress, CreatedAt)
    VALUES (@CompanyId, @BranchId, 1, N'admin', N'PAGOS', N'Transaction', N'seed-trx-pos-008', 'CREATE', N'SEED: Pago declinado transferencia', N'{"amount":500.00,"status":"DECLINED","reason":"Fondos insuficientes"}', '192.168.1.11', DATEADD(HOUR, -2, @now));

IF NOT EXISTS (SELECT 1 FROM audit.AuditLog WHERE CompanyId = @CompanyId AND Summary = N'SEED: Nuevo usuario cajero2 creado')
    INSERT INTO audit.AuditLog (CompanyId, BranchId, UserId, UserName, ModuleName, EntityName, EntityId, ActionType, Summary, NewValues, IpAddress, CreatedAt)
    VALUES (@CompanyId, @BranchId, 1, N'admin', N'SEGURIDAD', N'User', N'USR-002', 'CREATE', N'SEED: Nuevo usuario cajero2 creado', N'{"userName":"cajero2","role":"CAJERO","branch":1}', '192.168.1.10', DATEADD(HOUR, -7, @now));

IF NOT EXISTS (SELECT 1 FROM audit.AuditLog WHERE CompanyId = @CompanyId AND Summary = N'SEED: Eliminación producto descontinuado TEST-DISC-01')
    INSERT INTO audit.AuditLog (CompanyId, BranchId, UserId, UserName, ModuleName, EntityName, EntityId, ActionType, Summary, OldValues, IpAddress, CreatedAt)
    VALUES (@CompanyId, @BranchId, 1, N'admin', N'INVENTARIO', N'Product', N'TEST-DISC-01', 'DELETE', N'SEED: Eliminación producto descontinuado TEST-DISC-01', N'{"productName":"Producto Descontinuado","stockQty":0}', '192.168.1.10', DATEADD(HOUR, -1, @now));

PRINT 'Seeded 10 rows in audit.AuditLog';
GO

-- ═══════════════════════════════════════════════════════════════
-- RESUMEN FINAL
-- ═══════════════════════════════════════════════════════════════
PRINT '=== seed_demo_ecommerce_pos.sql — COMPLETE ===';
PRINT 'Tables seeded:';
PRINT '  master.Product ............ +6 variant children';
PRINT '  store.ProductVariant ...... +6 rows';
PRINT '  store.ProductVariantOptionValue +6 rows';
PRINT '  store.ProductAttribute .... +10 rows (6 FARMACIA + 4 ALIMENTOS)';
PRINT '  pos.WaitTicket ............ +3 tickets (6 lines)';
PRINT '  pos.SaleTicket ............ +5 tickets (9 lines)';
PRINT '  pay.Transactions .......... +8 rows';
PRINT '  audit.AuditLog ............ +10 rows';
GO
