/*  ═══════════════════════════════════════════════════════════════
    29_ecommerce_seed_data.sql — Datos de prueba para Ecommerce
    Agrega categorías, productos, imágenes y reseñas
    Compatible con SQL Server 2012 (sin OPENJSON/JSON_VALUE)
    ═══════════════════════════════════════════════════════════════ */
USE [DatqBoxWeb];
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ───────────────────────────────────────────────────────
-- 1. Nuevas categorías para ecommerce
-- ───────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [master].Category WHERE CategoryCode='ELECTRO' AND CompanyId=1)
    INSERT INTO [master].Category (CompanyId, CategoryCode, CategoryName, Description, IsActive, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (1,'ELECTRO',N'Electrónica',N'Dispositivos electrónicos',1,0,SYSUTCDATETIME(),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM [master].Category WHERE CategoryCode='HOGAR' AND CompanyId=1)
    INSERT INTO [master].Category (CompanyId, CategoryCode, CategoryName, Description, IsActive, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (1,'HOGAR',N'Hogar y Cocina',N'Artículos para el hogar',1,0,SYSUTCDATETIME(),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM [master].Category WHERE CategoryCode='DEPORTE' AND CompanyId=1)
    INSERT INTO [master].Category (CompanyId, CategoryCode, CategoryName, Description, IsActive, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (1,'DEPORTE',N'Deportes',N'Equipamiento deportivo',1,0,SYSUTCDATETIME(),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM [master].Category WHERE CategoryCode='ROPA' AND CompanyId=1)
    INSERT INTO [master].Category (CompanyId, CategoryCode, CategoryName, Description, IsActive, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (1,'ROPA',N'Ropa y Accesorios',N'Moda y accesorios',1,0,SYSUTCDATETIME(),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM [master].Category WHERE CategoryCode='SALUD' AND CompanyId=1)
    INSERT INTO [master].Category (CompanyId, CategoryCode, CategoryName, Description, IsActive, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (1,'SALUD',N'Salud y Belleza',N'Productos de salud y belleza',1,0,SYSUTCDATETIME(),SYSUTCDATETIME());
IF NOT EXISTS (SELECT 1 FROM [master].Category WHERE CategoryCode='JUGUETE' AND CompanyId=1)
    INSERT INTO [master].Category (CompanyId, CategoryCode, CategoryName, Description, IsActive, IsDeleted, CreatedAt, UpdatedAt)
    VALUES (1,'JUGUETE',N'Juguetes',N'Juguetes y juegos',1,0,SYSUTCDATETIME(),SYSUTCDATETIME());
GO

-- ───────────────────────────────────────────────────────
-- 2. Productos ecommerce (30 productos nuevos)
-- ───────────────────────────────────────────────────────
DECLARE @now DATETIME2 = SYSUTCDATETIME();

-- Electrónica (7 productos)
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='ELEC-AUD-BT01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'ELEC-AUD-BT01',N'Audífonos Bluetooth Pro - Cancelación de Ruido','ELECTRO','UND',89.99,45.00,'IVA',16,150,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='ELEC-SPKR-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'ELEC-SPKR-01',N'Parlante Portátil Waterproof 20W','ELECTRO','UND',45.99,22.00,'IVA',16,200,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='ELEC-CHRG-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'ELEC-CHRG-01',N'Cargador Inalámbrico Rápido 15W','ELECTRO','UND',29.99,12.00,'IVA',16,300,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='ELEC-PWR-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'ELEC-PWR-01',N'Power Bank 20000mAh USB-C Carga Rápida','ELECTRO','UND',39.99,18.00,'IVA',16,180,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='ELEC-WATCH-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'ELEC-WATCH-01',N'Smartwatch Fitness Tracker - Monitor Cardíaco','ELECTRO','UND',129.99,55.00,'IVA',16,100,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='ELEC-CAM-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'ELEC-CAM-01',N'Cámara Web HD 1080p con Micrófono','ELECTRO','UND',49.99,20.00,'IVA',16,120,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='ELEC-KBD-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'ELEC-KBD-01',N'Teclado Mecánico RGB Gaming','ELECTRO','UND',69.99,30.00,'IVA',16,90,0,1,0,@now,@now);

-- Hogar y Cocina (5 productos)
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='HOG-CAFE-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'HOG-CAFE-01',N'Cafetera Programable 12 Tazas con Filtro','HOGAR','UND',59.99,28.00,'IVA',16,80,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='HOG-LIC-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'HOG-LIC-01',N'Licuadora de Alta Potencia 700W','HOGAR','UND',44.99,20.00,'IVA',16,110,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='HOG-SART-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'HOG-SART-01',N'Set de Sartenes Antiadherentes (3 piezas)','HOGAR','UND',54.99,25.00,'IVA',16,70,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='HOG-LAMP-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'HOG-LAMP-01',N'Lámpara LED de Escritorio Regulable','HOGAR','UND',34.99,14.00,'IVA',16,140,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='HOG-ALMOH-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'HOG-ALMOH-01',N'Almohada Memory Foam Cervical','HOGAR','UND',24.99,10.00,'IVA',16,200,0,1,0,@now,@now);

-- Deportes (5 productos)
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='DEP-YOGA-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'DEP-YOGA-01',N'Mat de Yoga Antideslizante 6mm','DEPORTE','UND',22.99,9.00,'IVA',16,160,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='DEP-MANC-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'DEP-MANC-01',N'Set de Mancuernas Ajustables 20kg','DEPORTE','UND',79.99,35.00,'IVA',16,60,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='DEP-BOT-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'DEP-BOT-01',N'Botella Térmica Deportiva 1L Acero Inoxidable','DEPORTE','UND',19.99,7.00,'IVA',16,250,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='DEP-BAND-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'DEP-BAND-01',N'Set de Bandas Elásticas de Resistencia (5 pcs)','DEPORTE','UND',14.99,5.00,'IVA',16,300,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='DEP-MORR-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'DEP-MORR-01',N'Morral Deportivo Impermeable 40L','DEPORTE','UND',34.99,15.00,'IVA',16,130,0,1,0,@now,@now);

-- Ropa y Accesorios (4 productos)
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='ROP-CAMI-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'ROP-CAMI-01',N'Camiseta Deportiva Dry-Fit','ROPA','UND',18.99,7.00,'IVA',16,400,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='ROP-GORRA-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'ROP-GORRA-01',N'Gorra Deportiva Ajustable UV Protection','ROPA','UND',15.99,5.50,'IVA',16,350,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='ROP-ZAP-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'ROP-ZAP-01',N'Zapatillas Running Ultralight','ROPA','UND',74.99,32.00,'IVA',16,90,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='ROP-LENT-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'ROP-LENT-01',N'Lentes de Sol Polarizados UV400','ROPA','UND',27.99,10.00,'IVA',16,220,0,1,0,@now,@now);

-- Salud y Belleza (3 productos)
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='SAL-PROT-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'SAL-PROT-01',N'Proteína Whey 2lb Sabor Chocolate','SALUD','UND',42.99,20.00,'IVA',16,100,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='SAL-VIT-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'SAL-VIT-01',N'Multivitamínico Completo 90 Cápsulas','SALUD','UND',19.99,8.00,'IVA',16,250,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='SAL-CREMA-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'SAL-CREMA-01',N'Crema Hidratante Facial SPF 30','SALUD','UND',16.99,6.00,'IVA',16,180,0,1,0,@now,@now);

-- Tecnología / Oficina (3 productos)
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='TEC-MOUSE-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'TEC-MOUSE-01',N'Mouse Ergonómico Inalámbrico Recargable','TECNOL','UND',32.99,13.00,'IVA',16,170,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='TEC-HUB-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'TEC-HUB-01',N'Hub USB-C 7 en 1 HDMI/USB/SD','TECNOL','UND',38.99,16.00,'IVA',16,140,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='TEC-SOPORT-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'TEC-SOPORT-01',N'Soporte Laptop Aluminio Ajustable','TECNOL','UND',28.99,11.00,'IVA',16,120,0,1,0,@now,@now);

-- Juguetes (2 productos)
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='JUG-DRON-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'JUG-DRON-01',N'Mini Drone con Cámara HD para Principiantes','JUGUETE','UND',59.99,25.00,'IVA',16,75,0,1,0,@now,@now);
IF NOT EXISTS (SELECT 1 FROM [master].Product WHERE ProductCode='JUG-LEGO-01' AND CompanyId=1)
    INSERT INTO [master].Product (CompanyId,ProductCode,ProductName,CategoryCode,UnitCode,SalesPrice,CostPrice,DefaultTaxCode,DefaultTaxRate,StockQty,IsService,IsActive,IsDeleted,CreatedAt,UpdatedAt)
    VALUES (1,'JUG-LEGO-01',N'Set de Construcción 500 Piezas Creativo','JUGUETE','UND',34.99,14.00,'IVA',16,95,0,1,0,@now,@now);
GO

-- ───────────────────────────────────────────────────────
-- 3. Imágenes de productos (MediaAsset + EntityImage)
-- ───────────────────────────────────────────────────────
DECLARE @now2 DATETIME2 = SYSUTCDATETIME();
DECLARE @pc NVARCHAR(60), @url NVARCHAR(500), @alt NVARCHAR(200), @prim BIT, @sort INT;
DECLARE @maId INT, @prodId BIGINT;

-- Tabla temporal para mapear productos a sus imágenes
DECLARE @imgs TABLE (
    ProductCode NVARCHAR(60),
    ImgUrl NVARCHAR(500),
    AltText NVARCHAR(200),
    IsPrimary BIT,
    SortOrder INT
);

-- Electrónica
INSERT INTO @imgs VALUES ('ELEC-AUD-BT01','https://picsum.photos/seed/headphones1/600/600',N'Audífonos Bluetooth Pro',1,1);
INSERT INTO @imgs VALUES ('ELEC-AUD-BT01','https://picsum.photos/seed/headphones2/600/600',N'Audífonos vista lateral',0,2);
INSERT INTO @imgs VALUES ('ELEC-AUD-BT01','https://picsum.photos/seed/headphones3/600/600',N'Audífonos en estuche',0,3);
INSERT INTO @imgs VALUES ('ELEC-SPKR-01','https://picsum.photos/seed/speaker1/600/600',N'Parlante Portátil',1,1);
INSERT INTO @imgs VALUES ('ELEC-SPKR-01','https://picsum.photos/seed/speaker2/600/600',N'Parlante vista trasera',0,2);
INSERT INTO @imgs VALUES ('ELEC-CHRG-01','https://picsum.photos/seed/charger1/600/600',N'Cargador Inalámbrico',1,1);
INSERT INTO @imgs VALUES ('ELEC-CHRG-01','https://picsum.photos/seed/charger2/600/600',N'Cargador con teléfono',0,2);
INSERT INTO @imgs VALUES ('ELEC-PWR-01','https://picsum.photos/seed/powerbank1/600/600',N'Power Bank 20000mAh',1,1);
INSERT INTO @imgs VALUES ('ELEC-PWR-01','https://picsum.photos/seed/powerbank2/600/600',N'Power Bank puertos',0,2);
INSERT INTO @imgs VALUES ('ELEC-WATCH-01','https://picsum.photos/seed/smartwatch1/600/600',N'Smartwatch Fitness',1,1);
INSERT INTO @imgs VALUES ('ELEC-WATCH-01','https://picsum.photos/seed/smartwatch2/600/600',N'Smartwatch en muñeca',0,2);
INSERT INTO @imgs VALUES ('ELEC-WATCH-01','https://picsum.photos/seed/smartwatch3/600/600',N'Smartwatch funciones',0,3);
INSERT INTO @imgs VALUES ('ELEC-CAM-01','https://picsum.photos/seed/webcam1/600/600',N'Cámara Web HD',1,1);
INSERT INTO @imgs VALUES ('ELEC-KBD-01','https://picsum.photos/seed/keyboard1/600/600',N'Teclado Mecánico RGB',1,1);
INSERT INTO @imgs VALUES ('ELEC-KBD-01','https://picsum.photos/seed/keyboard2/600/600',N'Teclado iluminación',0,2);

-- Hogar
INSERT INTO @imgs VALUES ('HOG-CAFE-01','https://picsum.photos/seed/coffeemaker1/600/600',N'Cafetera Programable',1,1);
INSERT INTO @imgs VALUES ('HOG-CAFE-01','https://picsum.photos/seed/coffeemaker2/600/600',N'Cafetera panel',0,2);
INSERT INTO @imgs VALUES ('HOG-LIC-01','https://picsum.photos/seed/blender1/600/600',N'Licuadora Alta Potencia',1,1);
INSERT INTO @imgs VALUES ('HOG-SART-01','https://picsum.photos/seed/pans1/600/600',N'Set Sartenes',1,1);
INSERT INTO @imgs VALUES ('HOG-SART-01','https://picsum.photos/seed/pans2/600/600',N'Sartenes detalle',0,2);
INSERT INTO @imgs VALUES ('HOG-LAMP-01','https://picsum.photos/seed/desklamp1/600/600',N'Lámpara LED',1,1);
INSERT INTO @imgs VALUES ('HOG-ALMOH-01','https://picsum.photos/seed/pillow1/600/600',N'Almohada Memory Foam',1,1);

-- Deportes
INSERT INTO @imgs VALUES ('DEP-YOGA-01','https://picsum.photos/seed/yogamat1/600/600',N'Mat de Yoga',1,1);
INSERT INTO @imgs VALUES ('DEP-YOGA-01','https://picsum.photos/seed/yogamat2/600/600',N'Mat de Yoga enrollado',0,2);
INSERT INTO @imgs VALUES ('DEP-MANC-01','https://picsum.photos/seed/dumbbells1/600/600',N'Set Mancuernas',1,1);
INSERT INTO @imgs VALUES ('DEP-MANC-01','https://picsum.photos/seed/dumbbells2/600/600',N'Mancuernas detalle',0,2);
INSERT INTO @imgs VALUES ('DEP-BOT-01','https://picsum.photos/seed/bottle1/600/600',N'Botella Térmica',1,1);
INSERT INTO @imgs VALUES ('DEP-BAND-01','https://picsum.photos/seed/bands1/600/600',N'Bandas Elásticas',1,1);
INSERT INTO @imgs VALUES ('DEP-MORR-01','https://picsum.photos/seed/backpack1/600/600',N'Morral Deportivo',1,1);
INSERT INTO @imgs VALUES ('DEP-MORR-01','https://picsum.photos/seed/backpack2/600/600',N'Morral interior',0,2);

-- Ropa
INSERT INTO @imgs VALUES ('ROP-CAMI-01','https://picsum.photos/seed/tshirt1/600/600',N'Camiseta Deportiva',1,1);
INSERT INTO @imgs VALUES ('ROP-GORRA-01','https://picsum.photos/seed/cap1/600/600',N'Gorra Deportiva',1,1);
INSERT INTO @imgs VALUES ('ROP-ZAP-01','https://picsum.photos/seed/shoes1/600/600',N'Zapatillas Running',1,1);
INSERT INTO @imgs VALUES ('ROP-ZAP-01','https://picsum.photos/seed/shoes2/600/600',N'Zapatillas suela',0,2);
INSERT INTO @imgs VALUES ('ROP-ZAP-01','https://picsum.photos/seed/shoes3/600/600',N'Zapatillas lateral',0,3);
INSERT INTO @imgs VALUES ('ROP-LENT-01','https://picsum.photos/seed/sunglasses1/600/600',N'Lentes Polarizados',1,1);

-- Salud
INSERT INTO @imgs VALUES ('SAL-PROT-01','https://picsum.photos/seed/protein1/600/600',N'Proteína Whey',1,1);
INSERT INTO @imgs VALUES ('SAL-VIT-01','https://picsum.photos/seed/vitamins1/600/600',N'Multivitamínico',1,1);
INSERT INTO @imgs VALUES ('SAL-CREMA-01','https://picsum.photos/seed/cream1/600/600',N'Crema Hidratante',1,1);

-- Tecnología
INSERT INTO @imgs VALUES ('TEC-MOUSE-01','https://picsum.photos/seed/mouse1/600/600',N'Mouse Ergonómico',1,1);
INSERT INTO @imgs VALUES ('TEC-MOUSE-01','https://picsum.photos/seed/mouse2/600/600',N'Mouse vista lateral',0,2);
INSERT INTO @imgs VALUES ('TEC-HUB-01','https://picsum.photos/seed/usbhub1/600/600',N'Hub USB-C',1,1);
INSERT INTO @imgs VALUES ('TEC-SOPORT-01','https://picsum.photos/seed/stand1/600/600',N'Soporte Laptop',1,1);

-- Juguetes
INSERT INTO @imgs VALUES ('JUG-DRON-01','https://picsum.photos/seed/drone1/600/600',N'Mini Drone HD',1,1);
INSERT INTO @imgs VALUES ('JUG-DRON-01','https://picsum.photos/seed/drone2/600/600',N'Drone en vuelo',0,2);
INSERT INTO @imgs VALUES ('JUG-LEGO-01','https://picsum.photos/seed/blocks1/600/600',N'Set Construcción',1,1);

-- Insertar MediaAsset + EntityImage para cada imagen via cursor
DECLARE img_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT i.ProductCode, i.ImgUrl, i.AltText, i.IsPrimary, i.SortOrder
    FROM @imgs i;

OPEN img_cursor;
FETCH NEXT FROM img_cursor INTO @pc, @url, @alt, @prim, @sort;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @prodId = ProductId FROM [master].Product WHERE CompanyId=1 AND ProductCode=@pc AND IsDeleted=0;

    IF @prodId IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM cfg.MediaAsset ma
        INNER JOIN cfg.EntityImage ei ON ei.MediaAssetId = ma.MediaAssetId
        WHERE ma.PublicUrl = @url AND ei.EntityId = @prodId AND ei.EntityType = N'MASTER_PRODUCT'
    )
    BEGIN
        INSERT INTO cfg.MediaAsset (
            CompanyId, BranchId, StorageProvider, StorageKey, PublicUrl,
            OriginalFileName, MimeType, FileExtension, FileSizeBytes,
            AltText, WidthPx, HeightPx,
            IsActive, IsDeleted, CreatedAt, UpdatedAt
        ) VALUES (
            1, 1, N'external', @url, @url,
            @pc + N'.jpg', N'image/jpeg', N'.jpg', 0,
            @alt, 600, 600,
            1, 0, @now2, @now2
        );
        SET @maId = SCOPE_IDENTITY();

        INSERT INTO cfg.EntityImage (
            CompanyId, BranchId, EntityType, EntityId, MediaAssetId,
            RoleCode, SortOrder, IsPrimary, IsActive, IsDeleted, CreatedAt, UpdatedAt
        ) VALUES (
            1, 1, N'MASTER_PRODUCT', @prodId, @maId,
            N'PRODUCT_IMAGE', @sort, @prim, 1, 0, @now2, @now2
        );
    END;

    FETCH NEXT FROM img_cursor INTO @pc, @url, @alt, @prim, @sort;
END;

CLOSE img_cursor;
DEALLOCATE img_cursor;
GO

-- ───────────────────────────────────────────────────────
-- 4. Reseñas de productos (~50 reseñas variadas)
-- ───────────────────────────────────────────────────────
DECLARE @now3 DATETIME2 = SYSUTCDATETIME();

IF (SELECT COUNT(*) FROM store.ProductReview WHERE CompanyId=1) < 10
BEGIN
    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'ELEC-AUD-BT01',5,N'Excelente calidad de sonido',N'Los mejores audífonos que he tenido. La cancelación de ruido es increíble.',N'María G.',N'maria@test.com',1,1,0,DATEADD(DAY,-30,@now3)),
    (1,'ELEC-AUD-BT01',4,N'Muy buenos, batería dura bastante',N'La batería dura todo el día. El único detalle es que aprietan un poco al principio.',N'Carlos R.',N'carlos@test.com',1,1,0,DATEADD(DAY,-25,@now3)),
    (1,'ELEC-AUD-BT01',5,N'Los recomiendo al 100%',N'Uso estos audífonos para trabajar desde casa y son perfectos. Muy cómodos.',N'Ana P.',N'ana@test.com',0,1,0,DATEADD(DAY,-20,@now3)),
    (1,'ELEC-AUD-BT01',4,N'Buen producto',N'Buena relación precio-calidad. El sonido es claro y los bajos potentes.',N'Pedro M.',N'pedro@test.com',1,1,0,DATEADD(DAY,-15,@now3)),
    (1,'ELEC-AUD-BT01',3,N'Están bien',N'Cumplen su función. Esperaba un poco más de la cancelación de ruido.',N'Laura S.',N'laura@test.com',0,1,0,DATEADD(DAY,-10,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'ELEC-WATCH-01',5,N'Impresionante para el precio',N'Monitoreo cardíaco preciso, GPS funciona bien. Muy satisfecho con la compra.',N'Roberto L.',N'roberto@test.com',1,1,0,DATEADD(DAY,-28,@now3)),
    (1,'ELEC-WATCH-01',4,N'Buen smartwatch',N'La pantalla se ve muy bien al sol. Las notificaciones funcionan perfectamente.',N'Sandra K.',N'sandra@test.com',1,1,0,DATEADD(DAY,-22,@now3)),
    (1,'ELEC-WATCH-01',5,N'Lo uso para correr',N'Excelente tracker de actividad. Lo uso todos los días para mis carreras.',N'Diego F.',N'diego@test.com',0,1,0,DATEADD(DAY,-18,@now3)),
    (1,'ELEC-WATCH-01',4,N'Muy útil',N'Las funciones de salud son muy completas. Me encanta el monitor de sueño.',N'Patricia V.',N'patricia@test.com',1,1,0,DATEADD(DAY,-12,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'HOG-CAFE-01',5,N'El mejor café en casa',N'Hace un café delicioso. La función de programación es genial para las mañanas.',N'Fernando A.',N'fernando@test.com',1,1,0,DATEADD(DAY,-35,@now3)),
    (1,'HOG-CAFE-01',4,N'Muy buena cafetera',N'Fácil de usar y limpiar. El café sale caliente y con buen sabor.',N'Lucía M.',N'lucia@test.com',1,1,0,DATEADD(DAY,-27,@now3)),
    (1,'HOG-CAFE-01',5,N'Perfecta',N'La uso todos los días. 12 tazas es perfecto para la oficina.',N'Andrés B.',N'andres@test.com',0,1,0,DATEADD(DAY,-19,@now3)),
    (1,'HOG-CAFE-01',3,N'Buena pero...',N'El café es bueno pero la jarra es un poco frágil. Cuidado al lavarla.',N'Marta C.',N'marta@test.com',1,1,0,DATEADD(DAY,-14,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'DEP-YOGA-01',5,N'Perfecto para yoga',N'Antideslizante de verdad. Muy cómodo para las rodillas.',N'Valentina R.',N'valentina@test.com',1,1,0,DATEADD(DAY,-32,@now3)),
    (1,'DEP-YOGA-01',4,N'Buen material',N'Buena calidad, no se deforma. Lo recomiendo para principiantes.',N'Camila H.',N'camila@test.com',0,1,0,DATEADD(DAY,-24,@now3)),
    (1,'DEP-YOGA-01',5,N'Excelente',N'Lo uso para pilates y yoga. El grosor de 6mm es ideal.',N'Gabriela T.',N'gabriela@test.com',1,1,0,DATEADD(DAY,-16,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'ELEC-PWR-01',5,N'Indispensable para viajes',N'Carga mi teléfono 4 veces. La carga rápida funciona genial.',N'Juan D.',N'juan@test.com',1,1,0,DATEADD(DAY,-29,@now3)),
    (1,'ELEC-PWR-01',4,N'Muy buena capacidad',N'20000mAh es suficiente para varios dispositivos. Un poco pesado pero vale la pena.',N'Miguel S.',N'miguel@test.com',1,1,0,DATEADD(DAY,-21,@now3)),
    (1,'ELEC-PWR-01',5,N'Excelente power bank',N'USB-C de entrada y salida. Carga rápida tanto para cargar como descargar.',N'Isabel F.',N'isabel@test.com',0,1,0,DATEADD(DAY,-13,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'ROP-ZAP-01',5,N'Las mejores para correr',N'Super livianas y cómodas. Las uso para mis maratones y son increíbles.',N'Alejandro P.',N'alejandro@test.com',1,1,0,DATEADD(DAY,-33,@now3)),
    (1,'ROP-ZAP-01',4,N'Muy cómodas',N'El ajuste es perfecto. La amortiguación es buena para carreras largas.',N'Daniela V.',N'daniela@test.com',1,1,0,DATEADD(DAY,-26,@now3)),
    (1,'ROP-ZAP-01',5,N'Excelente calzado',N'Las uso todos los días para el gimnasio. Muy livianas y con buen soporte.',N'Tomás M.',N'tomas@test.com',0,1,0,DATEADD(DAY,-17,@now3)),
    (1,'ROP-ZAP-01',4,N'Buena compra',N'El diseño es bonito y son muy cómodas. La suela tiene buen agarre.',N'Carolina L.',N'carolina@test.com',1,1,0,DATEADD(DAY,-9,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'ELEC-KBD-01',5,N'Increíble para gaming',N'Los switches son suaves y la iluminación RGB es espectacular.',N'Nicolás G.',N'nicolas@test.com',1,1,0,DATEADD(DAY,-31,@now3)),
    (1,'ELEC-KBD-01',4,N'Muy buen teclado',N'Excelente para programar también. Los switches son silenciosos.',N'Sofía R.',N'sofia@test.com',0,1,0,DATEADD(DAY,-23,@now3)),
    (1,'ELEC-KBD-01',5,N'El mejor teclado',N'La calidad de construcción es premium. Los keycaps se sienten muy bien.',N'Mateo H.',N'mateo@test.com',1,1,0,DATEADD(DAY,-15,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'SAL-PROT-01',5,N'Sabor increíble',N'El sabor chocolate es delicioso. Se mezcla bien y no deja grumos.',N'Ricardo T.',N'ricardo@test.com',1,1,0,DATEADD(DAY,-34,@now3)),
    (1,'SAL-PROT-01',4,N'Buena proteína',N'25g de proteína por scoop. Buena relación calidad-precio.',N'Elena K.',N'elena@test.com',1,1,0,DATEADD(DAY,-26,@now3)),
    (1,'SAL-PROT-01',5,N'La mejor del mercado',N'Llevo 6 meses usándola. Los resultados son notorios.',N'David A.',N'david@test.com',0,1,0,DATEADD(DAY,-18,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'DEP-MANC-01',5,N'Perfectas para casa',N'El sistema ajustable es muy práctico. Reemplazan varios pares de mancuernas.',N'Andrés R.',N'andres.r@test.com',1,1,0,DATEADD(DAY,-30,@now3)),
    (1,'DEP-MANC-01',4,N'Buena inversión',N'La calidad es buena. El agarre es cómodo y los discos están bien balanceados.',N'Paula M.',N'paula@test.com',1,1,0,DATEADD(DAY,-22,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'ELEC-SPKR-01',5,N'Sonido potente',N'20W de potencia real. Lo usé en la piscina y funciona perfecto.',N'Jorge L.',N'jorge@test.com',1,1,0,DATEADD(DAY,-28,@now3)),
    (1,'ELEC-SPKR-01',4,N'Buen parlante',N'Resistente al agua como dice. La batería dura unas 8 horas.',N'Natalia S.',N'natalia@test.com',0,1,0,DATEADD(DAY,-20,@now3)),
    (1,'ELEC-SPKR-01',5,N'Excelente compra',N'El bajo es increíble para su tamaño. Lo llevo a todas partes.',N'Sebastián V.',N'sebastian@test.com',1,1,0,DATEADD(DAY,-12,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'JUG-DRON-01',4,N'Divertido',N'Muy fácil de volar. La cámara tiene buena calidad para el precio.',N'Luis H.',N'luis@test.com',1,1,0,DATEADD(DAY,-27,@now3)),
    (1,'JUG-DRON-01',5,N'Regalo perfecto',N'Se lo regalé a mi hijo y está encantado. Muy estable y fácil de controlar.',N'Carmen D.',N'carmen@test.com',0,1,0,DATEADD(DAY,-19,@now3)),
    (1,'JUG-DRON-01',4,N'Bueno para empezar',N'Ideal para principiantes. La batería dura unos 15 minutos.',N'Alberto F.',N'alberto@test.com',1,1,0,DATEADD(DAY,-11,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'TEC-MOUSE-01',5,N'Adiós dolor de muñeca',N'Desde que uso este mouse ergonómico se me quitó el dolor de muñeca.',N'Andrea G.',N'andrea@test.com',1,1,0,DATEADD(DAY,-29,@now3)),
    (1,'TEC-MOUSE-01',4,N'Muy cómodo',N'El diseño ergonómico es excelente. La batería dura semanas.',N'Cristian B.',N'cristian@test.com',1,1,0,DATEADD(DAY,-21,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'HOG-LIC-01',5,N'Potente',N'Licúa hasta hielo sin problemas. 700W de potencia real.',N'Rosa P.',N'rosa@test.com',1,1,0,DATEADD(DAY,-26,@now3)),
    (1,'HOG-LIC-01',4,N'Muy buena',N'Hago smoothies todos los días. Fácil de lavar y usar.',N'Manuel T.',N'manuel@test.com',0,1,0,DATEADD(DAY,-18,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'DEP-BAND-01',5,N'Excelente set',N'5 niveles de resistencia. Perfectas para entrenar en casa.',N'Valeria M.',N'valeria@test.com',1,1,0,DATEADD(DAY,-25,@now3)),
    (1,'DEP-BAND-01',5,N'Las uso todos los días',N'Muy resistentes y no se deforman. Vienen con bolsa de transporte.',N'Esteban R.',N'esteban@test.com',0,1,0,DATEADD(DAY,-17,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'TEC-HUB-01',5,N'Indispensable',N'7 puertos en uno. HDMI funciona perfecto a 4K. Lo uso con mi MacBook.',N'Joaquín L.',N'joaquin@test.com',1,1,0,DATEADD(DAY,-24,@now3)),
    (1,'TEC-HUB-01',4,N'Muy práctico',N'Todos los puertos funcionan bien. El cable es un poco corto.',N'Mariana F.',N'mariana@test.com',1,1,0,DATEADD(DAY,-16,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'ELEC-CHRG-01',5,N'Carga rápida real',N'15W de carga reales. Mi teléfono se carga en 2 horas.',N'Daniela M.',N'daniela.m@test.com',1,1,0,DATEADD(DAY,-23,@now3)),
    (1,'ELEC-CHRG-01',4,N'Bueno y bonito',N'Diseño elegante y funcional. Compatible con todos mis dispositivos.',N'Martín R.',N'martin@test.com',0,1,0,DATEADD(DAY,-15,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'HOG-SART-01',5,N'Excelentes sartenes',N'Nada se pega. Muy fáciles de limpiar y el mango no se calienta.',N'Gloria T.',N'gloria@test.com',1,1,0,DATEADD(DAY,-31,@now3)),
    (1,'HOG-SART-01',4,N'Buena calidad',N'El set de 3 tamaños es perfecto. El antiadherente funciona bien.',N'Ramón L.',N'ramon@test.com',1,1,0,DATEADD(DAY,-22,@now3));

    INSERT INTO store.ProductReview (CompanyId,ProductCode,Rating,Title,Comment,ReviewerName,ReviewerEmail,IsVerified,IsApproved,IsDeleted,CreatedAt) VALUES
    (1,'DEP-BOT-01',5,N'Mantiene la temperatura',N'Agua fría por 24 horas. Excelente calidad del acero.',N'Camilo V.',N'camilo@test.com',1,1,0,DATEADD(DAY,-20,@now3)),
    (1,'DEP-BOT-01',4,N'Perfecta para el gym',N'1 litro es suficiente. No gotea y el diseño es muy bonito.',N'Silvia G.',N'silvia@test.com',0,1,0,DATEADD(DAY,-12,@now3));
END;
GO

PRINT '=== 29_ecommerce_seed_data.sql OK ===';
GO
