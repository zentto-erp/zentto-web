-- ============================================================
-- DatqBoxWeb PostgreSQL - Helper Functions
-- Emulacion de funciones SQL Server
-- ============================================================

-- try_cast_int: intento seguro de convertir TEXT a INT
DROP FUNCTION IF EXISTS try_cast_int(TEXT) CASCADE;
CREATE OR REPLACE FUNCTION try_cast_int(p_val TEXT)
RETURNS INT AS $$
BEGIN
    RETURN p_val::INT;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- try_cast_bigint
DROP FUNCTION IF EXISTS try_cast_bigint(TEXT) CASCADE;
CREATE OR REPLACE FUNCTION try_cast_bigint(p_val TEXT)
RETURNS BIGINT AS $$
BEGIN
    RETURN p_val::BIGINT;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- try_cast_numeric
DROP FUNCTION IF EXISTS try_cast_numeric(TEXT) CASCADE;
CREATE OR REPLACE FUNCTION try_cast_numeric(p_val TEXT)
RETURNS NUMERIC AS $$
BEGIN
    RETURN p_val::NUMERIC;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- try_cast_date
DROP FUNCTION IF EXISTS try_cast_date(TEXT) CASCADE;
CREATE OR REPLACE FUNCTION try_cast_date(p_val TEXT)
RETURNS DATE AS $$
BEGIN
    RETURN p_val::DATE;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- try_cast_timestamp
DROP FUNCTION IF EXISTS try_cast_timestamp(TEXT) CASCADE;
CREATE OR REPLACE FUNCTION try_cast_timestamp(p_val TEXT)
RETURNS TIMESTAMP AS $$
BEGIN
    RETURN p_val::TIMESTAMP;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- isnumeric: emula ISNUMERIC() de SQL Server
DROP FUNCTION IF EXISTS isnumeric(TEXT) CASCADE;
CREATE OR REPLACE FUNCTION isnumeric(p_val TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    PERFORM p_val::NUMERIC;
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- isdate: emula ISDATE() de SQL Server
DROP FUNCTION IF EXISTS isdate(TEXT) CASCADE;
CREATE OR REPLACE FUNCTION isdate(p_val TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    PERFORM p_val::DATE;
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- format_date: emula FORMAT(fecha, 'yyyy-MM-dd')
DROP FUNCTION IF EXISTS format_date(TIMESTAMP, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION format_date(p_date TIMESTAMP, p_format TEXT DEFAULT 'YYYY-MM-DD')
RETURNS TEXT AS $$
BEGIN
    RETURN to_char(p_date, p_format);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- nullif_empty: NULLIF(valor, ''::VARCHAR) - muy usado en el codebase
DROP FUNCTION IF EXISTS nullif_empty(TEXT) CASCADE;
CREATE OR REPLACE FUNCTION nullif_empty(p_val TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN NULLIF(TRIM(p_val), ''::VARCHAR);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
