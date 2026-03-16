/*  ═══════════════════════════════════════════════════════════════
    usp_ecommerce_variants.sql — Variantes de Producto + Atributos por Industria
    Tablas nuevas: store.ProductVariantGroup, store.ProductVariantOption,
                   store.ProductVariant, store.ProductVariantOptionValue,
                   store.IndustryTemplate, store.IndustryTemplateAttribute,
                   store.ProductAttribute
    Columnas nuevas en master.Product: IsVariantParent, ParentProductCode,
                                       IndustryTemplateCode
    ═══════════════════════════════════════════════════════════════ */

USE [DatqBoxWeb];
GO

-- ═══════════════════════════════════════════════════════════════
-- PARTE 1: DDL — Columnas nuevas en master.Product
-- ═══════════════════════════════════════════════════════════════

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'IsVariantParent')
    ALTER TABLE [master].Product ADD IsVariantParent BIT NOT NULL DEFAULT 0;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'ParentProductCode')
    ALTER TABLE [master].Product ADD ParentProductCode NVARCHAR(80) NULL;
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[master].Product') AND name = 'IndustryTemplateCode')
    ALTER TABLE [master].Product ADD IndustryTemplateCode NVARCHAR(30) NULL;
GO

PRINT 'Added columns IsVariantParent, ParentProductCode, IndustryTemplateCode to master.Product';
GO

-- ═══════════════════════════════════════════════════════════════
-- PARTE 2: DDL — Tablas de variantes
-- ═══════════════════════════════════════════════════════════════

-- 2a. Grupos de variación (Color, Talla, Capacidad...)
IF OBJECT_ID('store.ProductVariantGroup', 'U') IS NULL
BEGIN
    CREATE TABLE store.ProductVariantGroup (
        VariantGroupId   INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId        INT            NOT NULL DEFAULT 1,
        GroupCode        NVARCHAR(30)   NOT NULL,   -- COLOR, TALLA, CAPACIDAD
        GroupName        NVARCHAR(100)  NOT NULL,   -- Color, Talla, Capacidad
        DisplayType      NVARCHAR(20)   NOT NULL DEFAULT N'BUTTON',  -- BUTTON, SWATCH, DROPDOWN, IMAGE
        SortOrder        INT            NOT NULL DEFAULT 0,
        IsActive         BIT            NOT NULL DEFAULT 1,
        IsDeleted        BIT            NOT NULL DEFAULT 0,
        CreatedAt        DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_ProductVariantGroup_Code UNIQUE (CompanyId, GroupCode)
    );
    CREATE NONCLUSTERED INDEX IX_ProductVariantGroup_Company
        ON store.ProductVariantGroup (CompanyId, IsDeleted, IsActive)
        INCLUDE (GroupCode, GroupName, DisplayType, SortOrder);
    PRINT 'Created table store.ProductVariantGroup';
END;
GO

-- 2b. Opciones dentro de un grupo (Rojo, Azul, S, M, L, 128GB...)
IF OBJECT_ID('store.ProductVariantOption', 'U') IS NULL
BEGIN
    CREATE TABLE store.ProductVariantOption (
        VariantOptionId  INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId        INT            NOT NULL DEFAULT 1,
        VariantGroupId   INT            NOT NULL,
        OptionCode       NVARCHAR(30)   NOT NULL,   -- ROJO, AZUL, S, M, L
        OptionLabel      NVARCHAR(100)  NOT NULL,   -- Rojo, Azul, S, M, L
        ColorHex         NVARCHAR(7)    NULL,        -- #FF0000 (solo para SWATCH)
        ImageUrl         NVARCHAR(500)  NULL,        -- URL miniatura (solo para IMAGE)
        SortOrder        INT            NOT NULL DEFAULT 0,
        IsActive         BIT            NOT NULL DEFAULT 1,
        IsDeleted        BIT            NOT NULL DEFAULT 0,
        CreatedAt        DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_VariantOption_Group FOREIGN KEY (VariantGroupId) REFERENCES store.ProductVariantGroup(VariantGroupId),
        CONSTRAINT UQ_VariantOption_Code UNIQUE (CompanyId, VariantGroupId, OptionCode)
    );
    CREATE NONCLUSTERED INDEX IX_ProductVariantOption_Group
        ON store.ProductVariantOption (VariantGroupId, IsDeleted, IsActive)
        INCLUDE (OptionCode, OptionLabel, ColorHex, SortOrder);
    PRINT 'Created table store.ProductVariantOption';
END;
GO

-- 2c. Variantes de producto (vincula producto padre <-> producto hijo)
IF OBJECT_ID('store.ProductVariant', 'U') IS NULL
BEGIN
    CREATE TABLE store.ProductVariant (
        ProductVariantId    INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId           INT            NOT NULL DEFAULT 1,
        ParentProductCode   NVARCHAR(80)   NOT NULL,  -- el producto "padre"
        VariantProductCode  NVARCHAR(80)   NOT NULL,  -- el producto hijo (real en master.Product)
        SKU                 NVARCHAR(80)   NULL,       -- SKU de la variante (si difiere)
        PriceDelta          DECIMAL(18,2)  NOT NULL DEFAULT 0,  -- delta vs padre (+5, -3, 0)
        StockOverride       DECIMAL(18,4)  NULL,       -- NULL = usar stock del producto hijo
        IsDefault           BIT            NOT NULL DEFAULT 0,
        SortOrder           INT            NOT NULL DEFAULT 0,
        IsActive            BIT            NOT NULL DEFAULT 1,
        IsDeleted           BIT            NOT NULL DEFAULT 0,
        CreatedAt           DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_ProductVariant_Code UNIQUE (CompanyId, ParentProductCode, VariantProductCode)
    );
    CREATE NONCLUSTERED INDEX IX_ProductVariant_Parent
        ON store.ProductVariant (CompanyId, ParentProductCode, IsDeleted, IsActive)
        INCLUDE (VariantProductCode, PriceDelta, StockOverride, IsDefault, SortOrder);
    PRINT 'Created table store.ProductVariant';
END;
GO

-- 2d. Valores de opciones por variante (N:M entre variante y opciones elegidas)
IF OBJECT_ID('store.ProductVariantOptionValue', 'U') IS NULL
BEGIN
    CREATE TABLE store.ProductVariantOptionValue (
        VariantOptionValueId INT IDENTITY(1,1) PRIMARY KEY,
        ProductVariantId     INT NOT NULL,
        VariantOptionId      INT NOT NULL,
        CONSTRAINT FK_PVOV_Variant FOREIGN KEY (ProductVariantId) REFERENCES store.ProductVariant(ProductVariantId),
        CONSTRAINT FK_PVOV_Option FOREIGN KEY (VariantOptionId) REFERENCES store.ProductVariantOption(VariantOptionId),
        CONSTRAINT UQ_PVOV UNIQUE (ProductVariantId, VariantOptionId)
    );
    PRINT 'Created table store.ProductVariantOptionValue';
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- PARTE 3: DDL — Tablas de atributos por industria
-- ═══════════════════════════════════════════════════════════════

-- 3a. Plantillas de industria
IF OBJECT_ID('store.IndustryTemplate', 'U') IS NULL
BEGIN
    CREATE TABLE store.IndustryTemplate (
        IndustryTemplateId   INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId            INT            NOT NULL DEFAULT 1,
        TemplateCode         NVARCHAR(30)   NOT NULL,   -- FARMACIA, ROPA, ELECTRONICA, ALIMENTOS
        TemplateName         NVARCHAR(100)  NOT NULL,   -- Farmacia, Ropa y Calzado, etc.
        Description          NVARCHAR(500)  NULL,
        IconName             NVARCHAR(50)   NULL,        -- nombre de ícono en MUI
        SortOrder            INT            NOT NULL DEFAULT 0,
        IsActive             BIT            NOT NULL DEFAULT 1,
        IsDeleted            BIT            NOT NULL DEFAULT 0,
        CreatedAt            DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_IndustryTemplate_Code UNIQUE (CompanyId, TemplateCode)
    );
    PRINT 'Created table store.IndustryTemplate';
END;
GO

-- 3b. Definición de atributos por plantilla
IF OBJECT_ID('store.IndustryTemplateAttribute', 'U') IS NULL
BEGIN
    CREATE TABLE store.IndustryTemplateAttribute (
        TemplateAttributeId INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId           INT            NOT NULL DEFAULT 1,
        TemplateCode        NVARCHAR(30)   NOT NULL,
        AttributeKey        NVARCHAR(50)   NOT NULL,   -- PrincipioActivo, Concentracion...
        AttributeLabel      NVARCHAR(100)  NOT NULL,   -- Principio Activo, Concentración...
        DataType            NVARCHAR(20)   NOT NULL DEFAULT N'TEXT',  -- TEXT, NUMBER, DATE, BOOLEAN, LIST
        IsRequired          BIT            NOT NULL DEFAULT 0,
        DefaultValue        NVARCHAR(200)  NULL,
        ListOptions         NVARCHAR(MAX)  NULL,        -- JSON array para DataType=LIST ej: ["Tableta","Cápsula","Jarabe"]
        DisplayGroup        NVARCHAR(100)  NOT NULL DEFAULT N'General',  -- agrupación visual
        SortOrder           INT            NOT NULL DEFAULT 0,
        IsActive            BIT            NOT NULL DEFAULT 1,
        IsDeleted           BIT            NOT NULL DEFAULT 0,
        CreatedAt           DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_TemplateAttribute_Key UNIQUE (CompanyId, TemplateCode, AttributeKey)
    );
    CREATE NONCLUSTERED INDEX IX_TemplateAttribute_Template
        ON store.IndustryTemplateAttribute (CompanyId, TemplateCode, IsDeleted, IsActive)
        INCLUDE (AttributeKey, AttributeLabel, DataType, DisplayGroup, SortOrder);
    PRINT 'Created table store.IndustryTemplateAttribute';
END;
GO

-- 3c. Valores de atributos asignados a productos (EAV tipado)
IF OBJECT_ID('store.ProductAttribute', 'U') IS NULL
BEGIN
    CREATE TABLE store.ProductAttribute (
        ProductAttributeId INT IDENTITY(1,1) PRIMARY KEY,
        CompanyId          INT            NOT NULL DEFAULT 1,
        ProductCode        NVARCHAR(80)   NOT NULL,
        TemplateCode       NVARCHAR(30)   NOT NULL,
        AttributeKey       NVARCHAR(50)   NOT NULL,
        ValueText          NVARCHAR(500)  NULL,
        ValueNumber        DECIMAL(18,4)  NULL,
        ValueDate          DATE           NULL,
        ValueBoolean       BIT            NULL,
        IsActive           BIT            NOT NULL DEFAULT 1,
        IsDeleted          BIT            NOT NULL DEFAULT 0,
        CreatedAt          DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt          DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_ProductAttribute_Key UNIQUE (CompanyId, ProductCode, AttributeKey)
    );
    CREATE NONCLUSTERED INDEX IX_ProductAttribute_Product
        ON store.ProductAttribute (CompanyId, ProductCode, IsDeleted, IsActive)
        INCLUDE (TemplateCode, AttributeKey, ValueText, ValueNumber, ValueDate, ValueBoolean);
    PRINT 'Created table store.ProductAttribute';
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- PARTE 4: SEED — Plantillas de industria con atributos
-- ═══════════════════════════════════════════════════════════════

-- 4a. Plantillas
IF NOT EXISTS (SELECT 1 FROM store.IndustryTemplate WHERE TemplateCode = N'FARMACIA' AND CompanyId = 1)
    INSERT INTO store.IndustryTemplate (CompanyId, TemplateCode, TemplateName, Description, IconName, SortOrder)
    VALUES (1, N'FARMACIA', N'Farmacia', N'Medicamentos, suplementos y productos farmacéuticos', N'LocalPharmacy', 1);

IF NOT EXISTS (SELECT 1 FROM store.IndustryTemplate WHERE TemplateCode = N'ROPA' AND CompanyId = 1)
    INSERT INTO store.IndustryTemplate (CompanyId, TemplateCode, TemplateName, Description, IconName, SortOrder)
    VALUES (1, N'ROPA', N'Ropa y Calzado', N'Prendas de vestir, calzado y accesorios de moda', N'Checkroom', 2);

IF NOT EXISTS (SELECT 1 FROM store.IndustryTemplate WHERE TemplateCode = N'ELECTRONICA' AND CompanyId = 1)
    INSERT INTO store.IndustryTemplate (CompanyId, TemplateCode, TemplateName, Description, IconName, SortOrder)
    VALUES (1, N'ELECTRONICA', N'Electrónica', N'Dispositivos electrónicos, componentes y accesorios', N'Devices', 3);

IF NOT EXISTS (SELECT 1 FROM store.IndustryTemplate WHERE TemplateCode = N'ALIMENTOS' AND CompanyId = 1)
    INSERT INTO store.IndustryTemplate (CompanyId, TemplateCode, TemplateName, Description, IconName, SortOrder)
    VALUES (1, N'ALIMENTOS', N'Alimentos y Bebidas', N'Productos alimenticios, bebidas y productos perecederos', N'Restaurant', 4);
GO

PRINT 'Seeded 4 industry templates';
GO

-- 4b. Atributos de FARMACIA
IF NOT EXISTS (SELECT 1 FROM store.IndustryTemplateAttribute WHERE TemplateCode = N'FARMACIA' AND AttributeKey = N'PrincipioActivo' AND CompanyId = 1)
BEGIN
    INSERT INTO store.IndustryTemplateAttribute (CompanyId, TemplateCode, AttributeKey, AttributeLabel, DataType, IsRequired, DisplayGroup, SortOrder) VALUES
    (1, N'FARMACIA', N'PrincipioActivo',     N'Principio Activo',        N'TEXT',    1, N'Composición',          1),
    (1, N'FARMACIA', N'Concentracion',        N'Concentración',           N'TEXT',    1, N'Composición',          2),
    (1, N'FARMACIA', N'FormaFarmaceutica',    N'Forma Farmacéutica',      N'LIST',    1, N'Presentación',         3),
    (1, N'FARMACIA', N'ViaAdministracion',    N'Vía de Administración',   N'LIST',    0, N'Presentación',         4),
    (1, N'FARMACIA', N'RegistroSanitario',    N'Registro Sanitario',      N'TEXT',    1, N'Regulatorio',          5),
    (1, N'FARMACIA', N'Laboratorio',          N'Laboratorio Fabricante',  N'TEXT',    1, N'Regulatorio',          6),
    (1, N'FARMACIA', N'RequiereReceta',       N'Requiere Receta',         N'BOOLEAN', 1, N'Regulatorio',          7),
    (1, N'FARMACIA', N'FechaVencimiento',     N'Fecha de Vencimiento',    N'DATE',    0, N'Control de Lote',      8),
    (1, N'FARMACIA', N'Lote',                 N'Número de Lote',          N'TEXT',    0, N'Control de Lote',      9),
    (1, N'FARMACIA', N'Contraindicaciones',   N'Contraindicaciones Clave',N'TEXT',    0, N'Información Clínica', 10);
    PRINT 'Seeded FARMACIA template attributes (10)';
END;
GO

-- Opciones LIST para FARMACIA
UPDATE store.IndustryTemplateAttribute
SET ListOptions = N'["Tableta","Cápsula","Jarabe","Solución inyectable","Crema","Gel","Supositorio","Gotas","Aerosol","Parche transdérmico","Polvo para suspensión"]'
WHERE TemplateCode = N'FARMACIA' AND AttributeKey = N'FormaFarmaceutica' AND CompanyId = 1 AND ListOptions IS NULL;

UPDATE store.IndustryTemplateAttribute
SET ListOptions = N'["Oral","Intravenosa","Intramuscular","Subcutánea","Tópica","Rectal","Oftálmica","Ótica","Nasal","Inhalatoria","Sublingual"]'
WHERE TemplateCode = N'FARMACIA' AND AttributeKey = N'ViaAdministracion' AND CompanyId = 1 AND ListOptions IS NULL;
GO

-- 4c. Atributos de ROPA
IF NOT EXISTS (SELECT 1 FROM store.IndustryTemplateAttribute WHERE TemplateCode = N'ROPA' AND AttributeKey = N'Material' AND CompanyId = 1)
BEGIN
    INSERT INTO store.IndustryTemplateAttribute (CompanyId, TemplateCode, AttributeKey, AttributeLabel, DataType, IsRequired, DisplayGroup, SortOrder) VALUES
    (1, N'ROPA', N'Material',             N'Material / Composición',    N'TEXT',    1, N'Composición',    1),
    (1, N'ROPA', N'Genero',               N'Género',                    N'LIST',    1, N'Clasificación',  2),
    (1, N'ROPA', N'Temporada',            N'Temporada',                 N'LIST',    0, N'Clasificación',  3),
    (1, N'ROPA', N'PaisOrigen',           N'País de Origen',            N'TEXT',    0, N'Origen',         4),
    (1, N'ROPA', N'InstruccionesLavado',  N'Instrucciones de Lavado',   N'TEXT',    0, N'Cuidado',        5),
    (1, N'ROPA', N'TipoPrenda',           N'Tipo de Prenda',            N'TEXT',    0, N'Clasificación',  6),
    (1, N'ROPA', N'Ajuste',               N'Ajuste / Fit',              N'LIST',    0, N'Clasificación',  7);
    PRINT 'Seeded ROPA template attributes (7)';
END;
GO

UPDATE store.IndustryTemplateAttribute
SET ListOptions = N'["Hombre","Mujer","Unisex","Niño","Niña"]'
WHERE TemplateCode = N'ROPA' AND AttributeKey = N'Genero' AND CompanyId = 1 AND ListOptions IS NULL;

UPDATE store.IndustryTemplateAttribute
SET ListOptions = N'["Primavera/Verano","Otoño/Invierno","Todo el año"]'
WHERE TemplateCode = N'ROPA' AND AttributeKey = N'Temporada' AND CompanyId = 1 AND ListOptions IS NULL;

UPDATE store.IndustryTemplateAttribute
SET ListOptions = N'["Regular","Slim","Oversize","Ajustado","Holgado"]'
WHERE TemplateCode = N'ROPA' AND AttributeKey = N'Ajuste' AND CompanyId = 1 AND ListOptions IS NULL;
GO

-- 4d. Atributos de ELECTRONICA
IF NOT EXISTS (SELECT 1 FROM store.IndustryTemplateAttribute WHERE TemplateCode = N'ELECTRONICA' AND AttributeKey = N'Voltaje' AND CompanyId = 1)
BEGIN
    INSERT INTO store.IndustryTemplateAttribute (CompanyId, TemplateCode, AttributeKey, AttributeLabel, DataType, IsRequired, DisplayGroup, SortOrder) VALUES
    (1, N'ELECTRONICA', N'Voltaje',                N'Voltaje',                 N'TEXT',    0, N'Eléctrico',        1),
    (1, N'ELECTRONICA', N'Potencia',               N'Potencia (W)',            N'NUMBER',  0, N'Eléctrico',        2),
    (1, N'ELECTRONICA', N'Conectividad',           N'Conectividad',            N'TEXT',    0, N'Conectividad',     3),
    (1, N'ELECTRONICA', N'SistemaOperativo',       N'Sistema Operativo',       N'TEXT',    0, N'Software',         4),
    (1, N'ELECTRONICA', N'Capacidad',              N'Capacidad de Almacenamiento', N'TEXT', 0, N'Almacenamiento', 5),
    (1, N'ELECTRONICA', N'Resolucion',             N'Resolución',              N'TEXT',    0, N'Pantalla',         6),
    (1, N'ELECTRONICA', N'CertificacionesTecnicas',N'Certificaciones Técnicas',N'TEXT',    0, N'Regulatorio',      7);
    PRINT 'Seeded ELECTRONICA template attributes (7)';
END;
GO

-- 4e. Atributos de ALIMENTOS
IF NOT EXISTS (SELECT 1 FROM store.IndustryTemplateAttribute WHERE TemplateCode = N'ALIMENTOS' AND AttributeKey = N'Ingredientes' AND CompanyId = 1)
BEGIN
    INSERT INTO store.IndustryTemplateAttribute (CompanyId, TemplateCode, AttributeKey, AttributeLabel, DataType, IsRequired, DisplayGroup, SortOrder) VALUES
    (1, N'ALIMENTOS', N'Ingredientes',             N'Ingredientes',                N'TEXT',    1, N'Composición',          1),
    (1, N'ALIMENTOS', N'InformacionNutricional',   N'Información Nutricional',     N'TEXT',    0, N'Composición',          2),
    (1, N'ALIMENTOS', N'Alergenos',                N'Alérgenos',                   N'TEXT',    0, N'Composición',          3),
    (1, N'ALIMENTOS', N'PesoNeto',                 N'Peso Neto',                   N'TEXT',    1, N'Presentación',         4),
    (1, N'ALIMENTOS', N'FechaVencimiento',         N'Fecha de Vencimiento',        N'DATE',    0, N'Control de Lote',      5),
    (1, N'ALIMENTOS', N'Lote',                     N'Número de Lote',              N'TEXT',    0, N'Control de Lote',      6),
    (1, N'ALIMENTOS', N'RegistroSanitario',        N'Registro Sanitario',          N'TEXT',    1, N'Regulatorio',          7),
    (1, N'ALIMENTOS', N'PaisOrigen',               N'País de Origen',              N'TEXT',    0, N'Origen',               8),
    (1, N'ALIMENTOS', N'Organico',                 N'Orgánico',                    N'BOOLEAN', 0, N'Certificaciones',      9),
    (1, N'ALIMENTOS', N'SinGluten',                N'Sin Gluten',                  N'BOOLEAN', 0, N'Certificaciones',     10),
    (1, N'ALIMENTOS', N'SinLactosa',               N'Sin Lactosa',                 N'BOOLEAN', 0, N'Certificaciones',     11),
    (1, N'ALIMENTOS', N'CondicionesAlmacenamiento',N'Condiciones de Almacenamiento',N'TEXT',   0, N'Almacenamiento',      12);
    PRINT 'Seeded ALIMENTOS template attributes (12)';
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- PARTE 5: SEED — Grupos de variación predefinidos
-- ═══════════════════════════════════════════════════════════════

IF NOT EXISTS (SELECT 1 FROM store.ProductVariantGroup WHERE GroupCode = N'COLOR' AND CompanyId = 1)
BEGIN
    INSERT INTO store.ProductVariantGroup (CompanyId, GroupCode, GroupName, DisplayType, SortOrder) VALUES
    (1, N'COLOR',      N'Color',      N'SWATCH',   1),
    (1, N'TALLA',      N'Talla',      N'BUTTON',   2),
    (1, N'CAPACIDAD',  N'Capacidad',  N'BUTTON',   3),
    (1, N'MATERIAL',   N'Material',   N'DROPDOWN', 4),
    (1, N'ESTILO',     N'Estilo',     N'DROPDOWN', 5);
    PRINT 'Seeded 5 variant groups';
END;
GO

-- Opciones de COLOR
IF NOT EXISTS (SELECT 1 FROM store.ProductVariantOption vo INNER JOIN store.ProductVariantGroup vg ON vg.VariantGroupId = vo.VariantGroupId WHERE vg.GroupCode = N'COLOR' AND vo.OptionCode = N'NEGRO' AND vo.CompanyId = 1)
BEGIN
    DECLARE @ColorGroupId INT = (SELECT VariantGroupId FROM store.ProductVariantGroup WHERE GroupCode = N'COLOR' AND CompanyId = 1);
    INSERT INTO store.ProductVariantOption (CompanyId, VariantGroupId, OptionCode, OptionLabel, ColorHex, SortOrder) VALUES
    (1, @ColorGroupId, N'NEGRO',     N'Negro',     N'#000000', 1),
    (1, @ColorGroupId, N'BLANCO',    N'Blanco',    N'#FFFFFF', 2),
    (1, @ColorGroupId, N'ROJO',      N'Rojo',      N'#E53935', 3),
    (1, @ColorGroupId, N'AZUL',      N'Azul',      N'#1E88E5', 4),
    (1, @ColorGroupId, N'VERDE',     N'Verde',     N'#43A047', 5),
    (1, @ColorGroupId, N'GRIS',      N'Gris',      N'#757575', 6),
    (1, @ColorGroupId, N'ROSA',      N'Rosa',      N'#E91E63', 7),
    (1, @ColorGroupId, N'MORADO',    N'Morado',    N'#7B1FA2', 8),
    (1, @ColorGroupId, N'NARANJA',   N'Naranja',   N'#FF6F00', 9),
    (1, @ColorGroupId, N'AMARILLO',  N'Amarillo',  N'#FDD835', 10);
    PRINT 'Seeded 10 COLOR options';
END;
GO

-- Opciones de TALLA
IF NOT EXISTS (SELECT 1 FROM store.ProductVariantOption vo INNER JOIN store.ProductVariantGroup vg ON vg.VariantGroupId = vo.VariantGroupId WHERE vg.GroupCode = N'TALLA' AND vo.OptionCode = N'XS' AND vo.CompanyId = 1)
BEGIN
    DECLARE @TallaGroupId INT = (SELECT VariantGroupId FROM store.ProductVariantGroup WHERE GroupCode = N'TALLA' AND CompanyId = 1);
    INSERT INTO store.ProductVariantOption (CompanyId, VariantGroupId, OptionCode, OptionLabel, SortOrder) VALUES
    (1, @TallaGroupId, N'XS',   N'XS',   1),
    (1, @TallaGroupId, N'S',    N'S',    2),
    (1, @TallaGroupId, N'M',    N'M',    3),
    (1, @TallaGroupId, N'L',    N'L',    4),
    (1, @TallaGroupId, N'XL',   N'XL',   5),
    (1, @TallaGroupId, N'XXL',  N'XXL',  6),
    (1, @TallaGroupId, N'XXXL', N'XXXL', 7);
    PRINT 'Seeded 7 TALLA options';
END;
GO

-- Opciones de CAPACIDAD
IF NOT EXISTS (SELECT 1 FROM store.ProductVariantOption vo INNER JOIN store.ProductVariantGroup vg ON vg.VariantGroupId = vo.VariantGroupId WHERE vg.GroupCode = N'CAPACIDAD' AND vo.OptionCode = N'32GB' AND vo.CompanyId = 1)
BEGIN
    DECLARE @CapGroupId INT = (SELECT VariantGroupId FROM store.ProductVariantGroup WHERE GroupCode = N'CAPACIDAD' AND CompanyId = 1);
    INSERT INTO store.ProductVariantOption (CompanyId, VariantGroupId, OptionCode, OptionLabel, SortOrder) VALUES
    (1, @CapGroupId, N'32GB',   N'32 GB',   1),
    (1, @CapGroupId, N'64GB',   N'64 GB',   2),
    (1, @CapGroupId, N'128GB',  N'128 GB',  3),
    (1, @CapGroupId, N'256GB',  N'256 GB',  4),
    (1, @CapGroupId, N'512GB',  N'512 GB',  5),
    (1, @CapGroupId, N'1TB',    N'1 TB',    6);
    PRINT 'Seeded 6 CAPACIDAD options';
END;
GO

-- ═══════════════════════════════════════════════════════════════
-- PARTE 6: Stored Procedures — Lectura de variantes y atributos
-- ═══════════════════════════════════════════════════════════════

-- 6a. Listar grupos de variación
IF OBJECT_ID('dbo.usp_Store_VariantGroup_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_VariantGroup_List;
GO
CREATE PROCEDURE dbo.usp_Store_VariantGroup_List
    @CompanyId INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        vg.VariantGroupId  AS id,
        vg.GroupCode        AS code,
        vg.GroupName        AS name,
        vg.DisplayType      AS displayType,
        vg.SortOrder        AS sortOrder
    FROM store.ProductVariantGroup vg
    WHERE vg.CompanyId = @CompanyId
      AND vg.IsDeleted = 0
      AND vg.IsActive  = 1
    ORDER BY vg.SortOrder, vg.GroupName;
END;
GO

-- 6b. Obtener opciones de un grupo de variación
IF OBJECT_ID('dbo.usp_Store_VariantGroup_GetOptions', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_VariantGroup_GetOptions;
GO
CREATE PROCEDURE dbo.usp_Store_VariantGroup_GetOptions
    @CompanyId      INT = 1,
    @GroupCode      NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        vo.VariantOptionId AS id,
        vo.OptionCode      AS code,
        vo.OptionLabel     AS label,
        vo.ColorHex        AS colorHex,
        vo.ImageUrl        AS imageUrl,
        vo.SortOrder       AS sortOrder
    FROM store.ProductVariantOption vo
    INNER JOIN store.ProductVariantGroup vg ON vg.VariantGroupId = vo.VariantGroupId
    WHERE vo.CompanyId = @CompanyId
      AND vg.GroupCode = @GroupCode
      AND vo.IsDeleted = 0
      AND vo.IsActive  = 1
      AND vg.IsDeleted = 0
      AND vg.IsActive  = 1
    ORDER BY vo.SortOrder, vo.OptionLabel;
END;
GO

-- 6c. Obtener variantes de un producto padre
IF OBJECT_ID('dbo.usp_Store_Product_GetVariants', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Product_GetVariants;
GO
CREATE PROCEDURE dbo.usp_Store_Product_GetVariants
    @CompanyId          INT = 1,
    @ParentProductCode  NVARCHAR(80)
AS
BEGIN
    SET NOCOUNT ON;

    -- Recordset 1: Variantes con nombre y precio
    SELECT
        pv.ProductVariantId   AS variantId,
        pv.VariantProductCode AS code,
        p.ProductName         AS name,
        ISNULL(pv.SKU, pv.VariantProductCode) AS sku,
        p.SalesPrice          AS price,
        pv.PriceDelta         AS priceDelta,
        ISNULL(pv.StockOverride, p.StockQty) AS stock,
        pv.IsDefault          AS isDefault,
        pv.SortOrder          AS sortOrder
    FROM store.ProductVariant pv
    INNER JOIN [master].Product p ON p.ProductCode = pv.VariantProductCode AND p.CompanyId = pv.CompanyId
    WHERE pv.CompanyId          = @CompanyId
      AND pv.ParentProductCode  = @ParentProductCode
      AND pv.IsDeleted = 0
      AND pv.IsActive  = 1
      AND p.IsDeleted  = 0
      AND p.IsActive   = 1
    ORDER BY pv.SortOrder, pv.ProductVariantId;

    -- Recordset 2: Opciones elegidas por cada variante
    SELECT
        pv.VariantProductCode AS code,
        vg.GroupCode          AS groupCode,
        vg.GroupName          AS groupName,
        vg.DisplayType        AS displayType,
        vo.OptionCode         AS optionCode,
        vo.OptionLabel        AS optionLabel,
        vo.ColorHex           AS colorHex,
        vo.ImageUrl           AS imageUrl
    FROM store.ProductVariantOptionValue pvov
    INNER JOIN store.ProductVariant pv ON pv.ProductVariantId = pvov.ProductVariantId
    INNER JOIN store.ProductVariantOption vo ON vo.VariantOptionId = pvov.VariantOptionId
    INNER JOIN store.ProductVariantGroup vg ON vg.VariantGroupId = vo.VariantGroupId
    WHERE pv.CompanyId          = @CompanyId
      AND pv.ParentProductCode  = @ParentProductCode
      AND pv.IsDeleted = 0
      AND pv.IsActive  = 1
    ORDER BY vg.SortOrder, vo.SortOrder;
END;
GO

-- 6d. Listar plantillas de industria
IF OBJECT_ID('dbo.usp_Store_IndustryTemplate_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_IndustryTemplate_List;
GO
CREATE PROCEDURE dbo.usp_Store_IndustryTemplate_List
    @CompanyId INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- Recordset 1: Plantillas
    SELECT
        it.IndustryTemplateId AS id,
        it.TemplateCode       AS code,
        it.TemplateName       AS name,
        it.Description        AS description,
        it.IconName           AS iconName,
        it.SortOrder          AS sortOrder
    FROM store.IndustryTemplate it
    WHERE it.CompanyId = @CompanyId
      AND it.IsDeleted = 0
      AND it.IsActive  = 1
    ORDER BY it.SortOrder, it.TemplateName;

    -- Recordset 2: Todos los atributos (agrupados por template)
    SELECT
        ita.TemplateCode       AS templateCode,
        ita.AttributeKey       AS [key],
        ita.AttributeLabel     AS label,
        ita.DataType           AS dataType,
        ita.IsRequired         AS isRequired,
        ita.DefaultValue       AS defaultValue,
        ita.ListOptions        AS listOptions,
        ita.DisplayGroup       AS displayGroup,
        ita.SortOrder          AS sortOrder
    FROM store.IndustryTemplateAttribute ita
    WHERE ita.CompanyId = @CompanyId
      AND ita.IsDeleted = 0
      AND ita.IsActive  = 1
    ORDER BY ita.TemplateCode, ita.SortOrder;
END;
GO

-- 6e. Obtener atributos de un producto
IF OBJECT_ID('dbo.usp_Store_Product_GetAttributes', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Store_Product_GetAttributes;
GO
CREATE PROCEDURE dbo.usp_Store_Product_GetAttributes
    @CompanyId    INT = 1,
    @ProductCode  NVARCHAR(80)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        pa.AttributeKey       AS [key],
        ita.AttributeLabel    AS label,
        ita.DataType          AS dataType,
        ita.DisplayGroup      AS displayGroup,
        pa.ValueText          AS valueText,
        pa.ValueNumber        AS valueNumber,
        pa.ValueDate          AS valueDate,
        pa.ValueBoolean       AS valueBoolean,
        ita.SortOrder         AS sortOrder
    FROM store.ProductAttribute pa
    INNER JOIN store.IndustryTemplateAttribute ita
        ON ita.TemplateCode  = pa.TemplateCode
       AND ita.AttributeKey  = pa.AttributeKey
       AND ita.CompanyId     = pa.CompanyId
       AND ita.IsDeleted     = 0
       AND ita.IsActive      = 1
    WHERE pa.CompanyId   = @CompanyId
      AND pa.ProductCode = @ProductCode
      AND pa.IsDeleted   = 0
      AND pa.IsActive    = 1
    ORDER BY ita.DisplayGroup, ita.SortOrder;
END;
GO

PRINT 'Created all variant and industry attribute stored procedures';
GO
