-- ============================================================
-- DatqBoxWeb PostgreSQL - usp_ecommerce_variants.sql
-- E-commerce product variants functions
-- ============================================================

/*  â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    usp_ecommerce_variants.sql â€” Variantes de Producto + Atributos por Industria
    Tablas nuevas: store."ProductVariantGroup", store."ProductVariantOption",
                   store."ProductVariant", store."ProductVariantOptionValue",
                   store."IndustryTemplate", store."IndustryTemplateAttribute",
                   store."ProductAttribute"
    Columnas nuevas en master."Product": "IsVariantParent", "ParentProductCode",
                                         "IndustryTemplateCode"
    â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Crear schema store si no existe
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
CREATE SCHEMA IF NOT EXISTS store;

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- PARTE 1: DDL â€” Columnas nuevas en master."Product"
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'Product' AND column_name = 'IsVariantParent'
    ) THEN
        ALTER TABLE master."Product" ADD COLUMN "IsVariantParent" BOOLEAN NOT NULL DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'Product' AND column_name = 'ParentProductCode'
    ) THEN
        ALTER TABLE master."Product" ADD COLUMN "ParentProductCode" VARCHAR(80) NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'master' AND table_name = 'Product' AND column_name = 'IndustryTemplateCode'
    ) THEN
        ALTER TABLE master."Product" ADD COLUMN "IndustryTemplateCode" VARCHAR(30) NULL;
    END IF;
END
$$;

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- PARTE 2: DDL â€” Tablas de variantes
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 2a. Grupos de variaciÃ³n (Color, Talla, Capacidad...)
CREATE TABLE IF NOT EXISTS store."ProductVariantGroup" (
    "VariantGroupId"   SERIAL PRIMARY KEY,
    "CompanyId"        INT            NOT NULL DEFAULT 1,
    "GroupCode"        VARCHAR(30)    NOT NULL,
    "GroupName"        VARCHAR(100)   NOT NULL,
    "DisplayType"      VARCHAR(20)    NOT NULL DEFAULT 'BUTTON',
    "SortOrder"        INT            NOT NULL DEFAULT 0,
    "IsActive"         BOOLEAN        NOT NULL DEFAULT TRUE,
    "IsDeleted"        BOOLEAN        NOT NULL DEFAULT FALSE,
    "CreatedAt"        TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_ProductVariantGroup_Code" UNIQUE ("CompanyId", "GroupCode")
);

CREATE INDEX IF NOT EXISTS "IX_ProductVariantGroup_Company"
    ON store."ProductVariantGroup" ("CompanyId", "IsDeleted", "IsActive");

-- 2b. Opciones dentro de un grupo (Rojo, Azul, S, M, L, 128GB...)
CREATE TABLE IF NOT EXISTS store."ProductVariantOption" (
    "VariantOptionId"  SERIAL PRIMARY KEY,
    "CompanyId"        INT            NOT NULL DEFAULT 1,
    "VariantGroupId"   INT            NOT NULL,
    "OptionCode"       VARCHAR(30)    NOT NULL,
    "OptionLabel"      VARCHAR(100)   NOT NULL,
    "ColorHex"         VARCHAR(7)     NULL,
    "ImageUrl"         VARCHAR(500)   NULL,
    "SortOrder"        INT            NOT NULL DEFAULT 0,
    "IsActive"         BOOLEAN        NOT NULL DEFAULT TRUE,
    "IsDeleted"        BOOLEAN        NOT NULL DEFAULT FALSE,
    "CreatedAt"        TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "FK_VariantOption_Group" FOREIGN KEY ("VariantGroupId") REFERENCES store."ProductVariantGroup"("VariantGroupId"),
    CONSTRAINT "UQ_VariantOption_Code" UNIQUE ("CompanyId", "VariantGroupId", "OptionCode")
);

CREATE INDEX IF NOT EXISTS "IX_ProductVariantOption_Group"
    ON store."ProductVariantOption" ("VariantGroupId", "IsDeleted", "IsActive");

-- 2c. Variantes de producto (vincula producto padre <-> producto hijo)
CREATE TABLE IF NOT EXISTS store."ProductVariant" (
    "ProductVariantId"    SERIAL PRIMARY KEY,
    "CompanyId"           INT            NOT NULL DEFAULT 1,
    "ParentProductCode"   VARCHAR(80)    NOT NULL,
    "VariantProductCode"  VARCHAR(80)    NOT NULL,
    "SKU"                 VARCHAR(80)    NULL,
    "PriceDelta"          NUMERIC(18,2)  NOT NULL DEFAULT 0,
    "StockOverride"       NUMERIC(18,4)  NULL,
    "IsDefault"           BOOLEAN        NOT NULL DEFAULT FALSE,
    "SortOrder"           INT            NOT NULL DEFAULT 0,
    "IsActive"            BOOLEAN        NOT NULL DEFAULT TRUE,
    "IsDeleted"           BOOLEAN        NOT NULL DEFAULT FALSE,
    "CreatedAt"           TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_ProductVariant_Code" UNIQUE ("CompanyId", "ParentProductCode", "VariantProductCode")
);

CREATE INDEX IF NOT EXISTS "IX_ProductVariant_Parent"
    ON store."ProductVariant" ("CompanyId", "ParentProductCode", "IsDeleted", "IsActive");

-- 2d. Valores de opciones por variante (N:M entre variante y opciones elegidas)
CREATE TABLE IF NOT EXISTS store."ProductVariantOptionValue" (
    "VariantOptionValueId" SERIAL PRIMARY KEY,
    "ProductVariantId"     INT NOT NULL,
    "VariantOptionId"      INT NOT NULL,
    CONSTRAINT "FK_PVOV_Variant" FOREIGN KEY ("ProductVariantId") REFERENCES store."ProductVariant"("ProductVariantId"),
    CONSTRAINT "FK_PVOV_Option" FOREIGN KEY ("VariantOptionId") REFERENCES store."ProductVariantOption"("VariantOptionId"),
    CONSTRAINT "UQ_PVOV" UNIQUE ("ProductVariantId", "VariantOptionId")
);

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- PARTE 3: DDL â€” Tablas de atributos por industria
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 3a. Plantillas de industria
CREATE TABLE IF NOT EXISTS store."IndustryTemplate" (
    "IndustryTemplateId"   SERIAL PRIMARY KEY,
    "CompanyId"            INT            NOT NULL DEFAULT 1,
    "TemplateCode"         VARCHAR(30)    NOT NULL,
    "TemplateName"         VARCHAR(100)   NOT NULL,
    "Description"          VARCHAR(500)   NULL,
    "IconName"             VARCHAR(50)    NULL,
    "SortOrder"            INT            NOT NULL DEFAULT 0,
    "IsActive"             BOOLEAN        NOT NULL DEFAULT TRUE,
    "IsDeleted"            BOOLEAN        NOT NULL DEFAULT FALSE,
    "CreatedAt"            TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_IndustryTemplate_Code" UNIQUE ("CompanyId", "TemplateCode")
);

-- 3b. DefiniciÃ³n de atributos por plantilla
CREATE TABLE IF NOT EXISTS store."IndustryTemplateAttribute" (
    "TemplateAttributeId" SERIAL PRIMARY KEY,
    "CompanyId"           INT            NOT NULL DEFAULT 1,
    "TemplateCode"        VARCHAR(30)    NOT NULL,
    "AttributeKey"        VARCHAR(50)    NOT NULL,
    "AttributeLabel"      VARCHAR(100)   NOT NULL,
    "DataType"            VARCHAR(20)    NOT NULL DEFAULT 'TEXT',
    "IsRequired"          BOOLEAN        NOT NULL DEFAULT FALSE,
    "DefaultValue"        VARCHAR(200)   NULL,
    "ListOptions"         TEXT           NULL,
    "DisplayGroup"        VARCHAR(100)   NOT NULL DEFAULT 'General',
    "SortOrder"           INT            NOT NULL DEFAULT 0,
    "IsActive"            BOOLEAN        NOT NULL DEFAULT TRUE,
    "IsDeleted"           BOOLEAN        NOT NULL DEFAULT FALSE,
    "CreatedAt"           TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_TemplateAttribute_Key" UNIQUE ("CompanyId", "TemplateCode", "AttributeKey")
);

CREATE INDEX IF NOT EXISTS "IX_TemplateAttribute_Template"
    ON store."IndustryTemplateAttribute" ("CompanyId", "TemplateCode", "IsDeleted", "IsActive");

-- 3c. Valores de atributos asignados a productos (EAV tipado)
CREATE TABLE IF NOT EXISTS store."ProductAttribute" (
    "ProductAttributeId" SERIAL PRIMARY KEY,
    "CompanyId"          INT            NOT NULL DEFAULT 1,
    "ProductCode"        VARCHAR(80)    NOT NULL,
    "TemplateCode"       VARCHAR(30)    NOT NULL,
    "AttributeKey"       VARCHAR(50)    NOT NULL,
    "ValueText"          VARCHAR(500)   NULL,
    "ValueNumber"        NUMERIC(18,4)  NULL,
    "ValueDate"          DATE           NULL,
    "ValueBoolean"       BOOLEAN        NULL,
    "IsActive"           BOOLEAN        NOT NULL DEFAULT TRUE,
    "IsDeleted"          BOOLEAN        NOT NULL DEFAULT FALSE,
    "CreatedAt"          TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"          TIMESTAMP      NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_ProductAttribute_Key" UNIQUE ("CompanyId", "ProductCode", "AttributeKey")
);

CREATE INDEX IF NOT EXISTS "IX_ProductAttribute_Product"
    ON store."ProductAttribute" ("CompanyId", "ProductCode", "IsDeleted", "IsActive");

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- PARTE 4: SEED â€” Plantillas de industria con atributos
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 4a. Plantillas
INSERT INTO store."IndustryTemplate" ("CompanyId", "TemplateCode", "TemplateName", "Description", "IconName", "SortOrder")
VALUES (1, 'FARMACIA', 'Farmacia', 'Medicamentos, suplementos y productos farmacÃ©uticos', 'LocalPharmacy', 1)
ON CONFLICT ON CONSTRAINT "UQ_IndustryTemplate_Code" DO NOTHING;

INSERT INTO store."IndustryTemplate" ("CompanyId", "TemplateCode", "TemplateName", "Description", "IconName", "SortOrder")
VALUES (1, 'ROPA', 'Ropa y Calzado', 'Prendas de vestir, calzado y accesorios de moda', 'Checkroom', 2)
ON CONFLICT ON CONSTRAINT "UQ_IndustryTemplate_Code" DO NOTHING;

INSERT INTO store."IndustryTemplate" ("CompanyId", "TemplateCode", "TemplateName", "Description", "IconName", "SortOrder")
VALUES (1, 'ELECTRONICA', 'ElectrÃ³nica', 'Dispositivos electrÃ³nicos, componentes y accesorios', 'Devices', 3)
ON CONFLICT ON CONSTRAINT "UQ_IndustryTemplate_Code" DO NOTHING;

INSERT INTO store."IndustryTemplate" ("CompanyId", "TemplateCode", "TemplateName", "Description", "IconName", "SortOrder")
VALUES (1, 'ALIMENTOS', 'Alimentos y Bebidas', 'Productos alimenticios, bebidas y productos perecederos', 'Restaurant', 4)
ON CONFLICT ON CONSTRAINT "UQ_IndustryTemplate_Code" DO NOTHING;

-- 4b. Atributos de FARMACIA
INSERT INTO store."IndustryTemplateAttribute" ("CompanyId", "TemplateCode", "AttributeKey", "AttributeLabel", "DataType", "IsRequired", "DisplayGroup", "SortOrder") VALUES
(1, 'FARMACIA', 'PrincipioActivo',     'Principio Activo',        'TEXT',    TRUE,  'ComposiciÃ³n',          1),
(1, 'FARMACIA', 'Concentracion',        'ConcentraciÃ³n',           'TEXT',    TRUE,  'ComposiciÃ³n',          2),
(1, 'FARMACIA', 'FormaFarmaceutica',    'Forma FarmacÃ©utica',      'LIST',    TRUE,  'PresentaciÃ³n',         3),
(1, 'FARMACIA', 'ViaAdministracion',    'VÃ­a de AdministraciÃ³n',   'LIST',    FALSE, 'PresentaciÃ³n',         4),
(1, 'FARMACIA', 'RegistroSanitario',    'Registro Sanitario',      'TEXT',    TRUE,  'Regulatorio',          5),
(1, 'FARMACIA', 'Laboratorio',          'Laboratorio Fabricante',  'TEXT',    TRUE,  'Regulatorio',          6),
(1, 'FARMACIA', 'RequiereReceta',       'Requiere Receta',         'BOOLEAN', TRUE,  'Regulatorio',          7),
(1, 'FARMACIA', 'FechaVencimiento',     'Fecha de Vencimiento',    'DATE',    FALSE, 'Control de Lote',      8),
(1, 'FARMACIA', 'Lote',                 'NÃºmero de Lote',          'TEXT',    FALSE, 'Control de Lote',      9),
(1, 'FARMACIA', 'Contraindicaciones',   'Contraindicaciones Clave','TEXT',    FALSE, 'InformaciÃ³n ClÃ­nica', 10)
ON CONFLICT ON CONSTRAINT "UQ_TemplateAttribute_Key" DO NOTHING;

-- Opciones LIST para FARMACIA
UPDATE store."IndustryTemplateAttribute"
SET "ListOptions" = '["Tableta","CÃ¡psula","Jarabe","SoluciÃ³n inyectable","Crema","Gel","Supositorio","Gotas","Aerosol","Parche transdÃ©rmico","Polvo para suspensiÃ³n"]'
WHERE "TemplateCode" = 'FARMACIA' AND "AttributeKey" = 'FormaFarmaceutica' AND "CompanyId" = 1 AND "ListOptions" IS NULL;

UPDATE store."IndustryTemplateAttribute"
SET "ListOptions" = '["Oral","Intravenosa","Intramuscular","SubcutÃ¡nea","TÃ³pica","Rectal","OftÃ¡lmica","Ã“tica","Nasal","Inhalatoria","Sublingual"]'
WHERE "TemplateCode" = 'FARMACIA' AND "AttributeKey" = 'ViaAdministracion' AND "CompanyId" = 1 AND "ListOptions" IS NULL;

-- 4c. Atributos de ROPA
INSERT INTO store."IndustryTemplateAttribute" ("CompanyId", "TemplateCode", "AttributeKey", "AttributeLabel", "DataType", "IsRequired", "DisplayGroup", "SortOrder") VALUES
(1, 'ROPA', 'Material',             'Material / ComposiciÃ³n',    'TEXT',    TRUE,  'ComposiciÃ³n',    1),
(1, 'ROPA', 'Genero',               'GÃ©nero',                    'LIST',    TRUE,  'ClasificaciÃ³n',  2),
(1, 'ROPA', 'Temporada',            'Temporada',                 'LIST',    FALSE, 'ClasificaciÃ³n',  3),
(1, 'ROPA', 'PaisOrigen',           'PaÃ­s de Origen',            'TEXT',    FALSE, 'Origen',         4),
(1, 'ROPA', 'InstruccionesLavado',  'Instrucciones de Lavado',   'TEXT',    FALSE, 'Cuidado',        5),
(1, 'ROPA', 'TipoPrenda',           'Tipo de Prenda',            'TEXT',    FALSE, 'ClasificaciÃ³n',  6),
(1, 'ROPA', 'Ajuste',               'Ajuste / Fit',              'LIST',    FALSE, 'ClasificaciÃ³n',  7)
ON CONFLICT ON CONSTRAINT "UQ_TemplateAttribute_Key" DO NOTHING;

UPDATE store."IndustryTemplateAttribute"
SET "ListOptions" = '["Hombre","Mujer","Unisex","NiÃ±o","NiÃ±a"]'
WHERE "TemplateCode" = 'ROPA' AND "AttributeKey" = 'Genero' AND "CompanyId" = 1 AND "ListOptions" IS NULL;

UPDATE store."IndustryTemplateAttribute"
SET "ListOptions" = '["Primavera/Verano","OtoÃ±o/Invierno","Todo el aÃ±o"]'
WHERE "TemplateCode" = 'ROPA' AND "AttributeKey" = 'Temporada' AND "CompanyId" = 1 AND "ListOptions" IS NULL;

UPDATE store."IndustryTemplateAttribute"
SET "ListOptions" = '["Regular","Slim","Oversize","Ajustado","Holgado"]'
WHERE "TemplateCode" = 'ROPA' AND "AttributeKey" = 'Ajuste' AND "CompanyId" = 1 AND "ListOptions" IS NULL;

-- 4d. Atributos de ELECTRONICA
INSERT INTO store."IndustryTemplateAttribute" ("CompanyId", "TemplateCode", "AttributeKey", "AttributeLabel", "DataType", "IsRequired", "DisplayGroup", "SortOrder") VALUES
(1, 'ELECTRONICA', 'Voltaje',                'Voltaje',                 'TEXT',    FALSE, 'ElÃ©ctrico',        1),
(1, 'ELECTRONICA', 'Potencia',               'Potencia (W)',            'NUMBER',  FALSE, 'ElÃ©ctrico',        2),
(1, 'ELECTRONICA', 'Conectividad',           'Conectividad',            'TEXT',    FALSE, 'Conectividad',     3),
(1, 'ELECTRONICA', 'SistemaOperativo',       'Sistema Operativo',       'TEXT',    FALSE, 'Software',         4),
(1, 'ELECTRONICA', 'Capacidad',              'Capacidad de Almacenamiento', 'TEXT', FALSE, 'Almacenamiento', 5),
(1, 'ELECTRONICA', 'Resolucion',             'ResoluciÃ³n',              'TEXT',    FALSE, 'Pantalla',         6),
(1, 'ELECTRONICA', 'CertificacionesTecnicas','Certificaciones TÃ©cnicas','TEXT',    FALSE, 'Regulatorio',      7)
ON CONFLICT ON CONSTRAINT "UQ_TemplateAttribute_Key" DO NOTHING;

-- 4e. Atributos de ALIMENTOS
INSERT INTO store."IndustryTemplateAttribute" ("CompanyId", "TemplateCode", "AttributeKey", "AttributeLabel", "DataType", "IsRequired", "DisplayGroup", "SortOrder") VALUES
(1, 'ALIMENTOS', 'Ingredientes',             'Ingredientes',                'TEXT',    TRUE,  'ComposiciÃ³n',          1),
(1, 'ALIMENTOS', 'InformacionNutricional',   'InformaciÃ³n Nutricional',     'TEXT',    FALSE, 'ComposiciÃ³n',          2),
(1, 'ALIMENTOS', 'Alergenos',                'AlÃ©rgenos',                   'TEXT',    FALSE, 'ComposiciÃ³n',          3),
(1, 'ALIMENTOS', 'PesoNeto',                 'Peso Neto',                   'TEXT',    TRUE,  'PresentaciÃ³n',         4),
(1, 'ALIMENTOS', 'FechaVencimiento',         'Fecha de Vencimiento',        'DATE',    FALSE, 'Control de Lote',      5),
(1, 'ALIMENTOS', 'Lote',                     'NÃºmero de Lote',              'TEXT',    FALSE, 'Control de Lote',      6),
(1, 'ALIMENTOS', 'RegistroSanitario',        'Registro Sanitario',          'TEXT',    TRUE,  'Regulatorio',          7),
(1, 'ALIMENTOS', 'PaisOrigen',               'PaÃ­s de Origen',              'TEXT',    FALSE, 'Origen',               8),
(1, 'ALIMENTOS', 'Organico',                 'OrgÃ¡nico',                    'BOOLEAN', FALSE, 'Certificaciones',      9),
(1, 'ALIMENTOS', 'SinGluten',                'Sin Gluten',                  'BOOLEAN', FALSE, 'Certificaciones',     10),
(1, 'ALIMENTOS', 'SinLactosa',               'Sin Lactosa',                 'BOOLEAN', FALSE, 'Certificaciones',     11),
(1, 'ALIMENTOS', 'CondicionesAlmacenamiento','Condiciones de Almacenamiento','TEXT',   FALSE, 'Almacenamiento',      12)
ON CONFLICT ON CONSTRAINT "UQ_TemplateAttribute_Key" DO NOTHING;

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- PARTE 5: SEED â€” Grupos de variaciÃ³n predefinidos
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

INSERT INTO store."ProductVariantGroup" ("CompanyId", "GroupCode", "GroupName", "DisplayType", "SortOrder") VALUES
(1, 'COLOR',      'Color',      'SWATCH',   1),
(1, 'TALLA',      'Talla',      'BUTTON',   2),
(1, 'CAPACIDAD',  'Capacidad',  'BUTTON',   3),
(1, 'MATERIAL',   'Material',   'DROPDOWN', 4),
(1, 'ESTILO',     'Estilo',     'DROPDOWN', 5)
ON CONFLICT ON CONSTRAINT "UQ_ProductVariantGroup_Code" DO NOTHING;

-- Opciones de COLOR
DO $$
DECLARE
    v_color_group_id INT;
    v_talla_group_id INT;
    v_cap_group_id   INT;
BEGIN
    SELECT "VariantGroupId" INTO v_color_group_id
    FROM store."ProductVariantGroup"
    WHERE "GroupCode" = 'COLOR' AND "CompanyId" = 1;

    INSERT INTO store."ProductVariantOption" ("CompanyId", "VariantGroupId", "OptionCode", "OptionLabel", "ColorHex", "SortOrder") VALUES
    (1, v_color_group_id, 'NEGRO',     'Negro',     '#000000', 1),
    (1, v_color_group_id, 'BLANCO',    'Blanco',    '#FFFFFF', 2),
    (1, v_color_group_id, 'ROJO',      'Rojo',      '#E53935', 3),
    (1, v_color_group_id, 'AZUL',      'Azul',      '#1E88E5', 4),
    (1, v_color_group_id, 'VERDE',     'Verde',     '#43A047', 5),
    (1, v_color_group_id, 'GRIS',      'Gris',      '#757575', 6),
    (1, v_color_group_id, 'ROSA',      'Rosa',      '#E91E63', 7),
    (1, v_color_group_id, 'MORADO',    'Morado',    '#7B1FA2', 8),
    (1, v_color_group_id, 'NARANJA',   'Naranja',   '#FF6F00', 9),
    (1, v_color_group_id, 'AMARILLO',  'Amarillo',  '#FDD835', 10)
    ON CONFLICT ON CONSTRAINT "UQ_VariantOption_Code" DO NOTHING;

    -- Opciones de TALLA
    SELECT "VariantGroupId" INTO v_talla_group_id
    FROM store."ProductVariantGroup"
    WHERE "GroupCode" = 'TALLA' AND "CompanyId" = 1;

    INSERT INTO store."ProductVariantOption" ("CompanyId", "VariantGroupId", "OptionCode", "OptionLabel", "SortOrder") VALUES
    (1, v_talla_group_id, 'XS',   'XS',   1),
    (1, v_talla_group_id, 'S',    'S',    2),
    (1, v_talla_group_id, 'M',    'M',    3),
    (1, v_talla_group_id, 'L',    'L',    4),
    (1, v_talla_group_id, 'XL',   'XL',   5),
    (1, v_talla_group_id, 'XXL',  'XXL',  6),
    (1, v_talla_group_id, 'XXXL', 'XXXL', 7)
    ON CONFLICT ON CONSTRAINT "UQ_VariantOption_Code" DO NOTHING;

    -- Opciones de CAPACIDAD
    SELECT "VariantGroupId" INTO v_cap_group_id
    FROM store."ProductVariantGroup"
    WHERE "GroupCode" = 'CAPACIDAD' AND "CompanyId" = 1;

    INSERT INTO store."ProductVariantOption" ("CompanyId", "VariantGroupId", "OptionCode", "OptionLabel", "SortOrder") VALUES
    (1, v_cap_group_id, '32GB',   '32 GB',   1),
    (1, v_cap_group_id, '64GB',   '64 GB',   2),
    (1, v_cap_group_id, '128GB',  '128 GB',  3),
    (1, v_cap_group_id, '256GB',  '256 GB',  4),
    (1, v_cap_group_id, '512GB',  '512 GB',  5),
    (1, v_cap_group_id, '1TB',    '1 TB',    6)
    ON CONFLICT ON CONSTRAINT "UQ_VariantOption_Code" DO NOTHING;
END
$$;

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- PARTE 6: Funciones â€” Lectura de variantes y atributos
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- 6a. Listar grupos de variaciÃ³n
DROP FUNCTION IF EXISTS public.usp_store_variantgroup_list(INT);
CREATE OR REPLACE FUNCTION public.usp_store_variantgroup_list(
    p_company_id INT DEFAULT 1
)
RETURNS TABLE(
    "id"          INT,
    "code"        VARCHAR(30),
    "name"        VARCHAR(100),
    "displayType" VARCHAR(20),
    "sortOrder"   INT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        vg."VariantGroupId"  AS "id",
        vg."GroupCode"       AS "code",
        vg."GroupName"       AS "name",
        vg."DisplayType"     AS "displayType",
        vg."SortOrder"       AS "sortOrder"
    FROM store."ProductVariantGroup" vg
    WHERE vg."CompanyId" = p_company_id
      AND vg."IsDeleted" = FALSE
      AND vg."IsActive"  = TRUE
    ORDER BY vg."SortOrder", vg."GroupName";
END;
$$;

-- 6b. Obtener opciones de un grupo de variaciÃ³n
DROP FUNCTION IF EXISTS public.usp_store_variantgroup_getoptions(INT, VARCHAR);
CREATE OR REPLACE FUNCTION public.usp_store_variantgroup_getoptions(
    p_company_id  INT DEFAULT 1,
    p_group_code  VARCHAR(30) DEFAULT NULL
)
RETURNS TABLE(
    "id"        INT,
    "code"      VARCHAR(30),
    "label"     VARCHAR(100),
    "colorHex"  VARCHAR(7),
    "imageUrl"  VARCHAR(500),
    "sortOrder" INT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        vo."VariantOptionId" AS "id",
        vo."OptionCode"      AS "code",
        vo."OptionLabel"     AS "label",
        vo."ColorHex"        AS "colorHex",
        vo."ImageUrl"        AS "imageUrl",
        vo."SortOrder"       AS "sortOrder"
    FROM store."ProductVariantOption" vo
    INNER JOIN store."ProductVariantGroup" vg ON vg."VariantGroupId" = vo."VariantGroupId"
    WHERE vo."CompanyId" = p_company_id
      AND vg."GroupCode" = p_group_code
      AND vo."IsDeleted" = FALSE
      AND vo."IsActive"  = TRUE
      AND vg."IsDeleted" = FALSE
      AND vg."IsActive"  = TRUE
    ORDER BY vo."SortOrder", vo."OptionLabel";
END;
$$;

-- 6c. Obtener variantes de un producto padre (Recordset 1: variantes)
DROP FUNCTION IF EXISTS public.usp_store_product_getvariants(INT, VARCHAR);
CREATE OR REPLACE FUNCTION public.usp_store_product_getvariants(
    p_company_id          INT DEFAULT 1,
    p_parent_product_code VARCHAR(80) DEFAULT NULL
)
RETURNS TABLE(
    "variantId"  INT,
    "code"       VARCHAR(80),
    "name"       VARCHAR(200),
    "sku"        VARCHAR(80),
    "price"      NUMERIC(18,2),
    "priceDelta" NUMERIC(18,2),
    "stock"      NUMERIC(18,4),
    "isDefault"  BOOLEAN,
    "sortOrder"  INT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pv."ProductVariantId"                                      AS "variantId",
        pv."VariantProductCode"                                    AS "code",
        p."ProductName"                                            AS "name",
        COALESCE(pv."SKU", pv."VariantProductCode")                AS "sku",
        p."SalesPrice"                                             AS "price",
        pv."PriceDelta"                                            AS "priceDelta",
        COALESCE(pv."StockOverride", p."StockQty")                 AS "stock",
        pv."IsDefault"                                             AS "isDefault",
        pv."SortOrder"                                             AS "sortOrder"
    FROM store."ProductVariant" pv
    INNER JOIN master."Product" p
        ON p."ProductCode" = pv."VariantProductCode"
       AND p."CompanyId"   = pv."CompanyId"
    WHERE pv."CompanyId"          = p_company_id
      AND pv."ParentProductCode"  = p_parent_product_code
      AND pv."IsDeleted" = FALSE
      AND pv."IsActive"  = TRUE
      AND p."IsDeleted"  = FALSE
      AND p."IsActive"   = TRUE
    ORDER BY pv."SortOrder", pv."ProductVariantId";
END;
$$;

-- 6c-bis. Obtener opciones elegidas por variante (Recordset 2 del SP original)
DROP FUNCTION IF EXISTS public.usp_store_product_getvariantoptions(INT, VARCHAR);
CREATE OR REPLACE FUNCTION public.usp_store_product_getvariantoptions(
    p_company_id          INT DEFAULT 1,
    p_parent_product_code VARCHAR(80) DEFAULT NULL
)
RETURNS TABLE(
    "code"        VARCHAR(80),
    "groupCode"   VARCHAR(30),
    "groupName"   VARCHAR(100),
    "displayType" VARCHAR(20),
    "optionCode"  VARCHAR(30),
    "optionLabel" VARCHAR(100),
    "colorHex"    VARCHAR(7),
    "imageUrl"    VARCHAR(500)
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pv."VariantProductCode" AS "code",
        vg."GroupCode"          AS "groupCode",
        vg."GroupName"          AS "groupName",
        vg."DisplayType"       AS "displayType",
        vo."OptionCode"         AS "optionCode",
        vo."OptionLabel"        AS "optionLabel",
        vo."ColorHex"           AS "colorHex",
        vo."ImageUrl"           AS "imageUrl"
    FROM store."ProductVariantOptionValue" pvov
    INNER JOIN store."ProductVariant" pv       ON pv."ProductVariantId"  = pvov."ProductVariantId"
    INNER JOIN store."ProductVariantOption" vo  ON vo."VariantOptionId"   = pvov."VariantOptionId"
    INNER JOIN store."ProductVariantGroup" vg   ON vg."VariantGroupId"   = vo."VariantGroupId"
    WHERE pv."CompanyId"          = p_company_id
      AND pv."ParentProductCode"  = p_parent_product_code
      AND pv."IsDeleted" = FALSE
      AND pv."IsActive"  = TRUE
    ORDER BY vg."SortOrder", vo."SortOrder";
END;
$$;

-- 6d. Listar plantillas de industria (Recordset 1: plantillas)
DROP FUNCTION IF EXISTS public.usp_store_industrytemplate_list(INT);
CREATE OR REPLACE FUNCTION public.usp_store_industrytemplate_list(
    p_company_id INT DEFAULT 1
)
RETURNS TABLE(
    "id"          INT,
    "code"        VARCHAR(30),
    "name"        VARCHAR(100),
    "description" VARCHAR(500),
    "iconName"    VARCHAR(50),
    "sortOrder"   INT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        it."IndustryTemplateId" AS "id",
        it."TemplateCode"       AS "code",
        it."TemplateName"       AS "name",
        it."Description"        AS "description",
        it."IconName"           AS "iconName",
        it."SortOrder"          AS "sortOrder"
    FROM store."IndustryTemplate" it
    WHERE it."CompanyId" = p_company_id
      AND it."IsDeleted" = FALSE
      AND it."IsActive"  = TRUE
    ORDER BY it."SortOrder", it."TemplateName";
END;
$$;

-- 6d-bis. Listar atributos de todas las plantillas (Recordset 2 del SP original)
DROP FUNCTION IF EXISTS public.usp_store_industrytemplate_listattributes(INT);
CREATE OR REPLACE FUNCTION public.usp_store_industrytemplate_listattributes(
    p_company_id INT DEFAULT 1
)
RETURNS TABLE(
    "templateCode" VARCHAR(30),
    "key"          VARCHAR(50),
    "label"        VARCHAR(100),
    "dataType"     VARCHAR(20),
    "isRequired"   BOOLEAN,
    "defaultValue" VARCHAR(200),
    "listOptions"  TEXT,
    "displayGroup" VARCHAR(100),
    "sortOrder"    INT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        ita."TemplateCode"   AS "templateCode",
        ita."AttributeKey"   AS "key",
        ita."AttributeLabel" AS "label",
        ita."DataType"       AS "dataType",
        ita."IsRequired"     AS "isRequired",
        ita."DefaultValue"   AS "defaultValue",
        ita."ListOptions"    AS "listOptions",
        ita."DisplayGroup"   AS "displayGroup",
        ita."SortOrder"      AS "sortOrder"
    FROM store."IndustryTemplateAttribute" ita
    WHERE ita."CompanyId" = p_company_id
      AND ita."IsDeleted" = FALSE
      AND ita."IsActive"  = TRUE
    ORDER BY ita."TemplateCode", ita."SortOrder";
END;
$$;

-- 6e. Obtener atributos de un producto
DROP FUNCTION IF EXISTS public.usp_store_product_getattributes(INT, VARCHAR);
CREATE OR REPLACE FUNCTION public.usp_store_product_getattributes(
    p_company_id   INT DEFAULT 1,
    p_product_code VARCHAR(80) DEFAULT NULL
)
RETURNS TABLE(
    "key"          VARCHAR(50),
    "label"        VARCHAR(100),
    "dataType"     VARCHAR(20),
    "displayGroup" VARCHAR(100),
    "valueText"    VARCHAR(500),
    "valueNumber"  NUMERIC(18,4),
    "valueDate"    DATE,
    "valueBoolean" BOOLEAN,
    "sortOrder"    INT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        pa."AttributeKey"    AS "key",
        ita."AttributeLabel" AS "label",
        ita."DataType"       AS "dataType",
        ita."DisplayGroup"   AS "displayGroup",
        pa."ValueText"       AS "valueText",
        pa."ValueNumber"     AS "valueNumber",
        pa."ValueDate"       AS "valueDate",
        pa."ValueBoolean"    AS "valueBoolean",
        ita."SortOrder"      AS "sortOrder"
    FROM store."ProductAttribute" pa
    INNER JOIN store."IndustryTemplateAttribute" ita
        ON ita."TemplateCode"  = pa."TemplateCode"
       AND ita."AttributeKey"  = pa."AttributeKey"
       AND ita."CompanyId"     = pa."CompanyId"
       AND ita."IsDeleted"     = FALSE
       AND ita."IsActive"      = TRUE
    WHERE pa."CompanyId"   = p_company_id
      AND pa."ProductCode" = p_product_code
      AND pa."IsDeleted"   = FALSE
      AND pa."IsActive"    = TRUE
    ORDER BY ita."DisplayGroup", ita."SortOrder";
END;
$$;
