-- =============================================================================
--  MigraciÃ³n 026: Fix tipos en funciones restaurante
--
--  Problemas encontrados:
--    1. usp_rest_diningtable_getbyid y usp_rest_diningtable_list declaran
--       "posicionX"/"posicionY" NUMERIC pero rest."DiningTable"."PositionX/Y"
--       son INT â†’ "structure of query does not match function result type"
--       en POST /pedidos/abrir (getDiningTableById).
--
--    2. Varias funciones seleccionan rest."OrderTicket"."CountryCode" y
--       fiscal."CountryConfig"."CountryCode" (ambas CHAR(2)) y las retornan
--       como VARCHAR sin cast explÃ­cito. En algunas versiones de PostgreSQL
--       esto puede causar "structure of query does not match function result type"
--       en los flujos de agregar item, cancelar item, cerrar pedido.
--
--  SoluciÃ³n:
--    - Cambiar NUMERIC â†’ INT para posicionX/posicionY (exacto al DDL)
--    - Agregar ::VARCHAR a todas las selecciones de columnas CHAR(2)
-- =============================================================================

\echo '  [026] Fix posicionX/Y INT en usp_rest_diningtable_getbyid...'

DROP FUNCTION IF EXISTS usp_rest_diningtable_getbyid(INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_diningtable_getbyid(INT, INT, BIGINT) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_diningtable_getbyid(
    p_company_id INT,
    p_branch_id  INT,
    p_mesa_id    BIGINT
)
RETURNS TABLE(
    "id"          BIGINT,
    "tableNumber" VARCHAR,
    "tableName"   VARCHAR,
    "capacity"    INT,
    "ambienteId"  VARCHAR,
    "ambiente"    VARCHAR,
    "posicionX"   INT,
    "posicionY"   INT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT dt."DiningTableId", dt."TableNumber"::VARCHAR, dt."TableName"::VARCHAR,
           dt."Capacity",
           dt."EnvironmentCode"::VARCHAR, dt."EnvironmentName"::VARCHAR,
           dt."PositionX", dt."PositionY"
    FROM rest."DiningTable" dt
    WHERE dt."CompanyId" = p_company_id AND dt."BranchId" = p_branch_id
      AND dt."DiningTableId" = p_mesa_id AND dt."IsActive" = TRUE
    LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_diningtable_getbyid(INT, INT, BIGINT) TO zentto_app;

\echo '  [026] Fix posicionX/Y INT en usp_rest_diningtable_list...'

DROP FUNCTION IF EXISTS usp_rest_diningtable_list(INT, INT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_diningtable_list(INT, INT, VARCHAR(50)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_diningtable_list(
    p_company_id  INT,
    p_branch_id   INT,
    p_ambiente_id VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "id"        BIGINT,
    "numero"    VARCHAR,
    "nombre"    VARCHAR,
    "capacidad" INT,
    "ambienteId" VARCHAR,
    "ambiente"  VARCHAR,
    "posicionX" INT,
    "posicionY" INT,
    "estado"    VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        dt."DiningTableId",
        dt."TableNumber"::VARCHAR,
        COALESCE(NULLIF(dt."TableName", ''), 'Mesa ' || dt."TableNumber")::VARCHAR,
        dt."Capacity",
        dt."EnvironmentCode"::VARCHAR,
        dt."EnvironmentName"::VARCHAR,
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

GRANT EXECUTE ON FUNCTION usp_rest_diningtable_list(INT, INT, VARCHAR) TO zentto_app;

\echo '  [026] Fix ::VARCHAR cast en usp_rest_orderticket_getbyid...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_getbyid(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_getbyid(BIGINT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_getbyid(p_pedido_id BIGINT)
RETURNS TABLE(
    "orderId"     BIGINT,
    "companyId"   INT,
    "branchId"    INT,
    "countryCode" VARCHAR,
    "status"      VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ot."OrderTicketId", ot."CompanyId", ot."BranchId",
           ot."CountryCode"::VARCHAR, ot."Status"::VARCHAR
    FROM rest."OrderTicket" ot WHERE ot."OrderTicketId" = p_pedido_id LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_getbyid(BIGINT) TO zentto_app;

\echo '  [026] Fix ::VARCHAR cast en usp_rest_orderticketline_getbyid...'

DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbyid(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbyid(BIGINT, BIGINT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbyid(p_pedido_id BIGINT, p_item_id BIGINT)
RETURNS TABLE(
    "itemId"      BIGINT,
    "lineNumber"  INT,
    "countryCode" VARCHAR,
    "productId"   BIGINT,
    "productCode" VARCHAR,
    "nombre"      VARCHAR,
    "cantidad"    NUMERIC,
    "unitPrice"   NUMERIC,
    "taxCode"     VARCHAR,
    "taxRate"     NUMERIC,
    "netAmount"   NUMERIC,
    "taxAmount"   NUMERIC,
    "totalAmount" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ol."OrderTicketLineId", ol."LineNumber", ol."CountryCode"::VARCHAR,
           ol."ProductId", ol."ProductCode"::VARCHAR, ol."ProductName"::VARCHAR,
           ol."Quantity", ol."UnitPrice",
           ol."TaxCode"::VARCHAR, ol."TaxRate",
           ol."NetAmount", ol."TaxAmount", ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    WHERE ol."OrderTicketId" = p_pedido_id AND ol."OrderTicketLineId" = p_item_id LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticketline_getbyid(BIGINT, BIGINT) TO zentto_app;

\echo '  [026] Fix ::VARCHAR cast en usp_rest_orderticket_getheaderforclose...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_getheaderforclose(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_getheaderforclose(BIGINT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_getheaderforclose(p_pedido_id BIGINT)
RETURNS TABLE(
    "id"             BIGINT,
    "empresaId"      INT,
    "sucursalId"     INT,
    "countryCode"    VARCHAR,
    "mesaId"         BIGINT,
    "clienteNombre"  VARCHAR,
    "clienteRif"     VARCHAR,
    "estado"         VARCHAR,
    "total"          NUMERIC,
    "fechaCierre"    TIMESTAMP,
    "codUsuario"     VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT o."OrderTicketId", o."CompanyId", o."BranchId",
           o."CountryCode"::VARCHAR,
           dt."DiningTableId",
           o."CustomerName"::VARCHAR, o."CustomerFiscalId"::VARCHAR,
           o."Status"::VARCHAR, o."TotalAmount", o."ClosedAt",
           COALESCE(uc."UserCode", uo."UserCode")::VARCHAR
    FROM rest."OrderTicket" o
    LEFT JOIN rest."DiningTable" dt
           ON dt."CompanyId" = o."CompanyId" AND dt."BranchId" = o."BranchId"
          AND dt."TableNumber" = o."TableNumber"
    LEFT JOIN sec."User" uo ON uo."UserId" = o."OpenedByUserId"
    LEFT JOIN sec."User" uc ON uc."UserId" = o."ClosedByUserId"
    WHERE o."OrderTicketId" = p_pedido_id LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_getheaderforclose(BIGINT) TO zentto_app;

\echo '  [026] Fix ::VARCHAR cast en usp_rest_orderticket_infercountrycode...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_infercountrycode(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticket_infercountrycode(p_empresa_id INT, p_sucursal_id INT)
RETURNS TABLE("countryCode" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT cc."CountryCode"::VARCHAR
    FROM fiscal."CountryConfig" cc
    WHERE cc."CompanyId" = p_empresa_id AND cc."BranchId" = p_sucursal_id AND cc."IsActive" = TRUE
    ORDER BY cc."UpdatedAt" DESC, cc."CountryConfigId" DESC LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_infercountrycode(INT, INT) TO zentto_app;

\echo '  [026] Fix ::VARCHAR cast en usp_rest_orderticketline_getfiscalbreakdown...'

DROP FUNCTION IF EXISTS usp_rest_orderticketline_getfiscalbreakdown(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getfiscalbreakdown(BIGINT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getfiscalbreakdown(p_pedido_id BIGINT)
RETURNS TABLE(
    "itemId"      BIGINT,
    "productoId"  VARCHAR,
    "nombre"      VARCHAR,
    "quantity"    NUMERIC,
    "unitPrice"   NUMERIC,
    "baseAmount"  NUMERIC,
    "taxCode"     VARCHAR,
    "taxRate"     NUMERIC,
    "taxAmount"   NUMERIC,
    "totalAmount" NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ol."OrderTicketLineId",
           ol."ProductCode"::VARCHAR, ol."ProductName"::VARCHAR,
           ol."Quantity", ol."UnitPrice", ol."NetAmount",
           ol."TaxCode"::VARCHAR, ol."TaxRate", ol."TaxAmount", ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    WHERE ol."OrderTicketId" = p_pedido_id
    ORDER BY ol."LineNumber";
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticketline_getfiscalbreakdown(BIGINT) TO zentto_app;

\echo '  [026] Fix ::VARCHAR cast en usp_rest_orderticketline_getbypedido...'

DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbypedido(INT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbypedido(BIGINT) CASCADE;
DROP FUNCTION IF EXISTS usp_rest_orderticketline_getbypedido(p_pedido_id BIGINT)
RETURNS TABLE(
    "id"             BIGINT,
    "productoId"     VARCHAR,
    "nombre"         VARCHAR,
    "cantidad"       NUMERIC,
    "precioUnitario" NUMERIC,
    "subtotal"       NUMERIC,
    "iva"            NUMERIC,
    "taxCode"        VARCHAR,
    "impuesto"       NUMERIC,
    "total"          NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ol."OrderTicketLineId",
           ol."ProductCode"::VARCHAR, ol."ProductName"::VARCHAR,
           ol."Quantity", ol."UnitPrice", ol."NetAmount",
           CASE WHEN ol."TaxRate" > 1 THEN ol."TaxRate" ELSE ol."TaxRate" * 100 END,
           ol."TaxCode"::VARCHAR, ol."TaxAmount", ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    WHERE ol."OrderTicketId" = p_pedido_id
    ORDER BY ol."LineNumber";
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticketline_getbypedido(BIGINT) TO zentto_app;

\echo '  [026] Fix ::VARCHAR cast en usp_rest_orderticket_getbymesaheader...'

DROP FUNCTION IF EXISTS usp_rest_orderticket_getbymesaheader(INT, INT, VARCHAR(20)) CASCADE;
CREATE OR REPLACE FUNCTION usp_rest_orderticket_getbymesaheader(
    p_company_id INT, p_branch_id INT, p_table_number VARCHAR(20)
)
RETURNS TABLE(
    "id"            BIGINT,
    "clienteNombre" VARCHAR,
    "clienteRif"    VARCHAR,
    "estado"        VARCHAR,
    "total"         NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT ot."OrderTicketId",
           ot."CustomerName"::VARCHAR, ot."CustomerFiscalId"::VARCHAR,
           ot."Status"::VARCHAR, ot."TotalAmount"
    FROM rest."OrderTicket" ot
    WHERE ot."CompanyId" = p_company_id AND ot."BranchId" = p_branch_id
      AND ot."TableNumber" = p_table_number AND ot."Status" IN ('OPEN', 'SENT')
    ORDER BY ot."OrderTicketId" DESC LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION usp_rest_orderticket_getbymesaheader(INT, INT, VARCHAR(20)) TO zentto_app;

\echo '  [026] Registrando migraciÃ³n...'
INSERT INTO public._migrations (name, applied_at)
VALUES ('026_fix_diningtable_position_and_countrycode_casts', NOW() AT TIME ZONE 'UTC')
ON CONFLICT (name) DO NOTHING;

\echo '  [026] COMPLETO â€” 8 funciones restaurante corregidas (posicionX/Y INT + ::VARCHAR casts)'
