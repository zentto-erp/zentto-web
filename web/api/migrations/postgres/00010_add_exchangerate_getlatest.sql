-- +goose Up
-- +goose StatementBegin
DROP FUNCTION IF EXISTS usp_cfg_exchangerate_getlatest() CASCADE;
CREATE OR REPLACE FUNCTION usp_cfg_exchangerate_getlatest()
RETURNS TABLE("CurrencyCode" VARCHAR, "RateToBase" NUMERIC(18,6), "RateDate" DATE, "SourceName" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (e."CurrencyCode")
           e."CurrencyCode"::VARCHAR,
           e."RateToBase",
           e."RateDate",
           e."SourceName"::VARCHAR
      FROM cfg."ExchangeRateDaily" e
     WHERE e."CurrencyCode" IN ('USD', 'EUR')
     ORDER BY e."CurrencyCode", e."RateDate" DESC;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_cfg_exchangerate_getlatest() CASCADE;
