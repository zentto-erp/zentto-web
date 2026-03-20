/*
 * ============================================================================
 *  Archivo : usp_ops.sql  (PostgreSQL)
 *  Esquemas: pos / rest / master / fin / cfg / sec (tablas)
 *
 *  Descripcion:
 *    Funciones operacionales que reemplazan SQL inline en los
 *    servicios TypeScript de: POS, Restaurante, MovInvent y Bancos.
 *
 *  Convenciones de nombrado:
 *    - POS         : usp_pos_[entity]_[action]
 *    - Restaurante : usp_rest_[entity]_[action]
 *    - MovInvent   : usp_inv_movement_[action]
 *    - Bancos      : usp_bank_[entity]_[action]
 * ============================================================================
 */

-- =============================================================================
--  SECCION 1: PROCEDIMIENTOS COMPARTIDOS (Scope, User, Tax, Product, Customer)
-- =============================================================================

-- usp_POS_ResolveDefaultScope
DROP FUNCTION IF EXISTS usp_pos_resolvedefaultscope() CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_resolvedefaultscope()
RETURNS TABLE("companyId" INT, "branchId" INT, "countryCode" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CompanyId",
        b."BranchId",
        UPPER(COALESCE(NULLIF(b."CountryCode", ''), c."FiscalCountryCode"))::VARCHAR
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId"
    WHERE c."CompanyCode" = 'DEFAULT'
      AND b."BranchCode"  = 'MAIN'
    ORDER BY c."CompanyId", b."BranchId"
    LIMIT 1;
END;
$$;

-- usp_POS_ResolveUserId
DROP FUNCTION IF EXISTS usp_pos_resolveuserid(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_resolveuserid(
    p_user_code VARCHAR(60)
)
RETURNS TABLE("userId" INT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT u."UserId"
    FROM sec."User" u
    WHERE UPPER(u."UserCode") = UPPER(p_user_code)
      AND u."IsDeleted" = FALSE
      AND u."IsActive"  = TRUE
    LIMIT 1;
END;
$$;

-- usp_POS_LoadCountryTaxRates
DROP FUNCTION IF EXISTS usp_pos_loadcountrytaxrates(VARCHAR(5)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_loadcountrytaxrates(
    p_country_code VARCHAR(5)
)
RETURNS TABLE("taxCode" VARCHAR, "rate" NUMERIC, "isDefault" BOOLEAN)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT tr."TaxCode", tr."Rate", tr."IsDefault"
    FROM fiscal."TaxRate" tr
    WHERE tr."CountryCode" = p_country_code
      AND tr."IsActive" = TRUE
    ORDER BY tr."IsDefault" DESC, tr."SortOrder", tr."TaxCode";
END;
$$;

-- usp_POS_ResolveProduct
DROP FUNCTION IF EXISTS usp_pos_resolveproduct(INT, VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_resolveproduct(
    p_company_id  INT,
    p_identifier  VARCHAR(50)
)
RETURNS TABLE(
    "productId"      BIGINT,
    "productCode"    VARCHAR,
    "productName"    VARCHAR,
    "defaultTaxCode" VARCHAR,
    "defaultTaxRate" NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."ProductId", p."ProductCode", p."ProductName",
        p."DefaultTaxCode", p."DefaultTaxRate"
    FROM master."Product" p
    WHERE p."CompanyId" = p_company_id
      AND p."IsDeleted" = FALSE
      AND (
          p."ProductCode" = p_identifier
          OR p."ProductId"::TEXT = p_identifier
      )
    ORDER BY p."ProductId" DESC
    LIMIT 1;
END;
$$;

-- usp_POS_ResolveCustomerById
DROP FUNCTION IF EXISTS usp_pos_resolvecustomerbyid(INT, VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_resolvecustomerbyid(
    p_company_id INT,
    p_id_input   VARCHAR(50)
)
RETURNS TABLE("customerId" BIGINT, "customerCode" VARCHAR, "customerName" VARCHAR, "fiscalId" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c."CustomerId", c."CustomerCode", c."CustomerName", c."FiscalId"
    FROM master."Customer" c
    WHERE c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE
      AND (
          c."CustomerCode" = p_id_input
          OR c."CustomerId"::TEXT = p_id_input
      )
    ORDER BY c."CustomerId" DESC
    LIMIT 1;
END;
$$;

-- usp_POS_ResolveCustomerByRif
DROP FUNCTION IF EXISTS usp_pos_resolvecustomerbyrif(INT, VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_resolvecustomerbyrif(
    p_company_id INT,
    p_rif        VARCHAR(50)
)
RETURNS TABLE("customerId" BIGINT, "customerCode" VARCHAR, "customerName" VARCHAR, "fiscalId" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT c."CustomerId", c."CustomerCode", c."CustomerName", c."FiscalId"
    FROM master."Customer" c
    WHERE c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE
      AND c."FiscalId"  = p_rif
    ORDER BY c."CustomerId" DESC
    LIMIT 1;
END;
$$;


-- =============================================================================
--  SECCION 2: POS - SERVICE
-- =============================================================================

-- usp_POS_Product_List
DROP FUNCTION IF EXISTS usp_pos_product_list(INT, INT, VARCHAR(200), VARCHAR(100), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_product_list(
    p_company_id INT,
    p_branch_id  INT,
    p_search     VARCHAR(200) DEFAULT NULL,
    p_categoria  VARCHAR(100) DEFAULT NULL,
    p_offset     INT DEFAULT 0,
    p_limit      INT DEFAULT 50
)
RETURNS TABLE(
    "id"         BIGINT,
    "codigo"     VARCHAR,
    "nombre"     VARCHAR,
    "imagen"     VARCHAR,
    "precioDetal" NUMERIC,
    "existencia" NUMERIC,
    "categoria"  VARCHAR,
    "iva"        NUMERIC,
    "TotalCount" BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM master."Product"
    WHERE "CompanyId" = p_company_id
      AND "IsDeleted" = FALSE AND "IsActive" = TRUE
      AND ("StockQty" > 0 OR "IsService" = TRUE)
      AND (p_search IS NULL OR "ProductCode" LIKE p_search OR "ProductName" LIKE p_search)
      AND (p_categoria IS NULL OR "CategoryCode" = p_categoria);

    RETURN QUERY
    SELECT
        p."ProductId",
        p."ProductCode",
        p."ProductName",
        img."PublicUrl",
        p."SalesPrice",
        p."StockQty",
        p."CategoryCode",
        CASE WHEN p."DefaultTaxRate" > 1 THEN p."DefaultTaxRate" ELSE p."DefaultTaxRate" * 100 END,
        v_total
    FROM master."Product" p
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId"  = p."CompanyId"
          AND ei."BranchId"   = p_branch_id
          AND ei."EntityType" = 'MASTER_PRODUCT'
          AND ei."EntityId"   = p."ProductId"
          AND ei."IsDeleted"  = FALSE AND ei."IsActive" = TRUE
          AND ma."IsDeleted"  = FALSE AND ma."IsActive" = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    WHERE p."CompanyId" = p_company_id
      AND p."IsDeleted" = FALSE AND p."IsActive" = TRUE
      AND (p."StockQty" > 0 OR p."IsService" = TRUE)
      AND (p_search IS NULL OR p."ProductCode" LIKE p_search OR p."ProductName" LIKE p_search)
      AND (p_categoria IS NULL OR p."CategoryCode" = p_categoria)
    ORDER BY p."ProductCode"
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- usp_POS_Product_GetByCode
DROP FUNCTION IF EXISTS usp_pos_product_getbycode(INT, INT, VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_product_getbycode(
    p_company_id INT,
    p_branch_id  INT,
    p_codigo     VARCHAR(50)
)
RETURNS TABLE(
    "id"         BIGINT,
    "codigo"     VARCHAR,
    "nombre"     VARCHAR,
    "imagen"     VARCHAR,
    "precioDetal" NUMERIC,
    "existencia" NUMERIC,
    "categoria"  VARCHAR,
    "iva"        NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."ProductId",
        p."ProductCode",
        p."ProductName",
        img."PublicUrl",
        p."SalesPrice",
        p."StockQty",
        p."CategoryCode",
        CASE WHEN p."DefaultTaxRate" > 1 THEN p."DefaultTaxRate" ELSE p."DefaultTaxRate" * 100 END
    FROM master."Product" p
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId"  = p."CompanyId"
          AND ei."BranchId"   = p_branch_id
          AND ei."EntityType" = 'MASTER_PRODUCT'
          AND ei."EntityId"   = p."ProductId"
          AND ei."IsDeleted"  = FALSE AND ei."IsActive" = TRUE
          AND ma."IsDeleted"  = FALSE AND ma."IsActive" = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    WHERE p."CompanyId" = p_company_id
      AND p."IsDeleted" = FALSE AND p."IsActive" = TRUE
      AND (p."ProductCode" = p_codigo OR p."ProductId"::TEXT = p_codigo)
    ORDER BY p."ProductId" DESC
    LIMIT 1;
END;
$$;

-- usp_POS_Customer_Search
DROP FUNCTION IF EXISTS usp_pos_customer_search(INT, VARCHAR(200), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_customer_search(
    p_company_id INT,
    p_search     VARCHAR(200) DEFAULT NULL,
    p_limit      INT DEFAULT 20
)
RETURNS TABLE(
    "id" BIGINT, "codigo" VARCHAR, "nombre" VARCHAR, "rif" VARCHAR,
    "telefono" VARCHAR, "email" VARCHAR, "direccion" VARCHAR,
    "tipoPrecio" VARCHAR, "credito" NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CustomerId", c."CustomerCode", c."CustomerName", c."FiscalId",
        c."Phone", c."Email", c."AddressLine",
        'Detal'::VARCHAR, c."CreditLimit"
    FROM master."Customer" c
    WHERE c."CompanyId" = p_company_id
      AND c."IsDeleted" = FALSE AND c."IsActive" = TRUE
      AND (p_search IS NULL OR c."CustomerCode" LIKE p_search OR c."CustomerName" LIKE p_search OR c."FiscalId" LIKE p_search)
    ORDER BY c."CustomerName"
    LIMIT p_limit;
END;
$$;

-- usp_POS_Category_List
DROP FUNCTION IF EXISTS usp_pos_category_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_category_list(
    p_company_id INT
)
RETURNS TABLE("id" VARCHAR, "nombre" VARCHAR, "productCount" BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(NULLIF(TRIM("CategoryCode"), ''), '(Sin Categoria)')::VARCHAR,
        COALESCE(NULLIF(TRIM("CategoryCode"), ''), '(Sin Categoria)')::VARCHAR,
        COUNT(1)
    FROM master."Product"
    WHERE "CompanyId" = p_company_id
      AND "IsDeleted" = FALSE AND "IsActive" = TRUE
      AND ("StockQty" > 0 OR "IsService" = TRUE)
    GROUP BY COALESCE(NULLIF(TRIM("CategoryCode"), ''), '(Sin Categoria)')
    ORDER BY COALESCE(NULLIF(TRIM("CategoryCode"), ''), '(Sin Categoria)');
END;
$$;

-- usp_POS_FiscalCorrelative_List
DROP FUNCTION IF EXISTS usp_pos_fiscalcorrelative_list(INT, INT, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_fiscalcorrelative_list(
    p_company_id INT,
    p_branch_id  INT,
    p_caja_id    VARCHAR(20) DEFAULT NULL
)
RETURNS TABLE("tipo" VARCHAR, "cajaId" VARCHAR, "serialFiscal" VARCHAR, "correlativoActual" INT, "descripcion" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        CASE WHEN fc."CashRegisterCode" = 'GLOBAL' THEN fc."CorrelativeType"
             ELSE fc."CorrelativeType" || '|CAJA:' || fc."CashRegisterCode"
        END::VARCHAR,
        CASE WHEN fc."CashRegisterCode" = 'GLOBAL' THEN NULL ELSE fc."CashRegisterCode" END,
        fc."SerialFiscal",
        fc."CurrentNumber",
        fc."Description"
    FROM pos."FiscalCorrelative" fc
    WHERE fc."CompanyId" = p_company_id
      AND fc."BranchId"  = p_branch_id
      AND fc."IsActive"  = TRUE
      AND (p_caja_id IS NULL OR fc."CashRegisterCode" IN ('GLOBAL', p_caja_id))
    ORDER BY
        CASE WHEN fc."CashRegisterCode" = 'GLOBAL' THEN 0 ELSE 1 END,
        fc."CashRegisterCode",
        fc."CorrelativeType";
END;
$$;

-- usp_POS_FiscalCorrelative_Upsert
DROP FUNCTION IF EXISTS usp_pos_fiscalcorrelative_upsert(INT, INT, VARCHAR(20), VARCHAR(20), INT, VARCHAR(200)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_fiscalcorrelative_upsert(
    p_company_id         INT,
    p_branch_id          INT,
    p_caja_id            VARCHAR(20),
    p_serial_fiscal      VARCHAR(20),
    p_correlativo_actual INT DEFAULT 0,
    p_descripcion        VARCHAR(200) DEFAULT ''
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pos."FiscalCorrelative"
        WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
          AND "CorrelativeType" = 'FACTURA' AND "CashRegisterCode" = p_caja_id
    ) THEN
        UPDATE pos."FiscalCorrelative"
        SET "SerialFiscal"  = p_serial_fiscal,
            "CurrentNumber" = p_correlativo_actual,
            "Description"   = p_descripcion,
            "UpdatedAt"     = NOW() AT TIME ZONE 'UTC',
            "IsActive"      = TRUE
        WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
          AND "CorrelativeType" = 'FACTURA' AND "CashRegisterCode" = p_caja_id;
    ELSE
        INSERT INTO pos."FiscalCorrelative" (
            "CompanyId", "BranchId", "CorrelativeType", "CashRegisterCode",
            "SerialFiscal", "CurrentNumber", "Description", "IsActive"
        )
        VALUES (
            p_company_id, p_branch_id, 'FACTURA', p_caja_id,
            p_serial_fiscal, p_correlativo_actual, p_descripcion, TRUE
        );
    END IF;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$$;

-- usp_POS_Report_Resumen
DROP FUNCTION IF EXISTS usp_pos_report_resumen(INT, INT, DATE, DATE, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_report_resumen(
    p_company_id INT,
    p_branch_id  INT,
    p_from_date  DATE,
    p_to_date    DATE,
    p_caja_id    VARCHAR(20) DEFAULT NULL
)
RETURNS TABLE(
    "totalVentas" NUMERIC, "transacciones" BIGINT,
    "productosVendidos" NUMERIC, "productosDiferentes" BIGINT,
    "ticketPromedio" NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH ventas AS (
        SELECT st."SaleTicketId", st."TotalAmount"
        FROM pos."SaleTicket" st
        WHERE st."CompanyId" = p_company_id AND st."BranchId" = p_branch_id
          AND (st."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
          AND (p_caja_id IS NULL OR UPPER(st."CashRegisterCode") = p_caja_id)
    ),
    detalle AS (
        SELECT l."ProductCode", l."Quantity"
        FROM pos."SaleTicketLine" l
        INNER JOIN ventas v ON v."SaleTicketId" = l."SaleTicketId"
    )
    SELECT
        COALESCE((SELECT SUM(v."TotalAmount") FROM ventas v), 0),
        COALESCE((SELECT COUNT(1) FROM ventas), 0),
        COALESCE((SELECT SUM(d."Quantity") FROM detalle d), 0),
        COALESCE((SELECT COUNT(DISTINCT d."ProductCode") FROM detalle d), 0),
        CASE
            WHEN (SELECT COUNT(1) FROM ventas) = 0 THEN 0::NUMERIC
            ELSE COALESCE((SELECT SUM(v."TotalAmount") FROM ventas v), 0)
                 / NULLIF((SELECT COUNT(1) FROM ventas), 0)
        END;
END;
$$;

-- usp_POS_Report_Ventas
DROP FUNCTION IF EXISTS usp_pos_report_ventas(INT, INT, DATE, DATE, VARCHAR(20), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_report_ventas(
    p_company_id INT,
    p_branch_id  INT,
    p_from_date  DATE,
    p_to_date    DATE,
    p_caja_id    VARCHAR(20) DEFAULT NULL,
    p_limit      INT DEFAULT 200
)
RETURNS TABLE(
    "id" BIGINT, "numFactura" VARCHAR, "fecha" TIMESTAMP,
    "cliente" VARCHAR, "cajaId" VARCHAR, "total" NUMERIC,
    "estado" VARCHAR, "metodoPago" VARCHAR, "tramaFiscal" TEXT,
    "serialFiscal" VARCHAR, "correlativoFiscal" INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v."SaleTicketId",
        v."InvoiceNumber",
        v."SoldAt",
        COALESCE(NULLIF(TRIM(v."CustomerName"), ''), 'Consumidor Final')::VARCHAR,
        v."CashRegisterCode",
        v."TotalAmount",
        'Completada'::VARCHAR,
        v."PaymentMethod",
        v."FiscalPayload",
        corr."SerialFiscal",
        corr."CurrentNumber"
    FROM pos."SaleTicket" v
    LEFT JOIN LATERAL (
        SELECT fc."SerialFiscal", fc."CurrentNumber"
        FROM pos."FiscalCorrelative" fc
        WHERE fc."CompanyId" = v."CompanyId" AND fc."BranchId" = v."BranchId"
          AND fc."CorrelativeType" = 'FACTURA' AND fc."IsActive" = TRUE
          AND fc."CashRegisterCode" IN (UPPER(v."CashRegisterCode"), 'GLOBAL')
        ORDER BY CASE WHEN fc."CashRegisterCode" = UPPER(v."CashRegisterCode") THEN 0 ELSE 1 END,
                 fc."FiscalCorrelativeId" DESC
        LIMIT 1
    ) corr ON TRUE
    WHERE v."CompanyId" = p_company_id AND v."BranchId" = p_branch_id
      AND (v."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
      AND (p_caja_id IS NULL OR UPPER(v."CashRegisterCode") = p_caja_id)
    ORDER BY v."SoldAt" DESC, v."SaleTicketId" DESC
    LIMIT p_limit;
END;
$$;

-- usp_POS_Report_ProductosTop
DROP FUNCTION IF EXISTS usp_pos_report_productostop(INT, INT, DATE, DATE, VARCHAR(20), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_report_productostop(
    p_company_id INT,
    p_branch_id  INT,
    p_from_date  DATE,
    p_to_date    DATE,
    p_caja_id    VARCHAR(20) DEFAULT NULL,
    p_limit      INT DEFAULT 20
)
RETURNS TABLE("productoId" BIGINT, "codigo" VARCHAR, "nombre" VARCHAR, "cantidad" NUMERIC, "total" NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT l."ProductId", l."ProductCode", l."ProductName",
           SUM(l."Quantity"), SUM(l."TotalAmount")
    FROM pos."SaleTicketLine" l
    INNER JOIN pos."SaleTicket" v ON v."SaleTicketId" = l."SaleTicketId"
    WHERE v."CompanyId" = p_company_id AND v."BranchId" = p_branch_id
      AND (v."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
      AND (p_caja_id IS NULL OR UPPER(v."CashRegisterCode") = p_caja_id)
    GROUP BY l."ProductId", l."ProductCode", l."ProductName"
    ORDER BY SUM(l."TotalAmount") DESC, SUM(l."Quantity") DESC
    LIMIT p_limit;
END;
$$;

-- usp_POS_Report_FormasPago
DROP FUNCTION IF EXISTS usp_pos_report_formaspago(INT, INT, DATE, DATE, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_report_formaspago(
    p_company_id INT,
    p_branch_id  INT,
    p_from_date  DATE,
    p_to_date    DATE,
    p_caja_id    VARCHAR(20) DEFAULT NULL
)
RETURNS TABLE("metodoPago" VARCHAR, "transacciones" BIGINT, "total" NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(NULLIF(TRIM(v."PaymentMethod"), ''), 'No especificado')::VARCHAR,
        COUNT(1),
        SUM(v."TotalAmount")
    FROM pos."SaleTicket" v
    WHERE v."CompanyId" = p_company_id AND v."BranchId" = p_branch_id
      AND (v."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
      AND (p_caja_id IS NULL OR UPPER(v."CashRegisterCode") = p_caja_id)
    GROUP BY COALESCE(NULLIF(TRIM(v."PaymentMethod"), ''), 'No especificado')
    ORDER BY SUM(v."TotalAmount") DESC;
END;
$$;

-- usp_POS_Report_Cajas
DROP FUNCTION IF EXISTS usp_pos_report_cajas(INT, INT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_report_cajas(
    p_company_id INT,
    p_branch_id  INT,
    p_from_date  DATE,
    p_to_date    DATE
)
RETURNS TABLE("cajaId" VARCHAR, "transacciones" BIGINT, "total" NUMERIC, "serialFiscal" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        UPPER(v."CashRegisterCode")::VARCHAR,
        COUNT(1),
        SUM(v."TotalAmount"),
        MAX(COALESCE(corr."SerialFiscal", ''))::VARCHAR
    FROM pos."SaleTicket" v
    LEFT JOIN LATERAL (
        SELECT fc."SerialFiscal"
        FROM pos."FiscalCorrelative" fc
        WHERE fc."CompanyId" = v."CompanyId" AND fc."BranchId" = v."BranchId"
          AND fc."CorrelativeType" = 'FACTURA' AND fc."IsActive" = TRUE
          AND fc."CashRegisterCode" IN (UPPER(v."CashRegisterCode"), 'GLOBAL')
        ORDER BY CASE WHEN fc."CashRegisterCode" = UPPER(v."CashRegisterCode") THEN 0 ELSE 1 END,
                 fc."FiscalCorrelativeId" DESC
        LIMIT 1
    ) corr ON TRUE
    WHERE v."CompanyId" = p_company_id AND v."BranchId" = p_branch_id
      AND (v."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
    GROUP BY UPPER(v."CashRegisterCode")
    ORDER BY UPPER(v."CashRegisterCode");
END;
$$;


-- =============================================================================
--  SECCION 3: POS ESPERA
-- =============================================================================

-- usp_POS_WaitTicket_Create
DROP FUNCTION IF EXISTS usp_pos_waitticket_create CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_waitticket_create(
    p_company_id        INT,
    p_branch_id         INT,
    p_country_code      VARCHAR(5),
    p_cash_register_code VARCHAR(20),
    p_station_name      VARCHAR(100) DEFAULT NULL,
    p_created_by_user_id INT DEFAULT NULL,
    p_customer_id       INT DEFAULT NULL,
    p_customer_code     VARCHAR(50) DEFAULT NULL,
    p_customer_name     VARCHAR(255) DEFAULT NULL,
    p_customer_fiscal_id VARCHAR(50) DEFAULT NULL,
    p_price_tier        VARCHAR(50) DEFAULT 'Detal',
    p_reason            VARCHAR(500) DEFAULT NULL,
    p_net_amount        NUMERIC(18,2) DEFAULT 0,
    p_discount_amount   NUMERIC(18,2) DEFAULT 0,
    p_tax_amount        NUMERIC(18,2) DEFAULT 0,
    p_total_amount      NUMERIC(18,2) DEFAULT 0
)
RETURNS TABLE("Resultado" BIGINT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO pos."WaitTicket" (
        "CompanyId", "BranchId", "CountryCode", "CashRegisterCode", "StationName",
        "CreatedByUserId", "CustomerId", "CustomerCode", "CustomerName", "CustomerFiscalId",
        "PriceTier", "Reason", "NetAmount", "DiscountAmount", "TaxAmount", "TotalAmount",
        "Status", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        p_company_id, p_branch_id, p_country_code, p_cash_register_code, p_station_name,
        p_created_by_user_id, p_customer_id, p_customer_code, p_customer_name, p_customer_fiscal_id,
        p_price_tier, p_reason, p_net_amount, p_discount_amount, p_tax_amount, p_total_amount,
        'WAITING', NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "WaitTicketId" INTO v_id;

    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$$;

-- usp_POS_WaitTicketLine_Insert
DROP FUNCTION IF EXISTS usp_pos_waitticketline_insert CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_waitticketline_insert(
    p_wait_ticket_id        BIGINT,
    p_line_number           INT,
    p_country_code          VARCHAR(5),
    p_product_id            INT DEFAULT NULL,
    p_product_code          VARCHAR(60) DEFAULT NULL,
    p_product_name          VARCHAR(255) DEFAULT NULL,
    p_quantity              NUMERIC(18,4) DEFAULT NULL,
    p_unit_price            NUMERIC(18,4) DEFAULT NULL,
    p_discount_amount       NUMERIC(18,2) DEFAULT 0,
    p_tax_code              VARCHAR(20) DEFAULT NULL,
    p_tax_rate              NUMERIC(10,6) DEFAULT NULL,
    p_net_amount            NUMERIC(18,2) DEFAULT NULL,
    p_tax_amount            NUMERIC(18,2) DEFAULT NULL,
    p_total_amount          NUMERIC(18,2) DEFAULT NULL,
    p_supervisor_approval_id INT DEFAULT NULL,
    p_line_meta_json        TEXT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO pos."WaitTicketLine" (
        "WaitTicketId", "LineNumber", "CountryCode", "ProductId", "ProductCode", "ProductName",
        "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate",
        "NetAmount", "TaxAmount", "TotalAmount",
        "SupervisorApprovalId", "LineMetaJson", "CreatedAt"
    )
    VALUES (
        p_wait_ticket_id, p_line_number, p_country_code, p_product_id, p_product_code, p_product_name,
        p_quantity, p_unit_price, p_discount_amount, p_tax_code, p_tax_rate,
        p_net_amount, p_tax_amount, p_total_amount,
        p_supervisor_approval_id, p_line_meta_json, NOW() AT TIME ZONE 'UTC'
    );

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$$;

-- usp_POS_WaitTicket_List
-- FIX: id BIGINT (WaitTicketId is bigint), fechaCreacion TIMESTAMP (not TIMESTAMPTZ)
DROP FUNCTION IF EXISTS usp_pos_waitticket_list(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_waitticket_list(
    p_company_id INT,
    p_branch_id  INT
)
RETURNS TABLE(
    id               bigint,
    "cajaId"         character varying,
    "estacionNombre" character varying,
    "clienteNombre"  character varying,
    motivo           character varying,
    total            numeric,
    "fechaCreacion"  timestamp without time zone
)
LANGUAGE plpgsql
AS $func$
BEGIN
    RETURN QUERY
    SELECT wt."WaitTicketId"::bigint, wt."CashRegisterCode"::VARCHAR, wt."StationName"::VARCHAR,
           wt."CustomerName"::VARCHAR, wt."Reason"::VARCHAR, wt."TotalAmount", wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id AND wt."BranchId" = p_branch_id AND wt."Status" = 'WAITING'
    ORDER BY wt."CreatedAt";
END;
$func$;

-- usp_POS_WaitTicket_GetHeader
DROP FUNCTION IF EXISTS usp_pos_waitticket_getheader CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_waitticket_getheader(
    p_company_id    INT,
    p_branch_id     INT,
    p_wait_ticket_id BIGINT
)
RETURNS TABLE(
    "id" BIGINT, "cajaId" VARCHAR, "estacionNombre" VARCHAR, "clienteId" VARCHAR,
    "clienteNombre" VARCHAR, "clienteRif" VARCHAR, "tipoPrecio" VARCHAR, "motivo" VARCHAR,
    "subtotal" NUMERIC, "impuestos" NUMERIC, "total" NUMERIC,
    "estado" VARCHAR, "fechaCreacion" TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT wt."WaitTicketId", wt."CashRegisterCode", wt."StationName", wt."CustomerCode",
           wt."CustomerName", wt."CustomerFiscalId", wt."PriceTier", wt."Reason",
           wt."NetAmount", wt."TaxAmount", wt."TotalAmount", wt."Status", wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id AND wt."BranchId" = p_branch_id AND wt."WaitTicketId" = p_wait_ticket_id
    LIMIT 1;
END;
$$;

-- usp_POS_WaitTicket_Recover
DROP FUNCTION IF EXISTS usp_pos_waitticket_recover CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_waitticket_recover(
    p_company_id         INT,
    p_branch_id          INT,
    p_wait_ticket_id     BIGINT,
    p_recovered_by_user_id INT DEFAULT NULL,
    p_recovered_at_register VARCHAR(20) DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE pos."WaitTicket"
    SET "Status" = 'RECOVERED',
        "RecoveredByUserId" = p_recovered_by_user_id,
        "RecoveredAtRegister" = p_recovered_at_register,
        "RecoveredAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id AND "WaitTicketId" = p_wait_ticket_id;

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$$;

-- usp_POS_WaitTicketLine_GetItems
DROP FUNCTION IF EXISTS usp_pos_waitticketline_getitems CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_waitticketline_getitems(
    p_wait_ticket_id BIGINT
)
RETURNS TABLE(
    "id" BIGINT, "productoId" VARCHAR, "codigo" VARCHAR, "nombre" VARCHAR,
    "cantidad" NUMERIC, "precioUnitario" NUMERIC, "descuento" NUMERIC,
    "iva" NUMERIC, "subtotal" NUMERIC, "total" NUMERIC,
    "supervisorApprovalId" INT, "lineMetaJson" TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        wl."WaitTicketLineId",
        COALESCE(wl."ProductId"::TEXT, wl."ProductCode")::VARCHAR,
        wl."ProductCode", wl."ProductName",
        wl."Quantity", wl."UnitPrice", wl."DiscountAmount",
        CASE WHEN wl."TaxRate" > 1 THEN wl."TaxRate" ELSE wl."TaxRate" * 100 END,
        wl."NetAmount", wl."TotalAmount",
        wl."SupervisorApprovalId", wl."LineMetaJson"
    FROM pos."WaitTicketLine" wl
    WHERE wl."WaitTicketId" = p_wait_ticket_id
    ORDER BY wl."LineNumber";
END;
$$;

-- usp_POS_WaitTicket_Void
DROP FUNCTION IF EXISTS usp_pos_waitticket_void CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_waitticket_void(
    p_company_id    INT,
    p_branch_id     INT,
    p_wait_ticket_id BIGINT
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE pos."WaitTicket"
    SET "Status" = 'VOIDED', "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
      AND "WaitTicketId" = p_wait_ticket_id AND "Status" = 'WAITING';

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$$;

-- usp_POS_SaleTicket_Create
DROP FUNCTION IF EXISTS usp_pos_saleticket_create CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_saleticket_create(
    p_company_id        INT,
    p_branch_id         INT,
    p_country_code      VARCHAR(5),
    p_invoice_number    VARCHAR(50),
    p_cash_register_code VARCHAR(20),
    p_sold_by_user_id   INT DEFAULT NULL,
    p_customer_id       INT DEFAULT NULL,
    p_customer_code     VARCHAR(50) DEFAULT NULL,
    p_customer_name     VARCHAR(255) DEFAULT NULL,
    p_customer_fiscal_id VARCHAR(50) DEFAULT NULL,
    p_price_tier        VARCHAR(50) DEFAULT 'Detal',
    p_payment_method    VARCHAR(50) DEFAULT NULL,
    p_fiscal_payload    TEXT DEFAULT NULL,
    p_wait_ticket_id    BIGINT DEFAULT NULL,
    p_net_amount        NUMERIC(18,2) DEFAULT 0,
    p_discount_amount   NUMERIC(18,2) DEFAULT 0,
    p_tax_amount        NUMERIC(18,2) DEFAULT 0,
    p_total_amount      NUMERIC(18,2) DEFAULT 0
)
RETURNS TABLE("Resultado" BIGINT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO pos."SaleTicket" (
        "CompanyId", "BranchId", "CountryCode", "InvoiceNumber", "CashRegisterCode",
        "SoldByUserId", "CustomerId", "CustomerCode", "CustomerName", "CustomerFiscalId",
        "PriceTier", "PaymentMethod", "FiscalPayload", "WaitTicketId",
        "NetAmount", "DiscountAmount", "TaxAmount", "TotalAmount", "SoldAt"
    )
    VALUES (
        p_company_id, p_branch_id, p_country_code, p_invoice_number, p_cash_register_code,
        p_sold_by_user_id, p_customer_id, p_customer_code, p_customer_name, p_customer_fiscal_id,
        p_price_tier, p_payment_method, p_fiscal_payload, p_wait_ticket_id,
        p_net_amount, p_discount_amount, p_tax_amount, p_total_amount, NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "SaleTicketId" INTO v_id;

    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$$;

-- usp_POS_SaleTicketLine_Insert
DROP FUNCTION IF EXISTS usp_pos_saleticketline_insert CASCADE;
CREATE OR REPLACE FUNCTION usp_pos_saleticketline_insert(
    p_sale_ticket_id        BIGINT,
    p_line_number           INT,
    p_country_code          VARCHAR(5),
    p_product_id            INT DEFAULT NULL,
    p_product_code          VARCHAR(60) DEFAULT NULL,
    p_product_name          VARCHAR(255) DEFAULT NULL,
    p_quantity              NUMERIC(18,4) DEFAULT NULL,
    p_unit_price            NUMERIC(18,4) DEFAULT NULL,
    p_discount_amount       NUMERIC(18,2) DEFAULT 0,
    p_tax_code              VARCHAR(20) DEFAULT NULL,
    p_tax_rate              NUMERIC(10,6) DEFAULT NULL,
    p_net_amount            NUMERIC(18,2) DEFAULT NULL,
    p_tax_amount            NUMERIC(18,2) DEFAULT NULL,
    p_total_amount          NUMERIC(18,2) DEFAULT NULL,
    p_supervisor_approval_id INT DEFAULT NULL,
    p_line_meta_json        TEXT DEFAULT NULL
)
RETURNS TABLE("Resultado" BIGINT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
DECLARE
    v_id BIGINT;
BEGIN
    INSERT INTO pos."SaleTicketLine" (
        "SaleTicketId", "LineNumber", "CountryCode", "ProductId", "ProductCode", "ProductName",
        "Quantity", "UnitPrice", "DiscountAmount", "TaxCode", "TaxRate",
        "NetAmount", "TaxAmount", "TotalAmount",
        "SupervisorApprovalId", "LineMetaJson"
    )
    VALUES (
        p_sale_ticket_id, p_line_number, p_country_code, p_product_id, p_product_code, p_product_name,
        p_quantity, p_unit_price, p_discount_amount, p_tax_code, p_tax_rate,
        p_net_amount, p_tax_amount, p_total_amount,
        p_supervisor_approval_id, p_line_meta_json
    )
    RETURNING "SaleTicketLineId" INTO v_id;

    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$$;


-- =============================================================================
--  SECCION 4: RESTAURANTE
-- =============================================================================

-- usp_Rest_DiningTable_List
DROP FUNCTION IF EXISTS usp_rest_diningtable_list(INT, INT, VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_diningtable_list(
    p_company_id  INT,
    p_branch_id   INT,
    p_ambiente_id VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE(
    "id" INT, "numero" VARCHAR, "nombre" VARCHAR, "capacidad" INT,
    "ambienteId" VARCHAR, "ambiente" VARCHAR,
    "posicionX" NUMERIC, "posicionY" NUMERIC, "estado" VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        dt."DiningTableId",
        dt."TableNumber",
        COALESCE(NULLIF(dt."TableName", ''), 'Mesa ' || dt."TableNumber")::VARCHAR,
        dt."Capacity",
        dt."EnvironmentCode",
        dt."EnvironmentName",
        dt."PositionX",
        dt."PositionY",
        CASE
            WHEN EXISTS (
                SELECT 1 FROM rest."OrderTicket" o
                WHERE o."CompanyId" = dt."CompanyId" AND o."BranchId" = dt."BranchId"
                  AND o."TableNumber" = dt."TableNumber" AND o."Status" IN ('OPEN', 'SENT')
            ) THEN 'ocupada'::VARCHAR
            ELSE 'libre'::VARCHAR
        END
    FROM rest."DiningTable" dt
    WHERE dt."CompanyId" = p_company_id AND dt."BranchId" = p_branch_id AND dt."IsActive" = TRUE
      AND (p_ambiente_id IS NULL OR dt."EnvironmentCode" = p_ambiente_id)
    ORDER BY dt."EnvironmentCode", dt."TableNumber"::INT, dt."TableNumber";
END;
$$;

-- usp_Rest_DiningTable_GetById
DROP FUNCTION IF EXISTS usp_rest_diningtable_getbyid(INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_diningtable_getbyid(
    p_company_id INT, p_branch_id INT, p_mesa_id INT
)
RETURNS TABLE("id" INT, "tableNumber" VARCHAR, "tableName" VARCHAR, "capacity" INT,
              "ambienteId" VARCHAR, "ambiente" VARCHAR, "posicionX" NUMERIC, "posicionY" NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT dt."DiningTableId", dt."TableNumber", dt."TableName", dt."Capacity",
           dt."EnvironmentCode", dt."EnvironmentName", dt."PositionX", dt."PositionY"
    FROM rest."DiningTable" dt
    WHERE dt."CompanyId" = p_company_id AND dt."BranchId" = p_branch_id
      AND dt."DiningTableId" = p_mesa_id AND dt."IsActive" = TRUE
    LIMIT 1;
END;
$$;

-- usp_Rest_OrderTicket_GetOpenByTable
DROP FUNCTION IF EXISTS usp_rest_orderticket_getopenbytable(INT, INT, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_getopenbytable(
    p_company_id INT, p_branch_id INT, p_table_number VARCHAR(20)
)
RETURNS TABLE("id" INT, "status" VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT ot."OrderTicketId", ot."Status"
    FROM rest."OrderTicket" ot
    WHERE ot."CompanyId" = p_company_id AND ot."BranchId" = p_branch_id
      AND ot."TableNumber" = p_table_number AND ot."Status" IN ('OPEN', 'SENT')
    ORDER BY ot."OrderTicketId" DESC LIMIT 1;
END;
$$;

-- usp_Rest_OrderTicket_Create
DROP FUNCTION IF EXISTS usp_rest_orderticket_create(INT, INT, VARCHAR(5), VARCHAR(20), INT, VARCHAR(255), VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_create(
    p_company_id INT, p_branch_id INT, p_country_code VARCHAR(5), p_table_number VARCHAR(20),
    p_opened_by_user_id INT DEFAULT NULL, p_customer_name VARCHAR(255) DEFAULT NULL,
    p_customer_fiscal_id VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
    INSERT INTO rest."OrderTicket" ("CompanyId","BranchId","CountryCode","TableNumber","OpenedByUserId",
        "CustomerName","CustomerFiscalId","Status","NetAmount","TaxAmount","TotalAmount","OpenedAt")
    VALUES (p_company_id,p_branch_id,p_country_code,p_table_number,p_opened_by_user_id,
        p_customer_name,p_customer_fiscal_id,'OPEN',0,0,0,NOW() AT TIME ZONE 'UTC')
    RETURNING "OrderTicketId" INTO v_id;
    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$$;

-- usp_Rest_OrderTicket_GetById
DROP FUNCTION IF EXISTS usp_rest_orderticket_getbyid(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_getbyid(p_pedido_id INT)
RETURNS TABLE("orderId" INT,"companyId" INT,"branchId" INT,"countryCode" VARCHAR,"status" VARCHAR)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ot."OrderTicketId",ot."CompanyId",ot."BranchId",ot."CountryCode",ot."Status"
    FROM rest."OrderTicket" ot WHERE ot."OrderTicketId"=p_pedido_id LIMIT 1;
END; $$;

-- usp_Rest_OrderTicketLine_NextLineNumber
DROP FUNCTION IF EXISTS usp_rest_orderticketline_nextlinenumber(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticketline_nextlinenumber(p_order_id INT)
RETURNS TABLE("nextLine" INT)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT COALESCE(MAX("LineNumber"),0)+1 FROM rest."OrderTicketLine" WHERE "OrderTicketId"=p_order_id;
END; $$;

-- usp_Rest_OrderTicketLine_Insert
DROP FUNCTION IF EXISTS usp_rest_orderticketline_insert(INT, INT, VARCHAR(5), INT, VARCHAR(60), VARCHAR(255), NUMERIC(18,4), NUMERIC(18,4), VARCHAR(20), NUMERIC(10,6), NUMERIC(18,2), NUMERIC(18,2), NUMERIC(18,2), VARCHAR(600), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticketline_insert(
    p_order_id INT, p_line_number INT, p_country_code VARCHAR(5),
    p_product_id INT DEFAULT NULL, p_product_code VARCHAR(60) DEFAULT NULL,
    p_product_name VARCHAR(255) DEFAULT NULL, p_quantity NUMERIC(18,4) DEFAULT NULL,
    p_unit_price NUMERIC(18,4) DEFAULT NULL, p_tax_code VARCHAR(20) DEFAULT NULL,
    p_tax_rate NUMERIC(10,6) DEFAULT NULL, p_net_amount NUMERIC(18,2) DEFAULT NULL,
    p_tax_amount NUMERIC(18,2) DEFAULT NULL, p_total_amount NUMERIC(18,2) DEFAULT NULL,
    p_notes VARCHAR(600) DEFAULT NULL, p_supervisor_approval_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
    INSERT INTO rest."OrderTicketLine" ("OrderTicketId","LineNumber","CountryCode",
        "ProductId","ProductCode","ProductName","Quantity","UnitPrice","TaxCode","TaxRate",
        "NetAmount","TaxAmount","TotalAmount","Notes","SupervisorApprovalId","CreatedAt","UpdatedAt")
    VALUES (p_order_id,p_line_number,p_country_code,p_product_id,p_product_code,p_product_name,
        p_quantity,p_unit_price,p_tax_code,p_tax_rate,p_net_amount,p_tax_amount,p_total_amount,
        p_notes,p_supervisor_approval_id,NOW() AT TIME ZONE 'UTC',NOW() AT TIME ZONE 'UTC')
    RETURNING "OrderTicketLineId" INTO v_id;
    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END; $$;

-- usp_Rest_OrderTicket_RecalcTotals
DROP FUNCTION IF EXISTS usp_rest_orderticket_recalctotals(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_recalctotals(p_order_id INT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v_net NUMERIC(18,2); v_tax NUMERIC(18,2); v_total NUMERIC(18,2);
BEGIN
    SELECT COALESCE(SUM("NetAmount"),0),COALESCE(SUM("TaxAmount"),0),COALESCE(SUM("TotalAmount"),0)
    INTO v_net,v_tax,v_total FROM rest."OrderTicketLine" WHERE "OrderTicketId"=p_order_id;
    UPDATE rest."OrderTicket" SET "NetAmount"=v_net,"TaxAmount"=v_tax,"TotalAmount"=v_total,
        "UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "OrderTicketId"=p_order_id;
END; $$;

-- usp_Rest_OrderTicket_CheckPriorVoid
DROP FUNCTION IF EXISTS usp_rest_orderticket_checkpriorvoid(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_checkpriorvoid(p_pedido_id INT, p_item_id INT)
RETURNS TABLE("alreadyVoided" INT) LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT 1 FROM sec."SupervisorOverride"
    WHERE "ModuleCode"='RESTAURANTE' AND "ActionCode"='ORDER_LINE_VOID' AND "Status"='CONSUMED'
      AND "SourceDocumentId"=p_pedido_id AND "SourceLineId"=p_item_id LIMIT 1;
END; $$;

-- usp_Rest_OrderTicketLine_GetById
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbyid(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticketline_getbyid(p_pedido_id INT, p_item_id INT)
RETURNS TABLE("itemId" INT,"lineNumber" INT,"countryCode" VARCHAR,"productId" INT,
    "productCode" VARCHAR,"nombre" VARCHAR,"cantidad" NUMERIC,"unitPrice" NUMERIC,
    "taxCode" VARCHAR,"taxRate" NUMERIC,"netAmount" NUMERIC,"taxAmount" NUMERIC,"totalAmount" NUMERIC)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ol."OrderTicketLineId",ol."LineNumber",ol."CountryCode",ol."ProductId",
        ol."ProductCode",ol."ProductName",ol."Quantity",ol."UnitPrice",ol."TaxCode",ol."TaxRate",
        ol."NetAmount",ol."TaxAmount",ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    WHERE ol."OrderTicketId"=p_pedido_id AND ol."OrderTicketLineId"=p_item_id LIMIT 1;
END; $$;

-- usp_Rest_OrderTicket_SendToKitchen
DROP FUNCTION IF EXISTS usp_rest_orderticket_sendtokitchen(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_sendtokitchen(p_pedido_id INT)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500)) LANGUAGE plpgsql AS $$ BEGIN
    UPDATE rest."OrderTicket" SET "Status"=CASE WHEN "Status"='OPEN' THEN 'SENT' ELSE "Status" END,
        "UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "OrderTicketId"=p_pedido_id;
    RETURN QUERY SELECT 1,'OK'::VARCHAR(500);
END; $$;

-- usp_Rest_OrderTicket_InferCountryCode
DROP FUNCTION IF EXISTS usp_rest_orderticket_infercountrycode(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_infercountrycode(p_empresa_id INT, p_sucursal_id INT)
RETURNS TABLE("countryCode" VARCHAR) LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT cc."CountryCode" FROM fiscal."CountryConfig" cc
    WHERE cc."CompanyId"=p_empresa_id AND cc."BranchId"=p_sucursal_id AND cc."IsActive"=TRUE
    ORDER BY cc."UpdatedAt" DESC, cc."CountryConfigId" DESC LIMIT 1;
END; $$;

-- usp_Rest_OrderTicket_GetHeaderForClose
DROP FUNCTION IF EXISTS usp_rest_orderticket_getheaderforclose(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_getheaderforclose(p_pedido_id INT)
RETURNS TABLE("id" INT,"empresaId" INT,"sucursalId" INT,"countryCode" VARCHAR,"mesaId" INT,
    "clienteNombre" VARCHAR,"clienteRif" VARCHAR,"estado" VARCHAR,"total" NUMERIC,
    "fechaCierre" TIMESTAMPTZ,"codUsuario" VARCHAR)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT o."OrderTicketId",o."CompanyId",o."BranchId",o."CountryCode",dt."DiningTableId",
        o."CustomerName",o."CustomerFiscalId",o."Status",o."TotalAmount",o."ClosedAt",
        COALESCE(uc."UserCode",uo."UserCode")::VARCHAR
    FROM rest."OrderTicket" o
    LEFT JOIN rest."DiningTable" dt ON dt."CompanyId"=o."CompanyId" AND dt."BranchId"=o."BranchId" AND dt."TableNumber"=o."TableNumber"
    LEFT JOIN sec."User" uo ON uo."UserId"=o."OpenedByUserId"
    LEFT JOIN sec."User" uc ON uc."UserId"=o."ClosedByUserId"
    WHERE o."OrderTicketId"=p_pedido_id LIMIT 1;
END; $$;

-- usp_Rest_OrderTicket_Close
DROP FUNCTION IF EXISTS usp_rest_orderticket_close(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_close(p_pedido_id INT, p_closed_by_user_id INT DEFAULT NULL)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500)) LANGUAGE plpgsql AS $$ BEGIN
    UPDATE rest."OrderTicket" SET "Status"='CLOSED',"ClosedByUserId"=p_closed_by_user_id,
        "ClosedAt"=NOW() AT TIME ZONE 'UTC',"UpdatedAt"=NOW() AT TIME ZONE 'UTC'
    WHERE "OrderTicketId"=p_pedido_id;
    RETURN QUERY SELECT 1,'OK'::VARCHAR(500);
END; $$;

-- usp_Rest_OrderTicketLine_GetFiscalBreakdown
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getfiscalbreakdown(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticketline_getfiscalbreakdown(p_pedido_id INT)
RETURNS TABLE("itemId" INT,"productoId" VARCHAR,"nombre" VARCHAR,"quantity" NUMERIC,
    "unitPrice" NUMERIC,"baseAmount" NUMERIC,"taxCode" VARCHAR,"taxRate" NUMERIC,
    "taxAmount" NUMERIC,"totalAmount" NUMERIC)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ol."OrderTicketLineId",ol."ProductCode",ol."ProductName",
        ol."Quantity",ol."UnitPrice",ol."NetAmount",ol."TaxCode",ol."TaxRate",ol."TaxAmount",ol."TotalAmount"
    FROM rest."OrderTicketLine" ol WHERE ol."OrderTicketId"=p_pedido_id ORDER BY ol."LineNumber";
END; $$;

-- usp_Rest_OrderTicket_GetByMesaHeader
DROP FUNCTION IF EXISTS usp_rest_orderticket_getbymesaheader(INT, INT, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_getbymesaheader(p_company_id INT,p_branch_id INT,p_table_number VARCHAR(20))
RETURNS TABLE("id" INT,"clienteNombre" VARCHAR,"clienteRif" VARCHAR,"estado" VARCHAR,"total" NUMERIC)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ot."OrderTicketId",ot."CustomerName",ot."CustomerFiscalId",ot."Status",ot."TotalAmount"
    FROM rest."OrderTicket" ot WHERE ot."CompanyId"=p_company_id AND ot."BranchId"=p_branch_id
      AND ot."TableNumber"=p_table_number AND ot."Status" IN ('OPEN','SENT')
    ORDER BY ot."OrderTicketId" DESC LIMIT 1;
END; $$;

-- usp_Rest_OrderTicketLine_GetByPedido
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbypedido(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticketline_getbypedido(p_pedido_id INT)
RETURNS TABLE("id" INT,"productoId" VARCHAR,"nombre" VARCHAR,"cantidad" NUMERIC,
    "precioUnitario" NUMERIC,"subtotal" NUMERIC,"iva" NUMERIC,"taxCode" VARCHAR,
    "impuesto" NUMERIC,"total" NUMERIC)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ol."OrderTicketLineId",ol."ProductCode",ol."ProductName",ol."Quantity",
        ol."UnitPrice",ol."NetAmount",
        CASE WHEN ol."TaxRate">1 THEN ol."TaxRate" ELSE ol."TaxRate"*100 END,
        ol."TaxCode",ol."TaxAmount",ol."TotalAmount"
    FROM rest."OrderTicketLine" ol WHERE ol."OrderTicketId"=p_pedido_id ORDER BY ol."LineNumber";
END; $$;

-- usp_Rest_OrderTicket_UpdateTimestamp
DROP FUNCTION IF EXISTS usp_rest_orderticket_updatetimestamp(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_updatetimestamp(p_pedido_id INT)
RETURNS VOID LANGUAGE plpgsql AS $$ BEGIN
    UPDATE rest."OrderTicket" SET "UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "OrderTicketId"=p_pedido_id;
END; $$;


-- =============================================================================
--  SECCION 5: MOVIMIENTO INVENTARIO
-- =============================================================================

-- usp_Inv_Movement_List
DROP FUNCTION IF EXISTS usp_inv_movement_list(VARCHAR(200), VARCHAR(50), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_inv_movement_list(
    p_search VARCHAR(200) DEFAULT NULL,
    p_tipo   VARCHAR(50) DEFAULT NULL,
    p_offset INT DEFAULT 0,
    p_limit  INT DEFAULT 50
)
RETURNS TABLE(
    "MovementId" BIGINT, "Codigo" VARCHAR, "Product" VARCHAR, "Documento" VARCHAR,
    "Tipo" VARCHAR, "Fecha" TIMESTAMPTZ, "Quantity" NUMERIC, "UnitCost" NUMERIC,
    "TotalCost" NUMERIC, "Notes" VARCHAR, "TotalCount" BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryMovement"
    WHERE "IsDeleted"=FALSE
      AND (p_search IS NULL OR "ProductCode" LIKE p_search OR "ProductName" LIKE p_search OR "DocumentRef" LIKE p_search)
      AND (p_tipo IS NULL OR "MovementType"=p_tipo);

    RETURN QUERY SELECT m."MovementId",m."ProductCode",m."ProductName",m."DocumentRef",
        m."MovementType",m."MovementDate"::TIMESTAMPTZ,m."Quantity",m."UnitCost",m."TotalCost",m."Notes",v_total
    FROM master."InventoryMovement" m
    WHERE m."IsDeleted"=FALSE
      AND (p_search IS NULL OR m."ProductCode" LIKE p_search OR m."ProductName" LIKE p_search OR m."DocumentRef" LIKE p_search)
      AND (p_tipo IS NULL OR m."MovementType"=p_tipo)
    ORDER BY m."MovementDate" DESC, m."MovementId" DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- usp_Inv_Movement_GetById
DROP FUNCTION IF EXISTS usp_inv_movement_getbyid(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_inv_movement_getbyid(p_id INT)
RETURNS TABLE("MovementId" BIGINT,"Codigo" VARCHAR,"Product" VARCHAR,"Documento" VARCHAR,
    "Tipo" VARCHAR,"Fecha" TIMESTAMPTZ,"Quantity" NUMERIC,"UnitCost" NUMERIC,"TotalCost" NUMERIC,"Notes" VARCHAR)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT m."MovementId",m."ProductCode",m."ProductName",m."DocumentRef",
        m."MovementType",m."MovementDate"::TIMESTAMPTZ,m."Quantity",m."UnitCost",m."TotalCost",m."Notes"
    FROM master."InventoryMovement" m WHERE m."MovementId"=p_id AND m."IsDeleted"=FALSE;
END; $$;

-- usp_Inv_Movement_ListPeriodSummary
DROP FUNCTION IF EXISTS usp_inv_movement_listperiodsummary(VARCHAR(10), VARCHAR(60), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_inv_movement_listperiodsummary(
    p_periodo VARCHAR(10) DEFAULT NULL, p_codigo VARCHAR(60) DEFAULT NULL,
    p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE("SummaryId" INT,"Periodo" VARCHAR,"Codigo" VARCHAR,"OpeningQty" NUMERIC,
    "InboundQty" NUMERIC,"OutboundQty" NUMERIC,"ClosingQty" NUMERIC,"fecha" TIMESTAMPTZ,
    "IsClosed" BOOLEAN,"TotalCount" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM master."InventoryPeriodSummary"
    WHERE (p_periodo IS NULL OR "Period"=p_periodo) AND (p_codigo IS NULL OR "ProductCode"=p_codigo);

    RETURN QUERY SELECT s."SummaryId",s."Period",s."ProductCode",s."OpeningQty",
        s."InboundQty",s."OutboundQty",s."ClosingQty",s."SummaryDate",s."IsClosed",v_total
    FROM master."InventoryPeriodSummary" s
    WHERE (p_periodo IS NULL OR s."Period"=p_periodo) AND (p_codigo IS NULL OR s."ProductCode"=p_codigo)
    ORDER BY s."Period" DESC, s."ProductCode"
    LIMIT p_limit OFFSET p_offset;
END; $$;


-- =============================================================================
--  SECCION 6: BANCOS - CONCILIACION
-- =============================================================================

-- usp_Bank_ResolveScope
DROP FUNCTION IF EXISTS usp_bank_resolvescope() CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_resolvescope()
RETURNS TABLE("companyId" INT,"branchId" INT,"systemUserId" INT)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT c."CompanyId",b."BranchId",su."UserId"
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b ON b."CompanyId"=c."CompanyId" AND b."BranchCode"='MAIN'
    LEFT JOIN sec."User" su ON su."UserCode"='SYSTEM'
    WHERE c."CompanyCode"='DEFAULT' ORDER BY c."CompanyId",b."BranchId" LIMIT 1;
END; $$;

-- usp_Bank_ResolveUserId
DROP FUNCTION IF EXISTS usp_bank_resolveuserid(VARCHAR(60)) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_resolveuserid(p_code VARCHAR(60))
RETURNS TABLE("userId" INT) LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT u."UserId" FROM sec."User" u WHERE UPPER(u."UserCode")=UPPER(p_code) ORDER BY u."UserId" LIMIT 1;
END; $$;

-- usp_Bank_Account_GetByNumber
DROP FUNCTION IF EXISTS usp_bank_account_getbynumber(INT, VARCHAR(40)) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_account_getbynumber(p_company_id INT, p_nro_cta VARCHAR(40))
RETURNS TABLE("bankAccountId" BIGINT,"nroCta" VARCHAR,"bankName" VARCHAR,"balance" NUMERIC,"availableBalance" NUMERIC)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ba."BankAccountId",ba."AccountNumber",b."BankName",ba."Balance",ba."AvailableBalance"
    FROM fin."BankAccount" ba INNER JOIN fin."Bank" b ON b."BankId"=ba."BankId"
    WHERE ba."CompanyId"=p_company_id AND ba."AccountNumber"=p_nro_cta AND ba."IsActive"=TRUE AND b."IsActive"=TRUE
    ORDER BY ba."BankAccountId" LIMIT 1;
END; $$;

-- usp_Bank_Movement_Create
DROP FUNCTION IF EXISTS usp_bank_movement_create(BIGINT, VARCHAR(12), SMALLINT, NUMERIC(18,2), NUMERIC(18,2), VARCHAR(50), VARCHAR(255), VARCHAR(255), VARCHAR(50), VARCHAR(60), VARCHAR(20), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_movement_create(
    p_bank_account_id BIGINT, p_movement_type VARCHAR(12), p_movement_sign SMALLINT,
    p_amount NUMERIC(18,2), p_net_amount NUMERIC(18,2),
    p_reference_no VARCHAR(50) DEFAULT NULL, p_beneficiary VARCHAR(255) DEFAULT NULL,
    p_concept VARCHAR(255) DEFAULT NULL, p_category_code VARCHAR(50) DEFAULT NULL,
    p_related_document_no VARCHAR(60) DEFAULT NULL, p_related_document_type VARCHAR(20) DEFAULT NULL,
    p_created_by_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500), "movementId" INT, "newBalance" NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    v_current_balance NUMERIC(18,2); v_current_available NUMERIC(18,2);
    v_new_balance NUMERIC(18,2); v_new_available NUMERIC(18,2); v_movement_id INT;
BEGIN
    SELECT "Balance","AvailableBalance" INTO v_current_balance,v_current_available
    FROM fin."BankAccount" WHERE "BankAccountId"=p_bank_account_id FOR UPDATE;

    v_new_balance := ROUND(v_current_balance+p_net_amount,2);
    v_new_available := ROUND(COALESCE(v_current_available,v_current_balance)+p_net_amount,2);

    UPDATE fin."BankAccount" SET "Balance"=v_new_balance,"AvailableBalance"=v_new_available,
        "UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "BankAccountId"=p_bank_account_id;

    INSERT INTO fin."BankMovement" ("BankAccountId","MovementDate","MovementType","MovementSign",
        "Amount","NetAmount","ReferenceNo","Beneficiary","Concept","CategoryCode",
        "RelatedDocumentNo","RelatedDocumentType","BalanceAfter","CreatedByUserId")
    VALUES (p_bank_account_id,NOW() AT TIME ZONE 'UTC',p_movement_type,p_movement_sign,
        p_amount,p_net_amount,p_reference_no,p_beneficiary,p_concept,p_category_code,
        p_related_document_no,p_related_document_type,v_new_balance,p_created_by_user_id)
    RETURNING "BankMovementId" INTO v_movement_id;

    RETURN QUERY SELECT v_movement_id, v_new_balance::TEXT::VARCHAR(500), v_movement_id, v_new_balance;
END; $$;

-- usp_Bank_Reconciliation_GetNetTotal
DROP FUNCTION IF EXISTS usp_bank_reconciliation_getnettotal(BIGINT, DATE, DATE) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_reconciliation_getnettotal(p_bank_account_id BIGINT, p_from_date DATE, p_to_date DATE)
RETURNS TABLE("netTotal" NUMERIC) LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT COALESCE(SUM("NetAmount"),0) FROM fin."BankMovement"
    WHERE "BankAccountId"=p_bank_account_id AND ("MovementDate")::DATE BETWEEN p_from_date AND p_to_date;
END; $$;

-- usp_Bank_Reconciliation_Create
DROP FUNCTION IF EXISTS usp_bank_reconciliation_create(INT, INT, BIGINT, DATE, DATE, NUMERIC(18,2), NUMERIC(18,2), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_reconciliation_create(
    p_company_id INT, p_branch_id INT, p_bank_account_id BIGINT,
    p_from_date DATE, p_to_date DATE, p_opening NUMERIC(18,2), p_closing NUMERIC(18,2),
    p_created_by_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
    INSERT INTO fin."BankReconciliation" ("CompanyId","BranchId","BankAccountId","DateFrom","DateTo",
        "OpeningSystemBalance","ClosingSystemBalance","OpeningBankBalance","CreatedByUserId")
    VALUES (p_company_id,p_branch_id,p_bank_account_id,p_from_date,p_to_date,
        p_opening,p_closing,p_opening,p_created_by_user_id)
    RETURNING "BankReconciliationId" INTO v_id;
    RETURN QUERY SELECT v_id,'OK'::VARCHAR(500);
END; $$;

-- usp_Bank_Reconciliation_List
DROP FUNCTION IF EXISTS usp_bank_reconciliation_list(INT, VARCHAR(40), VARCHAR(30), INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_reconciliation_list(
    p_company_id INT, p_nro_cta VARCHAR(40) DEFAULT NULL, p_estado VARCHAR(30) DEFAULT NULL,
    p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE("ID" INT,"Nro_Cta" VARCHAR,"Fecha_Desde" VARCHAR,"Fecha_Hasta" VARCHAR,
    "Saldo_Inicial_Sistema" NUMERIC,"Saldo_Final_Sistema" NUMERIC,"Saldo_Inicial_Banco" NUMERIC,
    "Saldo_Final_Banco" NUMERIC,"Diferencia" NUMERIC,"Estado" VARCHAR,"Observaciones" VARCHAR,
    "Banco" VARCHAR,"Pendientes" BIGINT,"Conciliados" BIGINT,"TotalCount" BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM fin."BankReconciliation" r
    INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=r."BankAccountId"
    WHERE r."CompanyId"=p_company_id
      AND (p_nro_cta IS NULL OR ba."AccountNumber"=p_nro_cta)
      AND (p_estado IS NULL OR r."Status"=p_estado);

    RETURN QUERY SELECT r."BankReconciliationId"::INT, ba."AccountNumber",
        TO_CHAR(r."DateFrom",'YYYY-MM-DD')::VARCHAR, TO_CHAR(r."DateTo",'YYYY-MM-DD')::VARCHAR,
        r."OpeningSystemBalance",r."ClosingSystemBalance",r."OpeningBankBalance",
        r."ClosingBankBalance",r."DifferenceAmount",r."Status",r."Notes",b."BankName",
        (SELECT COUNT(1) FROM fin."BankStatementLine" s WHERE s."ReconciliationId"=r."BankReconciliationId" AND s."IsMatched"=FALSE),
        (SELECT COUNT(1) FROM fin."BankStatementLine" s WHERE s."ReconciliationId"=r."BankReconciliationId" AND s."IsMatched"=TRUE),
        v_total
    FROM fin."BankReconciliation" r
    INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=r."BankAccountId"
    INNER JOIN fin."Bank" b ON b."BankId"=ba."BankId"
    WHERE r."CompanyId"=p_company_id
      AND (p_nro_cta IS NULL OR ba."AccountNumber"=p_nro_cta)
      AND (p_estado IS NULL OR r."Status"=p_estado)
    ORDER BY r."BankReconciliationId" DESC
    LIMIT p_limit OFFSET p_offset;
END; $$;

-- usp_Bank_Reconciliation_GetById
DROP FUNCTION IF EXISTS usp_bank_reconciliation_getbyid(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_reconciliation_getbyid(p_company_id INT, p_id INT)
RETURNS TABLE("ID" INT,"Nro_Cta" VARCHAR,"Fecha_Desde" VARCHAR,"Fecha_Hasta" VARCHAR,
    "Saldo_Inicial_Sistema" NUMERIC,"Saldo_Final_Sistema" NUMERIC,"Saldo_Inicial_Banco" NUMERIC,
    "Saldo_Final_Banco" NUMERIC,"Diferencia" NUMERIC,"Estado" VARCHAR,"Observaciones" VARCHAR,"Banco" VARCHAR)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT r."BankReconciliationId"::INT, ba."AccountNumber",
        TO_CHAR(r."DateFrom",'YYYY-MM-DD')::VARCHAR, TO_CHAR(r."DateTo",'YYYY-MM-DD')::VARCHAR,
        r."OpeningSystemBalance",r."ClosingSystemBalance",r."OpeningBankBalance",
        r."ClosingBankBalance",r."DifferenceAmount",r."Status",r."Notes",b."BankName"
    FROM fin."BankReconciliation" r
    INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=r."BankAccountId"
    INNER JOIN fin."Bank" b ON b."BankId"=ba."BankId"
    WHERE r."CompanyId"=p_company_id AND r."BankReconciliationId"=p_id LIMIT 1;
END; $$;

-- usp_Bank_Reconciliation_GetSystemMovements
DROP FUNCTION IF EXISTS usp_bank_reconciliation_getsystemmovements(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_reconciliation_getsystemmovements(p_id INT)
RETURNS TABLE("id" BIGINT,"Fecha" TIMESTAMPTZ,"Tipo" VARCHAR,"Nro_Ref" VARCHAR,
    "Beneficiario" VARCHAR,"Concepto" VARCHAR,"Monto" NUMERIC,"MontoNeto" NUMERIC,
    "SaldoPosterior" NUMERIC,"Conciliado" BOOLEAN)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT m."BankMovementId",m."MovementDate",m."MovementType",m."ReferenceNo",
        m."Beneficiary",m."Concept",m."Amount",m."NetAmount",m."BalanceAfter",m."IsReconciled"
    FROM fin."BankMovement" m
    INNER JOIN fin."BankReconciliation" r ON r."BankAccountId"=m."BankAccountId"
    WHERE r."BankReconciliationId"=p_id AND (m."MovementDate")::DATE BETWEEN r."DateFrom" AND r."DateTo"
    ORDER BY m."MovementDate" DESC, m."BankMovementId" DESC;
END; $$;

-- usp_Bank_Reconciliation_GetPendingStatements
DROP FUNCTION IF EXISTS usp_bank_reconciliation_getpendingstatements(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_reconciliation_getpendingstatements(p_id INT)
RETURNS TABLE("id" BIGINT,"Fecha" TIMESTAMPTZ,"Descripcion" VARCHAR,"Referencia" VARCHAR,
    "Tipo" VARCHAR,"Monto" NUMERIC,"Saldo" NUMERIC)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT sl."StatementLineId",sl."StatementDate",sl."DescriptionText",sl."ReferenceNo",
        sl."EntryType",sl."Amount",sl."Balance"
    FROM fin."BankStatementLine" sl WHERE sl."ReconciliationId"=p_id AND sl."IsMatched"=FALSE
    ORDER BY sl."StatementDate" DESC, sl."StatementLineId" DESC;
END; $$;

-- usp_Bank_Reconciliation_GetOpenForAccount
DROP FUNCTION IF EXISTS usp_bank_reconciliation_getopenforaccount(INT, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_reconciliation_getopenforaccount(p_company_id INT, p_bank_account_id BIGINT)
RETURNS TABLE("id" INT) LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT br."BankReconciliationId" FROM fin."BankReconciliation" br
    WHERE br."CompanyId"=p_company_id AND br."BankAccountId"=p_bank_account_id AND br."Status"='OPEN'
    ORDER BY br."BankReconciliationId" DESC LIMIT 1;
END; $$;

-- usp_Bank_StatementLine_Insert
DROP FUNCTION IF EXISTS usp_bank_statementline_insert(BIGINT, TIMESTAMPTZ, VARCHAR(255), VARCHAR(50), VARCHAR(12), NUMERIC(18,2), NUMERIC(18,2), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_statementline_insert(
    p_reconciliation_id BIGINT, p_statement_date TIMESTAMPTZ,
    p_description_text VARCHAR(255) DEFAULT NULL, p_reference_no VARCHAR(50) DEFAULT NULL,
    p_entry_type VARCHAR(12) DEFAULT NULL, p_amount NUMERIC(18,2) DEFAULT NULL,
    p_balance NUMERIC(18,2) DEFAULT NULL, p_created_by_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
    INSERT INTO fin."BankStatementLine" ("ReconciliationId","StatementDate","DescriptionText","ReferenceNo",
        "EntryType","Amount","Balance","CreatedByUserId")
    VALUES (p_reconciliation_id,p_statement_date,p_description_text,p_reference_no,
        p_entry_type,p_amount,p_balance,p_created_by_user_id)
    RETURNING "StatementLineId" INTO v_id;
    RETURN QUERY SELECT v_id,'OK'::VARCHAR(500);
END; $$;

-- usp_Bank_Reconciliation_MatchMovement
DROP FUNCTION IF EXISTS usp_bank_reconciliation_matchmovement(BIGINT, BIGINT, BIGINT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_reconciliation_matchmovement(
    p_reconciliation_id BIGINT, p_movement_id BIGINT,
    p_statement_id BIGINT DEFAULT NULL, p_matched_by_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500))
LANGUAGE plpgsql AS $$
DECLARE
    v_account_id BIGINT; v_expected_type VARCHAR(12); v_move_amount NUMERIC(18,2);
BEGIN
    SELECT br."BankAccountId" INTO v_account_id FROM fin."BankReconciliation" br
    WHERE br."BankReconciliationId"=p_reconciliation_id LIMIT 1;

    IF v_account_id IS NULL THEN
        RETURN QUERY SELECT 0,'Conciliacion no encontrada'::VARCHAR(500); RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM fin."BankMovement" WHERE "BankMovementId"=p_movement_id AND "BankAccountId"=v_account_id) THEN
        RETURN QUERY SELECT 0,'Movimiento no encontrado'::VARCHAR(500); RETURN;
    END IF;

    IF p_statement_id IS NULL OR p_statement_id=0 THEN
        SELECT CASE WHEN "MovementSign"<0 THEN 'DEBITO' ELSE 'CREDITO' END, "Amount"
        INTO v_expected_type, v_move_amount FROM fin."BankMovement" WHERE "BankMovementId"=p_movement_id LIMIT 1;

        SELECT sl."StatementLineId" INTO p_statement_id FROM fin."BankStatementLine" sl
        WHERE sl."ReconciliationId"=p_reconciliation_id AND sl."IsMatched"=FALSE
          AND sl."EntryType"=v_expected_type AND ABS(sl."Amount"-v_move_amount)<=0.01
        ORDER BY sl."StatementDate", sl."StatementLineId" LIMIT 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM fin."BankReconciliationMatch"
        WHERE "ReconciliationId"=p_reconciliation_id AND "BankMovementId"=p_movement_id) THEN
        INSERT INTO fin."BankReconciliationMatch" ("ReconciliationId","BankMovementId","StatementLineId","MatchedByUserId")
        VALUES (p_reconciliation_id, p_movement_id,
                CASE WHEN p_statement_id>0 THEN p_statement_id ELSE NULL END, p_matched_by_user_id);
    END IF;

    UPDATE fin."BankMovement" SET "IsReconciled"=TRUE,"ReconciledAt"=NOW() AT TIME ZONE 'UTC',
        "ReconciliationId"=p_reconciliation_id WHERE "BankMovementId"=p_movement_id;

    IF p_statement_id IS NOT NULL AND p_statement_id>0 THEN
        UPDATE fin."BankStatementLine" SET "IsMatched"=TRUE,"MatchedAt"=NOW() AT TIME ZONE 'UTC'
        WHERE "StatementLineId"=p_statement_id;
    END IF;

    RETURN QUERY SELECT 1,'Movimiento conciliado'::VARCHAR(500);
END; $$;

-- usp_Bank_Reconciliation_GetAccountNoById
DROP FUNCTION IF EXISTS usp_bank_reconciliation_getaccountnobyid(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_reconciliation_getaccountnobyid(p_id INT)
RETURNS TABLE("accountNo" VARCHAR) LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ba."AccountNumber" FROM fin."BankReconciliation" r
    INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=r."BankAccountId"
    WHERE r."BankReconciliationId"=p_id LIMIT 1;
END; $$;

-- usp_Bank_Reconciliation_Close
DROP FUNCTION IF EXISTS usp_bank_reconciliation_close(INT, NUMERIC(18,2), VARCHAR(500), INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_reconciliation_close(
    p_id INT, p_bank_closing NUMERIC(18,2), p_notes VARCHAR(500) DEFAULT NULL,
    p_closed_by_user_id INT DEFAULT NULL
)
RETURNS TABLE("Resultado" INT, "Mensaje" VARCHAR(500), "diferencia" NUMERIC, "estado" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_bank_account_id BIGINT; v_system_closing NUMERIC(18,2);
    v_difference NUMERIC(18,2); v_status VARCHAR(30);
BEGIN
    SELECT br."BankAccountId" INTO v_bank_account_id FROM fin."BankReconciliation" br
    WHERE br."BankReconciliationId"=p_id LIMIT 1;

    IF v_bank_account_id IS NULL THEN
        RETURN QUERY SELECT 0,'Conciliacion no encontrada'::VARCHAR(500),0::NUMERIC,''::VARCHAR; RETURN;
    END IF;

    SELECT ba."Balance" INTO v_system_closing FROM fin."BankAccount" ba
    WHERE ba."BankAccountId"=v_bank_account_id LIMIT 1;

    v_difference := ROUND(p_bank_closing-v_system_closing,2);
    v_status := CASE WHEN ABS(v_difference)<=0.01 THEN 'CLOSED' ELSE 'CLOSED_WITH_DIFF' END;

    UPDATE fin."BankReconciliation" SET "ClosingSystemBalance"=v_system_closing,
        "ClosingBankBalance"=p_bank_closing,"DifferenceAmount"=v_difference,"Status"=v_status,
        "Notes"=COALESCE(p_notes,"Notes"),"ClosedAt"=NOW() AT TIME ZONE 'UTC',
        "ClosedByUserId"=p_closed_by_user_id,"UpdatedAt"=NOW() AT TIME ZONE 'UTC'
    WHERE "BankReconciliationId"=p_id;

    RETURN QUERY SELECT 1,'OK'::VARCHAR(500),v_difference,v_status;
END; $$;

-- usp_Bank_Account_List
DROP FUNCTION IF EXISTS usp_bank_account_list(INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_account_list(p_company_id INT)
RETURNS TABLE("Nro_Cta" VARCHAR,"Banco" VARCHAR,"Descripcion" VARCHAR,"Moneda" VARCHAR,
    "Saldo" NUMERIC,"Saldo_Disponible" NUMERIC,"BancoNombre" VARCHAR)
LANGUAGE plpgsql AS $$ BEGIN
    RETURN QUERY SELECT ba."AccountNumber",b."BankName",ba."AccountName",ba."CurrencyCode"::VARCHAR,
        ba."Balance",ba."AvailableBalance",b."BankName"
    FROM fin."BankAccount" ba INNER JOIN fin."Bank" b ON b."BankId"=ba."BankId"
    WHERE ba."CompanyId"=p_company_id AND ba."IsActive"=TRUE AND b."IsActive"=TRUE
    ORDER BY b."BankName",ba."AccountNumber";
END; $$;

-- usp_Bank_Movement_ListByAccount
DROP FUNCTION IF EXISTS usp_bank_movement_listbyaccount(INT, VARCHAR(40), DATE, DATE, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_bank_movement_listbyaccount(
    p_company_id INT, p_nro_cta VARCHAR(40),
    p_from_date DATE DEFAULT NULL, p_to_date DATE DEFAULT NULL,
    p_offset INT DEFAULT 0, p_limit INT DEFAULT 50
)
RETURNS TABLE(
    "id" BIGINT,"Nro_Cta" VARCHAR,"Fecha" TIMESTAMPTZ,"Tipo" VARCHAR,"Nro_Ref" VARCHAR,
    "Beneficiario" VARCHAR,"Monto" NUMERIC,"MontoNeto" NUMERIC,"Concepto" VARCHAR,
    "Categoria" VARCHAR,"Documento_Relacionado" VARCHAR,"Tipo_Doc_Rel" VARCHAR,
    "SaldoPosterior" NUMERIC,"Conciliado" BOOLEAN,"TotalCount" BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE v_total BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total FROM fin."BankMovement" m
    INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=m."BankAccountId"
    WHERE ba."CompanyId"=p_company_id AND ba."AccountNumber"=p_nro_cta
      AND (p_from_date IS NULL OR m."MovementDate">=p_from_date)
      AND (p_to_date IS NULL OR m."MovementDate"<=p_to_date);

    RETURN QUERY SELECT m."BankMovementId",ba."AccountNumber",m."MovementDate"::TIMESTAMPTZ,m."MovementType",
        m."ReferenceNo",m."Beneficiary",m."Amount",m."NetAmount",m."Concept",m."CategoryCode",
        m."RelatedDocumentNo",m."RelatedDocumentType",m."BalanceAfter",m."IsReconciled",v_total
    FROM fin."BankMovement" m INNER JOIN fin."BankAccount" ba ON ba."BankAccountId"=m."BankAccountId"
    WHERE ba."CompanyId"=p_company_id AND ba."AccountNumber"=p_nro_cta
      AND (p_from_date IS NULL OR m."MovementDate">=p_from_date)
      AND (p_to_date IS NULL OR m."MovementDate"<=p_to_date)
    ORDER BY m."MovementDate" DESC, m."BankMovementId" DESC
    LIMIT p_limit OFFSET p_offset;
END; $$;

-- Verificacion
DO $$ BEGIN RAISE NOTICE '>>> usp_ops.sql ejecutado correctamente <<<'; END $$;
