USE DatqBoxWeb;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- cfg.State + cfg.LookupType + cfg.Lookup
-- Tablas, SPs y seed data
-- ============================================================

-- ============================================================
-- 1. TABLAS
-- ============================================================

-- ------------------------------------------------------------
-- cfg.State
-- ------------------------------------------------------------
IF OBJECT_ID('cfg.State', 'U') IS NULL
BEGIN
    CREATE TABLE cfg.State (
        StateId     INT IDENTITY(1,1) PRIMARY KEY,
        CountryCode CHAR(2)       NOT NULL REFERENCES cfg.Country(CountryCode),
        StateCode   NVARCHAR(10)  NOT NULL,
        StateName   NVARCHAR(100) NOT NULL,
        SortOrder   INT           NOT NULL DEFAULT 0,
        IsActive    BIT           NOT NULL DEFAULT 1,
        CONSTRAINT UQ_State_Country_Code UNIQUE (CountryCode, StateCode)
    );
END;
GO

-- ------------------------------------------------------------
-- cfg.LookupType
-- ------------------------------------------------------------
IF OBJECT_ID('cfg.LookupType', 'U') IS NULL
BEGIN
    CREATE TABLE cfg.LookupType (
        LookupTypeId INT IDENTITY(1,1) PRIMARY KEY,
        TypeCode     NVARCHAR(50)  NOT NULL UNIQUE,
        TypeName     NVARCHAR(100) NOT NULL,
        Description  NVARCHAR(250) NULL
    );
END;
GO

-- ------------------------------------------------------------
-- cfg.Lookup
-- ------------------------------------------------------------
IF OBJECT_ID('cfg.Lookup', 'U') IS NULL
BEGIN
    CREATE TABLE cfg.Lookup (
        LookupId     INT IDENTITY(1,1) PRIMARY KEY,
        LookupTypeId INT           NOT NULL REFERENCES cfg.LookupType(LookupTypeId),
        Code         NVARCHAR(50)  NOT NULL,
        Label        NVARCHAR(150) NOT NULL,
        LabelEn      NVARCHAR(150) NULL,
        SortOrder    INT           NOT NULL DEFAULT 0,
        IsActive     BIT           NOT NULL DEFAULT 1,
        Extra        NVARCHAR(500) NULL,
        CONSTRAINT UQ_Lookup_Type_Code UNIQUE (LookupTypeId, Code)
    );
END;
GO

-- ============================================================
-- 2. STORED PROCEDURES
-- ============================================================

-- ------------------------------------------------------------
-- usp_CFG_State_ListByCountry
-- Retorna estados activos de un país
-- ------------------------------------------------------------
IF OBJECT_ID('dbo.usp_CFG_State_ListByCountry', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CFG_State_ListByCountry;
GO

CREATE PROCEDURE dbo.usp_CFG_State_ListByCountry
    @CountryCode CHAR(2)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        StateId,
        CountryCode,
        StateCode,
        StateName,
        SortOrder,
        IsActive
    FROM cfg.State
    WHERE CountryCode = @CountryCode
      AND IsActive = 1
    ORDER BY SortOrder, StateName;
END;
GO

-- ------------------------------------------------------------
-- usp_CFG_State_List
-- Retorna TODOS los estados activos
-- ------------------------------------------------------------
IF OBJECT_ID('dbo.usp_CFG_State_List', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CFG_State_List;
GO

CREATE PROCEDURE dbo.usp_CFG_State_List
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.StateId,
        s.CountryCode,
        s.StateCode,
        s.StateName,
        s.SortOrder,
        s.IsActive,
        c.CountryName
    FROM cfg.State s
    INNER JOIN cfg.Country c ON c.CountryCode = s.CountryCode
    WHERE s.IsActive = 1
    ORDER BY c.SortOrder, c.CountryName, s.SortOrder, s.StateName;
END;
GO

-- ------------------------------------------------------------
-- usp_CFG_Lookup_ListByType
-- Retorna lookups activos de un tipo
-- ------------------------------------------------------------
IF OBJECT_ID('dbo.usp_CFG_Lookup_ListByType', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CFG_Lookup_ListByType;
GO

CREATE PROCEDURE dbo.usp_CFG_Lookup_ListByType
    @TypeCode NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        l.LookupId,
        l.LookupTypeId,
        lt.TypeCode,
        l.Code,
        l.Label,
        l.LabelEn,
        l.SortOrder,
        l.IsActive,
        l.Extra
    FROM cfg.Lookup l
    INNER JOIN cfg.LookupType lt ON lt.LookupTypeId = l.LookupTypeId
    WHERE lt.TypeCode = @TypeCode
      AND l.IsActive = 1
    ORDER BY l.SortOrder, l.Label;
END;
GO

-- ============================================================
-- 3. SEED DATA — cfg.State (MERGE idempotente)
-- ============================================================

-- ------------------------------------------------------------
-- 3a. Venezuela (VE) — 24 estados
-- ------------------------------------------------------------
MERGE INTO cfg.State AS tgt
USING (VALUES
    ('VE', N'VE-AM', N'Amazonas',        1),
    ('VE', N'VE-AN', N'Anzoátegui',      2),
    ('VE', N'VE-AP', N'Apure',           3),
    ('VE', N'VE-AR', N'Aragua',          4),
    ('VE', N'VE-BA', N'Barinas',         5),
    ('VE', N'VE-BO', N'Bolívar',         6),
    ('VE', N'VE-CA', N'Carabobo',        7),
    ('VE', N'VE-CO', N'Cojedes',         8),
    ('VE', N'VE-DA', N'Delta Amacuro',   9),
    ('VE', N'VE-DC', N'Distrito Capital', 10),
    ('VE', N'VE-FA', N'Falcón',          11),
    ('VE', N'VE-GU', N'Guárico',         12),
    ('VE', N'VE-LA', N'Lara',            13),
    ('VE', N'VE-ME', N'Mérida',          14),
    ('VE', N'VE-MI', N'Miranda',         15),
    ('VE', N'VE-MO', N'Monagas',         16),
    ('VE', N'VE-NE', N'Nueva Esparta',   17),
    ('VE', N'VE-PO', N'Portuguesa',      18),
    ('VE', N'VE-SU', N'Sucre',           19),
    ('VE', N'VE-TA', N'Táchira',         20),
    ('VE', N'VE-TR', N'Trujillo',        21),
    ('VE', N'VE-VA', N'Vargas (La Guaira)', 22),
    ('VE', N'VE-YA', N'Yaracuy',         23),
    ('VE', N'VE-ZU', N'Zulia',           24)
) AS src (CountryCode, StateCode, StateName, SortOrder)
ON tgt.CountryCode = src.CountryCode AND tgt.StateCode = src.StateCode
WHEN MATCHED THEN
    UPDATE SET StateName = src.StateName, SortOrder = src.SortOrder, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (CountryCode, StateCode, StateName, SortOrder, IsActive)
    VALUES (src.CountryCode, src.StateCode, src.StateName, src.SortOrder, 1);
GO

-- ------------------------------------------------------------
-- 3b. España (ES) — 17 comunidades autónomas
-- ------------------------------------------------------------
MERGE INTO cfg.State AS tgt
USING (VALUES
    ('ES', N'ES-AN', N'Andalucía',             1),
    ('ES', N'ES-AR', N'Aragón',                2),
    ('ES', N'ES-AS', N'Asturias',              3),
    ('ES', N'ES-IB', N'Baleares',              4),
    ('ES', N'ES-CN', N'Canarias',              5),
    ('ES', N'ES-CB', N'Cantabria',             6),
    ('ES', N'ES-CL', N'Castilla y León',       7),
    ('ES', N'ES-CM', N'Castilla-La Mancha',    8),
    ('ES', N'ES-CT', N'Cataluña',              9),
    ('ES', N'ES-VC', N'Comunidad Valenciana',  10),
    ('ES', N'ES-EX', N'Extremadura',           11),
    ('ES', N'ES-GA', N'Galicia',               12),
    ('ES', N'ES-RI', N'La Rioja',              13),
    ('ES', N'ES-MD', N'Madrid',                14),
    ('ES', N'ES-MU', N'Murcia',                15),
    ('ES', N'ES-NA', N'Navarra',               16),
    ('ES', N'ES-PV', N'País Vasco',            17)
) AS src (CountryCode, StateCode, StateName, SortOrder)
ON tgt.CountryCode = src.CountryCode AND tgt.StateCode = src.StateCode
WHEN MATCHED THEN
    UPDATE SET StateName = src.StateName, SortOrder = src.SortOrder, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (CountryCode, StateCode, StateName, SortOrder, IsActive)
    VALUES (src.CountryCode, src.StateCode, src.StateName, src.SortOrder, 1);
GO

-- ------------------------------------------------------------
-- 3c. Colombia (CO) — 33 departamentos
-- ------------------------------------------------------------
MERGE INTO cfg.State AS tgt
USING (VALUES
    ('CO', N'CO-AMA', N'Amazonas',              1),
    ('CO', N'CO-ANT', N'Antioquia',             2),
    ('CO', N'CO-ARA', N'Arauca',                3),
    ('CO', N'CO-ATL', N'Atlántico',             4),
    ('CO', N'CO-DC',  N'Bogotá D.C.',           5),
    ('CO', N'CO-BOL', N'Bolívar',               6),
    ('CO', N'CO-BOY', N'Boyacá',                7),
    ('CO', N'CO-CAL', N'Caldas',                8),
    ('CO', N'CO-CAQ', N'Caquetá',               9),
    ('CO', N'CO-CAS', N'Casanare',              10),
    ('CO', N'CO-CAU', N'Cauca',                 11),
    ('CO', N'CO-CES', N'Cesar',                 12),
    ('CO', N'CO-CHO', N'Chocó',                 13),
    ('CO', N'CO-COR', N'Córdoba',               14),
    ('CO', N'CO-CUN', N'Cundinamarca',          15),
    ('CO', N'CO-GUA', N'Guainía',               16),
    ('CO', N'CO-GUV', N'Guaviare',              17),
    ('CO', N'CO-HUI', N'Huila',                 18),
    ('CO', N'CO-LAG', N'La Guajira',            19),
    ('CO', N'CO-MAG', N'Magdalena',             20),
    ('CO', N'CO-MET', N'Meta',                  21),
    ('CO', N'CO-NAR', N'Nariño',                22),
    ('CO', N'CO-NSA', N'Norte de Santander',    23),
    ('CO', N'CO-PUT', N'Putumayo',              24),
    ('CO', N'CO-QUI', N'Quindío',               25),
    ('CO', N'CO-RIS', N'Risaralda',             26),
    ('CO', N'CO-SAP', N'San Andrés',            27),
    ('CO', N'CO-SAN', N'Santander',             28),
    ('CO', N'CO-SUC', N'Sucre',                 29),
    ('CO', N'CO-TOL', N'Tolima',                30),
    ('CO', N'CO-VAC', N'Valle del Cauca',       31),
    ('CO', N'CO-VAU', N'Vaupés',                32),
    ('CO', N'CO-VID', N'Vichada',               33)
) AS src (CountryCode, StateCode, StateName, SortOrder)
ON tgt.CountryCode = src.CountryCode AND tgt.StateCode = src.StateCode
WHEN MATCHED THEN
    UPDATE SET StateName = src.StateName, SortOrder = src.SortOrder, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (CountryCode, StateCode, StateName, SortOrder, IsActive)
    VALUES (src.CountryCode, src.StateCode, src.StateName, src.SortOrder, 1);
GO

-- ------------------------------------------------------------
-- 3d. México (MX) — 32 estados
-- ------------------------------------------------------------
MERGE INTO cfg.State AS tgt
USING (VALUES
    ('MX', N'MX-AGU', N'Aguascalientes',       1),
    ('MX', N'MX-BCN', N'Baja California',      2),
    ('MX', N'MX-BCS', N'Baja California Sur',  3),
    ('MX', N'MX-CAM', N'Campeche',             4),
    ('MX', N'MX-CHP', N'Chiapas',              5),
    ('MX', N'MX-CHH', N'Chihuahua',            6),
    ('MX', N'MX-CMX', N'Ciudad de México',     7),
    ('MX', N'MX-COA', N'Coahuila',             8),
    ('MX', N'MX-COL', N'Colima',               9),
    ('MX', N'MX-DUR', N'Durango',              10),
    ('MX', N'MX-MEX', N'Estado de México',     11),
    ('MX', N'MX-GUA', N'Guanajuato',           12),
    ('MX', N'MX-GRO', N'Guerrero',             13),
    ('MX', N'MX-HID', N'Hidalgo',              14),
    ('MX', N'MX-JAL', N'Jalisco',              15),
    ('MX', N'MX-MIC', N'Michoacán',            16),
    ('MX', N'MX-MOR', N'Morelos',              17),
    ('MX', N'MX-NAY', N'Nayarit',              18),
    ('MX', N'MX-NLE', N'Nuevo León',           19),
    ('MX', N'MX-OAX', N'Oaxaca',              20),
    ('MX', N'MX-PUE', N'Puebla',               21),
    ('MX', N'MX-QUE', N'Querétaro',            22),
    ('MX', N'MX-ROO', N'Quintana Roo',         23),
    ('MX', N'MX-SLP', N'San Luis Potosí',      24),
    ('MX', N'MX-SIN', N'Sinaloa',              25),
    ('MX', N'MX-SON', N'Sonora',               26),
    ('MX', N'MX-TAB', N'Tabasco',              27),
    ('MX', N'MX-TAM', N'Tamaulipas',           28),
    ('MX', N'MX-TLA', N'Tlaxcala',             29),
    ('MX', N'MX-VER', N'Veracruz',             30),
    ('MX', N'MX-YUC', N'Yucatán',              31),
    ('MX', N'MX-ZAC', N'Zacatecas',            32)
) AS src (CountryCode, StateCode, StateName, SortOrder)
ON tgt.CountryCode = src.CountryCode AND tgt.StateCode = src.StateCode
WHEN MATCHED THEN
    UPDATE SET StateName = src.StateName, SortOrder = src.SortOrder, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (CountryCode, StateCode, StateName, SortOrder, IsActive)
    VALUES (src.CountryCode, src.StateCode, src.StateName, src.SortOrder, 1);
GO

-- ------------------------------------------------------------
-- 3e. Estados Unidos (US) — 50 estados + DC
-- ------------------------------------------------------------
MERGE INTO cfg.State AS tgt
USING (VALUES
    ('US', N'US-AL', N'Alabama',                1),
    ('US', N'US-AK', N'Alaska',                 2),
    ('US', N'US-AZ', N'Arizona',                3),
    ('US', N'US-AR', N'Arkansas',               4),
    ('US', N'US-CA', N'California',             5),
    ('US', N'US-CO', N'Colorado',               6),
    ('US', N'US-CT', N'Connecticut',            7),
    ('US', N'US-DE', N'Delaware',               8),
    ('US', N'US-DC', N'District of Columbia',   9),
    ('US', N'US-FL', N'Florida',                10),
    ('US', N'US-GA', N'Georgia',                11),
    ('US', N'US-HI', N'Hawaii',                 12),
    ('US', N'US-ID', N'Idaho',                  13),
    ('US', N'US-IL', N'Illinois',               14),
    ('US', N'US-IN', N'Indiana',                15),
    ('US', N'US-IA', N'Iowa',                   16),
    ('US', N'US-KS', N'Kansas',                 17),
    ('US', N'US-KY', N'Kentucky',               18),
    ('US', N'US-LA', N'Louisiana',              19),
    ('US', N'US-ME', N'Maine',                  20),
    ('US', N'US-MD', N'Maryland',               21),
    ('US', N'US-MA', N'Massachusetts',          22),
    ('US', N'US-MI', N'Michigan',               23),
    ('US', N'US-MN', N'Minnesota',              24),
    ('US', N'US-MS', N'Mississippi',            25),
    ('US', N'US-MO', N'Missouri',               26),
    ('US', N'US-MT', N'Montana',                27),
    ('US', N'US-NE', N'Nebraska',               28),
    ('US', N'US-NV', N'Nevada',                 29),
    ('US', N'US-NH', N'New Hampshire',          30),
    ('US', N'US-NJ', N'New Jersey',             31),
    ('US', N'US-NM', N'New Mexico',             32),
    ('US', N'US-NY', N'New York',               33),
    ('US', N'US-NC', N'North Carolina',         34),
    ('US', N'US-ND', N'North Dakota',           35),
    ('US', N'US-OH', N'Ohio',                   36),
    ('US', N'US-OK', N'Oklahoma',               37),
    ('US', N'US-OR', N'Oregon',                 38),
    ('US', N'US-PA', N'Pennsylvania',           39),
    ('US', N'US-RI', N'Rhode Island',           40),
    ('US', N'US-SC', N'South Carolina',         41),
    ('US', N'US-SD', N'South Dakota',           42),
    ('US', N'US-TN', N'Tennessee',              43),
    ('US', N'US-TX', N'Texas',                  44),
    ('US', N'US-UT', N'Utah',                   45),
    ('US', N'US-VT', N'Vermont',                46),
    ('US', N'US-VA', N'Virginia',               47),
    ('US', N'US-WA', N'Washington',             48),
    ('US', N'US-WV', N'West Virginia',          49),
    ('US', N'US-WI', N'Wisconsin',              50),
    ('US', N'US-WY', N'Wyoming',                51)
) AS src (CountryCode, StateCode, StateName, SortOrder)
ON tgt.CountryCode = src.CountryCode AND tgt.StateCode = src.StateCode
WHEN MATCHED THEN
    UPDATE SET StateName = src.StateName, SortOrder = src.SortOrder, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (CountryCode, StateCode, StateName, SortOrder, IsActive)
    VALUES (src.CountryCode, src.StateCode, src.StateName, src.SortOrder, 1);
GO

-- ============================================================
-- 4. SEED DATA — cfg.LookupType + cfg.Lookup (MERGE idempotente)
-- ============================================================

-- ------------------------------------------------------------
-- 4a. LookupTypes
-- ------------------------------------------------------------
MERGE INTO cfg.LookupType AS tgt
USING (VALUES
    (N'PAYROLL_FREQUENCY', N'Frecuencia de Nómina',   N'Periodicidad de pago de nómina'),
    (N'PAYROLL_TYPE',      N'Tipo de Nómina',         N'Clasificación de nóminas'),
    (N'DOCUMENT_TYPE',     N'Tipo de Documento',      N'Tipos de documentos comerciales'),
    (N'RETENTION_TYPE',    N'Tipo de Retención',      N'Tipos de retenciones fiscales'),
    (N'SUPPLIER_TYPE',     N'Tipo de Proveedor',      N'Clasificación de proveedores'),
    (N'TEMPLATE_TYPE',     N'Tipo de Plantilla',      N'Tipos de plantillas de documentos')
) AS src (TypeCode, TypeName, Description)
ON tgt.TypeCode = src.TypeCode
WHEN MATCHED THEN
    UPDATE SET TypeName = src.TypeName, Description = src.Description
WHEN NOT MATCHED THEN
    INSERT (TypeCode, TypeName, Description)
    VALUES (src.TypeCode, src.TypeName, src.Description);
GO

-- ------------------------------------------------------------
-- 4b. Lookups — PAYROLL_FREQUENCY
-- ------------------------------------------------------------
MERGE INTO cfg.Lookup AS tgt
USING (
    SELECT lt.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder
    FROM (VALUES
        (N'SEMANAL',    N'Semanal',    N'Weekly',      1),
        (N'QUINCENAL',  N'Quincenal',  N'Biweekly',    2),
        (N'MENSUAL',    N'Mensual',    N'Monthly',     3),
        (N'ESPECIAL',   N'Especial',   N'Special',     4)
    ) AS src (Code, Label, LabelEn, SortOrder)
    CROSS JOIN cfg.LookupType lt
    WHERE lt.TypeCode = N'PAYROLL_FREQUENCY'
) AS src
ON tgt.LookupTypeId = src.LookupTypeId AND tgt.Code = src.Code
WHEN MATCHED THEN
    UPDATE SET Label = src.Label, LabelEn = src.LabelEn, SortOrder = src.SortOrder, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (LookupTypeId, Code, Label, LabelEn, SortOrder, IsActive)
    VALUES (src.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder, 1);
GO

-- ------------------------------------------------------------
-- 4c. Lookups — PAYROLL_TYPE
-- ------------------------------------------------------------
MERGE INTO cfg.Lookup AS tgt
USING (
    SELECT lt.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder
    FROM (VALUES
        (N'NORMAL',      N'Normal',       N'Regular',     1),
        (N'ESPECIAL',    N'Especial',     N'Special',     2),
        (N'VACACIONES',  N'Vacaciones',   N'Vacation',    3),
        (N'UTILIDADES',  N'Utilidades',   N'Profit Sharing', 4),
        (N'LIQUIDACION', N'Liquidación',  N'Settlement',  5)
    ) AS src (Code, Label, LabelEn, SortOrder)
    CROSS JOIN cfg.LookupType lt
    WHERE lt.TypeCode = N'PAYROLL_TYPE'
) AS src
ON tgt.LookupTypeId = src.LookupTypeId AND tgt.Code = src.Code
WHEN MATCHED THEN
    UPDATE SET Label = src.Label, LabelEn = src.LabelEn, SortOrder = src.SortOrder, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (LookupTypeId, Code, Label, LabelEn, SortOrder, IsActive)
    VALUES (src.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder, 1);
GO

-- ------------------------------------------------------------
-- 4d. Lookups — DOCUMENT_TYPE
-- ------------------------------------------------------------
MERGE INTO cfg.Lookup AS tgt
USING (
    SELECT lt.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder
    FROM (VALUES
        (N'FACTURA',       N'Factura',           N'Invoice',          1),
        (N'NOTA_CREDITO',  N'Nota de Crédito',   N'Credit Note',      2),
        (N'NOTA_DEBITO',   N'Nota de Débito',    N'Debit Note',       3),
        (N'COTIZACION',    N'Cotización',         N'Quote',            4),
        (N'ORDEN_COMPRA',  N'Orden de Compra',    N'Purchase Order',   5)
    ) AS src (Code, Label, LabelEn, SortOrder)
    CROSS JOIN cfg.LookupType lt
    WHERE lt.TypeCode = N'DOCUMENT_TYPE'
) AS src
ON tgt.LookupTypeId = src.LookupTypeId AND tgt.Code = src.Code
WHEN MATCHED THEN
    UPDATE SET Label = src.Label, LabelEn = src.LabelEn, SortOrder = src.SortOrder, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (LookupTypeId, Code, Label, LabelEn, SortOrder, IsActive)
    VALUES (src.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder, 1);
GO

-- ------------------------------------------------------------
-- 4e. Lookups — RETENTION_TYPE
-- ------------------------------------------------------------
MERGE INTO cfg.Lookup AS tgt
USING (
    SELECT lt.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder
    FROM (VALUES
        (N'ISLR',        N'ISLR',                      N'Income Tax Withholding',       1),
        (N'IVA',         N'IVA',                        N'VAT Withholding',              2),
        (N'IRPF',        N'IRPF',                       N'Personal Income Tax',          3),
        (N'ISR',         N'ISR',                         N'Income Tax',                   4),
        (N'RETEFUENTE',  N'Retención en la Fuente',     N'Withholding at Source',        5)
    ) AS src (Code, Label, LabelEn, SortOrder)
    CROSS JOIN cfg.LookupType lt
    WHERE lt.TypeCode = N'RETENTION_TYPE'
) AS src
ON tgt.LookupTypeId = src.LookupTypeId AND tgt.Code = src.Code
WHEN MATCHED THEN
    UPDATE SET Label = src.Label, LabelEn = src.LabelEn, SortOrder = src.SortOrder, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (LookupTypeId, Code, Label, LabelEn, SortOrder, IsActive)
    VALUES (src.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder, 1);
GO

-- ------------------------------------------------------------
-- 4f. Lookups — SUPPLIER_TYPE
-- ------------------------------------------------------------
MERGE INTO cfg.Lookup AS tgt
USING (
    SELECT lt.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder
    FROM (VALUES
        (N'NATURAL',   N'Persona Natural',    N'Individual',     1),
        (N'JURIDICA',  N'Persona Jurídica',   N'Corporation',    2)
    ) AS src (Code, Label, LabelEn, SortOrder)
    CROSS JOIN cfg.LookupType lt
    WHERE lt.TypeCode = N'SUPPLIER_TYPE'
) AS src
ON tgt.LookupTypeId = src.LookupTypeId AND tgt.Code = src.Code
WHEN MATCHED THEN
    UPDATE SET Label = src.Label, LabelEn = src.LabelEn, SortOrder = src.SortOrder, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (LookupTypeId, Code, Label, LabelEn, SortOrder, IsActive)
    VALUES (src.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder, 1);
GO

-- ------------------------------------------------------------
-- 4g. Lookups — TEMPLATE_TYPE
-- ------------------------------------------------------------
MERGE INTO cfg.Lookup AS tgt
USING (
    SELECT lt.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder
    FROM (VALUES
        (N'RECIBO',       N'Recibo de Pago',        N'Pay Stub',            1),
        (N'CONSTANCIA',   N'Constancia de Trabajo',  N'Employment Letter',   2),
        (N'ARC',          N'Comprobante ARC',        N'ARC Certificate',     3),
        (N'LIQUIDACION',  N'Liquidación',            N'Settlement',          4),
        (N'VACACIONES',   N'Vacaciones',             N'Vacation',            5),
        (N'CARTA',        N'Carta genérica',         N'Generic Letter',      6)
    ) AS src (Code, Label, LabelEn, SortOrder)
    CROSS JOIN cfg.LookupType lt
    WHERE lt.TypeCode = N'TEMPLATE_TYPE'
) AS src
ON tgt.LookupTypeId = src.LookupTypeId AND tgt.Code = src.Code
WHEN MATCHED THEN
    UPDATE SET Label = src.Label, LabelEn = src.LabelEn, SortOrder = src.SortOrder, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (LookupTypeId, Code, Label, LabelEn, SortOrder, IsActive)
    VALUES (src.LookupTypeId, src.Code, src.Label, src.LabelEn, src.SortOrder, 1);
GO

PRINT N'cfg.State + cfg.LookupType + cfg.Lookup — tablas, SPs y seed data creados correctamente.';
GO
