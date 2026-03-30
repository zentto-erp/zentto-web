-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_crud_empresa.sql
-- CRUD de Empresa (registro unico)
-- ============================================================

-- ---------- 1. Get (primer registro) ----------
CREATE OR REPLACE FUNCTION usp_empresa_get()
RETURNS TABLE(
    "Empresa"    VARCHAR(100),
    "RIF"        VARCHAR(50),
    "Nit"        VARCHAR(50),
    "Telefono"   VARCHAR(60),
    "Direccion"  VARCHAR(255),
    "Rifs"       VARCHAR(50)
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        e."Empresa",
        e."RIF",
        e."Nit",
        e."Telefono",
        e."Direccion",
        e."Rifs"
    FROM public."Empresa" e
    LIMIT 1;
END;
$$;

-- ---------- 2. Update ----------
CREATE OR REPLACE FUNCTION usp_empresa_update(
    p_row_json JSONB
)
RETURNS TABLE(
    "Resultado" INT,
    "Mensaje"   VARCHAR(500)
)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public."Empresa") THEN
        RETURN QUERY SELECT -1, 'Empresa no encontrada'::VARCHAR(500);
        RETURN;
    END IF;

    UPDATE public."Empresa" SET
        "Empresa"   = COALESCE(NULLIF(p_row_json->>'Empresa', ''::VARCHAR), "Empresa"),
        "RIF"       = COALESCE(NULLIF(p_row_json->>'RIF', ''::VARCHAR), "RIF"),
        "Nit"       = COALESCE(NULLIF(p_row_json->>'Nit', ''::VARCHAR), "Nit"),
        "Telefono"  = COALESCE(NULLIF(p_row_json->>'Telefono', ''::VARCHAR), "Telefono"),
        "Direccion" = COALESCE(NULLIF(p_row_json->>'Direccion', ''::VARCHAR), "Direccion"),
        "Rifs"      = COALESCE(NULLIF(p_row_json->>'Rifs', ''::VARCHAR), "Rifs");

    RETURN QUERY SELECT 1, 'OK'::VARCHAR(500);

EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT -99, SQLERRM::VARCHAR(500);
END;
$$;
