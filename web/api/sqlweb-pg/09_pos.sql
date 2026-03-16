-- usp_pos_categorias_list
CREATE OR REPLACE FUNCTION public.usp_pos_categorias_list()
 RETURNS TABLE(id character varying, nombre character varying, "productCount" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        RTRIM(COALESCE(i."Categoria", '(Sin Categoria)')),
        RTRIM(COALESCE(i."Categoria", '(Sin Categoria)')),
        COUNT(1)
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
      AND (i."StockQty" > 0 OR i."IsService" = TRUE)
    GROUP BY i."Categoria"
    ORDER BY i."Categoria";
END;
$function$
;

-- usp_pos_category_list
CREATE OR REPLACE FUNCTION public.usp_pos_category_list(p_company_id integer)
 RETURNS TABLE(id character varying, nombre character varying, "productCount" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(NULLIF(TRIM("CategoryCode"), ''), '(Sin Categoria)')::character varying::VARCHAR,
        COALESCE(NULLIF(TRIM("CategoryCode"), ''), '(Sin Categoria)')::character varying::VARCHAR,
        COUNT(1)
    FROM master."Product"
    WHERE "CompanyId" = p_company_id
      AND "IsDeleted" = FALSE AND "IsActive" = TRUE
      AND ("StockQty" > 0 OR "IsService" = TRUE)
    GROUP BY COALESCE(NULLIF(TRIM("CategoryCode"), ''), '(Sin Categoria)')::character varying
    ORDER BY COALESCE(NULLIF(TRIM("CategoryCode"), ''), '(Sin Categoria)')::character varying;
END;
$function$
;

-- usp_pos_clientes_search
CREATE OR REPLACE FUNCTION public.usp_pos_clientes_search(p_search character varying DEFAULT NULL::character varying, p_limit integer DEFAULT 20)
 RETURNS TABLE(id character varying, codigo character varying, nombre character varying, rif character varying, telefono character varying, email character varying, direccion character varying, "tipoPrecio" character varying, credito numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        c."CustomerCode",
        c."CustomerCode",
        c."CustomerName",
        c."FiscalId",
        c."TELEFONO",
        c."EMAIL",
        c."DIRECCION",
        COALESCE(c."LISTA_PRECIO", 'Detal'),
        COALESCE(c."CreditLimit", 0)
    FROM master."Customer" c
    WHERE COALESCE(c."IsDeleted", FALSE) = FALSE
      AND (
           p_search IS NULL
        OR c."CustomerCode" ILIKE '%' || p_search || '%'
        OR c."CustomerName" ILIKE '%' || p_search || '%'
        OR c."FiscalId" ILIKE '%' || p_search || '%'
      )
    ORDER BY c."CustomerName"
    LIMIT p_limit;
END;
$function$
;

-- usp_pos_customer_search
CREATE OR REPLACE FUNCTION public.usp_pos_customer_search(p_company_id integer, p_search character varying DEFAULT NULL::character varying, p_limit integer DEFAULT 20)
 RETURNS TABLE(id bigint, codigo character varying, nombre character varying, rif character varying, telefono character varying, email character varying, direccion character varying, "tipoPrecio" character varying, credito numeric)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pos_espera_anular
CREATE OR REPLACE FUNCTION public.usp_pos_espera_anular(p_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE "PosVentasEnEspera" SET "Estado" = 'anulado' WHERE "Id" = p_id AND "Estado" = 'espera';
END;
$function$
;

-- usp_pos_espera_crear
CREATE OR REPLACE FUNCTION public.usp_pos_espera_crear(p_caja_id character varying, p_estacion_nombre character varying DEFAULT NULL::character varying, p_cod_usuario character varying DEFAULT NULL::character varying, p_cliente_id character varying DEFAULT NULL::character varying, p_cliente_nombre character varying DEFAULT NULL::character varying, p_cliente_rif character varying DEFAULT NULL::character varying, p_tipo_precio character varying DEFAULT 'Detal'::character varying, p_motivo character varying DEFAULT NULL::character varying, p_detalle_json jsonb DEFAULT '[]'::jsonb)
 RETURNS TABLE("EsperaId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_espera_id INT;
BEGIN
    INSERT INTO "PosVentasEnEspera" ("CajaId", "EstacionNombre", "CodUsuario", "ClienteId", "ClienteNombre", "ClienteRif", "TipoPrecio", "Motivo")
    VALUES (p_caja_id, p_estacion_nombre, p_cod_usuario, p_cliente_id, p_cliente_nombre, p_cliente_rif, p_tipo_precio, p_motivo)
    RETURNING "Id" INTO v_espera_id;

    INSERT INTO "PosVentasEnEsperaDetalle" ("VentaEsperaId", "ProductoId", "Codigo", "Nombre", "Cantidad", "PrecioUnitario", "Descuento", "IVA", "Subtotal", "Orden")
    SELECT
        v_espera_id,
        (item->>'prodId')::VARCHAR(15),
        (item->>'cod')::VARCHAR(30),
        (item->>'nom')::VARCHAR(200),
        (item->>'cant')::NUMERIC(10,3),
        (item->>'precio')::NUMERIC(18,2),
        COALESCE((item->>'desc')::NUMERIC(18,2), 0),
        COALESCE((item->>'iva')::NUMERIC(5,2), 16),
        (item->>'sub')::NUMERIC(18,2),
        COALESCE((item->>'ord')::INT, 0)
    FROM jsonb_array_elements(p_detalle_json) AS item;

    -- Calcular totales
    UPDATE "PosVentasEnEspera" SET
        "Subtotal"  = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id),
        "Descuento" = (SELECT COALESCE(SUM("Descuento" * "Cantidad"), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id),
        "Impuestos" = (SELECT COALESCE(SUM("Subtotal" * "IVA" / 100), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id),
        "Total"     = (SELECT COALESCE(SUM("Subtotal" + "Subtotal" * "IVA" / 100), 0) FROM "PosVentasEnEsperaDetalle" WHERE "VentaEsperaId" = v_espera_id)
    WHERE "Id" = v_espera_id;

    RETURN QUERY SELECT v_espera_id AS "EsperaId";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- usp_pos_espera_list
CREATE OR REPLACE FUNCTION public.usp_pos_espera_list()
 RETURNS TABLE(id integer, "cajaId" character varying, "estacionNombre" character varying, "codUsuario" character varying, "clienteNombre" character varying, "clienteRif" character varying, "tipoPrecio" character varying, motivo character varying, total numeric, "fechaCreacion" timestamp without time zone, "cantItems" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        e."Id",
        e."CajaId",
        e."EstacionNombre",
        e."CodUsuario",
        e."ClienteNombre",
        e."ClienteRif",
        e."TipoPrecio",
        e."Motivo",
        e."Total",
        e."FechaCreacion",
        (SELECT COUNT(1) FROM "PosVentasEnEsperaDetalle" d WHERE d."VentaEsperaId" = e."Id")
    FROM "PosVentasEnEspera" e
    WHERE e."Estado" = 'espera'
    ORDER BY e."FechaCreacion" ASC;
END;
$function$
;

-- usp_pos_espera_recuperar_detalle
CREATE OR REPLACE FUNCTION public.usp_pos_espera_recuperar_detalle(p_id integer)
 RETURNS TABLE(id integer, "productoId" character varying, codigo character varying, nombre character varying, cantidad numeric, "precioUnitario" numeric, descuento numeric, iva numeric, subtotal numeric, orden integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        d."Id", d."ProductoId", d."Codigo",
        d."Nombre", d."Cantidad", d."PrecioUnitario",
        d."Descuento", d."IVA", d."Subtotal", d."Orden"
    FROM "PosVentasEnEsperaDetalle" d
    WHERE d."VentaEsperaId" = p_id
    ORDER BY d."Orden";
END;
$function$
;

-- usp_pos_espera_recuperar_header
CREATE OR REPLACE FUNCTION public.usp_pos_espera_recuperar_header(p_id integer, p_recuperado_por character varying DEFAULT NULL::character varying, p_recuperado_en character varying DEFAULT NULL::character varying)
 RETURNS TABLE(id integer, "cajaId" character varying, "clienteId" character varying, "clienteNombre" character varying, "clienteRif" character varying, "tipoPrecio" character varying, motivo character varying, subtotal numeric, descuento numeric, impuestos numeric, total numeric, "fechaCreacion" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        e."Id", e."CajaId", e."ClienteId",
        e."ClienteNombre", e."ClienteRif",
        e."TipoPrecio", e."Motivo",
        e."Subtotal", e."Descuento",
        e."Impuestos", e."Total", e."FechaCreacion"
    FROM "PosVentasEnEspera" e
    WHERE e."Id" = p_id AND e."Estado" = 'espera';

    -- Marcar como recuperado
    UPDATE "PosVentasEnEspera" SET
        "Estado" = 'recuperado',
        "RecuperadoPor" = p_recuperado_por,
        "RecuperadoEn" = p_recuperado_en,
        "FechaRecuperado" = NOW() AT TIME ZONE 'UTC'
    WHERE "Id" = p_id AND "Estado" = 'espera';
END;
$function$
;

-- usp_pos_fiscalcorrelative_list
CREATE OR REPLACE FUNCTION public.usp_pos_fiscalcorrelative_list(p_company_id integer, p_branch_id integer, p_caja_id character varying DEFAULT NULL::character varying)
 RETURNS TABLE(tipo character varying, "cajaId" character varying, "serialFiscal" character varying, "correlativoActual" integer, descripcion character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pos_fiscalcorrelative_upsert
CREATE OR REPLACE FUNCTION public.usp_pos_fiscalcorrelative_upsert(p_company_id integer, p_branch_id integer, p_caja_id character varying, p_serial_fiscal character varying, p_correlativo_actual integer DEFAULT 0, p_descripcion character varying DEFAULT ''::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pos_loadcountrytaxrates
CREATE OR REPLACE FUNCTION public.usp_pos_loadcountrytaxrates(p_country_code character varying)
 RETURNS TABLE("taxCode" character varying, rate numeric, "isDefault" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT tr."TaxCode", tr."Rate", tr."IsDefault"
    FROM fiscal."TaxRate" tr
    WHERE tr."CountryCode" = p_country_code
      AND tr."IsActive" = TRUE
    ORDER BY tr."IsDefault" DESC, tr."SortOrder", tr."TaxCode";
END;
$function$
;

-- usp_pos_product_getbycode
CREATE OR REPLACE FUNCTION public.usp_pos_product_getbycode(p_company_id integer, p_branch_id integer, p_codigo character varying)
 RETURNS TABLE(id bigint, codigo character varying, nombre character varying, imagen character varying, "precioDetal" numeric, existencia numeric, categoria character varying, iva numeric)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pos_product_list
CREATE OR REPLACE FUNCTION public.usp_pos_product_list(p_company_id integer, p_branch_id integer, p_search character varying DEFAULT NULL::character varying, p_categoria character varying DEFAULT NULL::character varying, p_offset integer DEFAULT 0, p_limit integer DEFAULT 50)
 RETURNS TABLE(id bigint, codigo character varying, nombre character varying, imagen character varying, "precioDetal" numeric, existencia numeric, categoria character varying, iva numeric, "TotalCount" bigint)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pos_producto_get_by_codigo
CREATE OR REPLACE FUNCTION public.usp_pos_producto_get_by_codigo(p_codigo character varying)
 RETURNS TABLE(id character varying, codigo character varying, nombre character varying, "precioDetal" numeric, "precioMayor" numeric, "precioDistribuidor" numeric, existencia numeric, categoria character varying, iva numeric, barra character varying, referencia character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        i."ProductCode",
        i."ProductCode",
        TRIM(
            COALESCE(RTRIM(i."Categoria"), '') ||
            CASE WHEN RTRIM(COALESCE(i."Tipo", '')) <> '' THEN ' ' || RTRIM(i."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."ProductName", '')) <> '' THEN ' ' || RTRIM(i."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Marca", '')) <> '' THEN ' ' || RTRIM(i."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Clase", '')) <> '' THEN ' ' || RTRIM(i."Clase") ELSE '' END
        ),
        i."SalesPrice",
        COALESCE(i."PRECIO_VENTA2", i."SalesPrice" * 0.90),
        COALESCE(i."PRECIO_VENTA3", i."SalesPrice" * 0.80),
        i."StockQty",
        i."Categoria",
        COALESCE(i."PORCENTAJE", 16),
        i."Barra",
        i."Referencia"
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
      AND (
           i."ProductCode" = p_codigo
        OR i."Barra" = p_codigo
        OR i."Referencia" = p_codigo
      )
    LIMIT 1;
END;
$function$
;

-- usp_pos_productos_list
CREATE OR REPLACE FUNCTION public.usp_pos_productos_list(p_search character varying DEFAULT NULL::character varying, p_categoria character varying DEFAULT NULL::character varying, p_almacen_id character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, id character varying, codigo character varying, nombre character varying, "precioDetal" numeric, "precioMayor" numeric, "precioDistribuidor" numeric, existencia numeric, categoria character varying, iva numeric, barra character varying, referencia character varying, "esServicio" boolean, "costoPromedio" numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset INT := (p_page - 1) * p_limit;
    v_total  BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
      AND (i."StockQty" > 0 OR i."IsService" = TRUE)
      AND (p_search IS NULL
           OR i."ProductCode" ILIKE '%' || p_search || '%'
           OR i."ProductName" ILIKE '%' || p_search || '%'
           OR i."Referencia" ILIKE '%' || p_search || '%'
           OR i."Barra" ILIKE '%' || p_search || '%'
           OR i."Categoria" ILIKE '%' || p_search || '%')
      AND (p_categoria IS NULL OR i."Categoria" = p_categoria);

    RETURN QUERY
    SELECT
        v_total,
        i."ProductCode",
        i."ProductCode",
        TRIM(
            COALESCE(RTRIM(i."Categoria"), '') ||
            CASE WHEN RTRIM(COALESCE(i."Tipo", '')) <> '' THEN ' ' || RTRIM(i."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."ProductName", '')) <> '' THEN ' ' || RTRIM(i."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Marca", '')) <> '' THEN ' ' || RTRIM(i."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(i."Clase", '')) <> '' THEN ' ' || RTRIM(i."Clase") ELSE '' END
        ),
        i."SalesPrice",
        COALESCE(i."PRECIO_VENTA2", i."SalesPrice" * 0.90),
        COALESCE(i."PRECIO_VENTA3", i."SalesPrice" * 0.80),
        i."StockQty",
        i."Categoria",
        COALESCE(i."PORCENTAJE", 16),
        i."Barra",
        i."Referencia",
        i."IsService",
        COALESCE(i."CostPrice", 0)
    FROM master."Product" i
    WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
      AND (i."StockQty" > 0 OR i."IsService" = TRUE)
      AND (p_search IS NULL
           OR i."ProductCode" ILIKE '%' || p_search || '%'
           OR i."ProductName" ILIKE '%' || p_search || '%'
           OR i."Referencia" ILIKE '%' || p_search || '%'
           OR i."Barra" ILIKE '%' || p_search || '%'
           OR i."Categoria" ILIKE '%' || p_search || '%')
      AND (p_categoria IS NULL OR i."Categoria" = p_categoria)
    ORDER BY i."ProductCode"
    LIMIT p_limit OFFSET v_offset;
END;
$function$
;

-- usp_pos_report_cajas
CREATE OR REPLACE FUNCTION public.usp_pos_report_cajas(p_company_id integer, p_branch_id integer, p_from_date date, p_to_date date)
 RETURNS TABLE("cajaId" character varying, transacciones bigint, total numeric, "serialFiscal" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        UPPER(v."CashRegisterCode")::character varying::VARCHAR,
        COUNT(1),
        SUM(v."TotalAmount"),
        MAX(COALESCE(corr."SerialFiscal", ''))::VARCHAR
    FROM pos."SaleTicket" v
    LEFT JOIN LATERAL (
        SELECT fc."SerialFiscal"
        FROM pos."FiscalCorrelative" fc
        WHERE fc."CompanyId" = v."CompanyId" AND fc."BranchId" = v."BranchId"
          AND fc."CorrelativeType" = 'FACTURA' AND fc."IsActive" = TRUE
          AND fc."CashRegisterCode" IN (UPPER(v."CashRegisterCode")::character varying, 'GLOBAL')
        ORDER BY CASE WHEN fc."CashRegisterCode" = UPPER(v."CashRegisterCode")::character varying THEN 0 ELSE 1 END,
                 fc."FiscalCorrelativeId" DESC
        LIMIT 1
    ) corr ON TRUE
    WHERE v."CompanyId" = p_company_id AND v."BranchId" = p_branch_id
      AND (v."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
    GROUP BY UPPER(v."CashRegisterCode")::character varying
    ORDER BY UPPER(v."CashRegisterCode")::character varying;
END;
$function$
;

-- usp_pos_report_formaspago
CREATE OR REPLACE FUNCTION public.usp_pos_report_formaspago(p_company_id integer, p_branch_id integer, p_from_date date, p_to_date date, p_caja_id character varying DEFAULT NULL::character varying)
 RETURNS TABLE("metodoPago" character varying, transacciones bigint, total numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(NULLIF(TRIM(v."PaymentMethod"), ''), 'No especificado')::character varying::VARCHAR,
        COUNT(1),
        SUM(v."TotalAmount")
    FROM pos."SaleTicket" v
    WHERE v."CompanyId" = p_company_id AND v."BranchId" = p_branch_id
      AND (v."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
      AND (p_caja_id IS NULL OR UPPER(v."CashRegisterCode")::character varying = p_caja_id)
    GROUP BY COALESCE(NULLIF(TRIM(v."PaymentMethod"), ''), 'No especificado')::character varying
    ORDER BY SUM(v."TotalAmount") DESC;
END;
$function$
;

-- usp_pos_report_productostop
CREATE OR REPLACE FUNCTION public.usp_pos_report_productostop(p_company_id integer, p_branch_id integer, p_from_date date, p_to_date date, p_caja_id character varying DEFAULT NULL::character varying, p_limit integer DEFAULT 20)
 RETURNS TABLE("productoId" integer, codigo character varying, nombre character varying, cantidad numeric, total numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT l."ProductId", l."ProductCode", l."ProductName",
           SUM(l."Quantity"), SUM(l."TotalAmount")
    FROM pos."SaleTicketLine" l
    INNER JOIN pos."SaleTicket" v ON v."SaleTicketId" = l."SaleTicketId"
    WHERE v."CompanyId" = p_company_id AND v."BranchId" = p_branch_id
      AND (v."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
      AND (p_caja_id IS NULL OR UPPER(v."CashRegisterCode")::character varying = p_caja_id)
    GROUP BY l."ProductId", l."ProductCode", l."ProductName"
    ORDER BY SUM(l."TotalAmount") DESC, SUM(l."Quantity") DESC
    LIMIT p_limit;
END;
$function$
;

-- usp_pos_report_resumen
CREATE OR REPLACE FUNCTION public.usp_pos_report_resumen(p_company_id integer, p_branch_id integer, p_from_date date, p_to_date date, p_caja_id character varying DEFAULT NULL::character varying)
 RETURNS TABLE("totalVentas" numeric, transacciones bigint, "productosVendidos" numeric, "productosDiferentes" bigint, "ticketPromedio" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH ventas AS (
        SELECT st."SaleTicketId", st."TotalAmount"
        FROM pos."SaleTicket" st
        WHERE st."CompanyId" = p_company_id AND st."BranchId" = p_branch_id
          AND (st."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
          AND (p_caja_id IS NULL OR UPPER(st."CashRegisterCode")::character varying = p_caja_id)
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
$function$
;

-- usp_pos_report_ventas
CREATE OR REPLACE FUNCTION public.usp_pos_report_ventas(p_company_id integer, p_branch_id integer, p_from_date date, p_to_date date, p_caja_id character varying DEFAULT NULL::character varying, p_limit integer DEFAULT 200)
 RETURNS TABLE(id integer, "numFactura" character varying, fecha timestamp with time zone, cliente character varying, "cajaId" character varying, total numeric, estado character varying, "metodoPago" character varying, "tramaFiscal" character varying, "serialFiscal" character varying, "correlativoFiscal" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        v."SaleTicketId",
        v."InvoiceNumber",
        v."SoldAt",
        COALESCE(NULLIF(TRIM(v."CustomerName"), ''), 'Consumidor Final')::character varying::VARCHAR,
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
          AND fc."CashRegisterCode" IN (UPPER(v."CashRegisterCode")::character varying, 'GLOBAL')
        ORDER BY CASE WHEN fc."CashRegisterCode" = UPPER(v."CashRegisterCode")::character varying THEN 0 ELSE 1 END,
                 fc."FiscalCorrelativeId" DESC
        LIMIT 1
    ) corr ON TRUE
    WHERE v."CompanyId" = p_company_id AND v."BranchId" = p_branch_id
      AND (v."SoldAt")::DATE BETWEEN p_from_date AND p_to_date
      AND (p_caja_id IS NULL OR UPPER(v."CashRegisterCode")::character varying = p_caja_id)
    ORDER BY v."SoldAt" DESC, v."SaleTicketId" DESC
    LIMIT p_limit;
END;
$function$
;

-- usp_pos_resolvecustomerbyid
CREATE OR REPLACE FUNCTION public.usp_pos_resolvecustomerbyid(p_company_id integer, p_id_input character varying)
 RETURNS TABLE("customerId" bigint, "customerCode" character varying, "customerName" character varying, "fiscalId" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pos_resolvecustomerbyrif
CREATE OR REPLACE FUNCTION public.usp_pos_resolvecustomerbyrif(p_company_id integer, p_rif character varying)
 RETURNS TABLE("customerId" bigint, "customerCode" character varying, "customerName" character varying, "fiscalId" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pos_resolvedefaultscope
CREATE OR REPLACE FUNCTION public.usp_pos_resolvedefaultscope()
 RETURNS TABLE("companyId" integer, "branchId" integer, "countryCode" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        c."CompanyId",
        b."BranchId",
        UPPER(COALESCE(NULLIF(b."CountryCode", ''::character varying), c."FiscalCountryCode")::character varying)::character varying::VARCHAR
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId"
    WHERE c."CompanyCode" = 'DEFAULT'
      AND b."BranchCode"  = 'MAIN'
    ORDER BY c."CompanyId", b."BranchId"
    LIMIT 1;
END;
$function$
;

-- usp_pos_resolveproduct
CREATE OR REPLACE FUNCTION public.usp_pos_resolveproduct(p_company_id integer, p_identifier character varying)
 RETURNS TABLE("productId" bigint, "productCode" character varying, "productName" character varying, "defaultTaxCode" character varying, "defaultTaxRate" numeric)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pos_resolveuserid
CREATE OR REPLACE FUNCTION public.usp_pos_resolveuserid(p_user_code character varying)
 RETURNS TABLE("userId" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u."UserId"
    FROM sec."User" u
    WHERE UPPER(u."UserCode")::character varying = UPPER(p_user_code)::character varying
      AND u."IsDeleted" = FALSE
      AND u."IsActive"  = TRUE
    LIMIT 1;
END;
$function$
;

-- usp_pos_saleticket_create
CREATE OR REPLACE FUNCTION public.usp_pos_saleticket_create(p_company_id integer, p_branch_id integer, p_country_code character varying, p_invoice_number character varying, p_cash_register_code character varying, p_sold_by_user_id integer DEFAULT NULL::integer, p_customer_id integer DEFAULT NULL::integer, p_customer_code character varying DEFAULT NULL::character varying, p_customer_name character varying DEFAULT NULL::character varying, p_customer_fiscal_id character varying DEFAULT NULL::character varying, p_price_tier character varying DEFAULT 'Detal'::character varying, p_payment_method character varying DEFAULT NULL::character varying, p_fiscal_payload text DEFAULT NULL::text, p_wait_ticket_id integer DEFAULT NULL::integer, p_net_amount numeric DEFAULT 0, p_discount_amount numeric DEFAULT 0, p_tax_amount numeric DEFAULT 0, p_total_amount numeric DEFAULT 0)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
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
$function$
;

-- usp_pos_saleticketline_insert
CREATE OR REPLACE FUNCTION public.usp_pos_saleticketline_insert(p_sale_ticket_id integer, p_line_number integer, p_country_code character varying, p_product_id integer DEFAULT NULL::integer, p_product_code character varying DEFAULT NULL::character varying, p_product_name character varying DEFAULT NULL::character varying, p_quantity numeric DEFAULT NULL::numeric, p_unit_price numeric DEFAULT NULL::numeric, p_discount_amount numeric DEFAULT 0, p_tax_code character varying DEFAULT NULL::character varying, p_tax_rate numeric DEFAULT NULL::numeric, p_net_amount numeric DEFAULT NULL::numeric, p_tax_amount numeric DEFAULT NULL::numeric, p_total_amount numeric DEFAULT NULL::numeric, p_supervisor_approval_id integer DEFAULT NULL::integer, p_line_meta_json text DEFAULT NULL::text)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
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
$function$
;

-- usp_pos_venta_crear
CREATE OR REPLACE FUNCTION public.usp_pos_venta_crear(p_num_factura character varying, p_caja_id character varying, p_cod_usuario character varying DEFAULT NULL::character varying, p_cliente_id character varying DEFAULT NULL::character varying, p_cliente_nombre character varying DEFAULT NULL::character varying, p_cliente_rif character varying DEFAULT NULL::character varying, p_tipo_precio character varying DEFAULT 'Detal'::character varying, p_metodo_pago character varying DEFAULT NULL::character varying, p_trama_fiscal text DEFAULT NULL::text, p_espera_origen_id integer DEFAULT NULL::integer, p_detalle_json jsonb DEFAULT '[]'::jsonb)
 RETURNS TABLE("VentaId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_venta_id INT;
BEGIN
    INSERT INTO "PosVentas" ("NumFactura", "CajaId", "CodUsuario", "ClienteId", "ClienteNombre", "ClienteRif", "TipoPrecio", "MetodoPago", "TramaFiscal", "EsperaOrigenId")
    VALUES (p_num_factura, p_caja_id, p_cod_usuario, p_cliente_id, p_cliente_nombre, p_cliente_rif, p_tipo_precio, p_metodo_pago, p_trama_fiscal, p_espera_origen_id)
    RETURNING "Id" INTO v_venta_id;

    INSERT INTO "PosVentasDetalle" ("VentaId", "ProductoId", "Codigo", "Nombre", "Cantidad", "PrecioUnitario", "Descuento", "IVA", "Subtotal")
    SELECT
        v_venta_id,
        (item->>'prodId')::VARCHAR(15),
        (item->>'cod')::VARCHAR(30),
        (item->>'nom')::VARCHAR(200),
        (item->>'cant')::NUMERIC(10,3),
        (item->>'precio')::NUMERIC(18,2),
        COALESCE((item->>'desc')::NUMERIC(18,2), 0),
        COALESCE((item->>'iva')::NUMERIC(5,2), 16),
        (item->>'sub')::NUMERIC(18,2)
    FROM jsonb_array_elements(p_detalle_json) AS item;

    UPDATE "PosVentas" SET
        "Subtotal"  = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id),
        "Descuento" = (SELECT COALESCE(SUM("Descuento" * "Cantidad"), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id),
        "Impuestos" = (SELECT COALESCE(SUM("Subtotal" * "IVA" / 100), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id),
        "Total"     = (SELECT COALESCE(SUM("Subtotal" + "Subtotal" * "IVA" / 100), 0) FROM "PosVentasDetalle" WHERE "VentaId" = v_venta_id)
    WHERE "Id" = v_venta_id;

    RETURN QUERY SELECT v_venta_id AS "VentaId";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- usp_pos_waitticket_create
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_create(p_company_id integer, p_branch_id integer, p_country_code character varying, p_cash_register_code character varying, p_station_name character varying DEFAULT NULL::character varying, p_created_by_user_id integer DEFAULT NULL::integer, p_customer_id integer DEFAULT NULL::integer, p_customer_code character varying DEFAULT NULL::character varying, p_customer_name character varying DEFAULT NULL::character varying, p_customer_fiscal_id character varying DEFAULT NULL::character varying, p_price_tier character varying DEFAULT 'Detal'::character varying, p_reason character varying DEFAULT NULL::character varying, p_net_amount numeric DEFAULT 0, p_discount_amount numeric DEFAULT 0, p_tax_amount numeric DEFAULT 0, p_total_amount numeric DEFAULT 0)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
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
$function$
;

-- usp_pos_waitticket_getheader
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_getheader(p_company_id integer, p_branch_id integer, p_wait_ticket_id integer)
 RETURNS TABLE(id integer, "cajaId" character varying, "estacionNombre" character varying, "clienteId" character varying, "clienteNombre" character varying, "clienteRif" character varying, "tipoPrecio" character varying, motivo character varying, subtotal numeric, impuestos numeric, total numeric, estado character varying, "fechaCreacion" timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT wt."WaitTicketId", wt."CashRegisterCode", wt."StationName", wt."CustomerCode",
           wt."CustomerName", wt."CustomerFiscalId", wt."PriceTier", wt."Reason",
           wt."NetAmount", wt."TaxAmount", wt."TotalAmount", wt."Status", wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id AND wt."BranchId" = p_branch_id AND wt."WaitTicketId" = p_wait_ticket_id
    LIMIT 1;
END;
$function$
;

-- usp_pos_waitticket_list
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_list(p_company_id integer, p_branch_id integer)
 RETURNS TABLE(id integer, "cajaId" character varying, "estacionNombre" character varying, "clienteNombre" character varying, motivo character varying, total numeric, "fechaCreacion" timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT wt."WaitTicketId", wt."CashRegisterCode", wt."StationName",
           wt."CustomerName", wt."Reason", wt."TotalAmount", wt."CreatedAt"
    FROM pos."WaitTicket" wt
    WHERE wt."CompanyId" = p_company_id AND wt."BranchId" = p_branch_id AND wt."Status" = 'WAITING'
    ORDER BY wt."CreatedAt";
END;
$function$
;

-- usp_pos_waitticket_recover
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_recover(p_company_id integer, p_branch_id integer, p_wait_ticket_id integer, p_recovered_by_user_id integer DEFAULT NULL::integer, p_recovered_at_register character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pos_waitticket_void
CREATE OR REPLACE FUNCTION public.usp_pos_waitticket_void(p_company_id integer, p_branch_id integer, p_wait_ticket_id integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE pos."WaitTicket"
    SET "Status" = 'VOIDED', "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
      AND "WaitTicketId" = p_wait_ticket_id AND "Status" = 'WAITING';

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);
END;
$function$
;

-- usp_pos_waitticketline_getitems
CREATE OR REPLACE FUNCTION public.usp_pos_waitticketline_getitems(p_wait_ticket_id integer)
 RETURNS TABLE(id integer, "productoId" character varying, codigo character varying, nombre character varying, cantidad numeric, "precioUnitario" numeric, descuento numeric, iva numeric, subtotal numeric, total numeric, "supervisorApprovalId" integer, "lineMetaJson" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_pos_waitticketline_insert
CREATE OR REPLACE FUNCTION public.usp_pos_waitticketline_insert(p_wait_ticket_id integer, p_line_number integer, p_country_code character varying, p_product_id integer DEFAULT NULL::integer, p_product_code character varying DEFAULT NULL::character varying, p_product_name character varying DEFAULT NULL::character varying, p_quantity numeric DEFAULT NULL::numeric, p_unit_price numeric DEFAULT NULL::numeric, p_discount_amount numeric DEFAULT 0, p_tax_code character varying DEFAULT NULL::character varying, p_tax_rate numeric DEFAULT NULL::numeric, p_net_amount numeric DEFAULT NULL::numeric, p_tax_amount numeric DEFAULT NULL::numeric, p_total_amount numeric DEFAULT NULL::numeric, p_supervisor_approval_id integer DEFAULT NULL::integer, p_line_meta_json text DEFAULT NULL::text)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- usp_rest_admin_adjuststock
CREATE OR REPLACE FUNCTION public.usp_rest_admin_adjuststock(p_product_id integer, p_delta_qty numeric)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_product_id IS NULL OR p_delta_qty = 0 THEN
        RETURN;
    END IF;

    UPDATE master."Product"
    SET "StockQty" = COALESCE("StockQty", 0) + p_delta_qty,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "ProductId" = p_product_id;
END;
$function$
;

-- usp_rest_admin_ambiente_list
CREATE OR REPLACE FUNCTION public.usp_rest_admin_ambiente_list(p_company_id integer, p_branch_id integer)
 RETURNS TABLE(id integer, nombre character varying, color character varying, orden integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        me."MenuEnvironmentId",
        me."EnvironmentName",
        me."ColorHex",
        me."SortOrder"
    FROM rest."MenuEnvironment" me
    WHERE me."CompanyId" = p_company_id
      AND me."BranchId"  = p_branch_id
      AND me."IsActive"  = TRUE
    ORDER BY me."SortOrder", me."EnvironmentName";
END;
$function$
;

-- usp_rest_admin_ambiente_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_admin_ambiente_upsert(p_id integer DEFAULT 0, p_company_id integer DEFAULT NULL::integer, p_branch_id integer DEFAULT NULL::integer, p_code character varying DEFAULT NULL::character varying, p_nombre character varying DEFAULT NULL::character varying, p_color character varying DEFAULT NULL::character varying, p_orden integer DEFAULT 0, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuEnvironment" WHERE "MenuEnvironmentId" = p_id) THEN
        UPDATE rest."MenuEnvironment"
        SET "EnvironmentName" = p_nombre,
            "ColorHex" = p_color,
            "SortOrder" = p_orden,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "MenuEnvironmentId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuEnvironment" (
            "CompanyId", "BranchId", "EnvironmentCode", "EnvironmentName",
            "ColorHex", "SortOrder", "IsActive", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_code, p_nombre,
            p_color, p_orden, TRUE, p_user_id, p_user_id
        )
        RETURNING "MenuEnvironmentId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$function$
;

-- usp_rest_admin_categoria_list
CREATE OR REPLACE FUNCTION public.usp_rest_admin_categoria_list(p_company_id integer, p_branch_id integer)
 RETURNS TABLE(id integer, nombre character varying, descripcion character varying, color character varying, orden integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        mc."MenuCategoryId",
        mc."CategoryName",
        mc."DescriptionText",
        mc."ColorHex",
        mc."SortOrder"
    FROM rest."MenuCategory" mc
    WHERE mc."CompanyId" = p_company_id
      AND mc."BranchId"  = p_branch_id
      AND mc."IsActive"  = TRUE
    ORDER BY mc."SortOrder", mc."CategoryName";
END;
$function$
;

-- usp_rest_admin_categoria_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_admin_categoria_upsert(p_id integer DEFAULT 0, p_company_id integer DEFAULT NULL::integer, p_branch_id integer DEFAULT NULL::integer, p_code character varying DEFAULT NULL::character varying, p_nombre character varying DEFAULT NULL::character varying, p_descripcion character varying DEFAULT NULL::character varying, p_color character varying DEFAULT NULL::character varying, p_orden integer DEFAULT 0, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuCategory" WHERE "MenuCategoryId" = p_id) THEN
        UPDATE rest."MenuCategory"
        SET "CategoryName" = p_nombre,
            "DescriptionText" = p_descripcion,
            "ColorHex" = p_color,
            "SortOrder" = p_orden,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "MenuCategoryId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuCategory" (
            "CompanyId", "BranchId", "CategoryCode", "CategoryName",
            "DescriptionText", "ColorHex", "SortOrder", "IsActive",
            "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_code, p_nombre,
            p_descripcion, p_color, p_orden, TRUE,
            p_user_id, p_user_id
        )
        RETURNING "MenuCategoryId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$function$
;

-- usp_rest_admin_componente_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_admin_componente_upsert(p_id integer DEFAULT 0, p_producto_id integer DEFAULT NULL::integer, p_nombre character varying DEFAULT NULL::character varying, p_obligatorio boolean DEFAULT false, p_orden integer DEFAULT 0)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuComponent" WHERE "MenuComponentId" = p_id) THEN
        UPDATE rest."MenuComponent"
        SET "ComponentName" = p_nombre,
            "IsRequired" = p_obligatorio,
            "SortOrder" = p_orden,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "MenuComponentId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuComponent" (
            "MenuProductId", "ComponentName", "IsRequired", "SortOrder", "IsActive"
        )
        VALUES (p_producto_id, p_nombre, p_obligatorio, p_orden, TRUE)
        RETURNING "MenuComponentId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$function$
;

-- usp_rest_admin_compra_getdetalle_header
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_getdetalle_header(p_compra_id integer)
 RETURNS TABLE(id integer, "numCompra" character varying, "proveedorId" character varying, "proveedorNombre" character varying, "fechaCompra" timestamp with time zone, estado character varying, subtotal numeric, iva numeric, total numeric, observaciones character varying, "codUsuario" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."PurchaseId",
        p."PurchaseNumber",
        s."SupplierCode",
        s."SupplierName",
        p."PurchaseDate",
        p."Status",
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes",
        u."UserCode"
    FROM rest."Purchase" p
    LEFT JOIN master."Supplier" s ON s."SupplierId" = p."SupplierId"
    LEFT JOIN sec."User" u ON u."UserId" = p."CreatedByUserId"
    WHERE p."PurchaseId" = p_compra_id
    LIMIT 1;
END;
$function$
;

-- usp_rest_admin_compra_getdetalle_lines
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_getdetalle_lines(p_compra_id integer)
 RETURNS TABLE(id integer, "compraId" integer, "inventarioId" character varying, descripcion character varying, cantidad numeric, "precioUnit" numeric, subtotal numeric, iva numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        pl."PurchaseLineId",
        pl."PurchaseId",
        pr."ProductCode",
        pl."DescriptionText",
        pl."Quantity",
        pl."UnitPrice",
        pl."SubtotalAmount",
        pl."TaxRatePercent"
    FROM rest."PurchaseLine" pl
    LEFT JOIN master."Product" pr ON pr."ProductId" = pl."IngredientProductId"
    WHERE pl."PurchaseId" = p_compra_id
    ORDER BY pl."PurchaseLineId";
END;
$function$
;

-- usp_rest_admin_compra_getnextseq
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_getnextseq(p_company_id integer, p_branch_id integer)
 RETURNS TABLE(seq bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT COALESCE(MAX(p."PurchaseId"), 0) + 1
    FROM rest."Purchase" p
    WHERE p."CompanyId" = p_company_id
      AND p."BranchId"  = p_branch_id;
END;
$function$
;

-- usp_rest_admin_compra_insert
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_insert(p_company_id integer, p_branch_id integer, p_purchase_number character varying, p_supplier_id integer DEFAULT NULL::integer, p_notes character varying DEFAULT NULL::character varying, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
BEGIN
    INSERT INTO rest."Purchase" (
        "CompanyId", "BranchId", "PurchaseNumber", "SupplierId",
        "PurchaseDate", "Status", "Notes", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
        p_company_id, p_branch_id, p_purchase_number, p_supplier_id,
        NOW() AT TIME ZONE 'UTC', 'PENDIENTE', p_notes, p_user_id, p_user_id
    )
    RETURNING "PurchaseId" INTO v_id;

    RETURN QUERY SELECT v_id;
END;
$function$
;

-- usp_rest_admin_compra_list
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_list(p_company_id integer, p_branch_id integer, p_status character varying DEFAULT NULL::character varying, p_from_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_to_date timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS TABLE(id integer, "numCompra" character varying, "proveedorId" character varying, "proveedorNombre" character varying, "fechaCompra" timestamp with time zone, estado character varying, subtotal numeric, iva numeric, total numeric, observaciones character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."PurchaseId",
        p."PurchaseNumber",
        s."SupplierCode",
        s."SupplierName",
        p."PurchaseDate",
        p."Status",
        p."SubtotalAmount",
        p."TaxAmount",
        p."TotalAmount",
        p."Notes"
    FROM rest."Purchase" p
    LEFT JOIN master."Supplier" s ON s."SupplierId" = p."SupplierId"
    WHERE p."CompanyId" = p_company_id
      AND p."BranchId"  = p_branch_id
      AND (p_status IS NULL OR p."Status" = p_status)
      AND (p_from_date IS NULL OR p."PurchaseDate" >= p_from_date)
      AND (p_to_date IS NULL OR p."PurchaseDate" <= p_to_date)
    ORDER BY p."PurchaseDate" DESC, p."PurchaseId" DESC;
END;
$function$
;

-- usp_rest_admin_compra_recalctotals
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_recalctotals(p_purchase_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_subtotal NUMERIC(18,2);
    v_tax      NUMERIC(18,2);
    v_total    NUMERIC(18,2);
BEGIN
    SELECT
        COALESCE(SUM("SubtotalAmount"), 0),
        COALESCE(SUM("SubtotalAmount" * "TaxRatePercent" / 100.0), 0),
        COALESCE(SUM("SubtotalAmount" + ("SubtotalAmount" * "TaxRatePercent" / 100.0)), 0)
    INTO v_subtotal, v_tax, v_total
    FROM rest."PurchaseLine"
    WHERE "PurchaseId" = p_purchase_id;

    UPDATE rest."Purchase"
    SET "SubtotalAmount" = v_subtotal,
        "TaxAmount"      = v_tax,
        "TotalAmount"    = v_total,
        "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
    WHERE "PurchaseId" = p_purchase_id;
END;
$function$
;

-- usp_rest_admin_compra_update
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compra_update(p_compra_id integer, p_supplier_id integer DEFAULT NULL::integer, p_status character varying DEFAULT NULL::character varying, p_notes character varying DEFAULT NULL::character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE rest."Purchase"
    SET "SupplierId" = COALESCE(p_supplier_id, "SupplierId"),
        "Status"     = COALESCE(p_status, "Status"),
        "Notes"      = COALESCE(p_notes, "Notes"),
        "UpdatedAt"  = NOW() AT TIME ZONE 'UTC'
    WHERE "PurchaseId" = p_compra_id;
END;
$function$
;

-- usp_rest_admin_compralinea_delete
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compralinea_delete(p_compra_id integer, p_detalle_id integer)
 RETURNS TABLE("ingredientProductId" integer, quantity numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Devolver datos previos antes de borrar
    RETURN QUERY
    SELECT pl."IngredientProductId", pl."Quantity"
    FROM rest."PurchaseLine" pl
    WHERE pl."PurchaseLineId" = p_detalle_id
      AND pl."PurchaseId" = p_compra_id
    LIMIT 1;

    DELETE FROM rest."PurchaseLine"
    WHERE "PurchaseLineId" = p_detalle_id
      AND "PurchaseId" = p_compra_id;
END;
$function$
;

-- usp_rest_admin_compralinea_getprev
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compralinea_getprev(p_id integer, p_compra_id integer)
 RETURNS TABLE("ingredientProductId" integer, quantity numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT pl."IngredientProductId", pl."Quantity"
    FROM rest."PurchaseLine" pl
    WHERE pl."PurchaseLineId" = p_id
      AND pl."PurchaseId" = p_compra_id
    LIMIT 1;
END;
$function$
;

-- usp_rest_admin_compralinea_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_admin_compralinea_upsert(p_id integer DEFAULT 0, p_compra_id integer DEFAULT NULL::integer, p_ingredient_product_id integer DEFAULT NULL::integer, p_descripcion character varying DEFAULT NULL::character varying, p_quantity numeric DEFAULT NULL::numeric, p_unit_price numeric DEFAULT NULL::numeric, p_tax_rate_percent numeric DEFAULT 16, p_subtotal numeric DEFAULT NULL::numeric)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 THEN
        UPDATE rest."PurchaseLine"
        SET "IngredientProductId" = p_ingredient_product_id,
            "DescriptionText" = p_descripcion,
            "Quantity" = p_quantity,
            "UnitPrice" = p_unit_price,
            "TaxRatePercent" = p_tax_rate_percent,
            "SubtotalAmount" = p_subtotal,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "PurchaseLineId" = p_id
          AND "PurchaseId" = p_compra_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."PurchaseLine" (
            "PurchaseId", "IngredientProductId", "DescriptionText",
            "Quantity", "UnitPrice", "TaxRatePercent", "SubtotalAmount"
        )
        VALUES (
            p_compra_id, p_ingredient_product_id, p_descripcion,
            p_quantity, p_unit_price, p_tax_rate_percent, p_subtotal
        )
        RETURNING "PurchaseLineId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$function$
;

-- usp_rest_admin_insumo_search
CREATE OR REPLACE FUNCTION public.usp_rest_admin_insumo_search(p_company_id integer, p_branch_id integer, p_search character varying DEFAULT NULL::character varying, p_limit integer DEFAULT 30)
 RETURNS TABLE(codigo character varying, descripcion character varying, imagen character varying, unidad character varying, existencia numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."ProductCode",
        p."ProductName",
        img."PublicUrl",
        p."UnitCode",
        p."StockQty"
    FROM master."Product" p
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId" = p."CompanyId"
          AND ei."BranchId" = p_branch_id
          AND ei."EntityType" = 'MASTER_PRODUCT'
          AND ei."EntityId" = p."ProductId"
          AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE
          AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    WHERE p."CompanyId" = p_company_id
      AND p."IsDeleted" = FALSE
      AND p."IsActive" = TRUE
      AND (
          p_search IS NULL
          OR p."ProductCode" LIKE p_search
          OR p."ProductName" LIKE p_search
      )
    ORDER BY p."ProductCode"
    LIMIT p_limit;
END;
$function$
;

-- usp_rest_admin_opcion_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_admin_opcion_upsert(p_id integer DEFAULT 0, p_componente_id integer DEFAULT NULL::integer, p_nombre character varying DEFAULT NULL::character varying, p_precio_extra numeric DEFAULT 0, p_orden integer DEFAULT 0)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuOption" WHERE "MenuOptionId" = p_id) THEN
        UPDATE rest."MenuOption"
        SET "OptionName" = p_nombre,
            "ExtraPrice" = p_precio_extra,
            "SortOrder" = p_orden,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "MenuOptionId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuOption" (
            "MenuComponentId", "OptionName", "ExtraPrice", "SortOrder", "IsActive"
        )
        VALUES (p_componente_id, p_nombre, p_precio_extra, p_orden, TRUE)
        RETURNING "MenuOptionId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$function$
;

-- usp_rest_admin_producto_delete
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_delete(p_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE rest."MenuProduct"
    SET "IsActive" = FALSE,
        "IsAvailable" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "MenuProductId" = p_id;
END;
$function$
;

-- usp_rest_admin_producto_get
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_get(p_id integer, p_branch_id integer)
 RETURNS TABLE(id integer, codigo character varying, nombre character varying, descripcion character varying, "categoriaId" integer, precio numeric, "costoEstimado" numeric, iva numeric, "esCompuesto" boolean, "tiempoPreparacion" integer, imagen character varying, "esSugerenciaDelDia" boolean, disponible boolean, "articuloInventarioId" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Resultset 1: producto
    RETURN QUERY
    SELECT
        mp."MenuProductId",
        mp."ProductCode",
        mp."ProductName",
        mp."DescriptionText",
        mp."MenuCategoryId",
        mp."PriceAmount",
        mp."EstimatedCost",
        mp."TaxRatePercent",
        mp."IsComposite",
        mp."PrepMinutes",
        COALESCE(img."PublicUrl", mp."ImageUrl"),
        mp."IsDailySuggestion",
        mp."IsAvailable",
        inv."ProductCode"
    FROM rest."MenuProduct" mp
    LEFT JOIN master."Product" inv ON inv."ProductId" = mp."InventoryProductId"
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId" = mp."CompanyId"
          AND ei."BranchId" = mp."BranchId"
          AND ei."EntityType" = 'REST_MENU_PRODUCT'
          AND ei."EntityId" = mp."MenuProductId"
          AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE
          AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    WHERE mp."MenuProductId" = p_id
      AND mp."IsActive" = TRUE
    LIMIT 1;
END;
$function$
;

-- usp_rest_admin_producto_get_componentes
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_get_componentes(p_id integer)
 RETURNS TABLE(id integer, nombre character varying, obligatorio boolean, orden integer, "opcionId" integer, "opcionNombre" character varying, "precioExtra" numeric, "opcionOrden" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        c."MenuComponentId",
        c."ComponentName",
        c."IsRequired",
        c."SortOrder",
        o."MenuOptionId",
        o."OptionName",
        o."ExtraPrice",
        o."SortOrder"
    FROM rest."MenuComponent" c
    LEFT JOIN rest."MenuOption" o
      ON o."MenuComponentId" = c."MenuComponentId"
     AND o."IsActive" = TRUE
    WHERE c."MenuProductId" = p_id
      AND c."IsActive" = TRUE
    ORDER BY c."SortOrder", c."MenuComponentId", o."SortOrder", o."MenuOptionId";
END;
$function$
;

-- usp_rest_admin_producto_get_receta
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_get_receta(p_id integer, p_branch_id integer)
 RETURNS TABLE(id integer, "productoId" integer, "inventarioId" character varying, descripcion character varying, imagen character varying, cantidad numeric, unidad character varying, comentario character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        r."MenuRecipeId",
        r."MenuProductId",
        p."ProductCode",
        p."ProductName",
        img."PublicUrl",
        r."Quantity",
        r."UnitCode",
        r."Notes"
    FROM rest."MenuRecipe" r
    INNER JOIN master."Product" p ON p."ProductId" = r."IngredientProductId"
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId" = p."CompanyId"
          AND ei."BranchId" = p_branch_id
          AND ei."EntityType" = 'MASTER_PRODUCT'
          AND ei."EntityId" = p."ProductId"
          AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE
          AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    WHERE r."MenuProductId" = p_id
      AND r."IsActive" = TRUE
    ORDER BY r."MenuRecipeId";
END;
$function$
;

-- usp_rest_admin_producto_list
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_list(p_company_id integer, p_branch_id integer, p_menu_category_id integer DEFAULT NULL::integer, p_search character varying DEFAULT NULL::character varying, p_solo_disponibles boolean DEFAULT true)
 RETURNS TABLE(id integer, codigo character varying, nombre character varying, descripcion character varying, "categoriaId" integer, "categoriaNombre" character varying, precio numeric, "costoEstimado" numeric, iva numeric, "esCompuesto" boolean, "tiempoPreparacion" integer, imagen character varying, "esSugerenciaDelDia" boolean, disponible boolean, "articuloInventarioId" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        mp."MenuProductId",
        mp."ProductCode",
        mp."ProductName",
        mp."DescriptionText",
        mp."MenuCategoryId",
        mc."CategoryName",
        mp."PriceAmount",
        mp."EstimatedCost",
        mp."TaxRatePercent",
        mp."IsComposite",
        mp."PrepMinutes",
        COALESCE(img."PublicUrl", mp."ImageUrl"),
        mp."IsDailySuggestion",
        mp."IsAvailable",
        inv."ProductCode"
    FROM rest."MenuProduct" mp
    LEFT JOIN rest."MenuCategory" mc ON mc."MenuCategoryId" = mp."MenuCategoryId"
    LEFT JOIN master."Product" inv ON inv."ProductId" = mp."InventoryProductId"
    LEFT JOIN LATERAL (
        SELECT ma."PublicUrl"
        FROM cfg."EntityImage" ei
        INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
        WHERE ei."CompanyId" = mp."CompanyId"
          AND ei."BranchId" = mp."BranchId"
          AND ei."EntityType" = 'REST_MENU_PRODUCT'
          AND ei."EntityId" = mp."MenuProductId"
          AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE
          AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
        ORDER BY CASE WHEN ei."IsPrimary" = TRUE THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId"
        LIMIT 1
    ) img ON TRUE
    WHERE mp."CompanyId" = p_company_id
      AND mp."BranchId"  = p_branch_id
      AND mp."IsActive" = TRUE
      AND (p_solo_disponibles = FALSE OR mp."IsAvailable" = TRUE)
      AND (p_menu_category_id IS NULL OR mp."MenuCategoryId" = p_menu_category_id)
      AND (p_search IS NULL OR mp."ProductCode" LIKE p_search OR mp."ProductName" LIKE p_search)
    ORDER BY mp."ProductName";
END;
$function$
;

-- usp_rest_admin_producto_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_admin_producto_upsert(p_id integer DEFAULT 0, p_company_id integer DEFAULT NULL::integer, p_branch_id integer DEFAULT NULL::integer, p_code character varying DEFAULT NULL::character varying, p_name character varying DEFAULT NULL::character varying, p_description character varying DEFAULT NULL::character varying, p_menu_category_id integer DEFAULT NULL::integer, p_price numeric DEFAULT 0, p_estimated_cost numeric DEFAULT 0, p_tax_rate_percent numeric DEFAULT 16, p_is_composite boolean DEFAULT false, p_prep_minutes integer DEFAULT 0, p_image_url character varying DEFAULT NULL::character varying, p_is_daily_suggestion boolean DEFAULT false, p_is_available boolean DEFAULT true, p_inventory_product_id integer DEFAULT NULL::integer, p_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuProduct" WHERE "MenuProductId" = p_id) THEN
        UPDATE rest."MenuProduct"
        SET "ProductCode" = p_code,
            "ProductName" = p_name,
            "DescriptionText" = p_description,
            "MenuCategoryId" = p_menu_category_id,
            "PriceAmount" = p_price,
            "EstimatedCost" = p_estimated_cost,
            "TaxRatePercent" = p_tax_rate_percent,
            "IsComposite" = p_is_composite,
            "PrepMinutes" = p_prep_minutes,
            "ImageUrl" = p_image_url,
            "IsDailySuggestion" = p_is_daily_suggestion,
            "IsAvailable" = p_is_available,
            "InventoryProductId" = p_inventory_product_id,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "MenuProductId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuProduct" (
            "CompanyId", "BranchId", "ProductCode", "ProductName", "DescriptionText",
            "MenuCategoryId", "PriceAmount", "EstimatedCost", "TaxRatePercent",
            "IsComposite", "PrepMinutes", "ImageUrl", "IsDailySuggestion",
            "IsAvailable", "InventoryProductId", "IsActive",
            "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, p_code, p_name, p_description,
            p_menu_category_id, p_price, p_estimated_cost, p_tax_rate_percent,
            p_is_composite, p_prep_minutes, p_image_url, p_is_daily_suggestion,
            p_is_available, p_inventory_product_id, TRUE,
            p_user_id, p_user_id
        )
        RETURNING "MenuProductId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$function$
;

-- usp_rest_admin_proveedor_search
CREATE OR REPLACE FUNCTION public.usp_rest_admin_proveedor_search(p_company_id integer, p_search character varying DEFAULT NULL::character varying, p_limit integer DEFAULT 20)
 RETURNS TABLE(id bigint, codigo character varying, nombre character varying, rif character varying, telefono character varying, direccion character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        s."SupplierId",
        s."SupplierCode",
        s."SupplierName",
        s."FiscalId",
        s."Phone",
        s."AddressLine"
    FROM master."Supplier" s
    WHERE s."CompanyId" = p_company_id
      AND s."IsDeleted" = FALSE
      AND s."IsActive" = TRUE
      AND (
          p_search IS NULL
          OR s."SupplierCode" LIKE p_search
          OR s."SupplierName" LIKE p_search
          OR s."FiscalId" LIKE p_search
      )
    ORDER BY s."SupplierName"
    LIMIT p_limit;
END;
$function$
;

-- usp_rest_admin_receta_delete
CREATE OR REPLACE FUNCTION public.usp_rest_admin_receta_delete(p_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE rest."MenuRecipe"
    SET "IsActive" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE "MenuRecipeId" = p_id;
END;
$function$
;

-- usp_rest_admin_receta_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_admin_receta_upsert(p_id integer DEFAULT 0, p_producto_id integer DEFAULT NULL::integer, p_ingredient_product_id integer DEFAULT NULL::integer, p_quantity numeric DEFAULT NULL::numeric, p_unit_code character varying DEFAULT NULL::character varying, p_notes character varying DEFAULT NULL::character varying)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM rest."MenuRecipe" WHERE "MenuRecipeId" = p_id) THEN
        UPDATE rest."MenuRecipe"
        SET "IngredientProductId" = p_ingredient_product_id,
            "Quantity" = p_quantity,
            "UnitCode" = p_unit_code,
            "Notes" = p_notes,
            "IsActive" = TRUE,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "MenuRecipeId" = p_id;

        RETURN QUERY SELECT p_id;
    ELSE
        INSERT INTO rest."MenuRecipe" (
            "MenuProductId", "IngredientProductId", "Quantity", "UnitCode", "Notes", "IsActive"
        )
        VALUES (p_producto_id, p_ingredient_product_id, p_quantity, p_unit_code, p_notes, TRUE)
        RETURNING "MenuRecipeId" INTO v_id;

        RETURN QUERY SELECT v_id;
    END IF;
END;
$function$
;

-- usp_rest_admin_resolvemenucategory
CREATE OR REPLACE FUNCTION public.usp_rest_admin_resolvemenucategory(p_menu_category_id integer)
 RETURNS TABLE(id integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT mc."MenuCategoryId"
    FROM rest."MenuCategory" mc
    WHERE mc."MenuCategoryId" = p_menu_category_id
    LIMIT 1;
END;
$function$
;

-- usp_rest_admin_resolveproduct
CREATE OR REPLACE FUNCTION public.usp_rest_admin_resolveproduct(p_company_id integer, p_key character varying)
 RETURNS TABLE("productId" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT p."ProductId"
    FROM master."Product" p
    WHERE p."CompanyId" = p_company_id
      AND p."IsDeleted" = FALSE
      AND p."IsActive" = TRUE
      AND (
          p."ProductCode" = p_key
          OR p."ProductId"::TEXT = p_key
      )
    ORDER BY p."ProductId"
    LIMIT 1;
END;
$function$
;

-- usp_rest_admin_resolvesupplier
CREATE OR REPLACE FUNCTION public.usp_rest_admin_resolvesupplier(p_company_id integer, p_key character varying)
 RETURNS TABLE("supplierId" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT s."SupplierId"
    FROM master."Supplier" s
    WHERE s."CompanyId" = p_company_id
      AND s."IsDeleted" = FALSE
      AND s."IsActive" = TRUE
      AND (
          s."SupplierCode" = p_key
          OR s."SupplierId"::TEXT = p_key
      )
    ORDER BY s."SupplierId"
    LIMIT 1;
END;
$function$
;

-- usp_rest_admin_syncmenuproductimage
CREATE OR REPLACE FUNCTION public.usp_rest_admin_syncmenuproductimage(p_company_id integer, p_branch_id integer, p_menu_product_id integer, p_storage_key character varying, p_user_id integer DEFAULT NULL::integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_media_asset_id INT;
BEGIN
    IF p_storage_key IS NULL OR LENGTH(p_storage_key) = 0 THEN
        RETURN;
    END IF;

    SELECT "MediaAssetId" INTO v_media_asset_id
    FROM cfg."MediaAsset"
    WHERE "CompanyId" = p_company_id
      AND "BranchId"  = p_branch_id
      AND "StorageKey" = p_storage_key
      AND "IsDeleted" = FALSE
      AND "IsActive" = TRUE
    ORDER BY "MediaAssetId" DESC
    LIMIT 1;

    IF v_media_asset_id IS NULL THEN
        RETURN;
    END IF;

    -- Quitar primary de todos
    UPDATE cfg."EntityImage"
    SET "IsPrimary" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_user_id
    WHERE "CompanyId" = p_company_id
      AND "BranchId"  = p_branch_id
      AND "EntityType" = 'REST_MENU_PRODUCT'
      AND "EntityId"   = p_menu_product_id
      AND "IsDeleted"  = FALSE
      AND "IsActive"   = TRUE;

    IF EXISTS (
        SELECT 1 FROM cfg."EntityImage"
        WHERE "CompanyId" = p_company_id
          AND "BranchId"  = p_branch_id
          AND "EntityType" = 'REST_MENU_PRODUCT'
          AND "EntityId"   = p_menu_product_id
          AND "MediaAssetId" = v_media_asset_id
    ) THEN
        UPDATE cfg."EntityImage"
        SET "IsPrimary" = TRUE,
            "SortOrder" = 0,
            "IsActive"  = TRUE,
            "IsDeleted" = FALSE,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_user_id
        WHERE "CompanyId" = p_company_id
          AND "BranchId"  = p_branch_id
          AND "EntityType" = 'REST_MENU_PRODUCT'
          AND "EntityId"   = p_menu_product_id
          AND "MediaAssetId" = v_media_asset_id;
    ELSE
        INSERT INTO cfg."EntityImage" (
            "CompanyId", "BranchId", "EntityType", "EntityId", "MediaAssetId",
            "SortOrder", "IsPrimary", "CreatedByUserId", "UpdatedByUserId"
        )
        VALUES (
            p_company_id, p_branch_id, 'REST_MENU_PRODUCT', p_menu_product_id, v_media_asset_id,
            0, TRUE, p_user_id, p_user_id
        );
    END IF;
END;
$function$
;

-- usp_rest_ambiente_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_ambiente_upsert(p_id integer DEFAULT 0, p_nombre character varying DEFAULT ''::character varying, p_color character varying DEFAULT '#4CAF50'::character varying, p_orden integer DEFAULT 0)
 RETURNS TABLE("ResultId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteAmbientes" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteAmbientes" SET "Nombre" = p_nombre, "Color" = p_color, "Orden" = p_orden WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteAmbientes" ("Nombre", "Color", "Orden") VALUES (p_nombre, p_color, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$function$
;

-- usp_rest_ambientes_list
CREATE OR REPLACE FUNCTION public.usp_rest_ambientes_list()
 RETURNS TABLE(id integer, nombre character varying, color character varying, orden integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT "Id", "Nombre", "Color", "Orden"
    FROM "RestauranteAmbientes" WHERE "Activo" = TRUE ORDER BY "Orden";
END;
$function$
;

-- usp_rest_categoria_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_categoria_upsert(p_id integer DEFAULT 0, p_nombre character varying DEFAULT ''::character varying, p_descripcion character varying DEFAULT NULL::character varying, p_color character varying DEFAULT NULL::character varying, p_orden integer DEFAULT 0)
 RETURNS TABLE("ResultId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteCategorias" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteCategorias" SET "Nombre" = p_nombre, "Descripcion" = p_descripcion, "Color" = p_color, "Orden" = p_orden WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteCategorias" ("Nombre", "Descripcion", "Color", "Orden") VALUES (p_nombre, p_descripcion, p_color, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$function$
;

-- usp_rest_categorias_list
CREATE OR REPLACE FUNCTION public.usp_rest_categorias_list()
 RETURNS TABLE(id integer, nombre character varying, descripcion character varying, color character varying, orden integer, "productCount" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT c."Id", c."Nombre", c."Descripcion", c."Color", c."Orden",
        (SELECT COUNT(1) FROM "RestauranteProductos" p WHERE p."CategoriaId" = c."Id" AND p."Activo" = TRUE)
    FROM "RestauranteCategorias" c WHERE c."Activa" = TRUE ORDER BY c."Orden";
END;
$function$
;

-- usp_rest_comanda_enviar
CREATE OR REPLACE FUNCTION public.usp_rest_comanda_enviar(p_pedido_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE "RestaurantePedidoItems"
    SET "EnviadoACocina" = TRUE,
        "HoraEnvio" = NOW() AT TIME ZONE 'UTC',
        "Estado" = 'en_preparacion'
    WHERE "PedidoId" = p_pedido_id
      AND "EnviadoACocina" = FALSE;

    UPDATE "RestaurantePedidos"
    SET "Estado" = 'en_preparacion'
    WHERE "Id" = p_pedido_id AND "Estado" = 'abierto';
END;
$function$
;

-- usp_rest_componente_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_componente_upsert(p_id integer DEFAULT 0, p_producto_id integer DEFAULT 0, p_nombre character varying DEFAULT ''::character varying, p_obligatorio boolean DEFAULT false, p_orden integer DEFAULT 0)
 RETURNS TABLE("ResultId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteProductoComponentes" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteProductoComponentes" SET "Nombre" = p_nombre, "Obligatorio" = p_obligatorio, "Orden" = p_orden WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteProductoComponentes" ("ProductoId", "Nombre", "Obligatorio", "Orden") VALUES (p_producto_id, p_nombre, p_obligatorio, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$function$
;

-- usp_rest_compra_crear
CREATE OR REPLACE FUNCTION public.usp_rest_compra_crear(p_proveedor_id character varying DEFAULT NULL::character varying, p_observaciones character varying DEFAULT NULL::character varying, p_cod_usuario character varying DEFAULT NULL::character varying, p_detalle_json jsonb DEFAULT '[]'::jsonb)
 RETURNS TABLE("CompraId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_compra_id  INT;
    v_num_compra VARCHAR(20);
    v_seq        INT;
BEGIN
    SELECT COALESCE(MAX("Id"), 0) + 1 INTO v_seq FROM "RestauranteCompras";
    v_num_compra := 'RC-' || REPLACE(TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM'), '-', '') || '-' || LPAD(v_seq::TEXT, 4, '0');

    INSERT INTO "RestauranteCompras" ("NumCompra", "ProveedorId", "Estado", "Observaciones", "CodUsuario")
    VALUES (v_num_compra, p_proveedor_id, 'pendiente', p_observaciones, p_cod_usuario)
    RETURNING "Id" INTO v_compra_id;

    INSERT INTO "RestauranteComprasDetalle" ("CompraId", "InventarioId", "Descripcion", "Cantidad", "PrecioUnit", "Subtotal", "IVA")
    SELECT
        v_compra_id,
        (item->>'invId')::VARCHAR(15),
        (item->>'desc')::VARCHAR(200),
        (item->>'cant')::NUMERIC(10,3),
        (item->>'precio')::NUMERIC(18,2),
        (item->>'cant')::NUMERIC(10,3) * (item->>'precio')::NUMERIC(18,2),
        COALESCE((item->>'iva')::NUMERIC(5,2), 16)
    FROM jsonb_array_elements(p_detalle_json) AS item;

    UPDATE "RestauranteCompras" SET
        "Subtotal" = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id),
        "IVA" = (SELECT COALESCE(SUM("Subtotal" * "IVA" / 100), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id),
        "Total" = (SELECT COALESCE(SUM("Subtotal" + "Subtotal" * "IVA" / 100), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id)
    WHERE "Id" = v_compra_id;

    RETURN QUERY SELECT v_compra_id;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- usp_rest_compras_list
CREATE OR REPLACE FUNCTION public.usp_rest_compras_list(p_estado character varying DEFAULT NULL::character varying, p_from timestamp without time zone DEFAULT NULL::timestamp without time zone, p_to timestamp without time zone DEFAULT NULL::timestamp without time zone)
 RETURNS TABLE(id integer, "numCompra" character varying, "proveedorId" character varying, "proveedorNombre" character varying, "fechaCompra" timestamp without time zone, "fechaRecepcion" timestamp without time zone, estado character varying, subtotal numeric, iva numeric, total numeric, observaciones character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        c."Id", c."NumCompra",
        c."ProveedorId",
        p."SupplierName",
        c."FechaCompra", c."FechaRecepcion",
        c."Estado", c."Subtotal", c."IVA", c."Total",
        c."Observaciones"
    FROM "RestauranteCompras" c
    LEFT JOIN master."Supplier" p ON p."SupplierCode" = c."ProveedorId"
    WHERE (COALESCE(p."IsDeleted", FALSE) = FALSE OR p."SupplierCode" IS NULL)
      AND (p_estado IS NULL OR c."Estado" = p_estado)
      AND (p_from IS NULL OR c."FechaCompra" >= p_from)
      AND (p_to IS NULL OR c."FechaCompra" <= p_to)
    ORDER BY c."FechaCompra" DESC;
END;
$function$
;

-- usp_rest_diningtable_getbyid
CREATE OR REPLACE FUNCTION public.usp_rest_diningtable_getbyid(p_company_id integer, p_branch_id integer, p_mesa_id integer)
 RETURNS TABLE(id integer, "tableNumber" character varying, "tableName" character varying, capacity integer, "ambienteId" character varying, ambiente character varying, "posicionX" numeric, "posicionY" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT dt."DiningTableId", dt."TableNumber", dt."TableName", dt."Capacity",
           dt."EnvironmentCode", dt."EnvironmentName", dt."PositionX", dt."PositionY"
    FROM rest."DiningTable" dt
    WHERE dt."CompanyId" = p_company_id AND dt."BranchId" = p_branch_id
      AND dt."DiningTableId" = p_mesa_id AND dt."IsActive" = TRUE
    LIMIT 1;
END;
$function$
;

-- usp_rest_diningtable_list
CREATE OR REPLACE FUNCTION public.usp_rest_diningtable_list(p_company_id integer, p_branch_id integer, p_ambiente_id character varying DEFAULT NULL::character varying)
 RETURNS TABLE(id integer, numero character varying, nombre character varying, capacidad integer, "ambienteId" character varying, ambiente character varying, "posicionX" numeric, "posicionY" numeric, estado character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        dt."DiningTableId",
        dt."TableNumber",
        COALESCE(NULLIF(dt."TableName", ''::character varying), 'Mesa ' || dt."TableNumber")::character varying::VARCHAR,
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
$function$
;

-- usp_rest_mesas_list
CREATE OR REPLACE FUNCTION public.usp_rest_mesas_list(p_ambiente_id character varying DEFAULT NULL::character varying)
 RETURNS TABLE(id integer, numero integer, nombre character varying, capacidad integer, "ambienteId" character varying, ambiente character varying, "posicionX" integer, "posicionY" integer, estado character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        m."Id",
        m."Numero",
        m."Nombre",
        m."Capacidad",
        m."AmbienteId",
        m."Ambiente",
        m."PosicionX",
        m."PosicionY",
        m."Estado"
    FROM "RestauranteMesas" m
    WHERE m."Activa" = TRUE
      AND (p_ambiente_id IS NULL OR m."AmbienteId" = p_ambiente_id)
    ORDER BY m."AmbienteId", m."Numero";
END;
$function$
;

-- usp_rest_opcion_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_opcion_upsert(p_id integer DEFAULT 0, p_componente_id integer DEFAULT 0, p_nombre character varying DEFAULT ''::character varying, p_precio_extra numeric DEFAULT 0, p_orden integer DEFAULT 0)
 RETURNS TABLE("ResultId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteComponenteOpciones" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteComponenteOpciones" SET "Nombre" = p_nombre, "PrecioExtra" = p_precio_extra, "Orden" = p_orden WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteComponenteOpciones" ("ComponenteId", "Nombre", "PrecioExtra", "Orden") VALUES (p_componente_id, p_nombre, p_precio_extra, p_orden)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$function$
;

-- usp_rest_orderticket_checkpriorvoid
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_checkpriorvoid(p_pedido_id integer, p_item_id integer)
 RETURNS TABLE("alreadyVoided" integer)
 LANGUAGE plpgsql
AS $function$ BEGIN
    RETURN QUERY SELECT 1 FROM sec."SupervisorOverride"
    WHERE "ModuleCode"='RESTAURANTE' AND "ActionCode"='ORDER_LINE_VOID' AND "Status"='CONSUMED'
      AND "SourceDocumentId"=p_pedido_id AND "SourceLineId"=p_item_id LIMIT 1;
END; $function$
;

-- usp_rest_orderticket_close
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_close(p_pedido_id integer, p_closed_by_user_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$ BEGIN
    UPDATE rest."OrderTicket" SET "Status"='CLOSED',"ClosedByUserId"=p_closed_by_user_id,
        "ClosedAt"=NOW() AT TIME ZONE 'UTC',"UpdatedAt"=NOW() AT TIME ZONE 'UTC'
    WHERE "OrderTicketId"=p_pedido_id;
    RETURN QUERY SELECT 1,'OK'::VARCHAR(500);
END; $function$
;

-- usp_rest_orderticket_create
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_create(p_company_id integer, p_branch_id integer, p_country_code character varying, p_table_number character varying, p_opened_by_user_id integer DEFAULT NULL::integer, p_customer_name character varying DEFAULT NULL::character varying, p_customer_fiscal_id character varying DEFAULT NULL::character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE v_id INT;
BEGIN
    INSERT INTO rest."OrderTicket" ("CompanyId","BranchId","CountryCode","TableNumber","OpenedByUserId",
        "CustomerName","CustomerFiscalId","Status","NetAmount","TaxAmount","TotalAmount","OpenedAt")
    VALUES (p_company_id,p_branch_id,p_country_code,p_table_number,p_opened_by_user_id,
        p_customer_name,p_customer_fiscal_id,'OPEN',0,0,0,NOW() AT TIME ZONE 'UTC')
    RETURNING "OrderTicketId" INTO v_id;
    RETURN QUERY SELECT v_id, 'OK'::VARCHAR(500);
END;
$function$
;

-- usp_rest_orderticket_getbyid
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_getbyid(p_pedido_id integer)
 RETURNS TABLE("orderId" integer, "companyId" integer, "branchId" integer, "countryCode" character varying, status character varying)
 LANGUAGE plpgsql
AS $function$ BEGIN
    RETURN QUERY SELECT ot."OrderTicketId",ot."CompanyId",ot."BranchId",ot."CountryCode",ot."Status"
    FROM rest."OrderTicket" ot WHERE ot."OrderTicketId"=p_pedido_id LIMIT 1;
END; $function$
;

-- usp_rest_orderticket_getbymesaheader
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_getbymesaheader(p_company_id integer, p_branch_id integer, p_table_number character varying)
 RETURNS TABLE(id integer, "clienteNombre" character varying, "clienteRif" character varying, estado character varying, total numeric)
 LANGUAGE plpgsql
AS $function$ BEGIN
    RETURN QUERY SELECT ot."OrderTicketId",ot."CustomerName",ot."CustomerFiscalId",ot."Status",ot."TotalAmount"
    FROM rest."OrderTicket" ot WHERE ot."CompanyId"=p_company_id AND ot."BranchId"=p_branch_id
      AND ot."TableNumber"=p_table_number AND ot."Status" IN ('OPEN','SENT')
    ORDER BY ot."OrderTicketId" DESC LIMIT 1;
END; $function$
;

-- usp_rest_orderticket_getheaderforclose
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_getheaderforclose(p_pedido_id integer)
 RETURNS TABLE(id integer, "empresaId" integer, "sucursalId" integer, "countryCode" character varying, "mesaId" integer, "clienteNombre" character varying, "clienteRif" character varying, estado character varying, total numeric, "fechaCierre" timestamp with time zone, "codUsuario" character varying)
 LANGUAGE plpgsql
AS $function$ BEGIN
    RETURN QUERY SELECT o."OrderTicketId",o."CompanyId",o."BranchId",o."CountryCode",dt."DiningTableId",
        o."CustomerName",o."CustomerFiscalId",o."Status",o."TotalAmount",o."ClosedAt",
        COALESCE(uc."UserCode",uo."UserCode")::VARCHAR
    FROM rest."OrderTicket" o
    LEFT JOIN rest."DiningTable" dt ON dt."CompanyId"=o."CompanyId" AND dt."BranchId"=o."BranchId" AND dt."TableNumber"=o."TableNumber"
    LEFT JOIN sec."User" uo ON uo."UserId"=o."OpenedByUserId"
    LEFT JOIN sec."User" uc ON uc."UserId"=o."ClosedByUserId"
    WHERE o."OrderTicketId"=p_pedido_id LIMIT 1;
END; $function$
;

-- usp_rest_orderticket_getopenbytable
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_getopenbytable(p_company_id integer, p_branch_id integer, p_table_number character varying)
 RETURNS TABLE(id integer, status character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT ot."OrderTicketId", ot."Status"
    FROM rest."OrderTicket" ot
    WHERE ot."CompanyId" = p_company_id AND ot."BranchId" = p_branch_id
      AND ot."TableNumber" = p_table_number AND ot."Status" IN ('OPEN', 'SENT')
    ORDER BY ot."OrderTicketId" DESC LIMIT 1;
END;
$function$
;

-- usp_rest_orderticket_infercountrycode
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_infercountrycode(p_empresa_id integer, p_sucursal_id integer)
 RETURNS TABLE("countryCode" character varying)
 LANGUAGE plpgsql
AS $function$ BEGIN
    RETURN QUERY SELECT cc."CountryCode" FROM fiscal."CountryConfig" cc
    WHERE cc."CompanyId"=p_empresa_id AND cc."BranchId"=p_sucursal_id AND cc."IsActive"=TRUE
    ORDER BY cc."UpdatedAt" DESC, cc."CountryConfigId" DESC LIMIT 1;
END; $function$
;

-- usp_rest_orderticket_recalctotals
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_recalctotals(p_order_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE v_net NUMERIC(18,2); v_tax NUMERIC(18,2); v_total NUMERIC(18,2);
BEGIN
    SELECT COALESCE(SUM("NetAmount"),0),COALESCE(SUM("TaxAmount"),0),COALESCE(SUM("TotalAmount"),0)
    INTO v_net,v_tax,v_total FROM rest."OrderTicketLine" WHERE "OrderTicketId"=p_order_id;
    UPDATE rest."OrderTicket" SET "NetAmount"=v_net,"TaxAmount"=v_tax,"TotalAmount"=v_total,
        "UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "OrderTicketId"=p_order_id;
END; $function$
;

-- usp_rest_orderticket_sendtokitchen
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_sendtokitchen(p_pedido_id integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$ BEGIN
    UPDATE rest."OrderTicket" SET "Status"=CASE WHEN "Status"='OPEN' THEN 'SENT' ELSE "Status" END,
        "UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "OrderTicketId"=p_pedido_id;
    RETURN QUERY SELECT 1,'OK'::VARCHAR(500);
END; $function$
;

-- usp_rest_orderticket_updatetimestamp
CREATE OR REPLACE FUNCTION public.usp_rest_orderticket_updatetimestamp(p_pedido_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$ BEGIN
    UPDATE rest."OrderTicket" SET "UpdatedAt"=NOW() AT TIME ZONE 'UTC' WHERE "OrderTicketId"=p_pedido_id;
END; $function$
;

-- usp_rest_orderticketline_getbyid
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_getbyid(p_pedido_id integer, p_item_id integer)
 RETURNS TABLE("itemId" integer, "lineNumber" integer, "countryCode" character varying, "productId" integer, "productCode" character varying, nombre character varying, cantidad numeric, "unitPrice" numeric, "taxCode" character varying, "taxRate" numeric, "netAmount" numeric, "taxAmount" numeric, "totalAmount" numeric)
 LANGUAGE plpgsql
AS $function$ BEGIN
    RETURN QUERY SELECT ol."OrderTicketLineId",ol."LineNumber",ol."CountryCode",ol."ProductId",
        ol."ProductCode",ol."ProductName",ol."Quantity",ol."UnitPrice",ol."TaxCode",ol."TaxRate",
        ol."NetAmount",ol."TaxAmount",ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    WHERE ol."OrderTicketId"=p_pedido_id AND ol."OrderTicketLineId"=p_item_id LIMIT 1;
END; $function$
;

-- usp_rest_orderticketline_getbypedido
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_getbypedido(p_pedido_id integer)
 RETURNS TABLE(id integer, "productoId" character varying, nombre character varying, cantidad numeric, "precioUnitario" numeric, subtotal numeric, iva numeric, "taxCode" character varying, impuesto numeric, total numeric)
 LANGUAGE plpgsql
AS $function$ BEGIN
    RETURN QUERY SELECT ol."OrderTicketLineId",ol."ProductCode",ol."ProductName",ol."Quantity",
        ol."UnitPrice",ol."NetAmount",
        CASE WHEN ol."TaxRate">1 THEN ol."TaxRate" ELSE ol."TaxRate"*100 END,
        ol."TaxCode",ol."TaxAmount",ol."TotalAmount"
    FROM rest."OrderTicketLine" ol WHERE ol."OrderTicketId"=p_pedido_id ORDER BY ol."LineNumber";
END; $function$
;

-- usp_rest_orderticketline_getfiscalbreakdown
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_getfiscalbreakdown(p_pedido_id integer)
 RETURNS TABLE("itemId" integer, "productoId" character varying, nombre character varying, quantity numeric, "unitPrice" numeric, "baseAmount" numeric, "taxCode" character varying, "taxRate" numeric, "taxAmount" numeric, "totalAmount" numeric)
 LANGUAGE plpgsql
AS $function$ BEGIN
    RETURN QUERY SELECT ol."OrderTicketLineId",ol."ProductCode",ol."ProductName",
        ol."Quantity",ol."UnitPrice",ol."NetAmount",ol."TaxCode",ol."TaxRate",ol."TaxAmount",ol."TotalAmount"
    FROM rest."OrderTicketLine" ol WHERE ol."OrderTicketId"=p_pedido_id ORDER BY ol."LineNumber";
END; $function$
;

-- usp_rest_orderticketline_insert
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_insert(p_order_id integer, p_line_number integer, p_country_code character varying, p_product_id integer DEFAULT NULL::integer, p_product_code character varying DEFAULT NULL::character varying, p_product_name character varying DEFAULT NULL::character varying, p_quantity numeric DEFAULT NULL::numeric, p_unit_price numeric DEFAULT NULL::numeric, p_tax_code character varying DEFAULT NULL::character varying, p_tax_rate numeric DEFAULT NULL::numeric, p_net_amount numeric DEFAULT NULL::numeric, p_tax_amount numeric DEFAULT NULL::numeric, p_total_amount numeric DEFAULT NULL::numeric, p_notes character varying DEFAULT NULL::character varying, p_supervisor_approval_id integer DEFAULT NULL::integer)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
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
END; $function$
;

-- usp_rest_orderticketline_nextlinenumber
CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_nextlinenumber(p_order_id integer)
 RETURNS TABLE("nextLine" integer)
 LANGUAGE plpgsql
AS $function$ BEGIN
    RETURN QUERY SELECT COALESCE(MAX("LineNumber"),0)+1 FROM rest."OrderTicketLine" WHERE "OrderTicketId"=p_order_id;
END; $function$
;

-- usp_rest_pedido_abrir
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_abrir(p_mesa_id integer, p_cliente_nombre character varying DEFAULT NULL::character varying, p_cliente_rif character varying DEFAULT NULL::character varying, p_cod_usuario character varying DEFAULT NULL::character varying)
 RETURNS TABLE("PedidoId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_pedido_id INT;
BEGIN
    INSERT INTO "RestaurantePedidos" ("MesaId", "ClienteNombre", "ClienteRif", "Estado", "CodUsuario")
    VALUES (p_mesa_id, p_cliente_nombre, p_cliente_rif, 'abierto', p_cod_usuario)
    RETURNING "Id" INTO v_pedido_id;

    UPDATE "RestauranteMesas" SET "Estado" = 'ocupada' WHERE "Id" = p_mesa_id;

    RETURN QUERY SELECT v_pedido_id AS "PedidoId";

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- usp_rest_pedido_cerrar
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_cerrar(p_pedido_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_mesa_id INT;
BEGIN
    SELECT "MesaId" INTO v_mesa_id FROM "RestaurantePedidos" WHERE "Id" = p_pedido_id;

    UPDATE "RestaurantePedidos"
    SET "Estado" = 'cerrado', "FechaCierre" = NOW() AT TIME ZONE 'UTC'
    WHERE "Id" = p_pedido_id;

    UPDATE "RestauranteMesas" SET "Estado" = 'libre' WHERE "Id" = v_mesa_id;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$function$
;

-- usp_rest_pedido_get_by_mesa_header
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_get_by_mesa_header(p_mesa_id integer)
 RETURNS TABLE(id integer, "mesaId" integer, "clienteNombre" character varying, "clienteRif" character varying, estado character varying, total numeric, comentarios character varying, "fechaApertura" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."Id",
        p."MesaId",
        p."ClienteNombre",
        p."ClienteRif",
        p."Estado",
        p."Total",
        p."Comentarios",
        p."FechaApertura"
    FROM "RestaurantePedidos" p
    WHERE p."MesaId" = p_mesa_id AND p."Estado" <> 'cerrado'
    ORDER BY p."FechaApertura" DESC
    LIMIT 1;
END;
$function$
;

-- usp_rest_pedido_get_by_mesa_items
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_get_by_mesa_items(p_mesa_id integer)
 RETURNS TABLE(id integer, "pedidoId" integer, "productoId" character varying, nombre character varying, cantidad numeric, "precioUnitario" numeric, subtotal numeric, iva numeric, estado character varying, "esCompuesto" boolean, componentes character varying, comentarios character varying, "enviadoACocina" boolean, "horaEnvio" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        i."Id",
        i."PedidoId",
        i."ProductoId",
        i."Nombre",
        i."Cantidad",
        i."PrecioUnitario",
        i."Subtotal",
        i."IvaPct",
        i."Estado",
        i."EsCompuesto",
        i."Componentes",
        i."Comentarios",
        i."EnviadoACocina",
        i."HoraEnvio"
    FROM "RestaurantePedidoItems" i
    INNER JOIN "RestaurantePedidos" p ON i."PedidoId" = p."Id"
    WHERE p."MesaId" = p_mesa_id AND p."Estado" <> 'cerrado'
    ORDER BY i."Id";
END;
$function$
;

-- usp_rest_pedido_item_agregar
CREATE OR REPLACE FUNCTION public.usp_rest_pedido_item_agregar(p_pedido_id integer, p_producto_id character varying, p_nombre character varying, p_cantidad numeric, p_precio_unitario numeric, p_iva numeric DEFAULT NULL::numeric, p_es_compuesto boolean DEFAULT false, p_componentes text DEFAULT NULL::text, p_comentarios character varying DEFAULT NULL::character varying)
 RETURNS TABLE("ItemId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_subtotal NUMERIC(18,2) := p_cantidad * p_precio_unitario;
    v_iva_pct  NUMERIC(9,4) := p_iva;
    v_item_id  INT;
BEGIN
    IF v_iva_pct IS NULL THEN
        SELECT
            CASE
                WHEN COALESCE(inv."PORCENTAJE", 0) > 1 THEN (inv."PORCENTAJE" / 100.0)::NUMERIC(9,4)
                ELSE COALESCE(inv."PORCENTAJE", 0)::NUMERIC(9,4)
            END
        INTO v_iva_pct
        FROM master."Product" inv
        WHERE COALESCE(inv."IsDeleted", FALSE) = FALSE
          AND TRIM(inv."ProductCode") = TRIM(p_producto_id)
        LIMIT 1;
    END IF;

    IF v_iva_pct IS NULL THEN
        v_iva_pct := 0;
    END IF;

    INSERT INTO "RestaurantePedidoItems" ("PedidoId", "ProductoId", "Nombre", "Cantidad", "PrecioUnitario", "Subtotal", "IvaPct", "EsCompuesto", "Componentes", "Comentarios")
    VALUES (p_pedido_id, p_producto_id, p_nombre, p_cantidad, p_precio_unitario, v_subtotal, v_iva_pct, p_es_compuesto, p_componentes, p_comentarios)
    RETURNING "Id" INTO v_item_id;

    -- Recalcular total del pedido
    UPDATE "RestaurantePedidos"
    SET "Total" = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "RestaurantePedidoItems" WHERE "PedidoId" = p_pedido_id)
    WHERE "Id" = p_pedido_id;

    RETURN QUERY SELECT v_item_id AS "ItemId";
END;
$function$
;

-- usp_rest_producto_delete
CREATE OR REPLACE FUNCTION public.usp_rest_producto_delete(p_id integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE "RestauranteProductos" SET "Activo" = FALSE WHERE "Id" = p_id;
END;
$function$
;

-- usp_rest_producto_get
CREATE OR REPLACE FUNCTION public.usp_rest_producto_get(p_id integer)
 RETURNS TABLE(id integer, codigo character varying, nombre character varying, descripcion character varying, precio numeric, "categoriaId" integer, categoria character varying, "esCompuesto" boolean, "tiempoPreparacion" integer, imagen character varying, "esSugerenciaDelDia" boolean, disponible boolean, iva numeric, "costoEstimado" numeric, "articuloInventarioId" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."Id", p."Codigo", p."Nombre", p."Descripcion",
        p."Precio", p."CategoriaId", c."Nombre",
        p."EsCompuesto", p."TiempoPreparacion",
        p."Imagen", p."EsSugerenciaDelDia",
        p."Disponible", p."IVA", p."CostoEstimado",
        p."ArticuloInventarioId"
    FROM "RestauranteProductos" p
    LEFT JOIN "RestauranteCategorias" c ON c."Id" = p."CategoriaId"
    WHERE p."Id" = p_id;
END;
$function$
;

-- usp_rest_producto_get_componentes
CREATE OR REPLACE FUNCTION public.usp_rest_producto_get_componentes(p_id integer)
 RETURNS TABLE(id integer, nombre character varying, obligatorio boolean, orden integer, "opcionId" integer, "opcionNombre" character varying, "precioExtra" numeric, "opcionOrden" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        comp."Id", comp."Nombre", comp."Obligatorio", comp."Orden",
        opc."Id", opc."Nombre", opc."PrecioExtra", opc."Orden"
    FROM "RestauranteProductoComponentes" comp
    LEFT JOIN "RestauranteComponenteOpciones" opc ON opc."ComponenteId" = comp."Id"
    WHERE comp."ProductoId" = p_id
    ORDER BY comp."Orden", opc."Orden";
END;
$function$
;

-- usp_rest_producto_get_receta
CREATE OR REPLACE FUNCTION public.usp_rest_producto_get_receta(p_id integer)
 RETURNS TABLE(id integer, "inventarioId" character varying, "inventarioNombre" character varying, cantidad numeric, unidad character varying, comentario character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        r."Id", r."InventarioId",
        i."ProductName",
        r."Cantidad", r."Unidad", r."Comentario"
    FROM "RestauranteRecetas" r
    LEFT JOIN master."Product" i ON i."ProductCode" = r."InventarioId"
    WHERE r."ProductoId" = p_id;
END;
$function$
;

-- usp_rest_producto_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_producto_upsert(p_id integer DEFAULT 0, p_codigo character varying DEFAULT ''::character varying, p_nombre character varying DEFAULT ''::character varying, p_descripcion character varying DEFAULT NULL::character varying, p_categoria_id integer DEFAULT NULL::integer, p_precio numeric DEFAULT 0, p_costo_estimado numeric DEFAULT 0, p_iva numeric DEFAULT 16, p_es_compuesto boolean DEFAULT false, p_tiempo_preparacion integer DEFAULT 0, p_imagen character varying DEFAULT NULL::character varying, p_es_sugerencia_del_dia boolean DEFAULT false, p_disponible boolean DEFAULT true, p_articulo_inventario_id character varying DEFAULT NULL::character varying)
 RETURNS TABLE("ResultId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteProductos" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteProductos" SET
            "Codigo" = p_codigo, "Nombre" = p_nombre, "Descripcion" = p_descripcion,
            "CategoriaId" = p_categoria_id, "Precio" = p_precio, "CostoEstimado" = p_costo_estimado,
            "IVA" = p_iva, "EsCompuesto" = p_es_compuesto, "TiempoPreparacion" = p_tiempo_preparacion,
            "Imagen" = p_imagen, "EsSugerenciaDelDia" = p_es_sugerencia_del_dia,
            "Disponible" = p_disponible, "ArticuloInventarioId" = p_articulo_inventario_id,
            "FechaModificacion" = NOW() AT TIME ZONE 'UTC'
        WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteProductos" ("Codigo", "Nombre", "Descripcion", "CategoriaId", "Precio", "CostoEstimado", "IVA", "EsCompuesto", "TiempoPreparacion", "Imagen", "EsSugerenciaDelDia", "Disponible", "ArticuloInventarioId")
        VALUES (p_codigo, p_nombre, p_descripcion, p_categoria_id, p_precio, p_costo_estimado, p_iva, p_es_compuesto, p_tiempo_preparacion, p_imagen, p_es_sugerencia_del_dia, p_disponible, p_articulo_inventario_id)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$function$
;

-- usp_rest_productos_list
CREATE OR REPLACE FUNCTION public.usp_rest_productos_list(p_categoria_id integer DEFAULT NULL::integer, p_search character varying DEFAULT NULL::character varying, p_solo_disponibles boolean DEFAULT true)
 RETURNS TABLE(id integer, codigo character varying, nombre character varying, descripcion character varying, precio numeric, "categoriaId" integer, categoria character varying, "esCompuesto" boolean, "tiempoPreparacion" integer, imagen character varying, "esSugerenciaDelDia" boolean, disponible boolean, iva numeric, "costoEstimado" numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."Id",
        p."Codigo",
        p."Nombre",
        p."Descripcion",
        p."Precio",
        p."CategoriaId",
        c."Nombre",
        p."EsCompuesto",
        p."TiempoPreparacion",
        p."Imagen",
        p."EsSugerenciaDelDia",
        p."Disponible",
        p."IVA",
        p."CostoEstimado"
    FROM "RestauranteProductos" p
    LEFT JOIN "RestauranteCategorias" c ON c."Id" = p."CategoriaId"
    WHERE p."Activo" = TRUE
      AND (p_solo_disponibles = FALSE OR p."Disponible" = TRUE)
      AND (p_categoria_id IS NULL OR p."CategoriaId" = p_categoria_id)
      AND (p_search IS NULL OR p."Nombre" ILIKE '%' || p_search || '%' OR p."Codigo" ILIKE '%' || p_search || '%')
    ORDER BY c."Orden", p."Nombre";
END;
$function$
;

-- usp_rest_receta_upsert
CREATE OR REPLACE FUNCTION public.usp_rest_receta_upsert(p_id integer DEFAULT 0, p_producto_id integer DEFAULT 0, p_inventario_id character varying DEFAULT ''::character varying, p_cantidad numeric DEFAULT 0, p_unidad character varying DEFAULT NULL::character varying, p_comentario character varying DEFAULT NULL::character varying)
 RETURNS TABLE("ResultId" integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_result_id INT;
BEGIN
    IF p_id > 0 AND EXISTS (SELECT 1 FROM "RestauranteRecetas" WHERE "Id" = p_id) THEN
        UPDATE "RestauranteRecetas" SET "InventarioId" = p_inventario_id, "Cantidad" = p_cantidad, "Unidad" = p_unidad, "Comentario" = p_comentario WHERE "Id" = p_id;
        v_result_id := p_id;
    ELSE
        INSERT INTO "RestauranteRecetas" ("ProductoId", "InventarioId", "Cantidad", "Unidad", "Comentario") VALUES (p_producto_id, p_inventario_id, p_cantidad, p_unidad, p_comentario)
        RETURNING "Id" INTO v_result_id;
    END IF;

    RETURN QUERY SELECT v_result_id;
END;
$function$
;

