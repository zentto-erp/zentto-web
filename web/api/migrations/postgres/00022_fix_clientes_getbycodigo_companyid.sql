-- +goose Up
-- Fix: usp_clientes_getbycodigo ahora acepta p_company_id para paridad con el service

DROP FUNCTION IF EXISTS usp_clientes_getbycodigo(INT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS usp_clientes_getbycodigo(VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION usp_clientes_getbycodigo(
    p_company_id INT DEFAULT 1,
    p_codigo VARCHAR(24) DEFAULT NULL
)
RETURNS TABLE(
    "CODIGO"          VARCHAR,
    "NOMBRE"          VARCHAR,
    "RIF"             VARCHAR,
    "SALDO_TOT"       DOUBLE PRECISION,
    "LIMITE"          DOUBLE PRECISION,
    "IsActive"        BOOLEAN,
    "IsDeleted"       BOOLEAN,
    "CompanyId"       INT,
    "CustomerCode"    VARCHAR,
    "CustomerName"    VARCHAR,
    "FiscalId"        VARCHAR,
    "TotalBalance"    DOUBLE PRECISION,
    "CreditLimit"     DOUBLE PRECISION,
    "NIT"             VARCHAR,
    "Direccion"       VARCHAR,
    "Telefono"        VARCHAR,
    "Contacto"        VARCHAR,
    "SalespersonCode" VARCHAR,
    "PriceListCode"   VARCHAR,
    "Ciudad"          VARCHAR,
    "CodPostal"       VARCHAR,
    "Email"           VARCHAR,
    "PaginaWww"       VARCHAR,
    "CodUsuario"      VARCHAR,
    "Credito"         DOUBLE PRECISION
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CustomerCode"::VARCHAR                        AS "CODIGO",
        c."CustomerName"::VARCHAR                        AS "NOMBRE",
        COALESCE(c."FiscalId",''::VARCHAR)::VARCHAR               AS "RIF",
        COALESCE(c."TotalBalance",0::NUMERIC)::DOUBLE PRECISION   AS "SALDO_TOT",
        COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION    AS "LIMITE",
        c."IsActive",
        c."IsDeleted",
        c."CompanyId",
        c."CustomerCode"::VARCHAR,
        c."CustomerName"::VARCHAR,
        COALESCE(c."FiscalId",''::VARCHAR)::VARCHAR,
        COALESCE(c."TotalBalance",0::NUMERIC)::DOUBLE PRECISION,
        COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION,
        NULL::VARCHAR                                    AS "NIT",
        COALESCE(c."AddressLine",''::VARCHAR)::VARCHAR            AS "Direccion",
        COALESCE(c."Phone",''::VARCHAR)::VARCHAR                  AS "Telefono",
        NULL::VARCHAR                                    AS "Contacto",
        NULL::VARCHAR                                    AS "SalespersonCode",
        NULL::VARCHAR                                    AS "PriceListCode",
        NULL::VARCHAR                                    AS "Ciudad",
        NULL::VARCHAR                                    AS "CodPostal",
        COALESCE(c."Email",''::VARCHAR)::VARCHAR                  AS "Email",
        NULL::VARCHAR                                    AS "PaginaWww",
        NULL::VARCHAR                                    AS "CodUsuario",
        COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION    AS "Credito"
    FROM master."Customer" c
    WHERE c."CustomerCode" = p_codigo
      AND c."CompanyId" = p_company_id
      AND COALESCE(c."IsDeleted", FALSE) = FALSE;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_clientes_getbycodigo(INT, VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION usp_clientes_getbycodigo(
    p_codigo VARCHAR(24)
)
RETURNS TABLE(
    "CODIGO"          VARCHAR,
    "NOMBRE"          VARCHAR,
    "RIF"             VARCHAR,
    "SALDO_TOT"       DOUBLE PRECISION,
    "LIMITE"          DOUBLE PRECISION,
    "IsActive"        BOOLEAN,
    "IsDeleted"       BOOLEAN,
    "CompanyId"       INT,
    "CustomerCode"    VARCHAR,
    "CustomerName"    VARCHAR,
    "FiscalId"        VARCHAR,
    "TotalBalance"    DOUBLE PRECISION,
    "CreditLimit"     DOUBLE PRECISION,
    "NIT"             VARCHAR,
    "Direccion"       VARCHAR,
    "Telefono"        VARCHAR,
    "Contacto"        VARCHAR,
    "SalespersonCode" VARCHAR,
    "PriceListCode"   VARCHAR,
    "Ciudad"          VARCHAR,
    "CodPostal"       VARCHAR,
    "Email"           VARCHAR,
    "PaginaWww"       VARCHAR,
    "CodUsuario"      VARCHAR,
    "Credito"         DOUBLE PRECISION
)
-- +goose StatementBegin
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."CustomerCode"::VARCHAR                        AS "CODIGO",
        c."CustomerName"::VARCHAR                        AS "NOMBRE",
        COALESCE(c."FiscalId",''::VARCHAR)::VARCHAR               AS "RIF",
        COALESCE(c."TotalBalance",0::NUMERIC)::DOUBLE PRECISION   AS "SALDO_TOT",
        COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION    AS "LIMITE",
        c."IsActive",
        c."IsDeleted",
        c."CompanyId",
        c."CustomerCode"::VARCHAR,
        c."CustomerName"::VARCHAR,
        COALESCE(c."FiscalId",''::VARCHAR)::VARCHAR,
        COALESCE(c."TotalBalance",0::NUMERIC)::DOUBLE PRECISION,
        COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION,
        NULL::VARCHAR                                    AS "NIT",
        COALESCE(c."AddressLine",''::VARCHAR)::VARCHAR            AS "Direccion",
        COALESCE(c."Phone",''::VARCHAR)::VARCHAR                  AS "Telefono",
        NULL::VARCHAR                                    AS "Contacto",
        NULL::VARCHAR                                    AS "SalespersonCode",
        NULL::VARCHAR                                    AS "PriceListCode",
        NULL::VARCHAR                                    AS "Ciudad",
        NULL::VARCHAR                                    AS "CodPostal",
        COALESCE(c."Email",''::VARCHAR)::VARCHAR                  AS "Email",
        NULL::VARCHAR                                    AS "PaginaWww",
        NULL::VARCHAR                                    AS "CodUsuario",
        COALESCE(c."CreditLimit",0::NUMERIC)::DOUBLE PRECISION    AS "Credito"
    FROM master."Customer" c
    WHERE c."CustomerCode" = p_codigo
      AND COALESCE(c."IsDeleted", FALSE) = FALSE;
END;
$$;
-- +goose StatementEnd

