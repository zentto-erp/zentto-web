-- =============================================================================
-- sp_cfg_state_lookup.sql  (PostgreSQL / PL/pgSQL)
-- Fecha: 2026-03-23
--
-- Tablas:
--   cfg."State"       - Estados/provincias por país
--   cfg."LookupType"  - Tipos de lookup
--   cfg."Lookup"      - Valores de lookup
--
-- Funciones:
--   1. usp_CFG_State_ListByCountry  - Estados activos de un país
--   2. usp_CFG_State_List           - Todos los estados activos
--   3. usp_CFG_Lookup_ListByType    - Lookups activos por tipo
--
-- Seed data:
--   - Estados: VE(24), ES(17), CO(33), MX(32), US(51)
--   - Lookups: PAYROLL_FREQUENCY, PAYROLL_TYPE, DOCUMENT_TYPE,
--              RETENTION_TYPE, SUPPLIER_TYPE, TEMPLATE_TYPE
-- =============================================================================

-- =============================================================================
-- 1. DDL — Tablas
-- =============================================================================

CREATE TABLE IF NOT EXISTS cfg."State" (
    "StateId"     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CountryCode" CHAR(2)      NOT NULL REFERENCES cfg."Country"("CountryCode"),
    "StateCode"   VARCHAR(10)  NOT NULL,
    "StateName"   VARCHAR(100) NOT NULL,
    "SortOrder"   INT          NOT NULL DEFAULT 0,
    "IsActive"    BOOLEAN      NOT NULL DEFAULT TRUE,
    UNIQUE("CountryCode", "StateCode")
);

CREATE TABLE IF NOT EXISTS cfg."LookupType" (
    "LookupTypeId" INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "TypeCode"     VARCHAR(50)  NOT NULL UNIQUE,
    "TypeName"     VARCHAR(100) NOT NULL,
    "Description"  VARCHAR(250)
);

CREATE TABLE IF NOT EXISTS cfg."Lookup" (
    "LookupId"     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "LookupTypeId" INT          NOT NULL REFERENCES cfg."LookupType"("LookupTypeId"),
    "Code"         VARCHAR(50)  NOT NULL,
    "Label"        VARCHAR(150) NOT NULL,
    "LabelEn"      VARCHAR(150),
    "SortOrder"    INT          NOT NULL DEFAULT 0,
    "IsActive"     BOOLEAN      NOT NULL DEFAULT TRUE,
    "Extra"        VARCHAR(500),
    UNIQUE("LookupTypeId", "Code")
);

-- =============================================================================
-- 2. Funciones
-- =============================================================================

-- Drop previos para permitir cambios de firma
DROP FUNCTION IF EXISTS public.usp_CFG_State_ListByCountry(CHAR);
DROP FUNCTION IF EXISTS public.usp_CFG_State_List();
DROP FUNCTION IF EXISTS public.usp_CFG_Lookup_ListByType(VARCHAR);

-- -----------------------------------------------------------------------------
-- usp_CFG_State_ListByCountry
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.usp_CFG_State_ListByCountry(
    p_country_code CHAR(2)
)
RETURNS TABLE (
    "StateId"     INT,
    "CountryCode" CHAR(2),
    "StateCode"   VARCHAR(10),
    "StateName"   VARCHAR(100),
    "SortOrder"   INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."StateId",
        s."CountryCode",
        s."StateCode",
        s."StateName",
        s."SortOrder"
    FROM cfg."State" s
    WHERE s."CountryCode" = p_country_code
      AND s."IsActive" = TRUE
    ORDER BY s."SortOrder", s."StateName";
END;
$$;

-- -----------------------------------------------------------------------------
-- usp_CFG_State_List
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.usp_CFG_State_List()
RETURNS TABLE (
    "StateId"     INT,
    "CountryCode" CHAR(2),
    "StateCode"   VARCHAR(10),
    "StateName"   VARCHAR(100),
    "SortOrder"   INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s."StateId",
        s."CountryCode",
        s."StateCode",
        s."StateName",
        s."SortOrder"
    FROM cfg."State" s
    WHERE s."IsActive" = TRUE
    ORDER BY s."CountryCode", s."SortOrder", s."StateName";
END;
$$;

-- -----------------------------------------------------------------------------
-- usp_CFG_Lookup_ListByType
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.usp_CFG_Lookup_ListByType(
    p_type_code VARCHAR(50)
)
RETURNS TABLE (
    "LookupId"  INT,
    "Code"      VARCHAR(50),
    "Label"     VARCHAR(150),
    "LabelEn"   VARCHAR(150),
    "SortOrder" INT,
    "Extra"     VARCHAR(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        l."LookupId",
        l."Code",
        l."Label",
        l."LabelEn",
        l."SortOrder",
        l."Extra"
    FROM cfg."Lookup" l
    INNER JOIN cfg."LookupType" lt ON lt."LookupTypeId" = l."LookupTypeId"
    WHERE lt."TypeCode" = p_type_code
      AND l."IsActive" = TRUE
    ORDER BY l."SortOrder", l."Label";
END;
$$;

-- =============================================================================
-- 3. SEED DATA — Estados
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- Venezuela (24 estados)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder") VALUES
('VE','VE-AM','Amazonas',1),
('VE','VE-AN','Anzoátegui',2),
('VE','VE-AP','Apure',3),
('VE','VE-AR','Aragua',4),
('VE','VE-BA','Barinas',5),
('VE','VE-BO','Bolívar',6),
('VE','VE-CA','Carabobo',7),
('VE','VE-CO','Cojedes',8),
('VE','VE-DA','Delta Amacuro',9),
('VE','VE-DC','Distrito Capital',10),
('VE','VE-FA','Falcón',11),
('VE','VE-GU','Guárico',12),
('VE','VE-LA','Lara',13),
('VE','VE-ME','Mérida',14),
('VE','VE-MI','Miranda',15),
('VE','VE-MO','Monagas',16),
('VE','VE-NE','Nueva Esparta',17),
('VE','VE-PO','Portuguesa',18),
('VE','VE-SU','Sucre',19),
('VE','VE-TA','Táchira',20),
('VE','VE-TR','Trujillo',21),
('VE','VE-VA','Vargas',22),
('VE','VE-YA','Yaracuy',23),
('VE','VE-ZU','Zulia',24)
ON CONFLICT ("CountryCode","StateCode") DO UPDATE
SET "StateName" = EXCLUDED."StateName",
    "SortOrder" = EXCLUDED."SortOrder",
    "IsActive"  = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- España (17 CCAA)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder") VALUES
('ES','ES-AN','Andalucía',1),
('ES','ES-AR','Aragón',2),
('ES','ES-AS','Asturias',3),
('ES','ES-IB','Baleares',4),
('ES','ES-CN','Canarias',5),
('ES','ES-CB','Cantabria',6),
('ES','ES-CL','Castilla y León',7),
('ES','ES-CM','Castilla-La Mancha',8),
('ES','ES-CT','Cataluña',9),
('ES','ES-VC','C. Valenciana',10),
('ES','ES-EX','Extremadura',11),
('ES','ES-GA','Galicia',12),
('ES','ES-RI','La Rioja',13),
('ES','ES-MD','Madrid',14),
('ES','ES-MU','Murcia',15),
('ES','ES-NA','Navarra',16),
('ES','ES-PV','País Vasco',17)
ON CONFLICT ("CountryCode","StateCode") DO UPDATE
SET "StateName" = EXCLUDED."StateName",
    "SortOrder" = EXCLUDED."SortOrder",
    "IsActive"  = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- Colombia (33 departamentos)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder") VALUES
('CO','CO-AMA','Amazonas',1),
('CO','CO-ANT','Antioquia',2),
('CO','CO-ARA','Arauca',3),
('CO','CO-ATL','Atlántico',4),
('CO','CO-DC','Bogotá D.C.',5),
('CO','CO-BOL','Bolívar',6),
('CO','CO-BOY','Boyacá',7),
('CO','CO-CAL','Caldas',8),
('CO','CO-CAQ','Caquetá',9),
('CO','CO-CAS','Casanare',10),
('CO','CO-CAU','Cauca',11),
('CO','CO-CES','Cesar',12),
('CO','CO-CHO','Chocó',13),
('CO','CO-COR','Córdoba',14),
('CO','CO-CUN','Cundinamarca',15),
('CO','CO-GUA','Guainía',16),
('CO','CO-GUV','Guaviare',17),
('CO','CO-HUI','Huila',18),
('CO','CO-LAG','La Guajira',19),
('CO','CO-MAG','Magdalena',20),
('CO','CO-MET','Meta',21),
('CO','CO-NAR','Nariño',22),
('CO','CO-NSA','Norte de Santander',23),
('CO','CO-PUT','Putumayo',24),
('CO','CO-QUI','Quindío',25),
('CO','CO-RIS','Risaralda',26),
('CO','CO-SAP','San Andrés',27),
('CO','CO-SAN','Santander',28),
('CO','CO-SUC','Sucre',29),
('CO','CO-TOL','Tolima',30),
('CO','CO-VAC','Valle del Cauca',31),
('CO','CO-VAU','Vaupés',32),
('CO','CO-VID','Vichada',33)
ON CONFLICT ("CountryCode","StateCode") DO UPDATE
SET "StateName" = EXCLUDED."StateName",
    "SortOrder" = EXCLUDED."SortOrder",
    "IsActive"  = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- México (32 entidades federativas)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder") VALUES
('MX','MX-AGU','Aguascalientes',1),
('MX','MX-BCN','Baja California',2),
('MX','MX-BCS','Baja California Sur',3),
('MX','MX-CAM','Campeche',4),
('MX','MX-CHP','Chiapas',5),
('MX','MX-CHH','Chihuahua',6),
('MX','MX-CMX','CDMX',7),
('MX','MX-COA','Coahuila',8),
('MX','MX-COL','Colima',9),
('MX','MX-DUR','Durango',10),
('MX','MX-MEX','Estado de México',11),
('MX','MX-GUA','Guanajuato',12),
('MX','MX-GRO','Guerrero',13),
('MX','MX-HID','Hidalgo',14),
('MX','MX-JAL','Jalisco',15),
('MX','MX-MIC','Michoacán',16),
('MX','MX-MOR','Morelos',17),
('MX','MX-NAY','Nayarit',18),
('MX','MX-NLE','Nuevo León',19),
('MX','MX-OAX','Oaxaca',20),
('MX','MX-PUE','Puebla',21),
('MX','MX-QUE','Querétaro',22),
('MX','MX-ROO','Quintana Roo',23),
('MX','MX-SLP','San Luis Potosí',24),
('MX','MX-SIN','Sinaloa',25),
('MX','MX-SON','Sonora',26),
('MX','MX-TAB','Tabasco',27),
('MX','MX-TAM','Tamaulipas',28),
('MX','MX-TLA','Tlaxcala',29),
('MX','MX-VER','Veracruz',30),
('MX','MX-YUC','Yucatán',31),
('MX','MX-ZAC','Zacatecas',32)
ON CONFLICT ("CountryCode","StateCode") DO UPDATE
SET "StateName" = EXCLUDED."StateName",
    "SortOrder" = EXCLUDED."SortOrder",
    "IsActive"  = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- Estados Unidos (50 estados + DC = 51)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO cfg."State" ("CountryCode","StateCode","StateName","SortOrder") VALUES
('US','US-AL','Alabama',1),
('US','US-AK','Alaska',2),
('US','US-AZ','Arizona',3),
('US','US-AR','Arkansas',4),
('US','US-CA','California',5),
('US','US-CO','Colorado',6),
('US','US-CT','Connecticut',7),
('US','US-DE','Delaware',8),
('US','US-DC','District of Columbia',9),
('US','US-FL','Florida',10),
('US','US-GA','Georgia',11),
('US','US-HI','Hawaii',12),
('US','US-ID','Idaho',13),
('US','US-IL','Illinois',14),
('US','US-IN','Indiana',15),
('US','US-IA','Iowa',16),
('US','US-KS','Kansas',17),
('US','US-KY','Kentucky',18),
('US','US-LA','Louisiana',19),
('US','US-ME','Maine',20),
('US','US-MD','Maryland',21),
('US','US-MA','Massachusetts',22),
('US','US-MI','Michigan',23),
('US','US-MN','Minnesota',24),
('US','US-MS','Mississippi',25),
('US','US-MO','Missouri',26),
('US','US-MT','Montana',27),
('US','US-NE','Nebraska',28),
('US','US-NV','Nevada',29),
('US','US-NH','New Hampshire',30),
('US','US-NJ','New Jersey',31),
('US','US-NM','New Mexico',32),
('US','US-NY','New York',33),
('US','US-NC','North Carolina',34),
('US','US-ND','North Dakota',35),
('US','US-OH','Ohio',36),
('US','US-OK','Oklahoma',37),
('US','US-OR','Oregon',38),
('US','US-PA','Pennsylvania',39),
('US','US-RI','Rhode Island',40),
('US','US-SC','South Carolina',41),
('US','US-SD','South Dakota',42),
('US','US-TN','Tennessee',43),
('US','US-TX','Texas',44),
('US','US-UT','Utah',45),
('US','US-VT','Vermont',46),
('US','US-VA','Virginia',47),
('US','US-WA','Washington',48),
('US','US-WV','West Virginia',49),
('US','US-WI','Wisconsin',50),
('US','US-WY','Wyoming',51)
ON CONFLICT ("CountryCode","StateCode") DO UPDATE
SET "StateName" = EXCLUDED."StateName",
    "SortOrder" = EXCLUDED."SortOrder",
    "IsActive"  = TRUE;

-- =============================================================================
-- 4. SEED DATA — LookupTypes + Lookups
-- =============================================================================

-- Helper: insert type and return id
-- Usamos DO blocks con variables para manejar las FK

DO $$
DECLARE
    v_type_id INT;
BEGIN

    -- ─────────────────────────────────────────────────────────────────────────
    -- PAYROLL_FREQUENCY
    -- ─────────────────────────────────────────────────────────────────────────
    INSERT INTO cfg."LookupType" ("TypeCode","TypeName","Description")
    VALUES ('PAYROLL_FREQUENCY','Frecuencia de Nómina','Periodicidad del pago de nómina')
    ON CONFLICT ("TypeCode") DO UPDATE
    SET "TypeName"    = EXCLUDED."TypeName",
        "Description" = EXCLUDED."Description"
    RETURNING "LookupTypeId" INTO v_type_id;

    INSERT INTO cfg."Lookup" ("LookupTypeId","Code","Label","LabelEn","SortOrder")
    VALUES
        (v_type_id, 'SEMANAL',   'Semanal',   'Weekly',     1),
        (v_type_id, 'QUINCENAL', 'Quincenal',  'Biweekly',   2),
        (v_type_id, 'MENSUAL',   'Mensual',   'Monthly',    3),
        (v_type_id, 'ESPECIAL',  'Especial',  'Special',    4)
    ON CONFLICT ("LookupTypeId","Code") DO UPDATE
    SET "Label"     = EXCLUDED."Label",
        "LabelEn"   = EXCLUDED."LabelEn",
        "SortOrder"  = EXCLUDED."SortOrder",
        "IsActive"   = TRUE;

    -- ─────────────────────────────────────────────────────────────────────────
    -- PAYROLL_TYPE
    -- ─────────────────────────────────────────────────────────────────────────
    INSERT INTO cfg."LookupType" ("TypeCode","TypeName","Description")
    VALUES ('PAYROLL_TYPE','Tipo de Nómina','Clasificación del tipo de nómina')
    ON CONFLICT ("TypeCode") DO UPDATE
    SET "TypeName"    = EXCLUDED."TypeName",
        "Description" = EXCLUDED."Description"
    RETURNING "LookupTypeId" INTO v_type_id;

    INSERT INTO cfg."Lookup" ("LookupTypeId","Code","Label","LabelEn","SortOrder")
    VALUES
        (v_type_id, 'NORMAL',      'Normal',       'Regular',     1),
        (v_type_id, 'ESPECIAL',    'Especial',     'Special',     2),
        (v_type_id, 'VACACIONES',  'Vacaciones',   'Vacation',    3),
        (v_type_id, 'UTILIDADES',  'Utilidades',   'Profit Sharing', 4),
        (v_type_id, 'LIQUIDACION', 'Liquidación',  'Settlement',  5)
    ON CONFLICT ("LookupTypeId","Code") DO UPDATE
    SET "Label"     = EXCLUDED."Label",
        "LabelEn"   = EXCLUDED."LabelEn",
        "SortOrder"  = EXCLUDED."SortOrder",
        "IsActive"   = TRUE;

    -- ─────────────────────────────────────────────────────────────────────────
    -- DOCUMENT_TYPE
    -- ─────────────────────────────────────────────────────────────────────────
    INSERT INTO cfg."LookupType" ("TypeCode","TypeName","Description")
    VALUES ('DOCUMENT_TYPE','Tipo de Documento','Tipos de documentos comerciales')
    ON CONFLICT ("TypeCode") DO UPDATE
    SET "TypeName"    = EXCLUDED."TypeName",
        "Description" = EXCLUDED."Description"
    RETURNING "LookupTypeId" INTO v_type_id;

    INSERT INTO cfg."Lookup" ("LookupTypeId","Code","Label","LabelEn","SortOrder")
    VALUES
        (v_type_id, 'FACTURA',       'Factura',        'Invoice',        1),
        (v_type_id, 'NOTA_CREDITO',  'Nota de Crédito','Credit Note',    2),
        (v_type_id, 'NOTA_DEBITO',   'Nota de Débito', 'Debit Note',     3),
        (v_type_id, 'COTIZACION',    'Cotización',     'Quote',          4),
        (v_type_id, 'ORDEN_COMPRA',  'Orden de Compra','Purchase Order', 5)
    ON CONFLICT ("LookupTypeId","Code") DO UPDATE
    SET "Label"     = EXCLUDED."Label",
        "LabelEn"   = EXCLUDED."LabelEn",
        "SortOrder"  = EXCLUDED."SortOrder",
        "IsActive"   = TRUE;

    -- ─────────────────────────────────────────────────────────────────────────
    -- RETENTION_TYPE
    -- ─────────────────────────────────────────────────────────────────────────
    INSERT INTO cfg."LookupType" ("TypeCode","TypeName","Description")
    VALUES ('RETENTION_TYPE','Tipo de Retención','Retenciones fiscales aplicables')
    ON CONFLICT ("TypeCode") DO UPDATE
    SET "TypeName"    = EXCLUDED."TypeName",
        "Description" = EXCLUDED."Description"
    RETURNING "LookupTypeId" INTO v_type_id;

    INSERT INTO cfg."Lookup" ("LookupTypeId","Code","Label","LabelEn","SortOrder","Extra")
    VALUES
        (v_type_id, 'ISLR',       'ISLR',        'Income Tax (VE)',  1, 'VE'),
        (v_type_id, 'IVA',        'IVA',         'VAT Retention',    2, 'VE,CO,MX'),
        (v_type_id, 'IRPF',       'IRPF',        'Income Tax (ES)',  3, 'ES'),
        (v_type_id, 'ISR',        'ISR',         'Income Tax (MX)',  4, 'MX'),
        (v_type_id, 'RETEFUENTE', 'Retefuente',  'Withholding (CO)', 5, 'CO')
    ON CONFLICT ("LookupTypeId","Code") DO UPDATE
    SET "Label"     = EXCLUDED."Label",
        "LabelEn"   = EXCLUDED."LabelEn",
        "SortOrder"  = EXCLUDED."SortOrder",
        "Extra"      = EXCLUDED."Extra",
        "IsActive"   = TRUE;

    -- ─────────────────────────────────────────────────────────────────────────
    -- SUPPLIER_TYPE
    -- ─────────────────────────────────────────────────────────────────────────
    INSERT INTO cfg."LookupType" ("TypeCode","TypeName","Description")
    VALUES ('SUPPLIER_TYPE','Tipo de Proveedor','Clasificación jurídica del proveedor')
    ON CONFLICT ("TypeCode") DO UPDATE
    SET "TypeName"    = EXCLUDED."TypeName",
        "Description" = EXCLUDED."Description"
    RETURNING "LookupTypeId" INTO v_type_id;

    INSERT INTO cfg."Lookup" ("LookupTypeId","Code","Label","LabelEn","SortOrder")
    VALUES
        (v_type_id, 'NATURAL',  'Persona Natural',  'Individual',   1),
        (v_type_id, 'JURIDICA', 'Persona Jurídica', 'Corporation',  2)
    ON CONFLICT ("LookupTypeId","Code") DO UPDATE
    SET "Label"     = EXCLUDED."Label",
        "LabelEn"   = EXCLUDED."LabelEn",
        "SortOrder"  = EXCLUDED."SortOrder",
        "IsActive"   = TRUE;

    -- ─────────────────────────────────────────────────────────────────────────
    -- TEMPLATE_TYPE
    -- ─────────────────────────────────────────────────────────────────────────
    INSERT INTO cfg."LookupType" ("TypeCode","TypeName","Description")
    VALUES ('TEMPLATE_TYPE','Tipo de Plantilla','Tipos de plantillas de documentos')
    ON CONFLICT ("TypeCode") DO UPDATE
    SET "TypeName"    = EXCLUDED."TypeName",
        "Description" = EXCLUDED."Description"
    RETURNING "LookupTypeId" INTO v_type_id;

    INSERT INTO cfg."Lookup" ("LookupTypeId","Code","Label","LabelEn","SortOrder")
    VALUES
        (v_type_id, 'RECIBO',      'Recibo de Pago',    'Pay Stub',          1),
        (v_type_id, 'CONSTANCIA',  'Constancia de Trabajo','Employment Letter', 2),
        (v_type_id, 'ARC',         'ARC',               'Tax Withholding Cert', 3),
        (v_type_id, 'LIQUIDACION', 'Liquidación',       'Settlement',        4),
        (v_type_id, 'VACACIONES',  'Vacaciones',        'Vacation Letter',   5),
        (v_type_id, 'CARTA',       'Carta',             'Letter',            6)
    ON CONFLICT ("LookupTypeId","Code") DO UPDATE
    SET "Label"     = EXCLUDED."Label",
        "LabelEn"   = EXCLUDED."LabelEn",
        "SortOrder"  = EXCLUDED."SortOrder",
        "IsActive"   = TRUE;

END;
$$;
