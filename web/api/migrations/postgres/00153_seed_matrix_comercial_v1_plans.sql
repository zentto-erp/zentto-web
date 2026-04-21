-- +goose Up
-- ══════════════════════════════════════════════════════════════════════════════
-- Lanzamiento multinicho — Lote 1.C1
-- Seed de los 10 planes CORE de la matriz comercial v1.
-- Ver docs/lanzamiento/MATRIZ_COMERCIAL_V1.md.
--
-- UPSERT idempotente por Slug (uq_pricing_plan_slug). Cada ejecución deja la
-- fila sincronizada con los valores abajo; el admin puede editar precios,
-- ModuleCodes y Limits desde el backoffice y la re-ejecución de esta
-- migración NO ocurrirá (goose_db_version marca 153 como aplicada).
--
-- PaddleSyncStatus='draft' — la sincronización a Paddle se dispara manualmente
-- vía POST /v1/backoffice/catalog/paddle/sync-all cuando el equipo comercial
-- confirme precios definitivos.
--
-- Solo PostgreSQL (ver docs/lanzamiento/DECISIONES.md §D-002).
-- ══════════════════════════════════════════════════════════════════════════════

-- ERP general — entry-point del portafolio clásico
INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode", "Description",
    "MonthlyPrice", "AnnualPrice", "BillingCycleDefault",
    "MaxUsers", "MaxTransactions",
    "Features", "ModuleCodes", "Limits",
    "Tier", "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "IsActive", "PaddleSyncStatus", "CompanyId"
) VALUES (
    'ERP Starter', 'erp-starter', 'erp', 'erp-core',
    'ERP integral: facturación, inventario, cxc/cxp, bancos y reportes. Ideal para PyMEs que quieren operar todo el ciclo administrativo en una sola plataforma.',
    49.00, 490.00, 'monthly',
    5, 500,
    '["Facturación electrónica", "Inventario", "Cuentas por cobrar y pagar", "Bancos", "Reportes fiscales"]'::jsonb,
    '["dashboard","facturas","abonos","cxc","clientes","compras","cxp","proveedores","inventario","articulos","pagos","bancos","reportes","configuracion","usuarios"]'::jsonb,
    '{"apiCalls":10000,"storage":5,"users":5}'::jsonb,
    'core', FALSE, FALSE, 14,
    10, TRUE, 'draft', 0
)
ON CONFLICT ("Slug") DO UPDATE SET
    "Name"                = EXCLUDED."Name",
    "VerticalType"        = EXCLUDED."VerticalType",
    "ProductCode"         = EXCLUDED."ProductCode",
    "Description"         = EXCLUDED."Description",
    "MonthlyPrice"        = EXCLUDED."MonthlyPrice",
    "AnnualPrice"         = EXCLUDED."AnnualPrice",
    "BillingCycleDefault" = EXCLUDED."BillingCycleDefault",
    "MaxUsers"            = EXCLUDED."MaxUsers",
    "MaxTransactions"     = EXCLUDED."MaxTransactions",
    "Features"            = EXCLUDED."Features",
    "ModuleCodes"         = EXCLUDED."ModuleCodes",
    "Limits"              = EXCLUDED."Limits",
    "Tier"                = EXCLUDED."Tier",
    "IsAddon"             = EXCLUDED."IsAddon",
    "IsTrialOnly"         = EXCLUDED."IsTrialOnly",
    "TrialDays"           = EXCLUDED."TrialDays",
    "SortOrder"           = EXCLUDED."SortOrder",
    "IsActive"            = EXCLUDED."IsActive",
    "UpdatedAt"           = NOW();

-- Retail POS
INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode", "Description",
    "MonthlyPrice", "AnnualPrice", "BillingCycleDefault",
    "MaxUsers", "MaxTransactions",
    "Features", "ModuleCodes", "Limits",
    "Tier", "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "IsActive", "PaddleSyncStatus", "CompanyId"
) VALUES (
    'POS Starter', 'pos-starter', 'pos', 'pos-core',
    'Punto de venta táctil con inventario, clientes y cierre de caja. Integra impresora fiscal vía Zentto Fiscal Agent.',
    39.00, 390.00, 'monthly',
    3, 500,
    '["POS táctil", "Impresora fiscal", "Inventario", "Cierre de caja", "Reportes diarios"]'::jsonb,
    '["dashboard","pos","clientes","articulos","inventario","pagos","reportes","usuarios"]'::jsonb,
    '{"apiCalls":10000,"storage":3,"users":3}'::jsonb,
    'core', FALSE, FALSE, 14,
    20, TRUE, 'draft', 0
)
ON CONFLICT ("Slug") DO UPDATE SET
    "Name"=EXCLUDED."Name","VerticalType"=EXCLUDED."VerticalType","ProductCode"=EXCLUDED."ProductCode","Description"=EXCLUDED."Description",
    "MonthlyPrice"=EXCLUDED."MonthlyPrice","AnnualPrice"=EXCLUDED."AnnualPrice","BillingCycleDefault"=EXCLUDED."BillingCycleDefault",
    "MaxUsers"=EXCLUDED."MaxUsers","MaxTransactions"=EXCLUDED."MaxTransactions",
    "Features"=EXCLUDED."Features","ModuleCodes"=EXCLUDED."ModuleCodes","Limits"=EXCLUDED."Limits",
    "Tier"=EXCLUDED."Tier","IsAddon"=EXCLUDED."IsAddon","IsTrialOnly"=EXCLUDED."IsTrialOnly","TrialDays"=EXCLUDED."TrialDays",
    "SortOrder"=EXCLUDED."SortOrder","IsActive"=EXCLUDED."IsActive","UpdatedAt"=NOW();

-- Restaurante
INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode", "Description",
    "MonthlyPrice", "AnnualPrice", "BillingCycleDefault",
    "MaxUsers", "MaxTransactions",
    "Features", "ModuleCodes", "Limits",
    "Tier", "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "IsActive", "PaddleSyncStatus", "CompanyId"
) VALUES (
    'Restaurante Starter', 'resto-starter', 'restaurante', 'restaurante-core',
    'Gestión de mesas, cocina, recetas e inventario de restaurante. Ideal para negocios gastronómicos.',
    49.00, 490.00, 'monthly',
    5, 1000,
    '["Gestión de mesas", "Comanda a cocina", "Recetas y mermas", "Inventario por receta", "Reportes de ventas"]'::jsonb,
    '["dashboard","restaurante","clientes","articulos","inventario","pagos","reportes","usuarios"]'::jsonb,
    '{"apiCalls":15000,"storage":5,"users":5}'::jsonb,
    'core', FALSE, FALSE, 14,
    30, TRUE, 'draft', 0
)
ON CONFLICT ("Slug") DO UPDATE SET
    "Name"=EXCLUDED."Name","VerticalType"=EXCLUDED."VerticalType","ProductCode"=EXCLUDED."ProductCode","Description"=EXCLUDED."Description",
    "MonthlyPrice"=EXCLUDED."MonthlyPrice","AnnualPrice"=EXCLUDED."AnnualPrice","BillingCycleDefault"=EXCLUDED."BillingCycleDefault",
    "MaxUsers"=EXCLUDED."MaxUsers","MaxTransactions"=EXCLUDED."MaxTransactions",
    "Features"=EXCLUDED."Features","ModuleCodes"=EXCLUDED."ModuleCodes","Limits"=EXCLUDED."Limits",
    "Tier"=EXCLUDED."Tier","IsAddon"=EXCLUDED."IsAddon","IsTrialOnly"=EXCLUDED."IsTrialOnly","TrialDays"=EXCLUDED."TrialDays",
    "SortOrder"=EXCLUDED."SortOrder","IsActive"=EXCLUDED."IsActive","UpdatedAt"=NOW();

-- Ecommerce
INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode", "Description",
    "MonthlyPrice", "AnnualPrice", "BillingCycleDefault",
    "MaxUsers", "MaxTransactions",
    "Features", "ModuleCodes", "Limits",
    "Tier", "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "IsActive", "PaddleSyncStatus", "CompanyId"
) VALUES (
    'Ecommerce Starter', 'ecom-starter', 'ecommerce', 'ecommerce-core',
    'Tienda online con checkout, shipping integrado y gestión de inventario multicanal.',
    59.00, 590.00, 'monthly',
    5, 2000,
    '["Tienda online", "Checkout Paddle/Stripe", "Shipping integrado", "Inventario multicanal", "CRM básico"]'::jsonb,
    '["dashboard","ecommerce","clientes","articulos","inventario","shipping","pagos","reportes","usuarios"]'::jsonb,
    '{"apiCalls":20000,"storage":10,"users":5}'::jsonb,
    'core', FALSE, FALSE, 14,
    40, TRUE, 'draft', 0
)
ON CONFLICT ("Slug") DO UPDATE SET
    "Name"=EXCLUDED."Name","VerticalType"=EXCLUDED."VerticalType","ProductCode"=EXCLUDED."ProductCode","Description"=EXCLUDED."Description",
    "MonthlyPrice"=EXCLUDED."MonthlyPrice","AnnualPrice"=EXCLUDED."AnnualPrice","BillingCycleDefault"=EXCLUDED."BillingCycleDefault",
    "MaxUsers"=EXCLUDED."MaxUsers","MaxTransactions"=EXCLUDED."MaxTransactions",
    "Features"=EXCLUDED."Features","ModuleCodes"=EXCLUDED."ModuleCodes","Limits"=EXCLUDED."Limits",
    "Tier"=EXCLUDED."Tier","IsAddon"=EXCLUDED."IsAddon","IsTrialOnly"=EXCLUDED."IsTrialOnly","TrialDays"=EXCLUDED."TrialDays",
    "SortOrder"=EXCLUDED."SortOrder","IsActive"=EXCLUDED."IsActive","UpdatedAt"=NOW();

-- CRM only
INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode", "Description",
    "MonthlyPrice", "AnnualPrice", "BillingCycleDefault",
    "MaxUsers", "MaxTransactions",
    "Features", "ModuleCodes", "Limits",
    "Tier", "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "IsActive", "PaddleSyncStatus", "CompanyId"
) VALUES (
    'CRM Pro', 'crm-pro', 'crm', 'crm-core',
    'Pipeline de ventas, leads, actividades y call center. Design system Zentto v2.',
    29.00, 290.00, 'monthly',
    3, 5000,
    '["Pipeline de ventas", "Leads y actividades", "Call center básico", "Reportes", "Campañas"]'::jsonb,
    '["dashboard","crm","clientes","reportes","usuarios"]'::jsonb,
    '{"apiCalls":10000,"storage":3,"users":3}'::jsonb,
    'core', FALSE, FALSE, 14,
    50, TRUE, 'draft', 0
)
ON CONFLICT ("Slug") DO UPDATE SET
    "Name"=EXCLUDED."Name","VerticalType"=EXCLUDED."VerticalType","ProductCode"=EXCLUDED."ProductCode","Description"=EXCLUDED."Description",
    "MonthlyPrice"=EXCLUDED."MonthlyPrice","AnnualPrice"=EXCLUDED."AnnualPrice","BillingCycleDefault"=EXCLUDED."BillingCycleDefault",
    "MaxUsers"=EXCLUDED."MaxUsers","MaxTransactions"=EXCLUDED."MaxTransactions",
    "Features"=EXCLUDED."Features","ModuleCodes"=EXCLUDED."ModuleCodes","Limits"=EXCLUDED."Limits",
    "Tier"=EXCLUDED."Tier","IsAddon"=EXCLUDED."IsAddon","IsTrialOnly"=EXCLUDED."IsTrialOnly","TrialDays"=EXCLUDED."TrialDays",
    "SortOrder"=EXCLUDED."SortOrder","IsActive"=EXCLUDED."IsActive","UpdatedAt"=NOW();

-- Contabilidad
INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode", "Description",
    "MonthlyPrice", "AnnualPrice", "BillingCycleDefault",
    "MaxUsers", "MaxTransactions",
    "Features", "ModuleCodes", "Limits",
    "Tier", "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "IsActive", "PaddleSyncStatus", "CompanyId"
) VALUES (
    'Contabilidad Pro', 'cont-pro', 'contabilidad', 'contabilidad-core',
    'Asientos, plan de cuentas, activos fijos, fiscal y reportes regulatorios.',
    49.00, 490.00, 'monthly',
    5, 2000,
    '["Asientos contables", "Plan de cuentas", "Activos fijos", "Fiscal multi-país", "Reportes regulatorios"]'::jsonb,
    '["dashboard","contabilidad","facturas","cxc","cxp","bancos","reportes","configuracion","usuarios"]'::jsonb,
    '{"apiCalls":15000,"storage":5,"users":5}'::jsonb,
    'core', FALSE, FALSE, 14,
    60, TRUE, 'draft', 0
)
ON CONFLICT ("Slug") DO UPDATE SET
    "Name"=EXCLUDED."Name","VerticalType"=EXCLUDED."VerticalType","ProductCode"=EXCLUDED."ProductCode","Description"=EXCLUDED."Description",
    "MonthlyPrice"=EXCLUDED."MonthlyPrice","AnnualPrice"=EXCLUDED."AnnualPrice","BillingCycleDefault"=EXCLUDED."BillingCycleDefault",
    "MaxUsers"=EXCLUDED."MaxUsers","MaxTransactions"=EXCLUDED."MaxTransactions",
    "Features"=EXCLUDED."Features","ModuleCodes"=EXCLUDED."ModuleCodes","Limits"=EXCLUDED."Limits",
    "Tier"=EXCLUDED."Tier","IsAddon"=EXCLUDED."IsAddon","IsTrialOnly"=EXCLUDED."IsTrialOnly","TrialDays"=EXCLUDED."TrialDays",
    "SortOrder"=EXCLUDED."SortOrder","IsActive"=EXCLUDED."IsActive","UpdatedAt"=NOW();

-- Hotel (app externa zentto-hotel; ERP core mínimo para documentos + app specific entitlement)
INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode", "Description",
    "MonthlyPrice", "AnnualPrice", "BillingCycleDefault",
    "MaxUsers", "MaxTransactions",
    "Features", "ModuleCodes", "Limits",
    "Tier", "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "IsActive", "PaddleSyncStatus", "CompanyId"
) VALUES (
    'Hotel Core', 'hotel-core', 'hotel', 'hotel-core',
    'PMS hotelero: reservas, habitaciones, check-in/out, tarifas. Conecta con zentto-hotel standalone.',
    79.00, 790.00, 'monthly',
    5, 2000,
    '["Reservas y tarifas", "Check-in/out", "Housekeeping", "Facturación integrada", "Reportes de ocupación"]'::jsonb,
    '["dashboard","clientes","facturas","pagos","reportes","usuarios","hotel"]'::jsonb,
    '{"apiCalls":15000,"storage":10,"users":5,"rooms":30}'::jsonb,
    'core', FALSE, FALSE, 14,
    70, TRUE, 'draft', 0
)
ON CONFLICT ("Slug") DO UPDATE SET
    "Name"=EXCLUDED."Name","VerticalType"=EXCLUDED."VerticalType","ProductCode"=EXCLUDED."ProductCode","Description"=EXCLUDED."Description",
    "MonthlyPrice"=EXCLUDED."MonthlyPrice","AnnualPrice"=EXCLUDED."AnnualPrice","BillingCycleDefault"=EXCLUDED."BillingCycleDefault",
    "MaxUsers"=EXCLUDED."MaxUsers","MaxTransactions"=EXCLUDED."MaxTransactions",
    "Features"=EXCLUDED."Features","ModuleCodes"=EXCLUDED."ModuleCodes","Limits"=EXCLUDED."Limits",
    "Tier"=EXCLUDED."Tier","IsAddon"=EXCLUDED."IsAddon","IsTrialOnly"=EXCLUDED."IsTrialOnly","TrialDays"=EXCLUDED."TrialDays",
    "SortOrder"=EXCLUDED."SortOrder","IsActive"=EXCLUDED."IsActive","UpdatedAt"=NOW();

-- Medical (app externa zentto-medical)
INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode", "Description",
    "MonthlyPrice", "AnnualPrice", "BillingCycleDefault",
    "MaxUsers", "MaxTransactions",
    "Features", "ModuleCodes", "Limits",
    "Tier", "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "IsActive", "PaddleSyncStatus", "CompanyId"
) VALUES (
    'Medical Core', 'medical-core', 'medical', 'medical-core',
    'Gestión médica: citas, pacientes, doctores, historia clínica. Conecta con zentto-medical standalone.',
    69.00, 690.00, 'monthly',
    5, 2000,
    '["Agenda de citas", "Historia clínica", "Presupuestos", "Chat paciente-médico", "Facturación integrada"]'::jsonb,
    '["dashboard","clientes","facturas","pagos","reportes","usuarios","medical"]'::jsonb,
    '{"apiCalls":15000,"storage":10,"users":5,"practitioners":5}'::jsonb,
    'core', FALSE, FALSE, 14,
    80, TRUE, 'draft', 0
)
ON CONFLICT ("Slug") DO UPDATE SET
    "Name"=EXCLUDED."Name","VerticalType"=EXCLUDED."VerticalType","ProductCode"=EXCLUDED."ProductCode","Description"=EXCLUDED."Description",
    "MonthlyPrice"=EXCLUDED."MonthlyPrice","AnnualPrice"=EXCLUDED."AnnualPrice","BillingCycleDefault"=EXCLUDED."BillingCycleDefault",
    "MaxUsers"=EXCLUDED."MaxUsers","MaxTransactions"=EXCLUDED."MaxTransactions",
    "Features"=EXCLUDED."Features","ModuleCodes"=EXCLUDED."ModuleCodes","Limits"=EXCLUDED."Limits",
    "Tier"=EXCLUDED."Tier","IsAddon"=EXCLUDED."IsAddon","IsTrialOnly"=EXCLUDED."IsTrialOnly","TrialDays"=EXCLUDED."TrialDays",
    "SortOrder"=EXCLUDED."SortOrder","IsActive"=EXCLUDED."IsActive","UpdatedAt"=NOW();

-- Education (app externa zentto-education)
INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode", "Description",
    "MonthlyPrice", "AnnualPrice", "BillingCycleDefault",
    "MaxUsers", "MaxTransactions",
    "Features", "ModuleCodes", "Limits",
    "Tier", "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "IsActive", "PaddleSyncStatus", "CompanyId"
) VALUES (
    'Education Core', 'education-core', 'education', 'education-core',
    'SIS escolar: estudiantes, calificaciones, pagos de matrícula. Conecta con zentto-education standalone.',
    59.00, 590.00, 'monthly',
    5, 5000,
    '["Matrícula y pagos", "Calificaciones", "Horarios", "Comunicados a padres", "Reportes académicos"]'::jsonb,
    '["dashboard","clientes","facturas","pagos","reportes","usuarios","education"]'::jsonb,
    '{"apiCalls":15000,"storage":10,"users":5,"students":200}'::jsonb,
    'core', FALSE, FALSE, 14,
    90, TRUE, 'draft', 0
)
ON CONFLICT ("Slug") DO UPDATE SET
    "Name"=EXCLUDED."Name","VerticalType"=EXCLUDED."VerticalType","ProductCode"=EXCLUDED."ProductCode","Description"=EXCLUDED."Description",
    "MonthlyPrice"=EXCLUDED."MonthlyPrice","AnnualPrice"=EXCLUDED."AnnualPrice","BillingCycleDefault"=EXCLUDED."BillingCycleDefault",
    "MaxUsers"=EXCLUDED."MaxUsers","MaxTransactions"=EXCLUDED."MaxTransactions",
    "Features"=EXCLUDED."Features","ModuleCodes"=EXCLUDED."ModuleCodes","Limits"=EXCLUDED."Limits",
    "Tier"=EXCLUDED."Tier","IsAddon"=EXCLUDED."IsAddon","IsTrialOnly"=EXCLUDED."IsTrialOnly","TrialDays"=EXCLUDED."TrialDays",
    "SortOrder"=EXCLUDED."SortOrder","IsActive"=EXCLUDED."IsActive","UpdatedAt"=NOW();

-- Inmobiliaria / Rental (zentto-inmobiliario + zentto-rental)
INSERT INTO cfg."PricingPlan" (
    "Name", "Slug", "VerticalType", "ProductCode", "Description",
    "MonthlyPrice", "AnnualPrice", "BillingCycleDefault",
    "MaxUsers", "MaxTransactions",
    "Features", "ModuleCodes", "Limits",
    "Tier", "IsAddon", "IsTrialOnly", "TrialDays",
    "SortOrder", "IsActive", "PaddleSyncStatus", "CompanyId"
) VALUES (
    'Real Estate Core', 'realestate-core', 'inmobiliario', 'inmobiliario-core',
    'Gestión inmobiliaria y rentas: propiedades, contratos, cobros recurrentes. Conecta con zentto-inmobiliario y zentto-rental.',
    59.00, 590.00, 'monthly',
    5, 2000,
    '["Propiedades y contratos", "Cobros recurrentes", "Clientes (CRM)", "Facturación", "Reportes de cartera"]'::jsonb,
    '["dashboard","clientes","facturas","pagos","reportes","usuarios","inmobiliario","rental"]'::jsonb,
    '{"apiCalls":15000,"storage":10,"users":5,"properties":50}'::jsonb,
    'core', FALSE, FALSE, 14,
    100, TRUE, 'draft', 0
)
ON CONFLICT ("Slug") DO UPDATE SET
    "Name"=EXCLUDED."Name","VerticalType"=EXCLUDED."VerticalType","ProductCode"=EXCLUDED."ProductCode","Description"=EXCLUDED."Description",
    "MonthlyPrice"=EXCLUDED."MonthlyPrice","AnnualPrice"=EXCLUDED."AnnualPrice","BillingCycleDefault"=EXCLUDED."BillingCycleDefault",
    "MaxUsers"=EXCLUDED."MaxUsers","MaxTransactions"=EXCLUDED."MaxTransactions",
    "Features"=EXCLUDED."Features","ModuleCodes"=EXCLUDED."ModuleCodes","Limits"=EXCLUDED."Limits",
    "Tier"=EXCLUDED."Tier","IsAddon"=EXCLUDED."IsAddon","IsTrialOnly"=EXCLUDED."IsTrialOnly","TrialDays"=EXCLUDED."TrialDays",
    "SortOrder"=EXCLUDED."SortOrder","IsActive"=EXCLUDED."IsActive","UpdatedAt"=NOW();

-- +goose Down
-- ══════════════════════════════════════════════════════════════════════════════
-- Down: elimina los 10 planes sembrados por Slug. Si algún tenant ya está
-- suscrito a alguno, el DELETE fallará por FK — limpiar suscripciones antes.
-- ══════════════════════════════════════════════════════════════════════════════

DELETE FROM cfg."PricingPlan" WHERE "Slug" IN (
    'erp-starter',
    'pos-starter',
    'resto-starter',
    'ecom-starter',
    'crm-pro',
    'cont-pro',
    'hotel-core',
    'medical-core',
    'education-core',
    'realestate-core'
);
