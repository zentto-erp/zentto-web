/*  ═══════════════════════════════════════════════════════════════
    seed_demo_ecommerce_pos.sql (PostgreSQL) — Datos demo para Ecommerce, POS y Auditoría
    Tablas: store."ProductVariant", store."ProductVariantOptionValue",
            store."ProductAttribute", pos."WaitTicket"/Line, pos."SaleTicket"/Line,
            pay."Transactions", audit."AuditLog"
    Idempotente — safe to re-run.
    ═══════════════════════════════════════════════════════════════ */

DO $$
DECLARE
  v_company_id   INT := 1;
  v_branch_id    INT := 1;
  v_country_code CHAR(2) := 'VE';
  v_now          TIMESTAMP := (NOW() AT TIME ZONE 'UTC');
  v_wt1          BIGINT;
  v_wt2          BIGINT;
  v_wt3          BIGINT;
  v_st1          BIGINT;
  v_st2          BIGINT;
  v_st3          BIGINT;
  v_st4          BIGINT;
  v_st5          BIGINT;
  v_pv_aud_neg   INT;
  v_pv_aud_bla   INT;
  v_pv_aud_azu   INT;
  v_pv_cami_s    INT;
  v_pv_cami_m    INT;
  v_pv_cami_l    INT;
  v_opt_negro    INT;
  v_opt_blanco   INT;
  v_opt_azul     INT;
  v_opt_s        INT;
  v_opt_m        INT;
  v_opt_l        INT;
BEGIN

  RAISE NOTICE '=== seed_demo_ecommerce_pos.sql — START ===';

  -- ═══════════════════════════════════════════════════════════════
  -- SECCIÓN 1: VARIANTES DE PRODUCTO
  -- ═══════════════════════════════════════════════════════════════

  -- Marcar padres como IsVariantParent = TRUE
  UPDATE master."Product" SET "IsVariantParent" = TRUE
  WHERE "CompanyId" = v_company_id AND "ProductCode" = 'ELEC-AUD-BT01' AND "IsVariantParent" = FALSE;

  UPDATE master."Product" SET "IsVariantParent" = TRUE
  WHERE "CompanyId" = v_company_id AND "ProductCode" = 'ROP-CAMI-01' AND "IsVariantParent" = FALSE;

  -- Productos hijo — Audífonos BT (3 colores)
  INSERT INTO master."Product" ("CompanyId", "ProductCode", "ProductName", "CategoryCode", "UnitCode", "SalesPrice", "CostPrice", "DefaultTaxCode", "DefaultTaxRate", "StockQty", "IsService", "IsActive", "IsDeleted", "ParentProductCode", "IsVariantParent", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, 'ELEC-AUD-BT01-NEG', 'Audífonos Bluetooth Pro - Negro', 'ELECTRO', 'UND', 89.99, 45.00, 'IVA', 16, 60, FALSE, TRUE, FALSE, 'ELEC-AUD-BT01', FALSE, v_now, v_now)
  ON CONFLICT ("CompanyId", "ProductCode") DO NOTHING;

  INSERT INTO master."Product" ("CompanyId", "ProductCode", "ProductName", "CategoryCode", "UnitCode", "SalesPrice", "CostPrice", "DefaultTaxCode", "DefaultTaxRate", "StockQty", "IsService", "IsActive", "IsDeleted", "ParentProductCode", "IsVariantParent", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, 'ELEC-AUD-BT01-BLA', 'Audífonos Bluetooth Pro - Blanco', 'ELECTRO', 'UND', 89.99, 45.00, 'IVA', 16, 50, FALSE, TRUE, FALSE, 'ELEC-AUD-BT01', FALSE, v_now, v_now)
  ON CONFLICT ("CompanyId", "ProductCode") DO NOTHING;

  INSERT INTO master."Product" ("CompanyId", "ProductCode", "ProductName", "CategoryCode", "UnitCode", "SalesPrice", "CostPrice", "DefaultTaxCode", "DefaultTaxRate", "StockQty", "IsService", "IsActive", "IsDeleted", "ParentProductCode", "IsVariantParent", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, 'ELEC-AUD-BT01-AZU', 'Audífonos Bluetooth Pro - Azul', 'ELECTRO', 'UND', 94.99, 45.00, 'IVA', 16, 40, FALSE, TRUE, FALSE, 'ELEC-AUD-BT01', FALSE, v_now, v_now)
  ON CONFLICT ("CompanyId", "ProductCode") DO NOTHING;

  -- Productos hijo — Camiseta (3 tallas)
  INSERT INTO master."Product" ("CompanyId", "ProductCode", "ProductName", "CategoryCode", "UnitCode", "SalesPrice", "CostPrice", "DefaultTaxCode", "DefaultTaxRate", "StockQty", "IsService", "IsActive", "IsDeleted", "ParentProductCode", "IsVariantParent", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, 'ROP-CAMI-01-S', 'Camiseta Deportiva Dry-Fit - S', 'ROPA', 'UND', 18.99, 7.00, 'IVA', 16, 120, FALSE, TRUE, FALSE, 'ROP-CAMI-01', FALSE, v_now, v_now)
  ON CONFLICT ("CompanyId", "ProductCode") DO NOTHING;

  INSERT INTO master."Product" ("CompanyId", "ProductCode", "ProductName", "CategoryCode", "UnitCode", "SalesPrice", "CostPrice", "DefaultTaxCode", "DefaultTaxRate", "StockQty", "IsService", "IsActive", "IsDeleted", "ParentProductCode", "IsVariantParent", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, 'ROP-CAMI-01-M', 'Camiseta Deportiva Dry-Fit - M', 'ROPA', 'UND', 18.99, 7.00, 'IVA', 16, 150, FALSE, TRUE, FALSE, 'ROP-CAMI-01', FALSE, v_now, v_now)
  ON CONFLICT ("CompanyId", "ProductCode") DO NOTHING;

  INSERT INTO master."Product" ("CompanyId", "ProductCode", "ProductName", "CategoryCode", "UnitCode", "SalesPrice", "CostPrice", "DefaultTaxCode", "DefaultTaxRate", "StockQty", "IsService", "IsActive", "IsDeleted", "ParentProductCode", "IsVariantParent", "CreatedAt", "UpdatedAt")
  VALUES (v_company_id, 'ROP-CAMI-01-L', 'Camiseta Deportiva Dry-Fit - L', 'ROPA', 'UND', 20.99, 7.00, 'IVA', 16, 130, FALSE, TRUE, FALSE, 'ROP-CAMI-01', FALSE, v_now, v_now)
  ON CONFLICT ("CompanyId", "ProductCode") DO NOTHING;

  RAISE NOTICE 'Seeded 6 variant child products in master."Product"';

  -- store."ProductVariant"
  INSERT INTO store."ProductVariant" ("CompanyId", "ParentProductCode", "VariantProductCode", "SKU", "PriceDelta", "StockOverride", "IsDefault", "SortOrder", "IsActive", "IsDeleted")
  VALUES (v_company_id, 'ELEC-AUD-BT01', 'ELEC-AUD-BT01-NEG', 'AUD-BT01-NEG', 0, NULL, TRUE, 1, TRUE, FALSE)
  ON CONFLICT ("CompanyId", "ParentProductCode", "VariantProductCode") DO NOTHING;

  INSERT INTO store."ProductVariant" ("CompanyId", "ParentProductCode", "VariantProductCode", "SKU", "PriceDelta", "StockOverride", "IsDefault", "SortOrder", "IsActive", "IsDeleted")
  VALUES (v_company_id, 'ELEC-AUD-BT01', 'ELEC-AUD-BT01-BLA', 'AUD-BT01-BLA', 0, NULL, FALSE, 2, TRUE, FALSE)
  ON CONFLICT ("CompanyId", "ParentProductCode", "VariantProductCode") DO NOTHING;

  INSERT INTO store."ProductVariant" ("CompanyId", "ParentProductCode", "VariantProductCode", "SKU", "PriceDelta", "StockOverride", "IsDefault", "SortOrder", "IsActive", "IsDeleted")
  VALUES (v_company_id, 'ELEC-AUD-BT01', 'ELEC-AUD-BT01-AZU', 'AUD-BT01-AZU', 5.00, NULL, FALSE, 3, TRUE, FALSE)
  ON CONFLICT ("CompanyId", "ParentProductCode", "VariantProductCode") DO NOTHING;

  INSERT INTO store."ProductVariant" ("CompanyId", "ParentProductCode", "VariantProductCode", "SKU", "PriceDelta", "StockOverride", "IsDefault", "SortOrder", "IsActive", "IsDeleted")
  VALUES (v_company_id, 'ROP-CAMI-01', 'ROP-CAMI-01-S', 'CAMI-01-S', 0, NULL, FALSE, 1, TRUE, FALSE)
  ON CONFLICT ("CompanyId", "ParentProductCode", "VariantProductCode") DO NOTHING;

  INSERT INTO store."ProductVariant" ("CompanyId", "ParentProductCode", "VariantProductCode", "SKU", "PriceDelta", "StockOverride", "IsDefault", "SortOrder", "IsActive", "IsDeleted")
  VALUES (v_company_id, 'ROP-CAMI-01', 'ROP-CAMI-01-M', 'CAMI-01-M', 0, NULL, TRUE, 2, TRUE, FALSE)
  ON CONFLICT ("CompanyId", "ParentProductCode", "VariantProductCode") DO NOTHING;

  INSERT INTO store."ProductVariant" ("CompanyId", "ParentProductCode", "VariantProductCode", "SKU", "PriceDelta", "StockOverride", "IsDefault", "SortOrder", "IsActive", "IsDeleted")
  VALUES (v_company_id, 'ROP-CAMI-01', 'ROP-CAMI-01-L', 'CAMI-01-L', 2.00, NULL, FALSE, 3, TRUE, FALSE)
  ON CONFLICT ("CompanyId", "ParentProductCode", "VariantProductCode") DO NOTHING;

  RAISE NOTICE 'Seeded 6 rows in store."ProductVariant"';

  -- ═══════════════════════════════════════════════════════════════
  -- SECCIÓN 2: store."ProductVariantOptionValue"
  -- ═══════════════════════════════════════════════════════════════

  SELECT pv."ProductVariantId" INTO v_pv_aud_neg FROM store."ProductVariant" pv WHERE pv."CompanyId" = v_company_id AND pv."VariantProductCode" = 'ELEC-AUD-BT01-NEG';
  SELECT pv."ProductVariantId" INTO v_pv_aud_bla FROM store."ProductVariant" pv WHERE pv."CompanyId" = v_company_id AND pv."VariantProductCode" = 'ELEC-AUD-BT01-BLA';
  SELECT pv."ProductVariantId" INTO v_pv_aud_azu FROM store."ProductVariant" pv WHERE pv."CompanyId" = v_company_id AND pv."VariantProductCode" = 'ELEC-AUD-BT01-AZU';
  SELECT pv."ProductVariantId" INTO v_pv_cami_s FROM store."ProductVariant" pv WHERE pv."CompanyId" = v_company_id AND pv."VariantProductCode" = 'ROP-CAMI-01-S';
  SELECT pv."ProductVariantId" INTO v_pv_cami_m FROM store."ProductVariant" pv WHERE pv."CompanyId" = v_company_id AND pv."VariantProductCode" = 'ROP-CAMI-01-M';
  SELECT pv."ProductVariantId" INTO v_pv_cami_l FROM store."ProductVariant" pv WHERE pv."CompanyId" = v_company_id AND pv."VariantProductCode" = 'ROP-CAMI-01-L';

  SELECT vo."VariantOptionId" INTO v_opt_negro  FROM store."ProductVariantOption" vo INNER JOIN store."ProductVariantGroup" vg ON vo."VariantGroupId" = vg."VariantGroupId" WHERE vg."CompanyId" = v_company_id AND vg."GroupCode" = 'COLOR' AND vo."OptionCode" = 'NEGRO';
  SELECT vo."VariantOptionId" INTO v_opt_blanco FROM store."ProductVariantOption" vo INNER JOIN store."ProductVariantGroup" vg ON vo."VariantGroupId" = vg."VariantGroupId" WHERE vg."CompanyId" = v_company_id AND vg."GroupCode" = 'COLOR' AND vo."OptionCode" = 'BLANCO';
  SELECT vo."VariantOptionId" INTO v_opt_azul   FROM store."ProductVariantOption" vo INNER JOIN store."ProductVariantGroup" vg ON vo."VariantGroupId" = vg."VariantGroupId" WHERE vg."CompanyId" = v_company_id AND vg."GroupCode" = 'COLOR' AND vo."OptionCode" = 'AZUL';
  SELECT vo."VariantOptionId" INTO v_opt_s      FROM store."ProductVariantOption" vo INNER JOIN store."ProductVariantGroup" vg ON vo."VariantGroupId" = vg."VariantGroupId" WHERE vg."CompanyId" = v_company_id AND vg."GroupCode" = 'TALLA' AND vo."OptionCode" = 'S';
  SELECT vo."VariantOptionId" INTO v_opt_m      FROM store."ProductVariantOption" vo INNER JOIN store."ProductVariantGroup" vg ON vo."VariantGroupId" = vg."VariantGroupId" WHERE vg."CompanyId" = v_company_id AND vg."GroupCode" = 'TALLA' AND vo."OptionCode" = 'M';
  SELECT vo."VariantOptionId" INTO v_opt_l      FROM store."ProductVariantOption" vo INNER JOIN store."ProductVariantGroup" vg ON vo."VariantGroupId" = vg."VariantGroupId" WHERE vg."CompanyId" = v_company_id AND vg."GroupCode" = 'TALLA' AND vo."OptionCode" = 'L';

  IF v_pv_aud_neg IS NOT NULL AND v_opt_negro IS NOT NULL THEN
    INSERT INTO store."ProductVariantOptionValue" ("ProductVariantId", "VariantOptionId") VALUES (v_pv_aud_neg, v_opt_negro) ON CONFLICT ("ProductVariantId", "VariantOptionId") DO NOTHING;
  END IF;
  IF v_pv_aud_bla IS NOT NULL AND v_opt_blanco IS NOT NULL THEN
    INSERT INTO store."ProductVariantOptionValue" ("ProductVariantId", "VariantOptionId") VALUES (v_pv_aud_bla, v_opt_blanco) ON CONFLICT ("ProductVariantId", "VariantOptionId") DO NOTHING;
  END IF;
  IF v_pv_aud_azu IS NOT NULL AND v_opt_azul IS NOT NULL THEN
    INSERT INTO store."ProductVariantOptionValue" ("ProductVariantId", "VariantOptionId") VALUES (v_pv_aud_azu, v_opt_azul) ON CONFLICT ("ProductVariantId", "VariantOptionId") DO NOTHING;
  END IF;
  IF v_pv_cami_s IS NOT NULL AND v_opt_s IS NOT NULL THEN
    INSERT INTO store."ProductVariantOptionValue" ("ProductVariantId", "VariantOptionId") VALUES (v_pv_cami_s, v_opt_s) ON CONFLICT ("ProductVariantId", "VariantOptionId") DO NOTHING;
  END IF;
  IF v_pv_cami_m IS NOT NULL AND v_opt_m IS NOT NULL THEN
    INSERT INTO store."ProductVariantOptionValue" ("ProductVariantId", "VariantOptionId") VALUES (v_pv_cami_m, v_opt_m) ON CONFLICT ("ProductVariantId", "VariantOptionId") DO NOTHING;
  END IF;
  IF v_pv_cami_l IS NOT NULL AND v_opt_l IS NOT NULL THEN
    INSERT INTO store."ProductVariantOptionValue" ("ProductVariantId", "VariantOptionId") VALUES (v_pv_cami_l, v_opt_l) ON CONFLICT ("ProductVariantId", "VariantOptionId") DO NOTHING;
  END IF;

  RAISE NOTICE 'Seeded 6 rows in store."ProductVariantOptionValue"';

  -- ═══════════════════════════════════════════════════════════════
  -- SECCIÓN 3: store."ProductAttribute"
  -- ═══════════════════════════════════════════════════════════════

  UPDATE master."Product" SET "IndustryTemplateCode" = 'FARMACIA'
  WHERE "CompanyId" = v_company_id AND "ProductCode" = 'SAL-VIT-01' AND (COALESCE("IndustryTemplateCode",'') <> 'FARMACIA');

  UPDATE master."Product" SET "IndustryTemplateCode" = 'ALIMENTOS'
  WHERE "CompanyId" = v_company_id AND "ProductCode" = 'MNU-HAMB-CLA' AND (COALESCE("IndustryTemplateCode",'') <> 'ALIMENTOS');

  INSERT INTO store."ProductAttribute" ("CompanyId", "ProductCode", "TemplateCode", "AttributeKey", "ValueText") VALUES (v_company_id, 'SAL-VIT-01', 'FARMACIA', 'PrincipioActivo', 'Complejo multivitamínico (A, B1, B6, B12, C, D3, E, K)') ON CONFLICT ("CompanyId", "ProductCode", "AttributeKey") DO NOTHING;
  INSERT INTO store."ProductAttribute" ("CompanyId", "ProductCode", "TemplateCode", "AttributeKey", "ValueText") VALUES (v_company_id, 'SAL-VIT-01', 'FARMACIA', 'Concentracion', '500mg por cápsula') ON CONFLICT ("CompanyId", "ProductCode", "AttributeKey") DO NOTHING;
  INSERT INTO store."ProductAttribute" ("CompanyId", "ProductCode", "TemplateCode", "AttributeKey", "ValueText") VALUES (v_company_id, 'SAL-VIT-01', 'FARMACIA', 'FormaFarmaceutica', 'Cápsula') ON CONFLICT ("CompanyId", "ProductCode", "AttributeKey") DO NOTHING;
  INSERT INTO store."ProductAttribute" ("CompanyId", "ProductCode", "TemplateCode", "AttributeKey", "ValueText") VALUES (v_company_id, 'SAL-VIT-01', 'FARMACIA', 'RegistroSanitario', 'INVIMA-2026-RS-0045821') ON CONFLICT ("CompanyId", "ProductCode", "AttributeKey") DO NOTHING;
  INSERT INTO store."ProductAttribute" ("CompanyId", "ProductCode", "TemplateCode", "AttributeKey", "ValueBoolean") VALUES (v_company_id, 'SAL-VIT-01', 'FARMACIA', 'RequiereReceta', FALSE) ON CONFLICT ("CompanyId", "ProductCode", "AttributeKey") DO NOTHING;
  INSERT INTO store."ProductAttribute" ("CompanyId", "ProductCode", "TemplateCode", "AttributeKey", "ValueText") VALUES (v_company_id, 'SAL-VIT-01', 'FARMACIA', 'Laboratorio', 'Laboratorios Farma Plus C.A.') ON CONFLICT ("CompanyId", "ProductCode", "AttributeKey") DO NOTHING;

  INSERT INTO store."ProductAttribute" ("CompanyId", "ProductCode", "TemplateCode", "AttributeKey", "ValueDate") VALUES (v_company_id, 'MNU-HAMB-CLA', 'ALIMENTOS', 'FechaVencimiento', '2026-06-30') ON CONFLICT ("CompanyId", "ProductCode", "AttributeKey") DO NOTHING;
  INSERT INTO store."ProductAttribute" ("CompanyId", "ProductCode", "TemplateCode", "AttributeKey", "ValueText") VALUES (v_company_id, 'MNU-HAMB-CLA', 'ALIMENTOS', 'Lote', 'LOTE-2026-03-001') ON CONFLICT ("CompanyId", "ProductCode", "AttributeKey") DO NOTHING;
  INSERT INTO store."ProductAttribute" ("CompanyId", "ProductCode", "TemplateCode", "AttributeKey", "ValueNumber") VALUES (v_company_id, 'MNU-HAMB-CLA', 'ALIMENTOS', 'PesoNeto', 250.0000) ON CONFLICT ("CompanyId", "ProductCode", "AttributeKey") DO NOTHING;
  INSERT INTO store."ProductAttribute" ("CompanyId", "ProductCode", "TemplateCode", "AttributeKey", "ValueText") VALUES (v_company_id, 'MNU-HAMB-CLA', 'ALIMENTOS', 'Ingredientes', 'Carne de res 150g, pan artesanal, queso cheddar, lechuga, tomate, cebolla, salsa especial') ON CONFLICT ("CompanyId", "ProductCode", "AttributeKey") DO NOTHING;

  RAISE NOTICE 'Seeded 10 rows in store."ProductAttribute" (6 FARMACIA + 4 ALIMENTOS)';

  -- ═══════════════════════════════════════════════════════════════
  -- SECCIÓN 4: pos."WaitTicket" + pos."WaitTicketLine"
  -- ═══════════════════════════════════════════════════════════════

  IF NOT EXISTS (SELECT 1 FROM pos."WaitTicket" WHERE "CompanyId" = v_company_id AND "BranchId" = v_branch_id AND "CashRegisterCode" = 'CAJA-01' AND "CustomerName" = 'María García' AND "Status" = 'WAITING') THEN
    INSERT INTO pos."WaitTicket" ("CompanyId", "BranchId", "CountryCode", "CashRegisterCode", "StationName", "CreatedByUserId", "CustomerName", "CustomerFiscalId", "PriceTier", "Reason", "NetAmount", "DiscountAmount", "TaxAmount", "TotalAmount", "Status", "CreatedAt", "UpdatedAt")
    VALUES (v_company_id, v_branch_id, v_country_code, 'CAJA-01', 'Estación Principal', 1, 'María García', 'V-18456789', 'DETAIL', 'Cliente fue a buscar forma de pago', 134.97, 0, 21.60, 156.57, 'WAITING', v_now - INTERVAL '45 minutes', v_now - INTERVAL '45 minutes')
    RETURNING "WaitTicketId" INTO v_wt1;
    BEGIN
      INSERT INTO pos."WaitTicketLine" ("WaitTicketId", "LineNumber", "CountryCode", "ProductCode", "ProductName", "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate", "NetAmount", "TaxAmount", "TotalAmount")
      VALUES
        (v_wt1, 1, v_country_code, 'ELEC-AUD-BT01', 'Audífonos Bluetooth Pro', 1, 89.99, 0, 'IVA', 16.0000, 89.99, 14.40, 104.39),
        (v_wt1, 2, v_country_code, 'ELEC-CHRG-01', 'Cargador Inalámbrico Rápido 15W', 1, 29.99, 0, 'IVA', 16.0000, 29.99, 4.80, 34.79),
        (v_wt1, 3, v_country_code, 'DEP-BOT-01', 'Botella Térmica Deportiva 1L', 1, 14.99, 0, 'IVA', 16.0000, 14.99, 2.40, 17.39);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_demo_ecommerce_pos: WaitTicketLine skip (FK_pos_WaitTicketLine_Tax — código fiscal no encontrado)';
    END;
    RAISE NOTICE 'Seeded WaitTicket 1 with 3 lines';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pos."WaitTicket" WHERE "CompanyId" = v_company_id AND "BranchId" = v_branch_id AND "CashRegisterCode" = 'CAJA-02' AND "CustomerName" = 'José Rodríguez' AND "Status" = 'WAITING') THEN
    INSERT INTO pos."WaitTicket" ("CompanyId", "BranchId", "CountryCode", "CashRegisterCode", "StationName", "CreatedByUserId", "CustomerName", "CustomerFiscalId", "PriceTier", "Reason", "NetAmount", "DiscountAmount", "TaxAmount", "TotalAmount", "Status", "CreatedAt", "UpdatedAt")
    VALUES (v_company_id, v_branch_id, v_country_code, 'CAJA-02', 'Estación 2', 1, 'José Rodríguez', 'V-20123456', 'DETAIL', 'Esperando autorización de TDC', 74.99, 0, 12.00, 86.99, 'WAITING', v_now - INTERVAL '20 minutes', v_now - INTERVAL '20 minutes')
    RETURNING "WaitTicketId" INTO v_wt2;
    BEGIN
      INSERT INTO pos."WaitTicketLine" ("WaitTicketId", "LineNumber", "CountryCode", "ProductCode", "ProductName", "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate", "NetAmount", "TaxAmount", "TotalAmount")
      VALUES (v_wt2, 1, v_country_code, 'ROP-ZAP-01', 'Zapatillas Running Ultralight', 1, 74.99, 0, 'IVA', 16.0000, 74.99, 12.00, 86.99);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_demo_ecommerce_pos: WaitTicketLine skip (FK_pos_WaitTicketLine_Tax — código fiscal no encontrado)';
    END;
    RAISE NOTICE 'Seeded WaitTicket 2 with 1 line';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pos."WaitTicket" WHERE "CompanyId" = v_company_id AND "BranchId" = v_branch_id AND "CashRegisterCode" = 'CAJA-01' AND "CustomerName" = 'Ana Martínez' AND "Status" = 'WAITING') THEN
    INSERT INTO pos."WaitTicket" ("CompanyId", "BranchId", "CountryCode", "CashRegisterCode", "StationName", "CreatedByUserId", "CustomerName", "CustomerFiscalId", "PriceTier", "Reason", "NetAmount", "DiscountAmount", "TaxAmount", "TotalAmount", "Status", "CreatedAt", "UpdatedAt")
    VALUES (v_company_id, v_branch_id, v_country_code, 'CAJA-01', 'Estación Principal', 1, 'Ana Martínez', 'V-15789012', 'DETAIL', 'Consultando disponibilidad de otro color', 64.98, 0, 10.40, 75.38, 'WAITING', v_now - INTERVAL '10 minutes', v_now - INTERVAL '10 minutes')
    RETURNING "WaitTicketId" INTO v_wt3;
    BEGIN
      INSERT INTO pos."WaitTicketLine" ("WaitTicketId", "LineNumber", "CountryCode", "ProductCode", "ProductName", "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate", "NetAmount", "TaxAmount", "TotalAmount")
      VALUES
        (v_wt3, 1, v_country_code, 'HOG-LAMP-01', 'Lámpara LED de Escritorio Regulable', 1, 34.99, 0, 'IVA', 16.0000, 34.99, 5.60, 40.59),
        (v_wt3, 2, v_country_code, 'ELEC-CHRG-01', 'Cargador Inalámbrico Rápido 15W', 1, 29.99, 0, 'IVA', 16.0000, 29.99, 4.80, 34.79);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_demo_ecommerce_pos: WaitTicketLine skip (FK_pos_WaitTicketLine_Tax — código fiscal no encontrado)';
    END;
    RAISE NOTICE 'Seeded WaitTicket 3 with 2 lines';
  END IF;

  -- ═══════════════════════════════════════════════════════════════
  -- SECCIÓN 5: pos."SaleTicket" + pos."SaleTicketLine"
  -- ═══════════════════════════════════════════════════════════════

  IF NOT EXISTS (SELECT 1 FROM pos."SaleTicket" WHERE "CompanyId" = v_company_id AND "BranchId" = v_branch_id AND "InvoiceNumber" = 'POS-000001') THEN
    INSERT INTO pos."SaleTicket" ("CompanyId", "BranchId", "CountryCode", "InvoiceNumber", "CashRegisterCode", "SoldByUserId", "CustomerName", "CustomerFiscalId", "PriceTier", "PaymentMethod", "NetAmount", "DiscountAmount", "TaxAmount", "TotalAmount", "SoldAt")
    VALUES (v_company_id, v_branch_id, v_country_code, 'POS-000001', 'CAJA-01', 1, 'Pedro López', 'V-12345678', 'DETAIL', 'EFECTIVO', 89.99, 0, 14.40, 104.39, v_now - INTERVAL '6 hours')
    RETURNING "SaleTicketId" INTO v_st1;
    BEGIN
      INSERT INTO pos."SaleTicketLine" ("SaleTicketId", "LineNumber", "CountryCode", "ProductCode", "ProductName", "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate", "NetAmount", "TaxAmount", "TotalAmount")
      VALUES (v_st1, 1, v_country_code, 'ELEC-AUD-BT01-NEG', 'Audífonos Bluetooth Pro - Negro', 1, 89.99, 0, 'IVA', 16.0000, 89.99, 14.40, 104.39);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_demo_ecommerce_pos: SaleTicketLine skip (FK_pos_SaleTicketLine_Tax — código fiscal no encontrado)';
    END;
    RAISE NOTICE 'Seeded SaleTicket POS-000001';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pos."SaleTicket" WHERE "CompanyId" = v_company_id AND "BranchId" = v_branch_id AND "InvoiceNumber" = 'POS-000002') THEN
    INSERT INTO pos."SaleTicket" ("CompanyId", "BranchId", "CountryCode", "InvoiceNumber", "CashRegisterCode", "SoldByUserId", "CustomerName", "CustomerFiscalId", "PriceTier", "PaymentMethod", "NetAmount", "DiscountAmount", "TaxAmount", "TotalAmount", "SoldAt")
    VALUES (v_company_id, v_branch_id, v_country_code, 'POS-000002', 'CAJA-01', 1, 'Laura Hernández', 'V-22334455', 'DETAIL', 'TDC', 159.97, 0, 25.60, 185.57, v_now - INTERVAL '5 hours')
    RETURNING "SaleTicketId" INTO v_st2;
    BEGIN
      INSERT INTO pos."SaleTicketLine" ("SaleTicketId", "LineNumber", "CountryCode", "ProductCode", "ProductName", "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate", "NetAmount", "TaxAmount", "TotalAmount")
      VALUES
        (v_st2, 1, v_country_code, 'ELEC-WATCH-01', 'Smartwatch Fitness Tracker', 1, 129.99, 0, 'IVA', 16.0000, 129.99, 20.80, 150.79),
        (v_st2, 2, v_country_code, 'ELEC-CHRG-01', 'Cargador Inalámbrico Rápido 15W', 1, 29.99, 0, 'IVA', 16.0000, 29.99, 4.80, 34.79);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_demo_ecommerce_pos: SaleTicketLine skip (FK_pos_SaleTicketLine_Tax — código fiscal no encontrado)';
    END;
    RAISE NOTICE 'Seeded SaleTicket POS-000002';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pos."SaleTicket" WHERE "CompanyId" = v_company_id AND "BranchId" = v_branch_id AND "InvoiceNumber" = 'POS-000003') THEN
    INSERT INTO pos."SaleTicket" ("CompanyId", "BranchId", "CountryCode", "InvoiceNumber", "CashRegisterCode", "SoldByUserId", "CustomerName", "CustomerFiscalId", "PriceTier", "PaymentMethod", "NetAmount", "DiscountAmount", "TaxAmount", "TotalAmount", "SoldAt")
    VALUES (v_company_id, v_branch_id, v_country_code, 'POS-000003', 'CAJA-02', 1, 'Carlos Mendoza', 'V-19876543', 'DETAIL', 'TRANSFERENCIA', 37.98, 0, 6.08, 44.06, v_now - INTERVAL '4 hours')
    RETURNING "SaleTicketId" INTO v_st3;
    BEGIN
      INSERT INTO pos."SaleTicketLine" ("SaleTicketId", "LineNumber", "CountryCode", "ProductCode", "ProductName", "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate", "NetAmount", "TaxAmount", "TotalAmount")
      VALUES (v_st3, 1, v_country_code, 'ROP-CAMI-01-M', 'Camiseta Deportiva Dry-Fit - M', 2, 18.99, 0, 'IVA', 16.0000, 37.98, 6.08, 44.06);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_demo_ecommerce_pos: SaleTicketLine skip (FK_pos_SaleTicketLine_Tax — código fiscal no encontrado)';
    END;
    RAISE NOTICE 'Seeded SaleTicket POS-000003';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pos."SaleTicket" WHERE "CompanyId" = v_company_id AND "BranchId" = v_branch_id AND "InvoiceNumber" = 'POS-000004') THEN
    INSERT INTO pos."SaleTicket" ("CompanyId", "BranchId", "CountryCode", "InvoiceNumber", "CashRegisterCode", "SoldByUserId", "CustomerName", "CustomerFiscalId", "PriceTier", "PaymentMethod", "NetAmount", "DiscountAmount", "TaxAmount", "TotalAmount", "SoldAt")
    VALUES (v_company_id, v_branch_id, v_country_code, 'POS-000004', 'CAJA-01', 1, 'Sofía Ramírez', 'V-25678901', 'DETAIL', 'PAGO_MOVIL', 62.97, 0, 10.08, 73.05, v_now - INTERVAL '3 hours')
    RETURNING "SaleTicketId" INTO v_st4;
    BEGIN
      INSERT INTO pos."SaleTicketLine" ("SaleTicketId", "LineNumber", "CountryCode", "ProductCode", "ProductName", "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate", "NetAmount", "TaxAmount", "TotalAmount")
      VALUES
        (v_st4, 1, v_country_code, 'SAL-PROT-01', 'Proteína Whey 2lb Sabor Chocolate', 1, 42.99, 0, 'IVA', 16.0000, 42.99, 6.88, 49.87),
        (v_st4, 2, v_country_code, 'DEP-BOT-01', 'Botella Térmica Deportiva 1L', 1, 19.99, 0, 'IVA', 16.0000, 19.99, 3.20, 23.19);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_demo_ecommerce_pos: SaleTicketLine skip (FK_pos_SaleTicketLine_Tax — código fiscal no encontrado)';
    END;
    RAISE NOTICE 'Seeded SaleTicket POS-000004';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pos."SaleTicket" WHERE "CompanyId" = v_company_id AND "BranchId" = v_branch_id AND "InvoiceNumber" = 'POS-000005') THEN
    INSERT INTO pos."SaleTicket" ("CompanyId", "BranchId", "CountryCode", "InvoiceNumber", "CashRegisterCode", "SoldByUserId", "CustomerName", "CustomerFiscalId", "PriceTier", "PaymentMethod", "NetAmount", "DiscountAmount", "TaxAmount", "TotalAmount", "SoldAt")
    VALUES (v_company_id, v_branch_id, v_country_code, 'POS-000005', 'CAJA-02', 1, 'Diego Torres', 'V-14567890', 'DETAIL', 'EFECTIVO', 117.97, 0, 18.88, 136.85, v_now - INTERVAL '1 hour')
    RETURNING "SaleTicketId" INTO v_st5;
    BEGIN
      INSERT INTO pos."SaleTicketLine" ("SaleTicketId", "LineNumber", "CountryCode", "ProductCode", "ProductName", "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate", "NetAmount", "TaxAmount", "TotalAmount")
      VALUES
        (v_st5, 1, v_country_code, 'HOG-CAFE-01', 'Cafetera Programable 12 Tazas', 1, 59.99, 0, 'IVA', 16.0000, 59.99, 9.60, 69.59),
        (v_st5, 2, v_country_code, 'HOG-LAMP-01', 'Lámpara LED de Escritorio Regulable', 1, 34.99, 0, 'IVA', 16.0000, 34.99, 5.60, 40.59),
        (v_st5, 3, v_country_code, 'DEP-YOGA-01', 'Mat de Yoga Antideslizante 6mm', 1, 22.99, 0, 'IVA', 16.0000, 22.99, 3.68, 26.67);
    EXCEPTION WHEN foreign_key_violation THEN
      RAISE NOTICE 'seed_demo_ecommerce_pos: SaleTicketLine skip (FK_pos_SaleTicketLine_Tax — código fiscal no encontrado)';
    END;
    RAISE NOTICE 'Seeded SaleTicket POS-000005';
  END IF;

  -- ═══════════════════════════════════════════════════════════════
  -- SECCIÓN 6: pay."Transactions"
  -- ═══════════════════════════════════════════════════════════════

  INSERT INTO pay."Transactions" ("TransactionUUID", "EmpresaId", "SucursalId", "SourceType", "SourceNumber", "PaymentMethodCode", "Currency", "Amount", "CommissionAmount", "NetAmount", "TrxType", "Status", "StationId", "CashierId", "IpAddress", "CreatedAt", "UpdatedAt")
  VALUES ('seed-trx-pos-001', v_company_id, 0, 'TICKET_POS', 'POS-000001', 'EFECTIVO', 'VES', 104.39, 0, 104.39, 'SALE', 'APPROVED', 'CAJA-01', '1', '192.168.1.10', v_now - INTERVAL '6 hours', v_now - INTERVAL '6 hours')
  ON CONFLICT ("TransactionUUID") DO NOTHING;

  INSERT INTO pay."Transactions" ("TransactionUUID", "EmpresaId", "SucursalId", "SourceType", "SourceNumber", "PaymentMethodCode", "Currency", "Amount", "CommissionAmount", "NetAmount", "TrxType", "Status", "GatewayTrxId", "GatewayAuthCode", "CardLastFour", "CardBrand", "StationId", "CashierId", "IpAddress", "CreatedAt", "UpdatedAt")
  VALUES ('seed-trx-pos-002', v_company_id, 0, 'TICKET_POS', 'POS-000002', 'TDC', 'VES', 185.57, 3.71, 181.86, 'SALE', 'APPROVED', 'GW-20260316-002', 'AUTH-5589', '4532', 'VISA', 'CAJA-01', '1', '192.168.1.10', v_now - INTERVAL '5 hours', v_now - INTERVAL '5 hours')
  ON CONFLICT ("TransactionUUID") DO NOTHING;

  INSERT INTO pay."Transactions" ("TransactionUUID", "EmpresaId", "SucursalId", "SourceType", "SourceNumber", "PaymentMethodCode", "Currency", "Amount", "CommissionAmount", "NetAmount", "TrxType", "Status", "PaymentRef", "BankCode", "StationId", "CashierId", "IpAddress", "CreatedAt", "UpdatedAt")
  VALUES ('seed-trx-pos-003', v_company_id, 0, 'TICKET_POS', 'POS-000003', 'TRANSFER', 'VES', 44.06, 0, 44.06, 'SALE', 'APPROVED', 'REF-20260316-44060', '0102', 'CAJA-02', '1', '192.168.1.11', v_now - INTERVAL '4 hours', v_now - INTERVAL '4 hours')
  ON CONFLICT ("TransactionUUID") DO NOTHING;

  INSERT INTO pay."Transactions" ("TransactionUUID", "EmpresaId", "SucursalId", "SourceType", "SourceNumber", "PaymentMethodCode", "Currency", "Amount", "CommissionAmount", "NetAmount", "TrxType", "Status", "PaymentRef", "MobileNumber", "BankCode", "StationId", "CashierId", "IpAddress", "CreatedAt", "UpdatedAt")
  VALUES ('seed-trx-pos-004', v_company_id, 0, 'TICKET_POS', 'POS-000004', 'C2P', 'VES', 73.05, 0, 73.05, 'SALE', 'APPROVED', 'C2P-20260316-73050', '0412***4567', '0134', 'CAJA-01', '1', '192.168.1.10', v_now - INTERVAL '3 hours', v_now - INTERVAL '3 hours')
  ON CONFLICT ("TransactionUUID") DO NOTHING;

  INSERT INTO pay."Transactions" ("TransactionUUID", "EmpresaId", "SucursalId", "SourceType", "SourceNumber", "PaymentMethodCode", "Currency", "Amount", "CommissionAmount", "NetAmount", "TrxType", "Status", "StationId", "CashierId", "IpAddress", "CreatedAt", "UpdatedAt")
  VALUES ('seed-trx-pos-005', v_company_id, 0, 'TICKET_POS', 'POS-000005', 'EFECTIVO', 'VES', 136.85, 0, 136.85, 'SALE', 'APPROVED', 'CAJA-02', '1', '192.168.1.11', v_now - INTERVAL '1 hour', v_now - INTERVAL '1 hour')
  ON CONFLICT ("TransactionUUID") DO NOTHING;

  INSERT INTO pay."Transactions" ("TransactionUUID", "EmpresaId", "SucursalId", "SourceType", "SourceNumber", "PaymentMethodCode", "Currency", "Amount", "CommissionAmount", "NetAmount", "TrxType", "Status", "CardLastFour", "CardBrand", "StationId", "CashierId", "IpAddress", "Notes", "CreatedAt", "UpdatedAt")
  VALUES ('seed-trx-pos-006', v_company_id, 0, 'TICKET_POS', 'POS-PENDING-01', 'TDC', 'VES', 250.00, 5.00, 245.00, 'SALE', 'PENDING', '8901', 'MASTERCARD', 'CAJA-01', '1', '192.168.1.10', 'Esperando respuesta del procesador', v_now, v_now)
  ON CONFLICT ("TransactionUUID") DO NOTHING;

  INSERT INTO pay."Transactions" ("TransactionUUID", "EmpresaId", "SucursalId", "SourceType", "SourceNumber", "PaymentMethodCode", "Currency", "Amount", "CommissionAmount", "NetAmount", "ExchangeRate", "AmountInBase", "TrxType", "Status", "StationId", "CashierId", "IpAddress", "CreatedAt", "UpdatedAt")
  VALUES ('seed-trx-pos-007', v_company_id, 0, 'TICKET_POS', 'POS-000001', 'EFECTIVO', 'USD', 2.85, 0, 2.85, 36.60, 104.31, 'SALE', 'APPROVED', 'CAJA-01', '1', '192.168.1.10', v_now - INTERVAL '6 hours', v_now - INTERVAL '6 hours')
  ON CONFLICT ("TransactionUUID") DO NOTHING;

  INSERT INTO pay."Transactions" ("TransactionUUID", "EmpresaId", "SucursalId", "SourceType", "SourceNumber", "PaymentMethodCode", "Currency", "Amount", "CommissionAmount", "NetAmount", "TrxType", "Status", "PaymentRef", "BankCode", "GatewayMessage", "StationId", "CashierId", "IpAddress", "Notes", "CreatedAt", "UpdatedAt")
  VALUES ('seed-trx-pos-008', v_company_id, 0, 'TICKET_POS', 'POS-DECLINED-01', 'TRANSFER', 'VES', 500.00, 0, 500.00, 'SALE', 'DECLINED', 'REF-FAIL-001', '0105', 'Fondos insuficientes', 'CAJA-02', '1', '192.168.1.11', 'Cliente intentó con otra cuenta', v_now - INTERVAL '2 hours', v_now - INTERVAL '2 hours')
  ON CONFLICT ("TransactionUUID") DO NOTHING;

  RAISE NOTICE 'Seeded 8 rows in pay."Transactions"';

  -- ═══════════════════════════════════════════════════════════════
  -- SECCIÓN 7: audit."AuditLog"
  -- ═══════════════════════════════════════════════════════════════

  INSERT INTO audit."AuditLog" ("CompanyId", "BranchId", "UserId", "UserName", "ModuleName", "EntityName", "EntityId", "ActionType", "Summary", "IpAddress", "CreatedAt")
  SELECT v_company_id, v_branch_id, 1, 'admin', 'SEGURIDAD', 'Session', 'SES-001', 'LOGIN', 'SEED: Login admin exitoso', '192.168.1.10', v_now - INTERVAL '8 hours'
  WHERE NOT EXISTS (SELECT 1 FROM audit."AuditLog" WHERE "CompanyId" = 1 AND "Summary" = 'SEED: Login admin exitoso');

  INSERT INTO audit."AuditLog" ("CompanyId", "BranchId", "UserId", "UserName", "ModuleName", "EntityName", "EntityId", "ActionType", "Summary", "NewValues", "IpAddress", "CreatedAt")
  SELECT v_company_id, v_branch_id, 1, 'admin', 'POS', 'SaleTicket', 'POS-000001', 'CREATE', 'SEED: Creación factura POS-000001', '{"total":104.39,"paymentMethod":"EFECTIVO"}', '192.168.1.10', v_now - INTERVAL '6 hours'
  WHERE NOT EXISTS (SELECT 1 FROM audit."AuditLog" WHERE "CompanyId" = 1 AND "Summary" = 'SEED: Creación factura POS-000001');

  INSERT INTO audit."AuditLog" ("CompanyId", "BranchId", "UserId", "UserName", "ModuleName", "EntityName", "EntityId", "ActionType", "Summary", "NewValues", "IpAddress", "CreatedAt")
  SELECT v_company_id, v_branch_id, 1, 'admin', 'POS', 'SaleTicket', 'POS-000002', 'CREATE', 'SEED: Creación factura POS-000002', '{"total":185.57,"paymentMethod":"TDC"}', '192.168.1.10', v_now - INTERVAL '5 hours'
  WHERE NOT EXISTS (SELECT 1 FROM audit."AuditLog" WHERE "CompanyId" = 1 AND "Summary" = 'SEED: Creación factura POS-000002');

  INSERT INTO audit."AuditLog" ("CompanyId", "BranchId", "UserId", "UserName", "ModuleName", "EntityName", "EntityId", "ActionType", "Summary", "NewValues", "IpAddress", "CreatedAt")
  SELECT v_company_id, v_branch_id, 1, 'admin', 'PAGOS', 'Transaction', 'seed-trx-pos-002', 'CREATE', 'SEED: Pago aprobado TDC POS-000002', '{"amount":185.57,"card":"VISA****4532","status":"APPROVED"}', '192.168.1.10', v_now - INTERVAL '5 hours'
  WHERE NOT EXISTS (SELECT 1 FROM audit."AuditLog" WHERE "CompanyId" = 1 AND "Summary" = 'SEED: Pago aprobado TDC POS-000002');

  INSERT INTO audit."AuditLog" ("CompanyId", "BranchId", "UserId", "UserName", "ModuleName", "EntityName", "EntityId", "ActionType", "Summary", "NewValues", "IpAddress", "CreatedAt")
  SELECT v_company_id, v_branch_id, 1, 'admin', 'POS', 'SaleTicket', 'POS-000003', 'CREATE', 'SEED: Creación factura POS-000003', '{"total":44.06,"paymentMethod":"TRANSFERENCIA"}', '192.168.1.11', v_now - INTERVAL '4 hours'
  WHERE NOT EXISTS (SELECT 1 FROM audit."AuditLog" WHERE "CompanyId" = 1 AND "Summary" = 'SEED: Creación factura POS-000003');

  INSERT INTO audit."AuditLog" ("CompanyId", "BranchId", "UserId", "UserName", "ModuleName", "EntityName", "EntityId", "ActionType", "Summary", "OldValues", "NewValues", "IpAddress", "CreatedAt")
  SELECT v_company_id, v_branch_id, 1, 'admin', 'INVENTARIO', 'Product', 'ELEC-AUD-BT01', 'UPDATE', 'SEED: Actualización precio producto ELEC-AUD-BT01', '{"salesPrice":85.99}', '{"salesPrice":89.99}', '192.168.1.10', v_now - INTERVAL '7 hours'
  WHERE NOT EXISTS (SELECT 1 FROM audit."AuditLog" WHERE "CompanyId" = 1 AND "Summary" = 'SEED: Actualización precio producto ELEC-AUD-BT01');

  INSERT INTO audit."AuditLog" ("CompanyId", "BranchId", "UserId", "UserName", "ModuleName", "EntityName", "EntityId", "ActionType", "Summary", "OldValues", "IpAddress", "CreatedAt")
  SELECT v_company_id, v_branch_id, 1, 'admin', 'FACTURACION', 'Invoice', 'DEV-001', 'VOID', 'SEED: Anulación documento DEV-001', '{"total":320.00,"reason":"Error en datos fiscales"}', '192.168.1.10', v_now - INTERVAL '3 hours'
  WHERE NOT EXISTS (SELECT 1 FROM audit."AuditLog" WHERE "CompanyId" = 1 AND "Summary" = 'SEED: Anulación documento DEV-001');

  INSERT INTO audit."AuditLog" ("CompanyId", "BranchId", "UserId", "UserName", "ModuleName", "EntityName", "EntityId", "ActionType", "Summary", "NewValues", "IpAddress", "CreatedAt")
  SELECT v_company_id, v_branch_id, 1, 'admin', 'PAGOS', 'Transaction', 'seed-trx-pos-008', 'CREATE', 'SEED: Pago declinado transferencia', '{"amount":500.00,"status":"DECLINED","reason":"Fondos insuficientes"}', '192.168.1.11', v_now - INTERVAL '2 hours'
  WHERE NOT EXISTS (SELECT 1 FROM audit."AuditLog" WHERE "CompanyId" = 1 AND "Summary" = 'SEED: Pago declinado transferencia');

  INSERT INTO audit."AuditLog" ("CompanyId", "BranchId", "UserId", "UserName", "ModuleName", "EntityName", "EntityId", "ActionType", "Summary", "NewValues", "IpAddress", "CreatedAt")
  SELECT v_company_id, v_branch_id, 1, 'admin', 'SEGURIDAD', 'User', 'USR-002', 'CREATE', 'SEED: Nuevo usuario cajero2 creado', '{"userName":"cajero2","role":"CAJERO","branch":1}', '192.168.1.10', v_now - INTERVAL '7 hours'
  WHERE NOT EXISTS (SELECT 1 FROM audit."AuditLog" WHERE "CompanyId" = 1 AND "Summary" = 'SEED: Nuevo usuario cajero2 creado');

  INSERT INTO audit."AuditLog" ("CompanyId", "BranchId", "UserId", "UserName", "ModuleName", "EntityName", "EntityId", "ActionType", "Summary", "OldValues", "IpAddress", "CreatedAt")
  SELECT v_company_id, v_branch_id, 1, 'admin', 'INVENTARIO', 'Product', 'TEST-DISC-01', 'DELETE', 'SEED: Eliminación producto descontinuado TEST-DISC-01', '{"productName":"Producto Descontinuado","stockQty":0}', '192.168.1.10', v_now - INTERVAL '1 hour'
  WHERE NOT EXISTS (SELECT 1 FROM audit."AuditLog" WHERE "CompanyId" = 1 AND "Summary" = 'SEED: Eliminación producto descontinuado TEST-DISC-01');

  RAISE NOTICE 'Seeded 10 rows in audit."AuditLog"';

  RAISE NOTICE '=== seed_demo_ecommerce_pos.sql — COMPLETE ===';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed_demo_ecommerce_pos.sql: %', SQLERRM;
  RAISE;
END $$;
